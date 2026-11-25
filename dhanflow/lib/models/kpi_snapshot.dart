import 'package:equatable/equatable.dart';
import '../core/utils/inr_formatter.dart';

class HealthScoreComponent extends Equatable {
  final String label;
  final int score;
  final int max;

  const HealthScoreComponent({
    required this.label,
    required this.score,
    required this.max,
  });

  factory HealthScoreComponent.fromJson(Map<String, dynamic> json) =>
      HealthScoreComponent(
        label: json['label'] as String,
        score: (json['score'] as num).toInt(),
        max: (json['max'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {'label': label, 'score': score, 'max': max};

  @override
  List<Object?> get props => [label, score, max];
}

class FinancialHealthScore extends Equatable {
  final int score;
  final String disclaimer;
  final List<HealthScoreComponent> breakdown;

  const FinancialHealthScore({
    required this.score,
    required this.disclaimer,
    required this.breakdown,
  });

  String get ratingLabel {
    if (score >= 80) return 'Strong';
    if (score >= 60) return 'Improving';
    if (score >= 40) return 'Moderate';
    return 'Needs Focus';
  }

  factory FinancialHealthScore.empty() => const FinancialHealthScore(
        score: 0,
        disclaimer:
            'Personal financial clarity indicator only — not a CIBIL or bank credit score.',
        breakdown: [],
      );

  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) =>
      FinancialHealthScore(
        score: (json['score'] as num).toInt(),
        disclaimer: json['disclaimer'] as String? ??
            'Personal financial clarity indicator only — not a CIBIL or bank credit score.',
        breakdown: (json['breakdown'] as List<dynamic>? ?? [])
            .map((e) => HealthScoreComponent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [score, disclaimer, breakdown];
}

class SmartAlert extends Equatable {
  final String severity; // 'high' | 'tip' | 'info' | 'positive'
  final String title;
  final String message;

  const SmartAlert({
    required this.severity,
    required this.title,
    required this.message,
  });

  factory SmartAlert.fromJson(Map<String, dynamic> json) => SmartAlert(
        severity: json['severity'] as String? ?? 'info',
        title: json['title'] as String,
        message: json['message'] as String,
      );

  @override
  List<Object?> get props => [severity, title, message];
}

class BullionStats extends Equatable {
  final String metal; // 'gold' | 'silver'
  final int totalGramsX10000;
  final int weightedAvgRatePaise; // Pre-GST per gram
  final int effectiveCostPaise; // Incl. GST per gram
  final int preGstAssetPaise; // Cost basis excluding GST
  final int totalCashPaidPaise; // Including all GST paid
  final int totalGSTPaidPaise;
  final int? currentSellPricePaise;

  const BullionStats({
    required this.metal,
    required this.totalGramsX10000,
    required this.weightedAvgRatePaise,
    required this.effectiveCostPaise,
    required this.preGstAssetPaise,
    required this.totalCashPaidPaise,
    required this.totalGSTPaidPaise,
    this.currentSellPricePaise,
  });

  double get totalGramsDouble => totalGramsX10000 / 10000.0;

  int? get currentSellValuePaise {
    if (currentSellPricePaise == null || totalGramsX10000 <= 0) return null;
    return PaiseMath.preGstForGrams(totalGramsX10000, currentSellPricePaise!);
  }

  int? get unrealisedPLPaise {
    final sellVal = currentSellValuePaise;
    if (sellVal == null) return null;
    return sellVal - totalCashPaidPaise;
  }

  double? get returnPct {
    final pl = unrealisedPLPaise;
    if (pl == null || totalCashPaidPaise == 0) return null;
    return (pl / totalCashPaidPaise) * 100;
  }

  bool get hasTransactions => totalGramsX10000 > 0;

  String get totalGramsFormatted => INRFormatter.formatGrams(totalGramsX10000);
  String get avgRateFormatted => INRFormatter.formatRatePerGm(weightedAvgRatePaise);
  String get effectiveCostFormatted => INRFormatter.formatRatePerGm(effectiveCostPaise);
  String get assetValueFormatted => INRFormatter.formatPaise(preGstAssetPaise);
  String get totalPaidFormatted => INRFormatter.formatPaise(totalCashPaidPaise);
  String get gstPaidFormatted => INRFormatter.formatPaise(totalGSTPaidPaise);

  factory BullionStats.empty({String metal = 'gold'}) => BullionStats(
        metal: metal,
        totalGramsX10000: 0,
        weightedAvgRatePaise: 0,
        effectiveCostPaise: 0,
        preGstAssetPaise: 0,
        totalCashPaidPaise: 0,
        totalGSTPaidPaise: 0,
      );

  factory BullionStats.fromJson(Map<String, dynamic> json) => BullionStats(
        metal: json['metal'] as String,
        totalGramsX10000: (json['total_grams_x10000'] as num).toInt(),
        weightedAvgRatePaise: (json['weighted_avg_rate_paise'] as num).toInt(),
        effectiveCostPaise: (json['effective_cost_paise'] as num).toInt(),
        preGstAssetPaise: (json['pre_gst_asset_paise'] as num).toInt(),
        totalCashPaidPaise: (json['total_cash_paid_paise'] as num).toInt(),
        totalGSTPaidPaise: (json['total_gst_paid_paise'] as num).toInt(),
        currentSellPricePaise: (json['current_sell_price_paise'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [
        metal,
        totalGramsX10000,
        weightedAvgRatePaise,
        effectiveCostPaise,
        preGstAssetPaise,
        totalCashPaidPaise,
        totalGSTPaidPaise,
        currentSellPricePaise,
      ];
}

class KPISnapshot extends Equatable {
  final int totalCCOutstandingPaise;
  final int totalCCLimitPaise;
  final int totalLoanRemainingPaise;
  final int totalPayablesPaise;

  final int kulDenaPaise;
  final int kulLenaPaise;
  final int asalNetDebtPaise;
  final int gullakAssetPaise; // Combined Total Assets (Metals + Diamonds & Custom Assets)
  final int metalsAssetPaise;
  final int customAssetsPaise;
  final int trueNetLiabilityPaise;
  final int pocketDebtPaise;

  final int totalCardsCount;
  final int clearedCardsCount;

  final BullionStats goldStats;
  final BullionStats silverStats;
  final FinancialHealthScore healthScore;
  final List<SmartAlert> smartAlerts;

  const KPISnapshot({
    required this.totalCCOutstandingPaise,
    required this.totalCCLimitPaise,
    required this.totalLoanRemainingPaise,
    required this.totalPayablesPaise,
    required this.kulDenaPaise,
    required this.kulLenaPaise,
    required this.asalNetDebtPaise,
    required this.gullakAssetPaise,
    this.metalsAssetPaise = 0,
    this.customAssetsPaise = 0,
    required this.trueNetLiabilityPaise,
    required this.pocketDebtPaise,
    required this.totalCardsCount,
    required this.clearedCardsCount,
    required this.goldStats,
    required this.silverStats,
    required this.healthScore,
    required this.smartAlerts,
  });

  int get activeCardsCount => totalCardsCount - clearedCardsCount;
  double get overallUtilizationPct =>
      totalCCLimitPaise > 0 ? (totalCCOutstandingPaise / totalCCLimitPaise) * 100 : 0.0;

  int get totalAssetsPaise => gullakAssetPaise;
  String get kulDenaFormatted => INRFormatter.formatPaise(kulDenaPaise);
  String get kulLenaFormatted => INRFormatter.formatPaise(kulLenaPaise);
  String get asalNetDebtFormatted => INRFormatter.formatPaise(asalNetDebtPaise);
  String get gullakAssetFormatted => INRFormatter.formatPaise(gullakAssetPaise);
  String get totalAssetsFormatted => INRFormatter.formatPaise(gullakAssetPaise);
  String get customAssetsFormatted => INRFormatter.formatPaise(customAssetsPaise);
  String get metalsAssetFormatted => INRFormatter.formatPaise(metalsAssetPaise);
  String get trueNetFormatted => INRFormatter.formatPaise(trueNetLiabilityPaise);
  String get pocketDebtFormatted => INRFormatter.formatPaise(pocketDebtPaise);

  bool get isNetPositive => asalNetDebtPaise < 0;
  bool get isTruePositive => trueNetLiabilityPaise < 0;

  factory KPISnapshot.empty() => KPISnapshot(
        totalCCOutstandingPaise: 0,
        totalCCLimitPaise: 0,
        totalLoanRemainingPaise: 0,
        totalPayablesPaise: 0,
        kulDenaPaise: 0,
        kulLenaPaise: 0,
        asalNetDebtPaise: 0,
        gullakAssetPaise: 0,
        trueNetLiabilityPaise: 0,
        pocketDebtPaise: 0,
        totalCardsCount: 0,
        clearedCardsCount: 0,
        goldStats: BullionStats.empty(metal: 'gold'),
        silverStats: BullionStats.empty(metal: 'silver'),
        healthScore: FinancialHealthScore.empty(),
        smartAlerts: const [],
      );

  factory KPISnapshot.fromJson(Map<String, dynamic> json) => KPISnapshot(
        totalCCOutstandingPaise: (json['total_cc_outstanding_paise'] as num).toInt(),
        totalCCLimitPaise: (json['total_cc_limit_paise'] as num? ?? 0).toInt(),
        totalLoanRemainingPaise: (json['total_loan_remaining_paise'] as num).toInt(),
        totalPayablesPaise: (json['total_payables_paise'] as num).toInt(),
        kulDenaPaise: (json['kul_dena_paise'] as num).toInt(),
        kulLenaPaise: (json['kul_lena_paise'] as num).toInt(),
        asalNetDebtPaise: (json['asal_net_debt_paise'] as num).toInt(),
        gullakAssetPaise: (json['gullak_asset_paise'] as num).toInt(),
        metalsAssetPaise: (json['metals_asset_paise'] as num? ?? 0).toInt(),
        customAssetsPaise: (json['custom_assets_paise'] as num? ?? 0).toInt(),
        trueNetLiabilityPaise: (json['true_net_liability_paise'] as num).toInt(),
        pocketDebtPaise: (json['pocket_debt_paise'] as num).toInt(),
        totalCardsCount: (json['total_cards_count'] as num).toInt(),
        clearedCardsCount: (json['cleared_cards_count'] as num).toInt(),
        goldStats: BullionStats.fromJson(json['gold_stats'] as Map<String, dynamic>),
        silverStats: BullionStats.fromJson(json['silver_stats'] as Map<String, dynamic>),
        healthScore: json['health_score'] != null
            ? FinancialHealthScore.fromJson(json['health_score'] as Map<String, dynamic>)
            : FinancialHealthScore.empty(),
        smartAlerts: (json['smart_alerts'] as List<dynamic>? ?? [])
            .map((e) => SmartAlert.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        totalCCOutstandingPaise,
        totalCCLimitPaise,
        totalLoanRemainingPaise,
        totalPayablesPaise,
        kulDenaPaise,
        kulLenaPaise,
        asalNetDebtPaise,
        gullakAssetPaise,
        metalsAssetPaise,
        customAssetsPaise,
        trueNetLiabilityPaise,
        pocketDebtPaise,
        totalCardsCount,
        clearedCardsCount,
        goldStats,
        silverStats,
        healthScore,
        smartAlerts,
      ];
}

class PayoffTimelineStep extends Equatable {
  final String id;
  final String name;
  final String kind;
  final int clearedInMonth;
  final int startingBalancePaise;
  final int aprBps;

  const PayoffTimelineStep({
    required this.id,
    required this.name,
    required this.kind,
    required this.clearedInMonth,
    required this.startingBalancePaise,
    required this.aprBps,
  });

  @override
  List<Object?> get props => [id, name, kind, clearedInMonth, startingBalancePaise, aprBps];
}

class DebtPayoffPlan extends Equatable {
  final String strategy; // 'snowball' | 'avalanche' | 'custom'
  final int monthlyBudgetPaise;
  final int totalDebtPaise;
  final int monthsToFreedom;
  final DateTime debtFreeDate;
  final int totalInterestPaise;
  final int interestSavedPaise;
  final String? nextTarget;
  final List<PayoffTimelineStep> payoffOrder;

  const DebtPayoffPlan({
    required this.strategy,
    required this.monthlyBudgetPaise,
    required this.totalDebtPaise,
    required this.monthsToFreedom,
    required this.debtFreeDate,
    required this.totalInterestPaise,
    required this.interestSavedPaise,
    required this.nextTarget,
    required this.payoffOrder,
  });

  @override
  List<Object?> get props => [
        strategy,
        monthlyBudgetPaise,
        totalDebtPaise,
        monthsToFreedom,
        debtFreeDate,
        totalInterestPaise,
        interestSavedPaise,
        nextTarget,
        payoffOrder,
      ];
}
