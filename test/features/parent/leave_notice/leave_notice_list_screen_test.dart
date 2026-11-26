import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_month_calendar.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/parent/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/domain/leave_notice.dart';
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
    'ATT-05b: nghỉ chiều sau giờ chốt ⇒ chỉ báo cô, không hỏi ăn, không huỷ suất',
    (tester) async {
      await pumpForm(tester, _NoticeOnlySource());
      await tester.tap(find.text('Buổi chiều'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bé có ăn bữa Phụ sáng, Trưa ở trường không?'),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        find.text(
          'Đã qua giờ chốt: đơn chỉ báo cô giáo, '
          'không đổi điểm danh và suất ăn ngày 13/10.',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    },
  );

  testWidgets(
    'ATT-05b: danh sách ghi rõ đơn chỉ báo cô và ngày đã qua giờ chốt',
    (tester) async {
      await pumpList(tester, _NoticeOnlySource());
      expect(find.text('Chỉ báo cô giáo (gửi sau giờ chốt)'), findsOneWidget);
      expect(
        find.text('Ngày 13/10 đã qua giờ chốt khi gửi: giữ nguyên điểm danh'),
        findsOneWidget,
      );
      // Huỷ từ 15/10: chỉ còn hiệu lực tới 14/10
      expect(
        find.text('Hiệu lực tới 14/10 (đã huỷ phần còn lại)'),
        findsOneWidget,
      );
    },
  );

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

  testWidgets('Figma PH03: thẻ bé ghi họ tên và lớp trên hai dòng', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    expect(find.text('Bé Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Lớp Mầm 3A'), findsOneWidget);
  });

  testWidgets(
    'Figma PH03: câu huỷ suất là dòng đậm riêng, dòng sau báo cô giáo',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.scrollUntilVisible(
        find.textContaining('Cô Hà (GV lớp Mầm 3A)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Suất ăn ngày 13/10 sẽ được huỷ tự động.'),
        findsOneWidget,
      );
      expect(
        find.text('Cô Hà (GV lớp Mầm 3A) sẽ nhận được thông báo về đơn này.'),
        findsOneWidget,
      );
    },
  );

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

  testWidgets('P03 (ATT-04): nghỉ cả ngày báo huỷ suất, không hỏi ăn', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.scrollUntilVisible(
      find.textContaining('Suất ăn ngày 13/10 sẽ được huỷ tự động'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Cô Hà (GV lớp Mầm 3A)'), findsOneWidget);
    expect(find.text('Có ăn'), findsNothing);
  });

  testWidgets(
    'ATT-12: nghỉ sáng ⇒ hỏi ăn bữa Xế, mặc định có ăn, huỷ Phụ sáng + Trưa',
    (tester) async {
      await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
      await tester.tap(find.text('Buổi sáng'));
      await tester.pumpAndSettle();
      expect(find.text('Bé có ăn bữa Xế ở trường không?'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(
          'Suất Phụ sáng, Trưa ngày 13/10 sẽ được huỷ tự động, '
          'bé vẫn ăn bữa Xế ở trường.',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Không ăn'));
      await tester.pumpAndSettle();
      expect(
        find.text('Suất Phụ sáng, Trưa, Xế ngày 13/10 sẽ được huỷ tự động.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('ATT-12: nghỉ chiều ⇒ một lựa chọn cho Phụ sáng + Trưa', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.tap(find.text('Buổi chiều'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bé có ăn bữa Phụ sáng, Trưa ở trường không?'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text(
        'Suất Xế ngày 13/10 sẽ được huỷ tự động, '
        'bé vẫn ăn bữa Phụ sáng, Trưa ở trường.',
      ),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  });

  testWidgets('ATT-12: nửa buổi ⇒ Đến ngày = Từ ngày, không mở lịch', (
    tester,
  ) async {
    await pumpForm(tester, FakeLeaveNoticeSource(delay: Duration.zero));
    await tester.tap(dateField('Đến ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Thứ Sáu, 16/10/2026')));
    await tester.pumpAndSettle();
    expect(dateValue('Đến ngày', '16/10/2026'), findsOneWidget);

    await tester.tap(find.text('Buổi sáng'));
    await tester.pumpAndSettle();
    expect(dateValue('Đến ngày', '13/10/2026'), findsOneWidget);
    await tester.tap(dateField('Đến ngày'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn ngày kết thúc nghỉ'), findsNothing);
  });

  testWidgets(
    'ATT-12: gửi đơn nghỉ chiều không ăn ⇒ eats false, danh sách ghi bữa',
    (tester) async {
      final source = FakeLeaveNoticeSource(delay: Duration.zero);
      await pumpForm(tester, source);
      await tester.tap(find.text('Buổi chiều'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Không ăn'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'Bé đi khám');
      await tester.tap(find.text('Gửi đơn xin nghỉ'));
      await tester.pumpAndSettle();
      final notices = (await tester.runAsync(
        () => source.loadNotices('child-1'),
      ))!;
      expect(notices.first.eats, isFalse);

      await pumpList(tester, source);
      expect(find.text('Bé không ăn bữa Phụ sáng, Trưa'), findsOneWidget);
      // Đơn mẫu nghỉ chiều có ăn
      expect(find.text('Bé ăn bữa Phụ sáng, Trưa ở trường'), findsOneWidget);
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

  testWidgets('submit_beRejects_showsBeMessage', (tester) async {
    await pumpForm(tester, _RejectingSource());
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Bé đi khám');
    await tester.tap(find.text('Gửi đơn xin nghỉ'));
    await tester.pumpAndSettle();

    expect(find.text('Đã có đơn nghỉ trùng ngày 13/10/2026'), findsOneWidget);
  });
}

/// Nguồn giả: đã qua giờ chốt hôm nay, nghỉ chiều chỉ là báo cô giáo (ATT-05b).
class _NoticeOnlySource extends FakeLeaveNoticeSource {
  _NoticeOnlySource() : super(delay: Duration.zero);

  @override
  Future<List<LeaveNotice>> loadNotices(String childId) async => [
    LeaveNotice(
      id: 'n-1',
      childId: childId,
      from: DateTime(2026, 10, 12),
      to: DateTime(2026, 10, 12),
      session: LeaveSession.afternoon,
      reason: 'Bé mệt',
      status: LeaveNoticeStatus.submitted,
      noticeOnly: true,
    ),
    LeaveNotice(
      id: 'n-2',
      childId: childId,
      from: DateTime(2026, 10, 13),
      to: DateTime(2026, 10, 16),
      effectiveTo: DateTime(2026, 10, 14),
      skippedDates: [DateTime(2026, 10, 13)],
      session: LeaveSession.fullDay,
      reason: 'Về quê',
      status: LeaveNoticeStatus.submitted,
    ),
  ];

  @override
  Future<LeaveMealPlan> loadMealPlan(
    String childId,
    DateTime date,
    LeaveSession session,
  ) async => const LeaveMealPlan(
    offMeals: [LeaveMeal.afternoonSnack],
    keptMeals: [LeaveMeal.morningSnack, LeaveMeal.lunch],
    noticeOnly: true,
  );
}

/// Nguồn giả: BE từ chối đơn (vd. 4022 trùng ngày).
class _RejectingSource extends FakeLeaveNoticeSource {
  _RejectingSource() : super(delay: Duration.zero);

  @override
  Future<LeaveNotice> submit(LeaveNoticeDraft draft) async =>
      throw ApiFailure(409, 'Đã có đơn nghỉ trùng ngày 13/10/2026', 4022);
}
