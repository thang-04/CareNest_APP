import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/app.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:carenest_app/features/auth/presentation/screens/login_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/sign_in_screen.dart';

import 'helpers/fake_auth_controller.dart';
import 'helpers/pump_app.dart';

Future<FakeAuthController> _pumpApp(
  WidgetTester tester, {
  required bool useMock,
}) async {
  usePhoneSize(tester);
  final fake = FakeAuthController(const AuthSignedOut());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => fake)],
      child: CareNestApp(useMock: useMock),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('realMode_startsSessionAndShowsSignIn', (tester) async {
    final fake = await _pumpApp(tester, useMock: false);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(fake.calls, ['start']);
  });

  testWidgets('realMode_resumed_reloadsAccount', (tester) async {
    final fake = await _pumpApp(tester, useMock: false);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(fake.calls, contains('onResumed'));
  });

  testWidgets('mockMode_keepsFakeLogin', (tester) async {
    final fake = await _pumpApp(tester, useMock: true);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(fake.calls, isEmpty);
  });
}
