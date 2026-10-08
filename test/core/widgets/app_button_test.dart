import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/widgets/app_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('AC-3: bấm nút thường gọi onPressed', (tester) async {
    var taps = 0;
    await pumpWithTheme(
      tester,
      Center(
        child: AppButton(label: 'Lưu', onPressed: () => taps++),
      ),
    );
    await tester.tap(find.text('Lưu'));
    expect(taps, 1);
  });

  testWidgets('AC-3: đang tải ⇒ hiện vòng tải, không gọi onPressed', (
    tester,
  ) async {
    var taps = 0;
    await pumpWithTheme(
      tester,
      Center(
        child: AppButton(
          label: 'Gửi',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Gửi'));
    expect(taps, 0);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isFalse,
    );
  });

  testWidgets('AC-3: onPressed null ⇒ disabled; cao tối thiểu 48', (
    tester,
  ) async {
    await pumpWithTheme(
      tester,
      const Center(child: AppButton(label: 'Khóa', onPressed: null)),
    );
    final button = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(button).enabled, isFalse);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  });

  testWidgets('variant dùng đúng loại nút Material; danger dùng màu error', (
    tester,
  ) async {
    await pumpWithTheme(
      tester,
      Column(
        children: [
          AppButton(
            label: 'A',
            onPressed: () {},
            variant: AppButtonVariant.secondary,
          ),
          AppButton(
            label: 'B',
            onPressed: () {},
            variant: AppButtonVariant.text,
          ),
          AppButton(
            label: 'C',
            onPressed: () {},
            variant: AppButtonVariant.danger,
          ),
        ],
      ),
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    final danger = tester.widget<FilledButton>(find.byType(FilledButton));
    final context = tester.element(find.byType(FilledButton));
    expect(
      danger.style?.backgroundColor?.resolve({}),
      Theme.of(context).colorScheme.error,
    );
  });

  testWidgets('expand ⇒ nút rộng hết chiều ngang', (tester) async {
    await pumpWithTheme(
      tester,
      AppButton(label: 'Đăng nhập', expand: true, onPressed: () {}),
    );
    expect(tester.getSize(find.byType(FilledButton)).width, 800);
  });
}
