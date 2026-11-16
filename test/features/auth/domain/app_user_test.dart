import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/domain/entities/app_user.dart';

AppUser _user(Set<String> roles, {List<int> childIds = const []}) => AppUser(
  userId: 1,
  username: '0900000001',
  fullName: 'Người dùng',
  roles: roles,
  permissions: const {},
  assignments: const [],
  childIds: childIds,
);

void main() {
  test('modes_teacherAndParentWithChildren', () {
    expect(_user({'PARENT', 'TEACHER'}, childIds: [7]).modes, [
      AppMode.teacher,
      AppMode.parent,
    ]);
  });

  test('modes_parentWithoutChildren_empty', () {
    final user = _user({'PARENT'});

    expect(user.modes, isEmpty);
    expect(user.hasAppRole, isTrue);
  });

  test('modes_principalOnly_empty', () {
    final user = _user({'PRINCIPAL'});

    expect(user.modes, isEmpty);
    expect(user.hasAppRole, isFalse);
  });

  test('modes_kitchen', () {
    expect(_user({'KITCHEN_STAFF'}).modes, [AppMode.kitchen]);
  });
}
