import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/rewards/domain/teacher_rewards.dart';

/// Dữ liệu giả dạng BE `RewardClassDetail`; danh hiệu theo OBS-14 (Web `REWARD_GENERAL_TITLES`).
class FakeTeacherRewardSource implements TeacherRewardSource {
  const FakeTeacherRewardSource();

  static const shared = FakeTeacherRewardSource();

  static const titleOptions = [
    'Bé ngoan',
    'Bé chăm ngoan',
    'Bé khỏe, bé ngoan',
    'Bé chăm ngoan xuất sắc',
    'Cháu ngoan Bác Hồ',
  ];

  @override
  Future<TeacherRewards> load(String classId) async => const TeacherRewards(
    className: FakeClassRosterSource.className,
    schoolYearLabel: 'Năm học 2026–2027',
    status: RewardStatus.draft,
    titleOptions: titleOptions,
    children: [
      TeacherRewardChild(
        childId: 'child-1',
        fullName: 'Nguyễn Minh Anh',
        schoolDays: 160,
        presentDays: 152,
        weeklyTickets: 28,
        monthlyTickets: 8,
        suggested: ['Bé chăm ngoan'],
        titles: ['Bé chăm ngoan'],
        note: 'Đi học đều, tích cực trong hoạt động lớp.',
      ),
      TeacherRewardChild(
        childId: 'k-02',
        fullName: 'Lê Hoàng Nam',
        schoolDays: 160,
        presentDays: 131,
        weeklyTickets: 15,
        monthlyTickets: 3,
        suggested: ['Bé ngoan'],
      ),
      TeacherRewardChild(
        childId: 'k-05',
        fullName: 'Đỗ Tuấn Kiệt',
        schoolDays: 160,
        presentDays: 158,
        weeklyTickets: 32,
        monthlyTickets: 9,
        suggested: ['Bé chăm ngoan xuất sắc'],
        titles: ['Bé chăm ngoan xuất sắc', 'Cháu ngoan Bác Hồ'],
      ),
      TeacherRewardChild(
        childId: 'k-07',
        fullName: 'Phan Gia Huy',
        schoolDays: 160,
        presentDays: 120,
        weeklyTickets: 6,
        monthlyTickets: 0,
      ),
    ],
  );
}
