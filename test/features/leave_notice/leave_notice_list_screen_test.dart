import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/presentation/screens/leave_notice_form_screen.dart';
import 'package:carenest_app/features/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

import '../../helpers/pump_app.dart';

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
    'Bố cục D: chạm ngày đầu rồi ngày cuối ⇒ chọn khoảng, báo huỷ suất cả khoảng',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Tư, 14/10/2026')));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 16/10/2026')));
      await tester.pump();
      expect(find.text('Nghỉ từ 14/10 đến 16/10/2026'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Suất ăn từ 14/10 đến 16/10 sẽ được huỷ tự động'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    },
  );

  testWidgets('Bố cục D: ngày đã qua không chọn được', (tester) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 09/10/2026')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.text('Nghỉ ngày 13/10/2026'), findsOneWidget);
  });

  testWidgets('Bố cục D: ngày đã có đơn nghỉ được đánh dấu có chữ', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    expect(
      find.bySemanticsLabel('Thứ Ba, 13/10/2026, Đã báo nghỉ'),
      findsOneWidget,
    );
    expect(find.text('Ngày đã báo nghỉ'), findsOneWidget);
  });

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
