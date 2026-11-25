import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';
import 'seed_service.dart';

class LocalStorageService {
  static const String _boxName = 'dhanflow_storage';
  static const String _stateKey = 'app_state_v1';
  static const String _undoStackKey = 'undo_stack_v1';
  static const String _tokenKey = 'auth_tokens_v1';
  static const String _userKey = 'auth_user_v1';

  static Box<String>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  static Box<String> get _requireBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('LocalStorageService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Load state from Hive or seed on first launch.
  static DhanflowAppState loadState() {
    final raw = _requireBox.get(_stateKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = DhanflowAppState.fromJson(decoded);
        final normalizedUrl = ApiConstants.normalizeBaseUrl(loaded.settings.apiBaseUrl);
        if (normalizedUrl != loaded.settings.apiBaseUrl) {
          final migrated = loaded.copyWith(
            settings: loaded.settings.copyWith(apiBaseUrl: normalizedUrl),
          );
          saveState(migrated);
          return migrated;
        }
        return loaded;
      } catch (_) {
        // Fallback safely if corrupted, preserve raw backup key
        _requireBox.put('corrupted_backup_${DateTime.now().millisecondsSinceEpoch}', raw);
      }
    }
    final seed = SeedService.createInitialState();
    saveState(seed);
    return seed;
  }

  static void saveState(DhanflowAppState state) {
    _requireBox.put(_stateKey, jsonEncode(state.toJson()));
  }

  static void pushUndoSnapshot(DhanflowAppState state) {
    final stackRaw = _requireBox.get(_undoStackKey);
    final stack = stackRaw != null ? (jsonDecode(stackRaw) as List<dynamic>).cast<String>() : <String>[];
    stack.insert(0, jsonEncode(state.toJson()));
    if (stack.length > 15) stack.removeLast();
    _requireBox.put(_undoStackKey, jsonEncode(stack));
  }

  static bool get canUndo {
    final stackRaw = _requireBox.get(_undoStackKey);
    if (stackRaw == null) return false;
    final stack = jsonDecode(stackRaw) as List<dynamic>;
    return stack.isNotEmpty;
  }

  /// Restores the previous financial balances while preserving immutable audit history
  /// by appending a reversing log entry rather than erasing history.
  static DhanflowAppState? popUndoSnapshot(DhanflowAppState current) {
    final stackRaw = _requireBox.get(_undoStackKey);
    if (stackRaw == null) return null;
    final stack = (jsonDecode(stackRaw) as List<dynamic>).cast<String>();
    if (stack.isEmpty) return null;

    final previousJson = stack.removeAt(0);
    _requireBox.put(_undoStackKey, jsonEncode(stack));

    final restored = DhanflowAppState.fromJson(jsonDecode(previousJson) as Map<String, dynamic>);

    // Immutable history: mark latest active event reversed and prepend reversing log entry
    final updatedLog = <ActivityLogModel>[
      ActivityLogModel(
        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
        eventType: 'REVERSAL',
        description: 'Reverted last action via Undo (balances restored cleanly)',
        createdAt: DateTime.now(),
      ),
      ...current.activityLog.map((e) {
        if (!e.isReversed && e == current.activityLog.firstWhere((x) => !x.isReversed && x.eventType != 'REVERSAL', orElse: () => e)) {
          return e.copyWith(isReversed: true);
        }
        return e;
      }),
    ];

    final finalState = restored.copyWith(
      lastUpdated: DateTime.now(),
      activityLog: updatedLog.take(300).toList(),
    );
    saveState(finalState);
    return finalState;
  }

  static void clearUndoStack() {
    _requireBox.delete(_undoStackKey);
  }

  static Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await _requireBox.put(
      _tokenKey,
      jsonEncode({'access_token': accessToken, 'refresh_token': refreshToken}),
    );
    await _requireBox.put(_userKey, jsonEncode(user));
  }

  static Map<String, String>? getTokens() {
    final raw = _requireBox.get(_tokenKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'access_token': map['access_token'] as String,
      'refresh_token': map['refresh_token'] as String,
    };
  }

  static Map<String, dynamic>? getUser() {
    final raw = _requireBox.get(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearAuthSession() async {
    await _requireBox.delete(_tokenKey);
    await _requireBox.delete(_userKey);
  }
}
