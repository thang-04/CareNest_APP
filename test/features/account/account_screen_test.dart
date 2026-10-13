import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/account/presentation/screens/account_screen.dart';
import 'package:carenest_app/features/account/presentation/screens/personal_info_screen.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpAccount(
  WidgetTester tester,
  AppRole role, {
  VoidCallback? onLogout,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: AccountScreen(
          role: role,
          onOpenProfile: () {},
          onChangePassword: () {},
          onLogout: onLogout ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('P14: phụ huynh thấy Con của tôi, 4 lối vào và Đăng xuất', (
    tester,
  ) async {
    usePhoneSize(tester);
    var loggedOut = false;
    await pumpAccount(tester, AppRole.parent, onLogout: () => loggedOut = true);
    expect(find.text('Nguyễn Thu Lan'), findsOneWidget);
    expect(find.text('0912 345 678 · Phụ huynh'), findsOneWidget);
    expect(find.textContaining('Con của tôi'), findsOneWidget);
    for (final label in [
      'Thông tin cá nhân',
      'Đổi mật khẩu',
      'Cài đặt thông báo',
      'Hỗ trợ & giới thiệu',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    expect(loggedOut, isTrue);
  });

  testWidgets('P14: mỗi vai trò hiện đúng nhãn vai trò', (tester) async {
    usePhoneSize(tester);
    for (final role in AppRole.values) {
      await pumpAccount(tester, role);
      expect(find.textContaining(role.label), findsWidgets, reason: role.name);
    }
  });

  testWidgets('P18: số điện thoại khoá, họ tên trống ⇒ báo lỗi', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const PersonalInfoScreen(role: AppRole.parent),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.at(1)).enabled, isFalse);

    await tester.enterText(fields.at(0), '  ');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    expect(find.text('Nhập họ và tên.'), findsOneWidget);
  });

  testWidgets('AC-10: Tài khoản và Thông tin cá nhân chữ 2.0 không tràn', (
    tester,
  ) async {
    usePhoneSize(tester, textScale: 2);
    await pumpAccount(tester, AppRole.vicePrincipal);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const PersonalInfoScreen(role: AppRole.teacher),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
