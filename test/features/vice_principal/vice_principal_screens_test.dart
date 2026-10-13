import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/approvals/data/fake_meal_adjustment_source.dart';
import 'package:carenest_app/features/approvals/presentation/screens/approvals_screen.dart';
import 'package:carenest_app/features/approvals/presentation/screens/meal_adjustment_screen.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/campus_children/presentation/screens/campus_children_screen.dart';
import 'package:carenest_app/features/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/meal_count_confirm/data/fake_meal_count_confirm_source.dart';
import 'package:carenest_app/features/meal_count_confirm/presentation/screens/meal_count_confirm_screen.dart';
import 'package:carenest_app/features/nutrition_balance/presentation/screens/nutrition_balance_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/presentation/screens/reward_proposals_screen.dart';
import 'package:carenest_app/features/vice_principal_home/data/fake_campus_today_source.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/campus_kitchen_screen.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/campus_menu_screen.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/vice_principal_home_screen.dart';

import '../../helpers/pump_app.dart';

final today = DateTime(2026, 10, 12);

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

FakeCampusTodaySource homeSource({FakeMode mode = FakeMode.data}) =>
    FakeCampusTodaySource(
      mode: mode,
      delay: Duration.zero,
      meals: FakeMealAdjustmentSource(),
      rewards: FakeRewardProposalSource(),
      mealCount: FakeMealCountConfirmSource(),
    );

void main() {
  testWidgets('V01 (AUTH-08): số trong ngày của cơ sở và 5 việc', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      VicePrincipalHomeScreen(
        source: homeSource(),
        cookingSource: FakeCookingStatusSource(),
      ),
      inScaffold: true,
    );
    expect(find.text('Lê Văn Bình'), findsOneWidget);
    expect(find.text('6 lớp · 182 bé có mặt / 196'), findsOneWidget);
    expect(find.bySemanticsLabel('Có phép: 9'), findsOneWidget);
    expect(find.bySemanticsLabel('Chờ duyệt: 3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Trẻ của cơ sở'), 200);
    expect(find.text('Bữa trưa: Đang nấu'), findsOneWidget);
    expect(find.text('2 suất ăn · 1 đề xuất khen thưởng'), findsOneWidget);
  });

  testWidgets('V01: lỗi tải ⇒ Thử lại, không để khung chờ chạy mãi', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      VicePrincipalHomeScreen(
        source: homeSource(mode: FakeMode.error),
        cookingSource: FakeCookingStatusSource(),
      ),
      inScaffold: true,
    );
    await tester.scrollUntilVisible(find.text('Thử lại'), 200);
  });

  testWidgets('V02: lọc theo loại yêu cầu', (tester) async {
    await pumpScreen(
      tester,
      ApprovalsScreen(
        mealSource: FakeMealAdjustmentSource(),
        rewardSource: FakeRewardProposalSource(),
      ),
      inScaffold: true,
    );
    expect(find.text('3 mới'), findsOneWidget);
    expect(find.text('Điều chỉnh suất · Mầm 3A'), findsOneWidget);
    await tester.tap(find.text('Khen thưởng').first);
    await tester.pumpAndSettle();
    expect(find.text('Điều chỉnh suất · Mầm 3A'), findsNothing);
    expect(find.text('7 đề xuất từ giáo viên'), findsNothing);
    expect(find.text('8 đề xuất từ giáo viên'), findsOneWidget);
  });

  testWidgets('V03 (NUT-03): từ chối phải có lý do; duyệt xong rời danh sách', (
    tester,
  ) async {
    final source = FakeMealAdjustmentSource();
    var done = 0;
    await pumpScreen(
      tester,
      MealAdjustmentScreen(
        id: 'adj-mam-3a',
        source: source,
        onDone: () => done++,
      ),
    );
    expect(labelOf('Mầm 3A: từ 24'), 'Mầm 3A: từ 24 thành 25 suất');
    expect(find.bySemanticsLabel('Sau khi duyệt: 183'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);

    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();
    expect(done, 0);
    expect(find.textContaining('Nhập lý do'), findsOneWidget);

    await tester.tap(find.text('Duyệt'));
    await tester.pumpAndSettle();
    expect(done, 1);
    expect(await source.loadPending(), hasLength(1));
  });

  testWidgets('V03: ID không có ⇒ không tìm thấy, không có nút duyệt', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      MealAdjustmentScreen(
        id: 'khong-co',
        source: FakeMealAdjustmentSource(),
        onDone: () {},
      ),
    );
    expect(find.text('Không tìm thấy yêu cầu'), findsOneWidget);
    expect(find.text('Duyệt'), findsNothing);
  });

  testWidgets('V04 (NUT-02, P-05): xác nhận gửi bếp xong thì hết nút', (
    tester,
  ) async {
    final source = FakeMealCountConfirmSource();
    await pumpScreen(tester, MealCountConfirmScreen(source: source));
    expect(find.text('Thứ Hai, 12/10 · tổng hợp lúc 08:15'), findsOneWidget);
    expect(find.bySemanticsLabel('Tổng suất: 182'), findsOneWidget);
    expect(
      labelOf('Chồi 1'),
      'Chồi 1, 29 suất thường, 2 suất thay thế, ăn chay',
    );
    await tester.tap(find.text('Xác nhận gửi bếp (182 suất)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã gửi bếp lúc 08:25'), findsOneWidget);
    expect(find.textContaining('Xác nhận gửi bếp'), findsNothing);
  });

  testWidgets('V05 (NUT-14): chỉ xem, có phiếu xuất kho và báo thiếu', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      CampusKitchenScreen(cookingSource: FakeCookingStatusSource()),
    );
    expect(
      find.text('Phiếu xuất kho PXK-1012 · đã duyệt 07:30'),
      findsOneWidget,
    );
    expect(find.textContaining('Chuyển sang'), findsNothing);
    await tester.scrollUntilVisible(find.text('Báo thiếu từ bếp · 07:55'), 200);
  });

  testWidgets('V06 → V07: nút cân đối mang nhóm + ngày đang chọn', (
    tester,
  ) async {
    await pumpScreen(tester, const CampusMenuScreen());
    await tester.scrollUntilVisible(
      find.text('Đã duyệt & công bố · 09/10'),
      200,
    );
    expect(find.text('Xem cân đối dinh dưỡng'), findsOneWidget);
  });

  testWidgets('V07 (NUT-06): nhãn Đạt / Thiếu là chữ, có cảnh báo', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      NutritionBalanceScreen(groupId: 'mam', day: today),
    );
    expect(find.text('Nhóm Mầm · Thứ Hai, 12/10 · chỉ xem'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Canxi: 312 mg, Chuẩn: từ 350 mg, Thiếu'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.textContaining('Canxi chưa đạt chuẩn'),
      200,
    );
  });

  testWidgets('V07: nhóm không có thực đơn ⇒ trạng thái rỗng', (tester) async {
    await pumpScreen(
      tester,
      NutritionBalanceScreen(groupId: 'nha-tre', day: today),
    );
    expect(find.text('Chưa có cân đối dinh dưỡng'), findsOneWidget);
  });

  testWidgets('V10 (AUTH-02, HLT-06): lọc lớp, dị ứng, tìm tên', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      CampusChildrenScreen(
        source: FakeCampusChildrenSource(delay: Duration.zero),
      ),
    );
    expect(find.text('196 bé'), findsOneWidget);
    expect(find.text('Dị ứng (4)'), findsOneWidget);
    expect(find.text('Ăn kiêng (4)'), findsOneWidget);

    await tester.tap(find.text('Dị ứng (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Lê Hoàng Nam'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsNothing);

    await tester.tap(find.text('Tất cả các lớp (6 lớp)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lá 1'));
    await tester.pumpAndSettle();
    expect(find.text('Dị ứng (2)'), findsOneWidget);
    expect(find.text('Lê Hoàng Nam'), findsNothing);

    await tester.enterText(find.byType(TextField), 'giang');
    await tester.pumpAndSettle();
    expect(find.text('Giang Bảo Anh'), findsOneWidget);
    expect(find.text('Mạc Tùng Lâm'), findsNothing);
  });

  testWidgets('V12 (OBS-10): hợp lệ có chữ; gửi HT và trả lại chuyển tab', (
    tester,
  ) async {
    final source = FakeRewardProposalSource();
    await pumpScreen(tester, RewardProposalsScreen(source: source));
    expect(find.text('Chờ xét (8)'), findsOneWidget);
    expect(
      labelOf('Vũ Đức Huy'),
      'Vũ Đức Huy, Mầm 3A, Bé chăm ngoan, 4/10 phiếu – chưa đủ điều kiện, Không hợp lệ',
    );
    await tester.tap(find.text('Gửi HT (7)'));
    await tester.pumpAndSettle();
    expect(find.text('Chờ xét (1)'), findsOneWidget);
    await tester.tap(find.text('Trả lại (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Không còn đề xuất chờ xét'), findsOneWidget);
    await tester.tap(find.text('Đã gửi HT'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
  });

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    (
      'Trang chủ Phó HT',
      VicePrincipalHomeScreen(
        source: homeSource(),
        cookingSource: FakeCookingStatusSource(),
      ),
      true,
    ),
    (
      'Yêu cầu chờ duyệt',
      ApprovalsScreen(
        mealSource: FakeMealAdjustmentSource(),
        rewardSource: FakeRewardProposalSource(),
      ),
      true,
    ),
    (
      'Duyệt điều chỉnh suất',
      MealAdjustmentScreen(
        id: 'adj-mam-3a',
        source: FakeMealAdjustmentSource(),
        onDone: () {},
      ),
      false,
    ),
    (
      'Chốt suất ăn',
      MealCountConfirmScreen(source: FakeMealCountConfirmSource()),
      false,
    ),
    (
      'Trạng thái bếp',
      CampusKitchenScreen(cookingSource: FakeCookingStatusSource()),
      false,
    ),
    ('Thực đơn tuần', const CampusMenuScreen(), false),
    (
      'Cân đối dinh dưỡng',
      NutritionBalanceScreen(groupId: 'mam', day: FakeParentHomeSource.today),
      false,
    ),
    (
      'Trẻ của cơ sở',
      CampusChildrenScreen(
        source: FakeCampusChildrenSource(delay: Duration.zero),
      ),
      false,
    ),
    (
      'Đề xuất khen thưởng',
      RewardProposalsScreen(source: FakeRewardProposalSource()),
      false,
    ),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}
