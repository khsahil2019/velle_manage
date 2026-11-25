import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/models.dart';
import '../../widgets/common/dhan_ui.dart';

class RecoveriesTab extends StatelessWidget {
  const RecoveriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final recoveries = state.appState.recoveries;
        final cubit = context.read<DhanflowCubit>();
        final hidden = state.hideBalances;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            SectionHeader(
              title: 'Kul Lena — Pending Recoveries',
              subtitle:
                  'Total Receivable: ${hidden ? '₹ ••••••' : state.kpis.kulLenaFormatted} across ${recoveries.length} people',
              trailing: ElevatedButton.icon(
                onPressed: () => _showAddBorrowerSheet(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                label: const Text('Add'),
              ),
            ),
            const SizedBox(height: 10),
            DhanCard(
              backgroundColor: AppColors.blueDim.withValues(alpha: 0.35),
              borderColor: AppColors.accentBlue.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 18, color: AppColors.accentBlue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Double-counting protection: Receivables (like Sakshi) stay separate from Credit Cards until you explicitly apply a payment.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...recoveries.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DhanCard(
                    borderColor: rec.isSettled
                        ? AppColors.accentGreen.withValues(alpha: 0.35)
                        : AppColors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BankAvatarBadge(name: rec.name, overrideColor: AppColors.accentGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  if (rec.note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(rec.note, style: AppTextStyles.caption),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  hidden ? '₹ ••••••' : rec.pendingFormatted,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                                Text(
                                  rec.isSettled ? 'settled' : 'pending',
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (rec.totalOriginalPaise > 0 &&
                            rec.totalPendingPaise < rec.totalOriginalPaise) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text('Recovery Progress',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption),
                              ),
                              const SizedBox(width: 8),
                              Text('${rec.recoveryPct.toStringAsFixed(1)}% recovered',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentGreen)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          UtilizationBar(
                            percentage: rec.recoveryPct,
                            overrideColor: AppColors.accentGreen,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (!rec.isSettled)
                              ElevatedButton.icon(
                                onPressed: () => _showRecordRecoverySheet(
                                    context, rec, state.appState.creditCards),
                                icon: const Icon(Icons.bolt_rounded, size: 16),
                                label: const Text('Record Payment Received'),
                              )
                            else
                              const StatusChip(
                                text: '✓ SETTLED',
                                color: AppColors.accentGreen,
                                bgColor: AppColors.greenDim,
                              ),
                            TextButton(
                              onPressed: () => cubit.removeRecovery(rec.id),
                              child: const Text('Remove',
                                  style: TextStyle(color: AppColors.accentRose)),
                            ),
                          ],
                        ),
                        if (rec.payments.isNotEmpty) ...[
                          const Divider(height: 20),
                          const Text('Payment History', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          ...rec.payments.take(4).map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(hidden ? '₹ ••••' : p.amountFormatted,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accentGreen)),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          p.appliedToCardId != null
                                              ? '${p.note} (Applied to Card)'
                                              : p.note,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ),
                                    Text(INRFormatter.timeAgo(p.paymentDate),
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  void _showRecordRecoverySheet(
    BuildContext context,
    RecoveryModel rec,
    List<CreditCardModel> cards,
  ) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final outstandingCards = cards.where((c) => !c.isCleared).toList();
    bool linkToCard = false;
    String? selectedCardId = outstandingCards.isNotEmpty ? outstandingCards.first.id : null;

    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final parsed = double.tryParse(amtCtrl.text);
        final amtPaise = parsed != null ? PaiseMath.rupeesToPaise(parsed) : null;
        final selectedCard = selectedCardId != null
            ? outstandingCards.firstWhere((c) => c.id == selectedCardId)
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Recovery from ${rec.name}', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text('Pending: ${rec.pendingFormatted}', style: AppTextStyles.caption),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => setSheetState(() {}),
              decoration: InputDecoration(
                labelText: 'Amount Received (₹)',
                prefixText: '₹ ',
                suffixIcon: TextButton(
                  onPressed: () {
                    amtCtrl.text = (rec.totalPendingPaise / 100.0).toStringAsFixed(2);
                    setSheetState(() {});
                  },
                  child: const Text('FULL'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (e.g. UPI / Cash)'),
            ),
            const SizedBox(height: 12),
            if (outstandingCards.isNotEmpty)
              DhanCard(
                backgroundColor: AppColors.bgHover,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Apply Received Recovery Directly to a Credit Card',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      value: linkToCard,
                      activeTrackColor: AppColors.accentGreen,
                      onChanged: (v) => setSheetState(() => linkToCard = v),
                    ),
                    if (linkToCard)
                      DropdownButtonFormField<String>(
                        initialValue: selectedCardId,
                        isExpanded: true,
                        dropdownColor: AppColors.bgCard2,
                        items: outstandingCards
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    '${c.name} (${c.outstandingFormatted} due)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setSheetState(() => selectedCardId = v),
                        decoration: const InputDecoration(labelText: 'Target Credit Card'),
                      ),
                  ],
                ),
              ),
            if (amtPaise != null && amtPaise > 0) ...[
              const SizedBox(height: 10),
              DhanCard(
                backgroundColor: AppColors.bgHover,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${rec.name} Pending After',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          INRFormatter.formatPaise(
                              (rec.totalPendingPaise - amtPaise).clamp(0, rec.totalPendingPaise)),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: AppColors.accentGreen),
                        ),
                      ],
                    ),
                    if (linkToCard && selectedCard != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${selectedCard.name} Outstanding After',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            INRFormatter.formatPaise((selectedCard.outstandingPaise - amtPaise)
                                .clamp(0, selectedCard.totalLimitPaise)),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                if (amtPaise == null || amtPaise <= 0) return;
                context.read<DhanflowCubit>().recordRecoveryPayment(
                      recoveryId: rec.id,
                      amountPaise: amtPaise,
                      note: noteCtrl.text,
                      linkedCardId: linkToCard ? selectedCardId : null,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Record Recovery'),
            ),
          ],
        );
      });
    });
  }

  void _showAddBorrowerSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Borrower (Kul Lena)', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Borrower Name')),
          const SizedBox(height: 10),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Pending Amount (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note')),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (nameCtrl.text.trim().isEmpty || amt == null || amt <= 0) return;
              context.read<DhanflowCubit>().addBorrower(
                    name: nameCtrl.text,
                    amountPaise: PaiseMath.rupeesToPaise(amt),
                    note: noteCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Borrower'),
          ),
        ],
      );
    });
  }
}
