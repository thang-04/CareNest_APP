import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/evaluation/data/fake_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/screens/evaluation_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

class _Opened {
  final themes = <String>[];
  var healthBook = 0;
}

Future<_Opened> _pumpEvaluation(
  WidgetTester tester, {
  String childId = 'child-1',
  double textScale = 1,
  EvaluationTab tab = EvaluationTab.day,
  FakeMode mode = FakeMode.data,
}) async {
  final opened = _Opened();
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      // Khóa mới mỗi lần bơm ⇒ tải lại theo nguồn mới, không giữ state lần trước
      home: EvaluationScreen(
        key: UniqueKey(),
        child: FakeParentHomeSource.childById(childId),
        initialTab: tab,
        source: FakeEvaluationSource(mode: mode, delay: Duration.zero),
        onOpenTheme: opened.themes.add,
        onOpenHealthBook: () => opened.healthBook++,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Đánh giá: 5 mục; mục Ngày mở sẵn ngày gần nhất cô đã lưu', (
    tester,
  ) async {
    await _pumpEvaluation(tester);
    expect(find.text('Đánh giá'), findsOneWidget);
    for (final tab in ['Ngày', 'Tuần', 'Chủ đề', 'Học kỳ', 'Cuối năm']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    expect(find.text('Tuần 35'), findsOneWidget);
    expect(find.text('Bé được cờ ngày 28/05'), findsOneWidget);
    expect(find.bySemanticsLabel('Sức khỏe: Bình thường'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Bữa chiều: Ăn ít, cần chú ý'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Hành vi: Hợp tác tốt · Giúp đỡ bạn'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Chưa đạt, 1 mục tiêu'), findsOneWidget);
    expect(find.bySemanticsLabel('Đạt, 3 mục tiêu'), findsOneWidget);
    expect(find.text('Kể lại được 1–2 câu trong chuyện'), findsOneWidget);
    expect(find.text('Hoạt động góc · Góc xây dựng'), findsOneWidget);
    expect(find.text('Cô Trần Thu Hà · 16:20'), findsOneWidget);
  });

  testWidgets('Mục Ngày: ngày vắng, tuần trước và ngày cô chưa lưu', (
    tester,
  ) async {
    await _pumpEvaluation(tester);
    await _tapVisible(tester, find.bySemanticsLabel('Thứ Năm, 27/05/2027'));
    expect(find.text('Bé nghỉ học ngày 27/05'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Tuần trước'));
    expect(find.text('Tuần 34'), findsOneWidget);
    // Tuần trước mở sẵn ngày cuối cô đã lưu (thứ Năm), không phải thứ Sáu chưa lưu
    expect(find.text('Con vận động theo nhạc rất nhịp nhàng.'), findsOneWidget);
    expect(find.bySemanticsLabel('Sức khỏe: Bình thường'), findsOneWidget);

    await _tapVisible(tester, find.bySemanticsLabel('Thứ Sáu, 21/05/2027'));
    expect(find.text('Chưa có đánh giá ngày 21/05'), findsOneWidget);

    await _tapVisible(tester, find.bySemanticsLabel('Thứ Ba, 18/05/2027'));
    expect(
      find.bySemanticsLabel('Sức khỏe: Sổ mũi, cần chú ý'),
      findsOneWidget,
    );

    await _tapVisible(tester, find.byTooltip('Tuần sau'));
    expect(find.text('Tuần 35'), findsOneWidget);
    expect(find.text('Bé được cờ ngày 28/05'), findsOneWidget);
  });

  testWidgets('Mục Tuần: tuần mới nhất mở sẵn, tuần cũ có "Đọc tiếp"', (
    tester,
  ) async {
    await _pumpEvaluation(tester, tab: EvaluationTab.week);
    expect(find.text('Tuần 35 · 24/05 – 28/05/2027'), findsOneWidget);
    expect(find.textContaining('Trưa thứ Tư con ngủ ít'), findsOneWidget);
    expect(find.text('Cô Trần Thu Hà · gửi 28/05, 16:40'), findsOneWidget);

    final readMore = find.text('Đọc tiếp');
    final before = tester.widgetList(readMore).length;
    expect(before, greaterThan(0));
    await _tapVisible(tester, readMore.first);
    expect(tester.widgetList(readMore).length, before - 1);
  });

  testWidgets('Mục Chủ đề: nhóm theo học kỳ, chạm chủ đề mở kết quả', (
    tester,
  ) async {
    final opened = await _pumpEvaluation(tester, tab: EvaluationTab.theme);
    expect(find.text('Học kỳ II'), findsOneWidget);
    expect(find.text('Học kỳ I'), findsOneWidget);
    expect(find.text('03/05 – 21/05 · 4/5 mục tiêu'), findsOneWidget);
    expect(find.text('Chưa đạt'), findsOneWidget);
    expect(
      find.text('Bé đạt chủ đề khi đạt từ 70% số mục tiêu.'),
      findsOneWidget,
    );

    await _tapVisible(tester, find.text('Bé vui hè'));
    expect(opened.themes, ['theme-mam-7']);
  });

  testWidgets('Mục Chủ đề: chủ đề đang học chưa có kết quả, không mở được', (
    tester,
  ) async {
    final opened = await _pumpEvaluation(
      tester,
      childId: 'child-2',
      tab: EvaluationTab.theme,
    );
    expect(find.text('Đang học · 24/05 – 31/05'), findsOneWidget);
    expect(find.text('Chưa có kết quả'), findsOneWidget);
    await _tapVisible(tester, find.text('Bé chuẩn bị vào lớp 1'));
    expect(opened.themes, isEmpty);
  });

  testWidgets(
    'Mục Học kỳ: lĩnh vực chưa đạt mở sẵn, mở ra thấy đủ MT, đổi học kỳ',
    (tester) async {
      await _pumpEvaluation(tester, tab: EvaluationTab.semester);
      expect(find.text('Học kỳ II'), findsOneWidget);
      expect(find.bySemanticsLabel('4 trên 5 lĩnh vực đạt'), findsOneWidget);
      expect(find.text('Kể chuyện theo tranh Đôi bạn tốt'), findsOneWidget);
      expect(find.text('Đạt ở 0/2 chủ đề'), findsOneWidget);
      // User 18/11: MT đạt hiện luôn, không có nút "Xem N mục tiêu đạt"
      expect(find.text('Bắt chước tiếng kêu của con vật'), findsOneWidget);
      expect(find.textContaining(RegExp('^Xem ')), findsNothing);
      // Lĩnh vực đạt đóng sẵn, chạm tên lĩnh vực để mở
      expect(find.text('Biết uống đủ nước khi trời nóng'), findsNothing);
      await _tapVisible(tester, find.text('Phát triển thể chất'));
      expect(find.text('Biết uống đủ nước khi trời nóng'), findsOneWidget);

      await _tapVisible(tester, find.byTooltip('Học kỳ trước'));
      expect(find.text('Học kỳ I'), findsOneWidget);
      expect(
        find.text('Hát đúng giai điệu bài Vui đến trường'),
        findsOneWidget,
      );
      expect(
        find.text('Cô Trần Thu Hà xác nhận ngày 20/01/2027'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Mục Cuối năm: phiếu, lưu ý cho gia đình, lĩnh vực, cân đo', (
    tester,
  ) async {
    final opened = await _pumpEvaluation(tester, tab: EvaluationTab.yearEnd);
    expect(find.text('PHIẾU ĐÁNH GIÁ SỰ PHÁT TRIỂN'), findsOneWidget);
    expect(find.text('Năm học 2026–2027'), findsOneWidget);
    expect(find.bySemanticsLabel('21 trên 25 mục tiêu đạt'), findsOneWidget);
    // Nhóm 3–4 tuổi không có nhãn hoàn thành chương trình
    expect(find.text('Hoàn thành chương trình mầm non'), findsNothing);
    expect(find.text('Lưu ý cho gia đình'), findsOneWidget);
    // Lĩnh vực đầu tiên có MT chưa đạt mở sẵn, kèm nhận xét của cô
    expect(find.text('Cô nhận xét'), findsOneWidget);
    expect(find.text('Xúc cơm ăn gọn gàng'), findsOneWidget);
    expect(find.bySemanticsLabel('Cân nặng: 18,1 kg'), findsOneWidget);
    expect(find.bySemanticsLabel('Chiều cao: 107,5 cm'), findsOneWidget);

    await _tapVisible(tester, find.text('Sổ sức khỏe'));
    expect(opened.healthBook, 1);
  });

  testWidgets('Mục Cuối năm: lớp 5–6 tuổi có nhãn hoàn thành chương trình', (
    tester,
  ) async {
    await _pumpEvaluation(
      tester,
      childId: 'child-2',
      tab: EvaluationTab.yearEnd,
    );
    expect(find.text('Hoàn thành chương trình mầm non'), findsOneWidget);
    expect(find.text('Nhóm 5–6 tuổi'), findsOneWidget);
  });

  testWidgets('Lỗi tải có "Thử lại"; chưa có dữ liệu thì mỗi mục báo trống', (
    tester,
  ) async {
    await _pumpEvaluation(tester, mode: FakeMode.error);
    expect(find.text('Chưa tải được đánh giá'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await _pumpEvaluation(tester, mode: FakeMode.empty);
    expect(find.text('Chưa có đánh giá ngày'), findsOneWidget);
    const empty = {
      'Tuần': 'Chưa có nhận xét tuần',
      'Chủ đề': 'Chưa có kết quả chủ đề',
      'Học kỳ': 'Chưa có kết quả học kỳ',
      'Cuối năm': 'Chưa có đánh giá cuối năm',
    };
    for (final MapEntry(key: tab, value: message) in empty.entries) {
      await _tapVisible(tester, find.text(tab));
      expect(find.text(message), findsOneWidget, reason: tab);
    }
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('Chữ $scale: 5 mục không tràn', (tester) async {
      await _pumpEvaluation(tester, textScale: scale);
      expect(tester.takeException(), isNull);
      for (final tab in ['Tuần', 'Chủ đề', 'Học kỳ', 'Cuối năm']) {
        await _tapVisible(tester, find.text(tab));
        expect(tester.takeException(), isNull, reason: tab);
      }
    });
  }
}
