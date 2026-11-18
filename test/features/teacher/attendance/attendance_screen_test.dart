import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/attendance_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpAttendance(
  WidgetTester tester, {
  FakeMode mode = FakeMode.data,
  bool failSave = false,
  bool locked = false,
  double textScale = 1,
  VoidCallback? onSaved,
  FakeAttendanceSource? source,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: AttendanceScreen(
        classId: FakeAttendanceSource.classId,
        source:
            source ??
            FakeAttendanceSource(
              mode: mode,
              failSave: failSave,
              locked: locked,
              delay: Duration.zero,
            ),
        onSaved: onSaved,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String countOf(String label) => find
    .bySemanticsLabel(RegExp('^$label: '))
    .evaluate()
    .single
    .renderObject!
    .debugSemantics!
    .label
    .split(': ')
    .last;

/// Cuộn tới nút theo nhãn đọc màn hình rồi bấm (danh sách dựng lười).
Future<void> tapLabel(WidgetTester tester, String label) async {
  // Nhãn khớp đầu chuỗi: node có thể gộp thêm chữ con
  final finder = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));
  await tester.scrollUntilVisible(finder, 150);
  // Đưa dòng ra giữa màn để không nằm dưới thanh nút đáy
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Về đầu danh sách để đọc các ô đếm.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'T02 (như Web): bé chưa ghi là Chưa ĐD; bé có đơn nghỉ là Vắng có phép, không sửa',
    (tester) async {
      await pumpAttendance(tester);
      expect(find.text('Mầm 3A · Thứ Hai, 12/10'), findsOneWidget);
      expect(find.text('Khóa lúc 08:30'), findsOneWidget);
      expect(countOf('Có mặt'), '0');
      expect(countOf('Có phép'), '2');
      expect(countOf('Chưa ĐD'), '26');
      await tapLabel(tester, 'Phạm Khánh Linh: có mặt');
      await scrollToTop(tester);
      expect(countOf('Có phép'), '2');
      expect(countOf('Có mặt'), '0');
    },
  );

  testWidgets('Có mặt tất cả chỉ áp cho bé chưa điểm danh', (tester) async {
    await pumpAttendance(tester);
    await tapLabel(tester, 'Nguyễn Minh Anh: vắng');
    await scrollToTop(tester);
    await tester.tap(find.text('Có mặt tất cả'));
    await tester.pump();
    expect(countOf('Có mặt'), '25');
    expect(countOf('Không phép'), '1');
    expect(countOf('Có phép'), '2');
    expect(countOf('Chưa ĐD'), '0');
  });

  testWidgets('trẻ có mặt có thể được chọn không ăn và không tính vào suất', (
    tester,
  ) async {
    final source = FakeAttendanceSource(delay: Duration.zero);
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: AttendanceScreen(
          classId: FakeAttendanceSource.classId,
          source: source,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Suất ăn: 0/0 trẻ có mặt'), findsOneWidget);
    await tester.tap(find.text('Có mặt tất cả'));
    await tester.pump();
    expect(find.text('Suất ăn: 26/26 trẻ có mặt'), findsOneWidget);
    await tester.tap(find.text('Chọn trẻ ăn (26/26)'));
    await tester.pumpAndSettle();
    expect(find.text('Trẻ tham gia ăn'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('meal-child-1')));
    await tester.pump();
    expect(find.text('Không ăn'), findsOneWidget);
    await tester.tap(find.text('Xong · 25 trẻ có ăn'));
    await tester.pumpAndSettle();
    await scrollToTop(tester);
    expect(find.text('Suất ăn: 25/26 trẻ có mặt'), findsOneWidget);
    await tester.tap(find.text('Lưu và sang Sức khỏe đầu ngày'));
    await tester.pumpAndSettle();
    final saved = source.lastSaved!;
    expect(saved.firstWhere((k) => k.childId == 'child-1').meals, isEmpty);
    expect(
      saved.firstWhere((k) => k.childId == 'child-1').status,
      AttendanceStatus.present,
    );
    final nam = saved.firstWhere((k) => k.childId == 'k-02');
    expect(nam.meals.length, MealSession.values.length);
  });

  testWidgets(
    'ATT-04/09: chỉ gửi trẻ không có đơn nghỉ và đã điểm danh (như Web)',
    (tester) async {
      final source = FakeAttendanceSource(delay: Duration.zero);
      await pumpAttendance(tester, source: source);
      await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
      await tapLabel(tester, 'Lê Hoàng Nam: vắng');
      await tester.tap(find.text('Lưu và sang Sức khỏe đầu ngày'));
      await tester.pumpAndSettle();
      final saved = source.lastSaved!;
      expect(saved.map((k) => k.childId), ['child-1', 'k-02']);
      expect(saved.any((k) => k.hasLeaveNotice), isFalse);
    },
  );

  testWidgets('ATT-06/08: đã khóa ⇒ chỉ xem, không có nút lưu', (tester) async {
    await pumpAttendance(tester, locked: true);
    expect(find.text('Đã khóa'), findsOneWidget);
    expect(find.text('Lưu và sang Sức khỏe đầu ngày'), findsNothing);
    await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
    await scrollToTop(tester);
    expect(countOf('Có mặt'), '0');
  });

  testWidgets('Lưu lỗi ⇒ banner, giữ nguyên lựa chọn, nút Lưu lại', (
    tester,
  ) async {
    var saved = false;
    await pumpAttendance(tester, failSave: true, onSaved: () => saved = true);
    await tapLabel(tester, 'Nguyễn Minh Anh: vắng');
    await tester.tap(find.text('Lưu và sang Sức khỏe đầu ngày'));
    await tester.pumpAndSettle();
    await scrollToTop(tester);
    expect(find.text('Chưa lưu được điểm danh'), findsOneWidget);
    expect(find.text('Lưu lại'), findsOneWidget);
    expect(countOf('Không phép'), '1');
    expect(saved, isFalse);
  });

  testWidgets('Lưu thành công ⇒ chuyển sang Sức khỏe đầu ngày', (tester) async {
    var saved = false;
    await pumpAttendance(tester, onSaved: () => saved = true);
    await tester.tap(find.text('Lưu và sang Sức khỏe đầu ngày'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
  });

  testWidgets('AC-5 (NUT-01): không hiện số suất ăn do APP tính', (
    tester,
  ) async {
    await pumpAttendance(tester);
    expect(find.textContaining('suất'), findsNothing);
  });

  testWidgets('Lớp rỗng', (tester) async {
    await pumpAttendance(tester, mode: FakeMode.empty);
    expect(find.text('Lớp chưa có trẻ'), findsOneWidget);
  });

  testWidgets('Lỗi tải', (tester) async {
    await pumpAttendance(tester, mode: FakeMode.error);
    expect(find.text('Chưa tải được danh sách lớp'), findsOneWidget);
  });

  testWidgets('AC-10: chữ lớn 2.0 ở 360×800 không tràn layout', (tester) async {
    await pumpAttendance(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
