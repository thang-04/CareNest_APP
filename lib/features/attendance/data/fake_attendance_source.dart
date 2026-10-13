import 'package:carenest_app/features/attendance/domain/attendance.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Nguồn dữ liệu điểm danh lớp/ngày; bản thật là upsert idempotent theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH).
abstract interface class AttendanceSource {
  Future<AttendanceSheet> loadSheet(String classId);
  Future<void> save(String classId, DateTime date, List<KidAttendance> kids);
}

/// Dữ liệu giả lớp Mầm 3A (28 trẻ) đầu giờ 12/10: GV chưa nhập; Khánh Linh và Minh Châu có đơn nghỉ;
/// Đức Huy vắng không đơn (cô Hà đã gọi phụ huynh) — khớp màn Đơn xin nghỉ của lớp.
class FakeAttendanceSource implements AttendanceSource {
  FakeAttendanceSource({
    this.mode = FakeMode.data,
    this.failSave = false,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final bool failSave;
  final Duration delay;

  static const classId = FakeClassRosterSource.classId;

  static const _notes = {
    'child-1': 'Đơn nghỉ 13/10',
    'k-02': 'Dị ứng hải sản',
    'k-03': 'Ốm · đơn 11–13/10',
    'k-04': 'Chưa có đơn',
    'k-05': 'Ăn 1 bữa · Trưa',
    'k-08': 'Việc gia đình · đơn 12/10',
  };
  static const _onLeave = {'k-03', 'k-08'};

  static List<KidAttendance> get kids => [
    for (final kid in FakeClassRosterSource.kids)
      KidAttendance(
        childId: kid.id,
        fullName: kid.fullName,
        status: _onLeave.contains(kid.id)
            ? AttendanceStatus.excused
            : kid.id == 'k-04'
            ? AttendanceStatus.unexcused
            : AttendanceStatus.notRecorded,
        eats: !_onLeave.contains(kid.id) && kid.id != 'k-04',
        note: _notes[kid.id],
        hasLeaveNotice: _onLeave.contains(kid.id),
      ),
  ];

  @override
  Future<AttendanceSheet> loadSheet(String classId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final list = mode == FakeMode.empty ? const <KidAttendance>[] : kids;
    return AttendanceSheet(
      classSummary: ClassSummary(
        id: classId,
        name: FakeClassRosterSource.className,
        campusName: FakeClassRosterSource.campusName,
        childCount: list.length,
      ),
      date: FakeParentHomeSource.today,
      kids: list,
      lockAt: '08:30',
    );
  }

  @override
  Future<void> save(
    String classId,
    DateTime date,
    List<KidAttendance> kids,
  ) async {
    await Future<void>.delayed(delay);
    if (failSave) throw StateError('Không lưu được (giả lập mất mạng)');
  }
}
