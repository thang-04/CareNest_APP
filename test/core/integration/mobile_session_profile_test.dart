import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_session.dart';

import 'mobile_session_sign_in_test.dart' show RecordingAppAuth;

/// BE giả: `/accounts/me` của phụ huynh chưa có ảnh chân dung (`profileUpdateRequired`).
class _AccountServer {
  late HttpServer server;
  bool photoMissing = true;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write(
        jsonEncode({
          'code': 200,
          'data': {
            'userId': 7,
            'roles': ['PARENT'],
            'childIds': [1],
            'profileUpdateRequired': photoMissing,
          },
        }),
      );
      await request.response.close();
    });
  }

  String get base => 'http://127.0.0.1:${server.port}';
}

void main() {
  late _AccountServer be;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    be = _AccountServer();
    await be.start();
    addTearDown(() => be.server.close(force: true));
  });

  MobileSession newSession() {
    final session = MobileSession(
      auth: RecordingAppAuth(),
      apiBaseUrl: '${be.base}/api',
      issuer: be.base,
    );
    addTearDown(session.dispose);
    return session;
  }

  test('signIn_profileUpdateRequired_keepsSession', () async {
    final session = newSession();
    await session.signIn();
    expect(session.signedIn, isTrue);
  });

  test('restore_profileUpdateRequired_keepsSession', () async {
    FlutterSecureStorage.setMockInitialValues({'auth.refresh': 'refresh-0'});
    final session = newSession();
    await session.restore();
    expect(session.signedIn, isTrue);
  });
}
