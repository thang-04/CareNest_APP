import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/activity_schedule/presentation/screens/activity_schedule_screen.dart';
import 'package:carenest_app/features/class_leave_notices/presentation/screens/class_leave_screen.dart';
import 'package:carenest_app/features/class_roster/presentation/screens/class_roster_screen.dart';
import 'package:carenest_app/features/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/daily_review/presentation/screens/daily_review_detail_screen.dart';
import 'package:carenest_app/features/daily_review/presentation/screens/daily_review_list_screen.dart';
import 'package:carenest_app/features/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/health_measure/presentation/screens/health_measure_detail_screen.dart';
import 'package:carenest_app/features/health_measure/presentation/screens/health_measure_list_screen.dart';
import 'package:carenest_app/features/meal_photos/data/fake_meal_photo_source.dart';
import 'package:carenest_app/features/meal_photos/domain/meal_photos.dart';
import 'package:carenest_app/features/meal_photos/presentation/screens/meal_photo_capture_screen.dart';
import 'package:carenest_app/features/meal_photos/presentation/screens/meal_photo_send_screen.dart';
import 'package:carenest_app/features/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/pickup/presentation/screens/pickup_list_screen.dart';
import 'package:carenest_app/features/pickup/presentation/screens/pickup_verify_screen.dart';

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

  testWidgets('T03 / AC-4 (ATT-05): GV chỉ xem, đánh dấu đã xem, không duyệt', (
    tester,
  ) async {
    await pumpScreen(tester, const ClassLeaveScreen());
    expect(find.text('Mới'), findsNWidgets(2));
    expect(find.textContaining('duyệt'), findsNothing);
    await tester.tap(find.text('Đánh dấu đã xem (2 đơn)'));
    await tester.pump();
    expect(find.text('Mới'), findsNothing);
    await tester.tap(find.text('Tất cả'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Lê Hoàng Nam'), 200);
  });

  testWidgets(
    'T04 → T04.1 / AC-7: chọn đủ tiêu chí mới lưu; không nhắc giáo án',
    (tester) async {
      final source = FakeDailyReviewSource();
      await pumpScreen(
        tester,
        DailyReviewListScreen(onOpenKid: noop, source: source),
      );
      expect(find.text('8/25 bé'), findsOneWidget);

      var saved = false;
      await pumpScreen(
        tester,
        DailyReviewDetailScreen(
          childId: 'child-1',
          source: source,
          onSaved: () => saved = true,
        ),
      );
      expect(find.textContaining('iáo án'), findsNothing);
      await tester.tap(find.text('Lưu & về danh sách'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Chọn đủ các tiêu chí trước khi lưu.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      for (final option in ['Tốt', 'Vui vẻ', 'Đạt']) {
        final chip = find.widgetWithText(AppFilterChip, option).first;
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pump();
      }
      await tester.tap(find.text('Lưu & về danh sách'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      final day = (await tester.runAsync(() => source.loadDay('x')))!;
      expect(day.kids.first.answers['emotion'], 'Vui vẻ');
    },
  );

  testWidgets('T05 → T06 / AC-9: giao bé ghi nhận người đón; ảnh là icon', (
    tester,
  ) async {
    final source = FakePickupSource();
    await pumpScreen(tester, PickupListScreen(onVerify: noop, source: source));
    expect(find.bySemanticsLabel('Đã đón: 18'), findsOneWidget);
    expect(find.text('Đăng ký: Mẹ Thu Lan, Bố Văn Hùng'), findsOneWidget);

    var done = false;
    await pumpScreen(
      tester,
      PickupVerifyScreen(
        childId: 'child-1',
        source: source,
        onDone: () => done = true,
      ),
    );
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('Đúng – giao bé'));
    await tester.pumpAndSettle();
    expect(done, isTrue);
    final kids = (await tester.runAsync(() => source.loadClass('x')))!;
    expect(kids.firstWhere((k) => k.childId == 'child-1').pickedUpBy, 'Mẹ');
  });

  testWidgets(
    'T07 → T07.1 / AC-8 (HLT-04): số đo, kết quả BE, không chẩn đoán',
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
        HealthMeasureDetailScreen(
          childId: 'k-20',
          source: source,
          onSaved: () {},
        ),
      );
      expect(find.text('Kết quả tính theo quy tắc của trường'), findsNothing);
      await tester.enterText(find.byType(TextField).at(0), '102');
      await tester.enterText(find.byType(TextField).at(1), '16,5');
      await tester.pumpAndSettle();
      expect(find.text('Bình thường'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Không phải chẩn đoán y tế. Lịch sử chỉnh sửa được lưu lại.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('điều trị'), findsNothing);
    },
  );

  testWidgets('T10 / AC-7 (OBS-08): lịch hoạt động không có duyệt giáo án', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ActivityScheduleScreen(initialDay: today, onReviewToday: () {}),
    );
    expect(
      find.text('Kế hoạch tuần 12–16/10 · Chủ đề “Mùa thu của bé”'),
      findsOneWidget,
    );
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
    ('Đánh giá', DailyReviewListScreen(onOpenKid: noop), false),
    (
      'Đánh giá bé',
      DailyReviewDetailScreen(childId: 'child-1', onSaved: () {}),
      false,
    ),
    ('Đón trẻ', PickupListScreen(onVerify: noop), false),
    ('Xác minh', PickupVerifyScreen(childId: 'k-02', onDone: () {}), false),
    ('Đo sức khỏe', HealthMeasureListScreen(onOpenKid: noop), false),
    (
      'Đo một bé',
      HealthMeasureDetailScreen(childId: 'child-1', onSaved: () {}),
      false,
    ),
    (
      'Lịch hoạt động',
      ActivityScheduleScreen(initialDay: today, onReviewToday: () {}),
      false,
    ),
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
