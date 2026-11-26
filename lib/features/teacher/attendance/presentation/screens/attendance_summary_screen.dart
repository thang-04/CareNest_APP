import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_context_chip.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_summary_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance_summary.dart';

enum _Range {
  thisMonth('Tháng này'),
  lastSevenDays('7 ngày gần nhất'),
  lastMonth('Tháng trước');

  const _Range(this.label);
  final String label;
}

/// Tổng hợp điểm danh lớp (Web `/attendance/summary`): chỉ xem. Số liệu theo ngày và theo trẻ do BE tính;
/// APP chỉ cộng các cột ngày để hiện bốn ô đầu trang như Web.
class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({
    super.key,
    required this.classId,
    this.today,
    this.source,
  });

  final String classId;

  /// Hôm nay theo giờ trường (mặc định ngày máy).
  final DateTime? today;
  final AttendanceSummarySource? source;

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  late final AttendanceSummarySource _source =
      widget.source ?? FakeAttendanceSummarySource();
  late final DateTime _today = _dateOnly(widget.today ?? DateTime.now());
  _Range _range = _Range.thisMonth;
  AttendanceSummary? _summary;
  bool _loading = true;
  Object? _error;
  int _loadSeq = 0;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) _bounds(_Range range) => switch (range) {
    _Range.thisMonth => (DateTime(_today.year, _today.month), _today),
    _Range.lastSevenDays => (
      DateTime(_today.year, _today.month, _today.day - 6),
      _today,
    ),
    _Range.lastMonth => (
      DateTime(_today.year, _today.month - 1),
      DateTime(_today.year, _today.month, 0),
    ),
  };

  Future<void> _load() async {
    final seq = ++_loadSeq;
    final (from, to) = _bounds(_range);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _source.load(widget.classId, from: from, to: to);
      // Bỏ phản hồi muộn của khoảng đã đổi
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _pick(_Range range) {
    if (range == _range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng hợp điểm danh')),
      body: _buildBody(),
    );
  }

  Widget _filters(AttendanceSummary? summary) {
    final (from, to) = _bounds(_range);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            AppContextChip(
              label: summary?.className.isNotEmpty ?? false
                  ? summary!.className
                  : 'Lớp của tôi',
              leading: const Icon(
                AppIcons.classGroup,
                size: AppSizes.iconInline,
              ),
              onTap: null,
            ),
            AppContextChip(
              label: DateLabels.range(from, to),
              leading: const Icon(AppIcons.calendar, size: AppSizes.iconInline),
              onTap: null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final range in _Range.values) ...[
                AppFilterChip(
                  label: range.label,
                  selected: _range == range,
                  onSelected: () => _pick(range),
                ),
                const SizedBox(width: AppSpacing.space2),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
    );
  }

  Widget _buildBody() {
    final summary = _summary;
    if (summary == null && _error == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: AppSkeletonList(rows: 6),
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _filters(summary),
          AppErrorState(
            title: 'Chưa tải được tổng hợp',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            onRetry: _load,
          ),
        ],
      );
    }
    final data = summary!;
    final textTheme = Theme.of(context).textTheme;
    final presentTotal = data.days.fold<int>(0, (sum, d) => sum + d.present);
    final excusedTotal = data.days.fold<int>(0, (sum, d) => sum + d.excused);
    final unexcusedTotal = data.days.fold<int>(
      0,
      (sum, d) => sum + d.unexcused,
    );
    final children = <Widget>[
      _filters(data),
      if (_loading)
        const AppSkeletonList(rows: 4)
      else if (data.days.isEmpty)
        const AppEmptyState(
          title: 'Không có dữ liệu trong khoảng đã chọn',
          message: 'Chọn khoảng ngày khác có ngày học.',
        )
      else ...[
        AppStatRow(
          tiles: [
            AppStatTile(
              value: '${data.days.length}',
              label: 'Ngày học',
              tone: AppStatusTone.blue,
            ),
            AppStatTile(
              value: '$presentTotal',
              label: 'Lượt có mặt',
              tone: AppStatusTone.green,
            ),
            AppStatTile(
              value: '$excusedTotal',
              label: 'Vắng có phép',
              tone: AppStatusTone.orange,
            ),
            AppStatTile(
              value: '$unexcusedTotal',
              label: 'Vắng không phép',
              tone: AppStatusTone.red,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Text('Theo ngày', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.space3),
        for (final day in data.days)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
            child: _DayCard(day: day, sessions: data.mealSessions),
          ),
        const SizedBox(height: AppSpacing.space3),
        Text('Theo trẻ', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.space3),
        if (data.children.isEmpty)
          const AppEmptyState(title: 'Lớp chưa có trẻ', message: ' ')
        else
          for (final child in data.children)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
              child: _ChildCard(child: child, sessions: data.mealSessions),
            ),
      ],
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: children,
    );
  }
}

String _mealLine(Map<MealSession, int> counts, List<MealSession> sessions) => [
  for (final session in sessions) '${session.label} ${counts[session] ?? 0}',
].join(' · ');

String _days(double value) => value == value.roundToDouble()
    ? '${value.toInt()}'
    : value.toStringAsFixed(1).replaceAll('.', ',');

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.sessions});

  final AttendanceSummaryDay day;
  final List<MealSession> sessions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateLabels.weekdayDayMonth(day.date),
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'Có mặt ${day.present} · Có phép ${day.excused} · Không phép ${day.unexcused} · Chưa ĐD ${day.missing}',
            style: textTheme.bodyMedium,
          ),
          if (day.morningOff > 0 || day.afternoonOff > 0)
            Text(
              'Nghỉ sáng ${day.morningOff} · Nghỉ chiều ${day.afternoonOff}',
              style: muted,
            ),
          Text(
            'Trẻ có ăn ${day.mealTotal} · ${_mealLine(day.meals, sessions)}',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.sessions});

  final AttendanceSummaryChild child;
  final List<MealSession> sessions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(child.fullName, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'Ngày có mặt ${_days(child.attendedDays)} · Có phép ${child.excused} · Không phép ${child.unexcused}',
            style: textTheme.bodyMedium,
          ),
          if (child.morningOff > 0 || child.afternoonOff > 0)
            Text(
              'Nghỉ sáng ${child.morningOff} · Nghỉ chiều ${child.afternoonOff}',
              style: muted,
            ),
          Text(
            'Ngày có ăn ${child.mealDays} · ${_mealLine(child.mealCounts, sessions)}',
            style: muted,
          ),
        ],
      ),
    );
  }
}
