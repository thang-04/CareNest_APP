import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/approvals/presentation/screens/principal_approvals_screen.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/campus_children/presentation/screens/campus_children_screen.dart';
import 'package:carenest_app/features/campuses/data/fake_campus_source.dart';
import 'package:carenest_app/features/campuses/presentation/screens/campuses_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/principal_overview/data/fake_school_overview_source.dart';
import 'package:carenest_app/features/principal_overview/presentation/screens/principal_overview_screen.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_principal_reward_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_batch.dart';
import 'package:carenest_app/features/reward_proposals/presentation/screens/reward_batch_screen.dart';
import 'package:carenest_app/features/school_children/presentation/screens/school_children_screen.dart';
import 'package:carenest_app/features/school_menu/presentation/screens/school_menu_overview_screen.dart';

import '../../helpers/pump_app.dart';

const batchId = 'batch-main-year';
const campuses = [
  (FakeCampusChildrenSource.mainCampusId, 'Cơ sở chính'),
  (FakeCampusChildrenSource.secondCampusId, 'Cơ sở 2'),
];

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
  bool inScaffold = false,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: inScaffold ? Scaffold(body: screen) : screen,
    ),
  );
  await tester.pumpAndSettle();
}

String? labelOf(String prefix) => find
    .bySemanticsLabel(RegExp('^$prefix'))
    .evaluate()
    .firstOrNull
    ?.renderObject
    ?.debugSemantics
    ?.label;

void main() {
  testWidgets(
    'H01 (AUTH-08, K5): hai cơ sở cạnh nhau, không có nghỉ phép nhân sự',
    (tester) async {
      await pumpScreen(
        tester,
        PrincipalOverviewScreen(
          source: FakeSchoolOverviewSource(
            delay: Duration.zero,
            rewards: FakePrincipalRewardSource(),
          ),
        ),
        inScaffold: true,
      );
      expect(find.text('Nguyễn Thị Hồng'), findsOneWidget);
      expect(
        find.text('Trường MN Thượng Hồng · Thứ Hai, 12/10'),
        findsOneWidget,
      );
      expect(
        labelOf('Cơ sở chính'),
        'Cơ sở chính, có mặt 182/196, 93%, 182 suất đã chốt, bếp đang nấu',
      );
      expect(
        labelOf('Cơ sở 2'),
        'Cơ sở 2, có mặt 130/138, 94%, 124 suất đã chốt, bếp đang nấu',
      );
      // Hai thẻ cùng một hàng
      final main = tester.getTopLeft(
        find.bySemanticsLabel(RegExp('^Cơ sở chính')),
      );
      final second = tester.getTopLeft(
        find.bySemanticsLabel(RegExp('^Cơ sở 2')),
      );
      expect(main.dy, second.dy);
      expect(main.dx, lessThan(second.dx));
      await tester.scrollUntilVisible(
        find.text('Khen thưởng cuối năm · 7 bé'),
        200,
      );
      await tester.scrollUntilVisible(find.bySemanticsLabel('Mầm: 91%'), 200);
      await tester.scrollUntilVisible(find.text('312/334 bé · 93%'), 200);
      expect(find.textContaining('Nghỉ phép'), findsNothing);
    },
  );

  testWidgets('H01: khổ 320 hai thẻ cơ sở vẫn cạnh nhau, không tràn', (
    tester,
  ) async {
    usePhoneSize(tester);
    tester.view.physicalSize = const Size(320, 800);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: PrincipalOverviewScreen(
            source: FakeSchoolOverviewSource(
              delay: Duration.zero,
              rewards: FakePrincipalRewardSource(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final main = tester.getTopLeft(
      find.bySemanticsLabel(RegExp('^Cơ sở chính')),
    );
    final second = tester.getTopLeft(find.bySemanticsLabel(RegExp('^Cơ sở 2')));
    expect(main.dy, second.dy);
  });

  testWidgets('H01: lỗi tải ⇒ Thử lại', (tester) async {
    await pumpScreen(
      tester,
      PrincipalOverviewScreen(
        source: FakeSchoolOverviewSource(
          mode: FakeMode.error,
          delay: Duration.zero,
          rewards: FakePrincipalRewardSource(),
        ),
      ),
      inScaffold: true,
    );
    await tester.scrollUntilVisible(find.text('Thử lại'), 200);
  });

  testWidgets('H02 (K5): đợt chờ duyệt và đã xử lý, không có tab nghỉ phép', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      PrincipalApprovalsScreen(source: FakePrincipalRewardSource()),
      inScaffold: true,
    );
    expect(find.text('1 mới'), findsOneWidget);
    expect(find.text('Khen thưởng cuối năm · 7 bé'), findsOneWidget);
    expect(find.text('Đã xử lý gần đây'), findsOneWidget);
    expect(find.text('Trả về'), findsOneWidget);
    expect(find.textContaining('Nghỉ phép'), findsNothing);
  });

  testWidgets('H04 (OBS-10): bỏ chọn ⇒ cần ghi chú; duyệt số đề xuất đã chọn', (
    tester,
  ) async {
    final source = FakePrincipalRewardSource();
    var done = 0;
    await pumpScreen(
      tester,
      RewardBatchScreen(id: batchId, source: source, onDone: () => done++),
    );
    expect(find.text('Cơ sở chính · 7 đề xuất hợp lệ'), findsOneWidget);
    expect(find.text('Duyệt (7)'), findsOneWidget);
    expect(find.text('+ 2 đề xuất khác · Xem tất cả'), findsOneWidget);

    await tester.tap(find.text('Nguyễn Minh Anh · Mầm 3A', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Duyệt (6)'), findsOneWidget);
    await tester.tap(find.text('Duyệt (6)'));
    await tester.pumpAndSettle();
    expect(done, 0);
    expect(find.text('Nhập ghi chú cho 1 đề xuất bỏ chọn'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Thiếu minh chứng tháng 9');
    await tester.tap(find.text('Duyệt (6)'));
    await tester.pumpAndSettle();
    expect(done, 1);
    final batch = await source.loadBatch(batchId);
    expect(batch?.status, RewardBatchStatus.approved);
    expect(batch?.decisionNote, 'Đã duyệt 12/10 · 6 bé');
  });

  testWidgets('H04: trả về Phó HT bắt buộc ghi chú', (tester) async {
    final source = FakePrincipalRewardSource();
    await pumpScreen(
      tester,
      RewardBatchScreen(id: batchId, source: source, onDone: () {}),
    );
    await tester.tap(find.text('Trả về Phó HT'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nhập ghi chú để Phó HT biết vì sao trả về'),
      findsOneWidget,
    );
    expect(
      (await source.loadBatch(batchId))?.status,
      RewardBatchStatus.pending,
    );
  });

  testWidgets('H06 (AUTH-01): lớp theo cơ sở, tìm tên bé', (tester) async {
    await pumpScreen(
      tester,
      SchoolChildrenScreen(
        source: FakeCampusChildrenSource(delay: Duration.zero),
      ),
    );
    expect(find.text('334 bé'), findsOneWidget);
    expect(labelOf('Mầm 3A'), isNotNull);
    await tester.tap(find.text('Cơ sở 2').first);
    await tester.pumpAndSettle();
    expect(find.text('Mầm 3A'), findsNothing);
    expect(find.text('Nhà trẻ 1 (CS2)'), findsOneWidget);

    await tester.tap(find.text('Tất cả cơ sở'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'minh anh');
    await tester.pumpAndSettle();
    expect(find.text('Mầm 3A · Cơ sở chính'), findsOneWidget);
  });

  testWidgets('H06 → lớp: mở sẵn lớp, ID lớp sai ⇒ coi như chưa chọn', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      CampusChildrenScreen(
        campusId: FakeCampusChildrenSource.secondCampusId,
        initialClassId: 'cs2-nha-tre-1',
        source: FakeCampusChildrenSource(delay: Duration.zero),
      ),
    );
    expect(find.text('Nhà trẻ 1 (CS2)'), findsOneWidget);
    expect(find.text('Dị ứng (1)'), findsOneWidget);
    expect(find.text('Tô Minh Khuê'), findsOneWidget);

    await pumpScreen(
      tester,
      CampusChildrenScreen(
        key: UniqueKey(),
        campusId: FakeCampusChildrenSource.secondCampusId,
        initialClassId: 'khong-co',
        source: FakeCampusChildrenSource(delay: Duration.zero),
      ),
    );
    expect(find.text('Tất cả các lớp (5 lớp)'), findsOneWidget);
  });

  testWidgets('H07 (NUT-08): đổi cơ sở thấy nhóm nhà trẻ và tóm tắt BE', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      SchoolMenuOverviewScreen(
        initialDay: FakeParentHomeSource.today,
        campuses: campuses,
      ),
    );
    expect(find.text('Mầm · Thứ Hai'), findsOneWidget);
    expect(find.text('612 kcal'), findsOneWidget);
    expect(find.text('Nhà trẻ · Thứ Hai'), findsNothing);
    await tester.tap(find.text('Cơ sở 2'));
    await tester.pumpAndSettle();
    expect(find.text('Nhà trẻ · Thứ Hai'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Năng lượng đạt chuẩn 4/4 nhóm tuổi'),
      200,
    );
  });

  testWidgets('H08 (AUTH-02): cơ sở và Phó HT phụ trách', (tester) async {
    await pumpScreen(
      tester,
      CampusesScreen(source: FakeCampusSource(delay: Duration.zero)),
    );
    expect(find.text('Thầy Lê Văn Bình'), findsOneWidget);
    expect(find.text('Cô Vũ Thị Hạnh'), findsOneWidget);
    expect(find.textContaining('6 lớp · 196 bé'), findsOneWidget);
    expect(find.textContaining('5 lớp · 138 bé'), findsOneWidget);
  });

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    (
      'Tổng quan',
      PrincipalOverviewScreen(
        source: FakeSchoolOverviewSource(
          delay: Duration.zero,
          rewards: FakePrincipalRewardSource(),
        ),
      ),
      true,
    ),
    (
      'Chờ Hiệu trưởng duyệt',
      PrincipalApprovalsScreen(source: FakePrincipalRewardSource()),
      true,
    ),
    (
      'Khen thưởng cuối năm',
      RewardBatchScreen(
        id: batchId,
        source: FakePrincipalRewardSource(),
        onDone: () {},
      ),
      false,
    ),
    (
      'Danh sách trẻ',
      SchoolChildrenScreen(
        source: FakeCampusChildrenSource(delay: Duration.zero),
      ),
      false,
    ),
    (
      'Thực đơn tuần',
      SchoolMenuOverviewScreen(
        initialDay: FakeParentHomeSource.today,
        campuses: campuses,
      ),
      false,
    ),
    (
      'Cơ sở của trường',
      CampusesScreen(source: FakeCampusSource(delay: Duration.zero)),
      false,
    ),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}
