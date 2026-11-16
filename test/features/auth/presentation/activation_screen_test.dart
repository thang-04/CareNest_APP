import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/network/api_client.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/auth/data/datasources/activation_remote_data_source.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:carenest_app/features/auth/presentation/screens/activation_screen.dart';

import '../../../helpers/fake_auth_controller.dart';
import '../../../helpers/fake_http_adapter.dart';
import '../../../helpers/pump_app.dart';

class _Setup {
  _Setup(this.fake, this.http);

  final FakeAuthController fake;
  final FakeHttpAdapter http;
}

Future<_Setup> _pump(WidgetTester tester) async {
  usePhoneSize(tester);
  final fake = FakeAuthController(const AuthSignedOut());
  final http = FakeHttpAdapter();
  final source = ActivationRemoteDataSource(
    ApiClient(
      Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
        ..httpClientAdapter = http,
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => fake),
        activationRemoteDataSourceProvider.overrideWithValue(source),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const ActivationScreen(),
      ),
    ),
  );
  await tester.pump();
  return _Setup(fake, http);
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

// Mật khẩu giả cho test
const _pw = 'MatKhau#2026'; // carenest:allow-secret — giá trị giả

Finder get _submit => find.widgetWithText(AppButton, 'Kích hoạt');

void main() {
  testWidgets('activate_success_startsSignInWithUsername', (tester) async {
    final setup = await _pump(tester);
    setup.http.enqueue(
      FakeReply.envelope(200, data: {'username': '0900000001'}),
    );
    await _fill(tester);

    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(setup.fake.calls, ['signIn:0900000001']);
    expect(find.text('Tài khoản đã kích hoạt'), findsOneWidget);
  });

  testWidgets('activate_success_canOpenSignInAgain', (tester) async {
    final setup = await _pump(tester);
    setup.http.enqueue(
      FakeReply.envelope(200, data: {'username': '0900000001'}),
    );
    await _fill(tester);
    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
    await tester.pump();

    expect(setup.fake.calls, ['signIn:0900000001', 'signIn:0900000001']);
  });

  testWidgets('activate_whileLoginPageOpen_signInButtonBusy', (tester) async {
    final setup = await _pump(tester);
    setup.http.enqueue(
      FakeReply.envelope(200, data: {'username': '0900000001'}),
    );
    await _fill(tester);
    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    setup.fake.emit(const AuthSigningIn());
    await tester.pump();
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(setup.fake.calls, ['signIn:0900000001']);
    expect(find.text('Đang mở trang đăng nhập...'), findsOneWidget);
  });

  testWidgets('activate_1006_showsContactSchool', (tester) async {
    final setup = await _pump(tester);
    setup.http.enqueue(FakeReply.envelope(400, errorCode: 1006, desc: 'x'));
    await _fill(tester);

    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã.',
      ),
      findsOneWidget,
    );
    expect(setup.fake.calls, isEmpty);
  });

  testWidgets('activate_passwordMismatch_blocksSubmit', (tester) async {
    final setup = await _pump(tester);
    await _fill(tester, confirm: 'KhacMatKhau#1');

    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
    expect(setup.http.requests, isEmpty);
  });

  testWidgets('activate_invalidPhone_blocksSubmit', (tester) async {
    final setup = await _pump(tester);
    await _fill(tester, phone: '12345');

    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(
      find.text('Nhập số điện thoại 10 số, bắt đầu bằng 0.'),
      findsOneWidget,
    );
    expect(setup.http.requests, isEmpty);
  });

  testWidgets('activate_doubleTap_sendsOnce', (tester) async {
    final setup = await _pump(tester);
    setup.http.enqueue(
      FakeReply.envelope(200, data: {'username': '0900000001'}),
    );
    await _fill(tester);
    await tester.ensureVisible(_submit);

    await tester.tap(_submit);
    await tester.tap(_submit, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(setup.http.requests, hasLength(1));
  });

  testWidgets('activate_networkError_showsRetryMessage', (tester) async {
    final setup = await _pump(tester);
    setup.http.enqueue(FakeReply.text(503, '<html>', contentType: 'text/html'));
    await _fill(tester);

    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(
      find.text('Không kết nối được máy chủ. Thử lại sau.'),
      findsOneWidget,
    );
  });
}
