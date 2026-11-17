import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/health_book/data/fake_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/health_book/presentation/screens/health_book_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

/// Sổ dựng sẵn cho các trường hợp dữ liệu giả không có.
class _BookSource implements HealthBookSource {
  const _BookSource(this.book);

  final HealthBook book;

  @override
  Future<HealthBook> load(String childId) async => book;
}

Future<void> pumpTrend(
  WidgetTester tester, {
  String childId = 'child-1',
  HealthBookSource source = const FakeHealthBookSource(delay: Duration.zero),
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: HealthBookScreen(
        child: FakeParentHomeSource.childById(childId),
        initialTab: HealthBookTab.trend,
        source: source,
        onOpenExam: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder chart(String pattern) => find.bySemanticsLabel(RegExp(pattern));

void main() {
  testWidgets('Xu hướng: mặc định Toàn bộ, hai biểu đồ đủ mọi lần đo', (
    tester,
  ) async {
    await pumpTrend(tester);
    expect(find.text('Xu hướng sức khỏe'), findsOneWidget);
    for (final period in ['6 tháng', '12 tháng', 'Toàn bộ']) {
      expect(find.text(period), findsOneWidget, reason: period);
    }
    expect(chart(r'^Chiều cao 6 lần đo: tháng 9/2025 khám 97,8 cm;'), findsOne);
    expect(chart(r'tháng 10/2026 104 cm$'), findsOne);
    expect(find.text('2025 – 2026'), findsWidgets);

    await tester.scrollUntilVisible(chart(r'^Cân nặng 6 lần đo'), 200);
    expect(chart(r'tháng 9/2026 khám 17 kg; tháng 10/2026 17,2 kg$'), findsOne);
    await tester.scrollUntilVisible(find.text('Đợt khám sức khỏe'), 200);
    expect(find.text('Đợt khám sức khỏe'), findsOneWidget);
  });

  testWidgets('Xu hướng: chọn 6 tháng chỉ còn các lần đo trong 6 tháng', (
    tester,
  ) async {
    await pumpTrend(tester);
    await tester.tap(find.text('6 tháng'));
    await tester.pumpAndSettle();
    expect(chart(r'^Chiều cao 4 lần đo: tháng 4/2026 101 cm;'), findsOne);
    expect(find.text('Năm 2026'), findsWidgets);

    await tester.tap(find.text('12 tháng'));
    await tester.pumpAndSettle();
    expect(chart(r'^Chiều cao 5 lần đo: tháng 1/2026 99,5 cm;'), findsOne);
  });

  testWidgets('Xu hướng: nhận định đã duyệt đủ các phần', (tester) async {
    await pumpTrend(tester);
    await tester.scrollUntilVisible(find.text('Nhận định xu hướng'), 300);
    expect(
      find.text('Phân tích 6 tháng · duyệt ngày 14/10/2026'),
      findsOneWidget,
    );
    expect(find.text('Đã duyệt'), findsOneWidget);
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.textContaining('chiều cao của bé tăng từ 101 cm'), findsOne);
    await tester.scrollUntilVisible(
      find.textContaining('AI soạn từ số đo'),
      300,
    );
    expect(find.text('Điểm tích cực'), findsOneWidget);
    expect(find.text('Chiều cao tăng đều qua các lần đo.'), findsOneWidget);
    expect(find.text('Lưu ý về dữ liệu'), findsOneWidget);
    expect(find.text('Cần chú ý'), findsNothing);
  });

  testWidgets('Xu hướng: bé chưa có nhận định thì báo, biểu đồ vẫn hiện', (
    tester,
  ) async {
    await pumpTrend(tester, childId: 'child-2');
    expect(chart(r'^Chiều cao 3 lần đo'), findsOne);
    await tester.scrollUntilVisible(
      find.text('Chưa có nhận định xu hướng'),
      300,
    );
    expect(
      find.text(
        'Cô giáo sẽ gửi nhận định khi đủ số đo. Biểu đồ vẫn cập nhật sau mỗi lần đo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Xu hướng: điểm cần chú ý và nhận định cũ', (tester) async {
    await pumpTrend(
      tester,
      source: _BookSource(
        HealthBook(
          rounds: const [],
          exams: const [],
          growth: [
            GrowthPoint(
              date: DateTime(2026, 9, 18),
              heightCm: 103.4,
              weightKg: 17.5,
              fromExam: true,
            ),
            GrowthPoint(
              date: DateTime(2026, 10, 12),
              heightCm: 104,
              weightKg: 17.2,
            ),
          ],
          interpretation: TrendInterpretation(
            periodLabel: 'Phân tích 6 tháng',
            approvedOn: DateTime(2026, 10, 14),
            overview: 'Chiều cao tăng, cân nặng giảm nhẹ.',
            attention: const [
              'Cân nặng lần đo ngày 12/10/2026 giảm 0,3 kg so với lần đo ngày 18/09/2026.',
            ],
            stale: true,
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Cần chú ý'), 300);
    expect(find.textContaining('giảm 0,3 kg'), findsOneWidget);
    expect(
      find.text(
        'Đã có số đo mới sau lần nhận định này. Nội dung nhận định chưa tính các lần đo mới.',
      ),
      findsOneWidget,
    );
    expect(find.text('Điểm tích cực'), findsNothing);
  });

  testWidgets('Xu hướng: khoảng chỉ có 1 lần đo thì không vẽ', (tester) async {
    await pumpTrend(
      tester,
      source: _BookSource(
        HealthBook(
          rounds: const [],
          exams: const [],
          growth: [
            GrowthPoint(
              date: DateTime(2025, 1, 10),
              heightCm: 95,
              weightKg: 14.5,
            ),
            GrowthPoint(
              date: DateTime(2026, 10, 12),
              heightCm: 104,
              weightKg: 17.2,
            ),
          ],
        ),
      ),
    );
    expect(chart(r'^Chiều cao 2 lần đo'), findsOne);
    await tester.tap(find.text('6 tháng'));
    await tester.pumpAndSettle();
    expect(chart(r'^Chiều cao'), findsNothing);
    expect(
      find.text(
        'Khoảng này chỉ có 1 lần đo. Cần ít nhất 2 lần đo để vẽ xu hướng, hãy chọn khoảng dài hơn.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Xu hướng: chưa có lần đo nào', (tester) async {
    await pumpTrend(
      tester,
      source: const FakeHealthBookSource(
        mode: FakeMode.empty,
        delay: Duration.zero,
      ),
    );
    expect(find.text('Chưa có số đo để vẽ xu hướng'), findsOneWidget);
    expect(find.text('6 tháng'), findsNothing);
  });

  testWidgets('AC-10: Xu hướng chữ 2.0 cuộn hết không tràn', (tester) async {
    await pumpTrend(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.textContaining('AI soạn từ số đo'),
      400,
    );
    expect(tester.takeException(), isNull);
  });
}
