import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_theme.dart';

void main() {
  final theme = buildLightTheme();

  test(
    'AC-1: ColorScheme theo DESIGN §4.1/§4.3 — primary là brand, chữ trên nút là onBrand',
    () {
      final scheme = theme.colorScheme;
      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, const Color(0xFF4FB0F5));
      expect(scheme.onPrimary, const Color(0xFF0E3F63));
      expect(scheme.secondary, const Color(0xFF0B72BC));
      expect(scheme.primaryContainer, const Color(0xFFE2F2FD));
      expect(scheme.error, const Color(0xFFE03131));
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.onSurface, const Color(0xFF1B2433));
      expect(scheme.outline, const Color(0xFFCDD6E3));
      expect(scheme.outlineVariant, const Color(0xFFE3E9F2));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF1F9FE));
    },
  );

  test('AC-1: thang chữ DESIGN §5.1, font BeVietnamPro, không độ đậm 800', () {
    final t = theme.textTheme;
    final expected = {
      'displaySmall': (t.displaySmall, 26.0, FontWeight.w700),
      'headlineMedium': (t.headlineMedium, 28.0, FontWeight.w700),
      'headlineSmall': (t.headlineSmall, 22.0, FontWeight.w700),
      'titleLarge': (t.titleLarge, 18.0, FontWeight.w600),
      'titleMedium': (t.titleMedium, 17.0, FontWeight.w700),
      'titleSmall': (t.titleSmall, 16.0, FontWeight.w600),
      'bodyLarge': (t.bodyLarge, 16.0, FontWeight.w400),
      'bodyMedium': (t.bodyMedium, 14.0, FontWeight.w400),
      'labelLarge': (t.labelLarge, 16.0, FontWeight.w700),
      'labelMedium': (t.labelMedium, 13.0, FontWeight.w600),
      'labelSmall': (t.labelSmall, 12.0, FontWeight.w600),
    };
    expected.forEach((name, spec) {
      final (style, size, weight) = spec;
      expect(style?.fontSize, size, reason: name);
      expect(style?.fontWeight, weight, reason: name);
      expect(style?.fontFamily, 'BeVietnamPro', reason: name);
    });
  });

  test('AC-1: nút chính cao 52, nền brand, chữ onBrand', () {
    final style = theme.filledButtonTheme.style!;
    expect(style.minimumSize?.resolve({})?.height, 52);
    expect(style.backgroundColor?.resolve({}), AppColors.brand);
    expect(style.foregroundColor?.resolve({}), AppColors.onBrand);
  });

  test('AC-2: chữ trên nền mỗi tông badge và mỗi nhóm phản hồi đạt ≥4.5:1', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final (hi, lo) = la > lb ? (la, lb) : (lb, la);
      return (hi + 0.05) / (lo + 0.05);
    }

    final status = theme.extension<AppStatusColors>()!;
    for (final tone in AppStatusTone.values) {
      final colors = status.tone(tone);
      expect(
        contrast(colors.foreground, colors.background),
        greaterThanOrEqualTo(4.5),
        reason: tone.name,
      );
    }
    for (final kind in AppFeedback.values) {
      final colors = status.feedbackOf(kind);
      expect(
        contrast(colors.foreground, colors.background),
        greaterThanOrEqualTo(4.5),
        reason: kind.name,
      );
    }
    expect(
      contrast(AppColors.onBrand, AppColors.brand),
      greaterThanOrEqualTo(4.5),
      reason: 'nút chính',
    );
  });

  testWidgets('Font BeVietnamPro được đóng gói đủ 4 weight', (tester) async {
    final manifest = await rootBundle.loadString('FontManifest.json');
    final families = (jsonDecode(manifest) as List)
        .cast<Map<String, dynamic>>();
    final family = families.firstWhere(
      (f) => f['family'] == 'BeVietnamPro',
      orElse: () => fail('FontManifest thiếu BeVietnamPro'),
    );
    final weights = (family['fonts'] as List)
        .map((f) => (f as Map<String, dynamic>)['weight'])
        .toSet();
    expect(weights, {400, 500, 600, 700});
  });
}
