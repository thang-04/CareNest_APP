import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';

/// Dữ liệu giả lớp Mầm 3A: bé có mặt theo màn Điểm danh; Lê Hoàng Nam đã ghi "Có dấu hiệu" (ho, sốt nhẹ).
/// Một bản dùng chung để danh sách thấy lần ghi vừa lưu.
class FakeDailyHealthSource implements DailyHealthSource {
  FakeDailyHealthSource({
    this.mode = FakeMode.data,
    this.canRecord = true,
    this.failSave = false,
    this.failHistory = false,
    this.delay = const Duration(milliseconds: 300),
  });

  static final shared = FakeDailyHealthSource();

  final FakeMode mode;
  final bool canRecord;
  final bool failSave;
  final bool failHistory;
  final Duration delay;

  /// Ngày đã yêu cầu ở lần tải gần nhất (để test kiểm tra tham số).
  DateTime? lastRequestedDate;

  late final Map<String, DailyHealthKid> _kids = {
    for (final kid in FakeAttendanceSource.kids)
      if (!kid.hasLeaveNotice)
        kid.childId: DailyHealthKid(
          childId: kid.childId,
          fullName: kid.fullName,
          entryCount: kid.childId == 'k-02' ? 1 : 0,
          // Bé về sớm do sức khỏe, đã trả lúc 10:15 ⇒ khóa ghi thêm
          handedOverAt: kid.childId == 'k-20'
              ? DateTime(2026, 10, 12, 10, 15)
              : null,
          latest: kid.childId == 'k-02'
              ? DailyHealthEntry(
                  requestId: 'req-k02-1',
                  classId: FakeClassRosterSource.classId,
                  childId: 'k-02',
                  date: FakeParentHomeSource.today,
                  temperature: 37.8,
                  observation: HealthObservation.noted,
                  symptoms: const [HealthSymptom.cough, HealthSymptom.fever],
                  actions: const [
                    HealthAction.monitor,
                    HealthAction.parentInformed,
                  ],
                  note: 'Ho nhẹ khi đến lớp',
                  recordedAt: DateTime(2026, 10, 12, 7, 50),
                  recordedByName: 'Cô Lan',
                )
              : null,
        ),
  };

  static bool _isToday(DateTime? date) {
    final today = FakeParentHomeSource.today;
    return date == null ||
        (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day);
  }

  @override
  Future<DailyHealthSheet> loadSheet(String classId, {DateTime? date}) async {
    await Future<void>.delayed(delay);
    lastRequestedDate = date;
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    return DailyHealthSheet(
      classId: classId,
      className: FakeClassRosterSource.className,
      date: date ?? FakeParentHomeSource.today,
      // Ngày đã qua: BE trả chỉ xem
      canRecord: canRecord && _isToday(date),
      kids: mode == FakeMode.empty ? const [] : _kids.values.toList(),
    );
  }

  @override
  Future<DailyHealthChildDay> loadChildDay(
    String classId,
    String childId, {
    DateTime? date,
  }) async {
    await Future<void>.delayed(delay);
    if (failHistory) throw StateError('Không tải được lịch sử giả');
    final kid = _kids[childId]!;
    return DailyHealthChildDay(
      entries: [?kid.latest],
      canRecord: canRecord && _isToday(date) && !kid.pickedUp,
      handedOverAt: kid.handedOverAt,
    );
  }

  @override
  Future<DailyHealthEntry> save(DailyHealthEntry entry) async {
    await Future<void>.delayed(delay);
    if (failSave) throw StateError('Không lưu được (giả lập mất mạng)');
    final kid = _kids[entry.childId]!;
    _kids[entry.childId] = DailyHealthKid(
      childId: kid.childId,
      fullName: kid.fullName,
      latest: entry,
      entryCount: kid.entryCount + 1,
      handedOverAt: kid.handedOverAt,
    );
    return entry;
  }
}
