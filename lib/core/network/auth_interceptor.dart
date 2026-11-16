import 'package:dio/dio.dart';

import 'package:carenest_app/core/errors/app_failure.dart';

/// Nguồn access token cho [AuthInterceptor]. Implementation ở feature auth; core không import feature.
abstract interface class AccessTokenSource {
  /// Token còn hạn (refresh trước nếu sắp hết); `null` = chưa đăng nhập.
  /// Không liên lạc được Keycloak ⇒ ném [AppFailure] (vd. [NetworkFailure]).
  Future<String?> validAccessToken();

  /// Gọi sau 401: `true` = đã có token mới; `false` = phiên đã hết.
  /// Không liên lạc được Keycloak ⇒ ném [AppFailure].
  Future<bool> refreshAfterUnauthorized();
}

/// Gắn Bearer cho request tới host của API; 401 ⇒ refresh một lần rồi gửi lại một lần.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._tokens,
    required this._apiBase,
  });

  /// `extra` của request công khai (vd. `POST /parent-activation`): không Bearer, không refresh.
  static const skipAuthKey = 'skipAuth';
  static const _retriedKey = 'authRetried';

  final Dio _dio;
  final AccessTokenSource _tokens;
  final Uri _apiBase;

  // Không gửi token tới host khác (ảnh/tệp ngoài, redirect) — CODING_GUIDE §5.5
  bool _applies(RequestOptions options) =>
      options.extra[skipAuthKey] != true &&
      options.uri.scheme == _apiBase.scheme &&
      options.uri.host == _apiBase.host &&
      options.uri.port == _apiBase.port;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_applies(options)) return handler.next(options);
    try {
      final token = await _tokens.validAccessToken();
      if (token == null) {
        options.headers.remove('Authorization');
      } else {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } on AppFailure catch (failure) {
      handler.reject(DioException(requestOptions: options, error: failure));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    // 401 của Resource Server xảy ra trước controller ⇒ gửi lại body JSON an toàn; FormData là stream, không gửi lại
    final canRetry =
        err.response?.statusCode == 401 &&
        _applies(options) &&
        options.extra[_retriedKey] != true &&
        options.data is! FormData;
    if (!canRetry) return handler.next(err);

    final bool refreshed;
    try {
      refreshed = await _tokens.refreshAfterUnauthorized();
    } on AppFailure catch (failure) {
      return handler.next(
        DioException(requestOptions: options, error: failure),
      );
    }
    if (!refreshed) return handler.next(err);

    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
