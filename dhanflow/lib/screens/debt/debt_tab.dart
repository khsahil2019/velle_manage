import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/models.dart';
import '../../widgets/common/dhan_ui.dart';

class DebtTab extends StatefulWidget {
  const DebtTab({super.key});

  @override
  State<DebtTab> createState() => _DebtTabState();
}

class _DebtTabState extends State<DebtTab> {
  int _segment = 0; // 0 = Cards, 1 = Loans & Payables, 2 = Freedom Engine

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _SegmentButton(
                      label: 'Cards (${state.appState.creditCards.length})',
                      selected: _segment == 0,
                      onTap: () => setState(() => _segment = 0),
                    ),
                    _SegmentButton(
                      label: 'Loans & Payables',
                      selected: _segment == 1,
                      onTap: () => setState(() => _segment = 1),
                    ),
                    _SegmentButton(
                      label: 'Payoff Engine',
                      selected: _segment == 2,
                      onTap: () => setState(() => _segment = 2),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _segment == 0
                  ? _CreditCardsView(state: state)
                  : _segment == 1
                      ? _LoansPayablesView(state: state)
                      : _DebtFreedomEngineView(state: state),
            ),
          ],
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── CREDIT CARDS VIEW ───────────────────────────────────────────────────────

class _CreditCardsView extends StatelessWidget {
  final DhanflowViewState state;
  const _CreditCardsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cards = state.appState.creditCards;
    final kpi = state.kpis;
    final cubit = context.read<DhanflowCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(
          title: 'Credit Cards Ledger',
          subtitle:
              '${kpi.clearedCardsCount}/${kpi.totalCardsCount} cleared · Total Limit ${INRFormatter.formatPaise(kpi.totalCCLimitPaise)} · Util ${INRFormatter.formatPct(kpi.overallUtilizationPct)}',
          trailing: TextButton.icon(
            onPressed: () => _showAddCardSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accentGreen),
            label: const Text('Add Card', style: TextStyle(color: AppColors.accentGreen)),
          ),
        ),
        const SizedBox(height: 10),
        ...cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DhanCard(
                borderColor: card.isCleared
                    ? AppColors.accentGreen.withValues(alpha: 0.35)
                    : AppColors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(card.name, style: AppTextStyles.cardTitle),
                        ),
                        if (card.isCleared)
                          const StatusChip(
                            text: '✓ CLEARED',
                            color: AppColors.accentGreen,
                            bgColor: AppColors.greenDim,
                          )
                        else
                          StatusChip(
                            text: card.categoryTag,
                            color: card.isCoveredByRecovery
                                ? AppColors.accentBlue
                                : AppColors.accentAmber,
                            bgColor: card.isCoveredByRecovery
                                ? AppColors.blueDim
                                : AppColors.amberDim,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('OUTSTANDING', style: AppTextStyles.label),
                            const SizedBox(height: 2),
                            Text(
                              card.outstandingFormatted,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: card.isCleared
                                    ? AppColors.accentGreen
                                    : AppColors.accentRose,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('AVAILABLE', style: AppTextStyles.label),
                            const SizedBox(height: 2),
                            Text(
                              card.availableFormatted,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentGreen,
                              ),
                            ),
                            Text('of ${card.totalLimitFormatted}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textTertiary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Utilization',
                            style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        Text(
                          card.utilizationFormatted,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: card.utilizationColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    UtilizationBar(percentage: card.utilizationPct),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniActionButton(
                          label: 'Update Avl Limit',
                          icon: Icons.swap_vert_rounded,
                          color: AppColors.accentBlue,
                          onTap: () => _showAvlLimitSheet(context, card),
                        ),
                        _MiniActionButton(
                          label: 'Pay / Spend',
                          icon: Icons.currency_rupee_rounded,
                          color: AppColors.accentGreen,
                          onTap: () => _showPaySpendSheet(context, card),
                        ),
                        _MiniActionButton(
                          label: 'Edit Limit',
                          icon: Icons.edit_outlined,
                          color: AppColors.textSecondary,
                          onTap: () => _showEditLimitSheet(context, card),
                        ),
                        _MiniActionButton(
                          label: 'Delete',
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.accentRose,
                          onTap: () => _confirmDelete(
                            context,
                            title: 'Remove ${card.name}?',
                            message: 'Outstanding: ${card.outstandingFormatted}',
                            onConfirm: () => cubit.removeCreditCard(card.id),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _showAvlLimitSheet(BuildContext context, CreditCardModel card) {
    final ctrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final parsed = double.tryParse(ctrl.text);
        final newAvlPaise = parsed != null ? PaiseMath.rupeesToPaise(parsed) : null;
        final previewOut = newAvlPaise != null
            ? (card.totalLimitPaise - newAvlPaise).clamp(0, card.totalLimitPaise)
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update Available Limit — ${card.name}', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text('Current available: ${card.availableFormatted} · Total: ${card.totalLimitFormatted}',
                style: AppTextStyles.caption),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => setSheetState(() {}),
              decoration: const InputDecoration(
                labelText: 'New Available Limit from Bank App (₹)',
                prefixText: '₹ ',
              ),
            ),
            if (previewOut != null) ...[
              const SizedBox(height: 10),
              DhanCard(
                backgroundColor: AppColors.bgHover,
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Outstanding', style: TextStyle(fontSize: 12)),
                    Text(INRFormatter.formatPaise(previewOut),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accentAmber)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                if (newAvlPaise == null) return;
                context.read<DhanflowCubit>().updateCardAvailableLimit(card.id, newAvlPaise);
                Navigator.pop(ctx);
              },
              child: const Text('Update Available Limit'),
            ),
          ],
        );
      });
    });
  }

  void _showPaySpendSheet(BuildContext context, CreditCardModel card) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isPayment = true;

    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${card.name} — Payment / Spend', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text('Outstanding: ${card.outstandingFormatted} · Available: ${card.availableFormatted}',
                style: AppTextStyles.caption),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('💳 Payment Made'),
                    selected: isPayment,
                    selectedColor: AppColors.accentGreen,
                    labelStyle: TextStyle(
                        color: isPayment ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.w700),
                    onSelected: (_) => setSheetState(() => isPayment = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('🛒 New Spend'),
                    selected: !isPayment,
                    selectedColor: AppColors.accentRose,
                    labelStyle: TextStyle(
                        color: !isPayment ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700),
                    onSelected: (_) => setSheetState(() => isPayment = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPayment ? AppColors.accentGreen : AppColors.accentRose,
                foregroundColor: isPayment ? Colors.black : Colors.white,
              ),
              onPressed: () {
                final val = double.tryParse(amtCtrl.text);
                if (val == null || val <= 0) return;
                context.read<DhanflowCubit>().recordCardTransaction(
                      card.id,
                      isPayment: isPayment,
                      amountPaise: PaiseMath.rupeesToPaise(val),
                      note: noteCtrl.text,
                    );
                Navigator.pop(ctx);
              },
              child: Text(isPayment ? 'Record Payment' : 'Record Spend'),
            ),
          ],
        );
      });
    });
  }

  void _showEditLimitSheet(BuildContext context, CreditCardModel card) {
    final limitCtrl = TextEditingController(
      text: (card.totalLimitPaise / 100.0).toStringAsFixed(2),
    );
    final tagCtrl = TextEditingController(text: card.categoryTag);
    final aprCtrl = TextEditingController(text: (card.aprBps / 100.0).toStringAsFixed(1));

    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Card — ${card.name}', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text('Outstanding remains ${card.outstandingFormatted} on limit changes',
              style: AppTextStyles.caption),
          const SizedBox(height: 14),
          TextField(
            controller: limitCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Total Credit Limit (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: tagCtrl,
            decoration: const InputDecoration(labelText: 'Category Tag'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: aprCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'APR % (for Debt Engine)'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final lim = double.tryParse(limitCtrl.text);
              final apr = double.tryParse(aprCtrl.text);
              if (lim == null || lim <= 0) return;
              context.read<DhanflowCubit>().updateCardDetails(
                    card.id,
                    newTotalLimitPaise: PaiseMath.rupeesToPaise(lim),
                    categoryTag: tagCtrl.text,
                    aprBps: apr != null ? (apr * 100).round() : null,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ],
      );
    });
  }

  void _showAddCardSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final limCtrl = TextEditingController();
    final avlCtrl = TextEditingController();
    final tagCtrl = TextEditingController(text: 'Active Pocket Debt');

    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Credit Card', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Card Name')),
          const SizedBox(height: 10),
          TextField(
            controller: limCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Total Limit (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: avlCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Available Limit (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(controller: tagCtrl, decoration: const InputDecoration(labelText: 'Category Tag')),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final lim = double.tryParse(limCtrl.text);
              final avl = double.tryParse(avlCtrl.text);
              if (nameCtrl.text.trim().isEmpty || lim == null || avl == null) return;
              context.read<DhanflowCubit>().addCreditCard(
                    name: nameCtrl.text,
                    totalLimitPaise: PaiseMath.rupeesToPaise(lim),
                    availableLimitPaise: PaiseMath.rupeesToPaise(avl),
                    categoryTag: tagCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Card'),
          ),
        ],
      );
    });
  }
}

// ── LOANS & PAYABLES VIEW ───────────────────────────────────────────────────

class _LoansPayablesView extends StatelessWidget {
  final DhanflowViewState state;
  const _LoansPayablesView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DhanflowCubit>();
    final loans = state.appState.loans;
    final payables = state.appState.personalPayables;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(
          title: 'EMI Loans',
          trailing: TextButton.icon(
            onPressed: () => _showAddLoanSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accentBlue),
            label: const Text('Add Loan', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ),
        const SizedBox(height: 8),
        ...loans.map((loan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DhanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loan.name, style: AppTextStyles.cardTitle),
                        StatusChip(
                          text: loan.isCleared ? 'CLEARED' : '${loan.remainingEmis} EMIs left',
                          color: loan.isCleared ? AppColors.accentGreen : AppColors.accentBlue,
                          bgColor: loan.isCleared ? AppColors.greenDim : AppColors.blueDim,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCol('EMI AMOUNT', loan.emiFormatted, AppColors.accentBlue),
                        _StatCol('REMAINING', '${loan.remainingEmis} / ${loan.originalEmis}',
                            AppColors.accentAmber),
                        _StatCol('TOTAL BALANCE', loan.totalRemainingFormatted,
                            loan.isCleared ? AppColors.accentGreen : AppColors.accentRose),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: List.generate(loan.originalEmis.clamp(0, 24), (i) {
                        final paid = i < loan.paidEmis;
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: paid ? AppColors.accentGreen : AppColors.accentRose,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!loan.isCleared)
                          ElevatedButton.icon(
                            onPressed: () => _confirmDelete(
                              context,
                              title: 'Mark 1 EMI Paid?',
                              message:
                                  '${loan.name}: Reduces remaining balance by ${loan.remainingEmis == 1 ? loan.totalRemainingFormatted : loan.emiFormatted}',
                              confirmText: 'Mark EMI Paid',
                              confirmColor: AppColors.accentGreen,
                              onConfirm: () => cubit.markLoanEmiPaid(loan.id),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Mark 1 EMI Paid'),
                          ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _confirmDelete(
                            context,
                            title: 'Remove ${loan.name}?',
                            message: 'Balance: ${loan.totalRemainingFormatted}',
                            onConfirm: () => cubit.removeLoan(loan.id),
                          ),
                          child: const Text('Remove', style: TextStyle(color: AppColors.accentRose)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Personal Payables',
          trailing: TextButton.icon(
            onPressed: () => _showAddPayableSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accentRose),
            label: const Text('Add Payable', style: TextStyle(color: AppColors.accentRose)),
          ),
        ),
        const SizedBox(height: 8),
        ...payables.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DhanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: AppTextStyles.cardTitle),
                            if (p.note.isNotEmpty)
                              Text(p.note, style: AppTextStyles.caption),
                          ],
                        ),
                        Text(
                          p.amountFormatted,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: p.isSettled ? AppColors.accentGreen : AppColors.accentRose,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (!p.isSettled)
                          ElevatedButton(
                            onPressed: () => _showPayPayableSheet(context, p),
                            child: const Text('Record Payment'),
                          ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => cubit.removePayable(p.id),
                          child: const Text('Remove', style: TextStyle(color: AppColors.accentRose)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _showAddLoanSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    final countCtrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add EMI Loan', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Loan Name')),
          const SizedBox(height: 10),
          TextField(
            controller: emiCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monthly EMI (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: countCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Remaining EMIs'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final emi = double.tryParse(emiCtrl.text);
              final cnt = int.tryParse(countCtrl.text);
              if (nameCtrl.text.trim().isEmpty || emi == null || cnt == null) return;
              context.read<DhanflowCubit>().addLoan(
                    name: nameCtrl.text,
                    emiAmountPaise: PaiseMath.rupeesToPaise(emi),
                    remainingEmis: cnt,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Loan'),
          ),
        ],
      );
    });
  }

  void _showAddPayableSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Personal Payable', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount Owed (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note')),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (nameCtrl.text.trim().isEmpty || amt == null) return;
              context.read<DhanflowCubit>().addPersonalPayable(
                    name: nameCtrl.text,
                    amountPaise: PaiseMath.rupeesToPaise(amt),
                    note: noteCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Payable'),
          ),
        ],
      );
    });
  }

  void _showPayPayableSheet(BuildContext context, PersonalPayableModel p) {
    final amtCtrl = TextEditingController(text: (p.amountPaise / 100.0).toStringAsFixed(2));
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pay ${p.name}', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text('Pending: ${p.amountFormatted}', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount Paid (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (amt == null || amt <= 0) return;
              context.read<DhanflowCubit>().payPersonalPayable(p.id, PaiseMath.rupeesToPaise(amt));
              Navigator.pop(ctx);
            },
            child: const Text('Record Payment'),
          ),
        ],
      );
    });
  }
}

// ── DEBT FREEDOM ENGINE VIEW ────────────────────────────────────────────────

class _DebtFreedomEngineView extends StatelessWidget {
  final DhanflowViewState state;
  const _DebtFreedomEngineView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DhanflowCubit>();
    final plan = state.payoffPlan;
    final budgetRupees = (state.appState.settings.monthlyPaymentCapacityPaise / 100.0).clamp(5000.0, 150000.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        DhanCard(
          borderColor: AppColors.accentGreen.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Strategy Selection', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in [
                    ('snowball', '❄️ Snowball (Smallest First)'),
                    ('avalanche', '🔥 Avalanche (Highest APR)'),
                    ('custom', '⚡ Custom Order'),
                  ])
                    ChoiceChip(
                      label: Text(s.$2),
                      selected: plan.strategy == s.$1,
                      selectedColor: AppColors.accentGreen,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: plan.strategy == s.$1 ? Colors.black : AppColors.textSecondary,
                      ),
                      onSelected: (_) => cubit.updateDebtEngine(strategy: s.$1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Repayment Budget',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    INRFormatter.formatPaise(state.appState.settings.monthlyPaymentCapacityPaise),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accentGreen),
                  ),
                ],
              ),
              Slider(
                value: budgetRupees,
                min: 5000,
                max: 150000,
                divisions: 29,
                activeColor: AppColors.accentGreen,
                onChanged: (v) =>
                    cubit.updateDebtEngine(monthlyBudgetPaise: PaiseMath.rupeesToPaise(v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DhanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payoff Projection', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCol('TOTAL DEBT', INRFormatter.formatPaise(plan.totalDebtPaise),
                      AppColors.accentRose),
                  _StatCol('TIME TO FREEDOM', '${plan.monthsToFreedom} months', AppColors.accentGreen),
                  _StatCol('INTEREST SAVED', INRFormatter.formatPaise(plan.interestSavedPaise),
                      AppColors.accentAmber),
                ],
              ),
              const SizedBox(height: 14),
              if (plan.nextTarget != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greenDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: AppColors.accentGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next Target: ${plan.nextTarget} · Projected Debt-Free: ${plan.debtFreeDate.day}/${plan.debtFreeDate.month}/${plan.debtFreeDate.year}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGreen),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Step-by-Step Clearance Order'),
        const SizedBox(height: 8),
        ...plan.payoffOrder.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DhanCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.bgHover,
                    child: Text('$idx',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentGreen)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.name, style: AppTextStyles.cardTitle),
                        Text(
                          'Balance: ${INRFormatter.formatPaise(step.startingBalancePaise)} · APR ${(step.aprBps / 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    text: 'Month ${step.clearedInMonth}',
                    color: AppColors.accentBlue,
                    bgColor: AppColors.blueDim,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Confirm',
  Color confirmColor = AppColors.accentRose,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard2,
      title: Text(title, style: AppTextStyles.sectionTitle),
      content: Text(message, style: AppTextStyles.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}
