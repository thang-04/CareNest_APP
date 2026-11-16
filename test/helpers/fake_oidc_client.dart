import 'dart:async';

import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';

/// OidcClient giả: trả token theo hàng đợi, đếm số lần gọi. Phần tử hàng đợi là
/// [OidcTokens], [OidcFailure] (ném ra) hoặc [Completer] (giữ kết quả để test chạy song song).
class FakeOidcClient implements OidcClient {
  final List<Object> signInResults = [];
  final List<Object> refreshResults = [];
  final List<String> refreshedWith = [];
  final List<String> revoked = [];
  int signInCalls = 0;
  String? lastLoginHint;
  Object? revokeError;

  int get refreshCalls => refreshedWith.length;

  @override
  Future<OidcTokens> signIn({String? loginHint}) async {
    signInCalls++;
    lastLoginHint = loginHint;
    return _next(signInResults);
  }

  @override
  Future<OidcTokens> refresh(String refreshToken) async {
    refreshedWith.add(refreshToken);
    return _next(refreshResults);
  }

  @override
  Future<void> revoke(String refreshToken) async {
    revoked.add(refreshToken);
    if (revokeError != null) throw revokeError!;
  }

  Future<OidcTokens> _next(List<Object> queue) async {
    if (queue.isEmpty) throw StateError('FakeOidcClient: no result queued');
    final result = queue.removeAt(0);
    if (result is Completer<OidcTokens>) return result.future;
    if (result is OidcTokens) return result;
    throw result;
  }
}

/// Token giả; `minutes` = thời gian còn hạn tính từ `now`.
OidcTokens fakeTokens(
  String suffix, {
  required DateTime now,
  int minutes = 5,
  String? idToken,
}) => OidcTokens(
  accessToken: 'a$suffix',
  accessTokenExpiresAt: now.add(Duration(minutes: minutes)),
  refreshToken: 'r$suffix',
  idToken: idToken ?? 'i$suffix',
);
