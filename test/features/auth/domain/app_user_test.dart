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

  test('fromAccount_teacherParentWithChild_modesTeacherThenParent', () {
    expect(
      AppUser.fromAccount({
        'userId': 3,
        'roles': ['TEACHER', 'PARENT'],
        'childIds': [9],
      }).modes,
      [AppMode.teacher, AppMode.parent],
    );
  });

  test('fromAccount_parentNoChild_noParentMode', () {
    expect(
      AppUser.fromAccount({
        'userId': 3,
        'roles': ['TEACHER', 'PARENT'],
        'childIds': <int>[],
      }).modes,
      [AppMode.teacher],
    );
  });

  test('fromAccount_readsFieldsAndAssignments', () {
    final user = AppUser.fromAccount({
      'userId': 5,
      'username': '0912345678',
      'fullName': 'Cô Hà',
      'roles': ['TEACHER'],
      'permissions': ['ATTENDANCE_RECORD'],
      'assignments': [
        {'staffRole': 'TEACHER', 'campusId': 1, 'classroomId': 12},
      ],
    });
    expect(user.userId, 5);
    expect(user.username, '0912345678');
    expect(user.fullName, 'Cô Hà');
    expect(user.permissions, {'ATTENDANCE_RECORD'});
    expect(user.assignments.single.classroomId, 12);
    expect(user.childIds, isEmpty);
  });
}
