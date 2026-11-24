import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/auth/data/activation_api.dart';
import 'package:carenest_app/features/auth/presentation/screens/activation_screen.dart';

import '../../../helpers/pump_app.dart';

/// Kích hoạt giả: trả lần lượt kết quả đã xếp (username hoặc lỗi), ghi lại số lần gọi.
class _FakeActivation implements ActivationGateway {
  final replies = <Object>[];
  var calls = 0;

  @override
  Future<String> activate({
    required String phone,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    calls++;
    final reply = replies.removeAt(0);
    if (reply is String) return reply;
    throw reply;
  }
}

class _Setup {
  _Setup(this.activation, this.signIns);

  final _FakeActivation activation;
  final List<String> signIns;
}

Future<_Setup> _pump(
  WidgetTester tester, {
  Future<void> Function()? signInDone,
}) async {
  usePhoneSize(tester);
  final activation = _FakeActivation();
  final signIns = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: ActivationScreen(
        api: activation,
        signInAs: (username) async {
          signIns.add(username);
          await signInDone?.call();
        },
      ),
    ),
  );
  await tester.pump();
  return _Setup(activation, signIns);
}

Future<void> _fill(
  WidgetTester tester, {
  String phone = '0900000001',
  String code = '123456',
  String pw = _pw,
  String? confirm,
}) async {
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), phone);
  await tester.enterText(fields.at(1), code);
  await tester.enterText(fields.at(2), pw);
  await tester.enterText(fields.at(3), confirm ?? pw);
  await tester.pump();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(_submit);
  await tester.tap(_submit);
  await tester.pumpAndSettle();
}

// Mật khẩu giả cho test
const _pw = 'MatKhau#2026'; // carenest:allow-secret — giá trị giả

Finder get _submit => find.widgetWithText(AppButton, 'Kích hoạt');

void main() {
  testWidgets('activate_success_signInWithUsername', (tester) async {
    final setup = await _pump(tester);
    setup.activation.replies.add('0900000001');
    await _fill(tester);

    await _tapSubmit(tester);

    expect(setup.signIns, ['0900000001']);
    expect(find.text('Tài khoản đã kích hoạt'), findsOneWidget);
  });

  testWidgets('activate_success_canOpenSignInAgain', (tester) async {
    final setup = await _pump(tester);
    setup.activation.replies.add('0900000001');
    await _fill(tester);
    await _tapSubmit(tester);

    await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
    await tester.pump();

    expect(setup.signIns, ['0900000001', '0900000001']);
  });

  testWidgets('activate_whileLoginPageOpen_signInButtonBusy', (tester) async {
    final page = Completer<void>();
    final setup = await _pump(tester, signInDone: () => page.future);
    setup.activation.replies.add('0900000001');
    await _fill(tester);
    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.textContaining('Đang mở trang đăng nhập'));
    await tester.pump();

    expect(setup.signIns, ['0900000001']);
    expect(find.text('Đang mở trang đăng nhập...'), findsOneWidget);
    page.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('activate_1006_showsContactSchool', (tester) async {
    final setup = await _pump(tester);
    setup.activation.replies.add(ApiFailure(400, 'x', 1006));
    await _fill(tester);

    await _tapSubmit(tester);

    expect(
      find.text(
        'Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã.',
      ),
      findsOneWidget,
    );
    expect(setup.signIns, isEmpty);
  });

  testWidgets('activate_1009_showsPolicyUnderPassword', (tester) async {
    final setup = await _pump(tester);
    setup.activation.replies.add(
      ApiFailure(400, 'Mật khẩu cần có chữ hoa', 1009),
    );
    await _fill(tester);

    await _tapSubmit(tester);

    expect(find.text('Mật khẩu cần có chữ hoa'), findsOneWidget);
  });

  testWidgets('activate_passwordMismatch_blocksSubmit', (tester) async {
    final setup = await _pump(tester);
    await _fill(tester, confirm: 'Khac#2026'); // carenest:allow-secret — giả

    await _tapSubmit(tester);

    expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
    expect(setup.activation.calls, 0);
  });

  testWidgets('activate_invalidPhone_blocksSubmit', (tester) async {
    final setup = await _pump(tester);
    await _fill(tester, phone: '12345');

    await _tapSubmit(tester);

    expect(
      find.text('Nhập số điện thoại 10 số, bắt đầu bằng 0.'),
      findsOneWidget,
    );
    expect(setup.activation.calls, 0);
  });

  testWidgets('activate_doubleTap_sendsOnce', (tester) async {
    final setup = await _pump(tester);
    setup.activation.replies.add('0900000001');
    await _fill(tester);
    await tester.ensureVisible(_submit);

    await tester.tap(_submit);
    await tester.tap(_submit, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(setup.activation.calls, 1);
  });

  testWidgets('activate_networkError_showsRetryMessage', (tester) async {
    final setup = await _pump(tester);
    setup.activation.replies.add(const SocketException('offline'));
    await _fill(tester);

    await _tapSubmit(tester);

    expect(
      find.text('Không kết nối được máy chủ. Thử lại sau.'),
      findsOneWidget,
    );
  });

  testWidgets('activate_503_showsRetryMessage', (tester) async {
    final setup = await _pump(tester);
    setup.activation.replies.add(ApiFailure(503, 'Không thể tải dữ liệu.'));
    await _fill(tester);

    await _tapSubmit(tester);

    expect(
      find.text('Không kết nối được máy chủ. Thử lại sau.'),
      findsOneWidget,
    );
  });
}
