import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:carenest_app/core/network/auth_interceptor.dart';
import 'package:carenest_app/core/network/safe_log_interceptor.dart';

/// Dio dùng chung cho API CareNest. `baseUrl` đã gồm tiền tố API (vd. `http://localhost:8080/api`).
Dio createApiDio({
  required String baseUrl,
  required AccessTokenSource tokens,
  HttpClientAdapter? adapter,
  void Function(String line)? logSink,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  // Log chỉ ở bản debug (release không log request)
  if (kDebugMode) {
    dio.interceptors.add(SafeLogInterceptor(sink: logSink ?? debugPrint));
  }
  dio.interceptors.add(
    AuthInterceptor(dio: dio, tokens: tokens, apiBase: Uri.parse(baseUrl)),
  );
  return dio;
}
