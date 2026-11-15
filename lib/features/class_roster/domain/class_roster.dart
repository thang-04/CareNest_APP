import 'package:flutter/foundation.dart';

/// Ghi chú nổi bật của trẻ trong lớp — mã BE trả (dị ứng HLT-06, chế độ ăn, đang nghỉ).
enum RosterTagKind { allergy, leave, meal, diet }

@immutable
class RosterTag {
  const RosterTag(this.kind, this.label);

  final RosterTagKind kind;

  /// "Dị ứng hải sản"
  final String label;
}

/// Một trẻ trong lớp được phân công (AUTH-03).
@immutable
class RosterKid {
  const RosterKid({
    required this.id,
    required this.fullName,
    required this.ageLabel,
    required this.guardianLine,
    this.tag,
  });

  final String id;
  final String fullName;
  final String ageLabel;

  /// "Mẹ: 0912 345 678"
  final String guardianLine;
  final RosterTag? tag;

  /// Tên gọi trong lớp: hai chữ cuối, vd. "Minh Anh".
  String get shortName {
    final parts = fullName.split(' ');
    return parts.length <= 2
        ? fullName
        : parts.sublist(parts.length - 2).join(' ');
  }
}

@immutable
class ClassRoster {
  const ClassRoster({
    required this.classId,
    required this.className,
    required this.campusName,
    required this.kids,
  });

  final String classId;
  final String className;
  final String campusName;
  final List<RosterKid> kids;
}

abstract interface class ClassRosterSource {
  Future<ClassRoster> loadRoster(String classId);
}
