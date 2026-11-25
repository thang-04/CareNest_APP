import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/child_activities_screen.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/child_attendance_screen.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/my_child_screen.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent/parent_menu/presentation/screens/weekly_menu_screen.dart';

import '../../../helpers/pump_app.dart';

final today = DateTime(2026, 10, 12);

/// Lần tải đầu lỗi, các lần sau trả dữ liệu giả — để thử "Thử lại".
class _FlakySource extends FakeMyChildSource {
  _FlakySource();

  var _calls = 0;

  @override
  Future<ChildProfile> loadProfile(String childId) {
    _calls++;
    if (_calls == 1) {
      return Future.error(StateError('Không tải được dữ liệu giả'));
    }
    return super.loadProfile(childId);
  }
}

/// Mọi mục khai báo sức khỏe là "chưa cung cấp" (BE `NOT_PROVIDED`).
class _NotProvidedSource extends FakeMyChildSource {
  const _NotProvidedSource();

  @override
  Future<ChildProfile> loadProfile(String childId) async {
    final base = await super.loadProfile(childId);
    return ChildProfile(
      fullName: base.fullName,
      className: base.className,
      ageLabel: base.ageLabel,
      schoolYear: base.schoolYear,
      birthDate: base.birthDate,
      gender: base.gender,
      campus: base.campus,
      teachers: base.teachers,
      health: const DeclaredHealth(
        allergyState: DeclarationState.notProvided,
        diet: DeclaredItem.notProvided(),
        selfHistory: DeclaredItem.notProvided(),
        familyHistory: DeclaredItem.notProvided(),
      ),
      guardians: base.guardians,
    );
  }
}

/// Dữ liệu như phiên thật (BE 25/11): số nửa ngày, chưa có tổng suất huỷ, tên năm học, SĐT.
class _LiveShapeSource extends FakeMyChildSource {
  const _LiveShapeSource();

  @override
  Future<AttendanceMonth> loadAttendance(
    String childId, {
    ChildSchoolYear? year,
  }) async => AttendanceMonth(
    month: DateTime(2026, 10),
    presentCount: 8.5,
    excusedCount: 0.5,
    absentCount: 0,
    days: [
      AttendanceDay(
        date: DateTime(2026, 10, 12),
        status: AttendanceDayStatus.present,
        absentPart: AbsentPart.morning,
        healthLine: '37,8 °C · Sốt',
        healthNote: 'Cô đã báo mẹ',
      ),
    ],
  );

  @override
  Future<ChildProfile> loadProfile(String childId) async => const ChildProfile(
    fullName: 'Trần Bảo Ngọc',
    className: 'Mẫu giáo 3A',
    birthDate: '14/03/2022',
    gender: 'Nữ',
    health: DeclaredHealth(
      allergyState: DeclarationState.notProvided,
      diet: DeclaredItem.notProvided(),
      selfHistory: DeclaredItem.notProvided(),
      familyHistory: DeclaredItem.notProvided(),
    ),
    guardians: [Guardian(relation: 'Mẹ', name: 'Thu Lan')],
  );
}

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
  bool inScaffold = false,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: inScaffold ? Scaffold(body: screen) : screen,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(SelectedChild.reset);

  testWidgets(
    'Bé của tôi = hồ sơ của bé: thẻ đầu, thông tin chung, cô chủ nhiệm, '
    'sức khỏe đã khai báo, người đưa đón',
    (tester) async {
      await pumpScreen(tester, const MyChildScreen(), inScaffold: true);
      expect(find.text('Bé của tôi'), findsOneWidget);
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      expect(find.text('Mầm 3A · 4 tuổi'), findsOneWidget);
      // Năm học ở hồ sơ và ở ô Năm học (năm đang chạy)
      expect(find.text('Năm học 2026–2027'), findsNWidgets(2));
      // User 18/11: không thanh chọn bé, không nút Gọi cô / Hồ sơ của bé, bỏ hành trình năm học
      expect(find.text('Bảo Ngọc'), findsNothing);
      expect(find.text('Gọi cô'), findsNothing);
      expect(find.text('Hồ sơ của bé'), findsNothing);
      expect(find.text('Hành trình năm học'), findsNothing);

      expect(find.text('14/03/2022 (4 tuổi)'), findsOneWidget);
      expect(find.text('Cơ sở chính – Thượng Hồng'), findsOneWidget);
      expect(find.text('Cô Trần Thu Hà · Cô Lê Mai'), findsOneWidget);
      expect(find.byTooltip('Gọi giáo viên chủ nhiệm'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Tiền sử gia đình'), 200);
      expect(find.text('Sức khỏe đã khai báo'), findsOneWidget);
      // Dị ứng và tiền sử bản thân đều "Không"; tiền sử có bệnh ghi như web
      expect(find.text('Không'), findsNWidgets(2));
      expect(find.text('Bình thường'), findsOneWidget);
      expect(find.text('Có — Tăng huyết áp'), findsOneWidget);
      expect(find.byType(AppStatusBadge), findsNothing);

      await tester.scrollUntilVisible(
        find.textContaining('Thông tin do nhà trường quản lý'),
        200,
      );
      expect(find.text('Mẹ – Thu Lan'), findsOneWidget);
      expect(find.text('0912 345 678'), findsOneWidget);
      expect(find.text('Bố – Văn Hùng'), findsOneWidget);
    },
  );

  testWidgets(
    'Đổi bé ở Trang chủ ⇒ hồ sơ đổi theo; bé có dị ứng hiện chip, tiền sử',
    (tester) async {
      await pumpScreen(tester, const MyChildScreen(), inScaffold: true);
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      SelectedChild.notifier.value = 'child-2';
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Hoàng Bảo Ngọc'), findsOneWidget);
      expect(find.text('Lá 1 · 5 tuổi'), findsOneWidget);
      expect(find.text('Cô Vũ Minh Thư'), findsOneWidget);
      expect(find.widgetWithText(AppStatusBadge, 'Hải sản'), findsOneWidget);
      expect(find.text('Suất thay thế'), findsOneWidget);
      expect(find.text('Có — Hen phế quản'), findsOneWidget);
    },
  );

  testWidgets('Khai báo chưa cung cấp ⇒ "Chưa cung cấp" ở cả bốn mục', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const MyChildScreen(source: _NotProvidedSource()),
      inScaffold: true,
    );
    expect(find.text('Chưa cung cấp'), findsNWidgets(4));
  });

  testWidgets('Lỗi tải ⇒ báo lỗi, "Thử lại" tải lại hồ sơ', (tester) async {
    await pumpScreen(
      tester,
      MyChildScreen(source: _FlakySource()),
      inScaffold: true,
    );
    expect(find.text('Chưa tải được thông tin của bé'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
  });

  testWidgets('Chữ 1,3 và 2,0 với bé có dị ứng: không tràn', (tester) async {
    SelectedChild.notifier.value = 'child-2';
    for (final scale in [1.3, 2.0]) {
      await pumpScreen(
        tester,
        MyChildScreen(key: UniqueKey()),
        textScale: scale,
        inScaffold: true,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('P09 / AC-9: ảnh hoạt động là khối giữ chỗ, có "+1"', (
    tester,
  ) async {
    await pumpScreen(tester, const ChildActivitiesScreen(childId: 'child-1'));
    expect(find.text('Hành vi tốt'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('+1'), 200);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('P10: số đếm tháng, chọn ngày nghỉ có phép hiện suất đã huỷ', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ChildAttendanceScreen(childId: 'child-1', initialDay: today),
    );
    expect(find.bySemanticsLabel('Có mặt: 8'), findsOneWidget);
    expect(find.bySemanticsLabel('Suất huỷ: 1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Thứ Ba, 13/10/2026, Nghỉ có phép'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Đã huỷ theo đơn xin nghỉ',
        findRichText: true,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('attendance_live_halfDayCountsAndDailyHealth', (tester) async {
    await pumpScreen(
      tester,
      ChildAttendanceScreen(
        childId: 'child-1',
        initialDay: today,
        source: const _LiveShapeSource(),
      ),
    );
    // ATT-14: nửa buổi = 0,5 ngày; BE chưa trả tổng suất huỷ ⇒ không có ô
    expect(find.bySemanticsLabel('Có mặt: 8,5'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Suất huỷ')), findsNothing);
    expect(
      find.textContaining('Buổi sáng', findRichText: true, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        '37,8 °C · Sốt',
        findRichText: true,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Cô đã báo mẹ',
        findRichText: true,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('profile_live_hidesSchoolYearAndMissingPhone', (tester) async {
    SelectedChild.notifier.value = 'c-1';
    await pumpScreen(
      tester,
      const MyChildScreen(
        source: _LiveShapeSource(),
        yearSource: _NoYearSource(),
      ),
      inScaffold: true,
    );
    expect(find.textContaining('Năm học'), findsNothing);
    await tester.scrollUntilVisible(find.text('Mẹ – Thu Lan'), 200);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets(
    'P05: đổi ngày trong tuần, hôm nay có ảnh mẫu bếp đăng theo bữa',
    (tester) async {
      await pumpScreen(
        tester,
        WeeklyMenuScreen(childId: 'child-1', initialDay: today),
      );
      expect(find.textContaining('Cháo thịt bằm'), findsOneWidget);
      expect(find.text('Ảnh mẫu nhóm Mầm · Bếp đăng 07:50'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ảnh mẫu nhóm Mầm · Bếp đăng 10:52'),
        200,
      );
      expect(find.byType(Image), findsNothing);

      await tester.scrollUntilVisible(find.text('T3'), -200);
      await tester.tap(find.text('T3'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bún bò'), findsOneWidget);
      expect(find.textContaining('Ảnh mẫu nhóm'), findsNothing);
    },
  );

  testWidgets('P05: bé có dị ứng ⇒ cảnh báo suất thay thế', (tester) async {
    await pumpScreen(
      tester,
      WeeklyMenuScreen(childId: 'child-2', initialDay: today),
    );
    await tester.scrollUntilVisible(find.textContaining('dị ứng hải sản'), 200);
  });

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    ('Bé của tôi', const MyChildScreen(), true),
    ('Hoạt động', const ChildActivitiesScreen(childId: 'child-1'), false),
    (
      'Điểm danh',
      ChildAttendanceScreen(childId: 'child-1', initialDay: today),
      false,
    ),
    (
      'Thực đơn',
      WeeklyMenuScreen(childId: 'child-1', initialDay: today),
      false,
    ),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}

/// Bé chưa có năm học ⇒ không có ô Năm học (để kiểm hồ sơ không tự ghi năm học).
class _NoYearSource implements ChildSchoolYearSource {
  const _NoYearSource();

  @override
  Future<List<ChildSchoolYear>> loadYears(String childId) async => const [];
}
