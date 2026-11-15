import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';

/// Dải ngày trong tuần (T2 12/10 …), ô đang chọn nền `brand`; Clay: không viền, gờ đáy (DESIGN.md §8.2 Danh sách).
class AppDayStrip extends StatelessWidget {
  const AppDayStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.onChanged,
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _DayTile(
              day: days[i],
              selected: _sameDay(days[i], selected),
              onTap: () => onChanged(days[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? AppColors.onBrand : AppColors.textPrimary;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: DateLabels.weekdayDate(day),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            constraints: const BoxConstraints(
              minHeight: AppSizes.minimumTapTarget,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: selected
                  ? AppShadows.buttonPrimary
                  : AppShadows.buttonSecondary,
            ),
            // Ô hẹp + chữ phóng lớn ⇒ thu nhỏ chữ trong ô thay vì tràn
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  Text(
                    DateLabels.weekdayShort(day),
                    style: textTheme.titleSmall?.copyWith(color: foreground),
                  ),
                  Text(
                    DateLabels.dayMonth(day),
                    style: textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.onBrand : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
