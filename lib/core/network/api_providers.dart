import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carenest_app/core/config/env.dart';
import 'package:carenest_app/core/network/api_client.dart';
import 'package:carenest_app/core/network/auth_interceptor.dart';
import 'package:carenest_app/core/network/dio_client.dart';

/// Base URL API đã gồm tiền tố `/api` (`--dart-define API_BASE_URL`).
final apiBaseUrlProvider = Provider<String>((ref) => Env.apiBaseUrl);

/// Adapter HTTP; `null` = mặc định của Dio. Test ghi đè bằng adapter giả.
final httpClientAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

/// Nguồn token của phiên. Ghép ở bootstrap với SessionManager của feature auth
/// (core không import feature — CODING_GUIDE §2.2).
final accessTokenSourceProvider = Provider<AccessTokenSource>(
  (ref) => throw UnimplementedError(
    'accessTokenSourceProvider phải được ghi đè (authOverrides)',
  ),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    createApiDio(
      baseUrl: ref.watch(apiBaseUrlProvider),
      tokens: ref.watch(accessTokenSourceProvider),
      adapter: ref.watch(httpClientAdapterProvider),
    ),
  ),
);
