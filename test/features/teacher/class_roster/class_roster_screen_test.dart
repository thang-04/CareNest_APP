import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/child_health.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/teacher/class_roster/presentation/screens/class_roster_screen.dart';

import '../../../helpers/pump_app.dart';

class _Roster implements ClassRosterSource {
  @override
  Future<ClassRoster> loadRoster(String classId) async => ClassRoster(
    classId: classId,
    className: 'Mầm 3A',
    campusName: '',
    kids: [
      RosterKid(
        id: '1',
        fullName: 'Nguyễn Minh Anh',
        ageLabel: '4 tuổi',
        guardianLine: 'Mẹ: 0912345678',
        dateOfBirth: DateTime(2022, 3, 14),
      ),
      const RosterKid(
        id: '2',
        fullName: 'Lê Hoàng Nam',
        ageLabel: '5 tuổi',
        guardianLine: 'Bố: 0900000001',
        status: RosterKidStatus.pendingPlacement,
      ),
      const RosterKid(
        id: '3',
        fullName: 'Phạm Khánh Linh',
        ageLabel: '4 tuổi',
        guardianLine: '',
        status: RosterKidStatus.left,
      ),
    ],
  );
}

class _Health implements ChildHealthSource {
  _Health(this.entries, {this.fail = false});

  final List<HealthEntry> entries;
  final bool fail;

  @override
  Future<ChildHealthHistory> load(String childId) async {
    if (fail) throw StateError('lỗi');
    return ChildHealthHistory(childId: childId, entries: entries);
  }
}

Future<void> pumpRoster(
  WidgetTester tester, {
  ChildHealthSource? health,
}) async {
  usePhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: ClassRosterScreen(
          classId: 'c',
          source: _Roster(),
          childHealthSource: health,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

HealthEntry _entry(int month, double h, double w) => HealthEntry(
  date: DateTime(2026, month, 5),
  title: 'Kỳ cân đo $month',
  kindLabel: 'Kỳ cân đo',
  heightCm: h,
  weightKg: w,
  bmi: 15.9,
  warningLabel: 'Bình thường',
);

void main() {
  testWidgets(
    'Danh sách trẻ: chip trạng thái có số, dòng có ngày sinh, phụ huynh',
    (tester) async {
      await pumpRoster(tester);
      expect(find.textContaining('Danh sách trẻ'), findsOneWidget);
      expect(find.text('Tổng số trẻ 3'), findsOneWidget);
      expect(find.text('Đang học 1'), findsOneWidget);
      expect(find.text('Chờ xếp lớp 1'), findsOneWidget);
      expect(find.text('Đã nghỉ học 1'), findsOneWidget);
      expect(find.textContaining('Ngày sinh 14/03/2022'), findsOneWidget);
      expect(find.text('Phụ huynh Mẹ: 0912345678'), findsOneWidget);
    },
  );

  testWidgets('Lọc theo trạng thái và tìm không dấu', (tester) async {
    await pumpRoster(tester);
    await tester.tap(find.text('Chờ xếp lớp 1'));
    await tester.pump();
    expect(find.text('Lê Hoàng Nam'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsNothing);
    await tester.tap(find.text('Tổng số trẻ 3'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'khanh linh');
    await tester.pump();
    expect(find.text('Phạm Khánh Linh'), findsOneWidget);
    expect(find.text('Lê Hoàng Nam'), findsNothing);
  });

  testWidgets('Chạm trẻ ⇒ biểu đồ và bảng số liệu, lịch sử khám cân đo', (
    tester,
  ) async {
    await pumpRoster(
      tester,
      health: _Health([_entry(9, 104, 17.2), _entry(6, 101.5, 16.4)]),
    );
    await tester.tap(find.text('Nguyễn Minh Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Xu hướng sức khỏe'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Chiều cao (cm)'), findsOneWidget);
    expect(find.text('Cân nặng (kg)'), findsOneWidget);
    await tester.tap(find.text('Bảng số liệu'));
    await tester.pumpAndSettle();
    for (final head in [
      'Ngày đo',
      'Chiều cao',
      'Cân nặng',
      'BMI',
      'Cảnh báo',
    ]) {
      expect(find.text(head), findsOneWidget, reason: head);
    }
    expect(find.text('104'), findsOneWidget);
    expect(find.text('17,2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lịch sử khám, cân đo'), 300);
    expect(find.textContaining('Chỉnh sửa'), findsNothing);
  });

  testWidgets('Trẻ chưa có số đo ⇒ trạng thái rỗng; lỗi ⇒ Thử lại', (
    tester,
  ) async {
    await pumpRoster(tester, health: _Health(const []));
    await tester.tap(find.text('Nguyễn Minh Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có số đo'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await pumpRoster(tester, health: _Health(const [], fail: true));
    await tester.tap(find.text('Nguyễn Minh Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
