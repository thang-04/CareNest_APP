import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_confirmation_dialog.dart';
import 'package:carenest_app/core/widgets/app_empty_state.dart';
import 'package:carenest_app/core/widgets/app_error_state.dart';
import 'package:carenest_app/core/widgets/app_loading.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('AC-6: empty có message, CTA chỉ hiện khi có hành động', (
    tester,
  ) async {
    var taps = 0;
    await pumpWithTheme(
      tester,
      Column(
        children: [
          const AppEmptyState(title: 'Chưa có dữ liệu', message: 'Giải thích'),
          AppEmptyState(
            title: 'Danh sách trống',
            actionLabel: 'Làm mới',
            onAction: () => taps++,
          ),
        ],
      ),
    );
    expect(find.text('Giải thích'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    await tester.tap(find.text('Làm mới'));
    expect(taps, 1);
  });

  testWidgets('AC-6: error có nút "Thử lại" gọi callback', (tester) async {
    var retries = 0;
    await pumpWithTheme(tester, AppErrorState(onRetry: () => retries++));
    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(retries, 1);
  });

  testWidgets('AC-6: loading có semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWithTheme(tester, const AppLoading());
    expect(find.bySemanticsLabel('Đang tải'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('AppCard có onTap thì bấm được', (tester) async {
    var taps = 0;
    await pumpWithTheme(
      tester,
      AppCard(onTap: () => taps++, child: const Text('Mở')),
    );
    await tester.tap(find.text('Mở'));
    expect(taps, 1);
  });

  testWidgets(
    'AppConfirmationDialog trả true khi xác nhận, false khi quay lại',
    (tester) async {
      final results = <bool>[];
      await pumpWithTheme(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await AppConfirmationDialog.show(
                context,
                title: 'Hủy phiếu này?',
                confirmLabel: 'Hủy phiếu',
                isDestructive: true,
              ),
            ),
            child: const Text('Mở'),
          ),
        ),
      );

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy phiếu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();

      expect(results, [true, false]);
    },
  );
}
