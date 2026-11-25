import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../activity/activity_tab.dart';
import '../auth/auth_screen.dart';
import '../bullion/bullion_tab.dart';
import '../debt/debt_tab.dart';
import '../overview/overview_tab.dart';
import '../recoveries/recoveries_tab.dart';
import '../../widgets/common/dhan_ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;

    return MultiBlocListener(
      listeners: [
        BlocListener<DhanflowCubit, DhanflowViewState>(
          listener: (context, state) {
            if (state.flashMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.flashMessage!),
                  backgroundColor: AppColors.bgCard2,
                  behavior: SnackBarBehavior.floating,
                ));
              context.read<DhanflowCubit>().clearMessages();
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.accentRose,
                  behavior: SnackBarBehavior.floating,
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
        appBar: AppBar(
          titleSpacing: 12,
          title: const Row(
            children: [
              TrustvlyLogo(size: 34, borderRadius: 10),
              SizedBox(width: 10),
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
                          fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    Text(
                      'Debt Freedom · Wealth Clarity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.undo_rounded, color: AppColors.accentAmber, size: 19),
                        onPressed: () => context.read<DhanflowCubit>().undoLastAction(),
                      ),
                    IconButton(
                      tooltip: state.hideBalances ? 'Show amounts' : 'Hide amounts',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        state.hideBalances
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 19,
                      ),
                      onPressed: () => context.read<DhanflowCubit>().toggleHideBalances(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10, left: 4),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, authState) {
                          if (authState is AuthAuthenticated) {
                            return InkWell(
                              onTap: () => showAccountSheet(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.greenDim,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.accentGreen.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      authState.initials,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accentGreen,
                                      ),
                                    ),
                                    if (MediaQuery.of(context).size.width >= 540) ...[
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 90),
                                        child: Text(
                                          (authState.user['name'] as String? ?? 'Account')
                                              .split(' ')
                                              .first,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }
                          return TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.bgCard,
                              foregroundColor: AppColors.textPrimary,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: AppColors.borderLight),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: narrow ? 9 : 12,
                                vertical: 6,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AuthScreen()),
                              );
                            },
                            icon: const Icon(Icons.login_rounded,
                                size: 14, color: AppColors.accentGreen),
                            label: const Text('Sign In',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
            child: Container(height: 1, color: AppColors.border),
          ),
        ),
        body: Row(
          children: [
            if (isWide)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.bgCard,
                  border: Border(right: BorderSide(color: AppColors.border)),
                ),
                child: NavigationRail(
                  backgroundColor: AppColors.bgCard,
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (i) => setState(() => _tabIndex = i),
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: AppColors.greenDim,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.accentGreen),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.credit_card_outlined),
                      selectedIcon: Icon(Icons.credit_card_rounded, color: AppColors.accentGreen),
                      label: Text('Debt'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.handshake_outlined),
                      selectedIcon: Icon(Icons.handshake_rounded, color: AppColors.accentGreen),
                      label: Text('Kul Lena'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.workspace_premium_outlined),
                      selectedIcon:
                          Icon(Icons.workspace_premium_rounded, color: AppColors.accentAmber),
                      label: Text('Bullion'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history_rounded, color: AppColors.accentGreen),
                      label: Text('Activity'),
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
                      OverviewTab(onNavigateTab: (i) => setState(() => _tabIndex = i)),
                      const DebtTab(),
                      const RecoveriesTab(),
                      const BullionTab(),
                      const ActivityTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: NavigationBar(
                  backgroundColor: AppColors.bgCard,
                  indicatorColor: AppColors.greenDim,
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (i) => setState(() => _tabIndex = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.accentGreen),
                      label: 'Overview',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.credit_card_outlined),
                      selectedIcon: Icon(Icons.credit_card_rounded, color: AppColors.accentGreen),
                      label: 'Debt',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.handshake_outlined),
                      selectedIcon: Icon(Icons.handshake_rounded, color: AppColors.accentGreen),
                      label: 'Kul Lena',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.workspace_premium_outlined),
                      selectedIcon:
                          Icon(Icons.workspace_premium_rounded, color: AppColors.accentAmber),
                      label: 'Bullion',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history_rounded, color: AppColors.accentGreen),
                      label: 'Activity',
                    ),
                  ],
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
        label = 'Synced';
        break;
      case CloudSyncStatus.syncing:
        dotColor = AppColors.accentAmber;
        label = 'Syncing';
        break;
      case CloudSyncStatus.error:
        dotColor = AppColors.accentRose;
        label = 'Retry';
        break;
      case CloudSyncStatus.offline:
        dotColor = AppColors.textTertiary;
        label = 'Local';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: 'Storage: $label',
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
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
