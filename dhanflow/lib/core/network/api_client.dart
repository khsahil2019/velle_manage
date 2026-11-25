import '../constants/api_constants.dart';
import '../../services/local_storage_service.dart';
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.normalizeBaseUrl(baseUrl ?? ApiConstants.defaultBaseUrl),
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final tokens = LocalStorageService.getTokens();
        if (tokens != null && tokens['access_token'] != null) {
          options.headers['Authorization'] = 'Bearer ${tokens['access_token']}';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401 &&
            !err.requestOptions.path.contains('/auth/')) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final tokens = LocalStorageService.getTokens();
            err.requestOptions.headers['Authorization'] =
                'Bearer ${tokens?['access_token']}';
            final cloneReq = await _dio.fetch(err.requestOptions);
            return handler.resolve(cloneReq);
          }
        }
        handler.next(err);
      },
    ));
  }

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = ApiConstants.normalizeBaseUrl(newUrl);
  }

  String get baseUrl => _dio.options.baseUrl;

  Future<bool> _tryRefreshToken() async {
    final tokens = LocalStorageService.getTokens();
    final refreshToken = tokens?['refresh_token'];
    if (refreshToken == null) return false;
    try {
      final res = await _dio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        final newTokens = data['tokens'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        await LocalStorageService.saveAuthSession(
          accessToken: newTokens['access_token'] as String,
          refreshToken: newTokens['refresh_token'] as String,
          user: user,
        );
        return true;
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Only clear saved session if server explicitly rejects refresh token (401/403),
      // keeping permanent offline-capable login across temporary network glitches.
      if (status == 401 || status == 403) {
        await LocalStorageService.clearAuthSession();
      }
    } catch (_) {
      // Preserve local session on transient errors
    }
    return false;
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response<dynamic>> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response<dynamic>> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response<dynamic>> delete(String path,
          {Map<String, dynamic>? query}) =>
      _dio.delete(path, queryParameters: query);
}
