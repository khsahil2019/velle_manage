import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../widgets/common/dhan_ui.dart';
import '../dashboard/dashboard_screen.dart';

/// Mandatory Auth Gate: opens Sign In / Create Account on launch until authenticated,
/// then stays permanently inside DashboardScreen across app restarts.
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          return const DashboardScreen();
        }
        return const AuthScreen(allowDismiss: false);
      },
    );
  }
}

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
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgPrimary,
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
                          // Top Quick Language & Theme Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => context.read<DhanflowCubit>().toggleLanguage(),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: context.bgCard,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.translate_rounded,
                                          size: 14, color: AppColors.accentGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        context.isHindi ? 'हिन्दी → English' : 'English → हिन्दी',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: isDark ? 'White Mode' : 'Dark Mode',
                                    icon: Icon(
                                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                      size: 20,
                                      color: isDark ? AppColors.accentAmber : const Color(0xFF6366F1),
                                    ),
                                    onPressed: () => context.read<DhanflowCubit>().toggleThemeMode(),
                                  ),
                                  if (widget.allowDismiss)
                                    IconButton(
                                      icon: Icon(Icons.close_rounded, color: context.textSecondary),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: TrustvlyLogo(size: 72, floating: true),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.tr('auth_welcome'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('auth_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: context.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: StatusChip(
                              text: context.tr('auth_permanent_badge'),
                              color: AppColors.accentGreen,
                              bgColor: context.greenDim,
                            ),
                          ),
                          const SizedBox(height: 20),
                          DhanCard(
                            padding: const EdgeInsets.all(20),
                            borderColor: context.borderLight,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Mode Switcher: Sign In vs Sign Up
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.bgPrimary : AppColors.lightBgCard2,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: context.border),
                                    ),
                                    child: Row(
                                      children: [
                                        _AuthTabButton(
                                          label: context.tr('auth_signin'),
                                          selected: !_isSignUp,
                                          onTap: () {
                                            context.read<AuthCubit>().clearError();
                                            setState(() => _isSignUp = false);
                                          },
                                        ),
                                        _AuthTabButton(
                                          label: context.tr('auth_signup'),
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
                                      decoration: InputDecoration(
                                        labelText: context.tr('auth_fullname'),
                                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
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
                                    decoration: InputDecoration(
                                      labelText: context.tr('auth_email'),
                                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
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
                                      labelText: context.tr('auth_password'),
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
                                        color: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: context.border),
                                      ),
                                      child: Column(
                                        children: [
                                          SwitchListTile.adaptive(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            title: Text(
                                              context.tr('auth_keep_local'),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            subtitle: Text(
                                              context.tr('auth_keep_local_sub'),
                                              style: TextStyle(fontSize: 10, color: context.textTertiary),
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
                                              title: Text(
                                                context.tr('auth_load_demo'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.textPrimary,
                                                ),
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
                                        color: context.roseDim.withValues(alpha: 0.6),
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
                                              style: TextStyle(
                                                  fontSize: 11, color: context.textPrimary),
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
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: isDark ? Colors.black : Colors.white,
                                              ),
                                            )
                                          : Text(_isSignUp
                                              ? context.tr('auth_signup_btn')
                                              : context.tr('auth_signin_btn')),
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                  if (_checkingHealth || _healthStatus != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: (_healthStatus?.isFullyReady == true
                                                ? context.greenDim
                                                : (_healthStatus?.reachable == true
                                                    ? context.amberDim
                                                    : context.roseDim))
                                            .withValues(alpha: 0.55),
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
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: context.textSecondary,
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
                                      color: context.textTertiary,
                                    ),
                                    label: Text(
                                      context.tr('auth_api_toggle'),
                                      style: TextStyle(fontSize: 11, color: context.textTertiary),
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
                              child: Text(
                                'Continue in Offline Local Mode →',
                                style: TextStyle(
                                  color: context.textSecondary,
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
              color: selected ? Colors.black : context.textSecondary,
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
          Text('Offline Local Mode',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ctx.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Your ledger is currently saved on this device only. Sign in or create an account to back up and sync automatically with the PHP backend database.',
            style: TextStyle(fontSize: 13, color: ctx.textSecondary),
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
              backgroundColor: ctx.greenDim,
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
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: ctx.textPrimary)),
                  Text(user['email'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: StatusChip(
                text: driver,
                color: AppColors.accentGreen,
                bgColor: ctx.greenDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DhanCard(
          backgroundColor: ctx.isDark ? AppColors.bgHover : AppColors.lightBgCard2,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Backend Status',
                      style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
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
                  Text('Endpoint', style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      dhanState.appState.settings.apiBaseUrl,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: ctx.textSecondary),
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
