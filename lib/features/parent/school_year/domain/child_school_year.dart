import 'package:flutter/foundation.dart';

import 'package:carenest_app/core/integration/api_dates.dart';

/// `SchoolYear.status` BE: PLANNED / ACTIVE / CLOSED.
enum ChildSchoolYearStatus { planned, active, closed }

/// Năm học bé có học lớp (`GET /children/{id}/school-years`); BE quyết định năm nào hiện (AUTH-04, CFG-YR-05).
@immutable
class ChildSchoolYear {
  const ChildSchoolYear({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.className,
  });

  final String id;

  /// "2026–2027"
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final ChildSchoolYearStatus status;

  /// Lớp của bé trong năm đó.
  final String className;

  /// AUTH-03: năm không đang chạy chỉ xem (không gửi đơn nghỉ).
  bool get readOnly => status != ChildSchoolYearStatus.active;

  DateTime _lastDay(DateTime today) => today.isAfter(endDate) ? endDate : today;

  /// Khoảng xem lại gần đây (Đánh giá, Khen thưởng) trong năm (ATT-15): tới hôm nay hoặc cuối năm, lùi như
  /// [recentStarts] nhưng không trước đầu năm; null khi năm chưa bắt đầu.
  ({DateTime from, DateTime to})? recentRange(DateTime today) {
    final to = _lastDay(today);
    if (to.isBefore(startDate)) return null;
    final from = recentStarts(to).first;
    return (from: from.isBefore(startDate) ? startDate : from, to: to);
  }

  /// Tháng điểm danh trong năm: tháng của hôm nay (năm đang chạy) hoặc tháng cuối năm; null khi năm chưa bắt đầu.
  ({DateTime from, DateTime to})? monthRange(DateTime today) {
    final to = _lastDay(today);
    if (to.isBefore(startDate)) return null;
    final month = DateTime(to.year, to.month);
    return (from: month.isBefore(startDate) ? startDate : month, to: to);
  }
}

abstract interface class ChildSchoolYearSource {
  Future<List<ChildSchoolYear>> loadYears(String childId);
}
