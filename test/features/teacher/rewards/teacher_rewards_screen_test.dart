import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/teacher/rewards/data/fake_teacher_reward_source.dart';
import 'package:carenest_app/features/teacher/rewards/data/live_teacher_reward_source.dart';
import 'package:carenest_app/features/teacher/rewards/domain/teacher_rewards.dart';
import 'package:carenest_app/features/teacher/rewards/presentation/screens/teacher_rewards_screen.dart';

import '../../../helpers/live_fakes.dart';
import '../../../helpers/pump_app.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  usePhoneSize(tester);
  tester.view.physicalSize = const Size(360, 1600);
  await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
  await tester.pumpAndSettle();
}

void main() {
  final session = FakeLiveSession(['TEACHER']);

  test('loadBoard_mapsPeriodsRowsAndRules', () async {
    final api = ScriptedApi(session, {
      'GET /assessment/behaviour-tickets/board?classId=12&type=WEEKLY&periodStart=2026-10-05':
          (_) => {
            'cls': {'id': 12, 'name': 'Mầm 3A'},
            'periods': [
              {'start': '2026-10-05', 'end': '2026-10-09', 'weekNo': 6},
              {'start': '2026-09-28', 'end': '2026-10-02', 'weekNo': 5},
            ],
            'period': {'start': '2026-10-05', 'end': '2026-10-09', 'weekNo': 6},
            'rules': {'WEEK_MIN_FLAGS': 3},
            'rows': [
              {
                'child': {'id': 5, 'fullName': 'Nguyễn Minh Anh'},
                'presentDays': 5,
                'flagCount': 4,
                'eligible': true,
                'ticket': {'issuedAt': '2026-10-09T08:30:00Z'},
                'canIssue': true,
              },
              {
                'child': {'id': 6, 'fullName': 'Trần Bảo'},
                'presentDays': 3,
                'flagCount': 1,
                'eligible': false,
                'ticket': null,
                'canIssue': false,
              },
            ],
          },
    });
    final board = await LiveTeacherRewardSource(
      api,
    ).loadBoard('12', TicketKind.weekly, periodStart: DateTime(2026, 10, 5));
    expect(board.className, 'Mầm 3A');
    expect(board.periods.map((p) => p.weekNo), [6, 5]);
    expect(board.period?.start, DateTime(2026, 10, 5));
    expect(board.rules['WEEK_MIN_FLAGS'], 3);
    expect(board.rows[0].hasTicket, isTrue);
    expect(board.rows[0].issuedAt, isNotNull);
    expect(board.rows[1].canIssue, isFalse);
    expect(board.rows[1].eligible, isFalse);
  });

  test('loadBoard_noPeriodYet', () async {
    final api = ScriptedApi(session, {
      'GET /assessment/behaviour-tickets/board?classId=12&type=MONTHLY': (_) =>
          {
            'cls': {'id': 12, 'name': 'Mầm 3A'},
            'periods': <Object>[],
            'period': null,
            'rows': <Object>[],
          },
    });
    final board = await LiveTeacherRewardSource(
      api,
    ).loadBoard('12', TicketKind.monthly);
    expect(board.period, isNull);
  });

  test('loadSummaryAndClasses_mapBeFields', () async {
    final api = ScriptedApi(session, {
      'GET /assessment/behaviour-tickets/summary?classId=12&month=2026-09-01':
          (_) => {
            'cls': {'name': 'Mầm 3A'},
            'month': '2026-09-01',
            'months': ['2026-10-01', '2026-09-01'],
            'totals': {'weekly': 4, 'monthly': 1, 'children': 2, 'total': 20},
            'rows': [
              {
                'child': {'id': 5, 'fullName': 'A'},
                'weekly': 3,
                'monthly': 1,
                'flags': 9,
              },
            ],
          },
      'GET /assessment/reward-lists': (_) => [
        {
          'classId': 12,
          'className': 'Mầm 3A',
          'children': 20,
          'awarded': null,
          'status': 'PENDING_VP',
          'submittedAt': '2027-05-20T01:00:00Z',
        },
        {'classId': 13, 'className': 'Mầm 3B', 'children': 18, 'status': null},
      ],
    });
    final source = LiveTeacherRewardSource(api);
    final summary = await source.loadSummary('12', month: DateTime(2026, 9));
    expect(summary.month, DateTime(2026, 9));
    expect(summary.months.length, 2);
    expect(summary.children, 2);
    expect(summary.total, 20);
    expect(summary.rows.single.flags, 9);
    final rows = await source.loadClasses();
    expect(rows[0].status, RewardStatus.pendingVp);
    expect(rows[0].awarded, isNull);
    expect(rows[0].submittedAt, isNotNull);
    expect(rows[1].status, isNull);
  });

  testWidgets('phiếu bé ngoan: tất cả như bản gốc, Tuần theo kỳ BE', (
    tester,
  ) async {
    await _pump(
      tester,
      const TeacherRewardsScreen(source: FakeTeacherRewardSource()),
    );
    expect(find.text('Phiếu tuần'), findsOneWidget);
    expect(find.text('Phiếu tháng'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);

    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tuần 6'), findsOneWidget);
    expect(find.text('Đã phát'), findsWidgets);
    expect(find.text('Đủ điều kiện'), findsOneWidget);
    expect(find.text('Chưa đủ điều kiện'), findsOneWidget);
    expect(find.textContaining('Cờ bé ngoan 4 (cần 3)'), findsOneWidget);
    expect(find.textContaining('Phát phiếu'), findsNothing);

    await tester.tap(find.byTooltip('Tuần trước'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tuần 5'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Tuần trước'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Tháng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tháng 9/2026'), findsOneWidget);
    expect(find.textContaining('Bé ngoan trong tháng 3 (cần 3)'), findsWidgets);
  });

  testWidgets('đề xuất: trạng thái lớp và danh hiệu từng bé', (tester) async {
    await _pump(
      tester,
      const TeacherRewardsScreen(source: FakeTeacherRewardSource()),
    );
    await tester.tap(find.text('Đề xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chờ PHT xem xét'), findsOneWidget);
    expect(find.text('Có mặt 152/160 · Bé chăm ngoan'), findsOneWidget);
    expect(find.text('Có mặt 131/160 · Bé ngoan (gợi ý)'), findsOneWidget);
  });

  testWidgets('lỗi tải ⇒ có Thử lại; chưa có lớp ⇒ thông báo', (tester) async {
    await _pump(
      tester,
      TeacherRewardsScreen(key: UniqueKey(), source: _FailingSource()),
    );
    expect(find.text('Chưa tải được khen thưởng'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await _pump(tester, TeacherRewardsScreen(key: UniqueKey(), classId: ''));
    expect(find.text('Bạn chưa được phân công lớp'), findsOneWidget);
  });
}

class _FailingSource extends FakeTeacherRewardSource {
  @override
  Future<TeacherRewards> load(String classId) =>
      Future.error(Exception('mạng'));

  @override
  Future<TicketBoard> loadBoard(
    String classId,
    TicketKind kind, {
    DateTime? periodStart,
  }) => Future.error(Exception('mạng'));
}
