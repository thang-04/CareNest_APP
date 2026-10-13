import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

@immutable
class AppTimelineEntry {
  const AppTimelineEntry({
    required this.title,
    this.time,
    this.subtitle,
    this.isCurrent = false,
  });

  /// "07:42"; null khi mốc giờ đã nằm trong tiêu đề.
  final String? time;
  final String title;
  final String? subtitle;

  /// Mốc đang diễn ra: chấm đặc, nền nhạt.
  final bool isCurrent;
}

/// Dòng thời gian dọc: cột giờ (tuỳ chọn) · chấm + đường nối · nội dung.
class AppTimeline extends StatelessWidget {
  const AppTimeline({super.key, required this.entries});

  final List<AppTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final showTime = entries.any((entry) => entry.time != null);
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            showTime: showTime,
            isFirst: i == 0,
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.showTime,
    required this.isFirst,
    required this.isLast,
  });

  final AppTimelineEntry entry;
  final bool showTime;
  final bool isFirst;
  final bool isLast;

  static const double _dot = 14;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final current = entry.isCurrent;
    final label = [
      ?entry.time,
      entry.title,
      ?entry.subtitle,
      if (current) 'đang diễn ra',
    ].join(', ');
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      // IntrinsicHeight để đường nối kéo đúng chiều cao nội dung; danh sách mốc trong ngày ngắn
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTime)
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space3),
                  child: Text(
                    entry.time ?? '',
                    style: textTheme.labelMedium?.copyWith(
                      color: current ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: AppSpacing.space3 + 2,
                    color: isFirst ? Colors.transparent : AppColors.border,
                  ),
                  Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: current ? AppColors.primary : AppColors.surface,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : AppColors.border,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                  decoration: current
                      ? BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.primaryBorder),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: textTheme.titleSmall),
                      if (entry.subtitle != null)
                        Text(
                          entry.subtitle!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
