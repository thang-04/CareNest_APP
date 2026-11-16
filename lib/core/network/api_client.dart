import 'package:dio/dio.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_envelope.dart';
import 'package:carenest_app/core/network/api_error_mapper.dart';

/// Cửa duy nhất gọi BE: parse envelope, trả `data` đã decode; mọi lỗi ném [AppFailure].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) => _send('GET', path, query: query, decode: decode, cancel: cancelToken);

  /// `skipAuth`: API công khai (vd. `POST /parent-activation`) ⇒ không gắn Bearer, không refresh.
  Future<T> post<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
    bool skipAuth = false,
  }) => _send(
    'POST',
    path,
    body: body,
    decode: decode,
    cancel: cancelToken,
    skipAuth: skipAuth,
  );

  Future<T> put<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) => _send('PUT', path, body: body, decode: decode, cancel: cancelToken);

  Future<T> patch<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) => _send('PATCH', path, body: body, decode: decode, cancel: cancelToken);

  Future<T> delete<T>(
    String path, {
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) => _send('DELETE', path, decode: decode, cancel: cancelToken);

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    required T Function(Object? data) decode,
    CancelToken? cancel,
    bool skipAuth = false,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancel,
        options: Options(
          method: method,
          extra: skipAuth ? const {'skipAuth': true} : null,
        ),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
    final status = response.statusCode ?? 0;
    final data = unwrapEnvelope(response.data, status);
    try {
      return decode(data);
    } catch (_) {
      // DTO không khớp shape BE trả ⇒ lỗi contract, không để TypeError lọt ra màn hình
      throw ContractFailure(status: status);
    }
  }
}
