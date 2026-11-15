import 'package:carenest_app/features/class_leave_notices/domain/class_leave_notice.dart';

/// Dữ liệu giả mockup T03, khớp đơn của phụ huynh bé Minh Anh (13/10, Khám răng định kỳ).
class FakeClassLeaveSource implements ClassLeaveSource {
  const FakeClassLeaveSource();

  @override
  Future<List<ClassLeaveEntry>> load(String classId) async => const [
    ClassLeaveEntry(
      id: 'l-1',
      childName: 'Nguyễn Minh Anh',
      period: 'Thứ Ba 13/10 · Cả ngày',
      reason: 'Khám răng định kỳ',
      meta: 'Mẹ (Thu Lan) gửi lúc 07:55',
      state: ClassLeaveState.fresh,
      upcoming: true,
    ),
    ClassLeaveEntry(
      id: 'l-2',
      childName: 'Phạm Khánh Linh',
      period: '11/10 – 13/10 · Cả ngày',
      reason: 'Bé bị ốm, sốt nhẹ',
      meta: 'Bố gửi lúc 20:10 ngày 10/10',
      state: ClassLeaveState.fresh,
      upcoming: true,
    ),
    ClassLeaveEntry(
      id: 'l-3',
      childName: 'Trần Bảo Ngọc',
      period: 'Thứ Sáu 16/10 · Buổi chiều',
      reason: 'Đi khám định kỳ',
      meta: 'Mẹ gửi ngày 09/10',
      state: ClassLeaveState.seen,
      upcoming: true,
    ),
    ClassLeaveEntry(
      id: 'l-4',
      childName: 'Vũ Đức Huy',
      period: 'Thứ Hai 12/10',
      reason: 'Chưa có đơn – vắng không phép',
      meta: 'Cô Hà đã gọi phụ huynh 08:15',
      state: ClassLeaveState.absentNoNotice,
      upcoming: true,
    ),
    ClassLeaveEntry(
      id: 'l-5',
      childName: 'Lê Hoàng Nam',
      period: 'Thứ Ba 29/09 · Cả ngày',
      reason: 'Việc gia đình',
      meta: 'Mẹ gửi ngày 28/09',
      state: ClassLeaveState.seen,
      upcoming: false,
    ),
  ];
}
