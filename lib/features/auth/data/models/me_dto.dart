import 'package:json_annotation/json_annotation.dart';

import 'package:carenest_app/features/auth/domain/entities/app_user.dart';

part 'me_dto.g.dart';

/// `data` của `GET /accounts/me` (BE AUTH_CONTRACT › Tài khoản hiện tại).
@JsonSerializable(createToJson: false)
class MeDto {
  const MeDto({
    required this.userId,
    required this.username,
    required this.fullName,
    this.email,
    this.roles = const [],
    this.permissions = const [],
    this.schoolWidePermissions = const [],
    this.assignments = const [],
    this.childIds = const [],
  });

  factory MeDto.fromJson(Map<String, dynamic> json) => _$MeDtoFromJson(json);

  final int userId;
  final String username;
  final String fullName;
  final String? email;
  @JsonKey(defaultValue: <String>[])
  final List<String> roles;
  @JsonKey(defaultValue: <String>[])
  final List<String> permissions;
  @JsonKey(defaultValue: <String>[])
  final List<String> schoolWidePermissions;
  @JsonKey(defaultValue: <AssignmentDto>[])
  final List<AssignmentDto> assignments;
  @JsonKey(defaultValue: <int>[])
  final List<int> childIds;

  AppUser toEntity() => AppUser(
    userId: userId,
    username: username,
    fullName: fullName,
    roles: roles.toSet(),
    permissions: permissions.toSet(),
    assignments: [for (final a in assignments) a.toEntity()],
    childIds: List.unmodifiable(childIds),
  );
}

@JsonSerializable(createToJson: false)
class AssignmentDto {
  const AssignmentDto({
    required this.staffRole,
    this.campusId,
    this.classroomId,
    this.validFrom,
    this.validTo,
  });

  factory AssignmentDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentDtoFromJson(json);

  final String staffRole;
  final int? campusId;
  final int? classroomId;
  final String? validFrom;
  final String? validTo;

  StaffAssignment toEntity() => StaffAssignment(
    staffRole: staffRole,
    campusId: campusId,
    classroomId: classroomId,
  );
}
