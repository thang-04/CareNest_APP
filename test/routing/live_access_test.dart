import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/routing/live_access.dart';
import 'package:carenest_app/routing/route_paths.dart';

String? _go(
  String location, {
  bool signedIn = true,
  AppMode? mode = AppMode.teacher,
  bool photoRequired = false,
}) => liveRedirect(
  signedIn: signedIn,
  mode: mode,
  photoRequired: photoRequired,
  location: location,
);

void main() {
  test('signedOut_anyPath_goesLogin', () {
    expect(_go('/parent', signedIn: false, mode: null), RoutePaths.login);
  });

  test('signedOut_login_stays', () {
    expect(_go(RoutePaths.login, signedIn: false, mode: null), isNull);
  });

  test('signedOut_activate_stays', () {
    expect(_go(RoutePaths.activate, signedIn: false, mode: null), isNull);
  });

  test('signedIn_noAppMode_goesUnsupported', () {
    expect(_go('/teacher', mode: null), RoutePaths.liveUnsupported);
  });

  test('signedIn_noAppMode_onUnsupported_stays', () {
    expect(_go(RoutePaths.liveUnsupported, mode: null), isNull);
  });

  test('signedIn_login_goesModeHome', () {
    expect(_go(RoutePaths.login), RoutePaths.teacherToday);
  });

  test('signedIn_otherRolePath_goesModeHome', () {
    expect(
      _go(RoutePaths.teacherAttendance, mode: AppMode.parent),
      RoutePaths.parentToday,
    );
  });

  test('signedIn_previewPath_goesModeHome', () {
    expect(
      _go(RoutePaths.preview, mode: AppMode.kitchen),
      RoutePaths.kitchenHome,
    );
  });

  test('signedIn_ownChildPath_stays', () {
    expect(_go(RoutePaths.parentLeaveNew, mode: AppMode.parent), isNull);
  });

  test('signedIn_liveEntry_passesThrough', () {
    expect(_go('/live/notifications/12'), isNull);
  });

  test('signedIn_withMode_unsupportedPage_goesModeHome', () {
    expect(_go(RoutePaths.liveUnsupported), RoutePaths.teacherToday);
  });

  test('signedIn_prefixLookalike_goesHome', () {
    expect(_go('/teacherx'), RoutePaths.teacherToday);
  });
}
