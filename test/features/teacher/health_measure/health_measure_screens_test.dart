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
  testWidgets('Kỳ đang mở: tiêu đề kỳ, thông tin kỳ, số đã đo và nhãn BMI', (
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
    expect(
      find.text('Kỳ cân đo · 05/11/2026 – 20/11/2026 · Cơ sở chính'),
      findsOneWidget,
    );
    expect(find.text('13/28 bé'), findsOneWidget);
    expect(find.bySemanticsLabel('Đã đo: 13'), findsOneWidget);
    expect(find.bySemanticsLabel('Chưa đo: 15'), findsOneWidget);
    expect(find.text('Bình thường'), findsWidgets);
  });

  testWidgets('Trẻ vắng không có số đo; tìm không ra ⇒ trạng thái rỗng', (
    tester,
  ) async {
    await pump(
      tester,
      HealthMeasureListScreen(
        onOpenKid: noop,
        source: FakeHealthMeasureSource(),
      ),
    );
    await tester.enterText(find.byType(TextField), 'khanh linh');
    await tester.pump();
    expect(find.text('Vắng hôm nay · đo bổ sung'), findsOneWidget);
    expect(find.textContaining('kg ·'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Không có bé nào'), findsOneWidget);
  });

  testWidgets('Không có kỳ đang mở ⇒ báo chưa mở kỳ, không có thao tác nhập', (
    tester,
  ) async {
    await pump(
      tester,
      HealthMeasureListScreen(
        onOpenKid: noop,
        source: FakeHealthMeasureSource(open: false),
      ),
    );
    expect(find.text('Cân nặng & chiều cao'), findsOneWidget);
    expect(
      find.text('Chưa mở kỳ cân đo. Bạn chỉ xem được số đo, chưa nhập được.'),
      findsOneWidget,
    );
    expect(find.text('Chưa đo'), findsNothing);
    expect(find.byType(AppButton), findsNothing);
    expect(find.text('Đợt khám và kỳ cân đo'), findsOneWidget);
    expect(find.text('Kỳ cân đo quý III'), findsOneWidget);
  });

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
    expect(find.text('Kết quả tính theo quy tắc của trường'), findsOneWidget);
    expect(find.text('Bình thường'), findsOneWidget);
    expect(find.text('BMI 15,9'), findsOneWidget);
  });
}
