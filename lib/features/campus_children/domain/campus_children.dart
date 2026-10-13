import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/class_roster/domain/class_roster.dart';

/// Một trẻ của cơ sở Phó HT phụ trách (AUTH-02). Ghi chú dị ứng / chế độ ăn là mã BE trả (HLT-06).
@immutable
class CampusChild {
  const CampusChild({
    required this.id,
    required this.fullName,
    required this.classId,
    required this.className,
    required this.ageLabel,
    this.tag,
  });

  final String id;
  final String fullName;
  final String classId;
  final String className;

  /// "4 tuổi"
  final String ageLabel;

  /// Chỉ dị ứng hoặc chế độ ăn; trạng thái trong ngày không hiện ở đây.
  final RosterTag? tag;
}

@immutable
class CampusClass {
  const CampusClass(this.id, this.name);

  final String id;
  final String name;
}

@immutable
class CampusChildren {
  const CampusChildren({
    required this.campusName,
    required this.classes,
    required this.children,
  });

  final String campusName;
  final List<CampusClass> classes;
  final List<CampusChild> children;
}

abstract interface class CampusChildrenSource {
  Future<CampusChildren> load(String campusId);
}
