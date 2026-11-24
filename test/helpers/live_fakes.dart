import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/routing/app_router.dart';

import 'pump_app.dart';

/// Phiên thật giả: `/accounts/me` đã tải, không gọi Keycloak (cùng kiểu test/routing/live_router_test.dart).
class FakeLiveSession extends MobileSession {
  FakeLiveSession(List<String> roles, {List<int> childIds = const []}) {
    account = {
      'userId': 4,
      'username': '0912345678',
      'fullName': 'Người Dùng Thử',
      'roles': roles,
      'childIds': childIds,
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
}) async {
  usePhoneSize(tester);
  final router = buildAppRouter(
    enablePreview: false,
    session: session,
    api: EmptyFeedApi(session),
    signIn: () async {},
    signOut: session.signOut,
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
