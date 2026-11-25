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

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final cubit = context.read<DhanflowCubit>();
        final authState = context.watch<AuthCubit>().state;
        final logs = state.appState.activityLog;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // Account & Backend Data Storage Card
            const SectionHeader(
              title: 'Account & Cloud Backend Storage',
              subtitle: 'Sign in or create an account to persist data in PHP + Cloud DB',
            ),
            const SizedBox(height: 10),
            DhanCard(
              borderColor: authState is AuthAuthenticated
                  ? AppColors.accentGreen.withValues(alpha: 0.35)
                  : AppColors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (authState is AuthAuthenticated)
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.greenDim,
                          child: Text(
                            authState.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgHover,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_off_rounded, color: AppColors.textTertiary),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState is AuthAuthenticated
                                  ? '${authState.user['name']} (${authState.user['email']})'
                                  : 'Offline Guest Mode (Local Hive)',
                              style: AppTextStyles.cardTitle,
                            ),
                            Text(
                              authState is AuthAuthenticated
                                  ? 'Auto-sync enabled · Storage: ${(authState.storageDriver ?? 'Cloud DB').toUpperCase()}'
                                  : 'Sign in to automatically store & sync data across devices',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AuthScreen()),
                              );
                            },
                            icon: const Icon(Icons.login_rounded, size: 16),
                            label: const Text('Sign In / Create Account'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const SectionHeader(
              title: 'Local JSON Backup & Snapshot',
              subtitle: 'Portable JSON export, restore, or reset',
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON backup exported / copied')),
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
                      side: const BorderSide(color: AppColors.accentRose),
                    ),
                    onPressed: () => _confirmReset(context),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset Snapshot'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            SectionHeader(
              title: 'Immutable Activity & Audit Log',
              subtitle: 'Undo creates a reversing entry rather than erasing history',
              trailing: TextButton.icon(
                onPressed: state.canUndo ? () => cubit.undoLastAction() : null,
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Undo Last'),
              ),
            ),
            const SizedBox(height: 8),
            DhanCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: logs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No events recorded yet.', style: AppTextStyles.body)),
                    )
                  : Column(
                      children: logs.map((entry) {
                        final color = _colorForEvent(entry.eventType);
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: entry.isReversed
                                        ? AppColors.textTertiary
                                        : AppColors.textSecondary,
                                    decoration: entry.isReversed
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                INRFormatter.timeAgo(entry.createdAt),
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

  Color _colorForEvent(String eventType) {
    if (eventType.contains('PAYMENT') || eventType.contains('RECOVERY')) {
      return AppColors.accentGreen;
    }
    if (eventType.contains('SPEND')) return AppColors.accentRose;
    if (eventType.contains('BULLION')) return AppColors.accentAmber;
    if (eventType.contains('LOAN')) return AppColors.accentBlue;
    return AppColors.textTertiary;
  }

  void _showImportSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Import JSON Backup', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text('Paste backup JSON or pick a .json file from storage',
              style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Row(
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
              const SizedBox(width: 8),
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard2,
        title: const Text('Reset to Initial Snapshot?', style: AppTextStyles.sectionTitle),
        content: const Text(
          'This restores all 8 credit cards, DMI Finance Loan, Arshi payable, 3 recoveries, and 5 Gullak transactions to exact seed values.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DhanflowCubit>().resetToSeed();
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}
