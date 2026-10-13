import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/new_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/otp_verify_screen.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
  await tester.pump();
}

FilledButton buttonOf(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

void main() {
  testWidgets(
    'P15: để trống ⇒ báo lỗi; chưa nối máy chủ ⇒ banner, không giả vờ đã gửi',
    (tester) async {
      usePhoneSize(tester);
      await pumpScreen(tester, const ForgotPasswordScreen());
      await tester.tap(find.text('Gửi mã OTP'));
      await tester.pump();
      expect(find.text('Nhập số điện thoại.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '0912345678');
      await tester.tap(find.text('Gửi mã OTP'));
      await tester.pump();
      expect(find.textContaining('chưa được kết nối'), findsOneWidget);
    },
  );

  testWidgets('P15: có callback ⇒ gửi số đã trim', (tester) async {
    usePhoneSize(tester);
    String? sent;
    await pumpScreen(
      tester,
      ForgotPasswordScreen(onSendCode: (phone) => sent = phone),
    );
    await tester.enterText(find.byType(TextField), ' 0912345678 ');
    await tester.tap(find.text('Gửi mã OTP'));
    expect(sent, '0912345678');
  });

  testWidgets('P16: chưa đủ 6 số ⇒ khoá nút; hết giờ đếm ⇒ có Gửi lại mã', (
    tester,
  ) async {
    usePhoneSize(tester);
    String? verified;
    await pumpScreen(
      tester,
      OtpVerifyScreen(
        maskedPhone: '091•••••678',
        resendAfter: const Duration(seconds: 2),
        onVerify: (code) => verified = code,
      ),
    );
    expect(find.textContaining('091•••••678'), findsOneWidget);
    expect(buttonOf(tester, 'Xác nhận mã').onPressed, isNull);

    await tester.enterText(find.byType(TextField), '48261');
    await tester.pump();
    expect(buttonOf(tester, 'Xác nhận mã').onPressed, isNull);

    await tester.enterText(find.byType(TextField), '482615');
    await tester.pump();
    await tester.tap(find.text('Xác nhận mã'));
    expect(verified, '482615');

    expect(find.textContaining('Gửi lại mã sau'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Gửi lại mã'), findsOneWidget);
  });

  testWidgets(
    'P17: điều kiện mật khẩu đổi theo nội dung nhập, đủ mới cho lưu',
    (tester) async {
      usePhoneSize(tester);
      String? saved;
      await pumpScreen(
        tester,
        NewPasswordScreen(onSave: (_, next) => saved = next),
      );
      final fields = find.byType(TextField);
      expect(buttonOf(tester, 'Lưu mật khẩu').onPressed, isNull);

      await tester.enterText(fields.at(0), 'matkhau1');
      await tester.enterText(fields.at(1), 'matkhau2');
      await tester.pump();
      expect(find.bySemanticsLabel('Ít nhất 8 ký tự: đạt'), findsOneWidget);
      expect(find.bySemanticsLabel('Có cả chữ và số: đạt'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Hai mật khẩu trùng khớp: chưa đạt'),
        findsOneWidget,
      );
      expect(buttonOf(tester, 'Lưu mật khẩu').onPressed, isNull);

      await tester.enterText(fields.at(1), 'matkhau1');
      await tester.pump();
      await tester.tap(find.text('Lưu mật khẩu'));
      expect(saved, 'matkhau1');
    },
  );

  testWidgets('P17 từ Tài khoản: bắt buộc mật khẩu hiện tại', (tester) async {
    usePhoneSize(tester);
    var calls = 0;
    await pumpScreen(
      tester,
      NewPasswordScreen(requireCurrent: true, onSave: (_, _) => calls++),
    );
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'matkhau1');
    await tester.enterText(fields.at(2), 'matkhau1');
    await tester.pump();
    await tester.tap(find.text('Lưu mật khẩu'));
    await tester.pump();
    expect(find.text('Nhập mật khẩu hiện tại.'), findsOneWidget);
    expect(calls, 0);
  });

  for (final screen in const <Widget>[
    ForgotPasswordScreen(),
    OtpVerifyScreen(maskedPhone: '091•••••678'),
    NewPasswordScreen(requireCurrent: true),
  ]) {
    testWidgets('AC-10: ${screen.runtimeType} chữ 2.0 không tràn', (
      tester,
    ) async {
      usePhoneSize(tester, textScale: 2);
      await pumpScreen(tester, screen);
      expect(tester.takeException(), isNull);
    });
  }
}
