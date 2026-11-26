import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/teacher/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_detail_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_list_screen.dart';

import '../../../helpers/pump_app.dart';

Future<void> pump(WidgetTester tester, Widget screen) async {
  usePhoneSize(tester);
  await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
  await tester.pumpAndSettle();
}

Future<void> noop(String _) async {}

void main() {
  testWidgets('Kỳ đang mở: header kỳ (loại, trạng thái, đã nhập) và nhãn BMI', (
    tester,
  ) async {
    await pump(
      tester,
      HealthMeasureListScreen(
        onOpenKid: noop,
        source: FakeHealthMeasureSource(),
      ),
    );
    expect(find.text('Kỳ cân đo quý IV'), findsWidgets);
    expect(find.text('Kỳ cân đo'), findsWidgets);
    expect(find.text('Đang diễn ra'), findsWidgets);
    expect(find.text('Đã nhập 13/28 trẻ'), findsOneWidget);
    expect(find.text('Bình thường'), findsWidgets);
  });

  testWidgets('Lọc Vắng ẩn số đo của trẻ đã đo', (tester) async {
    await pump(
      tester,
      HealthMeasureListScreen(
        onOpenKid: noop,
        source: FakeHealthMeasureSource(),
      ),
    );
    await tester.tap(find.text('Vắng').first);
    await tester.pump();
    expect(find.text('Vắng hôm nay'), findsWidgets);
    expect(find.textContaining('kg ·'), findsNothing);
  });

  testWidgets(
    'Không có kỳ đang mở ⇒ "Chưa mở kỳ cân đo", không có thao tác nhập',
    (tester) async {
      await pump(
        tester,
        HealthMeasureListScreen(
          onOpenKid: noop,
          source: FakeHealthMeasureSource(open: false),
        ),
      );
      expect(find.text('Chưa mở kỳ cân đo'), findsOneWidget);
      expect(find.text('Chưa đo'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(AppButton), findsNothing);
      expect(find.text('Đợt khám và kỳ cân đo'), findsOneWidget);
      expect(find.text('Kỳ cân đo quý III'), findsOneWidget);
    },
  );

  testWidgets(
    'Màn nhập một trẻ khi không có kỳ ⇒ chỉ báo chưa mở, ẩn nút lưu',
    (tester) async {
      await pump(
        tester,
        HealthMeasureDetailScreen(
          childId: 'child-1',
          source: FakeHealthMeasureSource(open: false),
        ),
      );
      expect(find.text('Chưa mở kỳ cân đo'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(AppButton), findsNothing);
    },
  );

  testWidgets('Trẻ đã đo hiện mức BMI do BE trả', (tester) async {
    await pump(
      tester,
      HealthMeasureDetailScreen(
        childId: 'child-1',
        source: FakeHealthMeasureSource(),
      ),
    );
    expect(find.text('Mức BMI theo tuổi do hệ thống tính'), findsOneWidget);
    expect(find.text('BMI 15,9'), findsOneWidget);
  });
}
