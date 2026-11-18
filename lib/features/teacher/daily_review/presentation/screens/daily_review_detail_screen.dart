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

/// Chi tiết một loại đánh giá của bé — CHỈ XEM trên App giáo viên.
class DailyReviewDetailScreen extends StatefulWidget {
  const DailyReviewDetailScreen({
    super.key,
    required this.childId,
    this.view = ReviewDetailView.day,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final String childId;
  final ReviewDetailView view;
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
  List<PeriodReview>? _periods;
  Object? _error;

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
      if (!mounted) return;
      setState(() {
        _day = day;
        _kid = day.kids
            .where((item) => item.childId == widget.childId)
            .firstOrNull;
        _periods = periods
            .where((item) => item.childId == widget.childId)
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final kid = _kid;
    return Scaffold(
      appBar: AppBar(title: Text(_title(widget.view))),
      body: _error != null
          ? Center(
              child: AppErrorState(
                title: 'Chưa tải được đánh giá',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: _load,
              ),
            )
          : day == null || _periods == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            )
          : kid == null
          ? const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không có đánh giá của bé này',
                message: 'Bé không có trong lớp đang chọn.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                _ChildHeader(
                  kid: kid,
                  showPresence: widget.view == ReviewDetailView.day,
                ),
                const SizedBox(height: AppSpacing.space4),
                ...switch (widget.view) {
                  ReviewDetailView.day => _dayContent(context, day, kid),
                  ReviewDetailView.week => _periodContent(
                    _periods!.where(
                      (review) => review.kind == ReviewPeriodKind.week,
                    ),
                  ),
                  ReviewDetailView.theme => _periodContent(
                    _periods!.where(
                      (review) => review.kind == ReviewPeriodKind.theme,
                    ),
                  ),
                  ReviewDetailView.semester => _periodContent(
                    _periods!.where(
                      (review) => review.kind == ReviewPeriodKind.semester,
                    ),
                  ),
                  ReviewDetailView.yearEnd => _periodContent(
                    _periods!.where(
                      (review) => review.kind == ReviewPeriodKind.yearEnd,
                    ),
                  ),
                },
              ],
            ),
    );
  }

  List<Widget> _dayContent(BuildContext context, ReviewDay day, KidReview kid) {
    final textTheme = Theme.of(context).textTheme;
    return [
      AppBanner(
        icon: AppIcons.review,
        title: 'Hoạt động · ${DateLabels.dayMonth(day.date)}',
        message: day.activityLine,
      ),
      const SizedBox(height: AppSpacing.space3),
      if (kid.state == KidReviewState.absent)
        const AppEmptyState(
          icon: AppIcons.calendarOff,
          title: 'Vắng hôm nay',
          message: 'Không có đánh giá ngày.',
        )
      else if (kid.state == KidReviewState.pending)
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
        if (kid.comment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          _TextCard(title: 'Nhận xét về bé', text: kid.comment),
        ],
        if (kid.attentionNotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          // BE `behaviors` (ObservedBehavior) — nhãn như Web BEHAVIORS
          AppBanner(title: 'Hành vi', message: kid.attentionNotes.join(' · ')),
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
      if (day.classComment.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.space4),
        _TextCard(title: 'Nhận xét chung của lớp', text: day.classComment),
      ],
      const SizedBox(height: AppSpacing.space3),
      Text('Chỉ xem · dữ liệu được ghi trên web.', style: textTheme.bodyMedium),
    ];
  }

  List<Widget> _periodContent(Iterable<PeriodReview> reviews) {
    final visible = reviews.toList();
    if (visible.isEmpty) {
      return const [
        AppEmptyState(
          icon: AppIcons.review,
          title: 'Chưa có nhận xét',
          message: 'Kỳ này chưa có dữ liệu của bé.',
        ),
      ];
    }
    return [
      for (final review in visible) ...[
        _PeriodCard(review: review),
        const SizedBox(height: AppSpacing.space3),
      ],
    ];
  }

  static String _title(ReviewDetailView view) => switch (view) {
    ReviewDetailView.day => 'Đánh giá ngày',
    ReviewDetailView.week => 'Nhận xét tuần',
    ReviewDetailView.theme => 'Đánh giá cuối chủ đề',
    ReviewDetailView.semester => 'Đánh giá học kỳ',
    ReviewDetailView.yearEnd => 'Đánh giá cuối năm',
  };

  /// Tông chỉ để dễ nhìn, luôn kèm chữ; nhãn theo thang BE của từng mặt.
  static AppStatusTone _tone(String? level) => switch (level) {
    'Ăn hết' ||
    'Ngủ tốt' ||
    'Vui vẻ' ||
    'Tích cực' ||
    'Bình thường' ||
    'Đạt' => AppStatusTone.green,
    'Ăn ít' || 'Ngủ ít' || 'Buồn' || 'Có biểu hiện' => AppStatusTone.orange,
    'Không ăn' ||
    'Không ngủ' ||
    'Quấy khóc' ||
    'Chưa tích cực' ||
    'Chưa đạt' => AppStatusTone.red,
    _ => AppStatusTone.gray,
  };
}

class _ChildHeader extends StatelessWidget {
  const _ChildHeader({required this.kid, required this.showPresence});

  final KidReview kid;
  final bool showPresence;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Row(
        children: [
          const AppIconTile(icon: AppIcons.childFace, tone: AppStatusTone.blue),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kid.fullName, style: textTheme.titleMedium),
                if (showPresence)
                  Text(kid.presenceLine, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space1),
          Text(text),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.periodLabel, style: textTheme.titleSmall),
              ),
              AppStatusBadge(
                label: review.statusLabel,
                tone: review.statusLabel == 'Đang cập nhật'
                    ? AppStatusTone.gray
                    : AppStatusTone.green,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(review.summary),
          if (review.attentionNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text('Lưu ý: ${review.attentionNote}'),
          ],
        ],
      ),
    );
  }
}
