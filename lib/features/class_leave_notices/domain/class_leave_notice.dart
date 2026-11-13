import 'package:flutter/foundation.dart';

/// Có đơn nghỉ (ngày nghỉ tự ghi Vắng có phép — ATT-04) hoặc trẻ vắng không có đơn.
/// GV chỉ xem, không duyệt, không đánh dấu đã xem (ATT-05).
enum ClassLeaveState { notice, absentNoNotice }

@immutable
class ClassLeaveEntry {
  const ClassLeaveEntry({
    required this.id,
    required this.childName,
    required this.period,
    required this.reason,
    required this.meta,
    required this.state,
    required this.upcoming,
  });

  final String id;
  final String childName;

  /// "Thứ Ba 13/10" hoặc "11/10 – 13/10" — đơn theo ngày, không chia buổi (ATT-05).
  final String period;
  final String reason;

  /// "Mẹ (Thu Lan) gửi lúc 07:55"
  final String meta;
  final ClassLeaveState state;

  /// Thuộc "Hôm nay & sắp tới" — BE lọc theo ngày.
  final bool upcoming;
}

abstract interface class ClassLeaveSource {
  Future<List<ClassLeaveEntry>> load(String classId);
}
