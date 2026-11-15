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
    this.editReason,
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

  /// Lý do sửa số đo đã lưu — bắt buộc khi sửa, BE lưu lịch sử (HLT-13).
  /// Lưu là công bố cho phụ huynh, không có bước công bố riêng (HLT-11).
  final String? editReason;
}

/// Kết quả xếp loại hệ thống tính (HLT-12, HLT-18) — APP chỉ hiển thị, GV không chọn.
@immutable
class MeasureResult {
  const MeasureResult({
    required this.label,
    required this.detail,
    required this.scale,
  });

  /// "Bình thường" — một mục trong [scale].
  final String label;

  /// "Cân nặng/tuổi · Chiều cao/tuổi đạt"
  final String detail;

  /// Các mức hiển thị, BE trả: "Thiếu cân", "Bình thường", "Thừa cân".
  final List<String> scale;
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
