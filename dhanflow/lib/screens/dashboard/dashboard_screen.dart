import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../activity/activity_tab.dart';
import '../bullion/bullion_tab.dart';
import '../debt/debt_tab.dart';
import '../overview/overview_tab.dart';
import '../recoveries/recoveries_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DhanflowCubit, DhanflowViewState>(
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
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, AppColors.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Center(
                  child: Text('₹',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DHANFLOW',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  Text('Debt Freedom · Wealth Clarity',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          actions: [
            BlocBuilder<DhanflowCubit, DhanflowViewState>(
              builder: (context, state) {
                return Row(
                  children: [
                    if (state.canUndo)
                      IconButton(
                        tooltip: 'Undo last action',
                        icon: const Icon(Icons.undo_rounded, color: AppColors.accentAmber),
                        onPressed: () => context.read<DhanflowCubit>().undoLastAction(),
                      ),
                    IconButton(
                      tooltip: 'Backup & Cloud Sync',
                      icon: const Icon(Icons.backup_outlined, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _tabIndex = 4),
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
        body: IndexedStack(
          index: _tabIndex,
          children: [
            OverviewTab(onNavigateTab: (i) => setState(() => _tabIndex = i)),
            const DebtTab(),
            const RecoveriesTab(),
            const BullionTab(),
            const ActivityTab(),
          ],
        ),
        bottomNavigationBar: Container(
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
                selectedIcon: Icon(Icons.workspace_premium_rounded, color: AppColors.accentAmber),
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
