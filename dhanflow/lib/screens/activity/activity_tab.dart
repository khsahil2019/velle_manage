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
            // Backup & Snapshot Controls
            const SectionHeader(
              title: 'Backup, Restore & Cloud Sync',
              subtitle: 'Local Hive storage + Vercel PHP Backend sync',
            ),
            const SizedBox(height: 10),
            DhanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
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
                  const Divider(height: 24),
                  // Vercel PHP Cloud Sync Section
                  Row(
                    children: [
                      Icon(
                        authState is AuthAuthenticated
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: authState is AuthAuthenticated
                            ? AppColors.accentGreen
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState is AuthAuthenticated
                                  ? 'Connected: ${authState.user['email']}'
                                  : 'Offline Mode (Local Hive Storage)',
                              style: AppTextStyles.cardTitle,
                            ),
                            Text(
                              'API: ${state.appState.settings.apiBaseUrl}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showCloudSyncSheet(context, state.appState.settings.apiBaseUrl),
                        child: Text(authState is AuthAuthenticated ? 'Manage' : 'Connect'),
                      ),
                    ],
                  ),
                  if (authState is AuthAuthenticated) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: state.isSyncing ? null : () => cubit.pushToCloud(),
                            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                            label: const Text('Push Local → Cloud'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: state.isSyncing ? null : () => cubit.pullFromCloud(),
                            icon: const Icon(Icons.cloud_download_outlined, size: 16),
                            label: const Text('Pull Cloud → Local'),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  void _showCloudSyncSheet(BuildContext context, String currentUrl) {
    final urlCtrl = TextEditingController(text: currentUrl);
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isRegister = false;

    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final authState = ctx.watch<AuthCubit>().state;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vercel PHP Cloud Sync', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: 'Vercel PHP API Base URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_rounded, color: AppColors.accentGreen),
                  onPressed: () => context.read<DhanflowCubit>().updateApiBaseUrl(urlCtrl.text),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (authState is AuthAuthenticated) ...[
              Text('Signed in as ${authState.user['name']} (${authState.user['email']})',
                  style: AppTextStyles.body),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentRose),
                onPressed: () {
                  context.read<AuthCubit>().logout();
                  Navigator.pop(ctx);
                },
                child: const Text('Sign Out (Switch to Offline Mode)'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Login'),
                      selected: !isRegister,
                      selectedColor: AppColors.accentGreen,
                      labelStyle: TextStyle(
                          color: !isRegister ? Colors.black : AppColors.textSecondary,
                          fontWeight: FontWeight.w700),
                      onSelected: (_) => setSheetState(() => isRegister = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Create Account'),
                      selected: isRegister,
                      selectedColor: AppColors.accentGreen,
                      labelStyle: TextStyle(
                          color: isRegister ? Colors.black : AppColors.textSecondary,
                          fontWeight: FontWeight.w700),
                      onSelected: (_) => setSheetState(() => isRegister = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isRegister) ...[
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 10),
              ],
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (min 8 chars)'),
              ),
              if (authState is AuthError) ...[
                const SizedBox(height: 8),
                Text(authState.message, style: const TextStyle(color: AppColors.accentRose, fontSize: 12)),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: authState is AuthLoading
                    ? null
                    : () async {
                        context.read<DhanflowCubit>().updateApiBaseUrl(urlCtrl.text);
                        final authCubit = context.read<AuthCubit>();
                        if (isRegister) {
                          await authCubit.register(
                            name: nameCtrl.text,
                            email: emailCtrl.text,
                            password: passCtrl.text,
                          );
                        } else {
                          await authCubit.login(
                            email: emailCtrl.text,
                            password: passCtrl.text,
                          );
                        }
                        if (ctx.mounted && context.read<AuthCubit>().state is AuthAuthenticated) {
                          Navigator.pop(ctx);
                        }
                      },
                child: Text(authState is AuthLoading
                    ? 'Connecting...'
                    : isRegister
                        ? 'Register & Connect'
                        : 'Sign In'),
              ),
            ],
          ],
        );
      });
    });
  }
}
