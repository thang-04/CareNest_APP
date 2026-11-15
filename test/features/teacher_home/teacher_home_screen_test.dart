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
    'Bố cục D (AUTH-03): thẻ lớp có vòng điểm danh, hạn, nút làm ngay',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Trần Thu Hà'), findsOneWidget);
      expect(find.text('Lớp Mầm 3A'), findsOneWidget);
      expect(find.text('28 bé · Đang diễn ra: 08:00 Tạo hình'), findsOneWidget);
      expect(find.bySemanticsLabel('0/28 đã điểm danh'), findsOneWidget);
      expect(find.text('Hạn điểm danh: 08:30 · còn 47 phút'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Điểm danh ngay'),
        findsOneWidget,
      );
      expect(find.text('Lịch hoạt động ›'), findsOneWidget);
    },
  );

  testWidgets(
    'Bố cục D: Việc tiếp theo trượt ngang, không lặp việc điểm danh',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Việc tiếp theo'), findsOneWidget);
      expect(find.text('Điểm danh & báo ăn'), findsNothing);
      for (final title in [
        'Đơn xin nghỉ',
        'Đánh giá hằng ngày',
        'Ảnh bữa ăn',
        'Đón trẻ',
        'Đo sức khỏe tháng 10',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Còn 15'), findsOneWidget);
    },
  );

  testWidgets('AC-7 (OBS-08): trang chủ không nhắc giáo án', (tester) async {
    await pumpTeacherHome(tester);
    expect(find.textContaining('iáo án'), findsNothing);
  });

  testWidgets('Không còn việc ⇒ trạng thái rỗng', (tester) async {
    await pumpTeacherHome(tester, mode: FakeMode.empty);
    expect(find.text('Không còn việc nào'), findsOneWidget);
    expect(find.bySemanticsLabel('28/28 đã điểm danh'), findsOneWidget);
    expect(find.text('Điểm danh ngay'), findsNothing);
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
