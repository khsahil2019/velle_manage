import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Trustvly brand icon emblem backed by the 1024px high-res asset
class TrustvlyLogo extends StatelessWidget {
  final double size;
  final double borderRadius;

  const TrustvlyLogo({
    super.key,
    this.size = 36,
    this.borderRadius = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.45),
          width: size > 48 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.22),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((borderRadius - 1).clamp(0, borderRadius)),
        child: Image.asset(
          'assets/trustvly_icon_1024.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class DhanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const DhanCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradient == null ? (backgroundColor ?? AppColors.bgCard) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor ?? AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

    if (onTap == null) {
      return Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: decoration,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: AppColors.bgHover.withValues(alpha: 0.5),
        child: Ink(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

class HeroCommandCard extends StatelessWidget {
  final String title;
  final String mainValue;
  final String subtitle;
  final bool isPositive;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final List<({String label, String value, Color color})> pills;

  const HeroCommandCard({
    super.key,
    required this.title,
    required this.mainValue,
    required this.subtitle,
    required this.isPositive,
    required this.hidden,
    required this.onToggleHidden,
    required this.pills,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isPositive ? AppColors.accentGreen : AppColors.accentRose;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgCard2,
            AppColors.bgCard,
            accent.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: StatusChip(
                  text: isPositive ? 'NET POSITIVE' : 'NET LIABILITY AFTER ASSETS',
                  color: accent,
                  bgColor: accent.withValues(alpha: 0.14),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: hidden ? 'Show balances' : 'Hide balances',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onPressed: onToggleHidden,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hidden ? '₹ • • • • • •' : mainValue,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hidden ? '₹ •••••' : p.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: p.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class KPITile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final bool hidden;
  final VoidCallback? onTap;

  const KPITile({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    this.hidden = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DhanCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.border,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hidden ? '₹ ••••••' : value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: -0.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class BankAvatarBadge extends StatelessWidget {
  final String name;
  final Color? overrideColor;

  const BankAvatarBadge({super.key, required this.name, this.overrideColor});

  @override
  Widget build(BuildContext context) {
    final lower = name.toLowerCase();
    final Color color;
    final String code;

    if (overrideColor != null) {
      color = overrideColor!;
      code = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    } else if (lower.contains('sbi')) {
      color = const Color(0xFF3B82F6);
      code = 'SBI';
    } else if (lower.contains('pnb')) {
      color = const Color(0xFFEC4899);
      code = 'PNB';
    } else if (lower.contains('icici')) {
      color = const Color(0xFFF97316);
      code = 'ICI';
    } else if (lower.contains('axis')) {
      color = const Color(0xFFA855F7);
      code = 'AXS';
    } else if (lower.contains('roar')) {
      color = const Color(0xFFF59E0B);
      code = 'ROA';
    } else if (lower.contains('hdfc')) {
      color = const Color(0xFF10B981);
      code = 'HDF';
    } else if (lower.contains('rbl')) {
      color = const Color(0xFF06B6D4);
      code = 'RBL';
    } else if (lower.contains('amazon')) {
      color = const Color(0xFF22C55E);
      code = 'APAY';
    } else {
      color = AppColors.accentBlue;
      code = name.trim().isEmpty
          ? '?'
          : name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Text(
          code,
          style: TextStyle(
            fontSize: code.length > 2 ? 10 : 12,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

class UtilizationBar extends StatelessWidget {
  final double percentage;
  final Color? overrideColor;
  final double height;

  const UtilizationBar({
    super.key,
    required this.percentage,
    this.overrideColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percentage / 100).clamp(0.0, 1.0);
    final barColor = overrideColor ?? AppColors.utilizationColor(percentage);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct),
        duration: const Duration(milliseconds: 350),
        builder: (context, val, _) => LinearProgressIndicator(
          value: val,
          minHeight: height,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color bgColor;

  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Flexible(flex: 0, child: trailing!),
        ],
      ],
    );
  }
}

Future<T?> showDhanBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

/// Requires explicit typed confirmation ("DELETE") so financial records & basic transactions
/// cannot be deleted accidentally with a single tap.
Future<void> showProtectedDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String actionLabel = 'Confirm Delete',
}) {
  final confirmCtrl = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final isUnlocked = confirmCtrl.text.trim().toUpperCase() == 'DELETE';
        return AlertDialog(
          backgroundColor: AppColors.bgCard2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.35)),
          ),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.roseDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.accentRose, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTextStyles.sectionTitle),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: AppTextStyles.body),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.roseDim.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Protected action: direct one-tap delete is disabled. Type DELETE below to confirm.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to unlock',
                  hintText: 'DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isUnlocked ? AppColors.accentRose : AppColors.bgHover,
                foregroundColor: isUnlocked ? Colors.white : AppColors.textTertiary,
              ),
              onPressed: isUnlocked
                  ? () {
                      Navigator.pop(ctx);
                      onConfirm();
                    }
                  : null,
              child: Text(actionLabel),
            ),
          ],
        );
      },
    ),
  );
}
