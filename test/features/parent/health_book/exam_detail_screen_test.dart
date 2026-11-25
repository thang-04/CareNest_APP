import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/health_book/data/fake_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/health_book/presentation/screens/exam_detail_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpExam(
  WidgetTester tester, {
  String examId = 'exam-2026',
  double textScale = 1,
  HealthBookSource source = const FakeHealthBookSource(delay: Duration.zero),
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: ExamDetailScreen(
        child: FakeParentHomeSource.childById('child-1'),
        examId: examId,
        source: source,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Đợt khám như API phụ huynh trả (25/11): chỉ phần kết luận.
class _ConclusionOnlySource extends HealthBookSource {
  const _ConclusionOnlySource();

  @override
  Future<HealthBook> load(String childId, {ChildSchoolYear? year}) async =>
      HealthBook(
        rounds: const [],
        growth: const [],
        exams: [
          HealthExam(
            id: '9',
            name: 'Khám sức khỏe đầu năm',
            date: DateTime(2026, 9, 20),
            ageMonths: 49,
            examiner: null,
            doctorName: null,
            followUp: FollowUpLevel.none,
            conclusion: 'Bình thường',
            action: null,
            nutritionStatus: null,
            parentOpinion: 'Gia đình đồng ý',
          ),
        ],
      );
}

void main() {
  testWidgets('examDetail_live_onlyConclusion', (tester) async {
    await pumpExam(tester, examId: '9', source: const _ConclusionOnlySource());
    expect(find.text('Kết luận và tư vấn'), findsOneWidget);
    expect(find.text('Bình thường'), findsWidgets);
    // Mục không có dữ liệu không hiện khung trống
    for (final title in [
      'Đơn vị khám',
      'Bác sĩ khám',
      'Tiền sử',
      'Dấu hiệu sinh tồn',
      'Dinh dưỡng',
      'Tiêm chủng',
      'Khám lâm sàng',
      'Tình trạng dinh dưỡng',
    ]) {
      expect(
        find.text(title, skipOffstage: false),
        findsNothing,
        reason: title,
      );
    }
    expect(find.textContaining('Hướng xử lý'), findsNothing);
    // User 25/11: phụ huynh xem được ý kiến phụ huynh trên phiếu
    expect(find.text('Ý kiến phụ huynh', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('Chi tiết đợt khám: thông tin đợt, kết luận và lời dặn', (
    tester,
  ) async {
    await pumpExam(tester);
    expect(find.text('Chi tiết đợt khám'), findsOneWidget);
    expect(find.text('Khám sức khỏe đầu năm học 2026-2027'), findsOneWidget);
    expect(find.text('Trạm Y tế xã Thượng Hồng'), findsOneWidget);
    expect(find.text('Kết luận và tư vấn'), findsOneWidget);
    expect(find.text('Cần theo dõi'), findsOneWidget);
    expect(find.text('Có vấn đề về sức khỏe: Sâu răng'), findsOneWidget);
    expect(
      find.textContaining('Chải răng cho bé 2 lần mỗi ngày'),
      findsOneWidget,
    );
  });

  testWidgets('Chi tiết đợt khám: đủ các phần của phiếu, mục bất thường nổi', (
    tester,
  ) async {
    await pumpExam(tester);
    await tester.scrollUntilVisible(find.text('Dấu hiệu sinh tồn'), 300);
    expect(find.bySemanticsLabel('Nhiệt độ: 36,7 °C, Bình thường'), findsOne);
    for (final section in [
      'Tiền sử',
      'Dấu hiệu sinh tồn',
      'Dinh dưỡng',
      'Phát triển tinh thần – vận động',
      'Tiêm chủng',
      'Khám lâm sàng',
    ]) {
      await tester.scrollUntilVisible(find.text(section), 300);
      expect(find.text(section), findsOneWidget, reason: section);
    }
    expect(
      find.text(
        '24 mục khám · 1 mục cần chú ý: Vết sâu, mảng bám, lỗ trên răng.',
      ),
      findsOneWidget,
    );
    final cavities = find.text('Vết sâu, mảng bám, lỗ trên răng');
    await tester.scrollUntilVisible(cavities, 300);
    final row = find.ancestor(of: cavities, matching: find.byType(Row)).first;
    expect(find.descendant(of: row, matching: find.text('Có')), findsOneWidget);
  });

  testWidgets('Chi tiết đợt khám: giá trị ngắn hay dài đều canh phải', (
    tester,
  ) async {
    await pumpExam(tester);
    final label = find.text('Tiền sử bản thân');
    await tester.scrollUntilVisible(label, 300);
    final row = find.ancestor(of: label, matching: find.byType(Row)).first;
    final value = find.descendant(of: row, matching: find.text('Không'));
    expect(
      tester.getRect(value).right,
      moreOrLessEquals(tester.getRect(row).right, epsilon: 1),
    );
  });

  testWidgets(
    'Chi tiết đợt khám: đơn vị dấu hiệu sinh tồn nằm riêng một dòng',
    (tester) async {
      await pumpExam(tester);
      await tester.scrollUntilVisible(find.text('Dấu hiệu sinh tồn'), 300);
      await tester.pumpAndSettle();
      expect(find.text('102', skipOffstage: false), findsOneWidget);
      expect(find.text('lần/phút', skipOffstage: false), findsNWidgets(2));
      expect(find.text('°C', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets('Chi tiết đợt khám: id không có trong sổ ⇒ báo không tìm thấy', (
    tester,
  ) async {
    await pumpExam(tester, examId: 'khong-co');
    expect(find.text('Không tìm thấy đợt khám'), findsOneWidget);
  });

  testWidgets('AC-10: Chi tiết đợt khám chữ 2.0 không tràn', (tester) async {
    await pumpExam(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    // Cuộn hết phiếu: các dòng bên dưới chỉ dựng khi vào màn hình
    await tester.scrollUntilVisible(find.textContaining('Đã công bố'), 400);
    expect(tester.takeException(), isNull);
  });
}
