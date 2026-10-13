import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/reward_proposals/domain/reward_batch.dart';

/// Tỉ lệ đánh giá một khối BE trả (thang và tiêu chí theo P-11, PENDING).
@immutable
class GroupEvaluation {
  const GroupEvaluation({
    required this.groupLabel,
    required this.ratio,
    required this.percent,
  });

  /// "Mầm"
  final String groupLabel;

  /// 0–1, chỉ để vẽ thanh.
  final double ratio;

  /// "91%"
  final String percent;
}

/// Tổng quan toàn trường cho Hiệu trưởng (AUTH-01) — mockup H01. Mọi số do BE tổng hợp (AUTH-08).
@immutable
class SchoolOverview {
  const SchoolOverview({
    required this.staffName,
    required this.schoolName,
    required this.campusCount,
    required this.schoolYear,
    required this.date,
    required this.present,
    required this.enrolled,
    required this.presentRate,
    required this.confirmedMeals,
    required this.mealCampuses,
    required this.menusPublished,
    required this.evaluationTitle,
    required this.evaluations,
    required this.pending,
  });

  /// "Nguyễn Thị Hồng"
  final String staffName;

  /// "Trường MN Thượng Hồng"
  final String schoolName;
  final int campusCount;

  /// "2026–2027"
  final String schoolYear;
  final DateTime date;
  final int present;
  final int enrolled;

  /// "93%"
  final String presentRate;
  final int confirmedMeals;

  /// Số cơ sở đã chốt suất.
  final int mealCampuses;

  /// Số cơ sở đã công bố thực đơn tuần.
  final int menusPublished;

  /// "Đánh giá trẻ tháng 9"
  final String evaluationTitle;
  final List<GroupEvaluation> evaluations;

  /// Đợt đang chờ Hiệu trưởng duyệt.
  final List<RewardBatch> pending;
}

abstract interface class SchoolOverviewSource {
  Future<SchoolOverview> loadToday();
}
