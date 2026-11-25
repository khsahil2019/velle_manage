import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';

enum BankBrand {
  sbi,
  pnb,
  icici,
  axis,
  hdfc,
  rbl,
  amazonPay,
  roar,
  kotak,
  idfc,
  indusind,
  oneCard,
  amex,
  custom,
}

enum CardNetwork { visa, mastercard, rupay, amex }

class BankPreset {
  final BankBrand brand;
  final String label;
  final String defaultCardName;
  final CardNetwork network;
  final int defaultAprBps;

  const BankPreset({
    required this.brand,
    required this.label,
    required this.defaultCardName,
    required this.network,
    this.defaultAprBps = 3600,
  });
}

class BankCardTheme {
  final BankBrand brand;
  final String bankCode;
  final CardNetwork network;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color metallicColor;
  final Color patternTint;

  const BankCardTheme({
    required this.brand,
    required this.bankCode,
    required this.network,
    required this.gradientColors,
    required this.accentColor,
    required this.metallicColor,
    required this.patternTint,
  });
}

const List<BankPreset> kBankPresets = [
  BankPreset(brand: BankBrand.sbi, label: 'SBI', defaultCardName: 'SBI Card', network: CardNetwork.visa),
  BankPreset(brand: BankBrand.hdfc, label: 'HDFC', defaultCardName: 'HDFC Millennia', network: CardNetwork.mastercard),
  BankPreset(brand: BankBrand.icici, label: 'ICICI', defaultCardName: 'ICICI Bank', network: CardNetwork.visa),
  BankPreset(brand: BankBrand.axis, label: 'Axis', defaultCardName: 'Axis Bank', network: CardNetwork.mastercard),
  BankPreset(brand: BankBrand.pnb, label: 'PNB', defaultCardName: 'PNB Card', network: CardNetwork.rupay),
  BankPreset(brand: BankBrand.amazonPay, label: 'Amazon', defaultCardName: 'Amazon Pay', network: CardNetwork.visa),
  BankPreset(brand: BankBrand.rbl, label: 'RBL', defaultCardName: 'RBL Bank', network: CardNetwork.mastercard),
  BankPreset(brand: BankBrand.roar, label: 'Roar', defaultCardName: 'Roar Card', network: CardNetwork.rupay),
  BankPreset(brand: BankBrand.kotak, label: 'Kotak', defaultCardName: 'Kotak Bank', network: CardNetwork.visa),
  BankPreset(brand: BankBrand.idfc, label: 'IDFC', defaultCardName: 'IDFC First', network: CardNetwork.visa),
  BankPreset(brand: BankBrand.oneCard, label: 'OneCard', defaultCardName: 'OneCard Metal', network: CardNetwork.visa),
  BankPreset(brand: BankBrand.amex, label: 'Amex', defaultCardName: 'Amex SmartEarn', network: CardNetwork.amex),
  BankPreset(brand: BankBrand.custom, label: 'Other', defaultCardName: '', network: CardNetwork.visa),
];

BankCardTheme resolveBankTheme(String cardName, {bool isCleared = false}) {
  final n = cardName.toLowerCase();

  if (n.contains('amazon')) {
    return const BankCardTheme(
      brand: BankBrand.amazonPay,
      bankCode: 'APAY',
      network: CardNetwork.visa,
      gradientColors: [Color(0xFF1E2430), Color(0xFF131822), Color(0xFF0A0D12)],
      accentColor: Color(0xFFFF9900),
      metallicColor: Color(0xFFFBBF24),
      patternTint: Color(0xFFFF9900),
    );
  }
  if (n.contains('swiggy') || n.contains('hdfc')) {
    final isSwiggy = n.contains('swiggy');
    return BankCardTheme(
      brand: BankBrand.hdfc,
      bankCode: 'HDFC',
      network: CardNetwork.mastercard,
      gradientColors: isSwiggy
          ? const [Color(0xFF28191B), Color(0xFF151926), Color(0xFF0B0F19)]
          : const [Color(0xFF13264D), Color(0xFF0D1833), Color(0xFF090E1C)],
      accentColor: isSwiggy ? const Color(0xFFFC8019) : const Color(0xFF38BDF8),
      metallicColor: const Color(0xFFE2E8F0),
      patternTint: isSwiggy ? const Color(0xFFFC8019) : const Color(0xFFEF4444),
    );
  }
  if (n.contains('sbi')) {
    return const BankCardTheme(
      brand: BankBrand.sbi,
      bankCode: 'SBI',
      network: CardNetwork.visa,
      gradientColors: [Color(0xFF174591), Color(0xFF102A60), Color(0xFF081433)],
      accentColor: Color(0xFF38BDF8),
      metallicColor: Color(0xFF93C5FD),
      patternTint: Color(0xFF0EA5E9),
    );
  }
  if (n.contains('pnb')) {
    return const BankCardTheme(
      brand: BankBrand.pnb,
      bankCode: 'PNB',
      network: CardNetwork.rupay,
      gradientColors: [Color(0xFF7D1935), Color(0xFF470D1E), Color(0xFF21060F)],
      accentColor: Color(0xFFFBBF24),
      metallicColor: Color(0xFFFDE68A),
      patternTint: Color(0xFFF59E0B),
    );
  }
  if (n.contains('icici')) {
    return const BankCardTheme(
      brand: BankBrand.icici,
      bankCode: 'ICICI',
      network: CardNetwork.visa,
      gradientColors: [Color(0xFF9A3412), Color(0xFF561B0A), Color(0xFF250B05)],
      accentColor: Color(0xFFFB923C),
      metallicColor: Color(0xFFFED7AA),
      patternTint: Color(0xFFF97316),
    );
  }
  if (n.contains('axis')) {
    return const BankCardTheme(
      brand: BankBrand.axis,
      bankCode: 'AXIS',
      network: CardNetwork.mastercard,
      gradientColors: [Color(0xFF831843), Color(0xFF4E0E2A), Color(0xFF240614)],
      accentColor: Color(0xFFF472B6),
      metallicColor: Color(0xFFFBCFE8),
      patternTint: Color(0xFFEC4899),
    );
  }
  if (n.contains('roar')) {
    return const BankCardTheme(
      brand: BankBrand.roar,
      bankCode: 'ROAR',
      network: CardNetwork.rupay,
      gradientColors: [Color(0xFF23262F), Color(0xFF14171F), Color(0xFF0A0C10)],
      accentColor: Color(0xFFF59E0B),
      metallicColor: Color(0xFFFCD34D),
      patternTint: Color(0xFFF59E0B),
    );
  }
  if (n.contains('rbl')) {
    return const BankCardTheme(
      brand: BankBrand.rbl,
      bankCode: 'RBL',
      network: CardNetwork.mastercard,
      gradientColors: [Color(0xFF1D3A76), Color(0xFF102046), Color(0xFF081024)],
      accentColor: Color(0xFFEF4444),
      metallicColor: Color(0xFFCBD5E1),
      patternTint: Color(0xFF3B82F6),
    );
  }
  if (n.contains('kotak')) {
    return const BankCardTheme(
      brand: BankBrand.kotak,
      bankCode: 'KOTAK',
      network: CardNetwork.visa,
      gradientColors: [Color(0xFF881337), Color(0xFF3B0B1E), Color(0xFF140914)],
      accentColor: Color(0xFFFB7185),
      metallicColor: Color(0xFFE2E8F0),
      patternTint: Color(0xFFE11D48),
    );
  }
  if (n.contains('idfc')) {
    return const BankCardTheme(
      brand: BankBrand.idfc,
      bankCode: 'IDFC',
      network: CardNetwork.visa,
      gradientColors: [Color(0xFF6B1D2F), Color(0xFF31101C), Color(0xFF14080E)],
      accentColor: Color(0xFFFDA4AF),
      metallicColor: Color(0xFFE2E8F0),
      patternTint: Color(0xFFBE123C),
    );
  }
  if (n.contains('onecard') || n.contains('one card')) {
    return const BankCardTheme(
      brand: BankBrand.oneCard,
      bankCode: 'ONE',
      network: CardNetwork.visa,
      gradientColors: [Color(0xFF242830), Color(0xFF12151C), Color(0xFF07080C)],
      accentColor: Color(0xFF94A3B8),
      metallicColor: Color(0xFFF8FAFC),
      patternTint: Color(0xFF64748B),
    );
  }
  if (n.contains('amex') || n.contains('american')) {
    return const BankCardTheme(
      brand: BankBrand.amex,
      bankCode: 'AMEX',
      network: CardNetwork.amex,
      gradientColors: [Color(0xFF1E3B4A), Color(0xFF0E222D), Color(0xFF071219)],
      accentColor: Color(0xFF22D3EE),
      metallicColor: Color(0xFFBAE6FD),
      patternTint: Color(0xFF06B6D4),
    );
  }
  if (n.contains('indus')) {
    return const BankCardTheme(
      brand: BankBrand.indusind,
      bankCode: 'INDUS',
      network: CardNetwork.visa,
      gradientColors: [Color(0xFF5A251B), Color(0xFF2D120F), Color(0xFF120808)],
      accentColor: Color(0xFFFBBF24),
      metallicColor: Color(0xFFFDE68A),
      patternTint: Color(0xFFD97706),
    );
  }

  return BankCardTheme(
    brand: BankBrand.custom,
    bankCode: cardName.trim().isEmpty
        ? 'CARD'
        : cardName.trim().substring(0, math.min(4, cardName.trim().length)).toUpperCase(),
    network: CardNetwork.visa,
    gradientColors: isCleared
        ? const [Color(0xFF0B3B2E), Color(0xFF0C2224), Color(0xFF071117)]
        : const [Color(0xFF1E293B), Color(0xFF111827), Color(0xFF080C15)],
    accentColor: isCleared ? AppColors.accentGreen : const Color(0xFF38BDF8),
    metallicColor: const Color(0xFFE2E8F0),
    patternTint: isCleared ? AppColors.accentGreen : const Color(0xFF60A5FA),
  );
}

/// Custom vector bank icon for realistic card faces and bank picker chips.
class BankEmblemIcon extends StatelessWidget {
  final BankBrand brand;
  final String fallbackLabel;
  final double size;

  const BankEmblemIcon({
    super.key,
    required this.brand,
    this.fallbackLabel = 'C',
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.62, size * 0.62),
          painter: _BankMarkPainter(brand: brand, fallbackLabel: fallbackLabel),
        ),
      ),
    );
  }
}

class _BankMarkPainter extends CustomPainter {
  final BankBrand brand;
  final String fallbackLabel;

  _BankMarkPainter({required this.brand, required this.fallbackLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    switch (brand) {
      case BankBrand.sbi:
        // Classic SBI keyhole circle
        canvas.drawCircle(
          Offset(cx, cy),
          w * 0.44,
          Paint()..color = const Color(0xFF38BDF8),
        );
        canvas.drawCircle(
          Offset(cx, cy * 0.92),
          w * 0.13,
          Paint()..color = const Color(0xFF0B1F4C),
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy + h * 0.24), width: w * 0.09, height: h * 0.34),
          Paint()..color = const Color(0xFF0B1F4C),
        );
        break;

      case BankBrand.hdfc:
        // Classic HDFC architectural red frame + blue center square
        final outerPaint = Paint()
          ..color = const Color(0xFFEF4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.16;
        canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76), outerPaint);
        final cutPaint = Paint()..color = const Color(0xFF151926);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.95, height: h * 0.18), cutPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.18, height: h * 0.95), cutPaint);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: w * 0.32, height: h * 0.32),
          Paint()..color = const Color(0xFF3B82F6),
        );
        break;

      case BankBrand.axis:
        // Sharp Axis geometric 'A' delta
        final p = Path()
          ..moveTo(cx, h * 0.08)
          ..lineTo(w * 0.92, h * 0.88)
          ..lineTo(w * 0.62, h * 0.88)
          ..lineTo(cx, h * 0.42)
          ..lineTo(w * 0.38, h * 0.88)
          ..lineTo(w * 0.08, h * 0.88)
          ..close();
        canvas.drawPath(p, Paint()..color = const Color(0xFFF472B6));
        break;

      case BankBrand.icici:
        // Stylized flame/swoosh crest
        final p = Path()
          ..moveTo(cx, h * 0.06)
          ..quadraticBezierTo(w * 0.96, h * 0.34, cx, h * 0.94)
          ..quadraticBezierTo(w * 0.06, h * 0.44, cx, h * 0.06)
          ..close();
        canvas.drawPath(p, Paint()..color = const Color(0xFFFB923C));
        canvas.drawCircle(
          Offset(cx, h * 0.44),
          w * 0.14,
          Paint()..color = const Color(0xFFFFEDD5),
        );
        break;

      case BankBrand.pnb:
        // Radiant rotated diamond emblem
        final diamond = Path()
          ..moveTo(cx, h * 0.06)
          ..lineTo(w * 0.94, cy)
          ..lineTo(cx, h * 0.94)
          ..lineTo(w * 0.06, cy)
          ..close();
        canvas.drawPath(diamond, Paint()..color = const Color(0xFFFBBF24));
        canvas.drawCircle(Offset(cx, cy), w * 0.18, Paint()..color = const Color(0xFF5E1027));
        break;

      case BankBrand.amazonPay:
        // Gold Amazon smile curve + arrow
        final arcPaint = Paint()
          ..color = const Color(0xFFFF9900)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.14
          ..strokeCap = StrokeCap.round;
        final arcPath = Path()
          ..moveTo(w * 0.12, h * 0.45)
          ..quadraticBezierTo(cx, h * 0.82, w * 0.86, h * 0.42);
        canvas.drawPath(arcPath, arcPaint);
        final tip = Path()
          ..moveTo(w * 0.72, h * 0.36)
          ..lineTo(w * 0.90, h * 0.40)
          ..lineTo(w * 0.82, h * 0.56);
        canvas.drawPath(tip, arcPaint);
        break;

      case BankBrand.roar:
        // Electric lightning/claw bolt
        final bolt = Path()
          ..moveTo(w * 0.62, h * 0.06)
          ..lineTo(w * 0.20, h * 0.54)
          ..lineTo(cx, h * 0.54)
          ..lineTo(w * 0.36, h * 0.94)
          ..lineTo(w * 0.82, h * 0.44)
          ..lineTo(w * 0.52, h * 0.44)
          ..close();
        canvas.drawPath(bolt, Paint()..color = const Color(0xFFFBBF24));
        break;

      case BankBrand.rbl:
        // Bold indigo-crimson shield prism
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.14, w * 0.5, h * 0.72), Radius.circular(w * 0.12)),
          Paint()..color = const Color(0xFF60A5FA),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.38, h * 0.14, w * 0.5, h * 0.72), Radius.circular(w * 0.12)),
          Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.9),
        );
        break;

      case BankBrand.kotak:
        // Stylized Kotak infinity ribbon
        final loopPaint = Paint()
          ..color = const Color(0xFFFB7185)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.15
          ..strokeCap = StrokeCap.round;
        canvas.drawCircle(Offset(w * 0.32, cy), w * 0.20, loopPaint);
        canvas.drawCircle(Offset(w * 0.68, cy), w * 0.20, loopPaint);
        break;

      default:
        final tp = TextPainter(
          text: TextSpan(
            text: fallbackLabel.isNotEmpty ? fallbackLabel[0].toUpperCase() : 'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: w * 0.62,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BankMarkPainter oldDelegate) =>
      oldDelegate.brand != brand || oldDelegate.fallbackLabel != fallbackLabel;
}

/// Brushed metallic EMV chip vector graphic.
class _EmvChip extends StatelessWidget {
  final Color tint;
  const _EmvChip({required this.tint});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 26),
      painter: _EmvChipPainter(tint: tint),
    );
  }
}

class _EmvChipPainter extends CustomPainter {
  final Color tint;
  const _EmvChipPainter({required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFFFDE68A), tint, 0.25)!,
        const Color(0xFFD97706),
        Color.lerp(const Color(0xFFFEF3C7), tint, 0.2)!,
      ],
    ).createShader(rect);

    canvas.drawRRect(rr, Paint()..shader = shader);
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rr, linePaint);
    canvas.drawLine(Offset(0, size.height * 0.34), Offset(size.width * 0.34, size.height * 0.34), linePaint);
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width * 0.34, size.height * 0.66), linePaint);
    canvas.drawLine(Offset(size.width * 0.66, size.height * 0.34), Offset(size.width, size.height * 0.34), linePaint);
    canvas.drawLine(Offset(size.width * 0.66, size.height * 0.66), Offset(size.width, size.height * 0.66), linePaint);
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.34, 2, size.width * 0.66, size.height - 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmvChipPainter oldDelegate) => oldDelegate.tint != tint;
}

class _NetworkBadge extends StatelessWidget {
  final CardNetwork network;
  const _NetworkBadge({required this.network});

  @override
  Widget build(BuildContext context) {
    switch (network) {
      case CardNetwork.mastercard:
        return SizedBox(
          width: 38,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xCCEB001B),
                  ),
                ),
              ),
              Positioned(
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xCCF79E1B),
                  ),
                ),
              ),
            ],
          ),
        );
      case CardNetwork.rupay:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Text(
            'RuPay',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        );
      case CardNetwork.amex:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
          ),
          child: const Text(
            'AMEX',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        );
      case CardNetwork.visa:
        return const Text(
          'VISA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.8,
            color: Colors.white,
          ),
        );
    }
  }
}

/// Realistic CRED-inspired animated physical bank credit card.
/// Full card surface is touchable to immediately update values without accidental deletion.
class CredCreditCard extends StatefulWidget {
  final CreditCardModel card;
  final bool hidden;
  final bool isPreview;
  final VoidCallback? onTapCard;
  final VoidCallback? onTapOutstanding;
  final VoidCallback? onTapAvailable;
  final VoidCallback? onTapTag;

  const CredCreditCard({
    super.key,
    required this.card,
    this.hidden = false,
    this.isPreview = false,
    this.onTapCard,
    this.onTapOutstanding,
    this.onTapAvailable,
    this.onTapTag,
  });

  @override
  State<CredCreditCard> createState() => _CredCreditCardState();
}

class _CredCreditCardState extends State<CredCreditCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  bool _pressed = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  String _last4Digits() {
    final seed = '${widget.card.id}_${widget.card.name}'.codeUnits.fold<int>(4129, (a, b) => (a * 31 + b) & 0x7FFFFFFF);
    final digits = 1000 + (seed % 9000);
    return digits.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final theme = resolveBankTheme(c.name, isCleared: c.isCleared);
    final utilColor = AppColors.utilizationColor(c.utilizationPct);
    final last4 = _last4Digits();

    return MouseRegion(
      onEnter: widget.isPreview ? null : (_) => setState(() => _hovered = true),
      onExit: widget.isPreview ? null : (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: widget.isPreview ? null : (_) => setState(() => _pressed = true),
        onTapCancel: widget.isPreview ? null : () => setState(() => _pressed = false),
        onTapUp: widget.isPreview ? null : (_) => setState(() => _pressed = false),
        onTap: widget.onTapCard,
        child: AnimatedScale(
          scale: _pressed ? 0.978 : (_hovered ? 1.008 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
              border: Border.all(
                color: c.isCleared
                    ? AppColors.accentGreen.withValues(alpha: 0.55)
                    : (_hovered
                        ? theme.accentColor.withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.16)),
                width: _hovered || c.isCleared ? 1.3 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: _hovered ? 26 : 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: (c.isCleared ? AppColors.accentGreen : theme.accentColor)
                      .withValues(alpha: _hovered ? 0.18 : 0.08),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                children: [
                  // Subtle geometric metallic rings in background
                  Positioned(
                    right: -46,
                    top: -46,
                    child: IgnorePointer(
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              theme.patternTint.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Animated diagonal glass metallic sheen sweep
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (context, _) {
                          final slide = (_shimmerCtrl.value * 3.0) - 1.0;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(slide - 0.65, -1.0),
                                end: Alignment(slide + 0.65, 1.0),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.045),
                                  Colors.transparent,
                                ],
                                stops: const [0.25, 0.5, 0.75],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Bank Emblem + Card Name + Tag Pill (clickable to edit Tag/Limit)
                        Row(
                          children: [
                            BankEmblemIcon(
                              brand: theme.brand,
                              fallbackLabel: theme.bankCode,
                              size: 36,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name.isEmpty ? 'New Credit Card' : c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    '•••• •••• •••• $last4',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.62),
                                      letterSpacing: 1.0,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onTapTag ?? widget.onTapCard,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 138),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (c.isCleared ? AppColors.accentGreen : Colors.black)
                                        .withValues(alpha: c.isCleared ? 0.24 : 0.34),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: c.isCleared
                                          ? AppColors.accentGreen.withValues(alpha: 0.7)
                                          : Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    c.isCleared
                                        ? '✓ CLEARED'
                                        : (c.categoryTag.trim().isEmpty ? 'NO TAG' : c.categoryTag),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: c.isCleared ? const Color(0xFF6EE7B7) : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Row 2: Metallic EMV Chip + Contactless + Network Mark
                        Row(
                          children: [
                            _EmvChip(tint: theme.metallicColor),
                            const SizedBox(width: 8),
                            Transform.rotate(
                              angle: math.pi / 2,
                              child: Icon(
                                Icons.wifi_rounded,
                                size: 17,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            const Spacer(),
                            _NetworkBadge(network: theme.network),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Row 3: Directly Touchable Financial Figures (CRED dark glass wells)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _CardValueWell(
                                  label: 'TOTAL DUE',
                                  value: widget.hidden ? '₹ ••••••' : c.outstandingFormatted,
                                  valueColor: c.isCleared ? const Color(0xFF6EE7B7) : Colors.white,
                                  subtitle: widget.isPreview ? null : 'Tap to Pay / Spend',
                                  onTap: widget.onTapOutstanding ?? widget.onTapCard,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _CardValueWell(
                                  label: 'AVAILABLE',
                                  value: widget.hidden ? '₹ ••••••' : c.availableFormatted,
                                  valueColor: const Color(0xFF6EE7B7),
                                  subtitle: widget.isPreview
                                      ? 'Limit ${c.totalLimitFormatted}'
                                      : 'of ${widget.hidden ? '₹ ••••' : c.totalLimitFormatted} · Edit',
                                  alignRight: true,
                                  onTap: widget.onTapAvailable ?? widget.onTapCard,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Row 4: Utilization bar + Tap cue
                        Row(
                          children: [
                            Text(
                              'UTIL ${c.utilizationFormatted}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (c.utilizationPct / 100).clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                                  valueColor: AlwaysStoppedAnimation<Color>(utilColor),
                                ),
                              ),
                            ),
                            if (!widget.isPreview) ...[
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Tap to update',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.72),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardValueWell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? subtitle;
  final bool alignRight;
  final VoidCallback? onTap;

  const _CardValueWell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.subtitle,
    this.alignRight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: Colors.white.withValues(alpha: 0.58),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.52),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
