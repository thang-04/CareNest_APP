import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher_home/domain/teacher_today.dart';

/// Dữ liệu giả mockup T01, khớp các màn: lớp Mầm 3A 28 bé, chưa điểm danh, 2 đơn nghỉ mới,
/// đo sức khỏe 13/28, đón trẻ từ 16:30.
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
                title: 'Điểm danh & báo ăn',
                subtitle: '0/$count bé · trước 08:30',
                badge: 'Cần làm',
                badgeLevel: TaskBadgeLevel.todo,
                highlighted: true,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.leave,
                title: 'Đơn xin nghỉ',
                subtitle: '2 đơn mới · Minh Anh, Khánh Linh',
                badge: '2 mới',
                badgeLevel: TaskBadgeLevel.fresh,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.review,
                title: 'Đánh giá hằng ngày',
                subtitle: 'Hoạt động: Tô màu chiếc lá',
                badge: 'Cuối ngày',
                badgeLevel: TaskBadgeLevel.info,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.mealPhotos,
                title: 'Ảnh bữa ăn',
                subtitle: 'Bữa sáng đã gửi · bữa trưa chưa chụp',
                badge: 'Bữa trưa',
                badgeLevel: TaskBadgeLevel.info,
              ),
              const TeacherTask(
                kind: TeacherTaskKind.pickup,
                title: 'Đón trẻ',
                subtitle: 'Từ 16:30 · xác minh người đón',
                badge: '16:30',
                badgeLevel: TaskBadgeLevel.info,
              ),
              TeacherTask(
                kind: TeacherTaskKind.health,
                title: 'Đo sức khỏe tháng 10',
                subtitle: 'Chiều cao, cân nặng · 13/$count bé',
                badge: 'Còn ${count - 13}',
                badgeLevel: TaskBadgeLevel.info,
              ),
            ],
    );
  }
}
