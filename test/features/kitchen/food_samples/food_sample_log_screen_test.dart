import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/fake_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_sample.dart';
import 'package:carenest_app/features/kitchen/food_samples/presentation/screens/food_sample_log_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/data/fake_kitchen_day_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

/// 11:00 ngày giả: mẫu trưa hôm qua (lấy 10:30) đã đủ 24 giờ.
final _now = DateTime(
  FakeParentHomeSource.today.year,
  FakeParentHomeSource.today.month,
  FakeParentHomeSource.today.day,
  11,
);

class _RecordingSource extends FakeFoodSampleSource {
  _RecordingSource({super.failWrites}) : super(delay: Duration.zero);

  final drafts = <FoodSampleDraft>[];
  final disposals = <DateTime>[];

  @override
  Future<FoodSample> create(FoodSampleDraft draft) {
    drafts.add(draft);
    return super.create(draft);
  }

  @override
  Future<FoodSample> dispose(int id, DateTime disposedAt) {
    disposals.add(disposedAt);
    return super.dispose(id, disposedAt);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  FoodSampleSource? source,
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: FoodSampleLogScreen(
        daySource: FakeKitchenDaySource(delay: Duration.zero),
        sampleSource: source ?? FakeFoodSampleSource(delay: Duration.zero),
        now: () => _now,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện trạng thái từng bữa hôm nay và mẫu cần hủy', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text(MealSession.morning.label), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsOneWidget);
    expect(find.text('Lấy mẫu 08:15'), findsOneWidget);
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Chưa lưu mẫu'), findsNWidgets(2));

    await _scrollTo(tester, find.text('Cần hủy'));
    expect(find.text('Ghi hủy'), findsOneWidget);
    expect(find.text('Chờ duyệt hủy'), findsOneWidget);
  });

  testWidgets('lưu mẫu bữa trưa gửi đủ món và giờ lấy mẫu', (tester) async {
    final source = _RecordingSource();
    await _pump(tester, source: source);

    await tester.tap(find.text('Lưu mẫu').first);
    await tester.pumpAndSettle();
    expect(find.text('Lưu mẫu · Bữa trưa'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    final draft = source.drafts.single;
    expect(draft.session, MealSession.lunch);
    expect(draft.dishIds, [42, 43, 21, 22, 23, 24]);
    expect(draft.sampledAt.isAfter(_now), isFalse);
    expect(find.text('Chưa lưu mẫu'), findsOneWidget);
  });

  testWidgets('bỏ chọn hết món thì báo lỗi, không gửi', (tester) async {
    final source = _RecordingSource();
    await _pump(tester, source: source);

    await tester.tap(find.text('Lưu mẫu').first);
    await tester.pumpAndSettle();
    for (final name in [
      'Cháo thịt bí đỏ',
      'Chuối nghiền',
      'Cơm tẻ',
      'Cá sốt cà chua',
      'Canh bí đỏ nấu thịt',
    ]) {
      await tester.ensureVisible(find.text(name).last);
      await tester.tap(find.text(name).last);
    }
    await tester.ensureVisible(find.text('Thịt gà rim (thay thế)').last);
    await tester.tap(find.text('Thịt gà rim (thay thế)').last);
    await tester.pump();
    await tester.ensureVisible(find.text('Lưu'));
    await tester.tap(find.text('Lưu'));
    await tester.pump();

    expect(find.text('Chọn ít nhất 1 món.'), findsOneWidget);
    expect(source.drafts, isEmpty);
  });

  testWidgets('ghi lỗi mạng thì giữ sheet và báo lỗi', (tester) async {
    await _pump(tester, source: _RecordingSource(failWrites: true));

    await tester.tap(find.text('Lưu mẫu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa lưu được. Kiểm tra mạng rồi thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Lưu mẫu · Bữa trưa'), findsOneWidget);
  });

  testWidgets('ghi hủy mẫu đủ 24 giờ', (tester) async {
    final source = _RecordingSource();
    await _pump(tester, source: source);

    await _scrollTo(tester, find.text('Ghi hủy'));
    await tester.tap(find.text('Ghi hủy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ghi hủy').last);
    await tester.pumpAndSettle();

    expect(source.disposals, [_now]);
    await _scrollTo(tester, find.text('Chờ duyệt hủy').last);
    expect(find.text('Chờ duyệt hủy'), findsNWidgets(2));
    expect(find.text('Cần hủy'), findsNothing);
  });

  testWidgets('chữ phóng to 200% không tràn', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
