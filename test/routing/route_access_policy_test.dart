import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';
import 'package:carenest_app/routing/route_access_policy.dart';
import 'package:carenest_app/routing/route_paths.dart';

void main() {
  test('homePathFor_eachMode', () {
    expect(homePathFor(AppMode.teacher), RoutePaths.teacherToday);
    expect(homePathFor(AppMode.kitchen), RoutePaths.kitchenHome);
    expect(homePathFor(AppMode.parent), RoutePaths.parentToday);
  });

  test('shellRoleFor_eachMode', () {
    expect(shellRoleFor(AppMode.teacher), AppRole.teacher);
    expect(shellRoleFor(AppMode.kitchen), AppRole.kitchen);
    expect(shellRoleFor(AppMode.parent), AppRole.parent);
  });
}
