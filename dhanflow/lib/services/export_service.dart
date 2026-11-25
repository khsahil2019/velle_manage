import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class ExportService {
  ExportService._();

  static String toPrettyJson(DhanflowAppState state) {
    return const JsonEncoder.withIndent('  ').convert(state.toJson());
  }

  static Future<void> exportBackup(DhanflowAppState state) async {
    final jsonStr = toPrettyJson(state);
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final fileName = 'trustvly-backup-$dateStr.json';

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: jsonStr));
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Trustvly Financial Backup ($dateStr)');
  }

  static DhanflowAppState parseAndValidateJson(String rawJson) {
    final decoded = jsonDecode(rawJson.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object');
    }
    if (!decoded.containsKey('credit_cards') ||
        !decoded.containsKey('bullion_transactions')) {
      throw const FormatException(
          'Missing required credit_cards or bullion_transactions fields');
    }
    return DhanflowAppState.fromJson(decoded);
  }
}
