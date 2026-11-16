import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/auth/data/models/me_dto.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';

void main() {
  // Dạng theo mẫu GET /accounts/me ở BE AUTH_CONTRACT, giá trị giả
  final payload = <String, dynamic>{
    'userId': 12,
    'username': '0900000001',
    'fullName': 'Giáo viên A',
    'email': null,
    'roles': ['TEACHER', 'PARENT'],
    'permissions': ['CHILD_PROFILE_VIEW'],
    'schoolWidePermissions': <String>[],
    'assignments': [
      {
        'staffRole': 'TEACHER',
        'campusId': null,
        'classroomId': 3,
        'validFrom': '2026-09-01',
        'validTo': null,
      },
    ],
    'childIds': [7],
  };

  test('fromJson_fullPayload', () {
    final user = MeDto.fromJson(payload).toEntity();

    expect(user.userId, 12);
    expect(user.username, '0900000001');
    expect(user.fullName, 'Giáo viên A');
    expect(user.roles, {'TEACHER', 'PARENT'});
    expect(user.permissions, {'CHILD_PROFILE_VIEW'});
    expect(user.assignments.single.staffRole, 'TEACHER');
    expect(user.assignments.single.classroomId, 3);
    expect(user.assignments.single.campusId, isNull);
    expect(user.childIds, [7]);
    expect(user.modes, [AppMode.teacher, AppMode.parent]);
  });

  test('fromJson_nullLists_defaultEmpty', () {
    final user = MeDto.fromJson({
      'userId': 5,
      'username': 'bep.cs1',
      'fullName': 'Bếp cơ sở 1',
      'roles': ['KITCHEN_STAFF'],
      'permissions': null,
      'schoolWidePermissions': null,
      'assignments': null,
      'childIds': null,
    }).toEntity();

    expect(user.permissions, isEmpty);
    expect(user.assignments, isEmpty);
    expect(user.childIds, isEmpty);
    expect(user.modes, [AppMode.kitchen]);
  });
}
