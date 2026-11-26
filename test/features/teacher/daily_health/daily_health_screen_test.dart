import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/daily_health/data/fake_daily_health_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/teacher/daily_health/presentation/screens/daily_health_screen.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpDailyHealth(
  WidgetTester tester,
  FakeDailyHealthSource source, {
  double textScale = 1,
  List<ClassOption> classes = const [],
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: DailyHealthScreen(
        classId: 'class-mam-3a',
        classes: classes,
        today: FakeParentHomeSource.today,
        source: source,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FakeDailyHealthSource fakeSource({
  FakeMode mode = FakeMode.data,
  bool canRecord = true,
  bool failHistory = false,
}) => FakeDailyHealthSource(
  mode: mode,
  canRecord: canRecord,
  failHistory: failHistory,
  delay: Duration.zero,
);

Future<void> openKid(WidgetTester tester, String name) async {
  final finder = find.text(name);
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> pickDay(WidgetTester tester, int day) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Hôm nay'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$day'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'HLT-07: chỉ trẻ có mặt; trẻ chưa ghi là "Chưa kiểm tra", không tự coi bình thường',
    (tester) async {
      await pumpDailyHealth(tester, fakeSource());
      expect(find.bySemanticsLabel(RegExp('^Có mặt: 25')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Có dấu hiệu: 1')), findsOneWidget);
      expect(find.text('Chưa kiểm tra'), findsWidgets);
      expect(find.text('Phạm Khánh Linh'), findsNothing);
      expect(find.text('Hôm nay'), findsOneWidget);
    },
  );

  testWidgets('tìm theo tên và lọc Có dấu hiệu / Chưa kiểm tra', (
    tester,
  ) async {
    await pumpDailyHealth(tester, fakeSource());
    await tester.enterText(find.byType(TextField), 'minh anh');
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Lê Hoàng Nam'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    final noted = find.widgetWithText(AppFilterChip, 'Có dấu hiệu');
    await tester.ensureVisible(noted);
    await tester.pumpAndSettle();
    await tester.tap(noted);
    await tester.pumpAndSettle();
    expect(find.text('Lê Hoàng Nam'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsNothing);
    final unchecked = find.widgetWithText(AppFilterChip, 'Chưa kiểm tra');
    await tester.ensureVisible(unchecked);
    await tester.pumpAndSettle();
    await tester.tap(unchecked);
    await tester.pumpAndSettle();
    expect(find.text('Lê Hoàng Nam'), findsNothing);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
  });

  testWidgets(
    'Ghi bình thường kèm thân nhiệt ⇒ gửi NO_CONCERN, không triệu chứng',
    (tester) async {
      final source = fakeSource();
      await pumpDailyHealth(tester, source);
      await openKid(tester, 'Nguyễn Minh Anh');
      await tester.enterText(find.byType(TextField).first, '36,8');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      final sheet = (await tester.runAsync(() => source.loadSheet('x')))!;
      final latest = sheet.kids
          .firstWhere((kid) => kid.childId == 'child-1')
          .latest!;
      expect(latest.observation, HealthObservation.noConcern);
      expect(latest.temperature, 36.8);
      expect(latest.symptoms, isEmpty);
      expect(latest.date, FakeParentHomeSource.today);
    },
  );

  testWidgets('Thân nhiệt ngoài 20,0–45,0 °C ⇒ báo lỗi, không gửi', (
    tester,
  ) async {
    final source = fakeSource();
    await pumpDailyHealth(tester, source);
    await openKid(tester, 'Nguyễn Minh Anh');
    await tester.enterText(find.byType(TextField).first, '83,5');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Thân nhiệt từ 20,0 đến 45,0 °C, tối đa 1 số lẻ.'),
      findsOneWidget,
    );
    final sheet = (await tester.runAsync(() => source.loadSheet('x')))!;
    expect(
      sheet.kids.firstWhere((kid) => kid.childId == 'child-1').checked,
      isFalse,
    );
  });

  testWidgets(
    'HLT-14: Có dấu hiệu ⇒ chọn biểu hiện + xử trí, gửi đúng mã enum BE',
    (tester) async {
      final source = fakeSource();
      await pumpDailyHealth(tester, source);
      await openKid(tester, 'Nguyễn Minh Anh');
      await tester.tap(find.text('Có dấu hiệu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sốt'));
      await tester.pump();
      await tester.tap(find.text('Đã gọi điện cho phụ huynh'));
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      final sheet = (await tester.runAsync(() => source.loadSheet('x')))!;
      final latest = sheet.kids
          .firstWhere((kid) => kid.childId == 'child-1')
          .latest!;
      expect(latest.observation.code, 'NOTED');
      expect(latest.symptoms.map((s) => s.code), ['FEVER']);
      expect(latest.actions.map((a) => a.code), ['PARENT_INFORMED']);
      expect(latest.temperature, isNull);
    },
  );

  testWidgets('trẻ đã có lần ghi: màn nhập hiện lịch sử và người ghi', (
    tester,
  ) async {
    await pumpDailyHealth(tester, fakeSource());
    await openKid(tester, 'Lê Hoàng Nam');
    await tester.scrollUntilVisible(
      find.text('Người ghi: Cô Lan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lịch sử trong ngày'), findsOneWidget);
    expect(find.textContaining('Xử trí: Theo dõi tại lớp'), findsOneWidget);
    expect(find.text('Người ghi: Cô Lan'), findsOneWidget);
  });

  testWidgets(
    'BE không cho ghi ⇒ chỉ xem, mở được lịch sử nhưng không có form',
    (tester) async {
      await pumpDailyHealth(tester, fakeSource(canRecord: false));
      expect(find.text('Chỉ xem'), findsOneWidget);
      await tester.tap(find.text('Nguyễn Minh Anh'));
      await tester.pumpAndSettle();
      expect(find.text('Thân nhiệt (°C)'), findsNothing);
      expect(find.text('Lịch sử trong ngày'), findsOneWidget);
      expect(find.text('Lưu'), findsNothing);
    },
  );

  testWidgets('lớp xem lịch sử (readOnly) ⇒ không có form nhập', (
    tester,
  ) async {
    await pumpDailyHealth(
      tester,
      fakeSource(),
      classes: const [
        ClassOption(id: 'class-mam-3a', name: 'Mầm 3A', readOnly: true),
      ],
    );
    expect(find.text('Đang xem lịch sử, không sửa được'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Minh Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Thân nhiệt (°C)'), findsNothing);
  });

  testWidgets('đổi sang ngày đã qua ⇒ tải theo ngày và chỉ xem', (
    tester,
  ) async {
    final source = fakeSource();
    await pumpDailyHealth(tester, source);
    await pickDay(tester, 11);
    expect(source.lastRequestedDate, DateTime(2026, 10, 11));
    expect(find.text('Đang xem lịch sử, không sửa được'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Minh Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Thân nhiệt (°C)'), findsNothing);
  });

  testWidgets('HLT-15: trẻ đã được trả ⇒ chỉ xem lịch sử, không có form', (
    tester,
  ) async {
    await pumpDailyHealth(tester, fakeSource());
    final row = find.textContaining('Đã trả trẻ lúc 10:15');
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Thân nhiệt (°C)'), findsNothing);
    expect(find.text('Đã trả trẻ lúc 10:15, không ghi thêm.'), findsOneWidget);
  });

  testWidgets('Rỗng', (tester) async {
    await pumpDailyHealth(tester, fakeSource(mode: FakeMode.empty));
    expect(find.text('Chưa có trẻ có mặt'), findsOneWidget);
  });

  testWidgets('Lỗi tải', (tester) async {
    await pumpDailyHealth(tester, fakeSource(mode: FakeMode.error));
    expect(find.text('Chưa tải được danh sách'), findsOneWidget);
  });

  testWidgets('Chữ lớn 2.0 không tràn layout', (tester) async {
    await pumpDailyHealth(tester, fakeSource(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
