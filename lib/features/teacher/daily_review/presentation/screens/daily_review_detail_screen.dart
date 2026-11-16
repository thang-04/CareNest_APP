import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';

/// Đánh giá hằng ngày — một bé, CHỈ XEM trên App (mockup T04.1): 7 mặt × 3 mức (OBS-02) + nhận xét.
/// GV nhập/sửa trên Web; App không có thao tác ghi. Không hiển thị giáo án (OBS-08).
class DailyReviewDetailScreen extends StatefulWidget {
  const DailyReviewDetailScreen({
    super.key,
    required this.childId,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final String childId;
  final String classId;
  final DailyReviewSource? source;

  @override
  State<DailyReviewDetailScreen> createState() =>
      _DailyReviewDetailScreenState();
}

class _DailyReviewDetailScreenState extends State<DailyReviewDetailScreen> {
  late final DailyReviewSource _source =
      widget.source ?? FakeDailyReviewSource.shared;
  ReviewDay? _day;
  KidReview? _kid;

  @override
  void initState() {
    super.initState();
    _source.loadDay(widget.classId).then((day) {
      if (!mounted) return;
      setState(() {
        _day = day;
        _kid = day.kids
            .where((item) => item.childId == widget.childId)
            .firstOrNull;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final kid = _kid;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá hằng ngày')),
      body: day == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            )
          : kid == null || kid.state == KidReviewState.absent
          ? const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không có đánh giá của bé này',
                message: 'Bé không có trong lớp hoặc vắng hôm nay.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                const AppBanner(
                  icon: AppIcons.info,
                  message: 'Chỉ xem. Đánh giá thực hiện trên web.',
                ),
                const SizedBox(height: AppSpacing.space3),
                AppBanner(
                  icon: AppIcons.review,
                  title: 'Hoạt động · ${DateLabels.dayMonth(day.date)}',
                  message: day.activityLine,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '${kid.fullName} · ${kid.presenceLine.toLowerCase()}',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.space3),
                if (kid.state == KidReviewState.pending)
                  const AppEmptyState(
                    icon: AppIcons.review,
                    title: 'Chưa có đánh giá',
                    message: 'Giáo viên chưa lưu đánh giá hôm nay trên web.',
                  )
                else ...[
                  AppCard(
                    flush: true,
                    child: Column(
                      children: [
                        for (final criterion in day.criteria)
                          AppListRow(
                            title: criterion.title,
                            trailing: AppStatusBadge(
                              label: kid.answers[criterion.id] ?? '—',
                              tone: _tone(kid.answers[criterion.id]),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (kid.note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space3),
                    AppCard(
                      dense: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nhận xét', style: textTheme.titleSmall),
                          const SizedBox(height: AppSpacing.space1),
                          Text(kid.note),
                        ],
                      ),
                    ),
                  ],
                  if (kid.flagged) ...[
                    const SizedBox(height: AppSpacing.space3),
                    AppStatusBadge(
                      label: 'Cờ: ${day.flagLabel}',
                      tone: AppStatusTone.green,
                      icon: AppIcons.flag,
                    ),
                  ],
                ],
              ],
            ),
    );
  }

  /// Tông màu chỉ để dễ nhìn; nhãn chữ luôn đi kèm (không truyền thông tin chỉ bằng màu).
  static AppStatusTone _tone(String? level) => switch (level) {
    'Đạt' => AppStatusTone.green,
    'Cần cố gắng' => AppStatusTone.orange,
    'Chưa đạt' => AppStatusTone.red,
    _ => AppStatusTone.gray,
  };
}
