import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/kpi_snapshot.dart';
import '../../models/models.dart';
import '../../widgets/common/dhan_ui.dart';

class OverviewTab extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const OverviewTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final rawName =
        authState is AuthAuthenticated ? (authState.user['name'] as String? ?? '') : '';
    final firstName = rawName.trim().isEmpty ? '' : rawName.trim().split(RegExp(r'\s+')).first;

    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final cubit = context.read<DhanflowCubit>();
        final kpi = state.kpis;
        final plan = state.payoffPlan;
        final hidden = state.hideBalances;
        final width = MediaQuery.of(context).size.width;
        final isDark = context.isDark;

        final grossDebt = kpi.kulDenaPaise;
        final grossAssets = kpi.kulLenaPaise + kpi.gullakAssetPaise;
        final coveragePct = grossDebt > 0
            ? ((grossAssets / grossDebt) * 100).clamp(0.0, 100.0)
            : 100.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            // ── CLEAN GREETING + QUICK PREFERENCES ROW ───────────────
            _GreetingHeader(
              firstName: firstName,
              hidden: hidden,
              onToggleHidden: cubit.toggleHideBalances,
              onToggleLanguage: cubit.toggleLanguage,
            ),
            const SizedBox(height: 14),

            // ── HERO BALANCE CARD ─────────────────────────────────────
            _HeroBalanceCard(
              kpi: kpi,
              hidden: hidden,
              coveragePct: coveragePct,
              onNavigateTab: onNavigateTab,
            ),
            const SizedBox(height: 14),

            // ── QUICK ACTION LAUNCHPAD ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.flash_on_rounded,
                    label: context.tr('ov_pay_due'),
                    color: AppColors.accentGreen,
                    onTap: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: context.tr('ov_add_spend'),
                    color: AppColors.accentRose,
                    onTap: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.handshake_outlined,
                    label: context.tr('ov_kullena'),
                    color: AppColors.accentBlue,
                    onTap: () => onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.diamond_outlined,
                    label: context.tr('ov_add_asset'),
                    color: AppColors.accentAmber,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── FOCUSED 4-TILE BREAKDOWN BENTO ───────────────────────
            Builder(builder: (context) {
              final loansAndOwedPaise = kpi.totalLoanRemainingPaise + kpi.totalPayablesPaise;
              final crossCount = width >= 920 ? 4 : 2;
              final tiles = [
                KPITile(
                  label: context.tr('ov_cc_due'),
                  value: INRFormatter.formatPaise(kpi.totalCCOutstandingPaise),
                  subtitle:
                      '${kpi.clearedCardsCount}/${kpi.totalCardsCount} cleared · ${kpi.overallUtilizationPct.toStringAsFixed(0)}% used',
                  accentColor:
                      kpi.overallUtilizationPct > 50 ? AppColors.accentRose : AppColors.accentBlue,
                  icon: Icons.credit_card_rounded,
                  hidden: hidden,
                  onTap: () => onNavigateTab(1),
                ),
                KPITile(
                  label: context.tr('ov_loans_owed'),
                  value: INRFormatter.formatPaise(loansAndOwedPaise),
                  subtitle: context.tr('ov_loans_owed_sub'),
                  accentColor: AppColors.accentPurple,
                  icon: Icons.account_balance_outlined,
                  hidden: hidden,
                  onTap: () => onNavigateTab(1),
                ),
                KPITile(
                  label: context.tr('ov_net_before_assets'),
                  value: kpi.asalNetDebtFormatted,
                  subtitle: context.tr('ov_net_before_sub'),
                  accentColor: kpi.isNetPositive ? AppColors.accentGreen : AppColors.accentAmber,
                  icon: Icons.balance_rounded,
                  hidden: hidden,
                ),
                KPITile(
                  label: context.tr('ov_my_assets'),
                  value: kpi.totalAssetsFormatted,
                  subtitle: context.tr('ov_my_assets_sub'),
                  accentColor: AppColors.accentAmber,
                  icon: Icons.diamond_outlined,
                  hidden: hidden,
                  onTap: () => onNavigateTab(3),
                ),
              ];
              final rows = <Widget>[];
              for (int i = 0; i < tiles.length; i += crossCount) {
                final rowTiles = <Widget>[];
                for (int j = 0; j < crossCount; j++) {
                  final idx = i + j;
                  rowTiles.add(
                    Expanded(child: idx < tiles.length ? tiles[idx] : const SizedBox.shrink()),
                  );
                  if (j < crossCount - 1) rowTiles.add(const SizedBox(width: 10));
                }
                rows.add(IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: rowTiles),
                ));
                if (i + crossCount < tiles.length) rows.add(const SizedBox(height: 10));
              }
              return Column(children: rows);
            }),
            const SizedBox(height: 8),
            Text(
              context.tr('ov_note'),
              style: TextStyle(fontSize: 10.5, color: context.textTertiary),
            ),
            const SizedBox(height: 16),

            // ── DEBT FREEDOM STRATEGY BANNER ─────────────────────────
            DhanCard(
              borderColor: AppColors.accentGreen.withValues(alpha: 0.35),
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.bgCard,
                        AppColors.greenDim.withValues(alpha: 0.42),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFECFDF5),
                      ],
              ),
              onTap: () => onNavigateTab(1),
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
                    child: const Icon(Icons.bolt_rounded, color: AppColors.accentGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              context.tr('ov_strategy_title'),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: context.textPrimary,
                              ),
                            ),
                            StatusChip(
                              text: plan.strategy.toUpperCase(),
                              color: AppColors.accentGreen,
                              bgColor: context.greenDim,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.monthsToFreedom == 0
                              ? context.tr('ov_all_cleared')
                              : '${context.tr('ov_next_target')}: ${plan.nextTarget ?? '-'} · ${plan.monthsToFreedom} ${context.tr('ov_months_left')} · ${context.tr('ov_saves')} ${hidden ? '₹ ••••' : INRFormatter.formatPaise(plan.interestSavedPaise)}',
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── HEALTH SCORE + LIABILITY CHART (RESPONSIVE) ──────────
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

            // ── SMART FINANCIAL ALERTS ───────────────────────────────
            if (kpi.smartAlerts.isNotEmpty) ...[
              SectionHeader(
                title: context.tr('ov_smart_radar'),
                subtitle: context.tr('ov_smart_radar_sub'),
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
                    borderColor: color.withValues(alpha: 0.30),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alert.message,
                                style: TextStyle(fontSize: 11, color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],

            // ── RECENT ACTIVITY FEED ────────────────────────────────
            SectionHeader(
              title: context.tr('ov_recent_activity'),
              subtitle: context.tr('ov_recent_sub'),
              trailing: TextButton.icon(
                onPressed: () => onNavigateTab(4),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accentGreen),
                label: Text(
                  context.tr('ov_see_all'),
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            DhanCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: state.appState.activityLog.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          context.tr('ov_no_activity'),
                          style: TextStyle(fontSize: 12, color: context.textTertiary),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < state.appState.activityLog.take(5).length; i++) ...[
                          if (i > 0) Divider(height: 1, color: context.border.withValues(alpha: 0.7)),
                          _ActivityFeedRow(
                            entry: state.appState.activityLog[i],
                            hidden: hidden,
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── CLEAN GREETING HEADER ──────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final String firstName;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onToggleLanguage;

  const _GreetingHeader({
    required this.firstName,
    required this.hidden,
    required this.onToggleHidden,
    required this.onToggleLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final greeting = firstName.isEmpty
        ? context.tr('home_hi')
        : '${context.tr('home_hi')}, $firstName';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('home_subtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onToggleLanguage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.border),
            ),
            child: Text(
              context.isHindi ? 'हि / EN' : 'EN / हि',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.accentBlue : const Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: hidden ? 'Show amounts' : 'Hide amounts',
          child: InkWell(
            onTap: onToggleHidden,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgCard : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: context.border),
              ),
              child: Icon(
                hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 16,
                color: context.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── HERO BALANCE CARD ──────────────────────────────────────────────────
class _HeroBalanceCard extends StatelessWidget {
  final KPISnapshot kpi;
  final bool hidden;
  final double coveragePct;
  final ValueChanged<int> onNavigateTab;

  const _HeroBalanceCard({
    required this.kpi,
    required this.hidden,
    required this.coveragePct,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isPositive = kpi.isTruePositive;
    final accent = isPositive ? AppColors.accentGreen : AppColors.accentRose;
    final covColor = coveragePct >= 80
        ? AppColors.accentGreen
        : coveragePct >= 40
            ? AppColors.accentAmber
            : AppColors.accentRose;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.30 : 0.36),
          width: 1.1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.bgCard2,
                  AppColors.bgCard,
                  accent.withValues(alpha: 0.10),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                  accent.withValues(alpha: 0.08),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? accent.withValues(alpha: 0.10) : const Color(0x100F172A),
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
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isPositive ? context.tr('ov_positive') : context.tr('ov_liability'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: covColor.withValues(alpha: isDark ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${coveragePct.toStringAsFixed(0)}% ${context.tr('ov_covered_short')}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: covColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            context.tr('ov_true_net_pos'),
            style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hidden ? '₹ • • • • • •' : kpi.trueNetFormatted,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
                color: context.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: coveragePct / 100.0,
              minHeight: 5,
              backgroundColor: context.border,
              valueColor: AlwaysStoppedAnimation<Color>(covColor),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _PillBox(
                  label: context.tr('ov_kul_dena'),
                  value: hidden ? '₹ ••••' : kpi.kulDenaFormatted,
                  color: AppColors.accentRose,
                  onTap: () => onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillBox(
                  label: context.tr('ov_kul_lena'),
                  value: hidden ? '₹ ••••' : kpi.kulLenaFormatted,
                  color: AppColors.accentGreen,
                  onTap: () => onNavigateTab(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillBox(
                  label: context.tr('ov_my_assets'),
                  value: hidden ? '₹ ••••' : kpi.totalAssetsFormatted,
                  color: AppColors.accentAmber,
                  onTap: () => onNavigateTab(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _PillBox({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgPrimary.withValues(alpha: 0.65) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── QUICK ACTION BUTTON ────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HEALTH SCORE CARD ──────────────────────────────────────────────────
class _HealthScoreCard extends StatelessWidget {
  final KPISnapshot kpi;
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
                      value: hs.score / 100.0,
                      strokeWidth: 7,
                      backgroundColor: context.border,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                    Center(
                      child: Text(
                        '${hs.score}',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: ringColor,
                        ),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tr('ov_health_title'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        StatusChip(
                          text: hs.ratingLabel,
                          color: ringColor,
                          bgColor: ringColor.withValues(alpha: context.isDark ? 0.16 : 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hs.disclaimer,
                      style: TextStyle(fontSize: 10, color: context.textTertiary),
                    ),
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
                      Expanded(
                        child: Text(
                          b.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${b.score}/${b.max}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
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

// ── LIABILITY BAR CHART CARD ───────────────────────────────────────────
class _LiabilityChartCard extends StatelessWidget {
  final KPISnapshot kpi;
  final bool hidden;
  const _LiabilityChartCard({required this.kpi, required this.hidden});

  @override
  Widget build(BuildContext context) {
    final items = [
      (context.tr('chart_cc'), kpi.totalCCOutstandingPaise, AppColors.accentRose),
      (context.tr('chart_loans'), kpi.totalLoanRemainingPaise, AppColors.accentBlue),
      (context.tr('chart_owed'), kpi.totalPayablesPaise, AppColors.accentPurple),
      (context.tr('chart_lena'), kpi.kulLenaPaise, AppColors.accentGreen),
      (context.tr('chart_assets'), kpi.gullakAssetPaise, AppColors.accentAmber),
    ];

    final maxY = items.map((e) => e.$2 / 100.0).fold<double>(1000, (a, b) => a > b ? a : b) * 1.18;

    return DhanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr('ov_snapshot_title'),
            subtitle: context.tr('ov_snapshot_sub'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: context.border.withValues(alpha: 0.6), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.bgCard2,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = items[group.x];
                      return BarTooltipItem(
                        '${item.$1}\n${hidden ? '₹ ••••••' : INRFormatter.formatPaise(item.$2)}',
                        TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
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
                            style: TextStyle(fontSize: 10, color: context.textSecondary),
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
                        width: 24,
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

class _ActivityFeedRow extends StatelessWidget {
  final ActivityLogModel entry;
  final bool hidden;
  const _ActivityFeedRow({required this.entry, required this.hidden});

  @override
  Widget build(BuildContext context) {
    final eventType = entry.eventType;
    final isCredit = eventType.contains('PAYMENT') || eventType.contains('RECOVERY');
    final isSpend = eventType.contains('SPEND');
    final dotColor = isCredit
        ? AppColors.accentGreen
        : isSpend
            ? AppColors.accentRose
            : AppColors.accentAmber;
    final delta = entry.deltaPaise;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: context.isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isCredit
                  ? Icons.south_west_rounded
                  : isSpend
                      ? Icons.north_east_rounded
                      : Icons.sync_alt_rounded,
              color: dotColor,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (delta != null && delta != 0)
                Text(
                  hidden
                      ? '₹ ••••'
                      : '${delta > 0 ? '+' : ''}${INRFormatter.formatPaise(delta)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: delta > 0 ? AppColors.accentGreen : AppColors.accentRose,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              Text(
                INRFormatter.timeAgo(entry.createdAt),
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
