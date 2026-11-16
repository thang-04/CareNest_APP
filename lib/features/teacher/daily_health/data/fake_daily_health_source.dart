import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả lớp Mầm 3A: bé có mặt theo màn Điểm danh; Lê Hoàng Nam đã ghi "Cần lưu ý" (ho, sốt nhẹ).
/// Một bản dùng chung để danh sách thấy lần ghi vừa lưu.
class FakeDailyHealthSource implements DailyHealthSource {
  FakeDailyHealthSource({
    this.mode = FakeMode.data,
    this.canRecord = true,
    this.failSave = false,
    this.delay = const Duration(milliseconds: 300),
  });

  static final shared = FakeDailyHealthSource();

  final FakeMode mode;
  final bool canRecord;
  final bool failSave;
  final Duration delay;

  late final Map<String, DailyHealthKid> _kids = {
    for (final kid in FakeAttendanceSource.kids)
      if (!kid.hasLeaveNotice)
        kid.childId: DailyHealthKid(
          childId: kid.childId,
          fullName: kid.fullName,
          entryCount: kid.childId == 'k-02' ? 1 : 0,
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
                )
              : null,
        ),
  };

  @override
  Future<DailyHealthSheet> loadSheet(String classId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    return DailyHealthSheet(
      classId: classId,
      className: FakeClassRosterSource.className,
      date: FakeParentHomeSource.today,
      canRecord: canRecord,
      kids: mode == FakeMode.empty ? const [] : _kids.values.toList(),
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
    );
    return entry;
  }
}
