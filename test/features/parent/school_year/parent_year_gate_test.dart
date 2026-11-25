import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/school_year/data/fake_child_school_year_source.dart';
import 'package:carenest_app/features/parent/school_year/presentation/parent_selected_year.dart';

import '../../../helpers/pump_app.dart';

void main() {
  tearDown(ParentSelectedYear.reset);

  testWidgets(
    'AC-1 (AUTH-03): mặc định năm đang chạy; chọn năm cũ ⇒ "Chỉ xem", màn dựng lại theo năm',
    (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: ParentYearGate(
            childId: 'child-1',
            source: const FakeChildSchoolYearSource(),
            builder: (year) => Scaffold(
              body: Column(
                children: [
                  const ParentYearChip(),
                  Text('Lớp ${year.className}'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Năm học 2026–2027'), findsOneWidget);
      expect(find.text('Lớp Mầm 3A'), findsOneWidget);
      expect(find.text('Chỉ xem'), findsNothing);

      await tester.tap(find.text('Năm học 2026–2027'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Năm học 2025–2026').last);
      await tester.pumpAndSettle();

      expect(find.text('Năm học 2025–2026'), findsOneWidget);
      expect(find.text('Lớp Nhà trẻ 2'), findsOneWidget);
      expect(find.text('Chỉ xem'), findsOneWidget);
    },
  );
}
