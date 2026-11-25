import 'dart:convert';
import 'dart:io';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_session.dart';

/// Keycloak giả: ghi lại yêu cầu đăng nhập, trả token cố định.
class RecordingAppAuth extends FlutterAppAuth {
  AuthorizationTokenRequest? authorization;

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    authorization = request;
    return AuthorizationTokenResponse(
      'access-1',
      'refresh-1',
      DateTime.now().add(const Duration(minutes: 5)),
      null,
      'Bearer',
      null,
      null,
      null,
    );
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async => TokenResponse(
    'access-2',
    'refresh-2',
    DateTime.now().add(const Duration(minutes: 5)),
    null,
    'Bearer',
    null,
    null,
  );
}

/// BE giả trả `/accounts/me`; trả server để đóng sau test.
Future<HttpServer> fakeAccountServer(Map<String, Object?> account) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response.write(jsonEncode({'code': 200, 'data': account}));
    await request.response.close();
  });
  return server;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<RecordingAppAuth> signIn({String? loginHint}) async {
    final server = await fakeAccountServer({
      'userId': 7,
      'roles': ['PARENT'],
    });
    addTearDown(() => server.close(force: true));
    final auth = RecordingAppAuth();
    final session = MobileSession(
      auth: auth,
      apiBaseUrl: 'http://127.0.0.1:${server.port}/api',
      issuer: 'http://127.0.0.1:${server.port}',
    );
    addTearDown(session.dispose);
    await session.signIn(loginHint: loginHint);
    return auth;
  }

  test('signIn_loginHint_passedToKeycloak', () async {
    final auth = await signIn(loginHint: '0912345678');
    expect(auth.authorization?.loginHint, '0912345678');
  });

  test('signIn_withoutHint_noLoginHint', () async {
    final auth = await signIn();
    expect(auth.authorization?.loginHint, isNull);
  });

  test('signIn_promptLogin_everyTime', () async {
    final auth = await signIn();
    expect(auth.authorization?.promptValues, ['login']);
  });
}
