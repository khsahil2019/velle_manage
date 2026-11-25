import 'package:dhanflow/core/constants/api_constants.dart';
import 'package:dhanflow/core/network/api_client.dart';
import 'package:dhanflow/services/local_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
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

class AuthCubit extends Cubit<AuthState> {
  final ApiClient apiClient;

  AuthCubit({required this.apiClient}) : super(const AuthOfflineGuest());

  void loadSession() {
    final user = LocalStorageService.getUser();
    final tokens = LocalStorageService.getTokens();
    if (user != null && tokens != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthOfflineGuest());
    }
  }

  Future<void> login({required String email, required String password}) async {
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
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response?.data['message'] as String?)
          : null;
      emit(AuthError(msg ?? 'Login failed: check API URL & network'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    bool seedInitialData = true,
  }) async {
    emit(const AuthLoading());
    try {
      final res = await apiClient.post(ApiConstants.register, data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'seed_initial_data': seedInitialData,
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
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response?.data['message'] as String?)
          : null;
      emit(AuthError(msg ?? 'Registration failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await LocalStorageService.clearAuthSession();
    emit(const AuthOfflineGuest());
  }
}
