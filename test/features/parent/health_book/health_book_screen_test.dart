import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
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

  testWidgets(
    'Kỳ cân đo: nhãn BMI nằm dưới dòng số đo, bên phải chỉ có mũi tên',
    (tester) async {
      await pumpBook(tester);
      final subtitle = find.text('15/07/2026 · 102,5 cm · 16,8 kg');
      await tester.scrollUntilVisible(subtitle, 200);
      final row = find.ancestor(
        of: subtitle,
        matching: find.byType(AppListRow),
      );
      final badge = find.descendant(
        of: row,
        matching: find.byType(AppStatusBadge),
      );
      expect(
        tester.getTopLeft(badge).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(subtitle).dy),
      );
    },
  );

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

  testWidgets('Đợt khám: danh sách đợt, chạm một đợt để mở chi tiết', (
    tester,
  ) async {
    final opened = await pumpBook(tester, tab: HealthBookTab.exams);
    expect(find.text('Đợt khám sức khỏe'), findsOneWidget);
    expect(find.text('18/09/2026 · BS. Nguyễn Thị Hằng'), findsOneWidget);
    expect(find.text('Cần theo dõi'), findsOneWidget);
    expect(find.text('Kết luận: Sâu răng'), findsOneWidget);
    expect(find.text('Không ghi nhận bất thường'), findsOneWidget);

    await tester.tap(find.text('Khám sức khỏe đầu năm học 2026-2027'));
    expect(opened, ['exam-2026']);
  });

  testWidgets('Kỳ cân đo: lối "Số đo khi khám" chuyển sang tab Đợt khám', (
    tester,
  ) async {
    await pumpBook(tester);
    final link = find.text('Số đo khi khám sức khỏe xem ở tab Đợt khám ›');
    await tester.scrollUntilVisible(link, 200);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text('Khám sức khỏe đầu năm học 2026-2027'), findsOneWidget);
  });

  for (final tab in HealthBookTab.values) {
    testWidgets('AC-10: Sổ sức khỏe tab ${tab.name} chữ 2.0 không tràn', (
      tester,
    ) async {
      await pumpBook(tester, textScale: 2, tab: tab);
      expect(tester.takeException(), isNull);
    });
  }
}
