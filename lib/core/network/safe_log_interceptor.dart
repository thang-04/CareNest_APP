import 'package:dio/dio.dart';

/// Log mỗi request một dòng `METHOD path status ms`. Không header, query, body: không lộ token
/// hay dữ liệu trẻ (.claude/rules/api-client.md); id số trong path thay bằng `{id}`.
class SafeLogInterceptor extends Interceptor {
  SafeLogInterceptor({required this._sink, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _startedKey = 'logStartedAt';

  final void Function(String line) _sink;
  final DateTime Function() _now;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedKey] = _now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _log(RequestOptions options, int? status) {
    final started = options.extra[_startedKey];
    final ms = started is DateTime
        ? _now().difference(started).inMilliseconds
        : 0;
    _sink(
      '${options.method} ${maskPath(options.uri.path)} ${status ?? 'ERR'} ${ms}ms',
    );
  }
}

/// `/api/children/12/health` ⇒ `/api/children/{id}/health`.
String maskPath(String path) => path
    .split('/')
    .map((segment) => RegExp(r'^\d+$').hasMatch(segment) ? '{id}' : segment)
    .join('/');
