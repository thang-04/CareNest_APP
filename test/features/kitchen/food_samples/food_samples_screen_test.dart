import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/fake_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/food_samples/presentation/screens/food_samples_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

/// Ghi lại mọi lần lưu; [failures] lần đầu lỗi mạng.
class _RecordingSource extends FakeFoodSampleSource {
  _RecordingSource({this.failures = 0}) : super(delay: Duration.zero);

  int failures;
  final saved = <List<DishNoteInput>>[];
  final disposed = <int>[];

  @override
  Future<FoodSampleDay> saveSample({
    required String session,
    int? sampleId,
    required List<DishNoteInput> dishes,
  }) async {
    saved.add(dishes);
    if (failures > 0) {
      failures--;
      throw StateError('mất mạng');
    }
    return super.saveSample(
      session: session,
      sampleId: sampleId,
      dishes: dishes,
    );
  }

  @override
  Future<FoodSampleDay> recordDisposal(int sampleId) {
    disposed.add(sampleId);
    return super.recordDisposal(sampleId);
  }
}

/// Lần tải đầu lỗi, các lần sau có dữ liệu.
class _FailOnceSource extends FakeFoodSampleSource {
  _FailOnceSource() : super(delay: Duration.zero);

  var _failed = false;

  @override
  Future<FoodSampleDay> loadToday() async {
    if (!_failed) {
      _failed = true;
      throw StateError('mất mạng');
    }
    return super.loadToday();
  }
}

Future<void> pumpSamples(
  WidgetTester tester, {
  FoodSampleSource? source,
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: FoodSamplesScreen(
        source: source ?? FakeFoodSampleSource(delay: Duration.zero),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Danh sách của màn; ô nhập chữ cũng có Scrollable riêng
Finder get list => find.byType(Scrollable).first;

Finder card(String session) => find.byKey(ValueKey('sample-$session'));

Finder inCard(String session, String text) =>
    find.descendant(of: card(session), matching: find.text(text));

Finder disposal(int id) => find.byKey(ValueKey('disposal-$id'));

Finder inDisposal(int id, String text) =>
    find.descendant(of: disposal(id), matching: find.text(text));

/// Ô nhập thứ [index] của thẻ bữa (mỗi món 3 ô: khối lượng, dụng cụ, nhiệt độ).
Finder field(String session, int index) => find
    .descendant(of: card(session), matching: find.byType(TextField))
    .at(index);

Future<void> showAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: list);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Lưu mẫu: bữa đã ghi chờ PHT duyệt, có ghi chú từng món', (
    tester,
  ) async {
    await pumpSamples(tester);
    expect(find.text('Hôm nay · Thứ Hai, 12/10 · Cơ sở chính'), findsOneWidget);
    expect(inCard('MORNING', 'Chờ duyệt lưu mẫu'), findsOneWidget);
    expect(inCard('MORNING', 'Lấy mẫu 08:05 · 1 món'), findsOneWidget);
    expect(inCard('MORNING', 'Cháo thịt băm cà rốt · Nhà trẻ'), findsOneWidget);
    expect(
      inCard('MORNING', '150 ml · Hộp inox có nắp · 0–5 °C'),
      findsOneWidget,
    );
    expect(inCard('MORNING', 'Sửa lưu mẫu bữa phụ sáng'), findsOneWidget);
  });

  testWidgets(
    'Lưu mẫu: bữa trưa chưa ghi có ô nhập từng món, điền sẵn dụng cụ',
    (tester) async {
      await pumpSamples(tester);
      await tester.scrollUntilVisible(
        inCard('LUNCH', 'Chưa ghi'),
        200,
        scrollable: list,
      );
      expect(inCard('LUNCH', '3 món theo thực đơn đã công bố'), findsOneWidget);
      expect(inCard('LUNCH', 'Cơm tẻ'), findsOneWidget);
      expect(inCard('LUNCH', 'Cá basa sốt cà chua'), findsOneWidget);
      expect(inCard('LUNCH', 'Canh bí đỏ thịt băm'), findsOneWidget);
      expect(
        find.descendant(of: card('LUNCH'), matching: find.byType(TextField)),
        findsNWidgets(9),
      );
      // Dụng cụ chứa, nhiệt độ lấy theo mẫu gần nhất; khối lượng để trống
      expect(
        tester.widget<TextField>(field('LUNCH', 0)).controller?.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(field('LUNCH', 1)).controller?.text,
        'Hộp inox có nắp',
      );
      expect(
        tester.widget<TextField>(field('LUNCH', 2)).controller?.text,
        '0–5',
      );
    },
  );

  testWidgets('Lưu mẫu: lưu bữa trưa ⇒ gửi ghi chú từng món, chờ PHT duyệt', (
    tester,
  ) async {
    final source = _RecordingSource();
    await pumpSamples(tester, source: source);
    await tester.scrollUntilVisible(field('LUNCH', 0), 200, scrollable: list);
    await tester.pumpAndSettle();
    await tester.enterText(field('LUNCH', 0), '150 g');
    // Ô đang nhập tự cuộn về con trỏ ở khung hình sau ⇒ chờ xong rồi mới cuộn tới nút
    await tester.pumpAndSettle();
    await showAndTap(tester, inCard('LUNCH', 'Lưu mẫu bữa trưa'));
    expect(source.saved, hasLength(1));
    final rice = source.saved.single.firstWhere((note) => note.dishId == 21);
    expect(rice.weight, '150 g');
    expect(rice.container, 'Hộp inox có nắp');
    expect(rice.temperature, '0–5');
    expect(inCard('LUNCH', 'Chờ duyệt lưu mẫu'), findsOneWidget);
    expect(inCard('LUNCH', 'Lấy mẫu 10:50 · 3 món'), findsOneWidget);
    expect(inCard('LUNCH', '150 g · Hộp inox có nắp · 0–5 °C'), findsOneWidget);
  });

  testWidgets('Lưu mẫu: lưu lỗi ⇒ giữ chữ đã nhập, lưu lại được', (
    tester,
  ) async {
    final source = _RecordingSource(failures: 1);
    await pumpSamples(tester, source: source);
    await tester.scrollUntilVisible(field('LUNCH', 0), 200, scrollable: list);
    await tester.pumpAndSettle();
    await tester.enterText(field('LUNCH', 0), '150 g');
    // Ô đang nhập tự cuộn về con trỏ ở khung hình sau ⇒ chờ xong rồi mới cuộn tới nút
    await tester.pumpAndSettle();
    await showAndTap(tester, inCard('LUNCH', 'Lưu mẫu bữa trưa'));
    expect(
      inCard('LUNCH', 'Chưa lưu được mẫu. Kiểm tra mạng rồi lưu lại.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(field('LUNCH', 0)).controller?.text,
      '150 g',
    );

    await showAndTap(tester, inCard('LUNCH', 'Lưu mẫu bữa trưa'));
    expect(source.saved, hasLength(2));
    expect(inCard('LUNCH', 'Chờ duyệt lưu mẫu'), findsOneWidget);
  });

  testWidgets('Lưu mẫu: sửa bản chưa duyệt ⇒ giữ giờ lấy mẫu; Hủy sửa trở lại', (
    tester,
  ) async {
    await pumpSamples(tester);
    await showAndTap(tester, inCard('MORNING', 'Sửa lưu mẫu bữa phụ sáng'));
    expect(
      tester.widget<TextField>(field('MORNING', 0)).controller?.text,
      '150 ml',
    );
    expect(inCard('MORNING', 'Giờ lấy mẫu giữ 08:05.'), findsOneWidget);
    await showAndTap(tester, inCard('MORNING', 'Hủy sửa'));
    expect(inCard('MORNING', 'Sửa lưu mẫu bữa phụ sáng'), findsOneWidget);

    await showAndTap(tester, inCard('MORNING', 'Sửa lưu mẫu bữa phụ sáng'));
    await tester.enterText(field('MORNING', 0), '200 ml');
    // Ô đang nhập tự cuộn về con trỏ ở khung hình sau ⇒ chờ xong rồi mới cuộn tới nút
    await tester.pumpAndSettle();
    await showAndTap(tester, inCard('MORNING', 'Lưu thay đổi'));
    expect(
      inCard('MORNING', '200 ml · Hộp inox có nắp · 0–5 °C'),
      findsOneWidget,
    );
    expect(inCard('MORNING', 'Lấy mẫu 08:05 · 1 món'), findsOneWidget);
  });

  testWidgets('Lưu mẫu: bữa chiều chưa tới ⇒ không có ô nhập', (tester) async {
    await pumpSamples(tester);
    await tester.scrollUntilVisible(card('AFTERNOON'), 300, scrollable: list);
    expect(inCard('AFTERNOON', 'Chưa tới bữa'), findsOneWidget);
    expect(inCard('AFTERNOON', 'Sữa chua chuối'), findsOneWidget);
    expect(
      find.descendant(of: card('AFTERNOON'), matching: find.byType(TextField)),
      findsNothing,
    );
  });

  testWidgets('Hủy mẫu: đến hạn ⇒ hỏi xác nhận rồi chờ PHT duyệt hủy', (
    tester,
  ) async {
    final source = _RecordingSource();
    await pumpSamples(tester, source: source);
    await tester.scrollUntilVisible(disposal(3), 300, scrollable: list);
    expect(inDisposal(3, 'Đến hạn hủy'), findsOneWidget);
    await showAndTap(tester, inDisposal(3, 'Ghi hủy mẫu'));
    expect(find.text('Ghi hủy mẫu bữa trưa 11/10?'), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(source.disposed, isEmpty);

    await showAndTap(tester, inDisposal(3, 'Ghi hủy mẫu'));
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Ghi hủy mẫu'),
      ),
    );
    await tester.pumpAndSettle();
    expect(source.disposed, [3]);
    expect(inDisposal(3, 'Chờ duyệt hủy mẫu'), findsOneWidget);
    expect(inDisposal(3, 'Ghi hủy mẫu'), findsNothing);
  });

  testWidgets('Hủy mẫu: chưa đủ 24 giờ hoặc đã ghi ⇒ không có nút', (
    tester,
  ) async {
    await pumpSamples(tester);
    await tester.scrollUntilVisible(disposal(4), 300, scrollable: list);
    expect(inDisposal(4, 'Chưa tới giờ hủy'), findsOneWidget);
    expect(
      inDisposal(4, 'Lấy mẫu 14:50 ngày 11/10 · hủy được từ 14:50 ngày 12/10'),
      findsOneWidget,
    );
    expect(inDisposal(4, 'Ghi hủy mẫu'), findsNothing);
    expect(inDisposal(2, 'Chờ duyệt hủy mẫu'), findsOneWidget);
    expect(inDisposal(2, 'Ghi hủy mẫu'), findsNothing);
  });

  testWidgets('Lưu mẫu: tải lỗi rồi Thử lại ⇒ hiện các bữa', (tester) async {
    await pumpSamples(tester, source: _FailOnceSource());
    expect(find.text('Chưa tải được sổ lưu mẫu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(card('MORNING'), findsOneWidget);
  });

  testWidgets('Lưu mẫu: ngày nghỉ ⇒ không có bữa cần lưu mẫu', (tester) async {
    await pumpSamples(
      tester,
      source: FakeFoodSampleSource(mode: FakeMode.empty, delay: Duration.zero),
    );
    expect(find.text('Hôm nay trường nghỉ'), findsOneWidget);
  });

  testWidgets('AC-10: Sổ lưu mẫu chữ 2.0 không tràn', (tester) async {
    await pumpSamples(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(disposal(4), 400, scrollable: list);
    expect(tester.takeException(), isNull);
  });
}
