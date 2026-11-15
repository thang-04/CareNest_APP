import 'package:flutter/foundation.dart';

/// Lớp được phân công (AUTH-03) — danh sách do BE trả.
@immutable
class ClassSummary {
  const ClassSummary({
    required this.id,
    required this.name,
    required this.campusName,
    required this.childCount,
  });

  final String id;
  final String name;
  final String campusName;
  final int childCount;
}

/// Trạng thái điểm danh một trẻ (ATT-01). Mã thật theo hợp đồng BE khi có endpoint.
enum AttendanceStatus { present, excused, unexcused, notRecorded }

/// Một dòng nhập: điểm danh + tham gia ăn nhập cùng lúc (ATT-02).
@immutable
class KidAttendance {
  const KidAttendance({
    required this.childId,
    required this.fullName,
    required this.status,
    required this.eats,
    this.note,
    this.hasLeaveNotice = false,
  });

  final String childId;
  final String fullName;
  final AttendanceStatus status;
  final bool eats;

  /// Ghi chú BE trả dưới tên: đơn nghỉ, dị ứng, suất ăn riêng.
  final String? note;

  /// Có đơn nghỉ hôm nay ⇒ BE đặt sẵn có phép + không ăn (ATT-04); bấm "Vắng" vẫn là có phép.
  final bool hasLeaveNotice;

  KidAttendance copyWith({AttendanceStatus? status, bool? eats}) {
    return KidAttendance(
      childId: childId,
      fullName: fullName,
      status: status ?? this.status,
      eats: eats ?? this.eats,
      note: note,
      hasLeaveNotice: hasLeaveNotice,
    );
  }
}

@immutable
class AttendanceSheet {
  const AttendanceSheet({
    required this.classSummary,
    required this.date,
    required this.kids,
    this.lockAt,
  });

  final ClassSummary classSummary;
  final DateTime date;
  final List<KidAttendance> kids;

  /// Giờ khoá nhập BE trả (cut-off P-03 PENDING); APP chỉ hiển thị, không tự khoá theo giờ máy.
  final String? lockAt;
}
