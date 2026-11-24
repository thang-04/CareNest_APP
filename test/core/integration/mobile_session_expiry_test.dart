import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_session.dart';

import 'mobile_session_sign_in_test.dart' show RecordingAppAuth;

/// Keycloak giả: đăng nhập được, làm mới token thì ném lỗi cho trước.
class _FailingRefresh extends RecordingAppAuth {
  _FailingRefresh(this.error);

  final Object error;

  @override
  Future<TokenResponse> token(TokenRequest request) async => throw error;
}

FlutterAppAuthPlatformException _oauth(String error) =>
    FlutterAppAuthPlatformException(
      code: 'token_failed',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(error: error),
    );

void main() {
  late HttpServer server;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write(
        jsonEncode({
          'code': 200,
          'data': {
            'userId': 7,
            'roles': ['TEACHER'],
          },
        }),
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
  });

  Future<MobileSession> signedIn(Object refreshError) async {
    final base = 'http://127.0.0.1:${server.port}';
    final session = MobileSession(
      auth: _FailingRefresh(refreshError),
      apiBaseUrl: '$base/api',
      issuer: base,
    );
    addTearDown(session.dispose);
    await session.signIn();
    return session;
  }

  test('renew_invalidGrant_clearsAndMarksExpired', () async {
    final session = await signedIn(_oauth('invalid_grant'));
    var calls = 0;
    session.addListener(() => calls++);

    await expectLater(session.accessToken(force: true), throwsA(anything));

    expect(session.signedIn, isFalse);
    expect(session.expired, isTrue);
    expect(calls, greaterThan(0));
    expect(
      await const FlutterSecureStorage().read(key: 'auth.refresh'),
      isNull,
    );
  });

  test('renew_networkError_keepsSession', () async {
    final session = await signedIn(PlatformException(code: 'network_error'));

    await expectLater(session.accessToken(force: true), throwsA(anything));

    expect(session.signedIn, isTrue);
    expect(session.expired, isFalse);
  });

  test('signIn_afterExpiry_clearsExpired', () async {
    final session = await signedIn(_oauth('invalid_grant'));
    await expectLater(session.accessToken(force: true), throwsA(anything));

    await session.signIn();

    expect(session.expired, isFalse);
    expect(session.signedIn, isTrue);
  });
}
