import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/teacher/daily_health/data/fake_daily_health_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/teacher/daily_health/presentation/screens/daily_health_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpDailyHealth(
  WidgetTester tester,
  FakeDailyHealthSource source, {
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: DailyHealthScreen(classId: 'class-mam-3a', source: source),
    ),
  );
  await tester.pumpAndSettle();
}

FakeDailyHealthSource fakeSource({
  FakeMode mode = FakeMode.data,
  bool canRecord = true,
}) => FakeDailyHealthSource(
  mode: mode,
  canRecord: canRecord,
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

void main() {
  testWidgets(
    'HLT-07: chỉ bé có mặt; bé chưa ghi là "Chưa kiểm tra", không tự coi bình thường',
    (tester) async {
      await pumpDailyHealth(tester, fakeSource());
      expect(find.bySemanticsLabel(RegExp('^Có mặt: 26')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Cần lưu ý: 1')), findsOneWidget);
      expect(find.text('Chưa kiểm tra'), findsWidgets);
      expect(find.text('Phạm Khánh Linh'), findsNothing);
    },
  );

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
    'HLT-14: Cần lưu ý ⇒ chọn biểu hiện + xử trí, gửi đúng mã enum BE',
    (tester) async {
      final source = fakeSource();
      await pumpDailyHealth(tester, source);
      await openKid(tester, 'Nguyễn Minh Anh');
      await tester.tap(find.text('Cần lưu ý'));
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

  testWidgets('BE không cho ghi ⇒ chỉ xem, không mở màn nhập', (tester) async {
    await pumpDailyHealth(tester, fakeSource(canRecord: false));
    expect(find.text('Chỉ xem'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Minh Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Thân nhiệt (°C)'), findsNothing);
  });

  testWidgets('HLT-15: bé đã được trả thì không mở màn nhập', (tester) async {
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
  });

  testWidgets('Rỗng', (tester) async {
    await pumpDailyHealth(tester, fakeSource(mode: FakeMode.empty));
    expect(find.text('Chưa có bé có mặt'), findsOneWidget);
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
