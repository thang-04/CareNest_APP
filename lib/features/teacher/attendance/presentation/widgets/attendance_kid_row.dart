import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';

/// Một trẻ — mockup T02: tên + ghi chú · hai nút Có mặt / Vắng. Có mặt là ăn mọi bữa (ATT-02), không nhập riêng.
/// Bé có đơn nghỉ: nút Vắng sáng + nhãn "Phụ huynh báo nghỉ", không sửa được (giống Web).
class AttendanceKidRow extends StatelessWidget {
  const AttendanceKidRow({
    super.key,
    required this.kid,
    required this.onPresent,
    required this.onAbsent,
    this.enabled = true,
  });

  final KidAttendance kid;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = kid.note ?? '';
    final nameBlock = Semantics(
      container: true,
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
            // Có phép chỉ do đơn nghỉ của phụ huynh (ATT-09), GV không chọn
            if (kid.hasLeaveNotice) ...[
              const SizedBox(height: AppSpacing.space1),
              const AppStatusBadge(
                label: 'Phụ huynh báo nghỉ',
                tone: AppStatusTone.blue,
              ),
            ],
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
    );
    final toggles = Wrap(
      spacing: 0,
      runSpacing: AppSpacing.space2,
      children: [
        _Toggle(
          label: 'Có mặt',
          semanticLabel: '${kid.fullName}: có mặt',
          tone: AppStatusTone.green,
          selected: kid.status == AttendanceStatus.present,
          // Bé có đơn nghỉ không sửa được (giống Web)
          onTap: enabled && !kid.hasLeaveNotice ? onPresent : null,
        ),
        const SizedBox(width: AppSpacing.space2),
        _Toggle(
          label: 'Vắng',
          semanticLabel: '${kid.fullName}: vắng',
          tone: AppStatusTone.red,
          selected:
              kid.status == AttendanceStatus.unexcused ||
              kid.status == AttendanceStatus.excused,
          onTap: enabled && !kid.hasLeaveNotice ? onAbsent : null,
        ),
      ],
    );
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final main = stacked
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
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.85)),
        boxShadow: AppShadows.card,
      ),
      // Chữ lớn ⇒ nút xuống dòng dưới tên thay vì ép tràn
      child: main,
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
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTapTarget - 4,
            minWidth: 64,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
          // Clay: nút chưa chọn trắng nổi gờ đáy; nút đã chọn nền tông + viền tông + quầng
          decoration: BoxDecoration(
            color: selected ? colors.background : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? colors.main : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? AppShadows.tinted(colors.main, strength: 0.35)
                : AppShadows.buttonSecondary,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colors.foreground : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
