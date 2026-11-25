import '../core/utils/inr_formatter.dart';
import '../models/kpi_snapshot.dart';
import '../models/models.dart';

/// Pure integer-paise KPI, Bullion, Health Score, and Smart Alerts engine.
class KPICalculator {
  KPICalculator._();

  static KPISnapshot compute(DhanflowAppState state) {
    final activeCards = state.creditCards.where((c) => c.isActive).toList();
    int totalCCOutstanding = 0;
    int totalCCLimit = 0;
    int clearedCount = 0;
    int pocketDebt = 0;

    for (final c in activeCards) {
      totalCCLimit += c.totalLimitPaise;
      totalCCOutstanding += c.outstandingPaise;
      if (c.isCleared) clearedCount++;
      if (!c.isCoveredByRecovery) {
        pocketDebt += c.outstandingPaise;
      }
    }

    final activeLoans = state.loans.where((l) => l.isActive && !l.isCleared).toList();
    final totalLoanRemaining = activeLoans.fold<int>(0, (s, l) => s + l.totalRemainingPaise);

    final activePayables = state.personalPayables.where((p) => !p.isSettled && p.amountPaise > 0).toList();
    final totalPayables = activePayables.fold<int>(0, (s, p) => s + p.amountPaise);

    final kulDena = totalCCOutstanding + totalLoanRemaining + totalPayables;
    final activeRecoveries = state.recoveries.where((r) => !r.isSettled && r.totalPendingPaise > 0).toList();
    final kulLena = activeRecoveries.fold<int>(0, (s, r) => s + r.totalPendingPaise);
    final asalNetDebt = kulDena - kulLena;

    final goldStats = computeBullionStats(
      state.bullionTransactions,
      'gold',
      state.settings.goldCurrentSellPaise,
    );
    final silverStats = computeBullionStats(
      state.bullionTransactions,
      'silver',
      state.settings.silverCurrentSellPaise,
    );
    final gullakAsset = goldStats.preGstAssetPaise + silverStats.preGstAssetPaise;
    final trueNetLiability = asalNetDebt - gullakAsset;

    final healthScore = _computeHealthScore(
      cards: activeCards,
      loans: state.loans,
      recoveries: state.recoveries,
      kulDena: kulDena,
      gullakAsset: gullakAsset,
      totalCCLimit: totalCCLimit,
      totalCCOutstanding: totalCCOutstanding,
    );

    final alerts = _computeSmartAlerts(
      cards: activeCards,
      loans: activeLoans,
      goldStats: goldStats,
      silverStats: silverStats,
    );

    return KPISnapshot(
      totalCCOutstandingPaise: totalCCOutstanding,
      totalCCLimitPaise: totalCCLimit,
      totalLoanRemainingPaise: totalLoanRemaining,
      totalPayablesPaise: totalPayables,
      kulDenaPaise: kulDena,
      kulLenaPaise: kulLena,
      asalNetDebtPaise: asalNetDebt,
      gullakAssetPaise: gullakAsset,
      trueNetLiabilityPaise: trueNetLiability,
      pocketDebtPaise: pocketDebt,
      totalCardsCount: activeCards.length,
      clearedCardsCount: clearedCount,
      goldStats: goldStats,
      silverStats: silverStats,
      healthScore: healthScore,
      smartAlerts: alerts,
    );
  }

  static BullionStats computeBullionStats(
    List<BullionTransactionModel> allTxns,
    String metal,
    int? currentSellPricePaise,
  ) {
    final txns = allTxns.where((t) => t.metal == metal).toList();
    if (txns.isEmpty) return BullionStats.empty(metal: metal);

    int totalGramsX10000 = 0;
    int preGstAsset = 0;
    int totalCashPaid = 0;
    int totalGstPaid = 0;

    final weightedInputs = <({int gramsX10000, int ratePaise})>[];
    for (final t in txns) {
      totalGramsX10000 += t.gramsX10000;
      preGstAsset += t.preGstPaise;
      totalCashPaid += t.totalPaidPaise;
      totalGstPaid += t.gstPaise;
      weightedInputs.add((gramsX10000: t.gramsX10000, ratePaise: t.buyRatePaise));
    }

    final avgRate = PaiseMath.weightedAvgRate(transactions: weightedInputs);
    final effectiveCost = PaiseMath.effectiveCostPerGram(totalCashPaid, totalGramsX10000);

    return BullionStats(
      metal: metal,
      totalGramsX10000: totalGramsX10000,
      weightedAvgRatePaise: avgRate,
      effectiveCostPaise: effectiveCost,
      preGstAssetPaise: preGstAsset,
      totalCashPaidPaise: totalCashPaid,
      totalGSTPaidPaise: totalGstPaid,
      currentSellPricePaise: currentSellPricePaise,
    );
  }

  static FinancialHealthScore _computeHealthScore({
    required List<CreditCardModel> cards,
    required List<LoanModel> loans,
    required List<RecoveryModel> recoveries,
    required int kulDena,
    required int gullakAsset,
    required int totalCCLimit,
    required int totalCCOutstanding,
  }) {
    final utilPct = totalCCLimit > 0 ? (totalCCOutstanding / totalCCLimit) * 100 : 0.0;
    final utilScore = (25 - (utilPct * 0.25)).round().clamp(0, 25);

    final clearedCount = cards.where((c) => c.isCleared).length;
    final clearedScore = cards.isNotEmpty ? ((clearedCount / cards.length) * 25).round() : 25;

    final origRec = recoveries.fold<int>(0, (s, r) => s + r.totalOriginalPaise);
    final pendRec = recoveries.fold<int>(0, (s, r) => s + r.totalPendingPaise);
    final recScore = origRec > 0
        ? (((origRec - pendRec) / origRec) * 20).round().clamp(5, 20)
        : 20;

    final origEmis = loans.fold<int>(0, (s, l) => s + l.originalEmis);
    final remEmis = loans.fold<int>(0, (s, l) => s + l.remainingEmis);
    final emiScore = origEmis > 0
        ? (((origEmis - remEmis) / origEmis) * 20).round().clamp(5, 20)
        : 20;

    final assetRatio = kulDena > 0 ? ((gullakAsset / kulDena) * 5).clamp(0.0, 1.0) : 1.0;
    final assetScore = (assetRatio * 10).round();

    final total = (utilScore + clearedScore + recScore + emiScore + assetScore).clamp(0, 100);

    return FinancialHealthScore(
      score: total,
      disclaimer: 'Personal financial clarity indicator only — not a CIBIL or bank credit score.',
      breakdown: [
        HealthScoreComponent(label: 'Credit Utilization', score: utilScore, max: 25),
        HealthScoreComponent(label: 'Cleared Cards Ratio', score: clearedScore, max: 25),
        HealthScoreComponent(label: 'Recovery Collection', score: recScore, max: 20),
        HealthScoreComponent(label: 'EMI Payoff Progress', score: emiScore, max: 20),
        HealthScoreComponent(label: 'Asset Buffer', score: assetScore, max: 10),
      ],
    );
  }

  static List<SmartAlert> _computeSmartAlerts({
    required List<CreditCardModel> cards,
    required List<LoanModel> loans,
    required BullionStats goldStats,
    required BullionStats silverStats,
  }) {
    final alerts = <SmartAlert>[];

    for (final c in cards) {
      if (c.utilizationPct >= 80) {
        alerts.add(SmartAlert(
          severity: 'high',
          title: '${c.name} utilization at ${c.utilizationFormatted}',
          message: 'Above 80% threshold. Tag: ${c.categoryTag}',
        ));
      } else if (!c.isCleared && c.outstandingPaise <= 50000) {
        alerts.add(SmartAlert(
          severity: 'tip',
          title: 'Quick Zero Win: ${c.name}',
          message: 'Only ${c.outstandingFormatted} left to clear another card!',
        ));
      }
    }

    for (final l in loans) {
      if (l.remainingEmis > 0 && l.remainingEmis <= 3) {
        alerts.add(SmartAlert(
          severity: 'info',
          title: '${l.name} nearing closure',
          message: 'Only ${l.remainingEmis} EMIs left to freedom.',
        ));
      }
    }

    for (final b in [goldStats, silverStats]) {
      final pl = b.unrealisedPLPaise;
      if (pl != null && pl > 0) {
        final name = b.metal == 'gold' ? 'Gold 24K' : 'Silver';
        alerts.add(SmartAlert(
          severity: 'positive',
          title: '$name in profit',
          message: 'Unrealized gain of ${INRFormatter.formatPaise(pl)}',
        ));
      }
    }

    return alerts;
  }
}
