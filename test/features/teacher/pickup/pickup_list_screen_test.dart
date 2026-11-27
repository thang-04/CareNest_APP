import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/teacher/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_list_screen.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_result_screen.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

import '../../../helpers/pump_app.dart';

Future<void> pump(WidgetTester tester, Widget screen) async {
  usePhoneSize(tester);
  await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
  await tester.pumpAndSettle();
}

Future<void> noop(String _) async {}

class _FailingSource extends FakePickupSource {
  @override
  Future<PickupBoard> loadBoard(String classId, {DateTime? date}) =>
      Future.error(Exception('x'));
}

class _PastBoardSource extends FakePickupSource {
  @override
  Future<PickupBoard> loadBoard(String classId, {DateTime? date}) async =>
      PickupBoard(
        rows: (await super.loadBoard(classId)).rows,
        date: DateTime(2026, 10, 13),
        today: DateTime(2026, 10, 14),
      );
}

void main() {
  testWidgets('số Đã đón / Chờ đón, ô tìm, dòng chờ đón có nút Trả trẻ', (
    tester,
  ) async {
    await pump(
      tester,
      PickupListScreen(onVerify: noop, source: FakePickupSource()),
    );
    expect(find.bySemanticsLabel('Chờ đón: 7'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Đã đón: \d+$')), findsOneWidget);
    expect(find.text('Tìm tên bé…'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Trả trẻ'), findsWidgets);
    expect(find.text('Chờ đón · 1 lần không trả trẻ'), findsOneWidget);
  });

  testWidgets('Trả trẻ gọi onVerify với bé đang chờ đón', (tester) async {
    final verified = <String>[];
    await pump(
      tester,
      PickupListScreen(
        onVerify: (id) async => verified.add(id),
        source: FakePickupSource(),
      ),
    );
    await tester.tap(find.widgetWithText(AppButton, 'Trả trẻ').first);
    await tester.pumpAndSettle();
    expect(verified, hasLength(1));
  });

  testWidgets('lớp chỉ xem ⇒ banner lịch sử, không có nút Trả trẻ', (
    tester,
  ) async {
    await pump(
      tester,
      PickupListScreen(
        onVerify: noop,
        onCall: noop,
        classes: const [ClassOption(id: 'c1', name: 'Lớp cũ', readOnly: true)],
        classId: 'c1',
        source: FakePickupSource(),
      ),
    );
    expect(find.text('Đang xem lịch sử, không sửa được'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Trả trẻ'), findsNothing);
  });

  testWidgets('BE báo ngày xem không phải hôm nay ⇒ chỉ xem', (tester) async {
    await pump(
      tester,
      PickupListScreen(
        onVerify: noop,
        today: DateTime(2026, 10, 13),
        source: _PastBoardSource(),
      ),
    );
    // Màn tính hôm nay = 13/10, bản giả BE báo hôm nay = 12/10 ⇒ board.canRecord false
    expect(find.text('Đang xem lịch sử, không sửa được'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Trả trẻ'), findsNothing);
  });

  testWidgets('chưa được phân công lớp', (tester) async {
    await pump(tester, PickupListScreen(onVerify: noop, classId: ''));
    expect(find.text('Bạn chưa được phân công lớp'), findsOneWidget);
  });

  testWidgets('lỗi tải ⇒ báo lỗi có Thử lại', (tester) async {
    await pump(
      tester,
      PickupListScreen(onVerify: noop, source: _FailingSource()),
    );
    expect(find.text('Chưa tải được bảng đón'), findsOneWidget);
  });

  testWidgets('Kết quả trả trẻ: người đón, xác minh, kết quả', (tester) async {
    await pump(tester, PickupResultScreen(source: FakePickupSource()));
    expect(find.text('Kết quả trả trẻ ngày 12/10/2026'), findsOneWidget);
    expect(find.text('Không trả trẻ'), findsOneWidget);
    expect(find.text('Đã trả trẻ'), findsWidgets);
  });
}
