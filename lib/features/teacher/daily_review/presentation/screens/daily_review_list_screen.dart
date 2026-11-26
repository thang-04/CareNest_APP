import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';
import 'package:carenest_app/features/teacher/shared/class_date_bar.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

/// Đánh giá trẻ — CHỈ XEM trên App: tình trạng đánh giá của cả lớp (Đã có / Chưa có); chạm một bé
/// mở trang Đánh giá của bé (Ngày, Tuần, Chủ đề, Học kỳ, Cuối năm — cùng giao diện phụ huynh).
/// Thanh Lớp · Ngày cho xem lại ngày trước (chỉ xem).
class DailyReviewListScreen extends StatefulWidget {
  const DailyReviewListScreen({
    super.key,
    required this.onOpenKid,
    this.classId = FakeClassRosterSource.classId,
    this.source,
    this.classes = const [],
    this.today,
  });

  /// Mở màn đánh giá một trẻ; trả về khi màn đóng để tải lại.
  final Future<void> Function(String childId) onOpenKid;
  final String classId;
  final DailyReviewSource? source;

  /// Các lớp chọn được; rỗng ⇒ chỉ lớp [classId].
  final List<ClassOption> classes;

  /// Hôm nay theo giờ nhà trường; mặc định ngày của máy.
  final DateTime? today;

  @override
  State<DailyReviewListScreen> createState() => _DailyReviewListScreenState();
}

class _DailyReviewListScreenState extends State<DailyReviewListScreen> {
  late final DailyReviewSource _source =
      widget.source ?? FakeDailyReviewSource.shared;
  late final DateTime _today = _dayOf(widget.today ?? DateTime.now());
  late String _classId = widget.classId;
  late DateTime _date = _today;
  ReviewDay? _day;
  Object? _error;
  String _query = '';
  int _seq = 0;

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  List<ClassOption> get _classes => widget.classes.isEmpty
      ? [ClassOption(id: widget.classId, name: 'Lớp')]
      : widget.classes;

  bool get _classReadOnly =>
      _classes.where((c) => c.id == _classId).firstOrNull?.readOnly ?? false;

  bool get _isToday => _date == _today;

  @override
  void initState() {
    super.initState();
    if (_classId.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _error = null;
      _day = null;
    });
    try {
      final day = await _source.loadDay(
        _classId,
        date: _isToday ? null : _date,
      );
      if (mounted && seq == _seq) setState(() => _day = day);
    } catch (error) {
      if (mounted && seq == _seq) setState(() => _error = error);
    }
  }

  Future<void> _open(KidReview kid) async {
    await widget.onOpenKid(kid.childId);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá trẻ')),
      body: _classId.isEmpty
          ? const Center(
              child: AppEmptyState(
                title: 'Bạn chưa được phân công lớp',
                message:
                    'Chỉ giáo viên của lớp mới xem được đánh giá hằng ngày.',
                icon: AppIcons.classGroup,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                const SchoolYearChip(),
                const SizedBox(height: AppSpacing.space3),
                ClassDateBar(
                  classes: _classes,
                  classId: _classId,
                  date: _date,
                  today: _today,
                  onClassChanged: (id) {
                    _classId = id;
                    _load();
                  },
                  onDateChanged: (date) {
                    _date = date;
                    _load();
                  },
                ),
                const SizedBox(height: AppSpacing.space3),
                ..._body(),
              ],
            ),
    );
  }

  List<Widget> _body() {
    final error = _error;
    if (error != null) {
      if (error is ApiFailure && '${error.errorCode}' == '7302') {
        return const [
          AppEmptyState(
            title: 'Ngày đã chọn không phải ngày học',
            message: 'Chọn ngày học để xem đánh giá của bé.',
          ),
        ];
      }
      return [
        AppErrorState(
          title: 'Chưa tải được đánh giá',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    final day = _day;
    if (day == null) return const [AppSkeletonList(rows: 5)];
    return _dayContent(day);
  }

  List<Widget> _banners(ReviewDay day) {
    final lock = day.yearReadOnly
        ? 'Lớp thuộc năm học đã kết thúc hoặc chưa bắt đầu, chỉ xem được.'
        : day.locked
        ? 'Ngày ${DateLabels.date(day.date)} đã khóa.'
        : null;
    final history = !_isToday || _classReadOnly;
    if (lock != null) {
      return [
        AppBanner(
          icon: AppIcons.lock,
          kind: AppBannerKind.warning,
          message: lock,
        ),
        const SizedBox(height: AppSpacing.space3),
      ];
    }
    if (history) {
      return const [
        AppBanner(
          icon: AppIcons.lock,
          message: 'Đang xem lịch sử, không sửa được.',
        ),
        SizedBox(height: AppSpacing.space3),
      ];
    }
    return const [];
  }

  List<Widget> _dayContent(ReviewDay day) {
    final textTheme = Theme.of(context).textTheme;
    final present = day.kids
        .where((kid) => kid.state != KidReviewState.absent)
        .length;
    final done = day.kids
        .where((kid) => kid.state == KidReviewState.done)
        .length;
    return [
      ..._banners(day),
      if (!day.attendanceTaken)
        AppEmptyState(
          title: 'Lớp chưa điểm danh ngày ${DateLabels.date(day.date)}',
          message: 'Điểm danh trước, chỉ bé có mặt mới được đánh giá.',
          icon: AppIcons.calendarOff,
        )
      else ...[
        AppSearchField(
          hint: 'Tìm tên bé…',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.space3),
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
              onTap: () => _open(kid),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
      ],
      Text(
        'Chỉ xem · chạm một bé để xem ngày, tuần, chủ đề, học kỳ, cuối năm.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
    ];
  }

  /// Dòng phụ như bản gốc; thêm biểu hiện sức khỏe và cờ bé ngoan do BE ghi nhận.
  static String _subtitle(KidReview kid, ReviewDay day) => switch (kid.state) {
    KidReviewState.absent => kid.presenceLine,
    KidReviewState.pending => '${kid.presenceLine} · chưa đánh giá',
    KidReviewState.done => [
      if (kid.comment.isNotEmpty) ...[
        kid.presenceLine,
        kid.comment,
      ] else ...[
        for (final criterion in day.criteria) ?kid.answers[criterion.id],
      ],
      if (kid.healthSigns.isNotEmpty) 'Sức khỏe: ${kid.healthSigns.join(', ')}',
      if (kid.flagged) 'Có cờ bé ngoan',
    ].join(' · '),
  };
}
