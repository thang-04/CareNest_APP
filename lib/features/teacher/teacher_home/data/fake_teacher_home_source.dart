import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/teacher_home/domain/teacher_today.dart';

/// Dữ liệu giả mockup T01, khớp các màn: lớp Mầm 3A 28 bé, chưa điểm danh; ba việc thao tác
/// Điểm danh → Sức khỏe → Trả trẻ, sau đó các mục chỉ xem.
class FakeTeacherHomeSource implements TeacherHomeSource {
  FakeTeacherHomeSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final Duration delay;

  @override
  Future<TeacherToday> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final count = FakeClassRosterSource.kids.length;
    return TeacherToday(
      teacherName: 'Trần Thu Hà',
      date: FakeParentHomeSource.today,
      className: FakeClassRosterSource.className,
      childCount: count,
      currentActivity: '08:00 Tạo hình',
      deadlineNote: 'Hạn điểm danh: 08:30 · còn 47 phút',
      attendanceRecorded: mode == FakeMode.empty ? count : 0,
      tasks: mode == FakeMode.empty
          ? const []
          : [
              TeacherTask(
                kind: TeacherTaskKind.attendance,
                title: 'Điểm danh',
                subtitle: '0/$count bé · trước 08:30',
                badge: 'Cần làm',
                badgeLevel: TaskBadgeLevel.todo,
                highlighted: true,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.dailyHealth,
                title: 'Sức khỏe',
                subtitle: 'Đầu ngày · cân nặng · chiều cao',
                badge: 'Tiếp theo',
                badgeLevel: TaskBadgeLevel.info,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.pickup,
                title: 'Trả trẻ',
                // PCK-04: không có giờ đón cố định
                subtitle: 'Đối chiếu ảnh phụ huynh',
                badge: 'Cuối ngày',
                badgeLevel: TaskBadgeLevel.info,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.leave,
                title: 'Đơn xin nghỉ của lớp',
                subtitle: '2 đơn hôm nay',
                badge: 'Chỉ xem',
                badgeLevel: TaskBadgeLevel.fresh,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.review,
                title: 'Đánh giá trẻ',
                subtitle: 'Ngày · tuần · định kỳ',
                badge: 'Chỉ xem',
                badgeLevel: TaskBadgeLevel.info,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.menu,
                title: 'Thực đơn',
                subtitle: 'Các bữa hôm nay',
                badge: 'Đã công bố',
                badgeLevel: TaskBadgeLevel.info,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.rewards,
                title: 'Khen thưởng',
                subtitle: 'Phiếu bé ngoan · đề xuất',
                badge: 'Chỉ xem',
                badgeLevel: TaskBadgeLevel.info,
              ),
            ],
    );
  }
}
