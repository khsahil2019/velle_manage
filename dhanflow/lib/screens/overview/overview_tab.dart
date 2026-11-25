import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../widgets/common/dhan_ui.dart';

class OverviewTab extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const OverviewTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final cubit = context.read<DhanflowCubit>();
        final kpi = state.kpis;
        final plan = state.payoffPlan;
        final hidden = state.hideBalances;
        final width = MediaQuery.of(context).size.width;
        final crossCount = width >= 920 ? 3 : 2;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // Hero Financial Command Card
            HeroCommandCard(
              title: 'True Net Liability (After Bullion Cost Basis)',
              mainValue: kpi.trueNetFormatted,
              subtitle:
                  'Net before bullion: ${hidden ? '₹ ••••••' : kpi.asalNetDebtFormatted} · Direct pocket card debt: ${hidden ? '₹ ••••••' : kpi.pocketDebtFormatted}',
              isPositive: kpi.isTruePositive,
              hidden: hidden,
              onToggleHidden: cubit.toggleHideBalances,
              pills: [
                (label: 'Kul Dena', value: kpi.kulDenaFormatted, color: AppColors.accentRose),
                (label: 'Kul Lena', value: kpi.kulLenaFormatted, color: AppColors.accentGreen),
                (label: 'Bullion Basis', value: kpi.gullakAssetFormatted, color: AppColors.accentAmber),
              ],
            ),
            const SizedBox(height: 14),

            // 6-Tile KPI Breakdown Grid
            GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: width >= 600 ? 2.15 : 1.55,
              children: [
                KPITile(
                  label: 'Kul Dena (Gross)',
                  value: kpi.kulDenaFormatted,
                  subtitle: 'Cards + Loans + Payables',
                  accentColor: AppColors.accentRose,
                  icon: Icons.arrow_upward_rounded,
                  hidden: hidden,
                  onTap: () => onNavigateTab(1),
                ),
                KPITile(
                  label: 'Kul Lena (Receivable)',
                  value: kpi.kulLenaFormatted,
                  subtitle:
                      '${state.appState.recoveries.where((r) => !r.isSettled).length} active borrowers',
                  accentColor: AppColors.accentGreen,
                  icon: Icons.arrow_downward_rounded,
                  hidden: hidden,
                  onTap: () => onNavigateTab(2),
                ),
                KPITile(
                  label: 'Net Before Bullion',
                  value: kpi.asalNetDebtFormatted,
                  subtitle: 'Kul Dena − Kul Lena',
                  accentColor: kpi.isNetPositive ? AppColors.accentGreen : AppColors.accentAmber,
                  icon: Icons.balance_rounded,
                  hidden: hidden,
                ),
                KPITile(
                  label: 'Bullion Cost Basis',
                  value: kpi.gullakAssetFormatted,
                  subtitle: 'Pre-GST acquisition basis',
                  accentColor: AppColors.accentAmber,
                  icon: Icons.workspace_premium_rounded,
                  hidden: hidden,
                  onTap: () => onNavigateTab(3),
                ),
                KPITile(
                  label: 'True Net Liability',
                  value: kpi.trueNetFormatted,
                  subtitle: 'After bullion cost basis',
                  accentColor: kpi.isTruePositive ? AppColors.accentGreen : AppColors.accentRose,
                  icon: Icons.shield_outlined,
                  hidden: hidden,
                ),
                KPITile(
                  label: 'Pocket Card Debt',
                  value: kpi.pocketDebtFormatted,
                  subtitle: 'Excl. SBI (${kpi.clearedCardsCount}/${kpi.totalCardsCount} cleared)',
                  accentColor: AppColors.accentBlue,
                  icon: Icons.credit_card_rounded,
                  hidden: hidden,
                  onTap: () => onNavigateTab(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Bullion Cost Basis reflects pre-GST purchase value, not guaranteed liquidation value.',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),

            // Debt Freedom Engine Banner
            DhanCard(
              borderColor: AppColors.accentGreen.withValues(alpha: 0.35),
              gradient: LinearGradient(
                colors: [
                  AppColors.bgCard,
                  AppColors.greenDim.withValues(alpha: 0.35),
                ],
              ),
              onTap: () => onNavigateTab(1),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.greenDim,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: AppColors.accentGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Debt Freedom Engine',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(
                              text: plan.strategy.toUpperCase(),
                              color: AppColors.accentGreen,
                              bgColor: AppColors.greenDim,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.monthsToFreedom == 0
                              ? 'All tracked debts are cleared!'
                              : 'Next Target: ${plan.nextTarget ?? '-'} · ${plan.monthsToFreedom} mos to freedom · Saves ${hidden ? '₹ ••••' : INRFormatter.formatPaise(plan.interestSavedPaise)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Responsive Side-by-Side Health Score + Chart on Wide Screens
            if (width >= 780)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _HealthScoreCard(kpi: kpi)),
                  const SizedBox(width: 14),
                  Expanded(child: _LiabilityChartCard(kpi: kpi, hidden: hidden)),
                ],
              )
            else ...[
              _HealthScoreCard(kpi: kpi),
              const SizedBox(height: 14),
              _LiabilityChartCard(kpi: kpi, hidden: hidden),
            ],
            const SizedBox(height: 16),

            if (kpi.smartAlerts.isNotEmpty) ...[
              const SectionHeader(
                title: 'Smart Financial Alerts',
                subtitle: 'Live thresholds across cards, loans, and bullion',
              ),
              const SizedBox(height: 10),
              ...kpi.smartAlerts.map((alert) {
                final Color color;
                final IconData icon;
                switch (alert.severity) {
                  case 'high':
                    color = AppColors.accentRose;
                    icon = Icons.warning_amber_rounded;
                    break;
                  case 'positive':
                    color = AppColors.accentGreen;
                    icon = Icons.trending_up_rounded;
                    break;
                  case 'tip':
                    color = AppColors.accentAmber;
                    icon = Icons.lightbulb_outline_rounded;
                    break;
                  default:
                    color = AppColors.accentBlue;
                    icon = Icons.info_outline_rounded;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DhanCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    borderColor: color.withValues(alpha: 0.32),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 17, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alert.title,
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                              const SizedBox(height: 2),
                              Text(alert.message,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            SectionHeader(
              title: 'Recent Activity',
              trailing: TextButton(
                onPressed: () => onNavigateTab(4),
                child: const Text('See All', style: TextStyle(color: AppColors.accentGreen)),
              ),
            ),
            const SizedBox(height: 6),
            DhanCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: state.appState.activityLog.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent activity', style: AppTextStyles.body),
                    )
                  : Column(
                      children: state.appState.activityLog.take(4).map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: e.eventType.contains('PAYMENT') ||
                                          e.eventType.contains('RECOVERY')
                                      ? AppColors.accentGreen
                                      : e.eventType.contains('SPEND')
                                          ? AppColors.accentRose
                                          : AppColors.accentAmber,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                INRFormatter.timeAgo(e.createdAt),
                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
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
}

class _HealthScoreCard extends StatelessWidget {
  final dynamic kpi;
  const _HealthScoreCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final hs = kpi.healthScore;
    final Color ringColor = hs.score >= 70
        ? AppColors.accentGreen
        : hs.score >= 45
            ? AppColors.accentAmber
            : AppColors.accentRose;

    return DhanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (hs.score as int) / 100.0,
                      strokeWidth: 7,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                    Center(
                      child: Text(
                        '${hs.score}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: ringColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text('Financial Health Score', style: AppTextStyles.sectionTitle),
                        ),
                        const SizedBox(width: 6),
                        StatusChip(
                          text: hs.ratingLabel as String,
                          color: ringColor,
                          bgColor: ringColor.withValues(alpha: 0.14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(hs.disclaimer as String,
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...hs.breakdown.map<Widget>((b) {
            final pct = b.max > 0 ? ((b.score / b.max) * 100).toDouble() : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b.label as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text('${b.score}/${b.max}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  UtilizationBar(
                    percentage: pct,
                    overrideColor: pct >= 70
                        ? AppColors.accentGreen
                        : pct >= 40
                            ? AppColors.accentAmber
                            : AppColors.accentRose,
                    height: 4,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LiabilityChartCard extends StatelessWidget {
  final dynamic kpi;
  final bool hidden;
  const _LiabilityChartCard({required this.kpi, required this.hidden});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('CC Debt', kpi.totalCCOutstandingPaise as int, AppColors.accentRose),
      ('Loans', kpi.totalLoanRemainingPaise as int, AppColors.accentBlue),
      ('Payables', kpi.totalPayablesPaise as int, AppColors.accentPurple),
      ('Receivable', kpi.kulLenaPaise as int, AppColors.accentGreen),
      ('Bullion', kpi.gullakAssetPaise as int, AppColors.accentAmber),
    ];

    final maxY = items.map((e) => e.$2 / 100.0).fold<double>(1000, (a, b) => a > b ? a : b) * 1.18;

    return DhanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Balance Sheet Snapshot',
            subtitle: 'Liabilities vs Receivables & Assets (₹)',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 205,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.border.withValues(alpha: 0.6), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgCard2,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = items[group.x];
                      return BarTooltipItem(
                        '${item.$1}\n${hidden ? '₹ ••••••' : INRFormatter.formatPaise(item.$2)}',
                        const TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            items[idx].$1,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: items.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.$2 / 100.0,
                        width: 26,
                        color: entry.value.$3,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
