import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Badge viên thuốc cao 28, chữ 13/600, icon 14; Clay: không viền, quầng màu tông (DESIGN.md §6.2).
/// Tông `blue` không icon có chấm sáng thay icon.
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
    final showDot = icon == null && tone == AppStatusTone.blue;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.badgeHeight),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.tinted(colors.main, strength: 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconBadge, color: colors.foreground),
            const SizedBox(width: AppSpacing.space1),
          ],
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.main,
                shape: BoxShape.circle,
                boxShadow: MediaQuery.disableAnimationsOf(context)
                    ? null
                    : [
                        BoxShadow(
                          color: colors.main.withValues(alpha: 0.25),
                          spreadRadius: 3,
                        ),
                      ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
