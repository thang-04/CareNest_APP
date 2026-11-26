import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả theo mockup P08–P10 và hồ sơ của bé, không phải dữ liệu thật của trẻ
/// (AGENTS.md nguyên tắc 4).
/// Khớp nhau giữa các màn: có mặt 07:42 ngày 12/10, ăn hết bữa trưa, đơn nghỉ 13/10 GV chưa xem,
/// tháng 10 có 8 ngày có mặt + 1 ngày nghỉ có phép (13/10, suất đã huỷ).
class FakeMyChildSource implements MyChildSource {
  const FakeMyChildSource();

  static DateTime _at(int day, int hour, int minute) =>
      DateTime(2026, 10, day, hour, minute);

  /// Giáo án ngày giả (thứ Hai 12/10): mỗi dòng của bảng tuần và hoạt động của ngày.
  @override
  Future<ActivityDay> loadActivities(String childId, {DateTime? date}) async =>
      ActivityDay(
        date: date ?? FakeParentHomeSource.today,
        groups: const [
          ActivityGroup(label: 'Đón trẻ', items: ['Trò chuyện về mùa thu']),
          ActivityGroup(label: 'Thể dục sáng', items: ['Bài tập với nơ']),
          ActivityGroup(
            label: 'Hoạt động học',
            items: ['Tạo hình: Tô màu chiếc lá mùa thu'],
          ),
          ActivityGroup(
            label: 'Chơi ngoài trời',
            items: ['Quan sát cây bàng', 'Trò chơi: Mèo đuổi chuột'],
          ),
          ActivityGroup(label: 'Hoạt động chiều', items: ['Ôn bài hát']),
        ],
      );

  @override
  Future<List<ChildTeacher>> loadTeachers(String childId) async =>
      childId == 'child-2'
      ? const [
          ChildTeacher(
            fullName: 'Cô Vũ Minh Thư',
            homeroom: true,
            phone: '0912000002',
          ),
        ]
      : const [
          ChildTeacher(
            fullName: 'Cô Trần Thu Hà',
            homeroom: true,
            phone: '0912000001',
          ),
          ChildTeacher(fullName: 'Cô Lê Mai', homeroom: false),
        ];

  @override
  Future<AttendanceMonth> loadAttendance(
    String childId, {
    ChildSchoolYear? year,
  }) async {
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

  /// Hồ sơ của bé; khai báo sức khỏe theo các trạng thái BE trả (CHD-06).
  @override
  Future<ChildProfile> loadProfile(String childId) async {
    final child = FakeParentHomeSource.childById(childId);
    final second = childId == 'child-2';
    return ChildProfile(
      fullName: child.fullName,
      className: child.className,
      ageLabel: child.ageLabel,
      schoolYear: '2026–2027',
      birthDate: second ? '02/08/2021 (5 tuổi)' : '14/03/2022 (4 tuổi)',
      gender: 'Nữ',
      campus: child.campusName,
      health: second
          ? const DeclaredHealth(
              allergyState: DeclarationState.reported,
              allergies: ['Hải sản'],
              diet: DeclaredItem.reported('Suất thay thế'),
              selfHistory: DeclaredItem.reported('Hen phế quản'),
              familyHistory: DeclaredItem.noneReported(),
            )
          : const DeclaredHealth(
              allergyState: DeclarationState.noneReported,
              diet: DeclaredItem.noneReported(),
              selfHistory: DeclaredItem.noneReported(),
              familyHistory: DeclaredItem.reported('Tăng huyết áp'),
            ),
      guardians: const [
        Guardian(relation: 'Mẹ', name: 'Thu Lan', phone: '0912 345 678'),
        Guardian(relation: 'Bố', name: 'Văn Hùng', phone: '0987 654 321'),
      ],
    );
  }
}
