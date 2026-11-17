import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/teacher/activity_schedule/presentation/screens/activity_schedule_screen.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/presentation/screens/class_leave_screen.dart';
import 'package:carenest_app/features/teacher/class_roster/presentation/screens/class_roster_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_detail_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_list_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_detail_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_list_screen.dart';
import 'package:carenest_app/features/teacher/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_list_screen.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_verify_screen.dart';

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

Future<void> noop(String _) async {}

void main() {
  testWidgets('T09 (AUTH-03): danh sách lớp, nhãn dị ứng, tìm không dấu', (
    tester,
  ) async {
    await pumpScreen(tester, const ClassRosterScreen(), inScaffold: true);
    expect(find.text('Dị ứng hải sản'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'khanh linh');
    await tester.pump();
    expect(find.text('Phạm Khánh Linh'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsNothing);
  });

  testWidgets(
    'T03 / AC-4 (ATT-05): GV chỉ xem đơn nghỉ, không duyệt, không thao tác',
    (tester) async {
      await pumpScreen(tester, const ClassLeaveScreen());
      expect(find.textContaining('duyệt'), findsNothing);
      expect(find.textContaining('Đánh dấu đã xem'), findsNothing);
      expect(find.byType(AppButton), findsNothing);
      await tester.tap(find.text('Tất cả'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Lê Hoàng Nam'), 200);
    },
  );

  testWidgets('T04 → T04.1 (OBS-02): chỉ xem 7 mặt × 3 mức, không có nút lưu', (
    tester,
  ) async {
    final source = FakeDailyReviewSource();
    await pumpScreen(
      tester,
      DailyReviewListScreen(onOpenKid: noop, source: source),
    );
    expect(find.text('8/25 bé'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Đánh giá'), findsNothing);

    await pumpScreen(
      tester,
      DailyReviewDetailScreen(childId: 'k-06', source: source),
    );
    expect(find.text('Chỉ xem. Đánh giá thực hiện trên web.'), findsOneWidget);
    expect(find.textContaining('iáo án'), findsNothing);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Cần cố gắng'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bé ngủ trưa muộn, hơi quấy.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Lưu'), findsNothing);
    expect(find.byType(AppFilterChip), findsNothing);
  });

  testWidgets(
    'T05 → T06 (PCK-02): khớp ảnh ⇒ PHOTO_MATCH có vị trí phụ huynh và giờ trả',
    (tester) async {
      final source = FakePickupSource();
      await pumpScreen(
        tester,
        PickupListScreen(onVerify: noop, source: source),
      );
      expect(find.bySemanticsLabel('Đã đón: 19'), findsOneWidget);
      expect(find.textContaining('Đăng ký'), findsNothing);

      var done = false;
      await pumpScreen(
        tester,
        PickupVerifyScreen(
          childId: 'child-1',
          source: source,
          onDone: () => done = true,
          now: () => DateTime(2026, 10, 12, 16, 40),
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.text('Mẹ – Nguyễn Thu Lan'), findsOneWidget);
      // Thẻ đầu là mẹ (position 1)
      await tester.tap(find.widgetWithText(AppButton, 'Trả trẻ').first);
      await tester.pumpAndSettle();
      expect(done, isTrue);
      final request = source.requests.single;
      expect(request.verification, PickupVerification.photoMatch);
      expect(request.guardianPosition, 1);
      expect(request.handoverTime, '16:40');
      expect(request.note, isNull);
    },
  );

  testWidgets(
    'T06 (PCK-02): bố chưa có ảnh ⇒ không trả trực tiếp; gọi xong phải ghi nội dung',
    (tester) async {
      final source = FakePickupSource();
      var done = false;
      await pumpScreen(
        tester,
        PickupVerifyScreen(
          childId: 'child-1',
          source: source,
          onDone: () => done = true,
          now: () => DateTime(2026, 10, 12, 16, 50),
        ),
      );
      // Thẻ thứ hai là bố, chưa có ảnh
      final dadButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Trả trẻ').at(1),
      );
      expect(dadButton.onPressed, isNull);

      final callButton = find.text('Ghi kết quả gọi');
      await tester.scrollUntilVisible(
        callButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(callButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Trả trẻ').last);
      await tester.pumpAndSettle();
      expect(find.text('Ghi nội dung cuộc gọi với phụ huynh.'), findsOneWidget);
      expect(source.requests, isEmpty);

      await tester.enterText(
        find.byType(TextField).last,
        'Mẹ xác nhận nhờ dì Hoa đón',
      );
      await tester.tap(find.widgetWithText(AppButton, 'Trả trẻ').last);
      await tester.pumpAndSettle();
      expect(done, isTrue);
      final request = source.requests.single;
      expect(request.verification, PickupVerification.phoneConfirmed);
      expect(request.guardianPosition, isNull);
      expect(request.handoverTime, '16:50');
      expect(request.note, 'Mẹ xác nhận nhờ dì Hoa đón');
    },
  );

  testWidgets(
    'T07 → T07.1 (HLT-09, HLT-11, HLT-13): nhập và sửa cân đo trên App',
    (tester) async {
      final source = FakeHealthMeasureSource();
      await pumpScreen(
        tester,
        HealthMeasureListScreen(onOpenKid: noop, source: source),
      );
      expect(find.text('13/28 bé'), findsOneWidget);
      expect(find.text('104 cm · 17,2 kg · vừa xong'), findsOneWidget);

      await pumpScreen(
        tester,
        HealthMeasureDetailScreen(childId: 'child-1', source: source),
      );
      expect(
        find.text('Lưu số đo là phụ huynh xem được ngay.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNWidgets(3));
      await tester.enterText(find.byType(TextField).first, '105');
      await tester.pump();
      expect(find.text('Lý do sửa'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Đo lại chiều cao');
      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Lưu thay đổi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Lưu thay đổi'));
      await tester.pumpAndSettle();
      final saved = (await source.loadMonth(
        'class-1',
      )).kids.firstWhere((kid) => kid.childId == 'child-1');
      expect(saved.height, '105');
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 1000),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Đã lưu chiều cao và cân nặng.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('không phải chẩn đoán y tế'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('điều trị'), findsNothing);
    },
  );

  testWidgets('T10 / AC-7 (OBS-08): lịch hoạt động không có duyệt giáo án', (
    tester,
  ) async {
    await pumpScreen(tester, ActivityScheduleScreen(initialDay: today));
    expect(find.text('Hoạt động dạy học'), findsOneWidget);
    expect(find.text('Hoạt động dạy học hôm nay'), findsOneWidget);
    expect(
      find.text('Kế hoạch tuần 12–16/10 · Chủ đề “Mùa thu của bé”'),
      findsOneWidget,
    );
    expect(find.text('Hoạt động học: Tạo hình'), findsOneWidget);
    expect(find.text('Hoạt động ngoài trời'), findsOneWidget);
    expect(find.text('Hoạt động góc'), findsOneWidget);
    expect(find.textContaining('iáo án'), findsNothing);
    expect(find.textContaining('duyệt'), findsNothing);
    await tester.tap(find.text('T3'));
    await tester.pumpAndSettle();
    expect(find.text('Hoạt động học: Âm nhạc'), findsOneWidget);
  });

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    ('Lớp học', const ClassRosterScreen(), true),
    ('Đơn nghỉ lớp', const ClassLeaveScreen(), false),
    ('Đánh giá', DailyReviewListScreen(onOpenKid: noop), false),
    ('Đánh giá bé', DailyReviewDetailScreen(childId: 'child-1'), false),
    ('Đón trẻ', PickupListScreen(onVerify: noop), false),
    ('Xác minh', PickupVerifyScreen(childId: 'k-02', onDone: () {}), false),
    ('Đo sức khỏe', HealthMeasureListScreen(onOpenKid: noop), false),
    ('Đo một bé', HealthMeasureDetailScreen(childId: 'child-1'), false),
    ('Lịch hoạt động', ActivityScheduleScreen(initialDay: today), false),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}
