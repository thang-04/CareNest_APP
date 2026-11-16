import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:carenest_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:carenest_app/routing/app_router.dart';
import 'package:carenest_app/routing/route_paths.dart';

import '../helpers/fake_auth_controller.dart';
import '../helpers/pump_app.dart';

class _Setup {
  _Setup(this.fake, this.router);

  final FakeAuthController fake;
  final GoRouter router;
}

Future<_Setup> _pumpReal(WidgetTester tester, AuthState initial) async {
  usePhoneSize(tester);
  final fake = FakeAuthController(initial);
  final container = ProviderContainer(
    overrides: [authControllerProvider.overrideWith(() => fake)],
  );
  addTearDown(container.dispose);
  final refresh = ValueNotifier(0);
  container.listen(authControllerProvider, (_, _) => refresh.value++);
  final router = buildAppRouter(
    enablePreview: false,
    refresh: refresh,
    readAuth: () => container.read(authControllerProvider),
    onSignOut: () => fake.signOut(),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: buildLightTheme(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _Setup(fake, router);
}

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('signedOut_opensSignInScreen', (tester) async {
    final setup = await _pumpReal(tester, const AuthSignedOut());

    expect(_location(setup.router), RoutePaths.login);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('signedInTeacher_opensTeacherHome', (tester) async {
    final setup = await _pumpReal(
      tester,
      AuthSignedIn(fakeUser(), AppMode.teacher),
    );

    expect(_location(setup.router), RoutePaths.teacherToday);
  });

  testWidgets('realMode_hasNoPreviewOrPrincipal', (tester) async {
    final setup = await _pumpReal(
      tester,
      AuthSignedIn(fakeUser(), AppMode.teacher),
    );

    // Màn ngoài chế độ hiện tại (Xem thử, BGH) ⇒ về màn chính của GV
    for (final path in [RoutePaths.preview, RoutePaths.principalHome]) {
      setup.router.go(path);
      await tester.pumpAndSettle();
      expect(_location(setup.router), RoutePaths.teacherToday, reason: path);
    }
  });

  testWidgets('signOut_clearsBackStack', (tester) async {
    final setup = await _pumpReal(
      tester,
      AuthSignedIn(fakeUser(), AppMode.teacher),
    );
    setup.router.push(RoutePaths.teacherAttendance);
    await tester.pumpAndSettle();
    expect(setup.router.canPop(), isTrue);

    setup.fake.emit(const AuthSignedOut());
    await tester.pumpAndSettle();

    expect(_location(setup.router), RoutePaths.login);
    expect(setup.router.canPop(), isFalse);
  });

  testWidgets('switchMode_movesToParentHome', (tester) async {
    final user = fakeUser(roles: {'TEACHER', 'PARENT'}, childIds: [7]);
    final setup = await _pumpReal(tester, AuthSignedIn(user, AppMode.teacher));

    setup.fake.emit(AuthSignedIn(user, AppMode.parent));
    await tester.pumpAndSettle();

    expect(_location(setup.router), RoutePaths.parentToday);
  });

  testWidgets('accountLogout_callsSignOut', (tester) async {
    final setup = await _pumpReal(
      tester,
      AuthSignedIn(fakeUser(), AppMode.teacher),
    );
    setup.router.go(RoutePaths.teacherAccount);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Đăng xuất'), 200);
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    final confirm = find.text('Đăng xuất').last;
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await tester.pumpAndSettle();
    }

    expect(setup.fake.calls, contains('signOut'));
  });
}
