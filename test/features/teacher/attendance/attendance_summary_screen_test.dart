import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_summary_source.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/attendance_summary_screen.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpSummary(
  WidgetTester tester,
  FakeAttendanceSummarySource source, {
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: AttendanceSummaryScreen(
        classId: 'class-mam-3a',
        today: FakeParentHomeSource.today,
        source: source,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện ô tổng, theo ngày và theo trẻ; mặc định Tháng này', (
    tester,
  ) async {
    final source = FakeAttendanceSummarySource(delay: Duration.zero);
    await pumpSummary(tester, source);
    expect(source.lastFrom, DateTime(2026, 10));
    expect(source.lastTo, FakeParentHomeSource.today);
    expect(find.text('Tổng hợp điểm danh'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Ngày học: 3')), findsOneWidget);
    // 24 + 23 + 22 lượt có mặt, cộng các dòng ngày BE trả
    expect(find.bySemanticsLabel(RegExp('^Lượt có mặt: 69')), findsOneWidget);
    expect(find.text('Theo ngày'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Theo trẻ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Theo trẻ'), findsOneWidget);
  });

  testWidgets('đổi khoảng ngày ⇒ tải lại với from/to mới', (tester) async {
    final source = FakeAttendanceSummarySource(delay: Duration.zero);
    await pumpSummary(tester, source);
    final lastMonth = find.widgetWithText(AppFilterChip, 'Tháng trước');
    await tester.ensureVisible(lastMonth);
    await tester.pumpAndSettle();
    await tester.tap(lastMonth);
    await tester.pumpAndSettle();
    expect(source.lastFrom, DateTime(2026, 9));
    expect(source.lastTo, DateTime(2026, 9, 30));
  });

  testWidgets('không có ngày học ⇒ trạng thái rỗng', (tester) async {
    await pumpSummary(
      tester,
      FakeAttendanceSummarySource(mode: FakeMode.empty, delay: Duration.zero),
    );
    expect(find.text('Không có dữ liệu trong khoảng đã chọn'), findsOneWidget);
  });

  testWidgets('lỗi tải ⇒ thử lại', (tester) async {
    await pumpSummary(
      tester,
      FakeAttendanceSummarySource(mode: FakeMode.error, delay: Duration.zero),
    );
    expect(find.text('Chưa tải được tổng hợp'), findsOneWidget);
  });

  testWidgets('chữ lớn 2.0 không tràn layout', (tester) async {
    await pumpSummary(
      tester,
      FakeAttendanceSummarySource(delay: Duration.zero),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
