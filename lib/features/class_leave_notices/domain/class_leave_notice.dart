import 'package:flutter/foundation.dart';

/// Trạng thái hiển thị cho GV: đơn mới / đã xem, hoặc trẻ vắng không có đơn.
/// GV chỉ xem/ghi nhận, không duyệt (ATT-05).
enum ClassLeaveState { fresh, seen, absentNoNotice }

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

  /// "Thứ Ba 13/10 · Cả ngày"
  final String period;
  final String reason;

  /// "Mẹ (Thu Lan) gửi lúc 07:55"
  final String meta;
  final ClassLeaveState state;

  /// Thuộc "Hôm nay & sắp tới" — BE lọc theo ngày.
  final bool upcoming;

  ClassLeaveEntry markSeen() => ClassLeaveEntry(
    id: id,
    childName: childName,
    period: period,
    reason: reason,
    meta: meta,
    state: state == ClassLeaveState.fresh ? ClassLeaveState.seen : state,
    upcoming: upcoming,
  );
}

abstract interface class ClassLeaveSource {
  Future<List<ClassLeaveEntry>> load(String classId);
}
