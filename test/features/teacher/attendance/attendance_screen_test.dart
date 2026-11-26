import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/attendance_screen.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpAttendance(
  WidgetTester tester, {
  FakeMode mode = FakeMode.data,
  bool failSave = false,
  bool locked = false,
  double textScale = 1,
  VoidCallback? onSaved,
  FakeAttendanceSource? source,
  List<ClassOption> classes = const [],
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: AttendanceScreen(
        classId: FakeAttendanceSource.classId,
        classes: classes,
        today: FakeParentHomeSource.today,
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
  final finder = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  // Đưa dòng ra giữa màn để không nằm dưới thanh nút đáy
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Về đầu danh sách để đọc các ô đếm.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
  await tester.pumpAndSettle();
}

Future<void> pickDay(WidgetTester tester, int day) async {
  await scrollToTop(tester);
  await tester.tap(find.text('Hôm nay'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$day'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> markAllPresent(WidgetTester tester) async {
  await tester.tap(find.text('Có mặt tất cả'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chọn Có mặt'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('đầu ngày: chưa điểm danh; trẻ có đơn nghỉ là Vắng do BE ghi', (
    tester,
  ) async {
    await pumpAttendance(tester);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Đang mở (khóa lúc 08:30)'), findsOneWidget);
    expect(countOf('Sĩ số'), '28');
    expect(countOf('Có mặt'), '0');
    expect(countOf('Vắng'), '3');
    expect(countOf('Chưa điểm danh'), '25');
    expect(find.text('Lưu điểm danh'), findsOneWidget);
  });

  testWidgets('Có mặt tất cả cần xác nhận và chỉ áp cho trẻ chưa điểm danh', (
    tester,
  ) async {
    await pumpAttendance(tester);
    await tapLabel(tester, 'Nguyễn Minh Anh: vắng');
    await scrollToTop(tester);
    await tester.tap(find.text('Có mặt tất cả'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chọn Có mặt cho tất cả trẻ chưa điểm danh?'),
      findsOneWidget,
    );
    // Hủy ⇒ không đổi gì
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(countOf('Có mặt'), '0');
    await markAllPresent(tester);
    expect(countOf('Có mặt'), '24');
    expect(countOf('Vắng'), '4');
    expect(countOf('Chưa điểm danh'), '0');
  });

  testWidgets('đơn nghỉ: nút Nghỉ có phép, thẻ mở thông tin báo nghỉ', (
    tester,
  ) async {
    await pumpAttendance(tester);
    final row = find.byKey(const ValueKey('k-03'));
    await tester.scrollUntilVisible(
      row,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
    await tester.pumpAndSettle();
    final tag = find.descendant(
      of: row,
      matching: find.text('Vắng có phép · Phụ huynh báo nghỉ'),
    );
    expect(find.text('Nghỉ có phép'), findsWidgets);
    await tester.tap(tag);
    await tester.pumpAndSettle();
    expect(find.text('Thông tin báo nghỉ'), findsOneWidget);
    expect(find.text('Ốm'), findsOneWidget);
  });

  testWidgets('bữa ăn từng bữa ngay trên dòng; trẻ không báo ăn không có bữa', (
    tester,
  ) async {
    final source = FakeAttendanceSource(delay: Duration.zero);
    await pumpAttendance(tester, source: source);
    await markAllPresent(tester);
    final row = find.byKey(const ValueKey('child-1'));
    await tester.scrollUntilVisible(
      row,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
    await tester.pumpAndSettle();
    final lunch = find.descendant(of: row, matching: find.text('Trưa'));
    await tester.tap(lunch);
    await tester.pump();
    await scrollToTop(tester);
    await tester.tap(find.text('Lưu điểm danh'));
    await tester.pumpAndSettle();
    final saved = source.lastSaved!;
    final minhAnh = saved.firstWhere((k) => k.childId == 'child-1');
    expect(minhAnh.meals[MealSession.lunch], isFalse);
    expect(minhAnh.meals[MealSession.morning], isTrue);
    final noMeal = saved.firstWhere((k) => k.childId == 'k-06');
    expect(noMeal.meals, isEmpty);
    expect(saved.any((k) => k.childId == 'k-03'), isFalse);
  });

  testWidgets('chỉ gửi trẻ có thay đổi; lưu xong hiện thông báo', (
    tester,
  ) async {
    final source = FakeAttendanceSource(delay: Duration.zero);
    var saved = 0;
    await pumpAttendance(tester, source: source, onSaved: () => saved++);
    await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
    await tapLabel(tester, 'Lê Hoàng Nam: vắng');
    await scrollToTop(tester);
    expect(find.text('2 trẻ có thay đổi chưa lưu'), findsOneWidget);
    await tester.tap(find.text('Lưu điểm danh'));
    await tester.pumpAndSettle();
    await scrollToTop(tester);
    expect(source.lastSaved!.map((k) => k.childId), ['child-1', 'k-02']);
    expect(find.text('Đã lưu các thay đổi điểm danh.'), findsOneWidget);
    expect(find.text('2 trẻ có thay đổi chưa lưu'), findsNothing);
    expect(saved, 1);
  });

  testWidgets('tìm theo tên và lọc Có dấu hiệu cần lưu ý', (tester) async {
    await pumpAttendance(tester);
    await tester.enterText(find.byType(TextField), 'minh anh');
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Lê Hoàng Nam'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    final noted = find.widgetWithText(AppFilterChip, 'Có dấu hiệu cần lưu ý');
    await tester.ensureVisible(noted);
    await tester.pumpAndSettle();
    await tester.tap(noted);
    await tester.pumpAndSettle();
    expect(find.text('Lê Hoàng Nam'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsNothing);
    expect(find.text('Có dị ứng'), findsOneWidget);
    final missing = find.widgetWithText(AppFilterChip, 'Chưa điểm danh');
    await tester.ensureVisible(missing);
    await tester.pumpAndSettle();
    await tester.tap(missing);
    await tester.pumpAndSettle();
    expect(find.text('Phạm Khánh Linh'), findsNothing);
  });

  testWidgets('lọc không ra trẻ ⇒ trạng thái rỗng', (tester) async {
    await pumpAttendance(tester);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy trẻ'), findsOneWidget);
  });

  testWidgets('đã khóa ⇒ chỉ xem, không có nút lưu', (tester) async {
    await pumpAttendance(tester, locked: true);
    expect(find.text('Đã khóa'), findsOneWidget);
    expect(find.text('Lưu điểm danh'), findsNothing);
    expect(find.text('Có mặt tất cả'), findsNothing);
    await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
    await scrollToTop(tester);
    expect(countOf('Có mặt'), '0');
  });

  testWidgets('lớp xem lịch sử (readOnly) ⇒ không sửa được', (tester) async {
    await pumpAttendance(
      tester,
      classes: const [
        ClassOption(
          id: FakeAttendanceSource.classId,
          name: 'Mầm 3A',
          readOnly: true,
        ),
      ],
    );
    expect(find.text('Đang xem lịch sử, không sửa được'), findsOneWidget);
    expect(find.text('Lưu điểm danh'), findsNothing);
    await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
    await scrollToTop(tester);
    expect(countOf('Có mặt'), '0');
  });

  testWidgets('ngày khác hôm nay ⇒ tải theo ngày, chỉ xem', (tester) async {
    final source = FakeAttendanceSource(delay: Duration.zero);
    await pumpAttendance(tester, source: source);
    await pickDay(tester, 11);
    expect(source.lastRequestedDate, DateTime(2026, 10, 11));
    expect(find.text('Đang xem lịch sử, không sửa được'), findsOneWidget);
    expect(find.text('Đã khóa'), findsOneWidget);
    expect(find.text('Lưu điểm danh'), findsNothing);
    expect(countOf('Chưa điểm danh'), '0');
  });

  testWidgets('đổi ngày khi còn thay đổi chưa lưu ⇒ hỏi xác nhận', (
    tester,
  ) async {
    final source = FakeAttendanceSource(delay: Duration.zero);
    await pumpAttendance(tester, source: source);
    await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
    await pickDay(tester, 11);
    expect(find.text('Đổi lớp hoặc ngày?'), findsOneWidget);
    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(source.lastRequestedDate, isNull);
    expect(find.text('Lưu điểm danh'), findsOneWidget);
    await pickDay(tester, 11);
    await tester.tap(find.text('Bỏ thay đổi và chuyển'));
    await tester.pumpAndSettle();
    expect(source.lastRequestedDate, DateTime(2026, 10, 11));
  });

  testWidgets('Lưu lỗi ⇒ banner, giữ nguyên lựa chọn, nút Lưu lại', (
    tester,
  ) async {
    var saved = false;
    await pumpAttendance(tester, failSave: true, onSaved: () => saved = true);
    await tapLabel(tester, 'Nguyễn Minh Anh: vắng');
    await tester.tap(find.text('Lưu điểm danh'));
    await tester.pumpAndSettle();
    await scrollToTop(tester);
    expect(find.text('Chưa lưu được điểm danh'), findsOneWidget);
    expect(find.text('Lưu lại'), findsOneWidget);
    expect(countOf('Vắng'), '4');
    expect(saved, isFalse);
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

  testWidgets('Lỗi tải ⇒ thử lại', (tester) async {
    await pumpAttendance(tester, mode: FakeMode.error);
    expect(find.text('Chưa tải được danh sách lớp'), findsOneWidget);
  });

  testWidgets('AC-10: chữ lớn 2.0 ở 360×800 không tràn layout', (tester) async {
    await pumpAttendance(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
