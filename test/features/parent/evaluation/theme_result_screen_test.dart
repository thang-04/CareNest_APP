import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/evaluation/data/fake_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/screens/theme_result_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> _pumpTheme(
  WidgetTester tester,
  String themeId, {
  String childId = 'child-1',
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: ThemeResultScreen(
        key: UniqueKey(),
        child: FakeParentHomeSource.childById(childId),
        themeId: themeId,
        source: const FakeEvaluationSource(delay: Duration.zero),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Chủ đề chưa đạt: số đạt, nhóm Chưa đạt trước, người xác nhận', (
    tester,
  ) async {
    await _pumpTheme(tester, 'theme-mam-5');
    expect(find.text('Cuối chủ đề'), findsOneWidget);
    expect(find.text('Thế giới động vật'), findsOneWidget);
    expect(find.text('01/03 – 02/04/2027 · Mầm 3A'), findsOneWidget);
    expect(find.bySemanticsLabel('3 trên 5 mục tiêu đạt'), findsOneWidget);
    expect(find.text('Chưa đạt chủ đề'), findsOneWidget);
    expect(
      find.text('Bé đạt chủ đề khi đạt từ 70% số mục tiêu.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Chưa đạt, 2 mục tiêu'), findsOneWidget);
    expect(find.text('Phân biệt to – nhỏ'), findsOneWidget);
    expect(find.bySemanticsLabel('Đạt, 3 mục tiêu'), findsOneWidget);
    expect(find.textContaining('Xem thêm'), findsNothing);
    final confirmed = find.text('Cô Trần Thu Hà xác nhận ngày 07/04/2027');
    await tester.scrollUntilVisible(confirmed, 200);
    expect(confirmed, findsOneWidget);
  });

  testWidgets(
    'Chủ đề đạt hết: không có nhóm Chưa đạt; hiện đủ MT đạt, không nút Xem thêm',
    (tester) async {
      await _pumpTheme(tester, 'theme-la-4', childId: 'child-2');
      expect(find.text('Đạt chủ đề'), findsOneWidget);
      expect(find.bySemanticsLabel('Chưa đạt, 0 mục tiêu'), findsNothing);
      // User 18/11: không thu gọn MT đạt, MT thứ 5 hiện luôn
      final fifth = find.text('Vẽ lá cờ Tổ quốc');
      await tester.scrollUntilVisible(fifth, 200);
      expect(fifth, findsOneWidget);
      expect(find.textContaining('Xem thêm'), findsNothing);
    },
  );

  testWidgets('Chủ đề lạ hoặc đang học ⇒ "Không tìm thấy kết quả chủ đề"', (
    tester,
  ) async {
    await _pumpTheme(tester, 'theme-x');
    expect(find.text('Không tìm thấy kết quả chủ đề'), findsOneWidget);

    await _pumpTheme(tester, 'theme-la-6', childId: 'child-2');
    expect(find.text('Không tìm thấy kết quả chủ đề'), findsOneWidget);
  });

  testWidgets('Chữ 2,0: kết quả chủ đề không tràn', (tester) async {
    await _pumpTheme(tester, 'theme-mam-5', textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
