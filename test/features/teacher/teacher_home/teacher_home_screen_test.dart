import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/teacher_home/data/fake_teacher_home_source.dart';
import 'package:carenest_app/features/teacher/teacher_home/presentation/screens/teacher_home_screen.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpTeacherHome(
  WidgetTester tester, {
  FakeMode mode = FakeMode.data,
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: TeacherHomeScreen(
          source: FakeTeacherHomeSource(mode: mode, delay: Duration.zero),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Figma T01 (AUTH-03): lời chào, thẻ lớp, Hoạt động hôm nay, hạn điểm danh',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Trần Thu Hà'), findsOneWidget);
      expect(find.text('Lớp Mầm 3A · 28 bé'), findsOneWidget);
      expect(find.text('Đang diễn ra: 08:00 Tạo hình'), findsOneWidget);
      expect(find.text('0/28 đã điểm danh'), findsOneWidget);
      expect(find.text('Hạn điểm danh: 08:30 · còn 47 phút'), findsOneWidget);
      expect(find.text('Hoạt động\nhôm nay ›'), findsOneWidget);
    },
  );

  testWidgets(
    'Cần làm: Điểm danh → Sức khỏe → Trả trẻ; nội dung còn lại ở Xem nhanh',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Cần làm'), findsWidgets);
      expect(find.text('Xem nhanh'), findsOneWidget);
      expect(find.text('Ảnh bữa ăn'), findsNothing);
      final titles = [
        'Điểm danh',
        'Sức khỏe',
        'Trả trẻ',
        'Đơn xin nghỉ của lớp',
        'Đánh giá hằng ngày',
      ];
      for (final title in titles) {
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(title)},')),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('AC-7 (OBS-08): trang chủ không nhắc giáo án', (tester) async {
    await pumpTeacherHome(tester);
    expect(find.textContaining('iáo án'), findsNothing);
  });

  testWidgets('Không còn việc ⇒ trạng thái rỗng', (tester) async {
    await pumpTeacherHome(tester, mode: FakeMode.empty);
    expect(find.text('Không còn việc nào'), findsOneWidget);
    expect(find.text('28/28 đã điểm danh'), findsOneWidget);
    expect(find.text('Hạn điểm danh: 08:30 · còn 47 phút'), findsNothing);
  });

  testWidgets('Lỗi ⇒ Thử lại', (tester) async {
    await pumpTeacherHome(tester, mode: FakeMode.error);
    expect(find.text('Thử lại', skipOffstage: false), findsOneWidget);
  });

  testWidgets('AC-10: chữ lớn 2.0 ở 360×800 không tràn layout', (tester) async {
    await pumpTeacherHome(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
