import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/routing/route_access_policy.dart';
import 'package:carenest_app/routing/route_paths.dart';

import '../helpers/fake_auth_controller.dart';

AuthState _signedIn(AppMode mode) => AuthSignedIn(
  fakeUser(roles: {'TEACHER', 'KITCHEN_STAFF', 'PARENT'}, childIds: [7]),
  mode,
);

void main() {
  test('checking_goesSplash', () {
    expect(
      redirectFor(const AuthChecking(), RoutePaths.login),
      RoutePaths.splash,
    );
    expect(redirectFor(const AuthChecking(), RoutePaths.splash), isNull);
  });

  test('retryNeeded_goesSplash', () {
    expect(
      redirectFor(
        const AuthRetryNeeded(NetworkFailure()),
        RoutePaths.teacherToday,
      ),
      RoutePaths.splash,
    );
  });

  test('signedOut_onTeacherRoute_goesLogin', () {
    expect(
      redirectFor(const AuthSignedOut(), RoutePaths.teacherAttendance),
      RoutePaths.login,
    );
  });

  test('signedOut_onLoginOrActivate_stays', () {
    expect(redirectFor(const AuthSignedOut(), RoutePaths.login), isNull);
    expect(redirectFor(const AuthSignedOut(), RoutePaths.activate), isNull);
    expect(redirectFor(const AuthSigningIn(), RoutePaths.activate), isNull);
  });

  test('blocked_goesBlocked', () {
    const blocked = AuthBlocked(AuthBlockReason.webOnlyAccount);

    expect(redirectFor(blocked, RoutePaths.parentToday), RoutePaths.blocked);
    expect(redirectFor(blocked, RoutePaths.blocked), isNull);
  });

  test('signedInTeacher_onLogin_goesTeacherHome', () {
    expect(
      redirectFor(_signedIn(AppMode.teacher), RoutePaths.login),
      RoutePaths.teacherToday,
    );
  });

  test('signedInParent_onTeacherRoute_goesParentHome', () {
    expect(
      redirectFor(_signedIn(AppMode.parent), RoutePaths.teacherAccount),
      RoutePaths.parentToday,
    );
  });

  test('signedInTeacher_onTeacherAttendance_stays', () {
    expect(
      redirectFor(_signedIn(AppMode.teacher), RoutePaths.teacherAttendance),
      isNull,
    );
  });

  test('signedInKitchen_onKitchenChild_stays', () {
    expect(
      redirectFor(_signedIn(AppMode.kitchen), RoutePaths.kitchenMeals),
      isNull,
    );
  });

  test('signedIn_prefixLookalike_goesHome', () {
    expect(
      redirectFor(_signedIn(AppMode.parent), '/parentx'),
      RoutePaths.parentToday,
    );
  });
}
