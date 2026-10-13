import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';

/// Đánh dấu một ngày: tông chấm + nhãn đọc cho trình đọc màn hình (không chỉ bằng màu).
@immutable
class AppDayMarker {
  const AppDayMarker({required this.tone, required this.label});

  final AppStatusTone tone;
  final String label;
}

/// Lịch tháng, thứ Hai đầu tuần; chấm dưới số theo `markers` do màn truyền vào.
/// Chú giải màu do màn tự đặt bên dưới.
class AppMonthCalendar extends StatelessWidget {
  const AppMonthCalendar({
    super.key,
    required this.month,
    this.selected,
    this.markers = const {},
    this.onSelected,
  });

  /// Bất kỳ ngày nào trong tháng cần hiện.
  final DateTime month;
  final DateTime? selected;

  /// Khoá là số ngày trong tháng.
  final Map<int, AppDayMarker> markers;
  final ValueChanged<DateTime>? onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();
    return Column(
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final header in DateLabels.weekdayHeaders)
                Expanded(
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _cell(context, row * 7 + col - leading + 1)),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int day) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: AppSizes.minimumTapTarget);
    }
    final date = DateTime(month.year, month.month, day);
    final isSelected =
        selected != null &&
        selected!.year == date.year &&
        selected!.month == date.month &&
        selected!.day == day;
    final isWeekend = date.weekday >= DateTime.saturday;
    final marker = markers[day];
    final textTheme = Theme.of(context).textTheme;
    final markerColor = marker == null
        ? null
        : AppStatusColors.of(context).tone(marker.tone).main;
    return Semantics(
      container: true,
      button: onSelected != null,
      selected: isSelected,
      label: [DateLabels.weekdayDate(date), ?marker?.label].join(', '),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onSelected == null ? null : () => onSelected!(date),
        radius: 22,
        child: SizedBox(
          height: AppSizes.minimumTapTarget,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: isSelected
                    ? const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$day',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : null,
                      color: isSelected
                          ? AppColors.surface
                          : isWeekend
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: markerColor ?? Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
