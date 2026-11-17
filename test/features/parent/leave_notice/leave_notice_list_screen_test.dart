import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_month_calendar.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/parent/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_form_screen.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpList(
  WidgetTester tester,
  FakeLeaveNoticeSource source, {
  double textScale = 1,
  Future<void> Function()? onCreate,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: LeaveNoticeListScreen(
        childId: 'child-1',
        source: source,
        onCreate: onCreate ?? () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpForm(
  WidgetTester tester,
  FakeLeaveNoticeSource source, {
  double textScale = 1,
  VoidCallback? onSubmitted,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: LeaveNoticeFormScreen(
        child: FakeParentHomeSource.children.first,
        source: source,
        onOpenSent: () {},
        onSubmitted: onSubmitted ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder dateField(String label) => find.byWidgetPredicate(
  (widget) => widget is AppDateField && widget.label == label,
);

Finder dateValue(String label, String value) =>
    find.descendant(of: dateField(label), matching: find.text(value));

void main() {
  testWidgets(
    'AC-4 (ATT-05): P04 chỉ có GV đã xem / chưa xem, không có duyệt',
    (tester) async {
      await pumpList(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      expect(find.text('13/10/2026 · Cả ngày'), findsOneWidget);
      expect(find.text('Khám răng định kỳ'), findsOneWidget);
      expect(find.text('GV chưa xem'), findsOneWidget);
      expect(find.text('GV đã xem'), findsNWidgets(2));
      expect(find.textContaining('duyệt'), findsNothing);
      expect(find.textContaining('Từ chối'), findsNothing);
    },
  );

  testWidgets('P04: danh sách rỗng ⇒ lời mời tạo đơn', (tester) async {
    await pumpList(
      tester,
      FakeLeaveNoticeSource(mode: FakeMode.empty, delay: Duration.zero),
    );
    expect(find.text('Chưa có đơn xin nghỉ'), findsOneWidget);
  });

  testWidgets('P04: lỗi tải ⇒ Thử lại, khoá nút tạo đơn', (tester) async {
    await pumpList(
      tester,
      FakeLeaveNoticeSource(mode: FakeMode.error, delay: Duration.zero),
    );
    expect(find.text('Thử lại'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Tạo đơn xin nghỉ mới'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('P03: thiếu lý do ⇒ báo lỗi, không gửi', (tester) async {
    final source = FakeLeaveNoticeSource(delay: Duration.zero);
    var submitted = false;
    await pumpForm(tester, source, onSubmitted: () => submitted = true);
    await tester.tap(find.text('Gửi đơn xin nghỉ'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Nhập lý do nghỉ.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nhập lý do nghỉ.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets(
    'P03 (ATT-04): nghỉ cả ngày báo huỷ suất; nửa buổi không tự suy',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.scrollUntilVisible(
        find.textContaining('Suất ăn ngày 13/10 sẽ được huỷ tự động'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Cô Hà (GV lớp Mầm 3A)'), findsOneWidget);

      await tester.tap(find.text('Buổi sáng'));
      await tester.pump();
      expect(find.textContaining('Suất ăn'), findsNothing);
    },
  );

  testWidgets('P03: nhập lý do, gửi ⇒ đơn mới ở đầu danh sách, GV chưa xem', (
    tester,
  ) async {
    final source = FakeLeaveNoticeSource(delay: Duration.zero);
    var submitted = false;
    await pumpForm(tester, source, onSubmitted: () => submitted = true);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Bé đi khám mắt');
    await tester.pump();
    expect(find.text('14/500 ký tự'), findsOneWidget);
    await tester.tap(find.text('Gửi đơn xin nghỉ'));
    await tester.pumpAndSettle();
    expect(submitted, isTrue);
    // Nguồn giả dùng Future.delayed ⇒ đọc lại ngoài fake-async
    final notices = (await tester.runAsync(
      () => source.loadNotices('child-1'),
    ))!;
    expect(notices.first.reason, 'Bé đi khám mắt');
    expect(notices.first.seenByTeacher, isFalse);
  });

  testWidgets(
    'Figma PH03: Từ ngày, Đến ngày mặc định ngày mai, form không có lịch',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      expect(dateValue('Từ ngày', '13/10/2026'), findsOneWidget);
      expect(dateValue('Đến ngày', '13/10/2026'), findsOneWidget);
      expect(find.byType(AppMonthCalendar), findsNothing);
    },
  );

  testWidgets(
    'Figma PH03: chọn Từ ngày sau Đến ngày ⇒ Đến ngày theo, huỷ suất ngày mới',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.tap(dateField('Từ ngày'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ngày bắt đầu nghỉ'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Tư, 14/10/2026')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ngày bắt đầu nghỉ'), findsNothing);
      expect(dateValue('Từ ngày', '14/10/2026'), findsOneWidget);
      expect(dateValue('Đến ngày', '14/10/2026'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Suất ăn ngày 14/10 sẽ được huỷ tự động'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    },
  );

  testWidgets(
    'Figma PH03: chọn Đến ngày ⇒ nghỉ nhiều ngày, báo huỷ suất cả khoảng',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.tap(dateField('Đến ngày'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ngày kết thúc nghỉ'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 16/10/2026')));
      await tester.pumpAndSettle();
      expect(dateValue('Từ ngày', '13/10/2026'), findsOneWidget);
      expect(dateValue('Đến ngày', '16/10/2026'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Suất ăn từ 13/10 đến 16/10 sẽ được huỷ tự động'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    },
  );

  testWidgets('Figma PH03: Đến ngày không chọn được ngày trước Từ ngày', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.tap(dateField('Đến ngày'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Thứ Hai, 12/10/2026')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Chọn ngày kết thúc nghỉ'), findsOneWidget);
  });

  testWidgets('Figma PH03: Từ ngày không chọn được ngày đã qua', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.tap(dateField('Từ ngày'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 09/10/2026')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Chọn ngày bắt đầu nghỉ'), findsOneWidget);
  });

  testWidgets('Figma PH03: lịch chọn ngày đánh dấu ngày đã báo nghỉ có chữ', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.tap(dateField('Từ ngày'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Thứ Ba, 13/10/2026, Đã báo nghỉ'),
      findsOneWidget,
    );
    expect(find.text('Ngày đã báo nghỉ'), findsOneWidget);
  });

  testWidgets(
    'Figma PH03: chữ 2.0 thì hai ô ngày xếp dọc, chữ 1.0 nằm cạnh nhau',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      expect(
        tester.getTopLeft(dateField('Đến ngày')).dy,
        tester.getTopLeft(dateField('Từ ngày')).dy,
      );
      await pumpForm(
        tester,
        FakeLeaveNoticeSource(delay: Duration.zero),
        textScale: 2,
      );
      expect(
        tester.getTopLeft(dateField('Đến ngày')).dy,
        greaterThan(tester.getTopLeft(dateField('Từ ngày')).dy),
      );
    },
  );

  testWidgets('AC-10: danh sách và form chữ 2.0 không tràn', (tester) async {
    await pumpList(
      tester,
      FakeLeaveNoticeSource(delay: Duration.zero),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await pumpForm(
      tester,
      FakeLeaveNoticeSource(delay: Duration.zero),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
