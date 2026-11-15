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

/// Cuộn tới nút theo nhãn đọc màn hình rồi bấm (danh sách dựng lười).
Future<void> tapLabel(WidgetTester tester, String label) async {
  // Nhãn khớp đầu chuỗi: node có thể gộp thêm chữ con
  final finder = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));
  await tester.scrollUntilVisible(finder, 150);
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
    'T02 (ATT-04): bé có đơn bấm Vắng vẫn là có phép; không đơn là vắng',
    (tester) async {
      await pumpAttendance(tester);
      await tapLabel(tester, 'Phạm Khánh Linh: vắng');
      await scrollToTop(tester);
      expect(countOf('Có phép'), '2');
      await tapLabel(tester, 'Nguyễn Minh Anh: vắng');
      await scrollToTop(tester);
      expect(countOf('Vắng'), '2');
    },
  );

  testWidgets('T02 (ATT-02): bấm tên bé có mặt để báo không ăn', (
    tester,
  ) async {
    await pumpAttendance(tester);
    await tapLabel(tester, 'Nguyễn Minh Anh: có mặt');
    await tapLabel(tester, 'Báo ăn cho Nguyễn Minh Anh');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Không ăn'));
    await tester.pumpAndSettle();
    expect(
      find.text('Đơn nghỉ 13/10 · Không ăn ▾', skipOffstage: false),
      findsOneWidget,
    );
  });

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
