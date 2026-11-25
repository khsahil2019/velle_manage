import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/models.dart';
import '../../widgets/common/dhan_ui.dart';

class RecoveriesTab extends StatefulWidget {
  const RecoveriesTab({super.key});

  @override
  State<RecoveriesTab> createState() => _RecoveriesTabState();
}

class _RecoveriesTabState extends State<RecoveriesTab> {
  String _filter = 'all'; // all | active | settled

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final recoveries = state.appState.recoveries;
        final cubit = context.read<DhanflowCubit>();
        final hidden = state.hideBalances;
        final isDark = context.isDark;

        final activeList = recoveries.where((r) => !r.isSettled && r.totalPendingPaise > 0).toList();
        final settledList = recoveries.where((r) => r.isSettled || r.totalPendingPaise == 0).toList();
        final filtered = _filter == 'active'
            ? activeList
            : (_filter == 'settled' ? settledList : recoveries);

        final totalOrig = recoveries.fold<int>(0, (s, r) => s + r.totalOriginalPaise);
        final totalPending = state.kpis.kulLenaPaise;
        final totalRecovered = (totalOrig - totalPending).clamp(0, totalOrig);
        final overallPct = totalOrig > 0 ? ((totalRecovered / totalOrig) * 100.0).clamp(0.0, 100.0) : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            // ── HERO KUL LENA RECEIVABLES CONSOLE ───────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: isDark ? 0.35 : 0.42),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.bgCard2,
                          AppColors.bgCard,
                          AppColors.accentGreen.withValues(alpha: 0.10),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF0FDF4),
                          AppColors.accentGreen.withValues(alpha: 0.08),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.accentGreen.withValues(alpha: 0.10)
                        : const Color(0x0E0F172A),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: isDark ? 0.16 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handshake_outlined, size: 12, color: AppColors.accentGreen),
                            SizedBox(width: 5),
                            Text(
                              'KUL LENA · RECEIVABLES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAddBorrowerSheet(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                        label: const Text('Add Person',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Total Pending Receivable',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hidden ? '₹ • • • • • •' : state.kpis.kulLenaFormatted,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: context.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Collection Progress',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      Text(
                        '${overallPct.toStringAsFixed(1)}% recovered (${hidden ? '₹ ••••' : INRFormatter.formatPaise(totalRecovered)})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  UtilizationBar(
                    percentage: overallPct,
                    overrideColor: AppColors.accentGreen,
                    height: 6,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroWell(
                          label: 'Active',
                          value: '${activeList.length} people',
                          color: AppColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroWell(
                          label: 'Settled',
                          value: '${settledList.length} cleared',
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroWell(
                          label: 'Recovered',
                          value: hidden ? '₹ ••••' : INRFormatter.formatPaise(totalRecovered),
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── DOUBLE COUNTING PROTECTION INFO STRIP ───────────────
            DhanCard(
              backgroundColor: context.blueDim.withValues(alpha: isDark ? 0.35 : 0.7),
              borderColor: AppColors.accentBlue.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 17, color: AppColors.accentBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Receivables stay separate from Credit Cards until you apply a received recovery to a card.',
                      style: TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── FILTER CHIPS ────────────────────────────────────────
            Row(
              children: [
                _FilterPill(
                  label: 'All (${recoveries.length})',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Pending (${activeList.length})',
                  selected: _filter == 'active',
                  accent: AppColors.accentAmber,
                  onTap: () => setState(() => _filter = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Settled (${settledList.length})',
                  selected: _filter == 'settled',
                  accent: AppColors.accentGreen,
                  onTap: () => setState(() => _filter = 'settled'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── BORROWER CARDS ──────────────────────────────────────
            if (filtered.isEmpty)
              DhanCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No entries match this filter.',
                      style: TextStyle(fontSize: 13, color: context.textSecondary),
                    ),
                  ),
                ),
              )
            else
              ...filtered.map((rec) {
                final settled = rec.isSettled || rec.totalPendingPaise == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DhanCard(
                    onTap: () => _showEditBorrowerSheet(context, rec),
                    borderColor: settled
                        ? AppColors.accentGreen.withValues(alpha: 0.4)
                        : context.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BankAvatarBadge(name: rec.name, overrideColor: AppColors.accentGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          rec.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.edit_outlined,
                                          size: 13, color: context.textTertiary),
                                    ],
                                  ),
                                  if (rec.note.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      rec.note,
                                      style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                                    ),
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                    color: settled ? AppColors.accentGreen : AppColors.accentGreen,
                                  ),
                                ),
                                Text(
                                  settled ? 'settled' : 'pending',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: settled ? AppColors.accentGreen : context.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (rec.totalOriginalPaise > 0 &&
                            rec.totalPendingPaise < rec.totalOriginalPaise) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Recovery Progress',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${rec.recoveryPct.toStringAsFixed(1)}% recovered',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
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
                            if (!settled)
                              ElevatedButton.icon(
                                onPressed: () => _showRecordRecoverySheet(
                                    context, rec, state.appState.creditCards),
                                icon: const Icon(Icons.bolt_rounded, size: 16),
                                label: const Text('Record Payment Received'),
                              )
                            else
                              StatusChip(
                                text: '✓ SETTLED',
                                color: AppColors.accentGreen,
                                bgColor: context.greenDim,
                              ),
                            OutlinedButton.icon(
                              onPressed: () => _showAddAdvanceSheet(context, rec),
                              icon: const Icon(Icons.add_rounded, size: 15),
                              label: const Text('Lend More'),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'More options',
                              color: context.bgCard2,
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                size: 19,
                                color: context.textTertiary,
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditBorrowerSheet(context, rec);
                                } else if (val == 'delete') {
                                  showProtectedDeleteDialog(
                                    context,
                                    title: 'Remove ${rec.name}?',
                                    message:
                                        'Pending balance: ${rec.pendingFormatted}. This permanently removes ${rec.name} from Kul Lena.',
                                    actionLabel: 'Remove Borrower',
                                    onConfirm: () => cubit.removeRecovery(rec.id),
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16, color: context.textPrimary),
                                      const SizedBox(width: 8),
                                      Text('Edit Borrower & Balance',
                                          style: TextStyle(fontSize: 12, color: context.textPrimary)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_outlined, size: 16, color: AppColors.accentRose),
                                      SizedBox(width: 8),
                                      Text('Remove Borrower',
                                          style: TextStyle(fontSize: 12, color: AppColors.accentRose)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (rec.payments.isNotEmpty) ...[
                          Divider(height: 22, color: context.border),
                          Text(
                            'PAYMENT HISTORY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...rec.payments.take(5).map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      hidden ? '₹ ••••' : p.amountFormatted,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accentGreen,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          p.appliedToCardId != null
                                              ? '${p.note.isEmpty ? 'Payment' : p.note} · Applied to Card'
                                              : (p.note.isEmpty ? 'Received' : p.note),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      INRFormatter.timeAgo(p.paymentDate),
                                      style: TextStyle(fontSize: 10.5, color: context.textTertiary),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                );
              }),
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
        final isDark = ctx.isDark;
        final parsed = double.tryParse(amtCtrl.text);
        final amtPaise = parsed != null ? PaiseMath.rupeesToPaise(parsed) : null;
        final selectedCard = selectedCardId != null
            ? outstandingCards.firstWhere((c) => c.id == selectedCardId)
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recovery from ${rec.name}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
            ),
            const SizedBox(height: 4),
            Text('Pending: ${rec.pendingFormatted}',
                style: TextStyle(fontSize: 12, color: ctx.textSecondary)),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [1000, 2000, 5000, 10000].map((val) {
                return ActionChip(
                  label: Text('+₹$val', style: TextStyle(fontSize: 11, color: ctx.textPrimary)),
                  backgroundColor: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                  side: BorderSide(color: ctx.border),
                  onPressed: () {
                    final cur = double.tryParse(amtCtrl.text) ?? 0;
                    amtCtrl.text = (cur + val).toStringAsFixed(0);
                    setSheetState(() {});
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (e.g. UPI / Cash / Bank Transfer)'),
            ),
            const SizedBox(height: 12),
            if (outstandingCards.isNotEmpty)
              DhanCard(
                backgroundColor: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Apply Received Recovery Directly to a Credit Card',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ctx.textPrimary,
                        ),
                      ),
                      value: linkToCard,
                      activeTrackColor: AppColors.accentGreen,
                      onChanged: (v) => setSheetState(() => linkToCard = v),
                    ),
                    if (linkToCard)
                      DropdownButtonFormField<String>(
                        initialValue: selectedCardId,
                        isExpanded: true,
                        dropdownColor: ctx.bgCard2,
                        items: outstandingCards
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    '${c.name} (${c.outstandingFormatted} due)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: ctx.textPrimary),
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
                backgroundColor: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
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
                            style: TextStyle(fontSize: 11.5, color: ctx.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          INRFormatter.formatPaise(
                              (rec.totalPendingPaise - amtPaise).clamp(0, rec.totalPendingPaise)),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentGreen,
                          ),
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
                              style: TextStyle(fontSize: 11.5, color: ctx.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            INRFormatter.formatPaise((selectedCard.outstandingPaise - amtPaise)
                                .clamp(0, selectedCard.totalLimitPaise)),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentGreen,
                            ),
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

  void _showAddAdvanceSheet(BuildContext context, RecoveryModel rec) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lend More to ${rec.name}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Current pending: ${rec.pendingFormatted}',
            style: TextStyle(fontSize: 12, color: ctx.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Additional Amount Given (₹)',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason / Note (optional)',
              hintText: 'e.g. UPI transfer, EMI advance',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(amtCtrl.text);
              if (v == null || v <= 0) return;
              context.read<DhanflowCubit>().addAdvanceToRecovery(
                    recoveryId: rec.id,
                    additionalAmountPaise: PaiseMath.rupeesToPaise(v),
                    note: noteCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add to Pending Receivable'),
          ),
        ],
      );
    });
  }

  void _showEditBorrowerSheet(BuildContext context, RecoveryModel rec) {
    final nameCtrl = TextEditingController(text: rec.name);
    final amtCtrl = TextEditingController(
      text: (rec.totalPendingPaise / 100.0).toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController(text: rec.note);

    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit ${rec.name}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
                ),
              ),
              IconButton(
                tooltip: 'Remove borrower',
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                onPressed: () {
                  Navigator.pop(ctx);
                  showProtectedDeleteDialog(
                    context,
                    title: 'Remove ${rec.name}?',
                    message: 'Pending balance: ${rec.pendingFormatted}. This removes ${rec.name} from Kul Lena.',
                    actionLabel: 'Remove Borrower',
                    onConfirm: () => context.read<DhanflowCubit>().removeRecovery(rec.id),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Borrower Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Current Pending Balance (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Breakdown / Note'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (nameCtrl.text.trim().isEmpty || amt == null || amt < 0) return;
              context.read<DhanflowCubit>().updateBorrowerDetails(
                    recoveryId: rec.id,
                    name: nameCtrl.text,
                    newPendingPaise: PaiseMath.rupeesToPaise(amt),
                    note: noteCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ],
      );
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
          Text(
            'Add Borrower (Kul Lena)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Borrower Name'),
          ),
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

class _HeroWell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroWell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.bgPrimary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: context.textTertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.accent = AppColors.accentGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
              : (isDark ? AppColors.bgCard : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent : context.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? accent : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
