import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpAttendance(
  WidgetTester tester, {
  FakeMode mode = FakeMode.data,
  bool failSave = false,
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: AttendanceScreen(
        classId: FakeAttendanceSource.classId,
        source: FakeAttendanceSource(
          mode: mode,
          failSave: failSave,
          delay: Duration.zero,
        ),
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

/// Danh sách chính; ô nhiệt độ cũng có Scrollable riêng nên phải chọn rõ.
final listScrollable = find.byType(Scrollable).first;

/// Cuộn tới nút theo nhãn đọc màn hình rồi bấm (danh sách dựng lười).
Future<void> tapLabel(WidgetTester tester, String label) async {
  // Nhãn khớp đầu chuỗi: node có thể gộp thêm chữ con
  final finder = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));
  await tester.scrollUntilVisible(finder, 150, scrollable: listScrollable);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Về đầu danh sách để đọc các ô đếm.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(listScrollable, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'T02 (ATT-01): thẻ lớp, giờ khoá, ô đếm theo lựa chọn đang nhập',
    (tester) async {
      await pumpAttendance(tester);
      expect(find.text('Mầm 3A · Thứ Hai, 12/10'), findsOneWidget);
      expect(find.text('Khoá lúc 08:30'), findsOneWidget);
      expect(countOf('Có mặt'), '0');
      expect(countOf('Có phép'), '2');
      expect(countOf('Vắng'), '1');
      expect(countOf('Chưa ĐD'), '25');
      expect(find.text('Lưu điểm danh (3/28)'), findsOneWidget);
    },
  );

  testWidgets('T02: đánh dấu tất cả có mặt chỉ đổi bé chưa điểm danh', (
    tester,
  ) async {
    await pumpAttendance(tester);
    await tester.tap(find.text('Đánh dấu tất cả có mặt'));
    await tester.pump();
    expect(countOf('Có mặt'), '25');
    expect(countOf('Có phép'), '2');
    expect(countOf('Vắng'), '1');
    expect(find.text('Lưu điểm danh (28/28)'), findsOneWidget);
  });

  testWidgets(
    'Redraw AC-10 (ATT-04, ATT-09): bé có đơn khóa ở Có phép (theo đơn); không đơn bấm Vắng là vắng',
    (tester) async {
      await pumpAttendance(tester);
      final locked = find.bySemanticsLabel(
        'Phạm Khánh Linh: có phép theo đơn, không đổi được',
      );
      await tester.scrollUntilVisible(locked, 150, scrollable: listScrollable);
      expect(locked, findsOneWidget);
      expect(find.bySemanticsLabel('Phạm Khánh Linh: vắng'), findsNothing);
      expect(find.bySemanticsLabel('Phạm Khánh Linh: có mặt'), findsNothing);
      expect(find.text('Có phép (theo đơn)'), findsWidgets);
      await scrollToTop(tester);
      await tester.tap(find.text('Đánh dấu tất cả có mặt'));
      await tester.pump();
      expect(countOf('Có phép'), '2');
      await tapLabel(tester, 'Nguyễn Minh Anh: vắng');
      await scrollToTop(tester);
      expect(countOf('Vắng'), '2');
      expect(countOf('Có phép'), '2');
    },
  );

  testWidgets(
    'Redraw AC-10 (ATT-02, HLT-07): không báo ăn; bé có mặt nhập nhiệt độ đầu ngày',
    (tester) async {
      await pumpAttendance(tester);
      expect(find.text('Điểm danh & nhiệt độ'), findsOneWidget);
      expect(
        find.text(
          'Chạm 1 lần cho cả lớp, rồi nhập nhiệt độ đầu ngày từng bé có mặt.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ăn 1 bữa', skipOffstage: false),
        findsNothing,
      );
      expect(find.textContaining('báo ăn', skipOffstage: false), findsNothing);
      expect(find.textContaining('Báo ăn', skipOffstage: false), findsNothing);
      // Chưa có mặt ⇒ chưa có ô nhiệt độ
      expect(find.byType(TextField), findsNothing);
      await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
      final input = find.descendant(
        of: find.byKey(const ValueKey('temperature-child-1')),
        matching: find.byType(TextField),
      );
      await tester.scrollUntilVisible(input, 150, scrollable: listScrollable);
      expect(
        find.bySemanticsLabel(RegExp('Nhiệt độ đầu ngày của Nguyễn Minh Anh')),
        findsWidgets,
      );
      await tester.enterText(input, '36,6');
      await tester.pump();
      expect(tester.widget<TextField>(input).controller!.text, '36,6');
      expect(find.text('°C'), findsOneWidget);
      await tester.enterText(input, '39.85');
      await tester.pump();
      expect(tester.widget<TextField>(input).controller!.text, '39.8');
      await tester.enterText(input, '30');
      await tester.pump();
      expect(find.text('Nhập từ 34,0 đến 42,0'), findsOneWidget);
      // Bấm Vắng ⇒ bỏ ô nhiệt độ
      await tapLabel(tester, 'Nguyễn Minh Anh: vắng');
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('Lưu lỗi ⇒ banner, giữ nguyên lựa chọn, nút Lưu lại', (
    tester,
  ) async {
    await pumpAttendance(tester, failSave: true);
    await tester.tap(find.text('Đánh dấu tất cả có mặt'));
    await tester.pump();
    await tester.tap(find.text('Lưu điểm danh (28/28)'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa lưu được điểm danh'), findsOneWidget);
    expect(find.text('Lưu lại'), findsOneWidget);
    expect(countOf('Có mặt'), '25');
  });

  testWidgets('Lưu thành công ⇒ báo đã lưu', (tester) async {
    await pumpAttendance(tester);
    await tester.tap(find.text('Lưu điểm danh (3/28)'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu điểm danh cả lớp.'), findsOneWidget);
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
