import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/routing/app_router.dart';

import '../helpers/pump_app.dart';

class FakeSession extends MobileSession {
  FakeSession(List<String> roles) {
    account = {
      'userId': 4,
      'username': 'gv.thu',
      'fullName': 'Giáo viên Thử',
      'roles': roles,
    };
  }

  @override
  bool get signedIn => true;

  @override
  Future<String> accessToken({bool force = false}) async => 'fake';
}

class FeedApi extends MobileApi {
  FeedApi(super.session);

  @override
  Future<Object?> json(String method, String path, {Object? body}) async => {
    'unreadCount': 0,
    'items': <Object>[],
  };
}

Future<GoRouter> pumpLive(WidgetTester tester, List<String> roles) async {
  usePhoneSize(tester);
  final session = FakeSession(roles);
  final router = buildAppRouter(
    enablePreview: false,
    session: session,
    api: FeedApi(session),
    signIn: () async {},
    signOut: () async {},
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: buildLightTheme(), routerConfig: router),
  );
  router.go('/live/notifications');
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('phiên thật Giáo viên: Thông báo có thanh đáy 4 tab, Tài khoản thật', (
    tester,
  ) async {
    await pumpLive(tester, ['TEACHER']);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final tab in ['Trang chủ', 'Lớp học', 'Thông báo', 'Tài khoản']) {
      expect(find.text(tab), findsWidgets);
    }
    expect(find.text('Chưa có thông báo'), findsOneWidget);

    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();
    expect(find.text('Giáo viên Thử'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);

    // Tab chưa nối API: báo "Sắp có", không hiện dữ liệu giả
    await tester.tap(find.text('Lớp học').last);
    await tester.pumpAndSettle();
    expect(find.text('Tính năng này sẽ có trong bản sau.'), findsOneWidget);
  });

  testWidgets('vai trò không có trên App (BGH) ⇒ báo dùng Web, không vào khung', (
    tester,
  ) async {
    await pumpLive(tester, ['PRINCIPAL']);
    expect(find.text('Tài khoản này dùng trên Web'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
