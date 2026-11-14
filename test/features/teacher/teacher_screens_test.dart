import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/activity_schedule/presentation/screens/activity_schedule_screen.dart';
import 'package:carenest_app/features/class_leave_notices/presentation/screens/class_leave_screen.dart';
import 'package:carenest_app/features/class_roster/presentation/screens/class_roster_screen.dart';
import 'package:carenest_app/features/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/daily_review/domain/daily_review.dart';
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

  testWidgets('Figma audit: T09 không có nhãn ăn theo bữa (ATT-02)', (
    tester,
  ) async {
    await pumpScreen(tester, const ClassRosterScreen(), inScaffold: true);
    // Plan 14/11 AC-4 (HLT-06): không có nhãn ăn chay, chỉ dị ứng
    expect(find.text('Ăn chay', skipOffstage: false), findsNothing);
    expect(find.textContaining('bữa', skipOffstage: false), findsNothing);
  });

  testWidgets(
    'Figma audit: T04 bé đã đánh giá hiện tóm tắt ngắn, không lặp 7 mức',
    (tester) async {
      final source = FakeDailyReviewSource();
      // Một bé có mặt khác mức mặc định ⇒ chỉ nêu mặt đó
      await source.save(
        KidReview(
          childId: 'k-06',
          fullName: 'Trần Bảo Ngọc',
          state: KidReviewState.done,
          presenceLine: 'Có mặt 07:47',
          answers: {
            for (final c in FakeDailyReviewSource.criteria)
              c.id: c.id == 'sleep' ? 'Cần cố gắng' : c.defaultOption,
          },
        ),
      );
      await pumpScreen(
        tester,
        DailyReviewListScreen(onOpenKid: noop, source: source),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Ngủ: Cần cố gắng'), findsOneWidget);
      expect(find.text('Đạt cả 7 mặt'), findsWidgets);
      expect(
        find.textContaining('Đạt · Đạt', skipOffstage: false),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Redraw AC-11 (ATT-05): GV chỉ xem; không Mới / Đã xem, không đánh dấu, không duyệt',
    (tester) async {
      await pumpScreen(tester, const ClassLeaveScreen());
      expect(find.text('Mới'), findsNothing);
      expect(find.text('Đã xem'), findsNothing);
      expect(find.textContaining('Đánh dấu'), findsNothing);
      expect(find.textContaining('duyệt'), findsNothing);
      expect(find.textContaining('Cả ngày'), findsNothing);
      expect(find.textContaining('Buổi'), findsNothing);
      expect(find.text('Vắng có phép'), findsNWidgets(3));
      // Plan 14/11 AC-5: chỉ đơn nghỉ, không có trẻ vắng không đơn
      expect(find.text('Vắng'), findsNothing);
      expect(find.text('Vũ Đức Huy'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      await tester.scrollUntilVisible(
        find.text(
          'Ngày có đơn tự ghi Vắng có phép, không có suất. GV chỉ xem đơn.',
        ),
        200,
      );
      await tester.scrollUntilVisible(find.text('Tất cả'), -200);
      await tester.tap(find.text('Tất cả'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Lê Hoàng Nam'), 200);
    },
  );

  testWidgets(
    'Redraw AC-12 (OBS-01, OBS-02): 7 mặt, mức Đạt / Cần cố gắng / Chưa đạt, mặc định Đạt; không nhắc giáo án',
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
      for (final old in [
        'Tốt',
        'Vui vẻ',
        'Bình thường',
        'Cần chú ý',
        'Cần hỗ trợ',
      ]) {
        expect(find.text(old, skipOffstage: false), findsNothing);
      }
      final aspects = [
        'Ăn uống',
        'Ngủ',
        'Cảm xúc',
        'Hành vi',
        'Tham gia hoạt động',
        'Kiến thức – kỹ năng',
        'Sức khỏe',
      ];
      for (final aspect in aspects) {
        await tester.scrollUntilVisible(
          find.text(aspect),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // Mỗi mặt chỉ có 3 mức, mặc định chọn Đạt (bé chưa đánh giá)
        final chips = tester
            .widgetList<AppFilterChip>(find.byType(AppFilterChip))
            .where((chip) => chip.icon == null);
        expect(chips.map((chip) => chip.label).toSet(), {
          'Đạt',
          'Cần cố gắng',
          'Chưa đạt',
        });
        expect(
          chips.where((chip) => chip.selected).map((c) => c.label).toSet(),
          {'Đạt'},
        );
      }
      // Đang ở mặt cuối (Sức khỏe): GV chỉ sửa mặt khác thường
      await tester.tap(find.widgetWithText(AppFilterChip, 'Cần cố gắng').last);
      await tester.pump();
      await tester.tap(find.text('Lưu & về danh sách'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      final day = (await tester.runAsync(() => source.loadDay('x')))!;
      final answers = day.kids.first.answers;
      expect(answers.length, 7);
      expect(answers['health'], 'Cần cố gắng');
      expect(answers.values.where((v) => v == 'Đạt').length, 6);
    },
  );

  testWidgets(
    'Redraw AC-13 (PCK-02, PCK-04): không khớp bắt ghi cuộc gọi rồi Trả bé / Không trả bé',
    (tester) async {
      final source = FakePickupSource();
      var done = 0;
      Future<void> open(String childId) => pumpScreen(
        tester,
        PickupVerifyScreen(
          childId: childId,
          source: source,
          onDone: () => done++,
        ),
      );
      Future<void> tapText(String text) async {
        final target = find.text(text).last;
        await tester.scrollUntilVisible(
          target,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await open('child-1');
      await tester.scrollUntilVisible(
        find.text(
          'Không khớp: gọi phụ huynh, ghi nội dung cuộc gọi rồi chọn Trả bé / Không trả bé. Hệ thống ghi người đón, giờ đón và báo phụ huynh.',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Chỉ giao bé khi'), findsNothing);
      expect(find.text('Trả bé', skipOffstage: false), findsNothing);
      await tapText('Không khớp – gọi phụ huynh');
      await tester.scrollUntilVisible(
        find.text('Trả bé'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Không trả bé'), findsOneWidget);

      // Thiếu nội dung cuộc gọi ⇒ không ghi
      await tapText('Không trả bé');
      expect(find.text('Ghi nội dung cuộc gọi.'), findsOneWidget);
      expect(done, 0);

      // Không trả bé ⇒ ghi lần đón, bé vẫn chờ
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Gọi mẹ không nghe máy');
      await tapText('Không trả bé');
      expect(done, 1);
      expect(source.calls.single.handedOver, isFalse);
      var kids = (await tester.runAsync(() => source.loadClass('x')))!;
      expect(kids.firstWhere((k) => k.childId == 'child-1').pickedUp, isFalse);

      // Trả bé ⇒ bắt người đón, ghi người đón + giờ đón
      await open('child-1');
      await tapText('Không khớp – gọi phụ huynh');
      await tester.enterText(
        find.byType(TextField).at(0),
        'Mẹ xác nhận nhờ chú Tâm đón',
      );
      await tapText('Trả bé');
      expect(find.text('Ghi người đến đón.'), findsOneWidget);
      expect(done, 1);
      await tester.enterText(find.byType(TextField).at(1), 'Chú Tâm');
      await tapText('Trả bé');
      expect(done, 2);
      expect(source.calls.last.handedOver, isTrue);
      kids = (await tester.runAsync(() => source.loadClass('x')))!;
      final kid = kids.firstWhere((k) => k.childId == 'child-1');
      expect(kid.pickedUpBy, 'Chú Tâm');
      expect(kid.pickedUpAt, isNotNull);
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
    'Redraw AC-14 (HLT-11, HLT-12): lưu là công bố, phân loại chỉ hiển thị; không chẩn đoán',
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
      expect(
        find.text('Kết quả do hệ thống tính (chỉ hiển thị)'),
        findsNothing,
      );
      expect(find.byType(Switch), findsNothing);
      expect(find.textContaining('Công bố cho phụ huynh'), findsNothing);
      expect(
        find.textContaining('Lý do sửa', findRichText: true),
        findsNothing,
      );
      await tester.enterText(find.byType(TextField).at(0), '102');
      await tester.enterText(find.byType(TextField).at(1), '16,5');
      await tester.pumpAndSettle();
      expect(
        find.text('Kết quả do hệ thống tính (chỉ hiển thị)'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Phân loại: Bình thường'), findsOneWidget);
      for (final level in ['Thiếu cân', 'Bình thường', 'Thừa cân']) {
        expect(find.text(level), findsOneWidget);
      }
      // Chip phân loại không bấm được
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(AppFilterChip), findsNothing);
      await tester.scrollUntilVisible(
        find.text(
          'Không phải chẩn đoán y tế. Sửa số đo phải nhập lý do, lịch sử được lưu.',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Lưu là công bố cho phụ huynh'),
        findsOneWidget,
      );
      expect(find.textContaining('điều trị'), findsNothing);
    },
  );

  testWidgets('Redraw AC-14 (HLT-13): sửa số đo đã lưu bắt buộc lý do', (
    tester,
  ) async {
    final source = FakeHealthMeasureSource();
    var saved = false;
    await pumpScreen(
      tester,
      HealthMeasureDetailScreen(
        childId: 'child-1',
        source: source,
        onSaved: () => saved = true,
      ),
    );
    expect(
      find.textContaining('Lý do sửa', findRichText: true),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(1), '17,4');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu & về danh sách'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    await tester.scrollUntilVisible(
      find.text('Nhập lý do sửa số đo.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      'Cân lại không áo khoác',
    );
    await tester.tap(find.text('Lưu & về danh sách'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(source.history.single.weight, '17,2');
    final month = (await tester.runAsync(() => source.loadMonth('x')))!;
    final kid = month.kids.firstWhere((k) => k.childId == 'child-1');
    expect(kid.weight, '17,4');
    expect(kid.editReason, 'Cân lại không áo khoác');
  });

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
