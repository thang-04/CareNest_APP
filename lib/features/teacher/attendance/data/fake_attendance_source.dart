import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';

/// Nguồn dữ liệu điểm danh lớp/ngày; bản thật là upsert idempotent theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH).
/// [date] null = hôm nay theo BE.
abstract interface class AttendanceSource {
  Future<AttendanceSheet> loadSheet(String classId, {DateTime? date});
  Future<void> save(String classId, DateTime date, List<KidAttendance> kids);
}

/// Dữ liệu giả lớp Mầm 3A (28 trẻ) đầu giờ 12/10, dạng như BE: chưa trẻ nào được ghi thủ công; Khánh Linh
/// và một trẻ khác có đơn nghỉ cả ngày (BE đã ghi Vắng có phép), một trẻ nghỉ sáng. Ngày khác hôm nay: đã khóa.
class FakeAttendanceSource implements AttendanceSource {
  FakeAttendanceSource({
    this.mode = FakeMode.data,
    this.failSave = false,
    this.locked = false,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final bool failSave;
  final bool locked;
  final Duration delay;

  static const classId = FakeClassRosterSource.classId;

  /// Danh sách vừa gửi lưu (để test kiểm tra thân request).
  List<KidAttendance>? lastSaved;

  /// Ngày đã yêu cầu ở lần tải gần nhất (để test kiểm tra tham số).
  DateTime? lastRequestedDate;

  static final _today = FakeParentHomeSource.today;

  static LeaveNotice _leave(
    String reason, {
    DayPartCode part = DayPartCode.fullDay,
    bool? eats,
    List<MealSession> eatsMeals = const [],
  }) => LeaveNotice(
    fromDate: DateTime(2026, 10, 11),
    toDate: DateTime(2026, 10, 13),
    reason: reason,
    part: part,
    eats: eats,
    eatsMeals: eatsMeals,
  );

  static List<KidAttendance> get kids => [
    for (final kid in FakeClassRosterSource.kids)
      switch (kid.id) {
        // BE ghi sẵn Vắng có phép cho đơn nghỉ cả ngày
        'k-03' => KidAttendance(
          childId: kid.id,
          fullName: kid.fullName,
          status: AttendanceStatus.excused,
          leave: _leave('Ốm'),
        ),
        'k-08' => KidAttendance(
          childId: kid.id,
          fullName: kid.fullName,
          status: AttendanceStatus.excused,
          leave: _leave('Việc gia đình'),
        ),
        'k-09' => KidAttendance(
          childId: kid.id,
          fullName: kid.fullName,
          status: AttendanceStatus.excused,
          absentPart: DayPartCode.morning,
          leave: _leave(
            'Khám bệnh buổi sáng',
            part: DayPartCode.morning,
            eats: true,
            eatsMeals: const [MealSession.afternoon],
          ),
        ),
        'k-02' => KidAttendance(
          childId: kid.id,
          fullName: kid.fullName,
          status: AttendanceStatus.notRecorded,
          hasAllergy: true,
          health: const KidHealthBrief(
            checked: true,
            noted: true,
            temperature: 37.8,
          ),
        ),
        'k-06' => KidAttendance(
          childId: kid.id,
          fullName: kid.fullName,
          status: AttendanceStatus.notRecorded,
          mealRegistered: false,
        ),
        _ => KidAttendance(
          childId: kid.id,
          fullName: kid.fullName,
          status: AttendanceStatus.notRecorded,
        ),
      },
  ];

  /// Ngày đã qua: BE trả sổ đã ghi, đã khóa.
  static List<KidAttendance> _history() => [
    for (final kid in kids)
      kid.status == AttendanceStatus.notRecorded
          ? kid.copyWith(
              status: AttendanceStatus.present,
              meals: {
                for (final s in MealSession.values) s: kid.mealRegistered,
              },
            )
          : kid,
  ];

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<AttendanceSheet> loadSheet(String classId, {DateTime? date}) async {
    await Future<void>.delayed(delay);
    lastRequestedDate = date;
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final day = date ?? _today;
    final past = !_sameDay(day, _today);
    final list = mode == FakeMode.empty
        ? const <KidAttendance>[]
        : past
        ? _history()
        : kids;
    return AttendanceSheet(
      classSummary: ClassSummary(
        id: classId,
        name: FakeClassRosterSource.className,
        campusName: FakeClassRosterSource.campusName,
        childCount: list.length,
      ),
      date: day,
      today: _today,
      kids: list,
      lockAt: '08:30',
      locked: locked || past,
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
    lastSaved = kids;
  }
}
