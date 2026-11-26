import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/teacher/class_roster/data/live_teacher_classes.dart';
import 'package:carenest_app/features/teacher/school_year/data/fake_school_year_source.dart';
import 'package:carenest_app/features/teacher/school_year/domain/school_year.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';
import 'package:carenest_app/routing/teacher_sources.dart';

void main() {
  const active = SchoolYear(
    id: '9',
    label: '2026–2027',
    status: SchoolYearStatus.active,
    className: 'Mầm 3A',
  );
  const closed = SchoolYear(
    id: '5',
    label: '2025–2026',
    status: SchoolYearStatus.closed,
    className: 'Nhà trẻ 2',
  );
  const planned = SchoolYear(
    id: '11',
    label: '2027–2028',
    status: SchoolYearStatus.planned,
    className: '',
  );

  tearDown(SelectedSchoolYear.reset);

  Future<List<TeacherClass>> byYear(String? yearId) async => switch (yearId) {
    null => [
      const TeacherClass(
        id: '12',
        name: 'Mầm 3A',
        teaches: true,
        canRecord: true,
      ),
    ],
    '5' => [
      const TeacherClass(id: '7', name: 'Nhà trẻ 2', historicalReadOnly: true),
    ],
    _ => const [],
  };

  Future<void> pump(
    WidgetTester tester,
    List<String?> requested,
    List<ClassOption> seen,
  ) async {
    SelectedSchoolYear.notifier.value = active;
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherClassGate(
          sources: TeacherSources(
            live: true,
            loadYearClasses: (id) {
              requested.add(id);
              return byYear(id);
            },
          ),
          builder: (classId, classes) {
            seen
              ..clear()
              ..addAll(classes);
            return Text('class $classId');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('activeYear_loadsWithoutYearIdAndIsEditable', (tester) async {
    final requested = <String?>[];
    final seen = <ClassOption>[];
    await pump(tester, requested, seen);
    expect(requested, [null]);
    expect(find.text('class 12'), findsOneWidget);
    expect(seen.single.readOnly, isFalse);
  });

  testWidgets('closedYear_reloadsThatYearsClassAsReadOnly', (tester) async {
    final requested = <String?>[];
    final seen = <ClassOption>[];
    await pump(tester, requested, seen);
    SelectedSchoolYear.notifier.value = closed;
    await tester.pumpAndSettle();
    expect(requested, [null, '5']);
    expect(find.text('class 7'), findsOneWidget);
    expect(seen.single.readOnly, isTrue);

    SelectedSchoolYear.notifier.value = active;
    await tester.pumpAndSettle();
    expect(find.text('class 12'), findsOneWidget);
    expect(seen.single.readOnly, isFalse);
  });

  testWidgets('yearWithoutClass_showsEmptyMessage', (tester) async {
    await pump(tester, <String?>[], <ClassOption>[]);
    SelectedSchoolYear.notifier.value = planned;
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có lớp trong năm học này'), findsOneWidget);
  });

  testWidgets('fakeMode_closedYearIsReadOnly', (tester) async {
    final seen = <ClassOption>[];
    SelectedSchoolYear.notifier.value = FakeSchoolYearSource.years.last;
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherClassGate(
          sources: const TeacherSources(),
          builder: (classId, classes) {
            seen
              ..clear()
              ..addAll(classes);
            return Text('class $classId');
          },
        ),
      ),
    );
    expect(seen.single.readOnly, isTrue);
    SelectedSchoolYear.notifier.value = FakeSchoolYearSource.years.first;
    await tester.pump();
    expect(seen.single.readOnly, isFalse);
  });
}
