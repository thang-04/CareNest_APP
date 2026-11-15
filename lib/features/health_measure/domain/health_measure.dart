import 'package:flutter/foundation.dart';

enum MeasureState { measured, pending, absent }

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
    this.published = true,
  });

  final String childId;
  final String fullName;
  final String ageLabel;
  final MeasureState state;

  /// Chuỗi người dùng nhập, giữ nguyên dấu phẩy thập phân ("17,2").
  final String? height;
  final String? weight;

  /// "vừa xong", "5 phút trước"
  final String? measuredWhen;

  /// "05/09: 103 cm · 16,8 kg"
  final String? previous;
  final bool published;
}

/// Kết quả xếp loại BE tính theo chuẩn của trường (HLT-03, P-13 PENDING) — APP chỉ hiển thị.
@immutable
class MeasureResult {
  const MeasureResult({
    required this.label,
    required this.detail,
    required this.position,
  });

  /// "Bình thường"
  final String label;

  /// "Cân nặng/tuổi · Chiều cao/tuổi đạt"
  final String detail;

  /// 0..1 trên thang Thiếu cân – Bình thường – Thừa cân, BE trả.
  final double position;
}

@immutable
class MeasureMonth {
  const MeasureMonth({required this.title, required this.kids});

  /// "Đo sức khỏe tháng 10"
  final String title;
  final List<MeasureKid> kids;
}

abstract interface class HealthMeasureSource {
  Future<MeasureMonth> loadMonth(String classId);

  /// Gửi số đo để BE tính kết quả; null khi BE chưa trả (thiếu số, chưa có chuẩn).
  Future<MeasureResult?> preview(String childId, String height, String weight);
  Future<void> save(MeasureKid kid);
}
