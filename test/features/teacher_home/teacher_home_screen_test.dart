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
  testWidgets('T01 (AUTH-03): hero, thẻ lớp, hạn điểm danh, việc cần làm', (
    tester,
  ) async {
    await pumpTeacherHome(tester);
    expect(find.text('Trần Thu Hà'), findsOneWidget);
    expect(find.text('Lớp Mầm 3A · 28 bé'), findsOneWidget);
    expect(find.text('Lịch hoạt động ›'), findsOneWidget);
    expect(find.text('Hạn điểm danh: 08:30 · còn 47 phút'), findsOneWidget);
    expect(find.text('Điểm danh & báo ăn'), findsOneWidget);
    expect(find.text('0/28 bé · trước 08:30'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Đo sức khỏe tháng 10'), 200);
    expect(find.text('Còn 15'), findsOneWidget);
  });

  testWidgets('AC-7 (OBS-08): trang chủ không nhắc giáo án', (tester) async {
    await pumpTeacherHome(tester);
    expect(find.textContaining('iáo án'), findsNothing);
  });

  testWidgets('Không còn việc ⇒ trạng thái rỗng', (tester) async {
    await pumpTeacherHome(tester, mode: FakeMode.empty);
    expect(find.text('Không còn việc nào'), findsOneWidget);
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
