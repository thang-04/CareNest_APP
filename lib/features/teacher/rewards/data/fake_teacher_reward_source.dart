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

  static final _periods = [
    TicketPeriod(
      start: DateTime(2026, 10, 5),
      end: DateTime(2026, 10, 9),
      weekNo: 6,
    ),
    TicketPeriod(
      start: DateTime(2026, 9, 28),
      end: DateTime(2026, 10, 2),
      weekNo: 5,
    ),
  ];

  @override
  Future<TicketBoard> loadBoard(
    String classId,
    TicketKind kind, {
    DateTime? periodStart,
  }) async {
    final periods = kind == TicketKind.weekly
        ? _periods
        : [TicketPeriod(start: DateTime(2026, 9), end: DateTime(2026, 9, 30))];
    return TicketBoard(
      className: FakeClassRosterSource.className,
      kind: kind,
      periods: periods,
      period: periods.firstWhere(
        (p) => p.start == periodStart,
        orElse: () => periods.first,
      ),
      rules: const {'WEEK_MIN_FLAGS': 3, 'MONTH_MIN_WEEKLY_TICKETS': 3},
      rows: [
        TicketBoardRow(
          childId: 'child-1',
          fullName: 'Nguyễn Minh Anh',
          presentDays: 5,
          flagCount: 4,
          weeklyTickets: 3,
          eligible: true,
          hasTicket: true,
          issuedAt: DateTime(2026, 10, 9, 15, 30),
        ),
        const TicketBoardRow(
          childId: 'k-02',
          fullName: 'Lê Hoàng Nam',
          presentDays: 5,
          flagCount: 3,
          weeklyTickets: 3,
          eligible: true,
        ),
        const TicketBoardRow(
          childId: 'k-07',
          fullName: 'Phan Gia Huy',
          presentDays: 4,
          flagCount: 1,
          weeklyTickets: 1,
          eligible: false,
        ),
      ],
    );
  }

  @override
  Future<TicketSummary> loadSummary(String classId, {DateTime? month}) async =>
      TicketSummary(
        className: FakeClassRosterSource.className,
        month: month,
        months: [DateTime(2026, 9)],
        weekly: 5,
        monthly: 1,
        children: 2,
        total: 4,
        rows: const [
          TicketSummaryRow(
            childId: 'child-1',
            fullName: 'Nguyễn Minh Anh',
            weekly: 4,
            monthly: 1,
            flags: 12,
          ),
          TicketSummaryRow(
            childId: 'k-02',
            fullName: 'Lê Hoàng Nam',
            weekly: 1,
            monthly: 0,
            flags: 5,
          ),
        ],
      );

  @override
  Future<List<RewardClassRow>> loadClasses() async => [
    RewardClassRow(
      classId: FakeClassRosterSource.classId,
      className: FakeClassRosterSource.className,
      children: 18,
      status: RewardStatus.pendingVp,
      awarded: 6,
      submittedAt: DateTime(2027, 5, 20),
    ),
  ];
}
