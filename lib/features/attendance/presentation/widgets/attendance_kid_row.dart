import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/attendance/domain/arrival_health.dart';
import 'package:carenest_app/features/attendance/domain/attendance.dart';
import 'package:carenest_app/features/attendance/presentation/widgets/arrival_health_section.dart';

/// Một trẻ — mockup T02: tên + ghi chú · hai nút Có mặt / Vắng; có mặt thì kiểm tra sức khỏe đầu ngày
/// (HLT-07), vắng thì không có ô sức khỏe. Bé có đơn nghỉ khóa ở "Có phép (theo đơn)" (ATT-04, ATT-09).
class AttendanceKidRow extends StatelessWidget {
  const AttendanceKidRow({
    super.key,
    required this.kid,
    required this.onPresent,
    required this.onAbsent,
    required this.onHealthChanged,
    this.healthErrors = const {},
    this.enabled = true,
  });

  final KidAttendance kid;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final ValueChanged<ArrivalHealth> onHealthChanged;
  final Map<ArrivalHealthField, String> healthErrors;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nameBlock = Padding(
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
          if (kid.note case final note?)
            Text(
              note,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
    final Widget actions = kid.hasLeaveNotice
        ? Semantics(
            container: true,
            label: '${kid.fullName}: có phép theo đơn, không đổi được',
            excludeSemantics: true,
            child: const AppStatusBadge(
              label: 'Có phép (theo đơn)',
              tone: AppStatusTone.blue,
              icon: AppIcons.lock,
            ),
          )
        // Wrap: chữ lớn + nút đang chọn in đậm thì nút xuống dòng thay vì tràn
        : Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              _Toggle(
                label: 'Có mặt',
                semanticLabel: '${kid.fullName}: có mặt',
                tone: AppStatusTone.green,
                selected: kid.status == AttendanceStatus.present,
                onTap: enabled ? onPresent : null,
              ),
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
    final showHealth =
        !kid.hasLeaveNotice && kid.status == AttendanceStatus.present;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chữ lớn ⇒ nút xuống dòng dưới tên thay vì ép tràn
          if (stacked) ...[
            nameBlock,
            const SizedBox(height: AppSpacing.space2),
            actions,
          ] else
            Row(
              children: [
                Expanded(child: nameBlock),
                const SizedBox(width: AppSpacing.space2),
                actions,
              ],
            ),
          if (showHealth) ...[
            const SizedBox(height: AppSpacing.space1),
            ArrivalHealthSection(
              key: ValueKey('health-${kid.childId}'),
              childId: kid.childId,
              childName: kid.fullName,
              health: kid.health,
              errors: healthErrors,
              enabled: enabled,
              onChanged: onHealthChanged,
            ),
          ],
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
        borderRadius: BorderRadius.circular(AppRadius.control),
        // Viền ngoài 6 ⇒ vùng chạm 48 dù nút nhìn thấy cao 36
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            constraints: const BoxConstraints(
              minHeight: AppSizes.filterChipHeight,
              minWidth: 56,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            // Figma GV02: nút chọn nền nhạt + viền đậm cùng tông; chưa chọn trắng viền mảnh
            decoration: BoxDecoration(
              color: selected ? colors.background : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
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
      ),
    );
  }
}
