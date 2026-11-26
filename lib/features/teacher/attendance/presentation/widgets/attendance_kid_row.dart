import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';

/// Thẻ đơn nghỉ trên dòng trẻ — cùng chữ với Web (`LEAVE_PART_TAGS`).
String leaveTagOf(KidAttendance kid) {
  final leave = kid.leave!;
  if (leave.noticeOnly) return 'Báo nghỉ chiều sau giờ chốt';
  if (leave.isHalfDay) {
    return leave.part == DayPartCode.morning
        ? 'Nghỉ buổi sáng · PH báo'
        : 'Nghỉ buổi chiều · PH báo';
  }
  return switch (kid.status) {
    AttendanceStatus.excused => 'Vắng có phép · Phụ huynh báo nghỉ',
    AttendanceStatus.present => 'Đến dù có đơn nghỉ',
    _ => 'Phụ huynh báo nghỉ',
  };
}

String _partLabel(DayPartCode part) => switch (part) {
  DayPartCode.fullDay => 'Cả ngày',
  DayPartCode.morning => 'Chỉ sáng',
  DayPartCode.afternoon => 'Chỉ chiều',
};

String _temperatureText(double value) =>
    '${value.toStringAsFixed(1).replaceAll('.', ',')} °C';

/// Một trẻ — mockup T02: tên + thẻ thông tin BE trả · hai nút Có mặt / Vắng. Bữa ăn chọn ở màn "Trẻ tham gia ăn".
/// Thẻ đơn nghỉ chạm để xem chi tiết (BE trả, chỉ xem).
class AttendanceKidRow extends StatelessWidget {
  const AttendanceKidRow({
    super.key,
    required this.kid,
    required this.onPresent,
    required this.onAbsent,
    this.onOpenLeave,
    this.enabled = true,
  });

  final KidAttendance kid;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback? onOpenLeave;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final badges = <Widget>[
      if (kid.hasAllergy)
        const AppStatusBadge(
          label: 'Có dị ứng',
          tone: AppStatusTone.orange,
          icon: AppIcons.alertTriangle,
        ),
      if (!kid.mealRegistered)
        const AppStatusBadge(label: 'Không báo ăn', tone: AppStatusTone.gray),
      if (kid.presentPart case final part? when kid.absentPart != null)
        AppStatusBadge(label: _partLabel(part), tone: AppStatusTone.blue),
      if (kid.health.temperature case final temperature?)
        AppStatusBadge(
          label: _temperatureText(temperature),
          tone: AppStatusTone.gray,
        ),
      if (kid.health.noted)
        const AppStatusBadge(
          label: 'Cần lưu ý',
          tone: AppStatusTone.orange,
          icon: AppIcons.heart,
        ),
      if (kid.hasLeaveNotice)
        Semantics(
          button: true,
          label: '${leaveTagOf(kid)}: ${kid.fullName}. Xem đơn nghỉ',
          excludeSemantics: true,
          child: InkWell(
            onTap: onOpenLeave,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AppStatusBadge(
              label: leaveTagOf(kid),
              tone: AppStatusTone.blue,
            ),
          ),
        ),
    ];
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
            if (badges.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space1),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: badges,
              ),
            ],
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
          onTap: enabled ? onPresent : null,
        ),
        const SizedBox(width: AppSpacing.space2),
        _Toggle(
          label: 'Vắng',
          semanticLabel: '${kid.fullName}: vắng',
          tone: AppStatusTone.red,
          selected: kid.isAbsent,
          onTap: enabled ? onAbsent : null,
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
