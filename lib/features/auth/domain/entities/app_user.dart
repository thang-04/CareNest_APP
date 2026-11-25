import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';

/// Role BE mà App dùng được (BE AUTH-21, ADR-0022).
const kAppRoles = {'TEACHER', 'KITCHEN_STAFF', 'PARENT'};

/// Tài khoản đang đăng nhập theo `GET /accounts/me`. Không chứa token (CODING_GUIDE §2.1).
@immutable
class AppUser {
  const AppUser({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.roles,
    required this.permissions,
    required this.assignments,
    required this.childIds,
  });

  /// Từ `data` của `GET /accounts/me` mà `MobileSession` đã tải; khóa thiếu ⇒ rỗng.
  factory AppUser.fromAccount(Map<String, dynamic> account) {
    List<Object?> list(String key) => account[key] as List? ?? const [];
    return AppUser(
      userId: (account['userId'] as num?)?.toInt() ?? 0,
      username: account['username']?.toString() ?? '',
      fullName: account['fullName']?.toString() ?? '',
      roles: {for (final role in list('roles')) role.toString()},
      permissions: {for (final p in list('permissions')) p.toString()},
      assignments: [
        for (final a in list('assignments').whereType<Map>())
          StaffAssignment(
            staffRole: a['staffRole']?.toString() ?? '',
            campusId: (a['campusId'] as num?)?.toInt(),
            classroomId: (a['classroomId'] as num?)?.toInt(),
          ),
      ],
      childIds: [
        for (final id in list('childIds').whereType<num>()) id.toInt(),
      ],
    );
  }

  final int userId;

  /// Tên đăng nhập; tài khoản mới là SĐT 10 số (BE AUTH-18).
  final String username;
  final String fullName;
  final Set<String> roles;
  final Set<String> permissions;
  final List<StaffAssignment> assignments;
  final List<int> childIds;

  /// Chế độ được dùng, thứ tự GV → bếp → phụ huynh. Phụ huynh cần có con đang học (ADR-0022).
  List<AppMode> get modes => [
    if (roles.contains('TEACHER')) AppMode.teacher,
    if (roles.contains('KITCHEN_STAFF')) AppMode.kitchen,
    if (roles.contains('PARENT') && childIds.isNotEmpty) AppMode.parent,
  ];

  /// Có ít nhất một role của App (phân biệt tài khoản chỉ dùng Web với tài khoản chưa dùng được).
  bool get hasAppRole => roles.any(kAppRoles.contains);
}

/// Phân công đang hiệu lực hôm nay: GV theo lớp, bếp theo điểm trường (AUTH_CONTRACT).
@immutable
class StaffAssignment {
  const StaffAssignment({
    required this.staffRole,
    this.campusId,
    this.classroomId,
  });

  final String staffRole;
  final int? campusId;
  final int? classroomId;
}
