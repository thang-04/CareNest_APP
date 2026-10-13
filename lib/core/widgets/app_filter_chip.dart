import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Chip lọc/chọn viên thuốc cao 36, vùng chạm 48; đang chọn nền `primarySoft` chữ `onBrand`.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      color: selected ? AppColors.onBrand : AppColors.textPrimary,
    );
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            // minHeight thay chiều cao cứng: chữ phóng lớn thì chip cao lên, không tràn
            constraints: const BoxConstraints(
              minHeight: AppSizes.filterChipHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySoft : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected
                    ? AppColors.primaryBorder
                    : AppColors.borderStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: style?.color),
                  const SizedBox(width: 6),
                ],
                Flexible(child: Text(label, style: style)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
