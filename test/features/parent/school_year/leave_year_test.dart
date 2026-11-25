import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';

import '../../../helpers/pump_app.dart';

Future<void> _pump(WidgetTester tester, ChildSchoolYear year) async {
  usePhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: LeaveNoticeListScreen(
        childId: 'child-1',
        source: FakeLeaveNoticeSource(delay: Duration.zero),
        year: year,
        onCreate: () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AC-4 (AUTH-03): năm đã đóng ⇒ chỉ đơn trong năm, không có nút tạo đơn',
    (tester) async {
      await _pump(
        tester,
        ChildSchoolYear(
          id: '2',
          label: '2025–2026',
          startDate: DateTime(2025, 9, 1),
          endDate: DateTime(2026, 5, 31),
          status: ChildSchoolYearStatus.closed,
          className: 'Nhà trẻ 1',
        ),
      );
      expect(find.text('13/10/2026 · Cả ngày'), findsNothing);
      expect(find.text('Chưa có đơn xin nghỉ'), findsOneWidget);
      expect(find.text('Tạo đơn xin nghỉ mới'), findsNothing);
    },
  );

  testWidgets('AC-4: năm đang chạy ⇒ đơn trong năm và nút tạo đơn', (
    tester,
  ) async {
    await _pump(
      tester,
      ChildSchoolYear(
        id: '3',
        label: '2026–2027',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2027, 5, 31),
        status: ChildSchoolYearStatus.active,
        className: 'Mầm 1',
      ),
    );
    expect(find.text('13/10/2026 · Cả ngày'), findsOneWidget);
    expect(find.text('Tạo đơn xin nghỉ mới'), findsOneWidget);
  });

  testWidgets(
    'AC-3 (ATT-05): đơn còn hiệu lực có nút Huỷ đơn, xác nhận rồi mới huỷ',
    (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: LeaveNoticeListScreen(
            childId: 'child-1',
            source: FakeLeaveNoticeSource(delay: Duration.zero),
            onCreate: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Chỉ đơn 13/10 còn ngày chưa qua (hôm nay giả 12/10); đơn cũ không huỷ được
      expect(find.text('Huỷ đơn'), findsOneWidget);

      await tester.tap(find.text('Huỷ đơn'));
      await tester.pumpAndSettle();
      expect(find.text('Huỷ đơn xin nghỉ?'), findsOneWidget);
      await tester.tap(find.text('Giữ đơn'));
      await tester.pumpAndSettle();
      expect(find.text('Huỷ đơn'), findsOneWidget);

      await tester.tap(find.text('Huỷ đơn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ đơn nghỉ'));
      await tester.pumpAndSettle();
      expect(find.text('Huỷ đơn'), findsNothing);
      expect(find.text('Đã huỷ'), findsWidgets);
    },
  );
}
