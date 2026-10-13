import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/auth/presentation/screens/login_screen.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpLogin(WidgetTester tester, LoginScreen screen) async {
  await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
  await tester.pump();
}

void main() {
  testWidgets(
    'AC-3: đủ logo, hai ô nhập, Quên mật khẩu, Đăng nhập, ghi chú SMS, phiên bản; không có đăng ký',
    (tester) async {
      usePhoneSize(tester);
      await pumpLogin(tester, const LoginScreen());
      expect(find.bySemanticsLabel('CareNest'), findsOneWidget);
      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
      expect(find.textContaining('Đăng ký'), findsNothing);
      expect(find.text('Xem thử theo vai trò'), findsNothing);
      expect(find.textContaining('cấp qua SMS'), findsOneWidget);
      expect(find.text('Phiên bản v1.0.0'), findsOneWidget);
    },
  );

  testWidgets('AC-3: để trống ⇒ báo lỗi dưới ô, không gọi onSubmit', (
    tester,
  ) async {
    usePhoneSize(tester);
    var submitted = false;
    await pumpLogin(tester, LoginScreen(onSubmit: (_, _) => submitted = true));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    expect(find.text('Nhập số điện thoại.'), findsOneWidget);
    expect(find.text('Nhập mật khẩu.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('AC-3: nhập đủ ⇒ gọi onSubmit với tài khoản đã trim', (
    tester,
  ) async {
    usePhoneSize(tester);
    String? account;
    await pumpLogin(
      tester,
      LoginScreen(onSubmit: (value, _) => account = value),
    );
    await tester.enterText(find.byType(TextField).first, ' 0912345678 ');
    await tester.enterText(find.byType(TextField).last, 'matkhau');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    expect(account, '0912345678');
  });

  testWidgets('AC-3: đang gửi ⇒ khóa nút và ô nhập', (tester) async {
    usePhoneSize(tester);
    await pumpLogin(tester, const LoginScreen(isSubmitting: true));
    expect(find.text('Đang đăng nhập'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isFalse,
    );
  });

  testWidgets('AC-3: lỗi từ BE hiện banner', (tester) async {
    usePhoneSize(tester);
    await pumpLogin(
      tester,
      const LoginScreen(errorMessage: 'Tài khoản hoặc mật khẩu chưa đúng.'),
    );
    expect(find.text('Tài khoản hoặc mật khẩu chưa đúng.'), findsOneWidget);
  });

  testWidgets('Chưa nối auth ⇒ Quên mật khẩu vẫn bấm được, báo chưa kết nối', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpLogin(tester, const LoginScreen());
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pump();
    expect(find.textContaining('chưa được kết nối'), findsOneWidget);
  });

  testWidgets('AC-10: chữ lớn 2.0 ở 360×800 không tràn layout', (tester) async {
    usePhoneSize(tester, textScale: 2);
    await pumpLogin(tester, LoginScreen(onOpenPreview: () {}));
    expect(tester.takeException(), isNull);
  });
}
