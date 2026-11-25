import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../bullion/bullion_tab.dart';
import '../debt/debt_tab.dart';
import '../overview/overview_tab.dart';
import '../profile/profile_screen.dart';
import '../recoveries/recoveries_tab.dart';
import '../../widgets/common/dhan_ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;
  final ValueNotifier<int> _profileSubTab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _profileSubTab.dispose();
    super.dispose();
  }

  void _openTab(int index, {int profileSubTab = 0}) {
    if (index == 4) {
      _profileSubTab.value = profileSubTab;
    }
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    final isDark = context.isDark;

    return MultiBlocListener(
      listeners: [
        BlocListener<DhanflowCubit, DhanflowViewState>(
          listener: (context, state) {
            if (state.flashMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(
                    state.flashMessage!,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: context.bgCard2,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                ));
              context.read<DhanflowCubit>().clearMessages();
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.accentRose,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                ));
              context.read<DhanflowCubit>().clearMessages();
            }
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) =>
              (prev is! AuthAuthenticated && curr is AuthAuthenticated) ||
              (prev is AuthAuthenticated && curr is AuthOfflineGuest),
          listener: (context, authState) {
            final dhanflow = context.read<DhanflowCubit>();
            if (authState is AuthAuthenticated) {
              dhanflow.handleAuthConnected(
                justSignedUp: authState.justSignedUp,
                uploadLocalOnSignup: authState.uploadLocalOnSignup,
              );
            } else if (authState is AuthOfflineGuest) {
              dhanflow.handleSignedOut();
            }
          },
        ),
      ],
      child: Scaffold(
        extendBody: false,
        appBar: AppBar(
          titleSpacing: 12,
          title: Row(
            children: [
              const TrustvlyLogo(size: 34, borderRadius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trustvly',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      context.tr('app_tagline'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            BlocBuilder<DhanflowCubit, DhanflowViewState>(
              builder: (context, state) {
                final narrow = MediaQuery.of(context).size.width < 430;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SyncStatusPill(status: state.syncStatus, compact: narrow),
                    if (state.canUndo)
                      IconButton(
                        tooltip: 'Undo last action',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.undo_rounded, color: AppColors.accentAmber, size: 19),
                        onPressed: () => context.read<DhanflowCubit>().undoLastAction(),
                      ),
                    IconButton(
                      tooltip: context.isHindi ? 'Switch to English' : 'हिन्दी में बदलें',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.blueDim.withValues(alpha: isDark ? 0.5 : 0.7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          context.isHindi ? 'हि' : 'EN',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                      onPressed: () => context.read<DhanflowCubit>().toggleLanguage(),
                    ),
                    IconButton(
                      tooltip: state.hideBalances ? 'Show amounts' : 'Hide amounts',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        state.hideBalances
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: context.textSecondary,
                        size: 19,
                      ),
                      onPressed: () => context.read<DhanflowCubit>().toggleHideBalances(),
                    ),
                    IconButton(
                      tooltip: isDark ? 'White Mode' : 'Dark Mode',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? AppColors.accentAmber : const Color(0xFF6366F1),
                        size: 19,
                      ),
                      onPressed: () => context.read<DhanflowCubit>().toggleThemeMode(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10, left: 4),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, authState) {
                          final initials =
                              authState is AuthAuthenticated ? authState.initials : 'P';
                          return InkWell(
                            onTap: () => _openTab(4, profileSubTab: 0),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: context.greenDim,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.accentGreen.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentGreen,
                                    ),
                                  ),
                                  if (MediaQuery.of(context).size.width >= 540 &&
                                      authState is AuthAuthenticated) ...[
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 86),
                                      child: Text(
                                        (authState.user['name'] as String? ?? 'Profile')
                                            .split(' ')
                                            .first,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: context.border),
          ),
        ),
        body: Row(
          children: [
            if (isWide)
              Container(
                decoration: BoxDecoration(
                  color: context.bgCard,
                  border: Border(right: BorderSide(color: context.border)),
                ),
                child: NavigationRail(
                  backgroundColor: context.bgCard,
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (i) => _openTab(i),
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: context.greenDim,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(
                        Icons.dashboard_rounded,
                        color: isDark ? AppColors.accentGreen : const Color(0xFF059669),
                      ),
                      label: Text(context.tr('nav_home')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.credit_card_outlined),
                      selectedIcon: Icon(
                        Icons.credit_card_rounded,
                        color: isDark ? AppColors.accentGreen : const Color(0xFF059669),
                      ),
                      label: Text(context.tr('nav_debt')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.handshake_outlined),
                      selectedIcon: Icon(
                        Icons.handshake_rounded,
                        color: isDark ? AppColors.accentGreen : const Color(0xFF059669),
                      ),
                      label: Text(context.tr('nav_kullena')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.diamond_outlined),
                      selectedIcon: const Icon(Icons.diamond_rounded, color: AppColors.accentAmber),
                      label: Text(context.tr('nav_assets')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: isDark ? AppColors.accentBlue : const Color(0xFF2563EB),
                      ),
                      label: Text(context.tr('nav_profile')),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: IndexedStack(
                    index: _tabIndex,
                    children: [
                      OverviewTab(
                        onNavigateTab: (i) {
                          if (i == 4) {
                            _openTab(4, profileSubTab: 1);
                          } else {
                            _openTab(i);
                          }
                        },
                      ),
                      const DebtTab(),
                      const RecoveriesTab(),
                      const AssetsTab(),
                      ProfileScreen(subTabNotifier: _profileSubTab),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : _TrustvlyDockedNavBar(
                currentIndex: _tabIndex,
                onTap: (i) => _openTab(i),
              ),
      ),
    );
  }
}

/// Clean docked bottom navigation bar anchored flush to the bottom edge (zero floating/hanging gap).
class _TrustvlyDockedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TrustvlyDockedNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final emerald = isDark ? AppColors.accentGreen : const Color(0xFF059669);
    final blue = isDark ? AppColors.accentBlue : const Color(0xFF2563EB);

    final items = [
      (
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: context.tr('nav_home'),
        color: emerald,
      ),
      (
        icon: Icons.credit_card_outlined,
        activeIcon: Icons.credit_card_rounded,
        label: context.tr('nav_debt'),
        color: emerald,
      ),
      (
        icon: Icons.handshake_outlined,
        activeIcon: Icons.handshake_rounded,
        label: context.tr('nav_kullena'),
        color: emerald,
      ),
      (
        icon: Icons.diamond_outlined,
        activeIcon: Icons.diamond_rounded,
        label: context.tr('nav_assets'),
        color: AppColors.accentAmber,
      ),
      (
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: context.tr('nav_profile'),
        color: blue,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : Colors.white,
        border: Border(
          top: BorderSide(color: context.border, width: 1),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 12,
                  offset: Offset(0, -3),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final selected = idx == currentIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(idx),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Sleek flush top active indicator bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: selected ? 32 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: selected ? item.color : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: selected
                                ? item.color.withValues(alpha: isDark ? 0.16 : 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 20,
                            color: selected ? item.color : context.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                color: selected ? item.color : context.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _SyncStatusPill extends StatelessWidget {
  final CloudSyncStatus status;
  final bool compact;
  const _SyncStatusPill({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String label;

    switch (status) {
      case CloudSyncStatus.synced:
        dotColor = AppColors.accentGreen;
        label = context.tr('synced');
        break;
      case CloudSyncStatus.syncing:
        dotColor = AppColors.accentAmber;
        label = context.tr('syncing');
        break;
      case CloudSyncStatus.error:
        dotColor = AppColors.accentRose;
        label = context.tr('retry');
        break;
      case CloudSyncStatus.offline:
        dotColor = context.textTertiary;
        label = context.tr('local');
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: 'Storage: $label',
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!compact) ...[
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: dotColor)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
