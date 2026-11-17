import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/health_book/data/fake_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/presentation/screens/health_book_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<List<String>> pumpBook(
  WidgetTester tester, {
  String childId = 'child-1',
  double textScale = 1,
  HealthBookTab tab = HealthBookTab.rounds,
}) async {
  final opened = <String>[];
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: HealthBookScreen(
        child: FakeParentHomeSource.childById(childId),
        initialTab: tab,
        source: const FakeHealthBookSource(delay: Duration.zero),
        onOpenExam: opened.add,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

Finder note(String text) => find.textContaining(text, findRichText: true);

void main() {
  testWidgets('Sổ sức khỏe: 3 tab; kỳ cân đo mới nhất mở sẵn, kỳ cũ đóng', (
    tester,
  ) async {
    await pumpBook(tester);
    expect(find.text('Sổ sức khỏe'), findsOneWidget);
    for (final tab in ['Kỳ cân đo', 'Đợt khám', 'Xu hướng']) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    expect(find.text('Cân đo định kỳ tháng 10/2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Chiều cao: 104 cm'), findsOneWidget);
    expect(find.bySemanticsLabel('Cân nặng: 17,2 kg'), findsOneWidget);
    expect(note('Cân sau bữa ăn sáng.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Cân đo định kỳ tháng 4/2026'),
      200,
    );
    expect(note('Bé vừa khỏi ốm'), findsNothing);
  });

  testWidgets('Kỳ cân đo: chạm để mở, chạm lần nữa để đóng', (tester) async {
    await pumpBook(tester);
    final april = find.text('Cân đo định kỳ tháng 4/2026');
    await tester.scrollUntilVisible(april, 200);
    await tester.pumpAndSettle();
    await tester.tap(april);
    await tester.pumpAndSettle();
    expect(note('Bé vừa khỏi ốm, ăn kém mấy hôm trước.'), findsOneWidget);

    await tester.tap(april);
    await tester.pumpAndSettle();
    expect(note('Bé vừa khỏi ốm'), findsNothing);
  });

  testWidgets('AC-10: Sổ sức khỏe chữ 2.0 không tràn', (tester) async {
    await pumpBook(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
