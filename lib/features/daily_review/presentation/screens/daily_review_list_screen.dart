import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/daily_review/domain/daily_review.dart';

/// Đánh giá hằng ngày — danh sách bé (mockup T04). Bé vắng không cần đánh giá.
class DailyReviewListScreen extends StatefulWidget {
  const DailyReviewListScreen({
    super.key,
    required this.onOpenKid,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  /// Mở màn đánh giá một bé; trả về khi màn đóng để tải lại.
  final Future<void> Function(String childId) onOpenKid;
  final String classId;
  final DailyReviewSource? source;

  @override
  State<DailyReviewListScreen> createState() => _DailyReviewListScreenState();
}

class _DailyReviewListScreenState extends State<DailyReviewListScreen> {
  late final DailyReviewSource _source =
      widget.source ?? FakeDailyReviewSource.shared;
  ReviewDay? _day;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final day = await _source.loadDay(widget.classId);
      if (mounted) setState(() => _day = day);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _open(KidReview kid) async {
    await widget.onOpenKid(kid.childId);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final present =
        day?.kids.where((kid) => kid.state != KidReviewState.absent).length ??
        0;
    final done =
        day?.kids.where((kid) => kid.state == KidReviewState.done).length ?? 0;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá hằng ngày'),
        actions: [
          if (day != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space4),
              child: Center(
                child: Text(
                  '$done/$present bé',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (_error != null)
            AppErrorState(
              title: 'Chưa tải được danh sách',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: _load,
            )
          else if (day == null)
            const AppSkeletonList(rows: 5)
          else ...[
            AppStatRow(
              tiles: [
                AppStatTile(
                  value: '$done',
                  label: 'Đã đánh giá',
                  tone: AppStatusTone.green,
                ),
                AppStatTile(
                  value: '${present - done}',
                  label: 'Chưa đánh giá',
                  tone: AppStatusTone.orange,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            AppSearchField(
              hint: 'Tìm tên bé…',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.space3),
            for (final kid in day.kids.where(
              (kid) => matchesSearch(kid.fullName, _query),
            )) ...[
              AppCard(
                flush: true,
                child: AppListRow(
                  leading: AppAvatar(name: kid.fullName),
                  title: kid.fullName,
                  subtitle: Text(_subtitle(kid, day)),
                  trailing: switch (kid.state) {
                    KidReviewState.pending => AppButton(
                      label: 'Đánh giá',
                      small: true,
                      onPressed: () => _open(kid),
                    ),
                    KidReviewState.done => const AppStatusBadge(
                      label: 'Đã xong',
                      tone: AppStatusTone.green,
                    ),
                    KidReviewState.absent => const AppStatusBadge(
                      label: 'Vắng',
                      tone: AppStatusTone.gray,
                    ),
                  },
                  onTap: kid.state == KidReviewState.absent
                      ? null
                      : () => _open(kid),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Chạm một bé để mở màn đánh giá trong ngày. Bé vắng không cần đánh giá.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  static String _subtitle(KidReview kid, ReviewDay day) => switch (kid.state) {
    KidReviewState.absent => kid.presenceLine,
    KidReviewState.pending => '${kid.presenceLine} · chưa đánh giá',
    KidReviewState.done => [
      for (final criterion in day.criteria) ?kid.answers[criterion.id],
    ].join(' · '),
  };
}
