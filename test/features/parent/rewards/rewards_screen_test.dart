import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/rewards/data/fake_reward_source.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';
import 'package:carenest_app/features/parent/rewards/presentation/screens/rewards_screen.dart';

import '../../../helpers/pump_app.dart';

/// Nguồn cố định cho trạng thái dữ liệu giả chưa có (phiếu đã phát ở kỳ mới nhất, ngưỡng khác).
class _BookSource implements RewardSource {
  const _BookSource(this.book);

  final RewardBook book;

  @override
  Future<RewardBook> load(String childId) async => book;
}

/// Sổ khen thưởng như BE phụ huynh trả (25/11): không ngưỡng, tên năm học, ngày duyệt, tổng năm.
final _liveShapeBook = RewardBook(
  weeks: [
    RewardWeek(
      from: DateTime(2026, 11, 23),
      to: DateTime(2026, 11, 27),
      flags: 2,
      ongoing: true,
      days: [
        FlagDay(date: DateTime(2026, 11, 23), status: FlagDayStatus.flagged),
        FlagDay(date: DateTime(2026, 11, 24), status: FlagDayStatus.flagged),
      ],
    ),
  ],
  months: [RewardMonth(month: DateTime(2026, 11), weeklyTickets: 1)],
  yearEnd: const YearEndReward(
    titles: ['Bé chăm ngoan'],
    teacherNote: 'Con rất lễ phép.',
  ),
);

class _Opened {
  var daily = 0;
}

Future<_Opened> _pumpRewards(
  WidgetTester tester, {
  String childId = 'child-1',
  double textScale = 1,
  RewardsTab tab = RewardsTab.week,
  RewardSource source = const FakeRewardSource(delay: Duration.zero),
}) async {
  final opened = _Opened();
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      // Khóa mới mỗi lần bơm ⇒ tải lại theo nguồn mới, không giữ state lần trước
      home: RewardsScreen(
        key: UniqueKey(),
        child: FakeParentHomeSource.childById(childId),
        initialTab: tab,
        source: source,
        onOpenDailyEvaluation: () => opened.daily++,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Khen thưởng: 3 mục; mục Tuần có cờ từng ngày và câu ngưỡng', (
    tester,
  ) async {
    await _pumpRewards(tester);
    expect(find.text('Khen thưởng'), findsOneWidget);
    for (final tab in ['Tuần', 'Tháng', 'Cuối năm']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    expect(find.text('TUẦN NÀY'), findsOneWidget);
    expect(find.text('24/05 – 28/05'), findsOneWidget);
    expect(find.bySemanticsLabel('3 cờ trong tuần'), findsOneWidget);
    expect(find.bySemanticsLabel('Thứ Hai, 24/05: có cờ'), findsOneWidget);
    expect(find.bySemanticsLabel('Thứ Tư, 26/05: không có cờ'), findsOneWidget);
    expect(find.bySemanticsLabel('Thứ Năm, 27/05: nghỉ'), findsOneWidget);
    expect(find.text('Nghỉ'), findsOneWidget);
    expect(
      find.text('Từ 3 cờ trong tuần, cô xét phiếu Bé ngoan khi hết tuần.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Mục Tuần: các tuần trước nhóm theo tháng; "Xem các tuần trước" mở tháng cũ',
    (tester) async {
      await _pumpRewards(tester);
      expect(find.text('Các tuần trước'), findsOneWidget);
      expect(find.text('Tháng 5/2027'), findsOneWidget);
      expect(find.text('Tháng 4/2027'), findsOneWidget);
      expect(find.text('Tháng 3/2027'), findsNothing);
      // Tháng 5: 2 tuần có phiếu; tháng 4: 3 tuần
      expect(find.text('Bé ngoan'), findsNWidgets(5));

      await tester.scrollUntilVisible(find.text('10/05 – 14/05'), 200);
      expect(find.text('2 cờ'), findsWidgets);
      expect(find.bySemanticsLabel('Có phiếu Bé ngoan'), findsWidgets);

      await _tapVisible(tester, find.text('Xem các tuần trước'));
      expect(find.text('Tháng 3/2027'), findsOneWidget);
      expect(find.text('01/03 – 05/03'), findsOneWidget);
      expect(find.text('Xem các tuần trước'), findsNothing);
    },
  );

  testWidgets('rewards_live_hidesRulesAndGuide', (tester) async {
    await _pumpRewards(tester, source: _BookSource(_liveShapeBook));
    // Q2 (user 25/11): BE chưa trả ngưỡng ⇒ ẩn câu quy tắc và nút giải thích
    expect(find.textContaining('cô xét phiếu'), findsNothing);
    expect(find.byTooltip('Cách bé nhận khen thưởng'), findsNothing);
    expect(find.textContaining('null'), findsNothing);

    await _tapVisible(tester, find.text('Tháng'));
    expect(find.textContaining('cô xét phiếu'), findsNothing);
  });

  testWidgets('rewards_live_yearEnd_hidesYearAndApproval', (tester) async {
    await _pumpRewards(
      tester,
      tab: RewardsTab.yearEnd,
      source: _BookSource(_liveShapeBook),
    );
    expect(find.text('Bé chăm ngoan'), findsOneWidget);
    expect(find.text('Con rất lễ phép.'), findsOneWidget);
    expect(find.textContaining('NĂM HỌC'), findsNothing);
    expect(find.textContaining('Hiệu trưởng duyệt ngày'), findsNothing);
  });

  testWidgets('"Xem đánh giá từng ngày" mở trang Đánh giá', (tester) async {
    final opened = await _pumpRewards(tester);
    await _tapVisible(tester, find.text('Xem đánh giá từng ngày'));
    expect(opened.daily, 1);
  });

  testWidgets('Mục Tháng: ô phiếu từng tuần, câu ngưỡng, các tháng trước', (
    tester,
  ) async {
    await _pumpRewards(tester, tab: RewardsTab.month);
    expect(find.text('THÁNG NÀY'), findsOneWidget);
    expect(find.text('Tháng 5/2027'), findsOneWidget);
    expect(
      find.bySemanticsLabel('2 phiếu Bé ngoan trong tháng'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Tuần 03/05: có phiếu Bé ngoan'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Tuần 17/05: không có phiếu'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tuần 24/05: tuần đang diễn ra'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Từ 3 phiếu Bé ngoan trong tháng, cô xét phiếu Bé ngoan toàn diện '
        'khi hết tháng.',
      ),
      findsOneWidget,
    );
    expect(find.text('Các tháng trước'), findsOneWidget);
    expect(find.text('Tháng 9/2026'), findsOneWidget);
    // Tháng 2/2027 và 10/2026
    expect(find.text('2 phiếu Bé ngoan'), findsNWidgets(2));
    // Tháng 4, 3, 1/2027, 12, 11/2026
    expect(find.text('Bé ngoan toàn diện'), findsNWidgets(5));
  });

  testWidgets('Mục Cuối năm: danh hiệu, Lời cô, ngày duyệt, tổng cả năm', (
    tester,
  ) async {
    await _pumpRewards(tester, tab: RewardsTab.yearEnd);
    expect(find.text('NĂM HỌC 2026–2027'), findsOneWidget);
    expect(find.text('Danh hiệu của bé'), findsOneWidget);
    expect(find.text('Bé chăm ngoan xuất sắc'), findsOneWidget);
    expect(find.text('Cháu ngoan Bác Hồ'), findsOneWidget);
    expect(find.text('Lời cô'), findsOneWidget);
    expect(find.textContaining('mạnh dạn phát biểu'), findsOneWidget);
    expect(find.text('Hiệu trưởng duyệt ngày 28/05/2027'), findsOneWidget);
    expect(find.text('Cả năm học'), findsOneWidget);
    expect(find.text('Đến 28/05/2027'), findsOneWidget);
    for (final value in ['92', '24', '5']) {
      expect(find.text(value), findsOneWidget, reason: value);
    }

    await _pumpRewards(tester, childId: 'child-2', tab: RewardsTab.yearEnd);
    expect(find.text('Nguyễn Hoàng Bảo Ngọc'), findsOneWidget);
    expect(
      find.text('Hoàn thành tốt chương trình giáo dục mầm non'),
      findsOneWidget,
    );
  });

  testWidgets('Nút ? giải thích cách nhận với ngưỡng BE trả; "Đã hiểu" đóng', (
    tester,
  ) async {
    final book = RewardBook(
      schoolYear: '2026–2027',
      rules: const RewardRules(weekMinFlags: 4, monthMinWeeklyTickets: 2),
      weeks: [
        RewardWeek(
          from: DateTime(2027, 5, 24),
          to: DateTime(2027, 5, 28),
          flags: 1,
          ongoing: true,
        ),
      ],
    );
    await _pumpRewards(tester, source: _BookSource(book));
    expect(
      find.text('Từ 4 cờ trong tuần, cô xét phiếu Bé ngoan khi hết tuần.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Cách bé nhận khen thưởng'));
    await tester.pumpAndSettle();
    expect(find.text('Cách bé nhận khen thưởng'), findsOneWidget);
    expect(
      find.text('Bé có từ 4 cờ trong tuần được cô xét phiếu khi hết tuần.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Bé có từ 2 phiếu Bé ngoan trong tháng được cô xét phiếu khi hết '
        'tháng.',
      ),
      findsOneWidget,
    );
    expect(find.text('Danh hiệu cuối năm'), findsOneWidget);

    await _tapVisible(tester, find.text('Đã hiểu'));
    expect(find.text('Đã hiểu'), findsNothing);
  });

  testWidgets(
    'Kỳ đã kết thúc có phiếu; danh sách đã duyệt mà bé không có danh hiệu',
    (tester) async {
      const teacher = 'Cô Trần Thu Hà';
      final book = RewardBook(
        schoolYear: '2026–2027',
        rules: const RewardRules(weekMinFlags: 3, monthMinWeeklyTickets: 3),
        weeks: [
          RewardWeek(
            from: DateTime(2027, 5, 24),
            to: DateTime(2027, 5, 28),
            flags: 3,
            ticket: IssuedTicket(
              issuedBy: teacher,
              issuedAt: DateTime(2027, 5, 31),
            ),
          ),
        ],
        months: [
          RewardMonth(
            month: DateTime(2027, 4),
            weeklyTickets: 3,
            ticket: IssuedTicket(
              issuedBy: teacher,
              issuedAt: DateTime(2027, 5, 3),
            ),
          ),
        ],
        yearEnd: YearEndReward(
          titles: const [],
          approvedAt: DateTime(2027, 5, 28),
          teacherNote: 'Con lễ phép, chăm tập thể dục buổi sáng.',
        ),
      );
      await _pumpRewards(tester, source: _BookSource(book));
      expect(find.text('TUẦN VỪA QUA'), findsOneWidget);
      expect(find.text('Bé nhận phiếu Bé ngoan'), findsOneWidget);
      expect(find.text('$teacher phát · 31/05/2027'), findsOneWidget);
      expect(find.text('Các tuần trước'), findsNothing);

      await _tapVisible(tester, find.text('Tháng'));
      expect(find.text('THÁNG VỪA QUA'), findsOneWidget);
      expect(find.text('Bé nhận phiếu Bé ngoan toàn diện'), findsOneWidget);
      expect(find.text('$teacher phát · 03/05/2027'), findsOneWidget);

      await _tapVisible(tester, find.text('Cuối năm'));
      expect(find.text('Năm học này bé chưa có danh hiệu'), findsOneWidget);
      expect(find.text('Danh hiệu của bé'), findsNothing);
      expect(find.text('Lời cô'), findsOneWidget);
      expect(find.text('Hiệu trưởng duyệt ngày 28/05/2027'), findsOneWidget);
      expect(find.text('Cả năm học'), findsNothing);
    },
  );

  testWidgets('Lỗi tải có "Thử lại"; chưa có dữ liệu thì mỗi mục báo trống', (
    tester,
  ) async {
    await _pumpRewards(
      tester,
      source: const FakeRewardSource(
        mode: FakeMode.error,
        delay: Duration.zero,
      ),
    );
    expect(find.text('Chưa tải được khen thưởng'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byTooltip('Cách bé nhận khen thưởng'), findsNothing);

    await _pumpRewards(
      tester,
      source: const FakeRewardSource(
        mode: FakeMode.empty,
        delay: Duration.zero,
      ),
    );
    expect(find.text('Chưa có cờ bé ngoan'), findsOneWidget);
    await _tapVisible(tester, find.text('Tháng'));
    expect(find.text('Chưa có phiếu Bé ngoan'), findsOneWidget);
    await _tapVisible(tester, find.text('Cuối năm'));
    expect(find.text('Chưa có danh hiệu cuối năm'), findsOneWidget);
    expect(find.text('Cả năm học'), findsNothing);
  });

  testWidgets('Chữ 1,3 và 2,0: cả 3 mục không tràn', (tester) async {
    for (final scale in [1.3, 2.0]) {
      await _pumpRewards(tester, textScale: scale);
      expect(tester.takeException(), isNull, reason: 'Tuần $scale');
      for (final tab in ['Tháng', 'Cuối năm']) {
        await _tapVisible(tester, find.text(tab));
        expect(tester.takeException(), isNull, reason: '$tab $scale');
      }
    }
  });
}
