import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../services/local_storage_service.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthOfflineGuest extends AuthState {
  const AuthOfflineGuest();
}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  final String? storageDriver;
  final bool justSignedUp;
  final bool uploadLocalOnSignup;

  const AuthAuthenticated(
    this.user, {
    this.storageDriver,
    this.justSignedUp = false,
    this.uploadLocalOnSignup = false,
  });

  String get initials {
    final name = (user['name'] as String? ?? 'U').trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => [user, storageDriver, justSignedUp, uploadLocalOnSignup];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class ApiHealthStatus {
  final bool reachable;
  final bool databaseConfigured;
  final String? databaseDriver;
  final String? runtime;
  final String endpoint;
  final String message;

  const ApiHealthStatus({
    required this.reachable,
    required this.databaseConfigured,
    required this.endpoint,
    required this.message,
    this.databaseDriver,
    this.runtime,
  });

  bool get isFullyReady => reachable && databaseConfigured;
}

class AuthCubit extends Cubit<AuthState> {
  final ApiClient apiClient;

  AuthCubit({required this.apiClient}) : super(const AuthOfflineGuest());

  /// Verifies live API reachability and whether backend DB credentials are configured.
  Future<ApiHealthStatus> checkBackendHealth() async {
    final endpoint = '${apiClient.baseUrl}${ApiConstants.health}';
    try {
      final res = await apiClient.get(ApiConstants.health);
      if (res.data is Map && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>? ?? {};
        final dbConfigured = data['database_configured'] as bool? ?? false;
        final driver = data['database_driver'] as String?;
        final runtime = data['runtime'] as String?;
        final apiMsg = res.data['message'] as String? ?? 'OK';
        return ApiHealthStatus(
          reachable: true,
          databaseConfigured: dbConfigured,
          databaseDriver: driver,
          runtime: runtime,
          endpoint: endpoint,
          message: dbConfigured
              ? '$runtime Online · Database ready (${(driver ?? 'SQL').toUpperCase()})'
              : '$runtime Online · $apiMsg',
        );
      }
      return ApiHealthStatus(
        reachable: false,
        databaseConfigured: false,
        endpoint: endpoint,
        message: 'Unexpected response from $endpoint',
      );
    } on DioException catch (e) {
      return ApiHealthStatus(
        reachable: e.response != null,
        databaseConfigured: false,
        endpoint: endpoint,
        message: _extractDioError(e, 'Unable to reach API at $endpoint'),
      );
    } catch (e) {
      return ApiHealthStatus(
        reachable: false,
        databaseConfigured: false,
        endpoint: endpoint,
        message: e.toString(),
      );
    }
  }

  String _extractDioError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
      return data['message'] as String;
    }
    final status = e.response?.statusCode;
    if (status != null) {
      return '$fallback (HTTP $status)';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network/CORS error connecting to ${apiClient.baseUrl}. Check internet and Backend API Endpoint URL.';
    }
    return fallback;
  }

  void loadSession() {
    final user = LocalStorageService.getUser();
    final tokens = LocalStorageService.getTokens();
    if (user != null && tokens != null) {
      emit(AuthAuthenticated(user));
      refreshProfile();
    } else {
      emit(const AuthOfflineGuest());
    }
  }

  Future<void> refreshProfile() async {
    if (LocalStorageService.getTokens() == null) return;
    try {
      final res = await apiClient.get(ApiConstants.authMe);
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        final driver = data['storage_driver'] as String?;
        final tokens = LocalStorageService.getTokens();
        if (tokens != null) {
          await LocalStorageService.saveAuthSession(
            accessToken: tokens['access_token']!,
            refreshToken: tokens['refresh_token']!,
            user: user,
          );
        }
        emit(AuthAuthenticated(user, storageDriver: driver));
      }
    } catch (_) {
      // Keep cached session if offline
    }
  }

  Future<bool> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final res = await apiClient.post(ApiConstants.login, data: {
        'email': email.trim(),
        'password': password,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      await LocalStorageService.saveAuthSession(
        accessToken: tokens['access_token'] as String,
        refreshToken: tokens['refresh_token'] as String,
        user: user,
      );
      emit(AuthAuthenticated(user));
      refreshProfile();
      return true;
    } on DioException catch (e) {
      emit(AuthError(_extractDioError(e, 'Sign in failed: verify credentials and server connection')));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    bool seedInitialData = true,
    bool uploadCurrentLocalData = false,
  }) async {
    emit(const AuthLoading());
    try {
      final res = await apiClient.post(ApiConstants.register, data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'seed_initial_data': uploadCurrentLocalData ? false : seedInitialData,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      await LocalStorageService.saveAuthSession(
        accessToken: tokens['access_token'] as String,
        refreshToken: tokens['refresh_token'] as String,
        user: user,
      );
      emit(AuthAuthenticated(
        user,
        justSignedUp: true,
        uploadLocalOnSignup: uploadCurrentLocalData,
      ));
      return true;
    } on DioException catch (e) {
      emit(AuthError(_extractDioError(e, 'Registration failed')));
      return false;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (LocalStorageService.getTokens() != null) {
        await apiClient.post(ApiConstants.authLogout);
      }
    } catch (_) {
      // Clear local session regardless of network state
    }
    await LocalStorageService.clearAuthSession();
    emit(const AuthOfflineGuest());
  }

  void clearError() {
    if (state is AuthError) {
      emit(const AuthOfflineGuest());
    }
  }
}
