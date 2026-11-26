import 'package:carenest_app/features/teacher/class_leave_notices/domain/class_leave_notice.dart';

/// Dữ liệu giả dạng BE `LeaveRequestResponse`, khớp đơn của bé Minh Anh (13/10) và Khánh Linh (11–13/10).
class FakeClassLeaveSource implements ClassLeaveSource {
  const FakeClassLeaveSource();

  @override
  Future<List<ClassLeaveEntry>> load(
    String classId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final range = defaultLeaveRange(DateTime(2026, 10, 12));
    final start = from ?? range.$1;
    final end = to ?? range.$2;
    return [
      for (final entry in _all)
        if (!entry.toDate.isBefore(start) && !entry.fromDate.isAfter(end))
          entry,
    ];
  }

  static final _all = [
    ClassLeaveEntry(
      id: 'l-1',
      childId: 'child-1',
      childName: 'Nguyễn Minh Anh',
      fromDate: DateTime(2026, 10, 13),
      toDate: DateTime(2026, 10, 13),
      reason: 'Khám răng định kỳ',
      status: LeaveRequestStatus.active,
      className: 'Mầm 3A',
      part: LeavePart.afternoon,
      eats: false,
      eatsMeals: const ['LUNCH'],
      createdByName: 'Nguyễn Thu Lan',
      createdAt: DateTime(2026, 10, 12, 7, 55),
      appliedDates: [DateTime(2026, 10, 13)],
    ),
    ClassLeaveEntry(
      id: 'l-2',
      childId: 'k-03',
      childName: 'Phạm Khánh Linh',
      fromDate: DateTime(2026, 10, 11),
      toDate: DateTime(2026, 10, 13),
      reason: 'Bé bị ốm, sốt nhẹ',
      status: LeaveRequestStatus.active,
      className: 'Mầm 3A',
      noticeOnly: true,
      createdByName: 'Phạm Văn Tùng',
      createdAt: DateTime(2026, 10, 10, 20, 10),
      appliedDates: [DateTime(2026, 10, 12), DateTime(2026, 10, 13)],
      skippedDates: [DateTime(2026, 10, 11)],
    ),
    ClassLeaveEntry(
      id: 'l-3',
      childId: 'k-06',
      childName: 'Trần Bảo Ngọc',
      fromDate: DateTime(2026, 10, 16),
      toDate: DateTime(2026, 10, 16),
      reason: 'Đi khám định kỳ',
      status: LeaveRequestStatus.cancelled,
      createdByName: 'Trần Thị Mai',
      createdAt: DateTime(2026, 10, 9, 19, 30),
      cancelledAt: DateTime(2026, 10, 11, 8, 0),
    ),
    ClassLeaveEntry(
      id: 'l-4',
      childId: 'k-02',
      childName: 'Lê Hoàng Nam',
      fromDate: DateTime(2026, 9, 29),
      toDate: DateTime(2026, 9, 29),
      reason: 'Việc gia đình',
      status: LeaveRequestStatus.active,
      createdByName: 'Lê Thị Mai',
      createdAt: DateTime(2026, 9, 28, 21, 0),
      appliedDates: [DateTime(2026, 9, 29)],
    ),
  ];
}
