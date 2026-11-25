import '../models/kpi_snapshot.dart';
import '../models/models.dart';

class _SimDebt {
  final String id;
  final String name;
  final String kind;
  int balance;
  final int startingBalance;
  final int aprBps;
  final int minPayment;

  _SimDebt({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
    required this.aprBps,
    required this.minPayment,
  }) : startingBalance = balance;
}

/// Debt Freedom Engine — Snowball, Avalanche & Custom Payoff Simulator
class DebtEngine {
  DebtEngine._();

  static DebtPayoffPlan simulate({
    required DhanflowAppState state,
    String strategy = 'snowball',
    int monthlyBudgetPaise = 2500000,
    List<String> customOrder = const [],
  }) {
    final debts = <_SimDebt>[];

    for (final c in state.creditCards.where((c) => c.isActive && c.outstandingPaise > 0)) {
      final bal = c.outstandingPaise;
      final minPay = ((bal * 0.05).round()).clamp(bal < 50000 ? bal : 50000, bal);
      debts.add(_SimDebt(
        id: c.id,
        name: c.name,
        kind: 'credit_card',
        balance: bal,
        aprBps: c.aprBps,
        minPayment: minPay,
      ));
    }

    for (final l in state.loans.where((l) => l.isActive && !l.isCleared)) {
      final bal = l.totalRemainingPaise;
      debts.add(_SimDebt(
        id: l.id,
        name: l.name,
        kind: 'loan',
        balance: bal,
        aprBps: l.aprBps,
        minPayment: l.emiAmountPaise < bal ? l.emiAmountPaise : bal,
      ));
    }

    for (final p in state.personalPayables.where((p) => !p.isSettled && p.amountPaise > 0)) {
      final bal = p.amountPaise;
      debts.add(_SimDebt(
        id: p.id,
        name: p.name,
        kind: 'payable',
        balance: bal,
        aprBps: 0,
        minPayment: 100000 < bal ? 100000 : bal,
      ));
    }

    if (debts.isEmpty) {
      return DebtPayoffPlan(
        strategy: strategy,
        monthlyBudgetPaise: monthlyBudgetPaise,
        totalDebtPaise: 0,
        monthsToFreedom: 0,
        debtFreeDate: DateTime.now(),
        totalInterestPaise: 0,
        interestSavedPaise: 0,
        nextTarget: null,
        payoffOrder: const [],
      );
    }

    final totalDebt = debts.fold<int>(0, (s, d) => s + d.balance);
    final minSum = debts.fold<int>(0, (s, d) => s + d.minPayment);
    final effectiveBudget = monthlyBudgetPaise > minSum ? monthlyBudgetPaise : minSum;

    List<_SimDebt> cloneSorted() {
      final list = debts
          .map((d) => _SimDebt(
                id: d.id,
                name: d.name,
                kind: d.kind,
                balance: d.balance,
                aprBps: d.aprBps,
                minPayment: d.minPayment,
              ))
          .toList();

      list.sort((a, b) {
        if (strategy == 'avalanche') {
          final cmp = b.aprBps.compareTo(a.aprBps);
          return cmp != 0 ? cmp : a.balance.compareTo(b.balance);
        }
        if (strategy == 'custom' && customOrder.isNotEmpty) {
          final ia = customOrder.indexOf(a.id);
          final ib = customOrder.indexOf(b.id);
          final sa = ia == -1 ? 99999 : ia;
          final sb = ib == -1 ? 99999 : ib;
          return sa.compareTo(sb);
        }
        return a.balance.compareTo(b.balance);
      });
      return list;
    }

    final simPlan = _run(cloneSorted(), effectiveBudget);
    final minOnlyPlan = _run(cloneSorted(), minSum);

    final now = DateTime.now();
    final freedomDate = DateTime(now.year, now.month + simPlan.months, now.day);

    return DebtPayoffPlan(
      strategy: strategy,
      monthlyBudgetPaise: effectiveBudget,
      totalDebtPaise: totalDebt,
      monthsToFreedom: simPlan.months,
      debtFreeDate: freedomDate,
      totalInterestPaise: simPlan.totalInterest,
      interestSavedPaise:
          (minOnlyPlan.totalInterest - simPlan.totalInterest).clamp(0, minOnlyPlan.totalInterest),
      nextTarget: simPlan.steps.isNotEmpty ? simPlan.steps.first.name : null,
      payoffOrder: simPlan.steps,
    );
  }

  static ({int months, int totalInterest, List<PayoffTimelineStep> steps}) _run(
    List<_SimDebt> items,
    int budgetPaise,
  ) {
    int months = 0;
    int totalInterest = 0;
    final steps = <PayoffTimelineStep>[];
    const maxMonths = 180;

    while (months < maxMonths) {
      final remaining = items.fold<int>(0, (s, d) => s + d.balance);
      if (remaining <= 0) break;

      months++;
      int available = budgetPaise;

      for (final d in items) {
        if (d.balance <= 0) continue;
        final monthlyInterest = ((d.balance * d.aprBps) / (10000 * 12)).round();
        d.balance += monthlyInterest;
        totalInterest += monthlyInterest;
      }

      for (final d in items) {
        if (d.balance <= 0) continue;
        final pay = [d.balance, d.minPayment, available].reduce((a, b) => a < b ? a : b);
        d.balance -= pay;
        available -= pay;
        if (d.balance == 0 && !steps.any((s) => s.id == d.id)) {
          steps.add(PayoffTimelineStep(
            id: d.id,
            name: d.name,
            kind: d.kind,
            clearedInMonth: months,
            startingBalancePaise: d.startingBalance,
            aprBps: d.aprBps,
          ));
        }
      }

      if (available > 0) {
        for (final d in items) {
          if (d.balance <= 0 || available <= 0) continue;
          final extra = d.balance < available ? d.balance : available;
          d.balance -= extra;
          available -= extra;
          if (d.balance == 0 && !steps.any((s) => s.id == d.id)) {
            steps.add(PayoffTimelineStep(
              id: d.id,
              name: d.name,
              kind: d.kind,
              clearedInMonth: months,
              startingBalancePaise: d.startingBalance,
              aprBps: d.aprBps,
            ));
          }
        }
      }
    }

    return (months: months, totalInterest: totalInterest, steps: steps);
  }
}
