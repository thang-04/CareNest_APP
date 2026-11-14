import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/my_child/presentation/screens/child_activities_screen.dart';
import 'package:carenest_app/features/my_child/presentation/screens/child_attendance_screen.dart';
import 'package:carenest_app/features/my_child/presentation/screens/child_profile_screen.dart';
import 'package:carenest_app/features/my_child/presentation/screens/my_child_screen.dart';
import 'package:carenest_app/features/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent_menu/presentation/screens/weekly_menu_screen.dart';

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

void main() {
  setUp(SelectedChild.reset);

  testWidgets(
    'Redraw AC-5 (OBS-02, ATT-04): Hôm nay có mức Đạt / Cần cố gắng, đơn nghỉ Vắng có phép',
    (tester) async {
      await pumpScreen(tester, const MyChildScreen(), inScaffold: true);
      expect(find.text('07:42 · Điểm danh – Có mặt'), findsOneWidget);
      expect(find.text('Sức khỏe: Đạt'), findsOneWidget);
      expect(find.text('Cảm xúc: Đạt'), findsOneWidget);
      expect(find.text('Kiến thức – kỹ năng: Cần cố gắng'), findsOneWidget);
      expect(find.textContaining('Tốt'), findsNothing);
      expect(find.textContaining('Vui vẻ'), findsNothing);
      await tester.scrollUntilVisible(find.text('Đơn xin nghỉ 13/10'), 200);
      expect(find.text('Vắng có phép 13/10'), findsOneWidget);
      expect(find.textContaining('GV chưa xem'), findsNothing);
      expect(find.textContaining('GV đã xem'), findsNothing);
      expect(find.textContaining('Suất ăn'), findsNothing);
    },
  );

  testWidgets(
    'P11 / AC-8 (HLT-04): Sức khỏe có số đo, biểu đồ, câu không chẩn đoán',
    (tester) async {
      await pumpScreen(tester, const MyChildScreen(), inScaffold: true);
      await tester.tap(find.text('Sức khỏe'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Chiều cao: 104 cm'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Cân nặng các tháng: T6')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining('không thay thế chẩn đoán y tế'),
        200,
      );
      expect(find.textContaining('điều trị'), findsNothing);
    },
  );

  testWidgets('Figma audit: P11 lần đo gần nhất 05/10/2026', (tester) async {
    await pumpScreen(
      tester,
      const MyChildScreen(initialTab: MyChildTab.health),
      inScaffold: true,
    );
    expect(find.text('Lần đo gần nhất · 05/10/2026'), findsOneWidget);
  });

  testWidgets(
    'Redraw AC-8 (OBS-06, OBS-10): Phát triển có nhận xét tháng, phiếu bé ngoan tuần, khen thưởng',
    (tester) async {
      await pumpScreen(tester, const MyChildScreen(), inScaffold: true);
      await tester.tap(find.text('Phát triển'));
      await tester.pumpAndSettle();
      expect(find.text('Nhận xét tháng 9/2026'), findsOneWidget);
      expect(find.text('Cô Trần Thu Hà · 30/09/2026'), findsOneWidget);
      expect(find.text('Nhận xét tháng 8/2026'), findsOneWidget);
      expect(find.textContaining('Nhận xét tuần'), findsNothing);
      expect(find.bySemanticsLabel('2 trên 4 phiếu tuần'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Khen thưởng cuối năm'), 200);
    },
  );

  testWidgets('Đổi bé ở chỗ khác ⇒ tab Bé của tôi đổi theo', (tester) async {
    await pumpScreen(tester, const MyChildScreen(), inScaffold: true);
    expect(find.textContaining('Nguyễn Minh Anh'), findsWidgets);
    SelectedChild.notifier.value = 'child-2';
    await tester.pumpAndSettle();
    expect(find.textContaining('Nguyễn Hoàng Bảo Ngọc'), findsOneWidget);
  });

  testWidgets('P09 / AC-9: ảnh hoạt động là khối giữ chỗ, có "+1"', (
    tester,
  ) async {
    await pumpScreen(tester, const ChildActivitiesScreen(childId: 'child-1'));
    expect(find.text('Hành vi: Đạt'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('+1'), 200);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'Redraw AC-6 (OBS-02): Hoạt động & đánh giá dùng mức Đạt / Cần cố gắng / Chưa đạt',
    (tester) async {
      await pumpScreen(tester, const ChildActivitiesScreen(childId: 'child-1'));
      expect(find.text('Sức khỏe: Đạt'), findsOneWidget);
      expect(find.text('Kiến thức – kỹ năng: Cần cố gắng'), findsOneWidget);
      expect(find.textContaining('Tốt'), findsNothing);
      expect(find.textContaining('Vui vẻ'), findsNothing);
    },
  );

  testWidgets(
    'Redraw AC-7 (ATT-02): số đếm tháng không có Suất huỷ, không ghi từng bữa',
    (tester) async {
      await pumpScreen(
        tester,
        ChildAttendanceScreen(childId: 'child-1', initialDay: today),
      );
      expect(find.bySemanticsLabel('Có mặt: 8'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Suất huỷ')), findsNothing);
      expect(find.textContaining('Suất', findRichText: true), findsNothing);
      expect(
        find.textContaining('ăn sáng', findRichText: true, skipOffstage: false),
        findsNothing,
      );
      await tester.tap(
        find.bySemanticsLabel('Thứ Ba, 13/10/2026, Vắng có phép'),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Theo đơn xin nghỉ',
          findRichText: true,
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Đã huỷ', findRichText: true, skipOffstage: false),
        findsNothing,
      );
    },
  );

  testWidgets('P13: hồ sơ có GV chủ nhiệm, người đưa đón; chỉ xem', (
    tester,
  ) async {
    await pumpScreen(tester, const ChildProfileScreen(childId: 'child-1'));
    expect(find.text('Cô Trần Thu Hà · Cô Lê Mai'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Mẹ – Thu Lan'), 200);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'Redraw AC-4 (NUT-16): đổi ngày trong tuần, hôm nay có ảnh mẫu của bếp cơ sở',
    (tester) async {
      await pumpScreen(
        tester,
        WeeklyMenuScreen(childId: 'child-1', initialDay: today),
      );
      expect(find.textContaining('Cháo thịt bằm'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ảnh mẫu của bếp cơ sở · 11:05'),
        200,
      );
      expect(find.textContaining('đăng'), findsNothing);
      expect(find.byType(Image), findsNothing);

      await tester.scrollUntilVisible(find.text('T3'), -200);
      await tester.tap(find.text('T3'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bún bò'), findsOneWidget);
      expect(find.text('Ảnh mẫu của bếp cơ sở · 11:05'), findsNothing);
    },
  );

  testWidgets('P05: bé có dị ứng ⇒ cảnh báo suất thay thế', (tester) async {
    await pumpScreen(
      tester,
      WeeklyMenuScreen(childId: 'child-2', initialDay: today),
    );
    await tester.scrollUntilVisible(find.textContaining('dị ứng hải sản'), 200);
  });

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    ('Bé của tôi', const MyChildScreen(), true),
    ('Sức khỏe', const MyChildScreen(initialTab: MyChildTab.health), true),
    (
      'Phát triển',
      const MyChildScreen(initialTab: MyChildTab.development),
      true,
    ),
    ('Hoạt động', const ChildActivitiesScreen(childId: 'child-1'), false),
    (
      'Điểm danh',
      ChildAttendanceScreen(childId: 'child-1', initialDay: today),
      false,
    ),
    ('Hồ sơ', const ChildProfileScreen(childId: 'child-1'), false),
    (
      'Thực đơn',
      WeeklyMenuScreen(childId: 'child-1', initialDay: today),
      false,
    ),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}
