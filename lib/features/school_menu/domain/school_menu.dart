import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/parent_menu/domain/weekly_menu.dart';

/// Thực đơn thay thế cho trẻ dị ứng / ăn chay ở mức cần để nấu: số bé, đổi món — không tên trẻ (AUTH-05).
@immutable
class AlternativeMenu {
  const AlternativeMenu({
    required this.title,
    required this.count,
    required this.swaps,
    required this.isAllergy,
  });

  /// "Dị ứng hải sản"
  final String title;
  final int count;

  /// Cặp (món gốc, món thay) — APP vẽ mũi tên bằng icon, font Be Vietnam Pro không có ký tự →.
  final List<(String, String)> swaps;
  final bool isAllergy;
}

/// Thực đơn một nhóm tuổi một ngày, đã duyệt (NUT-08); định lượng theo nhóm tuổi do BE tính (NUT-06).
@immutable
class AgeGroupMenu {
  const AgeGroupMenu({
    required this.groupId,
    required this.groupLabel,
    required this.ageRange,
    required this.childCount,
    required this.meals,
    this.alternatives = const [],
  });

  final String groupId;

  /// "Mầm"
  final String groupLabel;

  /// "3–4 tuổi"
  final String ageRange;
  final int childCount;
  final List<MenuMeal> meals;
  final List<AlternativeMenu> alternatives;
}

@immutable
class SchoolMenuWeek {
  const SchoolMenuWeek({
    required this.weekStart,
    required this.groups,
    required this.days,
    this.publishedNote,
    this.nutritionSummary,
  });

  final DateTime weekStart;

  /// Thứ tự nhóm tuổi hiển thị: (id, nhãn).
  final List<(String, String)> groups;

  /// Ngày (yyyymmdd) → nhóm → thực đơn.
  final Map<DateTime, Map<String, AgeGroupMenu>> days;

  /// "Đã duyệt & công bố · 09/10"
  final String? publishedNote;

  /// Tóm tắt cân đối dinh dưỡng BE trả cho cả tuần, vd. "Năng lượng đạt chuẩn 3/3 nhóm tuổi · …"
  final String? nutritionSummary;
}

abstract interface class SchoolMenuSource {
  Future<SchoolMenuWeek> loadWeek(String campusId);
}
