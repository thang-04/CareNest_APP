import 'package:carenest_app/features/parent_home/domain/parent_today.dart';

/// Nguồn dữ liệu màn Phụ huynh · Trang chủ; bản thật gọi API phụ huynh (chưa có endpoint).
abstract interface class ParentHomeSource {
  Future<List<ChildSummary>> loadChildren();
  Future<ParentToday> loadToday(String childId);
}

enum FakeMode { data, empty, error }

/// Dữ liệu giả theo mockup, không phải dữ liệu thật của trẻ (AGENTS.md nguyên tắc 4).
/// Khớp các màn khác: bé Minh Anh, lớp Mầm 3A, cô Hà, có mặt 07:42, đơn nghỉ 13/10.
class FakeParentHomeSource implements ParentHomeSource {
  FakeParentHomeSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final Duration delay;

  static final today = DateTime(2026, 10, 12);
  static const parentName = 'Chị Nguyễn Thu Lan';

  static const children = [
    ChildSummary(
      id: 'child-1',
      fullName: 'Nguyễn Minh Anh',
      shortName: 'Minh Anh',
      className: 'Mầm 3A',
      campusName: 'Cơ sở chính – Thượng Hồng',
      ageLabel: '4 tuổi',
      homeroomTeacher: 'Cô Hà',
    ),
    ChildSummary(
      id: 'child-2',
      fullName: 'Nguyễn Hoàng Bảo Ngọc',
      shortName: 'Bảo Ngọc',
      className: 'Lá 1',
      campusName: 'Cơ sở 2 – An Đồng',
      ageLabel: '5 tuổi',
      homeroomTeacher: 'Cô Thư',
    ),
  ];

  static ChildSummary childById(String id) =>
      children.firstWhere((child) => child.id == id);

  @override
  Future<List<ChildSummary>> loadChildren() async {
    await Future<void>.delayed(delay);
    return children;
  }

  @override
  Future<ParentToday> loadToday(String childId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) {
      throw StateError('Không tải được dữ liệu giả');
    }
    final child = childById(childId);
    if (mode == FakeMode.empty) {
      return ParentToday(
        greetingName: parentName,
        date: today,
        child: child,
        attendance: ParentAttendanceStatus.notRecorded,
        unreadNotifications: 0,
      );
    }
    return ParentToday(
      greetingName: parentName,
      date: today,
      child: child,
      attendance: ParentAttendanceStatus.present,
      arrivedAt: DateTime(2026, 10, 12, 7, 42),
      unreadNotifications: 2,
      menuPublished: true,
      activityTitle: 'Tô màu chiếc lá mùa thu',
    );
  }
}
