import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/widgets/parent_home_cards.dart';

import '../../../helpers/pump_app.dart';

/// Nguồn giả với danh sách con tuỳ chọn (1, 2 hoặc 3 bé) để kiểm phần "ló ra".
class _ChildrenSource implements ParentHomeSource {
  _ChildrenSource(this.children);

  final List<ChildSummary> children;
  final _base = FakeParentHomeSource(delay: Duration.zero);

  @override
  Future<List<ChildSummary>> loadChildren() async => children;

  @override
  Future<ParentToday> loadToday(String childId) async {
    final today = await _base.loadToday(FakeParentHomeSource.children[0].id);
    final child = children.firstWhere((item) => item.id == childId);
    return ParentToday(
      greetingName: today.greetingName,
      date: today.date,
      child: child,
      attendance: today.attendance,
      arrivedAt: today.arrivedAt,
      unreadNotifications: today.unreadNotifications,
      menuPublished: today.menuPublished,
      activityTitle: today.activityTitle,
    );
  }
}

/// Hôm nay cố định (phiên thật): bé chỉ có tên, lớp — BE chưa trả điểm trường, tuổi, GV.
class _TodaySource implements ParentHomeSource {
  _TodaySource({
    this.attendance = ParentAttendanceStatus.notRecorded,
    this.absentPart,
    this.afternoonNoticeSent = false,
  });

  final ParentAttendanceStatus attendance;
  final AbsentPart? absentPart;
  final bool afternoonNoticeSent;

  static const child = ChildSummary(
    id: 'c-1',
    fullName: 'Trần Bảo Ngọc',
    shortName: 'Bảo Ngọc',
    className: 'Mẫu giáo 3A',
  );

  @override
  Future<List<ChildSummary>> loadChildren() async => const [child];

  @override
  Future<ParentToday> loadToday(String childId) async => ParentToday(
    greetingName: 'Phụ huynh',
    date: DateTime(2026, 11, 25),
    child: child,
    attendance: attendance,
    absentPart: absentPart,
    afternoonNoticeSent: afternoonNoticeSent,
    unreadNotifications: 0,
  );
}

/// Hôm nay bị BE từ chối (403): con không còn thuộc tài khoản.
class _ForbiddenTodaySource extends _TodaySource {
  @override
  Future<ParentToday> loadToday(String childId) => Future.error(
    ApiFailure(403, 'Bạn chỉ xem được thông tin của con mình', 4108),
  );
}

const _thirdChild = ChildSummary(
  id: 'child-3',
  fullName: 'Nguyễn Gia Khang',
  shortName: 'Gia Khang',
  className: 'Nhà trẻ 1B',
  campusName: 'Cơ sở chính – Thượng Hồng',
  ageLabel: '2 tuổi',
  homeroomTeacher: 'Cô Lan',
);

Future<void> pumpParentHome(
  WidgetTester tester,
  FakeMode mode, {
  double textScale = 1,
  ParentHomeSource? source,
  bool live = false,
  VoidCallback? onSwitchToTeacher,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: ParentHomeScreen(
          source:
              source ?? FakeParentHomeSource(mode: mode, delay: Duration.zero),
          live: live,
          onSwitchToTeacher: onSwitchToTeacher,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(SelectedChild.reset);

  testWidgets(
    'Nút "Giáo viên" chỉ khi kiêm GV, chạm ⇒ chuyển chế độ (AUTH-21)',
    (tester) async {
      await pumpParentHome(tester, FakeMode.data);
      expect(find.text('Giáo viên'), findsNothing);

      var switched = false;
      await pumpParentHome(
        tester,
        FakeMode.data,
        onSwitchToTeacher: () => switched = true,
      );
      await tester.tap(find.text('Giáo viên'));
      expect(switched, isTrue);
    },
  );

  testWidgets('Bố cục H (PAR-01): lời chào → thẻ bé → Việc nhanh', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.data);
    expect(find.text('Chị Nguyễn Thu Lan'), findsOneWidget);
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Mầm 3A · 4 tuổi'), findsOneWidget);
    expect(find.text('Có mặt'), findsOneWidget);
    expect(find.bySemanticsLabel('Điểm danh: 07:42'), findsOneWidget);
    expect(find.bySemanticsLabel('Thực đơn: Đã công bố'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Hoạt động: Tô màu chiếc lá mùa thu'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Thông báo, 2 chưa đọc'), findsOneWidget);

    double top(Finder finder) => tester.getTopLeft(finder).dy;
    expect(
      top(find.text('Chị Nguyễn Thu Lan')),
      lessThan(top(find.text('Minh Anh'))),
    );
    await tester.scrollUntilVisible(find.text('Sổ sức khỏe'), 200);
    expect(top(find.text('Minh Anh')), lessThan(top(find.text('Việc nhanh'))));
    for (final label in [
      'Xin nghỉ cho bé',
      'Hoạt động & đánh giá',
      'Thực đơn tuần',
      'Sổ sức khỏe',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // Hàng cuối: Đánh giá và Khen thưởng mở trang riêng (user 18/11)
    await tester.scrollUntilVisible(find.text('Khen thưởng'), 200);
    expect(find.text('Đánh giá'), findsOneWidget);
  });

  testWidgets('Hai bé (AUTH-04): chạm phần ló để đổi sang bé kia', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.data);
    expect(find.text('Bảo Ngọc · Lá 1'), findsOneWidget);
    await tester.tap(find.text('Bảo Ngọc · Lá 1'));
    await tester.pumpAndSettle();
    expect(SelectedChild.notifier.value, 'child-2');
    expect(find.text('Bảo Ngọc'), findsOneWidget);
    expect(find.text('Minh Anh · Mầm 3A'), findsOneWidget);
  });

  testWidgets('Ba bé: phần ló ghi "+2 bé khác" và mở sheet chọn bé', (
    tester,
  ) async {
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _ChildrenSource([...FakeParentHomeSource.children, _thirdChild]),
    );
    expect(find.text('+2 bé khác'), findsOneWidget);
    await tester.tap(find.text('+2 bé khác'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn bé'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Gia Khang'));
    await tester.pumpAndSettle();
    expect(SelectedChild.notifier.value, 'child-3');
    expect(find.text('Gia Khang'), findsOneWidget);
  });

  testWidgets('Một bé: không có phần ló', (tester) async {
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _ChildrenSource([FakeParentHomeSource.children.first]),
    );
    expect(find.byType(OtherChildrenPeek), findsNothing);
    expect(find.text('Minh Anh'), findsOneWidget);
  });

  testWidgets('Dữ liệu rỗng ⇒ Chưa điểm danh, thực đơn chưa công bố', (
    tester,
  ) async {
    await pumpParentHome(tester, FakeMode.empty);
    expect(find.bySemanticsLabel('Điểm danh: Chưa điểm danh'), findsOneWidget);
    expect(find.bySemanticsLabel('Thực đơn: Chưa công bố'), findsOneWidget);
    expect(find.bySemanticsLabel('Hoạt động: Chưa có'), findsOneWidget);
  });

  testWidgets('parentHome_noSchool_showsLabel', (tester) async {
    SelectedChild.notifier.value = 'c-1';
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _TodaySource(attendance: ParentAttendanceStatus.noSchool),
    );
    expect(
      find.bySemanticsLabel('Điểm danh: Không phải ngày học'),
      findsOneWidget,
    );
  });

  testWidgets('parentHome_live_hidesCampusAndAge', (tester) async {
    SelectedChild.notifier.value = 'c-1';
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _TodaySource(),
      live: true,
    );
    // BE chưa trả tuổi ⇒ chỉ tên lớp, không có " · " thừa
    expect(find.text('Mẫu giáo 3A'), findsOneWidget);
  });

  testWidgets('parentHome_live_menuStatus_activityOpens', (tester) async {
    SelectedChild.notifier.value = 'c-1';
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _TodaySource(),
      live: true,
    );
    // Thực đơn theo cờ BE (PAR-14), không còn "Sắp có"; hoạt động mời mở màn
    expect(find.bySemanticsLabel('Thực đơn: Sắp có'), findsNothing);
    expect(find.bySemanticsLabel('Hoạt động: Xem'), findsOneWidget);
  });

  testWidgets('parentHome_halfDay_showsAbsentPart', (tester) async {
    SelectedChild.notifier.value = 'c-1';
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _TodaySource(
        attendance: ParentAttendanceStatus.present,
        absentPart: AbsentPart.morning,
      ),
    );
    expect(find.text('Nghỉ buổi sáng theo đơn'), findsOneWidget);
  });

  testWidgets('parentHome_noticeOnlyAfternoon_showsLine (ATT-05b)', (
    tester,
  ) async {
    SelectedChild.notifier.value = 'c-1';
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _TodaySource(
        attendance: ParentAttendanceStatus.present,
        afternoonNoticeSent: true,
      ),
    );
    expect(find.text('Đã báo cô nghỉ buổi chiều'), findsOneWidget);
  });

  testWidgets('parentHome_403_showsBeReason', (tester) async {
    SelectedChild.notifier.value = 'c-1';
    await pumpParentHome(
      tester,
      FakeMode.data,
      source: _ForbiddenTodaySource(),
    );
    expect(
      find.text('Bạn chỉ xem được thông tin của con mình'),
      findsOneWidget,
    );
  });

  testWidgets('Lỗi tải ⇒ trạng thái lỗi có Thử lại', (tester) async {
    await pumpParentHome(tester, FakeMode.error);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('Đang tải ⇒ khung chờ', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: ParentHomeScreen(source: FakeParentHomeSource())),
      ),
    );
    expect(find.byType(AppSkeletonCard), findsWidgets);
    await tester.pumpAndSettle();
  });

  testWidgets('AC-5: khổ 320 xếp dọc ba ô hôm nay, không tràn', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: ParentHomeScreen(
            source: FakeParentHomeSource(delay: Duration.zero),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    double top(String label) =>
        tester.getTopLeft(find.bySemanticsLabel(RegExp('^$label:'))).dy;
    expect(top('Điểm danh'), lessThan(top('Thực đơn')));
  });

  testWidgets('AC-5: chữ lớn 2.0 ở 360×800 không tràn layout', (tester) async {
    await pumpParentHome(tester, FakeMode.data, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
