import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';

import 'mobile_session_sign_in_test.dart' show RecordingAppAuth;

/// BE + Keycloak giả: `/accounts/me` trả lỗi cho trước, ghi lại các lời gọi.
Future<(HttpServer, List<String>)> _server(int status, int errorCode) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final calls = <String>[];
  server.listen((request) async {
    calls.add('${request.method} ${request.uri.path}');
    if (request.uri.path == '/api/accounts/me') {
      request.response.statusCode = status;
      request.response.write(
        jsonEncode({'code': status, 'errorCode': errorCode, 'desc': 'x'}),
      );
    } else {
      request.response.statusCode = 204;
    }
    await request.response.close();
  });
  return (server, calls);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<(MobileSession, List<String>)> signInWith(
    int status,
    int errorCode,
  ) async {
    final (server, calls) = await _server(status, errorCode);
    addTearDown(() => server.close(force: true));
    final base = 'http://127.0.0.1:${server.port}';
    final session = MobileSession(
      auth: RecordingAppAuth(),
      apiBaseUrl: '$base/api',
      issuer: base,
    );
    addTearDown(session.dispose);
    return (session, calls);
  }

  test('signIn_webOnly1101_explainsAndRevokes', () async {
    final (session, calls) = await signInWith(403, 1101);

    await expectLater(
      session.signIn(),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.message,
          'message',
          'Tài khoản này dùng trên Web CareNest, không dùng trên App.',
        ),
      ),
    );

    expect(session.signedIn, isFalse);
    expect(calls, contains('POST /protocol/openid-connect/logout'));
    expect(
      await const FlutterSecureStorage().read(key: 'auth.refresh'),
      isNull,
    );
  });

  test('signIn_notProvisioned1014_asksToContactSchool', () async {
    final (session, _) = await signInWith(403, 1014);

    await expectLater(
      session.signIn(),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.message,
          'message',
          'Tài khoản chưa dùng được. Vui lòng liên hệ nhà trường.',
        ),
      ),
    );
    expect(session.signedIn, isFalse);
  });
}
