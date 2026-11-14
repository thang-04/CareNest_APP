import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/leave_notice/presentation/screens/leave_notice_form_screen.dart';
import 'package:carenest_app/features/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpList(
  WidgetTester tester,
  LeaveNoticeSource source, {
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
    'Redraw AC-3 (ATT-05): P04 không GV đã xem, không duyệt; đơn còn hủy được có Hủy đơn',
    (tester) async {
      await pumpList(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      expect(find.text('13/10/2026'), findsOneWidget);
      expect(find.text('Khám răng định kỳ'), findsOneWidget);
      expect(find.text('Đã gửi'), findsNWidgets(2));
      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.textContaining('GV đã xem'), findsNothing);
      expect(find.textContaining('GV chưa xem'), findsNothing);
      expect(find.textContaining('duyệt'), findsNothing);
      expect(find.textContaining('Từ chối'), findsNothing);
      expect(find.textContaining('huỷ suất'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Hủy đơn'), findsOneWidget);
      expect(
        find.text(
          'Hủy đơn được cho các ngày chưa qua giờ chốt; ngày đã qua giờ chốt vẫn ghi Vắng có phép.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Redraw AC-3: Hủy đơn ⇒ xác nhận ⇒ đơn hiện Đã hủy', (
    tester,
  ) async {
    final source = FakeLeaveNoticeSource(delay: Duration.zero);
    await pumpList(tester, source);
    await tester.tap(find.text('Hủy đơn'));
    await tester.pumpAndSettle();
    expect(find.text('Hủy đơn nghỉ 13/10/2026?'), findsOneWidget);
    await tester.tap(find.text('Hủy đơn').last);
    await tester.pumpAndSettle();
    expect(find.text('Đã hủy'), findsNWidgets(2));
    expect(find.text('Hủy đơn'), findsNothing);
    final notices = (await tester.runAsync(
      () => source.loadNotices('child-1'),
    ))!;
    expect(notices.first.status, LeaveNoticeStatus.cancelled);
  });

  LeaveNotice notice(String id, DateTime from, DateTime to) => LeaveNotice(
    id: id,
    childId: 'child-1',
    from: from,
    to: to,
    reason: 'Bé ốm',
    status: LeaveNoticeStatus.submitted,
  );

  testWidgets(
    'Plan 14/11 AC-3 (ATT-04): đơn 3 ngày đã qua 1 ngày ⇒ hủy phần còn lại, ngày đã qua vẫn nghỉ có phép',
    (tester) async {
      final source = FakeLeaveNoticeSource(
        delay: Duration.zero,
        notices: [
          notice('p-1', DateTime(2026, 10, 11), DateTime(2026, 10, 13)),
        ],
      );
      await pumpList(tester, source);
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Đơn được hủy từ ngày đầu tiên chưa qua giờ chốt. Ngày đã qua giờ chốt vẫn ghi Vắng có phép.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Hủy đơn').last);
      await tester.pumpAndSettle();
      expect(find.text('Hủy từ 12/10'), findsOneWidget);
      expect(find.text('Vẫn nghỉ có phép: 11/10/2026'), findsOneWidget);
      expect(find.text('Hủy đơn'), findsNothing);
      final saved = (await tester.runAsync(
        () => source.loadNotices('child-1'),
      ))!;
      expect(saved.single.status, LeaveNoticeStatus.submitted);
      expect(saved.single.effectiveTo, DateTime(2026, 10, 11));
    },
  );

  testWidgets('Plan 14/11 AC-3: đơn đã qua hết ⇒ không có nút hủy', (
    tester,
  ) async {
    await pumpList(
      tester,
      FakeLeaveNoticeSource(
        delay: Duration.zero,
        notices: [notice('p-2', DateTime(2026, 10, 8), DateTime(2026, 10, 9))],
      ),
    );
    expect(find.text('Đã gửi'), findsOneWidget);
    expect(find.text('Hủy đơn'), findsNothing);
  });

  testWidgets(
    'Plan 14/11 AC-3: BE báo qua giờ chốt ⇒ thông báo không hủy được',
    (tester) async {
      await pumpList(tester, _CannotCancelSource());
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy đơn').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Các ngày của đơn đã qua giờ chốt, không hủy được.'),
        findsOneWidget,
      );
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
    'Redraw AC-2 (ATT-04, ATT-05): không chọn buổi; ghi chú Vắng có phép, tối đa 30 ngày',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.scrollUntilVisible(
        find.textContaining(
          'Ngày nghỉ ghi Vắng có phép. Tối đa 30 ngày mỗi đơn.',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Cô Hà (GV lớp Mầm 3A)'), findsOneWidget);
      expect(find.text('Buổi nghỉ'), findsNothing);
      expect(find.text('Buổi sáng'), findsNothing);
      expect(find.text('Cả ngày'), findsNothing);
      expect(find.textContaining('Suất ăn'), findsNothing);
    },
  );

  testWidgets('Redraw AC-2 (ATT-05): khoảng quá 30 ngày ⇒ báo lỗi, không gửi', (
    tester,
  ) async {
    var submitted = false;
    await pumpForm(
      tester,
      FakeLeaveNoticeSource(delay: Duration.zero),
      onSubmitted: () => submitted = true,
    );
    await tester.tap(find.widgetWithText(AppDateField, 'Đến ngày *'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tháng sau'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 13/11/2026')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Về quê');
    await tester.tap(find.text('Gửi đơn xin nghỉ'));
    await tester.pumpAndSettle();
    expect(submitted, isFalse);
    expect(
      find.text('Mỗi đơn tối đa 30 ngày. Chọn lại ngày kết thúc.'),
      findsOneWidget,
    );
  });

  testWidgets('P03: nhập lý do, gửi ⇒ đơn mới ở đầu danh sách, còn hủy được', (
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
    expect(notices.first.status, LeaveNoticeStatus.submitted);
    expect(notices.first.canCancel, isTrue);
  });

  testWidgets('Figma PH03: Từ ngày / Đến ngày mở lịch chọn khoảng', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    expect(find.text('Bé Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Lớp Mầm 3A'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppDateField, 'Từ ngày *'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Tư, 14/10/2026')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppDateField, 'Đến ngày *'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 16/10/2026')));
    await tester.pumpAndSettle();
    expect(find.text('14/10/2026'), findsOneWidget);
    expect(find.text('16/10/2026'), findsOneWidget);
  });

  testWidgets('Figma PH03: ngày đã qua không chọn được', (tester) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.tap(find.widgetWithText(AppDateField, 'Từ ngày *'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 09/10/2026')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Chọn ngày bắt đầu nghỉ'), findsOneWidget);
    expect(find.text('13/10/2026'), findsNWidgets(2));
  });

  testWidgets(
    'Figma PH03: lịch chọn ngày đánh dấu ngày đã có đơn nghỉ có chữ',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.tap(find.widgetWithText(AppDateField, 'Từ ngày *'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Thứ Ba, 13/10/2026, Đã báo nghỉ'),
        findsOneWidget,
      );
      expect(find.text('Ngày đã báo nghỉ'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(AppDateField, 'Từ ngày *'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn ngày bắt đầu nghỉ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// BE trả 409 `LEAVE_CANNOT_CANCEL` dù App còn hiện nút (giờ chốt do BE quyết định).
class _CannotCancelSource implements LeaveNoticeSource {
  final _notice = LeaveNotice(
    id: 'p-3',
    childId: 'child-1',
    from: DateTime(2026, 10, 12),
    to: DateTime(2026, 10, 12),
    reason: 'Bé ốm',
    status: LeaveNoticeStatus.submitted,
    canCancel: true,
  );

  @override
  DateTime get today => DateTime(2026, 10, 12);

  @override
  Future<List<LeaveNotice>> loadNotices(String childId) async => [_notice];

  @override
  Future<LeaveNotice> submit(LeaveNoticeDraft draft) =>
      throw UnimplementedError();

  @override
  Future<LeaveNotice> cancel(String noticeId) async =>
      throw const LeaveCannotCancelException();
}
