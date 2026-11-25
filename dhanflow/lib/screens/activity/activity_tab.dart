import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/models.dart';
import '../../widgets/common/dhan_ui.dart';

/// Pure Activity & Audit Log Screen — records all local JSON, card, loan, recovery, and asset events.
class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  String _filter = 'all'; // all | cards | loans | recoveries | assets | system
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilter(ActivityLogModel entry) {
    final t = entry.eventType.toUpperCase();
    switch (_filter) {
      case 'cards':
        return t.startsWith('CC_');
      case 'loans':
        return t.contains('LOAN') || t.contains('PAYABLE');
      case 'recoveries':
        return t.contains('RECOVERY');
      case 'assets':
        return t.contains('BULLION') || t.contains('ASSET');
      case 'system':
        return t == 'IMPORT' || t == 'EXPORT' || t == 'SYSTEM';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final cubit = context.read<DhanflowCubit>();
        final allLogs = state.appState.activityLog;
        final hidden = state.hideBalances;
        final isDark = context.isDark;

        final filteredLogs = allLogs.where((entry) {
          if (!_matchesFilter(entry)) return false;
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            final descMatch = entry.description.toLowerCase().contains(q);
            final typeMatch = entry.eventType.toLowerCase().contains(q);
            final entityMatch = (entry.relatedEntityName ?? '').toLowerCase().contains(q);
            if (!descMatch && !typeMatch && !entityMatch) return false;
          }
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            // ── HEADER BANNER ───────────────────────────────────────
            DhanCard(
              borderColor: AppColors.accentGreen.withValues(alpha: 0.30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.bgCard2,
                        AppColors.bgCard,
                        AppColors.accentGreen.withValues(alpha: 0.08),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF0FDF4),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.greenDim,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppColors.accentGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity & Audit Trail',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${allLogs.length} events logged across cards, assets, recoveries & local JSON',
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (state.canUndo) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentAmber,
                        side: BorderSide(color: AppColors.accentAmber.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => cubit.undoLastAction(),
                      icon: const Icon(Icons.undo_rounded, size: 15),
                      label: const Text('Undo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── SEARCH BAR ──────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search activities, cards, assets or events...',
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.textTertiary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 16, color: context.textTertiary),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── FILTER PILLS ────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _LogFilterChip(
                    label: 'All Logs',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 6),
                  _LogFilterChip(
                    label: 'Cards',
                    selected: _filter == 'cards',
                    color: AppColors.accentRose,
                    onTap: () => setState(() => _filter = 'cards'),
                  ),
                  const SizedBox(width: 6),
                  _LogFilterChip(
                    label: 'Assets',
                    selected: _filter == 'assets',
                    color: AppColors.accentAmber,
                    onTap: () => setState(() => _filter = 'assets'),
                  ),
                  const SizedBox(width: 6),
                  _LogFilterChip(
                    label: 'Kul Lena',
                    selected: _filter == 'recoveries',
                    color: AppColors.accentGreen,
                    onTap: () => setState(() => _filter = 'recoveries'),
                  ),
                  const SizedBox(width: 6),
                  _LogFilterChip(
                    label: 'Loans & Dues',
                    selected: _filter == 'loans',
                    color: AppColors.accentBlue,
                    onTap: () => setState(() => _filter = 'loans'),
                  ),
                  const SizedBox(width: 6),
                  _LogFilterChip(
                    label: 'Local JSON & System',
                    selected: _filter == 'system',
                    color: AppColors.accentPurple,
                    onTap: () => setState(() => _filter = 'system'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── ACTIVITY TIMELINE LIST ──────────────────────────────
            if (filteredLogs.isEmpty)
              DhanCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 36, color: context.textTertiary),
                      const SizedBox(height: 10),
                      Text(
                        allLogs.isEmpty
                            ? 'No activity recorded yet.'
                            : 'No matching logs for this filter.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Card updates, recoveries, asset additions & local JSON snapshots appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: context.textTertiary),
                      ),
                    ],
                  ),
                ),
              )
            else
              DhanCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: filteredLogs.asMap().entries.map((item) {
                    final idx = item.key;
                    final entry = item.value;
                    final isLast = idx == filteredLogs.length - 1;
                    final meta = _metaForEvent(entry.eventType);

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(bottom: BorderSide(color: context.border, width: 0.8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: isDark ? 0.16 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: meta.color.withValues(alpha: 0.32)),
                            ),
                            child: Icon(meta.icon, size: 17, color: meta.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: meta.color.withValues(alpha: isDark ? 0.15 : 0.10),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        meta.tag,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: meta.color,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      INRFormatter.timeAgo(entry.createdAt),
                                      style: TextStyle(fontSize: 10, color: context.textTertiary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  entry.description,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: entry.isReversed
                                        ? context.textTertiary
                                        : context.textPrimary,
                                    decoration: entry.isReversed
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      INRFormatter.formatDateTime(entry.createdAt),
                                      style: TextStyle(fontSize: 10, color: context.textTertiary),
                                    ),
                                    if (entry.deltaPaise != null && entry.deltaPaise != 0) ...[
                                      const Spacer(),
                                      Text(
                                        hidden
                                            ? '₹ ••••'
                                            : '${entry.deltaPaise! > 0 ? '+' : ''}${INRFormatter.formatPaise(entry.deltaPaise!)}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: meta.color,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  ({Color color, IconData icon, String tag}) _metaForEvent(String eventType) {
    final t = eventType.toUpperCase();
    if (t.contains('PAYMENT') || t.contains('RECOVERY')) {
      return (color: AppColors.accentGreen, icon: Icons.south_west_rounded, tag: t.replaceAll('_', ' '));
    }
    if (t.contains('SPEND') || t.contains('REMOVE')) {
      return (color: AppColors.accentRose, icon: Icons.north_east_rounded, tag: t.replaceAll('_', ' '));
    }
    if (t.contains('BULLION') || t.contains('ASSET')) {
      return (color: AppColors.accentAmber, icon: Icons.diamond_outlined, tag: t.replaceAll('_', ' '));
    }
    if (t.contains('LOAN') || t.contains('PAYABLE')) {
      return (color: AppColors.accentBlue, icon: Icons.account_balance_outlined, tag: t.replaceAll('_', ' '));
    }
    if (t == 'IMPORT' || t == 'EXPORT') {
      return (color: AppColors.accentPurple, icon: Icons.data_object_rounded, tag: 'JSON $t');
    }
    if (t.startsWith('CC_')) {
      return (color: AppColors.accentBlue, icon: Icons.credit_card_rounded, tag: t.replaceAll('_', ' '));
    }
    return (color: AppColors.accentBlue, icon: Icons.bolt_rounded, tag: t.replaceAll('_', ' '));
  }
}

class _LogFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _LogFilterChip({
    required this.label,
    required this.selected,
    this.color = AppColors.accentGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.22 : 0.15)
              : (isDark ? AppColors.bgCard : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : context.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? color : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
