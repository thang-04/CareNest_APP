import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent_home/presentation/selected_child.dart';

import '../../helpers/pump_app.dart';

/// Nguồn giả với danh sách con tuỳ chọn (1, 2 hoặc 3 bé) để kiểm phần "ló ra".
class _ChildrenSource implements ParentHomeSource {
  _ChildrenSource(this.children);

  final List<ChildSummary> children;
  final _base = FakeParentHomeSource(delay: Duration.zero);

  @override
  Future<List<ChildSummary>> loadChildren() async => children;

  @override
  Future<ParentToday> loadToday(String childId) async {
    final today = await _base.loadToday(FakeParentHomeSource.children[0].id);
    final child = children.firstWhere((item) => item.id == childId);
    return ParentToday(
      greetingName: today.greetingName,
      date: today.date,
      child: child,
      attendance: today.attendance,
      arrivedAt: today.arrivedAt,
      unreadNotifications: today.unreadNotifications,
      menuPublished: today.menuPublished,
      activityTitle: today.activityTitle,
    );
  }
}

const _thirdChild = ChildSummary(
  id: 'child-3',
  fullName: 'Nguyễn Gia Khang',
  shortName: 'Gia Khang',
  className: 'Nhà trẻ 1B',
  campusName: 'Cơ sở chính – Thượng Hồng',
  ageLabel: '2 tuổi',
  homeroomTeacher: 'Cô Lan',
);

Future<void> pumpParentHome(
  WidgetTester tester,
  FakeMode mode, {
  double textScale = 1,
  ParentHomeSource? source,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: ParentHomeScreen(
          source:
              source ?? FakeParentHomeSource(mode: mode, delay: Duration.zero),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(SelectedChild.reset);

  testWidgets('Figma PH02: dải chào + thẻ bé → Hôm nay → Tiện ích', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.data);
    expect(find.text('Chị Nguyễn Thu Lan'), findsOneWidget);
    expect(find.text('Bé Nguyễn Minh Anh'), findsOneWidget);
    expect(find.textContaining('Lớp Mầm 3A · 4 tuổi'), findsOneWidget);
    expect(find.text('Hôm nay · Thứ Hai, 12/10'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Điểm danh: Có mặt lúc 07:42'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Thực đơn: Đã công bố'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Hoạt động: Tô màu chiếc lá mùa thu'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Thông báo, 2 chưa đọc'), findsOneWidget);

    double top(Finder finder) => tester.getTopLeft(finder).dy;
    expect(
      top(find.text('Chị Nguyễn Thu Lan')),
      lessThan(top(find.text('Bé Nguyễn Minh Anh'))),
    );
    await tester.scrollUntilVisible(find.text('Sức khỏe'), 200);
    expect(
      top(find.text('Bé Nguyễn Minh Anh')),
      lessThan(top(find.text('Tiện ích'))),
    );
    for (final label in [
      'Xin nghỉ cho bé',
      'Hoạt động & đánh giá',
      'Thực đơn tuần',
      'Sức khỏe',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Hai bé (AUTH-04): Đổi bé mở sheet, chọn bé kia', (tester) async {
    await pumpParentHome(tester, FakeMode.data);
    await tester.tap(find.text('Đổi bé'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn bé'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Hoàng Bảo Ngọc'));
    await tester.pumpAndSettle();
    expect(SelectedChild.notifier.value, 'child-2');
    expect(find.text('Bé Nguyễn Hoàng Bảo Ngọc'), findsOneWidget);
    expect(find.textContaining('Lớp Lá 1 · 5 tuổi'), findsOneWidget);
  });

  testWidgets('Ba bé: sheet chọn bé có đủ các con', (tester) async {
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _ChildrenSource([...FakeParentHomeSource.children, _thirdChild]),
    );
    await tester.tap(find.text('Đổi bé'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn bé'), findsOneWidget);
    expect(find.text('Nguyễn Hoàng Bảo Ngọc'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Gia Khang'));
    await tester.pumpAndSettle();
    expect(SelectedChild.notifier.value, 'child-3');
    expect(find.text('Bé Nguyễn Gia Khang'), findsOneWidget);
  });

  testWidgets('Một bé: không có Đổi bé', (tester) async {
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _ChildrenSource([FakeParentHomeSource.children.first]),
    );
    expect(find.text('Đổi bé'), findsNothing);
    expect(find.text('Bé Nguyễn Minh Anh'), findsOneWidget);
  });

  testWidgets('Dữ liệu rỗng ⇒ Chưa điểm danh, thực đơn chưa công bố', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.empty);
    expect(find.bySemanticsLabel('Điểm danh: Chưa điểm danh'), findsOneWidget);
    expect(find.bySemanticsLabel('Thực đơn: Chưa công bố'), findsOneWidget);
    expect(find.bySemanticsLabel('Hoạt động: Chưa có'), findsOneWidget);
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

  testWidgets('AC-5: khổ 320 các dòng hôm nay xếp dọc, không tràn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: ParentHomeScreen(
            source: FakeParentHomeSource(delay: Duration.zero),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    double top(String label) =>
        tester.getTopLeft(find.bySemanticsLabel(RegExp('^$label:'))).dy;
    expect(top('Điểm danh'), lessThan(top('Thực đơn')));
  });

  testWidgets('AC-5: chữ lớn 2.0 ở 360×800 không tràn layout', (tester) async {
    await pumpParentHome(tester, FakeMode.data, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
