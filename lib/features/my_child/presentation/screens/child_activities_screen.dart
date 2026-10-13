import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_timeline.dart';
import 'package:carenest_app/features/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/my_child/domain/my_child.dart';
import 'package:carenest_app/features/my_child/presentation/widgets/my_child_widgets.dart';

/// Hoạt động & đánh giá — mockup P09. Chỉ nội dung đã công bố cho phụ huynh (PAR-02);
/// nguồn hoạt động trong ngày còn OPEN (OBS-07, ADR-0006).
class ChildActivitiesScreen extends StatefulWidget {
  const ChildActivitiesScreen({
    super.key,
    required this.childId,
    this.source = const FakeMyChildSource(),
  });

  final String childId;
  final MyChildSource source;

  @override
  State<ChildActivitiesScreen> createState() => _ChildActivitiesScreenState();
}

class _ChildActivitiesScreenState extends State<ChildActivitiesScreen> {
  late Future<ActivityDay> _day = widget.source.loadActivities(widget.childId);

  // Hiện tối đa 3 ô ảnh; ô cuối phủ "+N" khi còn nhiều hơn
  static const _visiblePhotos = 3;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hoạt động & đánh giá')),
      body: FutureBuilder<ActivityDay>(
        future: _day,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được hoạt động',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(
                  () => _day = widget.source.loadActivities(widget.childId),
                ),
              ),
            );
          }
          final day = snapshot.data;
          if (day == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            );
          }
          final shown = day.photoCount.clamp(0, _visiblePhotos);
          final more = day.photoCount - shown;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppCard(
                dense: true,
                child: Text(
                  DateLabels.weekdayDate(day.date),
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall,
                ),
              ),
              if (day.review case final review?) ...[
                const SizedBox(height: AppSpacing.space3),
                AppCard(
                  dense: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Đánh giá hằng ngày',
                          children: [
                            TextSpan(
                              text: ' · ${review.teacher}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      ReviewTagWrap(tags: review.tags),
                      if (review.note != null) ...[
                        const SizedBox(height: AppSpacing.space3),
                        Text(
                          '“${review.note}”',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              Semantics(
                header: true,
                child: Text(
                  'Hoạt động trong ngày',
                  style: textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppTimeline(
                entries: [
                  for (final entry in day.entries)
                    AppTimelineEntry(
                      time: DateLabels.time24(entry.time),
                      title: entry.title,
                      subtitle: entry.detail,
                      isCurrent: entry.isCurrent,
                    ),
                ],
              ),
              if (day.photoCount > 0) ...[
                const SizedBox(height: AppSpacing.space3),
                AppCard(
                  dense: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ảnh hoạt động · ${day.photoTitle} (${day.photoCount})',
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      Row(
                        children: [
                          for (var i = 0; i < shown; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.space2),
                            Expanded(
                              child: AppPhotoPlaceholder(
                                moreCount: i == shown - 1 ? more : 0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
