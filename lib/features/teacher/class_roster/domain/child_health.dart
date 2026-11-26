import 'package:flutter/foundation.dart';

import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Một lần đo/khám trong sổ sức khỏe của trẻ (`GET /children/{id}/health`), mới nhất trước.
@immutable
class HealthEntry {
  const HealthEntry({
    required this.date,
    required this.title,
    required this.kindLabel,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.warningLabel,
    this.warningTone,
    this.ageMonths,
  });

  final DateTime date;

  /// Tên kỳ cân đo / đợt khám.
  final String title;

  /// "Kỳ cân đo" hoặc "Đợt khám sức khỏe".
  final String kindLabel;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final int? ageMonths;

  /// Cảnh báo do BE xếp (mức BMI hoặc kết luận bác sĩ), APP chỉ đổi mã sang chữ; null ⇒ BE không trả.
  final String? warningLabel;
  final AppStatusTone? warningTone;
}

@immutable
class ChildHealthHistory {
  const ChildHealthHistory({required this.childId, required this.entries});

  final String childId;
  final List<HealthEntry> entries;
}

/// Nguồn sổ sức khỏe một trẻ — chỉ xem. BE quyết định phạm vi lớp.
abstract interface class ChildHealthSource {
  Future<ChildHealthHistory> load(String childId);
}
