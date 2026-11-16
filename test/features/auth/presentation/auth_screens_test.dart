import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:carenest_app/features/auth/presentation/screens/blocked_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/session_loading_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/sign_in_screen.dart';

import '../../../helpers/fake_auth_controller.dart';
import '../../../helpers/pump_app.dart';

Future<FakeAuthController> _pump(
  WidgetTester tester,
  AuthState state,
  Widget screen,
) async {
  usePhoneSize(tester);
  final fake = FakeAuthController(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => fake)],
      child: MaterialApp(theme: buildLightTheme(), home: screen),
    ),
  );
  await tester.pump();
  return fake;
}

void main() {
  group('SignInScreen', () {
    testWidgets('signInScreen_hasNoForgotPassword', (tester) async {
      await _pump(tester, const AuthSignedOut(), const SignInScreen());

      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.textContaining('Quên mật khẩu'), findsNothing);
      expect(find.textContaining('10 số'), findsOneWidget);
    });

    testWidgets('signInScreen_buttonCallsSignIn', (tester) async {
      final fake = await _pump(
        tester,
        const AuthSignedOut(),
        const SignInScreen(),
      );

      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pump();

      expect(fake.calls, ['signIn:']);
    });

    testWidgets('signInScreen_activateLink_callsCallback', (tester) async {
      var opened = false;
      await _pump(
        tester,
        const AuthSignedOut(),
        SignInScreen(onActivate: () => opened = true),
      );

      await tester.tap(find.text('Kích hoạt tài khoản'));
      await tester.pump();

      expect(opened, isTrue);
    });

    testWidgets('signInScreen_showsExpiredNotice', (tester) async {
      await _pump(
        tester,
        const AuthSignedOut(notice: AuthNotice.sessionExpired),
        const SignInScreen(),
      );

      expect(
        find.text('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.'),
        findsOneWidget,
      );
    });

    testWidgets('signInScreen_signingIn_disablesButton', (tester) async {
      final fake = await _pump(
        tester,
        const AuthSigningIn(),
        const SignInScreen(),
      );

      await tester.tap(find.byType(AppButton).first);
      await tester.pump();

      expect(find.text('Đang mở trang đăng nhập...'), findsOneWidget);
      expect(fake.calls, isEmpty);
    });
  });

  group('SessionLoadingScreen', () {
    testWidgets('checking_showsLoading', (tester) async {
      await _pump(tester, const AuthChecking(), const SessionLoadingScreen());

      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('retryScreen_retryButtonCallsRetry', (tester) async {
      final fake = await _pump(
        tester,
        const AuthRetryNeeded(NetworkFailure()),
        const SessionLoadingScreen(),
      );

      expect(find.text('Không kết nối được máy chủ'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();

      expect(fake.calls, ['retry']);
    });
  });

  group('BlockedScreen', () {
    testWidgets('blocked_webOnly_showsMessageAndSignOut', (tester) async {
      final fake = await _pump(
        tester,
        const AuthBlocked(AuthBlockReason.webOnlyAccount),
        const BlockedScreen(),
      );

      expect(
        find.text('Tài khoản này dùng trên Web CareNest.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Đăng xuất'));
      await tester.pump();

      expect(fake.calls, ['signOut']);
    });

    testWidgets('blocked_unavailable_showsContactSchool', (tester) async {
      await _pump(
        tester,
        const AuthBlocked(AuthBlockReason.accountUnavailable),
        const BlockedScreen(),
      );

      expect(
        find.text('Tài khoản chưa dùng được. Vui lòng liên hệ nhà trường.'),
        findsOneWidget,
      );
    });
  });
}
