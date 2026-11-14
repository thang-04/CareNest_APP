import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher_home/data/fake_teacher_home_source.dart';
import 'package:carenest_app/features/teacher_home/presentation/screens/teacher_home_screen.dart';

import '../../helpers/pump_app.dart';

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
    'Figma GV01 (AUTH-03): dải chào, thẻ lớp + Lịch hoạt động, hạn điểm danh',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Chào cô,'), findsOneWidget);
      expect(find.text('Trần Thu Hà'), findsOneWidget);
      expect(find.text('Lớp Mầm 3A · 28 bé'), findsOneWidget);
      expect(find.text('Đang diễn ra: 08:00 Tạo hình'), findsOneWidget);
      expect(find.text('Hạn điểm danh: 08:30 · còn 47 phút'), findsOneWidget);
      expect(find.text('Lịch hoạt động ›'), findsOneWidget);
      expect(find.bySemanticsLabel('Lịch hoạt động'), findsOneWidget);
    },
  );

  testWidgets(
    'Figma GV01: Việc cần làm hôm nay xếp dọc, điểm danh đứng đầu, mỗi việc một lần',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Việc cần làm hôm nay'), findsOneWidget);
      final titles = [
        'Điểm danh & sức khỏe',
        'Đơn xin nghỉ',
        'Đánh giá hằng ngày',
        'Đón trẻ',
        'Đo sức khỏe tháng 10',
      ];
      for (final title in titles) {
        await tester.scrollUntilVisible(find.text(title), 150);
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('0/28 bé · trước 08:30'), findsOneWidget);
      expect(find.text('Cần làm'), findsOneWidget);
      expect(find.text('Còn 15'), findsOneWidget);
      // Có mặt là ăn đủ bữa (ATT-02) ⇒ việc điểm danh không có báo ăn
      expect(find.textContaining('báo ăn'), findsNothing);
    },
  );

  testWidgets(
    'Redraw AC-9: không có việc Cơ sở vật chất, không lối vào ảnh bữa ăn',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.textContaining('Cơ sở vật chất'), findsNothing);
      expect(find.textContaining('CSVC'), findsNothing);
      expect(find.textContaining('Ảnh bữa'), findsNothing);
      expect(find.textContaining('chụp'), findsNothing);
      expect(find.text('2 mới'), findsNothing);
    },
  );

  testWidgets('AC-7 (OBS-08): trang chủ không nhắc giáo án', (tester) async {
    await pumpTeacherHome(tester);
    expect(find.textContaining('iáo án'), findsNothing);
  });

  testWidgets('Không còn việc ⇒ trạng thái rỗng', (tester) async {
    await pumpTeacherHome(tester, mode: FakeMode.empty);
    expect(find.text('Không còn việc nào'), findsOneWidget);
    expect(find.text('Đã điểm danh 28/28 bé hôm nay.'), findsOneWidget);
    expect(find.textContaining('Hạn điểm danh'), findsNothing);
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
