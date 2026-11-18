import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/teacher/activity_schedule/presentation/screens/activity_schedule_screen.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/presentation/screens/class_leave_screen.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/class_roster/presentation/screens/class_roster_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_detail_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_list_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_detail_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_list_screen.dart';
import 'package:carenest_app/features/teacher/meal_photos/data/fake_meal_photo_source.dart';
import 'package:carenest_app/features/teacher/meal_photos/domain/meal_photos.dart';
import 'package:carenest_app/features/teacher/meal_photos/presentation/screens/meal_photo_capture_screen.dart';
import 'package:carenest_app/features/teacher/meal_photos/presentation/screens/meal_photo_send_screen.dart';
import 'package:carenest_app/features/teacher/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_list_screen.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_verify_screen.dart';
import 'package:carenest_app/features/teacher/rewards/data/fake_teacher_reward_source.dart';
import 'package:carenest_app/features/teacher/rewards/presentation/screens/teacher_rewards_screen.dart';

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
Future<void> noopReview(String _, ReviewDetailView _) async {}

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

  testWidgets('T04 → T04.1 (OBS-02): mỗi loại đánh giá mở riêng', (
    tester,
  ) async {
    final source = FakeDailyReviewSource();
    String? openedChildId;
    await pumpScreen(
      tester,
      DailyReviewListScreen(
        onOpenKid: (childId, view) async {
          expect(view, ReviewDetailView.week);
          openedChildId = childId;
        },
        source: source,
      ),
    );
    expect(find.text('Đánh giá trẻ'), findsOneWidget);
    expect(find.text('Ngày'), findsOneWidget);
    expect(find.text('Tuần'), findsOneWidget);
    expect(find.text('Cuối chủ đề'), findsOneWidget);
    expect(find.text('Học kỳ'), findsOneWidget);
    expect(find.text('Cuối năm'), findsOneWidget);
    expect(find.text('Định kỳ'), findsNothing);
    expect(find.text('Đã có'), findsWidgets);
    expect(find.text('Nhận xét chung của lớp'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Đánh giá'), findsNothing);

    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tuần 12–16/10'), findsWidgets);
    expect(find.textContaining('hoạt động trong tuần'), findsWidgets);
    await tester.tap(
      find.text(FakeClassRosterSource.kids.first.fullName).first,
    );
    await tester.pumpAndSettle();
    expect(openedChildId, FakeClassRosterSource.kids.first.id);

    await tester.tap(find.text('Cuối chủ đề'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cuối chủ đề'), findsWidgets);
    final periods = await source.loadPeriods(FakeClassRosterSource.classId);
    expect(
      periods.any((review) => review.kind == ReviewPeriodKind.semester),
      isTrue,
    );

    await pumpScreen(
      tester,
      DailyReviewDetailScreen(childId: 'k-06', source: source),
    );
    expect(find.textContaining('iáo án'), findsNothing);
    expect(find.text('Ăn bữa trưa'), findsOneWidget);
    expect(find.text('Ngủ ít'), findsOneWidget);
    expect(find.text('Cần cố gắng'), findsNothing);
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, -700),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhận xét về bé'), findsOneWidget);
    expect(find.text('Hành vi'), findsOneWidget);
    expect(
      find.text('Bé tham gia tốt, cần ổn định giờ ngủ trưa.'),
      findsOneWidget,
    );
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, -1800),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhận xét chung của lớp'), findsOneWidget);
    expect(find.text('Chỉ xem · dữ liệu được ghi trên web.'), findsOneWidget);
    expect(find.text('Tuần & định kỳ'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Lưu'), findsNothing);
    expect(find.byType(AppFilterChip), findsNothing);

    await pumpScreen(
      tester,
      DailyReviewDetailScreen(
        childId: 'k-06',
        view: ReviewDetailView.week,
        source: source,
      ),
    );
    expect(find.text('Nhận xét tuần'), findsOneWidget);
    expect(find.text('Tuần 12–16/10'), findsOneWidget);
    expect(find.textContaining('Theo dõi thêm giấc ngủ trưa.'), findsOneWidget);
    expect(find.text('Ăn bữa trưa'), findsNothing);
    expect(find.textContaining('Cuối chủ đề'), findsNothing);

    await pumpScreen(
      tester,
      DailyReviewDetailScreen(
        childId: 'k-06',
        view: ReviewDetailView.theme,
        source: source,
      ),
    );
    expect(find.text('Đánh giá cuối chủ đề'), findsOneWidget);
    expect(find.text('Cuối chủ đề · Mùa thu của bé'), findsOneWidget);
    expect(find.text('Học kỳ I'), findsNothing);
    expect(find.text('Cuối năm học 2025–2026'), findsNothing);

    await pumpScreen(
      tester,
      DailyReviewDetailScreen(
        childId: 'k-06',
        view: ReviewDetailView.semester,
        source: source,
      ),
    );
    expect(find.text('Đánh giá học kỳ'), findsOneWidget);
    expect(find.text('Học kỳ I'), findsOneWidget);
    expect(find.textContaining('Cuối chủ đề'), findsNothing);
    expect(find.text('Cuối năm học 2025–2026'), findsNothing);

    await pumpScreen(
      tester,
      DailyReviewDetailScreen(
        childId: 'k-06',
        view: ReviewDetailView.yearEnd,
        source: source,
      ),
    );
    expect(find.text('Đánh giá cuối năm'), findsOneWidget);
    expect(find.text('Cuối năm học 2025–2026'), findsOneWidget);
    expect(find.textContaining('Cuối chủ đề'), findsNothing);
    expect(find.text('Học kỳ I'), findsNothing);
    expect(find.text('Tuần 12–16/10'), findsNothing);
  });

  testWidgets(
    'ATT-05: đơn nghỉ lớp theo trạng thái BE, có Đã hủy và ngày không áp dụng',
    (tester) async {
      await pumpScreen(tester, ClassLeaveScreen(today: DateTime(2026, 10, 1)));
      expect(find.text('Đang hiệu lực'), findsWidgets);
      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.text('Không áp dụng: 11/10'), findsOneWidget);
      expect(find.textContaining('Đã xem'), findsNothing);
    },
  );

  testWidgets('Khen thưởng: xem phiếu bé ngoan và đề xuất của lớp', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const TeacherRewardsScreen(source: FakeTeacherRewardSource()),
    );
    expect(find.text('Phiếu bé ngoan'), findsOneWidget);
    expect(find.text('Phiếu tuần'), findsOneWidget);
    expect(find.text('Phiếu tháng'), findsWidgets);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);

    expect(find.text('Đang lập'), findsOneWidget);

    await tester.tap(find.text('Đề xuất'));
    await tester.pumpAndSettle();
    // OBS-14: chỉ danh hiệu BE; chưa chọn thì hiện gợi ý
    expect(find.text('Có mặt 152/160 · Bé chăm ngoan'), findsOneWidget);
    expect(find.text('Có mặt 131/160 · Bé ngoan (gợi ý)'), findsOneWidget);
    expect(find.textContaining('Bé tiến bộ'), findsNothing);
    expect(find.textContaining('Bé ngoan toàn diện'), findsNothing);
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
      expect(find.widgetWithText(AppButton, 'Trả trẻ'), findsOneWidget);
      await tester.tap(find.text('Mẹ – Nguyễn Thu Lan'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, 'Trả trẻ'));
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
      expect(find.widgetWithText(AppButton, 'Trả trẻ'), findsOneWidget);
      await tester.tap(find.text('Bố – Trần Văn Hùng'));
      await tester.pump();
      final handoverButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Trả trẻ'),
      );
      expect(handoverButton.onPressed, isNull);

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

  testWidgets('T15 → T16 / AC-9: chụp thêm ảnh giữ chỗ, gửi phụ huynh', (
    tester,
  ) async {
    final source = FakeMealPhotoSource();
    MealSlot? next;
    await pumpScreen(
      tester,
      MealPhotoCaptureScreen(source: source, onNext: (slot) => next = slot),
    );
    expect(find.text('Đã chụp (2/6)'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Chụp ảnh'));
    await tester.pump();
    expect(find.text('Đã chụp (3/6)'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('Tiếp ›'));
    expect(next, MealSlot.lunch);

    var sent = false;
    await pumpScreen(
      tester,
      MealPhotoSendScreen(
        slot: MealSlot.lunch,
        source: source,
        onSent: () => sent = true,
      ),
    );
    expect(
      find.textContaining('không chụp mặt bé', skipOffstage: false),
      findsOneWidget,
    );
    await tester.tap(find.text('Gửi phụ huynh'));
    await tester.pumpAndSettle();
    expect(sent, isTrue);
  });

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    ('Lớp học', const ClassRosterScreen(), true),
    ('Đơn nghỉ lớp', const ClassLeaveScreen(), false),
    ('Đánh giá', DailyReviewListScreen(onOpenKid: noopReview), false),
    ('Đánh giá bé', DailyReviewDetailScreen(childId: 'child-1'), false),
    ('Khen thưởng', const TeacherRewardsScreen(), false),
    ('Đón trẻ', PickupListScreen(onVerify: noop), false),
    ('Xác minh', PickupVerifyScreen(childId: 'k-02', onDone: () {}), false),
    ('Đo sức khỏe', HealthMeasureListScreen(onOpenKid: noop), false),
    ('Đo một bé', HealthMeasureDetailScreen(childId: 'child-1'), false),
    ('Lịch hoạt động', ActivityScheduleScreen(initialDay: today), false),
    ('Chụp ảnh', MealPhotoCaptureScreen(onNext: (_) {}), false),
    (
      'Gửi ảnh',
      MealPhotoSendScreen(slot: MealSlot.lunch, onSent: () {}),
      false,
    ),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}
