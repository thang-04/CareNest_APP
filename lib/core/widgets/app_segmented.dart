import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Segmented Clay: rãnh lõm (gradient tối dần lên trên), ô chọn trắng nổi (DESIGN.md §B4.1).
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.disabled = const {},
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Ô khóa: chữ mờ, chạm không đổi, trình đọc màn hình đọc "đã tắt". Lý do khóa do màn hiện bằng chữ.
  final Set<T> disabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space1),
      decoration: BoxDecoration(
        // Flutter không có bóng trong ⇒ rãnh lõm bằng nền đậm hơn ở mép trên
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.border, AppColors.track],
          stops: [0, 0.45],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (final (value, label) in segments)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                enabled: !disabled.contains(value),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: disabled.contains(value)
                      ? null
                      : () => onChanged(value),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space2,
                    ),
                    decoration: BoxDecoration(
                      color: value == selected
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: value == selected
                          ? AppShadows.buttonSecondary
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: value == selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: disabled.contains(value)
                            ? AppColors.textDisabled
                            : value == selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
