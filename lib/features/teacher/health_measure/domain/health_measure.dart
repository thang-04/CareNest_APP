import 'package:flutter/foundation.dart';

import 'package:carenest_app/core/theme/app_status_colors.dart';

enum MeasureState { measured, pending, absent }

/// Mức BMI theo tuổi BE xếp cho số đo đã lưu (HLT-18) — APP chỉ đổi mã sang chữ, không tự tính.
@immutable
class MeasureResult {
  const MeasureResult({
    required this.label,
    required this.tone,
    this.detail = '',
  });

  /// "Bình thường"
  final String label;
  final AppStatusTone tone;

  /// "BMI 15,9"
  final String detail;
}

@immutable
class MeasureKid {
  const MeasureKid({
    required this.childId,
    required this.fullName,
    required this.ageLabel,
    required this.state,
    this.height,
    this.weight,
    this.measuredWhen,
    this.previous,
    this.note,
    this.published = true,
    this.result,
  });

  final String childId;
  final String fullName;
  final String ageLabel;
  final MeasureState state;

  /// Chuỗi người dùng nhập, giữ nguyên dấu phẩy thập phân ("17,2").
  final String? height;
  final String? weight;

  /// "05/09"
  final String? measuredWhen;

  /// "05/09: 103 cm · 16,8 kg"
  final String? previous;
  final String? note;
  final bool published;

  /// BMI và mức BMI BE trả cho số đo đã lưu; null khi BE không trả.
  final MeasureResult? result;
}

/// Kỳ cân đo đang mở ở điểm trường của lớp: tên, loại, ngày, trạng thái, tiến độ nhập (BE trả).
@immutable
class MeasureCampaign {
  const MeasureCampaign({
    required this.name,
    required this.kindLabel,
    required this.dateRange,
    required this.statusLabel,
    required this.recorded,
    required this.total,
    this.campusName = '',
    this.absent = 0,
  });

  final String name;
  final String kindLabel;
  final String campusName;

  /// "05/11/2026 – 20/11/2026"
  final String dateRange;
  final String statusLabel;
  final int recorded;
  final int total;
  final int absent;
}

/// Một dòng của "Đợt khám và kỳ cân đo" (`GET /health-checks`), chỉ xem.
@immutable
class HealthCampaign {
  const HealthCampaign({
    required this.id,
    required this.name,
    required this.kindLabel,
    required this.dateRange,
    required this.statusLabel,
    required this.statusTone,
    required this.recorded,
    required this.total,
    this.campusName = '',
    this.warningLabel,
  });

  final String id;
  final String name;
  final String kindLabel;
  final String campusName;
  final String dateRange;
  final String statusLabel;
  final AppStatusTone statusTone;
  final int recorded;
  final int total;

  /// "2 trẻ có cảnh báo" — số do BE đếm; null ⇒ không có.
  final String? warningLabel;
}

@immutable
class MeasureMonth {
  const MeasureMonth({required this.title, required this.kids, this.campaign});

  /// Kỳ cân đo đang mở không có ⇒ rỗng.
  final String title;
  final List<MeasureKid> kids;
  final MeasureCampaign? campaign;

  /// HLT-01: chỉ nhập số đo khi có kỳ cân đo đang diễn ra.
  bool get isOpen => campaign != null;
}

/// Nguồn cân đo theo HLT-09, HLT-11, HLT-13. BE quyết định quyền, kỳ đo và kết quả.
abstract interface class HealthMeasureSource {
  Future<MeasureMonth> loadMonth(String classId);

  /// Các đợt khám, kỳ cân đo xem được (chỉ đọc).
  Future<List<HealthCampaign>> loadCampaigns();

  /// Tạo hoặc sửa số đo. Sửa bản đã có bắt buộc `reason`; lưu là công bố.
  Future<void> saveMeasurement({
    required String childId,
    required String height,
    required String weight,
    String? note,
    String? reason,
  });
}
