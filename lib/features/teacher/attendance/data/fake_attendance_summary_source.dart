import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance_summary.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';

/// Tổng hợp giả lớp Mầm 3A: 3 ngày học gần nhất, 2 trẻ.
class FakeAttendanceSummarySource implements AttendanceSummarySource {
  FakeAttendanceSummarySource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  /// Khoảng đã yêu cầu ở lần tải gần nhất (để test kiểm tra tham số).
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Future<AttendanceSummary> load(
    String classId, {
    DateTime? from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(delay);
    lastFrom = from;
    lastTo = to;
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final end = to ?? FakeParentHomeSource.today;
    final start = from ?? DateTime(end.year, end.month);
    return AttendanceSummary(
      className: FakeClassRosterSource.className,
      from: start,
      to: end,
      size: 28,
      mealSessions: MealSession.values,
      days: mode == FakeMode.empty
          ? const []
          : [
              for (var i = 2; i >= 0; i--)
                AttendanceSummaryDay(
                  date: DateTime(end.year, end.month, end.day - i),
                  present: 24 - i,
                  excused: 2,
                  unexcused: i,
                  missing: 2 - i,
                  mealTotal: 23 - i,
                  meals: {
                    MealSession.morning: 22 - i,
                    MealSession.lunch: 23 - i,
                    MealSession.afternoon: 21,
                  },
                  morningOff: i == 0 ? 1 : 0,
                ),
            ],
      children: mode == FakeMode.empty
          ? const []
          : const [
              AttendanceSummaryChild(
                childId: 'child-1',
                fullName: 'Nguyễn Minh Anh',
                attendedDays: 3,
                mealDays: 3,
                mealCounts: {
                  MealSession.morning: 3,
                  MealSession.lunch: 3,
                  MealSession.afternoon: 2,
                },
              ),
              AttendanceSummaryChild(
                childId: 'k-03',
                fullName: 'Phạm Khánh Linh',
                attendedDays: 1.5,
                excused: 1,
                unexcused: 1,
                mealDays: 1,
                mealCounts: {MealSession.lunch: 1},
                morningOff: 1,
              ),
            ],
    );
  }
}
