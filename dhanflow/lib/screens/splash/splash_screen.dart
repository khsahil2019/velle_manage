import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/dhan_ui.dart';
import '../dashboard/dashboard_screen.dart';

/// Animated dark-fintech splash screen for Trustvly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progress;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.72, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.72, curve: Curves.easeOutCubic)),
    );
    _progress = Tween<double>(begin: 0.08, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 1.0, curve: Curves.easeInOutCubic)),
    );

    _controller.forward();
    _navTimer = Timer(const Duration(milliseconds: 1450), _goToDashboard);
  }

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: const DashboardScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient fintech corner glows
          Positioned(
            top: -140,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGreen.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentAmber.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.accentGreen.withValues(alpha: 0.22),
                                        AppColors.accentGreen.withValues(alpha: 0.02),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.accentGreen.withValues(alpha: 0.28),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const TrustvlyLogo(size: 92, borderRadius: 24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            FadeTransition(
                              opacity: _textFade,
                              child: SlideTransition(
                                position: _textSlide,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [
                                          AppColors.textPrimary,
                                          Color(0xFFD1FAE5),
                                        ],
                                      ).createShader(bounds),
                                      child: const Text(
                                        'Trustvly',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1.1,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.greenDim.withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.accentGreen.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Text(
                                        'DEBT FREEDOM · WEALTH CLARITY',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: AppColors.accentGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _SplashFeatureChip(
                                          icon: Icons.currency_rupee_rounded,
                                          label: 'INR Precision',
                                          color: AppColors.accentGreen,
                                        ),
                                        _SplashFeatureChip(
                                          icon: Icons.workspace_premium_rounded,
                                          label: '24K Bullion',
                                          color: AppColors.accentAmber,
                                        ),
                                        _SplashFeatureChip(
                                          icon: Icons.verified_user_outlined,
                                          label: 'Cloud & Local Vault',
                                          color: AppColors.accentBlue,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: _progress.value,
                                      minHeight: 4,
                                      backgroundColor: AppColors.border,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.accentGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Preparing financial ledger...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SplashFeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
