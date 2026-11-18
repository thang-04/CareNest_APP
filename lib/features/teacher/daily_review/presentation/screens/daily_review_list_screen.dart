import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';

/// Đánh giá trẻ theo ngày, tuần và kỳ — CHỈ XEM trên App giáo viên.
class DailyReviewListScreen extends StatefulWidget {
  const DailyReviewListScreen({
    super.key,
    required this.onOpenKid,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  /// Mở màn đánh giá một bé; trả về khi màn đóng để tải lại.
  final Future<void> Function(String childId, ReviewDetailView view) onOpenKid;
  final String classId;
  final DailyReviewSource? source;

  @override
  State<DailyReviewListScreen> createState() => _DailyReviewListScreenState();
}

enum _ReviewView { day, week, theme, semester, yearEnd }

class _DailyReviewListScreenState extends State<DailyReviewListScreen> {
  late final DailyReviewSource _source =
      widget.source ?? FakeDailyReviewSource.shared;
  ReviewDay? _day;
  List<PeriodReview>? _periods;
  Object? _error;
  String _query = '';
  _ReviewView _view = _ReviewView.day;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final day = await _source.loadDay(widget.classId);
      final periods = await _source.loadPeriods(widget.classId);
      if (mounted) {
        setState(() {
          _day = day;
          _periods = periods;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _open(KidReview kid) async {
    await widget.onOpenKid(kid.childId, ReviewDetailView.day);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá trẻ')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (_error != null)
            AppErrorState(
              title: 'Chưa tải được danh sách',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: _load,
            )
          else if (day == null || _periods == null)
            const AppSkeletonList(rows: 5)
          else ...[
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space1,
              children: [
                for (final (view, label) in const [
                  (_ReviewView.day, 'Ngày'),
                  (_ReviewView.week, 'Tuần'),
                  (_ReviewView.theme, 'Cuối chủ đề'),
                  (_ReviewView.semester, 'Học kỳ'),
                  (_ReviewView.yearEnd, 'Cuối năm'),
                ])
                  AppFilterChip(
                    label: label,
                    selected: _view == view,
                    onSelected: () => setState(() => _view = view),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            AppSearchField(
              hint: 'Tìm tên bé…',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.space3),
            ...switch (_view) {
              _ReviewView.day => _dayContent(day),
              _ReviewView.week => _periodContent(
                _periods!.where(
                  (review) => review.kind == ReviewPeriodKind.week,
                ),
                ReviewDetailView.week,
              ),
              _ReviewView.theme => _periodContent(
                _periods!.where(
                  (review) => review.kind == ReviewPeriodKind.theme,
                ),
                ReviewDetailView.theme,
              ),
              _ReviewView.semester => _periodContent(
                _periods!.where(
                  (review) => review.kind == ReviewPeriodKind.semester,
                ),
                ReviewDetailView.semester,
              ),
              _ReviewView.yearEnd => _periodContent(
                _periods!.where(
                  (review) => review.kind == ReviewPeriodKind.yearEnd,
                ),
                ReviewDetailView.yearEnd,
              ),
            },
          ],
        ],
      ),
    );
  }

  List<Widget> _dayContent(ReviewDay day) {
    final present = day.kids
        .where((kid) => kid.state != KidReviewState.absent)
        .length;
    final done = day.kids
        .where((kid) => kid.state == KidReviewState.done)
        .length;
    final textTheme = Theme.of(context).textTheme;
    return [
      if (day.classComment.isNotEmpty) ...[
        AppBanner(
          icon: AppIcons.info,
          title: 'Nhận xét chung của lớp',
          message: day.classComment,
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      AppStatRow(
        tiles: [
          AppStatTile(
            value: '$done',
            label: 'Đã có',
            tone: AppStatusTone.green,
          ),
          AppStatTile(
            value: '${present - done}',
            label: 'Chưa có',
            tone: AppStatusTone.orange,
          ),
        ],
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
              KidReviewState.pending => const AppStatusBadge(
                label: 'Chưa có',
                tone: AppStatusTone.orange,
              ),
              KidReviewState.done => const AppStatusBadge(
                label: 'Đã có',
                tone: AppStatusTone.green,
              ),
              KidReviewState.absent => const AppStatusBadge(
                label: 'Vắng',
                tone: AppStatusTone.gray,
              ),
            },
            onTap: kid.state == KidReviewState.absent ? null : () => _open(kid),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
      Text(
        'Chỉ xem · chạm một bé để xem chi tiết.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
    ];
  }

  List<Widget> _periodContent(
    Iterable<PeriodReview> reviews,
    ReviewDetailView view,
  ) {
    final visible = reviews
        .where((review) => matchesSearch(review.fullName, _query))
        .toList();
    if (visible.isEmpty) {
      return const [
        AppEmptyState(
          icon: AppIcons.review,
          title: 'Chưa có nhận xét',
          message: 'Kỳ này chưa có dữ liệu.',
        ),
      ];
    }
    return [
      for (final review in visible) ...[
        AppCard(
          flush: true,
          child: AppListRow(
            leading: AppAvatar(name: review.fullName),
            title: review.fullName,
            subtitle: Text('${review.periodLabel} · ${review.summary}'),
            trailing: AppStatusBadge(
              label: review.statusLabel,
              tone: review.statusLabel == 'Đang cập nhật'
                  ? AppStatusTone.gray
                  : AppStatusTone.green,
            ),
            onTap: () => widget.onOpenKid(review.childId, view),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }

  static String _subtitle(KidReview kid, ReviewDay day) => switch (kid.state) {
    KidReviewState.absent => kid.presenceLine,
    KidReviewState.pending => '${kid.presenceLine} · chưa đánh giá',
    KidReviewState.done =>
      kid.comment.isNotEmpty
          ? '${kid.presenceLine} · ${kid.comment}'
          : [
              for (final criterion in day.criteria) ?kid.answers[criterion.id],
            ].join(' · '),
  };
}
