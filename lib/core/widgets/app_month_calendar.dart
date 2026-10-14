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
/// Chọn một ngày (`selected`) hoặc một khoảng (`rangeStart`–`rangeEnd`). Chú giải màu do màn tự đặt bên dưới.
class AppMonthCalendar extends StatelessWidget {
  const AppMonthCalendar({
    super.key,
    required this.month,
    this.selected,
    this.rangeStart,
    this.rangeEnd,
    this.isDayEnabled,
    this.markers = const {},
    this.onSelected,
  });

  /// Bất kỳ ngày nào trong tháng cần hiện.
  final DateTime month;
  final DateTime? selected;

  /// Khoảng đang chọn; hai đầu tô nền `brand`, giữa tô `primarySoft`.
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  /// Ngày không chọn được (vd. đã qua) ⇒ chữ mờ, không bấm; null ⇒ mọi ngày bấm được.
  final bool Function(DateTime day)? isDayEnabled;

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
    bool same(DateTime? other) =>
        other != null &&
        other.year == date.year &&
        other.month == date.month &&
        other.day == day;
    final start = rangeStart;
    final end = rangeEnd ?? rangeStart;
    final isEndpoint = same(start) || same(end);
    final inRange =
        start != null &&
        end != null &&
        !date.isBefore(start) &&
        !date.isAfter(end);
    final isSelected = same(selected) || isEndpoint;
    final enabled = isDayEnabled?.call(date) ?? true;
    final isWeekend = date.weekday >= DateTime.saturday;
    // Dải nền nối hai đầu khoảng: đầu khoảng tô nửa phải, cuối khoảng tô nửa trái
    final hasRange = !DateUtils.isSameDay(start, end);
    final band = !inRange || !hasRange
        ? null
        : same(start)
        ? const [Colors.transparent, AppColors.primarySoft]
        : same(end)
        ? const [AppColors.primarySoft, Colors.transparent]
        : const [AppColors.primarySoft, AppColors.primarySoft];
    final marker = markers[day];
    final textTheme = Theme.of(context).textTheme;
    final markerColor = marker == null
        ? null
        : AppStatusColors.of(context).tone(marker.tone).main;
    return Semantics(
      container: true,
      button: onSelected != null,
      selected: isSelected || inRange,
      enabled: enabled,
      label: [DateLabels.weekdayDate(date), ?marker?.label].join(', '),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onSelected == null || !enabled ? null : () => onSelected!(date),
        radius: 22,
        child: Container(
          height: AppSizes.minimumTapTarget,
          decoration: band == null
              ? null
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: band,
                    stops: const [0.5, 0.5],
                  ),
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: isEndpoint
                    ? const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      )
                    : isSelected
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
                      color: isEndpoint
                          ? AppColors.onBrand
                          : isSelected
                          ? AppColors.surface
                          : !enabled || isWeekend
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
