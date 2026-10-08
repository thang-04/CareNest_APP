import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_theme.dart';

void main() {
  final theme = buildLightTheme();

  test(
    'AC-2: ColorScheme giữ đúng màu đã duyệt, không lấy màu sinh từ seed',
    () {
      final scheme = theme.colorScheme;
      expect(scheme.primary, const Color(0xFF1565E0));
      expect(scheme.onPrimary, const Color(0xFFFFFFFF));
      expect(scheme.primaryContainer, AppColors.primaryContainer);
      expect(scheme.onPrimaryContainer, AppColors.brandBlue700);
      expect(scheme.error, const Color(0xFFE03131));
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.onSurface, AppColors.textPrimary);
      expect(scheme.onSurfaceVariant, AppColors.textSecondary);
      expect(scheme.outline, AppColors.borderStrong);
      expect(scheme.outlineVariant, AppColors.border);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F8FC));
    },
  );

  test('AC-2: thang chữ theo DESIGN §5.1, font BeVietnamPro', () {
    final t = theme.textTheme;
    final expected = {
      'headlineSmall': (t.headlineSmall, 24.0, FontWeight.w700),
      'titleLarge': (t.titleLarge, 20.0, FontWeight.w600),
      'titleMedium': (t.titleMedium, 16.0, FontWeight.w600),
      'bodyLarge': (t.bodyLarge, 16.0, FontWeight.w400),
      'bodyMedium': (t.bodyMedium, 14.0, FontWeight.w400),
      'labelLarge': (t.labelLarge, 14.0, FontWeight.w600),
      'labelSmall': (t.labelSmall, 12.0, FontWeight.w400),
    };
    expected.forEach((name, spec) {
      final (style, size, weight) = spec;
      expect(style?.fontSize, size, reason: name);
      expect(style?.fontWeight, weight, reason: name);
      expect(style?.fontFamily, 'BeVietnamPro', reason: name);
      expect(style?.color, AppColors.textPrimary, reason: name);
    });
  });

  test('AC-2: đăng ký AppStatusColors với đủ tông', () {
    final status = theme.extension<AppStatusColors>();
    expect(status, isNotNull);
    expect(status!.success, AppColors.success);
    expect(status.tones.keys, containsAll(AppStatusTone.values));
    expect(status.tone(AppStatusTone.danger).foreground, AppColors.dangerText);
  });

  test('Chữ chip đạt tương phản ≥4.5:1 trên nền mỗi tông (WCAG AA)', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final (hi, lo) = la > lb ? (la, lb) : (lb, la);
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final tone in AppStatusTone.values) {
      final colors = AppStatusColors.light.tone(tone);
      expect(
        contrast(colors.foreground, colors.background),
        greaterThanOrEqualTo(4.5),
        reason: tone.name,
      );
    }
  });

  test('AppStatusColors.lerp ở t=0 và t=1 trả về hai đầu', () {
    const a = AppStatusColors.light;
    final b = a.copyWith(success: const Color(0xFF000000));
    expect(a.lerp(b, 0).success, a.success);
    expect(a.lerp(b, 1).success, const Color(0xFF000000));
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

  test('Nút chuẩn cao tối thiểu 48', () {
    final size = theme.filledButtonTheme.style?.minimumSize?.resolve({});
    expect(size?.height, 48);
  });
}
