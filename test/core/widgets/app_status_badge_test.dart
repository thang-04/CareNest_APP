import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('AC-5: mỗi tông hiện chữ và màu lấy từ AppStatusColors', (
    tester,
  ) async {
    await pumpWithTheme(
      tester,
      Wrap(
        children: [
          for (final tone in AppStatusTone.values)
            AppStatusBadge(label: tone.name, tone: tone),
        ],
      ),
    );
    for (final tone in AppStatusTone.values) {
      final colors = AppStatusColors.light.tone(tone);
      final text = tester.widget<Text>(find.text(tone.name));
      expect(text.style?.color, colors.foreground, reason: tone.name);
      final box = tester.widget<Container>(
        find.ancestor(
          of: find.text(tone.name),
          matching: find.byType(Container),
        ),
      );
      expect(
        (box.decoration as BoxDecoration?)?.color,
        colors.background,
        reason: tone.name,
      );
    }
  });

  testWidgets('có icon thì hiện icon cạnh chữ', (tester) async {
    await pumpWithTheme(
      tester,
      const AppStatusBadge(
        label: 'Hoàn thành',
        tone: AppStatusTone.success,
        icon: Icons.check,
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
  });
}
