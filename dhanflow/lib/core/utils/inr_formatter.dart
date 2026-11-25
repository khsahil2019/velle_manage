/// INR Formatter — Indian number system (lakh/crore grouping)
/// Operates on PAISE (integer) values for accuracy.
class INRFormatter {
  INRFormatter._();

  static String formatPaise(int paise, {bool showSymbol = true}) {
    final isNegative = paise < 0;
    final absPaise = paise.abs();

    final rupees = absPaise ~/ 100;
    final paiseRemainder = absPaise % 100;

    final formatted = _formatRupeeInteger(rupees);
    final paiseStr = paiseRemainder.toString().padLeft(2, '0');
    final symbol = showSymbol ? '₹' : '';
    final sign = isNegative ? '-' : '';

    return '$sign$symbol$formatted.$paiseStr';
  }

  static String formatCompactPaise(int paise) {
    final absVal = paise.abs() / 100.0;
    final sign = paise < 0 ? '-' : '';
    if (absVal >= 10000000) {
      return '$sign₹${(absVal / 10000000).toStringAsFixed(2)}Cr';
    }
    if (absVal >= 100000) {
      return '$sign₹${(absVal / 100000).toStringAsFixed(2)}L';
    }
    if (absVal >= 1000) {
      return '$sign₹${(absVal / 1000).toStringAsFixed(1)}k';
    }
    return formatPaise(paise);
  }

  static String formatDouble(double rupees, {bool showSymbol = true}) {
    return formatPaise((rupees * 100).round(), showSymbol: showSymbol);
  }

  static String formatGrams(int gramsX10000) {
    final grams = gramsX10000 / 10000.0;
    return '${grams.toStringAsFixed(4)} gm';
  }

  static String formatRatePerGm(int rateInPaise, {bool showSymbol = true}) {
    return '${formatPaise(rateInPaise, showSymbol: showSymbol)}/gm';
  }

  static String formatPct(double pct) {
    return '${pct.toStringAsFixed(1)}%';
  }

  static String formatDateTime(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]}, $h:$m $ampm';
  }

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDateTime(d);
  }

  static String _formatRupeeInteger(int rupees) {
    if (rupees == 0) return '0';

    final str = rupees.toString();
    if (str.length <= 3) return str;

    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }

    return '${buffer.toString()},$lastThree';
  }
}

/// Paise math — ALL monetary arithmetic uses integer / BigInt operations.
class PaiseMath {
  PaiseMath._();

  static int addGST3Pct(int paise) => ((paise * 103) + 50) ~/ 100;

  static int gst3Pct(int paise) => ((paise * 3) + 50) ~/ 100;

  static int removeGST3Pct(int paiseInclGST) => ((paiseInclGST * 100) + 51) ~/ 103;

  static int percentOf(int paise, int pct) => ((paise * pct) + 50) ~/ 100;

  /// Compute pre-GST paise from gramsX10000 and ratePaise/gm using half-up rounding.
  static int preGstForGrams(int gramsX10000, int ratePaise) {
    final prod = BigInt.from(gramsX10000) * BigInt.from(ratePaise);
    return ((prod + BigInt.from(5000)) ~/ BigInt.from(10000)).toInt();
  }

  /// Weighted average buy rate with half-up integer rounding.
  static int weightedAvgRate({
    required List<({int gramsX10000, int ratePaise})> transactions,
  }) {
    if (transactions.isEmpty) return 0;

    int totalGramsX10000 = 0;
    var weightedSum = BigInt.zero;

    for (final t in transactions) {
      totalGramsX10000 += t.gramsX10000;
      weightedSum += BigInt.from(t.gramsX10000) * BigInt.from(t.ratePaise);
    }

    if (totalGramsX10000 == 0) return 0;
    final denom = BigInt.from(totalGramsX10000);
    final half = denom ~/ BigInt.two;
    return ((weightedSum + half) ~/ denom).toInt();
  }

  /// Weighted effective cost per gram given totalCashPaidPaise & totalGramsX10000.
  static int effectiveCostPerGram(int totalCashPaidPaise, int totalGramsX10000) {
    if (totalGramsX10000 == 0) return 0;
    final num = BigInt.from(totalCashPaidPaise) * BigInt.from(10000);
    final denom = BigInt.from(totalGramsX10000);
    final half = denom ~/ BigInt.two;
    return ((num + half) ~/ denom).toInt();
  }

  static int clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int subtractSafe(int from, int amount) {
    return (from - amount).clamp(0, from > 0 ? from : 0);
  }

  static int rupeesToPaise(double rupees) => (rupees * 100).round();

  static int gramsToX10000(double grams) => (grams * 10000).round();

  static double paiseToRupees(int paise) => paise / 100.0;
}
