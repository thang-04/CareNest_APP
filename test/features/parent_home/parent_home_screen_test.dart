import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent_home/presentation/selected_child.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpParentHome(
  WidgetTester tester,
  FakeMode mode, {
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: ParentHomeScreen(
          source: FakeParentHomeSource(mode: mode, delay: Duration.zero),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(SelectedChild.reset);

  testWidgets('P02 (PAR-01): hero → thẻ bé → Hôm nay → Tiện ích', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.data);
    expect(find.text('Chị Nguyễn Thu Lan'), findsOneWidget);
    expect(find.text('Bé Nguyễn Minh Anh'), findsOneWidget);
    expect(find.textContaining('Lớp Mầm 3A · 4 tuổi'), findsOneWidget);
    expect(find.text('Hôm nay · Thứ Hai, 12/10'), findsOneWidget);
    expect(find.text('Có mặt · 07:42'), findsOneWidget);
    expect(find.text('Hoạt động · Tô màu chiếc lá mùa thu'), findsOneWidget);
    expect(find.bySemanticsLabel('Thông báo, 2 chưa đọc'), findsOneWidget);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Bé Nguyễn Minh Anh'), lessThan(top('Điểm danh')));
    await tester.scrollUntilVisible(find.text('Sức khỏe'), 200);
    expect(top('Điểm danh'), lessThan(top('Tiện ích')));
    for (final label in [
      'Xin nghỉ cho bé',
      'Hoạt động & đánh giá',
      'Thực đơn tuần',
      'Sức khỏe',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('P02 (AUTH-04): Đổi bé mở sheet, đổi sang con khác', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.data);
    await tester.tap(find.text('Đổi bé'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn bé'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Hoàng Bảo Ngọc'));
    await tester.pumpAndSettle();
    expect(find.text('Bé Nguyễn Hoàng Bảo Ngọc'), findsOneWidget);
    expect(SelectedChild.notifier.value, 'child-2');
  });

  testWidgets('Dữ liệu rỗng ⇒ Chưa điểm danh, chưa công bố thực đơn', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.empty);
    expect(find.text('Chưa điểm danh'), findsOneWidget);
    expect(
      find.text('Nhà trường chưa công bố thực đơn hôm nay.'),
      findsOneWidget,
    );
  });

  testWidgets('Lỗi tải ⇒ trạng thái lỗi có Thử lại', (tester) async {
    await pumpParentHome(tester, FakeMode.error);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('Đang tải ⇒ khung chờ', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: ParentHomeScreen(source: FakeParentHomeSource())),
      ),
    );
    expect(find.byType(AppSkeletonCard), findsWidgets);
    await tester.pumpAndSettle();
  });

  testWidgets('AC-10: chữ lớn 2.0 ở 360×800 không tràn layout', (tester) async {
    await pumpParentHome(tester, FakeMode.data, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
