import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta_plogging/core/network/api_endpoints.dart';
import 'package:meta_plogging/core/network/auth_expired_notifier.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor(dio, ref));
  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  _AuthInterceptor(this._dio, this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken == null) {
          await _forceLogout();
          handler.next(err);
          return;
        }

        // 인터셉터 없는 별도 Dio로 refresh — 만료 토큰 헤더가 붙지 않도록
        final plainDio = Dio(
          BaseOptions(baseUrl: ApiEndpoints.baseUrl),
        );
        final response = await plainDio.post(
          ApiEndpoints.refreshToken,
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken = response.data['access_token'] as String;
        await _storage.write(key: _accessTokenKey, value: newAccessToken);

        // 원래 요청 재시도
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
        return;
      } catch (_) {
        await _forceLogout();
      }
    }
    handler.next(err);
  }

  Future<void> _forceLogout() async {
    await _storage.deleteAll();
    try {
      _ref.read(authExpiredProvider.notifier).expire();
    } catch (_) {}
  }
}
