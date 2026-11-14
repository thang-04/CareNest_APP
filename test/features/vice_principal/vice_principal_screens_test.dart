import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/approvals/presentation/screens/approvals_screen.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/campus_children/presentation/screens/campus_children_screen.dart';
import 'package:carenest_app/features/meal_count_confirm/data/fake_meal_count_confirm_source.dart';
import 'package:carenest_app/features/meal_count_confirm/presentation/screens/meal_count_confirm_screen.dart';
import 'package:carenest_app/features/nutrition_balance/presentation/screens/nutrition_balance_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/presentation/screens/reward_proposals_screen.dart';
import 'package:carenest_app/features/vice_principal_home/data/fake_campus_today_source.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/campus_menu_screen.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/vice_principal_home_screen.dart';

import '../../helpers/pump_app.dart';

final today = DateTime(2026, 10, 12);
final confirmedAt = DateTime(2026, 10, 12, 8, 25);

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

FakeCampusTodaySource homeSource({
  FakeMode mode = FakeMode.data,
  DateTime? mealsConfirmedAt,
}) => FakeCampusTodaySource(
  mode: mode,
  delay: Duration.zero,
  rewards: FakeRewardProposalSource(),
  mealCount: FakeMealCountConfirmSource(confirmedAt: mealsConfirmedAt),
);

/// AUTH-21, BE ADR-0026: màn BGH không có nút gửi thao tác ghi.
void expectNoWriteActions() {
  for (final label in ['Duyệt', 'Từ chối', 'Xem & chốt', 'Trả về Phó HT']) {
    expect(find.text(label), findsNothing, reason: label);
  }
  for (final prefix in [
    'Xác nhận gửi bếp',
    'Gửi HT (',
    'Trả lại (',
    'Duyệt (',
  ]) {
    expect(find.textContaining(prefix), findsNothing, reason: prefix);
  }
  expect(find.byType(Checkbox), findsNothing);
}

void main() {
  testWidgets(
    'V01 (AUTH-08, AUTH-21): thẻ cơ sở, số hôm nay, số suất chờ xác nhận trên Web',
    (tester) async {
      await pumpScreen(
        tester,
        VicePrincipalHomeScreen(source: homeSource()),
        inScaffold: true,
      );
      expect(find.text('Chào thầy,'), findsOneWidget);
      expect(find.text('Lê Văn Bình'), findsOneWidget);
      expect(find.text('Cơ sở chính – Thượng Hồng'), findsOneWidget);
      expect(find.text('6 lớp · 182 bé có mặt / 196'), findsOneWidget);
      expect(find.bySemanticsLabel('Có mặt: 182'), findsOneWidget);
      expect(find.bySemanticsLabel('Có phép: 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Vắng: 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Chờ xử lý: 2'), findsOneWidget);
      expect(find.text('Theo dõi hôm nay'), findsOneWidget);
      expect(find.text('Chưa xác nhận'), findsOneWidget);
      expect(find.text('Tổng hợp 08:15 · hạn 08:30'), findsOneWidget);
      // Số suất chưa xác nhận ⇒ thẻ có viền nhấn như Figma PHT 01
      expect(
        tester
            .widget<AppTaskCard>(
              find.widgetWithText(AppTaskCard, 'Số suất hôm nay'),
            )
            .highlighted,
        isTrue,
      );
      expectNoWriteActions();
      await tester.scrollUntilVisible(find.text('Trẻ của cơ sở'), 200);
      expect(find.text('Số suất · 8 đề xuất khen thưởng'), findsOneWidget);
      expect(find.text('2 việc'), findsOneWidget);
      // NUT-14 REMOVED: không còn trạng thái bếp; chỉ dị ứng, không ăn chay / ăn kiêng
      expect(find.text('Trạng thái bếp'), findsNothing);
      expect(find.textContaining('ăn kiêng'), findsNothing);
      expect(find.textContaining('Ăn chay'), findsNothing);
    },
  );

  testWidgets(
    'V01: đã xác nhận trên Web ⇒ nhãn Đã xác nhận, chỉ còn việc khen thưởng',
    (tester) async {
      await pumpScreen(
        tester,
        VicePrincipalHomeScreen(
          source: homeSource(mealsConfirmedAt: confirmedAt),
        ),
        inScaffold: true,
      );
      expect(find.text('Đã xác nhận'), findsOneWidget);
      expect(find.text('Đã gửi bếp 08:25 · 182 suất'), findsOneWidget);
      expect(find.bySemanticsLabel('Chờ xử lý: 1'), findsOneWidget);
      expect(
        tester
            .widget<AppTaskCard>(
              find.widgetWithText(AppTaskCard, 'Số suất hôm nay'),
            )
            .highlighted,
        isFalse,
      );
      await tester.scrollUntilVisible(find.text('1 việc'), 200);
      expect(find.text('8 đề xuất khen thưởng'), findsOneWidget);
    },
  );

  testWidgets('V01: không có việc ⇒ trạng thái rỗng', (tester) async {
    await pumpScreen(
      tester,
      VicePrincipalHomeScreen(source: homeSource(mode: FakeMode.empty)),
      inScaffold: true,
    );
    expect(find.bySemanticsLabel('Chờ xử lý: 0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Chưa có việc cần theo dõi'),
      200,
    );
    expect(find.byType(AppTaskCard), findsNothing);
  });

  testWidgets('V01: lỗi tải ⇒ Thử lại, không để khung chờ chạy mãi', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      VicePrincipalHomeScreen(source: homeSource(mode: FakeMode.error)),
      inScaffold: true,
    );
    await tester.scrollUntilVisible(find.text('Thử lại'), 200);
  });

  testWidgets('V02 (AUTH-21): chờ xử lý chỉ xem, lọc theo loại', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ApprovalsScreen(
        mealSource: FakeMealCountConfirmSource(),
        rewardSource: FakeRewardProposalSource(),
      ),
      inScaffold: true,
    );
    expect(find.text('Chờ xử lý'), findsOneWidget);
    expect(find.text('2 việc'), findsOneWidget);
    expect(find.text('Số suất chưa xác nhận'), findsOneWidget);
    expect(find.textContaining('Chỉ xem.'), findsOneWidget);
    await tester.tap(find.text('Khen thưởng').first);
    await tester.pumpAndSettle();
    expect(find.text('Số suất chưa xác nhận'), findsNothing);
    expect(find.text('8 đề xuất từ giáo viên chờ xét'), findsOneWidget);
    expectNoWriteActions();
  });

  testWidgets('V02: số suất đã xác nhận ⇒ không còn việc suất ăn', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ApprovalsScreen(
        mealSource: FakeMealCountConfirmSource(confirmedAt: confirmedAt),
        rewardSource: FakeRewardProposalSource(),
      ),
      inScaffold: true,
    );
    expect(find.text('1 việc'), findsOneWidget);
    expect(find.text('Số suất chưa xác nhận'), findsNothing);
  });

  testWidgets('V04 (NUT-02, AUTH-21): số suất chỉ xem, xác nhận trên Web', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      MealCountConfirmScreen(source: FakeMealCountConfirmSource()),
    );
    expect(find.text('Số suất hôm nay'), findsOneWidget);
    expect(find.text('Thứ Hai, 12/10 · tổng hợp lúc 08:15'), findsOneWidget);
    expect(find.bySemanticsLabel('Tổng suất: 182'), findsOneWidget);
    expect(
      labelOf('Chồi 1'),
      'Chồi 1, 29 suất thường, 2 suất thay thế, dị ứng trứng',
    );
    expect(find.textContaining('xác nhận trên CareNest Web'), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
    expectNoWriteActions();
  });

  testWidgets('Figma audit: PHT 04 trạng thái chưa xác nhận nằm dưới bảng', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      MealCountConfirmScreen(source: FakeMealCountConfirmSource()),
    );
    final banner = find.text('Chưa xác nhận — xác nhận trên CareNest Web');
    await tester.scrollUntilVisible(banner, 200);
    expect(
      tester.getTopLeft(banner).dy,
      greaterThan(tester.getTopLeft(find.text('Lá 2')).dy),
    );
  });

  testWidgets('V04: đã xác nhận ⇒ hiện giờ xác nhận', (tester) async {
    await pumpScreen(
      tester,
      MealCountConfirmScreen(
        source: FakeMealCountConfirmSource(confirmedAt: confirmedAt),
      ),
    );
    expect(
      find.textContaining('Đã xác nhận gửi bếp lúc 08:25'),
      findsOneWidget,
    );
    expect(find.byType(AppButton), findsNothing);
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
    // Câu chỉ xem nằm trong banner đã duyệt (Figma PHT 06), AUTH-21
    expect(
      find.text('Lập và duyệt trên CareNest Web · App chỉ xem'),
      findsOneWidget,
    );
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
    // Plan 14/11 AC-4: không có lọc ăn kiêng / ăn chay
    expect(find.textContaining('Ăn kiêng'), findsNothing);

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

  testWidgets(
    'V12 (OBS-10, AUTH-21): hợp lệ có chữ; chỉ xem, không gửi HT / trả lại',
    (tester) async {
      await pumpScreen(
        tester,
        RewardProposalsScreen(source: FakeRewardProposalSource()),
      );
      expect(find.text('Chờ xét (8)'), findsOneWidget);
      expect(
        labelOf('Vũ Đức Huy'),
        'Vũ Đức Huy, Mầm 3A, Bé chăm ngoan, 4/10 phiếu – chưa đủ điều kiện, Không hợp lệ',
      );
      expect(find.byType(AppButton), findsNothing);
      expectNoWriteActions();
      await tester.scrollUntilVisible(find.textContaining('Chỉ xem.'), 200);
      await tester.scrollUntilVisible(find.text('Đã gửi HT'), -200);
      await tester.tap(find.text('Đã gửi HT'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa gửi đề xuất nào cho Hiệu trưởng'), findsOneWidget);
    },
  );

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    ('Trang chủ Phó HT', VicePrincipalHomeScreen(source: homeSource()), true),
    (
      'Chờ xử lý',
      ApprovalsScreen(
        mealSource: FakeMealCountConfirmSource(),
        rewardSource: FakeRewardProposalSource(),
      ),
      true,
    ),
    (
      'Số suất hôm nay',
      MealCountConfirmScreen(source: FakeMealCountConfirmSource()),
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
