import 'package:carenest_app/features/my_child/domain/my_child.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả theo mockup P08–P13, không phải dữ liệu thật của trẻ (AGENTS.md nguyên tắc 4).
/// Khớp nhau giữa các màn: có mặt 07:42 ngày 12/10, ăn hết bữa trưa, đơn nghỉ 13/10 GV chưa xem,
/// tháng 10 có 8 ngày có mặt + 1 ngày nghỉ có phép (13/10, suất đã huỷ).
class FakeMyChildSource implements MyChildSource {
  const FakeMyChildSource();

  static DateTime _at(int day, int hour, int minute) =>
      DateTime(2026, 10, day, hour, minute);

  static String _teacherFull(String childId) =>
      childId == 'child-2' ? 'Cô Vũ Minh Thư' : 'Cô Trần Thu Hà';

  static DailyReview _review(String childId) => DailyReview(
    teacher: _teacherFull(childId),
    tags: const [
      ReviewTag(criterion: ReviewCriterion.health, label: 'Sức khỏe: Tốt'),
      ReviewTag(criterion: ReviewCriterion.emotion, label: 'Cảm xúc: Vui vẻ'),
      ReviewTag(criterion: ReviewCriterion.learning, label: 'Học tập: Đạt'),
      ReviewTag(criterion: ReviewCriterion.behavior, label: 'Hành vi tốt'),
    ],
    note:
        'Bé hào hứng tô màu, tự xếp đồ dùng gọn gàng. Cần nhắc bé uống thêm nước.',
  );

  @override
  Future<ChildToday> loadToday(String childId) async => ChildToday(
    date: FakeParentHomeSource.today,
    events: [
      DayEvent(
        time: _at(12, 7, 42),
        kind: DayEventKind.attendance,
        label: 'Điểm danh – Có mặt',
      ),
      DayEvent(
        time: _at(12, 10, 45),
        kind: DayEventKind.meal,
        label: 'Bữa trưa – Ăn hết suất',
      ),
      DayEvent(
        time: _at(12, 15, 30),
        kind: DayEventKind.activity,
        label: 'Hoạt động – Tô màu chiếc lá',
      ),
      DayEvent(
        time: _at(12, 16, 45),
        kind: DayEventKind.pickup,
        label: 'Đón về – Mẹ đón bé',
      ),
    ],
    review: _review(childId),
    upcomingLeave: const LeaveSummary(
      title: 'Đơn xin nghỉ 13/10',
      detail: 'Suất ăn 13/10 đã huỷ',
      seenByTeacher: false,
    ),
  );

  @override
  Future<HealthSummary> loadHealth(String childId) async => HealthSummary(
    measuredOn: DateTime(2026, 10, 12),
    height: '104 cm',
    weight: '17,2 kg',
    nutritionLabel: 'Bình thường',
    weightTrend: const [
      WeightPoint('T6', 15.9),
      WeightPoint('T7', 16.3),
      WeightPoint('T8', 16.6),
      WeightPoint('T9', 16.8),
      WeightPoint('T10', 17.2),
    ],
    dietLine: childId == 'child-2'
        ? 'Dị ứng hải sản · ăn suất thay thế'
        : 'Không có dị ứng · ăn suất thường',
  );

  @override
  Future<DevelopmentSummary> loadDevelopment(
    String childId,
  ) async => DevelopmentSummary(
    weekRange: '05/10 – 09/10',
    weekNote:
        'Bé mạnh dạn phát biểu, biết chia sẻ đồ chơi với bạn. Cần luyện thêm kỹ năng cầm bút.',
    weekAuthor: '${_teacherFull(childId)} · 09/10/2026',
    weekConfirmed: true,
    monthlyTitle: 'Nhận xét tháng 9/2026',
    flagMonth: 'Tháng 10',
    flagsEarned: 2,
    flagsNeeded: 3,
    flagSlots: 4,
    yearEndNote: 'Kết quả hiển thị sau khi Ban giám hiệu phê duyệt.',
  );

  @override
  Future<ActivityDay> loadActivities(String childId) async => ActivityDay(
    date: FakeParentHomeSource.today,
    review: _review(childId),
    entries: [
      ActivityEntry(
        time: _at(12, 7, 42),
        title: 'Đón trẻ',
        detail: 'Mẹ đưa bé đến lớp',
      ),
      ActivityEntry(
        time: _at(12, 8, 30),
        title: 'Thể dục sáng',
        detail: 'Bé tham gia tích cực',
      ),
      ActivityEntry(
        time: _at(12, 9, 15),
        title: 'Tạo hình',
        detail: 'Tô màu chiếc lá mùa thu · 4 ảnh',
        isCurrent: true,
      ),
      ActivityEntry(
        time: _at(12, 10, 45),
        title: 'Ăn trưa',
        detail: 'Ăn hết suất · cơm, canh bí đỏ, cá',
      ),
      ActivityEntry(
        time: _at(12, 12, 0),
        title: 'Ngủ trưa',
        detail: 'Ngủ ngon khoảng 2 giờ',
      ),
    ],
    photoTitle: 'Tạo hình',
    photoCount: 4,
  );

  @override
  Future<AttendanceMonth> loadAttendance(String childId) async {
    AttendanceDay present(int day, int arriveMinute) => AttendanceDay(
      date: DateTime(2026, 10, day),
      status: AttendanceDayStatus.present,
      arrivedAt: _at(day, 7, arriveMinute),
      mealsLine: 'đã ăn sáng · trưa · chiều',
      pickupLine: '16:45 · Mẹ',
    );
    return AttendanceMonth(
      month: DateTime(2026, 10),
      presentCount: 8,
      excusedCount: 1,
      absentCount: 0,
      cancelledMealCount: 1,
      days: [
        present(1, 50),
        present(2, 45),
        present(5, 40),
        present(6, 52),
        present(7, 38),
        present(8, 47),
        present(9, 41),
        present(12, 42),
        AttendanceDay(
          date: DateTime(2026, 10, 13),
          status: AttendanceDayStatus.excused,
          mealCancelled: true,
        ),
      ],
    );
  }

  @override
  Future<ChildProfile> loadProfile(String childId) async {
    final child = FakeParentHomeSource.childById(childId);
    final second = childId == 'child-2';
    return ChildProfile(
      fullName: child.fullName,
      classLine: 'Lớp ${child.className} · Năm học 2026–2027',
      birthDate: second ? '02/08/2021 (5 tuổi)' : '14/03/2022 (4 tuổi)',
      gender: 'Nữ',
      campus: child.campusName,
      teachers: second ? 'Cô Vũ Minh Thư' : 'Cô Trần Thu Hà · Cô Lê Mai',
      healthLine: second
          ? 'Dị ứng: Hải sản · Chế độ ăn: Suất thay thế'
          : 'Dị ứng: Không · Chế độ ăn: Bình thường',
      guardians: const [
        Guardian(relation: 'Mẹ', name: 'Thu Lan', phone: '0912 345 678'),
        Guardian(relation: 'Bố', name: 'Văn Hùng', phone: '0987 654 321'),
      ],
    );
  }
}
