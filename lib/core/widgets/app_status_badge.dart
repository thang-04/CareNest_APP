import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Badge viên thuốc cao 28, chữ 13/600, icon 14; phẳng: nền nhạt theo tông, không viền (Figma App, DESIGN.md §6.2).
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.of(context).tone(tone);
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.badgeHeight),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconBadge, color: colors.foreground),
            const SizedBox(width: AppSpacing.space1),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
                color: colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
