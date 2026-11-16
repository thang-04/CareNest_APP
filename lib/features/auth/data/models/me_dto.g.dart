// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeDto _$MeDtoFromJson(Map<String, dynamic> json) => MeDto(
  userId: (json['userId'] as num).toInt(),
  username: json['username'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String?,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  schoolWidePermissions:
      (json['schoolWidePermissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  assignments:
      (json['assignments'] as List<dynamic>?)
          ?.map((e) => AssignmentDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  childIds:
      (json['childIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
);

AssignmentDto _$AssignmentDtoFromJson(Map<String, dynamic> json) =>
    AssignmentDto(
      staffRole: json['staffRole'] as String,
      campusId: (json['campusId'] as num?)?.toInt(),
      classroomId: (json['classroomId'] as num?)?.toInt(),
      validFrom: json['validFrom'] as String?,
      validTo: json['validTo'] as String?,
    );
