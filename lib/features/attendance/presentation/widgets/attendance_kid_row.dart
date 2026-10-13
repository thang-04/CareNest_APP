import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/features/attendance/domain/attendance.dart';

/// Một trẻ — mockup T02: tên + ghi chú (bấm để báo ăn) · hai nút Có mặt / Vắng.
/// Có phép theo đơn nghỉ thì không nút nào sáng, ghi chú cho biết lý do.
class AttendanceKidRow extends StatelessWidget {
  const AttendanceKidRow({
    super.key,
    required this.kid,
    required this.onPresent,
    required this.onAbsent,
    required this.onTapMeals,
    this.enabled = true,
  });

  final KidAttendance kid;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback onTapMeals;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mealLine = kid.status == AttendanceStatus.present && !kid.eats
        ? 'Không ăn ▾'
        : null;
    final subtitle = [?kid.note, ?mealLine].join(' · ');
    final nameBlock = Semantics(
      container: true,
      button: true,
      label: 'Báo ăn cho ${kid.fullName}',
      child: InkWell(
        onTap: enabled ? onTapMeals : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kid.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final toggles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Toggle(
          label: 'Có mặt',
          semanticLabel: '${kid.fullName}: có mặt',
          tone: AppStatusTone.green,
          selected: kid.status == AttendanceStatus.present,
          onTap: enabled ? onPresent : null,
        ),
        const SizedBox(width: AppSpacing.space2),
        _Toggle(
          label: 'Vắng',
          semanticLabel: '${kid.fullName}: vắng',
          tone: AppStatusTone.red,
          selected: kid.status == AttendanceStatus.unexcused,
          onTap: enabled ? onAbsent : null,
        ),
      ],
    );
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      // Chữ lớn ⇒ nút xuống dòng dưới tên thay vì ép tràn
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameBlock,
                const SizedBox(height: AppSpacing.space2),
                toggles,
              ],
            )
          : Row(
              children: [
                Expanded(child: nameBlock),
                const SizedBox(width: AppSpacing.space2),
                toggles,
              ],
            ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.semanticLabel,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final AppStatusTone tone;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.of(context).tone(tone);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTapTarget - 4,
            minWidth: 64,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
          decoration: BoxDecoration(
            color: selected ? colors.background : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? colors.main : AppColors.borderStrong,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.foreground : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
