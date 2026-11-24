import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/routing/app_router.dart';

import 'pump_app.dart';

/// Phiên thật giả: `/accounts/me` đã tải, không gọi Keycloak (cùng kiểu test/routing/live_router_test.dart).
class FakeLiveSession extends MobileSession {
  FakeLiveSession(
    List<String> roles, {
    List<int> childIds = const [],
    bool photoMissing = false,
  }) {
    account = {
      'userId': 4,
      'username': '0912345678',
      'fullName': 'Người Dùng Thử',
      'roles': roles,
      'childIds': childIds,
      'profileUpdateRequired': photoMissing,
    };
  }

  bool signedOut = false;

  @override
  bool get signedIn => account != null;

  @override
  Future<String> accessToken({bool force = false}) async => 'fake';

  @override
  Future<void> signOut() async {
    signedOut = true;
    account = null;
    notifyListeners();
  }
}

/// API giả: mọi lời gọi trả danh sách thông báo rỗng.
class EmptyFeedApi extends MobileApi {
  EmptyFeedApi(super.session);

  @override
  Future<Object?> json(String method, String path, {Object? body}) async => {
    'unreadCount': 0,
    'items': <Object>[],
  };
}

/// Dựng router chế độ thật với phiên giả; trả router để test điều hướng.
Future<GoRouter> pumpLiveApp(
  WidgetTester tester,
  FakeLiveSession session, {
  String location = '/live/notifications',
  LastModeStore? modeStore,
}) async {
  usePhoneSize(tester);
  final router = buildAppRouter(
    enablePreview: false,
    session: session,
    api: EmptyFeedApi(session),
    signIn: () async {},
    signOut: session.signOut,
    modeStore: modeStore ?? LastModeStore(MemorySecureStore(), env: 'test'),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: buildLightTheme(), routerConfig: router),
  );
  router.go(location);
  await tester.pumpAndSettle();
  // Màn dữ liệu giả tải sau 400ms; chờ hết để không còn timer khi test kết thúc
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return router;
}

/// Kho chế độ đọc chậm: `read` chờ tới khi test gọi [release].
class SlowSecureStore implements SecureStore {
  SlowSecureStore(this.values);

  final Map<String, String> values;
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<String?> read(String key) async {
    // Giá trị lúc bắt đầu đọc, như kho thật trả về sau một lần ghi chồng lên
    final value = values[key];
    await _gate.future;
    return value;
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
