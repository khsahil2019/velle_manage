import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../services/export_service.dart';
import '../../widgets/common/dhan_ui.dart';
import '../auth/auth_screen.dart';

/// Dedicated Profile, Account, Cloud Storage, Local JSON Vault & Settings Screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final cubit = context.read<DhanflowCubit>();
        final authState = context.watch<AuthCubit>().state;
        final isDark = context.isDark;
        final app = state.appState;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            // ── USER PROFILE HERO CARD ──────────────────────────────
            DhanCard(
              borderColor: authState is AuthAuthenticated
                  ? AppColors.accentGreen.withValues(alpha: 0.35)
                  : context.border,
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
                        const Color(0xFFF8FAFC),
                        AppColors.accentGreen.withValues(alpha: 0.06),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (authState is AuthAuthenticated)
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: context.greenDim,
                          child: Text(
                            authState.initials,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.border),
                          ),
                          child: Icon(Icons.person_outline_rounded,
                              size: 26, color: context.textSecondary),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState is AuthAuthenticated
                                  ? (authState.user['name'] as String? ?? 'Trustvly User')
                                  : 'Offline Guest Profile',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authState is AuthAuthenticated
                                  ? (authState.user['email'] as String? ?? '')
                                  : 'Local device storage active · Sign in for cloud sync',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        text: authState is AuthAuthenticated
                            ? (authState.storageDriver ?? 'CLOUD DB').toUpperCase()
                            : 'LOCAL',
                        color: authState is AuthAuthenticated
                            ? AppColors.accentGreen
                            : AppColors.accentAmber,
                        bgColor: authState is AuthAuthenticated
                            ? context.greenDim
                            : context.amberDim,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMiniStat(
                          label: 'Cards',
                          value: '${app.creditCards.length}',
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileMiniStat(
                          label: 'Assets',
                          value: '${app.bullionTransactions.length + app.personalAssets.length}',
                          color: AppColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileMiniStat(
                          label: 'Recoveries',
                          value: '${app.recoveries.length}',
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileMiniStat(
                          label: 'Logs',
                          value: '${app.activityLog.length}',
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── CLOUD STORAGE & BACKEND SYNC ────────────────────────
            const SectionHeader(
              title: 'Cloud Storage & Backend Sync',
              subtitle: 'Persist your financial ledger to Vercel PHP + Cloud DB',
            ),
            const SizedBox(height: 10),
            DhanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ApiDiagnosticsStrip(apiUrl: app.settings.apiBaseUrl),
                  const SizedBox(height: 12),
                  if (authState is AuthAuthenticated)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: state.isSyncing ? null : () => cubit.pushToCloud(),
                          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: const Text('Push to Cloud'),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.isSyncing ? null : () => cubit.pullFromCloud(),
                          icon: const Icon(Icons.cloud_download_outlined, size: 16),
                          label: const Text('Pull from Cloud'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentRose,
                            side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.5)),
                          ),
                          onPressed: () => context.read<AuthCubit>().logout(),
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Sign Out'),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Sign In / Create Account'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── LOCAL JSON BACKUP & SNAPSHOT ────────────────────────
            const SectionHeader(
              title: 'Local JSON Backup & Snapshot',
              subtitle: 'Export, import, or reset local JSON financial data (logged in Activity)',
            ),
            const SizedBox(height: 10),
            DhanCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ExportService.exportBackup(state.appState);
                      cubit.recordExportBackup();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON backup exported / copied & logged')),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showImportSheet(context),
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: const Text('Import JSON'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRose,
                      side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.5)),
                    ),
                    onPressed: () => _confirmReset(context),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset Snapshot'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── APPEARANCE & DEBT ENGINE SETTINGS ───────────────────
            const SectionHeader(
              title: 'Preferences & Debt Payoff Engine',
              subtitle: 'Customize theme appearance, privacy & payoff strategy',
            ),
            const SizedBox(height: 10),
            DhanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.accentAmber : const Color(0xFF6366F1))
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          size: 18,
                          color: isDark ? AppColors.accentAmber : const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appearance Mode',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              isDark ? 'Obsidian Dark Mode active' : 'Clean White Mode active',
                              style: TextStyle(fontSize: 11, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: !isDark,
                        activeThumbColor: const Color(0xFF059669),
                        onChanged: (_) => cubit.toggleThemeMode(),
                      ),
                    ],
                  ),
                  Divider(height: 22, color: context.border),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.visibility_off_outlined,
                            size: 18, color: AppColors.accentGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy Mask Balances',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              'Hide rupee amounts across cards & dashboard',
                              style: TextStyle(fontSize: 11, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.hideBalances,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (_) => cubit.toggleHideBalances(),
                      ),
                    ],
                  ),
                  Divider(height: 22, color: context.border),
                  Text(
                    'DEBT PAYOFF STRATEGY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Snowball (Smallest)')),
                          selected: app.settings.debtPayoffStrategy == 'snowball',
                          selectedColor: AppColors.accentGreen,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: app.settings.debtPayoffStrategy == 'snowball'
                                ? Colors.black
                                : context.textSecondary,
                          ),
                          onSelected: (_) => cubit.updateDebtEngine(strategy: 'snowball'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Avalanche (APR)')),
                          selected: app.settings.debtPayoffStrategy == 'avalanche',
                          selectedColor: AppColors.accentGreen,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: app.settings.debtPayoffStrategy == 'avalanche'
                                ? Colors.black
                                : context.textSecondary,
                          ),
                          onSelected: (_) => cubit.updateDebtEngine(strategy: 'avalanche'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Payoff Budget: ${INRFormatter.formatPaise(app.settings.monthlyPaymentCapacityPaise)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showBudgetSheet(context, app.settings.monthlyPaymentCapacityPaise),
                        child: const Text('Edit Budget'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBudgetSheet(BuildContext context, int currentPaise) {
    final ctrl = TextEditingController(text: (currentPaise / 100).toStringAsFixed(0));
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Monthly Debt Payoff Budget',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ctx.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Capacity (₹)',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v == null || v <= 0) return;
              context.read<DhanflowCubit>().updateDebtEngine(
                    monthlyBudgetPaise: PaiseMath.rupeesToPaise(v),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save Budget'),
          ),
        ],
      );
    });
  }

  void _showImportSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Import JSON Backup',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ctx.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Paste backup JSON or pick a .json file from device storage',
            style: TextStyle(fontSize: 11, color: ctx.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final content = await File(result.files.single.path!).readAsString();
                    ctrl.text = content;
                  }
                },
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Pick .json File'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final clip = await Clipboard.getData('text/plain');
                  if (clip?.text != null) ctrl.text = clip!.text!;
                },
                icon: const Icon(Icons.paste_rounded, size: 16),
                label: const Text('Paste'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            maxLines: 6,
            decoration: const InputDecoration(hintText: '{"schema_version": "1.0.0", ...}'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              context.read<DhanflowCubit>().importJson(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Validate & Restore'),
          ),
        ],
      );
    });
  }

  void _confirmReset(BuildContext context) {
    showProtectedDeleteDialog(
      context,
      title: 'Reset to Initial Snapshot?',
      message:
          'This restores all credit cards, loans, payables, recoveries, and initial metal holdings to exact seed values.',
      actionLabel: 'Reset Everything',
      onConfirm: () => context.read<DhanflowCubit>().resetToSeed(),
    );
  }
}

class _ProfileMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProfileMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.bgPrimary.withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: context.textTertiary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ApiDiagnosticsStrip extends StatefulWidget {
  final String apiUrl;
  const _ApiDiagnosticsStrip({required this.apiUrl});

  @override
  State<_ApiDiagnosticsStrip> createState() => _ApiDiagnosticsStripState();
}

class _ApiDiagnosticsStripState extends State<_ApiDiagnosticsStrip> {
  bool _loading = false;
  ApiHealthStatus? _status;

  Future<void> _testApi() async {
    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().checkBackendHealth();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 14, color: context.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.apiUrl,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ),
              TextButton.icon(
                onPressed: _loading ? null : _testApi,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  _loading ? Icons.sync_rounded : Icons.network_check_rounded,
                  size: 13,
                ),
                label: Text(_loading ? 'Checking...' : 'Test API', style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 4),
            Text(
              _status!.message,
              style: TextStyle(
                fontSize: 10.5,
                color: _status!.isFullyReady
                    ? AppColors.accentGreen
                    : (_status!.reachable ? AppColors.accentAmber : AppColors.accentRose),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
