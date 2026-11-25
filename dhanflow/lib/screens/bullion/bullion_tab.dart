import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/kpi_snapshot.dart';
import '../../models/models.dart';
import '../../widgets/common/dhan_ui.dart';

class BullionTab extends StatelessWidget {
  const BullionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final kpi = state.kpis;
        final txns = state.appState.bullionTransactions;
        final hidden = state.hideBalances;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            SectionHeader(
              title: 'Gullak Bullion Portfolio',
              subtitle:
                  'Gold ${kpi.goldStats.totalGramsFormatted} · Silver ${kpi.silverStats.totalGramsFormatted}',
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber),
                onPressed: () => _showAddBullionSheet(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Buy'),
              ),
            ),
            const SizedBox(height: 12),
            _MetalSummaryCard(
              title: 'Gold 24K',
              emoji: '🥇',
              accentColor: AppColors.accentAmber,
              stats: kpi.goldStats,
              txns: txns.where((t) => t.metal == 'gold').toList(),
              hidden: hidden,
            ),
            const SizedBox(height: 14),
            _MetalSummaryCard(
              title: 'Silver',
              emoji: '🥈',
              accentColor: AppColors.textSecondary,
              stats: kpi.silverStats,
              txns: txns.where((t) => t.metal == 'silver').toList(),
              hidden: hidden,
            ),
          ],
        );
      },
    );
  }

  void _showAddBullionSheet(BuildContext context) {
    String metal = 'gold';
    bool rateMode = true;
    final gramsCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final grams = double.tryParse(gramsCtrl.text);
        final inputVal = double.tryParse(valueCtrl.text);

        int? preGstPreview;
        int? gstPreview;
        int? paidPreview;
        int? ratePreview;

        if (grams != null && grams > 0 && inputVal != null && inputVal > 0) {
          final gx = PaiseMath.gramsToX10000(grams);
          if (rateMode) {
            ratePreview = PaiseMath.rupeesToPaise(inputVal);
            preGstPreview = PaiseMath.preGstForGrams(gx, ratePreview);
            gstPreview = PaiseMath.gst3Pct(preGstPreview);
            paidPreview = preGstPreview + gstPreview;
          } else {
            paidPreview = PaiseMath.rupeesToPaise(inputVal);
            preGstPreview = PaiseMath.removeGST3Pct(paidPreview);
            gstPreview = paidPreview - preGstPreview;
            ratePreview = PaiseMath.effectiveCostPerGram(preGstPreview, gx);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Gullak Purchase', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            const Text('Auto-splits 3% GST and updates weighted average cost basis',
                style: AppTextStyles.caption),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('🥇 Gold 24K'),
                    selected: metal == 'gold',
                    selectedColor: AppColors.accentAmber,
                    labelStyle: TextStyle(
                        color: metal == 'gold' ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.w700),
                    onSelected: (_) => setSheetState(() => metal = 'gold'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('🥈 Silver'),
                    selected: metal == 'silver',
                    selectedColor: AppColors.textSecondary,
                    labelStyle: TextStyle(
                        color: metal == 'silver' ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.w700),
                    onSelected: (_) => setSheetState(() => metal = 'silver'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: gramsCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setSheetState(() {}),
              decoration: const InputDecoration(labelText: 'Grams (e.g. 0.2500)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Pre-GST Rate/gm'),
                      ),
                    ),
                    selected: rateMode,
                    selectedColor: AppColors.accentGreen,
                    labelStyle: TextStyle(
                        fontSize: 11,
                        color: rateMode ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.w700),
                    onSelected: (_) => setSheetState(() => rateMode = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Total Paid (Incl. GST)'),
                      ),
                    ),
                    selected: !rateMode,
                    selectedColor: AppColors.accentGreen,
                    labelStyle: TextStyle(
                        fontSize: 11,
                        color: !rateMode ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.w700),
                    onSelected: (_) => setSheetState(() => rateMode = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setSheetState(() {}),
              decoration: InputDecoration(
                labelText: rateMode ? 'Buy Rate per gram (Pre-GST ₹)' : 'Total Cash Paid (₹)',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null && ctx.mounted) {
                  setSheetState(() {
                    selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      selectedDate.hour,
                      selectedDate.minute,
                    );
                  });
                }
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 15),
              label: Text(
                'Purchase Date: ${INRFormatter.formatDateTime(selectedDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (paidPreview != null &&
                preGstPreview != null &&
                gstPreview != null &&
                ratePreview != null) ...[
              const SizedBox(height: 10),
              DhanCard(
                backgroundColor: AppColors.bgHover,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _PreviewRow('Pre-GST Rate', INRFormatter.formatRatePerGm(ratePreview)),
                    _PreviewRow('Pre-GST Value', INRFormatter.formatPaise(preGstPreview)),
                    _PreviewRow('3% GST', INRFormatter.formatPaise(gstPreview),
                        color: AppColors.accentRose),
                    _PreviewRow('Total Cash Paid', INRFormatter.formatPaise(paidPreview),
                        color: AppColors.accentAmber),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber),
              onPressed: () {
                if (grams == null || grams <= 0 || inputVal == null || inputVal <= 0) return;
                context.read<DhanflowCubit>().addBullionPurchase(
                      metal: metal,
                      gramsX10000: PaiseMath.gramsToX10000(grams),
                      buyRatePaise: rateMode ? PaiseMath.rupeesToPaise(inputVal) : null,
                      totalPaidPaise: !rateMode ? PaiseMath.rupeesToPaise(inputVal) : null,
                      purchaseDate: selectedDate,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add Purchase'),
            ),
          ],
        );
      });
    });
  }
}

class _MetalSummaryCard extends StatefulWidget {
  final String title;
  final String emoji;
  final Color accentColor;
  final BullionStats stats;
  final List<BullionTransactionModel> txns;
  final bool hidden;

  const _MetalSummaryCard({
    required this.title,
    required this.emoji,
    required this.accentColor,
    required this.stats,
    required this.txns,
    required this.hidden,
  });

  @override
  State<_MetalSummaryCard> createState() => _MetalSummaryCardState();
}

class _MetalSummaryCardState extends State<_MetalSummaryCard> {
  late final TextEditingController _sellCtrl;

  @override
  void initState() {
    super.initState();
    _sellCtrl = TextEditingController(
      text: widget.stats.currentSellPricePaise != null
          ? (widget.stats.currentSellPricePaise! / 100.0).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _sellCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final pl = s.unrealisedPLPaise;
    final sellVal = s.currentSellValuePaise;
    final cubit = context.read<DhanflowCubit>();
    final h = widget.hidden;

    return DhanCard(
      borderColor: widget.accentColor.withValues(alpha: 0.25),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.bgCard,
          widget.accentColor.withValues(alpha: 0.06),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.emoji} ${widget.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: widget.accentColor),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                text: s.totalGramsFormatted,
                color: widget.accentColor,
                bgColor: widget.accentColor.withValues(alpha: 0.14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell('Avg Buy (Pre-GST)', h ? '₹ •••••' : s.avgRateFormatted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    _MetricCell('Effective Cost (Incl. GST)', h ? '₹ •••••' : s.effectiveCostFormatted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell('Pre-GST Asset Value', h ? '₹ •••••' : s.assetValueFormatted,
                    color: AppColors.accentGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCell('Total Cash Paid', h ? '₹ •••••' : s.totalPaidFormatted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell('Total 3% GST Paid', h ? '₹ •••' : s.gstPaidFormatted,
                    color: AppColors.accentRose),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCell('Break-Even Sell/gm', h ? '₹ •••••' : s.effectiveCostFormatted,
                    color: AppColors.accentAmber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgHover,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📈 Live Gullak Sell Price Simulator',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'Enter platform live sell price (/gm). Break-even accounts for purchase GST; check platform spread before selling.',
                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sellCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    cubit.updateSellPrice(
                      s.metal,
                      parsed != null && parsed > 0 ? PaiseMath.rupeesToPaise(parsed) : null,
                    );
                  },
                  decoration: const InputDecoration(
                    labelText: 'Current Gullak Sell Price (/gm)',
                    prefixText: '₹ ',
                  ),
                ),
                if (pl != null && sellVal != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('EST. SELL VALUE', style: AppTextStyles.label),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(h ? '₹ •••••' : INRFormatter.formatPaise(sellVal),
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('UNREALISED P/L', style: AppTextStyles.label),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                h
                                    ? '₹ ••••'
                                    : '${pl >= 0 ? '+' : ''}${INRFormatter.formatPaise(pl)} (${s.returnPct?.toStringAsFixed(2) ?? '0.00'}%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: pl >= 0 ? AppColors.accentGreen : AppColors.accentRose,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Purchase History', style: AppTextStyles.label),
          const SizedBox(height: 6),
          if (widget.txns.isEmpty)
            const Text('No purchases logged yet.', style: AppTextStyles.caption)
          else
            ...widget.txns.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${t.gramsFormatted} @ ${h ? '₹ •••••' : t.rateFormatted}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(
                              '${INRFormatter.formatDateTime(t.purchaseDate)} · Pre-GST ${h ? '₹ ••••' : t.preGstFormatted} + GST ${h ? '₹ ••' : t.gstFormatted}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(h ? '₹ ••••' : t.totalPaidFormatted,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      PopupMenuButton<String>(
                        tooltip: 'Transaction options',
                        color: AppColors.bgCard2,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        onSelected: (val) {
                          if (val == 'delete') {
                            showProtectedDeleteDialog(
                              context,
                              title: 'Remove ${t.metal.toUpperCase()} Transaction?',
                              message:
                                  '${t.gramsFormatted} purchased on ${INRFormatter.formatDateTime(t.purchaseDate)} (Paid ${t.totalPaidFormatted}).',
                              actionLabel: 'Delete Entry',
                              onConfirm: () => cubit.deleteBullionTransaction(t.id),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 16, color: AppColors.accentRose),
                                SizedBox(width: 8),
                                Text('Remove Transaction',
                                    style: TextStyle(fontSize: 12, color: AppColors.accentRose)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricCell(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color ?? AppColors.textPrimary)),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _PreviewRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
