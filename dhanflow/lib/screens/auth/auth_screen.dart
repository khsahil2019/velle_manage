import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../widgets/common/dhan_ui.dart';

/// Dedicated Sign In & Sign Up Screen with Vercel PHP Backend Storage integration
class AuthScreen extends StatefulWidget {
  final bool allowDismiss;
  const AuthScreen({super.key, this.allowDismiss = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _seedInitialData = true;
  bool _uploadCurrentLocalData = false;
  bool _showAdvancedUrl = false;
  bool _checkingHealth = false;
  ApiHealthStatus? _healthStatus;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
      text: context.read<DhanflowCubit>().state.appState.settings.apiBaseUrl,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBackendHealth());
  }

  Future<void> _checkBackendHealth() async {
    if (!mounted) return;
    setState(() => _checkingHealth = true);
    final normalized = ApiConstants.normalizeBaseUrl(_urlCtrl.text);
    _urlCtrl.text = normalized;
    context.read<DhanflowCubit>().updateApiBaseUrl(normalized);
    final status = await context.read<AuthCubit>().checkBackendHealth();
    if (!mounted) return;
    setState(() {
      _checkingHealth = false;
      _healthStatus = status;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final dhanflowCubit = context.read<DhanflowCubit>();
    dhanflowCubit.updateApiBaseUrl(_urlCtrl.text);

    final authCubit = context.read<AuthCubit>();
    bool ok;
    if (_isSignUp) {
      ok = await authCubit.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        seedInitialData: _seedInitialData,
        uploadCurrentLocalData: _uploadCurrentLocalData,
      );
    } else {
      ok = await authCubit.login(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
    }

    if (ok && mounted && widget.allowDismiss) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Subtle ambient fintech background glow
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGreen.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentBlue.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final isLoading = authState is AuthLoading;
                      final errorMsg = authState is AuthError ? authState.message : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.allowDismiss)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                            ),
                          const Center(
                            child: TrustvlyLogo(size: 68, borderRadius: 20),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Trustvly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Debt Freedom · Cloud Vault Storage · Bullion Intelligence',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          DhanCard(
                            padding: const EdgeInsets.all(20),
                            borderColor: AppColors.borderLight,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Mode Switcher: Sign In vs Sign Up
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgPrimary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        _AuthTabButton(
                                          label: 'Sign In',
                                          selected: !_isSignUp,
                                          onTap: () {
                                            context.read<AuthCubit>().clearError();
                                            setState(() => _isSignUp = false);
                                          },
                                        ),
                                        _AuthTabButton(
                                          label: 'Create Account',
                                          selected: _isSignUp,
                                          onTap: () {
                                            context.read<AuthCubit>().clearError();
                                            setState(() => _isSignUp = true);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  if (_isSignUp) ...[
                                    TextFormField(
                                      controller: _nameCtrl,
                                      textCapitalization: TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                                      ),
                                      validator: (v) {
                                        if (_isSignUp && (v == null || v.trim().length < 2)) {
                                          return 'Enter your full name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email Address',
                                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                                    ),
                                    validator: (v) {
                                      if (v == null || !v.contains('@') || !v.contains('.')) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),

                                  if (_isSignUp) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgHover,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        children: [
                                          SwitchListTile.adaptive(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            title: const Text(
                                              'Sync current device ledger to new account',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            ),
                                            subtitle: const Text(
                                              'Keeps your active cards, loans & Gullak entries',
                                              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                            ),
                                            value: _uploadCurrentLocalData,
                                            activeTrackColor: AppColors.accentGreen,
                                            onChanged: (v) =>
                                                setState(() => _uploadCurrentLocalData = v),
                                          ),
                                          if (!_uploadCurrentLocalData)
                                            SwitchListTile.adaptive(
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                              title: const Text(
                                                'Pre-load initial demo template',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                              value: _seedInitialData,
                                              activeTrackColor: AppColors.accentBlue,
                                              onChanged: (v) =>
                                                  setState(() => _seedInitialData = v),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (errorMsg != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.roseDim.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.accentRose.withValues(alpha: 0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded,
                                              size: 16, color: AppColors.accentRose),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              errorMsg,
                                              style: const TextStyle(
                                                  fontSize: 11, color: AppColors.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _submit,
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Text(_isSignUp ? 'Create Account & Sync' : 'Sign In'),
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                  if (_checkingHealth || _healthStatus != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: (_healthStatus?.isFullyReady == true
                                                ? AppColors.greenDim
                                                : (_healthStatus?.reachable == true
                                                    ? AppColors.amberDim
                                                    : AppColors.roseDim))
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: (_healthStatus?.isFullyReady == true
                                                  ? AppColors.accentGreen
                                                  : (_healthStatus?.reachable == true
                                                      ? AppColors.accentAmber
                                                      : AppColors.accentRose))
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _checkingHealth
                                                ? Icons.sync_rounded
                                                : (_healthStatus?.isFullyReady == true
                                                    ? Icons.cloud_done_rounded
                                                    : (_healthStatus?.reachable == true
                                                        ? Icons.storage_rounded
                                                        : Icons.cloud_off_rounded)),
                                            size: 15,
                                            color: _healthStatus?.isFullyReady == true
                                                ? AppColors.accentGreen
                                                : (_healthStatus?.reachable == true
                                                    ? AppColors.accentAmber
                                                    : AppColors.accentRose),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _checkingHealth
                                                  ? 'Checking Vercel PHP API status...'
                                                  : (_healthStatus?.message ?? ''),
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  TextButton.icon(
                                    onPressed: () =>
                                        setState(() => _showAdvancedUrl = !_showAdvancedUrl),
                                    icon: Icon(
                                      _showAdvancedUrl
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.settings_ethernet_rounded,
                                      size: 15,
                                      color: AppColors.textTertiary,
                                    ),
                                    label: const Text(
                                      'Backend API Endpoint & Test',
                                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                    ),
                                  ),
                                  if (_showAdvancedUrl) ...[
                                    TextFormField(
                                      controller: _urlCtrl,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        labelText: 'Vercel PHP Backend URL',
                                        hintText: 'https://vellemanage.vercel.app',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _checkingHealth ? null : _checkBackendHealth,
                                            icon: const Icon(Icons.network_check_rounded, size: 15),
                                            label: const Text('Test API', style: TextStyle(fontSize: 11)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            _urlCtrl.text = ApiConstants.defaultBaseUrl;
                                            _checkBackendHealth();
                                          },
                                          child: const Text('Reset Default', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (widget.allowDismiss) ...[
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'Continue in Offline Local Mode →',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AuthTabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.black : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows signed-in Account Details, Backend Storage status, Sync controls & Sign Out
void showAccountSheet(BuildContext context) {
  showDhanBottomSheet(context, builder: (ctx) {
    final authState = ctx.watch<AuthCubit>().state;
    final dhanState = ctx.watch<DhanflowCubit>().state;

    if (authState is! AuthAuthenticated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Offline Local Mode', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Your ledger is currently saved on this device only. Sign in or create an account to back up and sync automatically with the PHP backend database.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Sign In / Create Account'),
          ),
        ],
      );
    }

    final user = authState.user;
    final driver = authState.storageDriver?.toUpperCase() ?? 'CLOUD DB';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.greenDim,
              child: Text(
                authState.initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] as String? ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle),
                  Text(user['email'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: StatusChip(
                text: driver,
                color: AppColors.accentGreen,
                bgColor: AppColors.greenDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DhanCard(
          backgroundColor: AppColors.bgHover,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Backend Status', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      dhanState.syncStatus == CloudSyncStatus.synced
                          ? '● Synced to Backend'
                          : dhanState.syncStatus == CloudSyncStatus.syncing
                              ? '↻ Syncing...'
                              : dhanState.syncStatus == CloudSyncStatus.error
                                  ? '⚠ Sync Retrying'
                                  : '○ Ready',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dhanState.syncStatus == CloudSyncStatus.error
                            ? AppColors.accentAmber
                            : AppColors.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Endpoint', style: AppTextStyles.caption),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      dhanState.appState.settings.apiBaseUrl,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: dhanState.isSyncing
                    ? null
                    : () => context.read<DhanflowCubit>().pushToCloud(),
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Push to Backend'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: dhanState.isSyncing
                    ? null
                    : () => context.read<DhanflowCubit>().pullFromCloud(),
                icon: const Icon(Icons.cloud_download_outlined, size: 16),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Pull from Backend'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentRose,
            side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await context.read<AuthCubit>().logout();
          },
          icon: const Icon(Icons.logout_rounded, size: 17),
          label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  });
}
