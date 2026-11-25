import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';
import 'package:carenest_app/features/shared/app_mode/app_mode.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';
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
    'Trang chủ như phụ huynh (AUTH-03): lời chào, thẻ lớp, dải ô, hạn điểm danh',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Trần Thu Hà'), findsOneWidget);
      expect(find.text('Mầm 3A'), findsOneWidget);
      expect(find.text('28 bé'), findsOneWidget);
      expect(find.bySemanticsLabel('Điểm danh: 0/28'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Hoạt động: 08:00 Tạo hình'),
        findsOneWidget,
      );
      expect(find.text('Hạn điểm danh: 08:30 · còn 47 phút'), findsOneWidget);
    },
  );

  testWidgets(
    'Cần làm: Điểm danh → Sức khỏe → Trả trẻ; còn lại ở lưới Việc nhanh',
    (tester) async {
      await pumpTeacherHome(tester);
      expect(find.text('Cần làm'), findsWidgets);
      for (final title in ['Điểm danh', 'Sức khỏe', 'Trả trẻ']) {
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(title)},')),
          findsOneWidget,
          reason: title,
        );
      }
      expect(find.textContaining('16:30'), findsNothing);
      await tester.scrollUntilVisible(find.text('Lịch hoạt động'), 300);
      expect(find.text('Việc nhanh'), findsOneWidget);
      for (final title in [
        'Đơn xin nghỉ của lớp',
        'Đánh giá trẻ',
        'Thực đơn',
        'Khen thưởng',
        'Lịch hoạt động',
      ]) {
        expect(find.bySemanticsLabel(title), findsOneWidget, reason: title);
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
    expect(find.bySemanticsLabel('Điểm danh: 28/28'), findsOneWidget);
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

  testWidgets('Chọn năm học cũ ⇒ chỉ xem, không có Cần làm (AUTH-03)', (
    tester,
  ) async {
    addTearDown(SelectedSchoolYear.reset);
    await pumpTeacherHome(tester);
    expect(find.text('Năm học 2026–2027'), findsOneWidget);
    await tester.tap(find.text('Năm học 2026–2027'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Năm học 2025–2026').last);
    await tester.pumpAndSettle();
    expect(find.text('Nhà trẻ 2'), findsOneWidget);
    expect(find.text('Chỉ xem'), findsOneWidget);
    expect(find.text('Cần làm'), findsNothing);
    expect(find.text('Xem lại'), findsOneWidget);
  });

  testWidgets('GV kiêm phụ huynh ⇒ nút Phụ huynh chuyển chế độ (AUTH-21)', (
    tester,
  ) async {
    var switched = false;
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: TeacherHomeScreen(
            source: FakeTeacherHomeSource(delay: Duration.zero),
            onSwitchToParent: () => switched = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phụ huynh'));
    expect(switched, isTrue);
  });

  test('AppMode: GV kiêm phụ huynh mặc định chế độ GV, giữ chế độ đã chọn', () {
    addTearDown(AppMode.reset);
    final roles = AppMode.appRolesOf(['PARENT', 'TEACHER'], [1]);
    expect(AppMode.resolve(roles), AppRole.teacher);
    expect(AppMode.dualRole.value, isTrue);
    AppMode.active.value = AppRole.parent;
    expect(AppMode.resolve(roles), AppRole.parent);
    // Không còn con đang học ⇒ chỉ vai GV
    expect(AppMode.appRolesOf(['PARENT', 'TEACHER'], []), [AppRole.teacher]);
  });
}
