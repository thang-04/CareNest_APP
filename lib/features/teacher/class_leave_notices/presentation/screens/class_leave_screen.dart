import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_context_chip.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/data/fake_class_leave_source.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/domain/class_leave_notice.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

/// Đơn xin nghỉ của lớp — mockup T03, dạng BE `LeaveRequestResponse`. GV chỉ xem, không duyệt (ATT-05).
/// "Hôm nay & sắp tới" lọc theo ngày nghỉ cuối; "Tất cả" hiện thêm bộ lọc Từ / Đến ngày để xem
/// lại đơn cũ. Mỗi đơn thêm buổi nghỉ, bé có ăn không, báo nghỉ sau giờ chốt.
class ClassLeaveScreen extends StatefulWidget {
  const ClassLeaveScreen({
    super.key,
    this.classId = FakeClassRosterSource.classId,
    this.classes = const [],
    this.source = const FakeClassLeaveSource(),
    this.today,
  });

  final String classId;

  /// Mỗi giáo viên một lớp: không hiện chip lớp (giữ tham số để router không đổi).
  final List<ClassOption> classes;
  final ClassLeaveSource source;

  /// Mốc lọc "Hôm nay & sắp tới" (giờ nhà trường); mặc định ngày máy (bản giả: ngày giả).
  final DateTime? today;

  @override
  State<ClassLeaveScreen> createState() => _ClassLeaveScreenState();
}

class _ClassLeaveScreenState extends State<ClassLeaveScreen> {
  late final DateTime _today = _dayOf(
    widget.today ??
        (widget.source is FakeClassLeaveSource
            ? FakeParentHomeSource.today
            : DateTime.now()),
  );
  late DateTime _from = defaultLeaveRange(_today).$1;
  late DateTime _to = defaultLeaveRange(_today).$2;
  List<ClassLeaveEntry>? _entries;
  Object? _error;
  bool _upcomingOnly = true;
  int _seq = 0;

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _entries = null;
      _error = null;
    });
    try {
      final entries = await widget.source.load(
        widget.classId,
        from: _from,
        to: _to,
      );
      if (mounted && seq == _seq) setState(() => _entries = entries);
    } catch (error) {
      if (mounted && seq == _seq) setState(() => _error = error);
    }
  }

  Future<void> _pickDate({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(_today.year - 2),
      lastDate: DateTime(_today.year + 1, 12, 31),
      helpText: from ? 'Từ ngày' : 'Đến ngày',
    );
    if (picked == null || !mounted) return;
    final day = _dayOf(picked);
    // Khoảng ngày luôn hợp lệ: đầu kia nhích theo để "từ" không sau "đến"
    if (from) {
      _from = day;
      if (_to.isBefore(day)) _to = day;
    } else {
      _to = day;
      if (_from.isAfter(day)) _from = day;
    }
    _load();
  }

  /// Nhãn, tông như Web `LeaveStatusBadge`.
  static (String, AppStatusTone) _badge(LeaveRequestStatus status) =>
      switch (status) {
        LeaveRequestStatus.active => (status.label, AppStatusTone.green),
        LeaveRequestStatus.cancelled => (status.label, AppStatusTone.gray),
      };

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final visible = entries == null
        ? const <ClassLeaveEntry>[]
        : _upcomingOnly
        ? entries.where((entry) => !entry.toDate.isBefore(_today)).toList()
        : entries;
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn xin nghỉ của lớp')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppFilterChip(
                label: 'Hôm nay & sắp tới',
                selected: _upcomingOnly,
                onSelected: () => setState(() => _upcomingOnly = true),
              ),
              AppFilterChip(
                label: 'Tất cả',
                selected: !_upcomingOnly,
                onSelected: () => setState(() => _upcomingOnly = false),
              ),
            ],
          ),
          if (!_upcomingOnly) ...[
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                AppContextChip(
                  label: 'Từ ${DateLabels.date(_from)}',
                  semanticLabel: 'Từ ngày',
                  leading: const Icon(AppIcons.calendar, size: 20),
                  onTap: () => _pickDate(from: true),
                ),
                AppContextChip(
                  label: 'Đến ${DateLabels.date(_to)}',
                  semanticLabel: 'Đến ngày',
                  leading: const Icon(AppIcons.calendar, size: 20),
                  onTap: () => _pickDate(from: false),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          if (_error != null)
            AppErrorState(
              title: 'Chưa tải được đơn xin nghỉ',
              message: loadFailureMessage(_error),
              onRetry: _load,
            )
          else if (entries == null)
            const AppSkeletonList(rows: 4)
          else if (visible.isEmpty)
            const AppEmptyState(
              title: 'Không có đơn xin nghỉ',
              message: 'Đơn phụ huynh gửi sẽ hiện ở đây.',
            )
          else ...[
            for (final entry in visible) ...[
              _EntryCard(entry: entry, badge: _badge(entry.status)),
              const SizedBox(height: AppSpacing.space3),
            ],
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.badge});

  final ClassLeaveEntry entry;
  final (String, AppStatusTone) badge;

  static String _dates(List<DateTime> days) =>
      days.map(DateLabels.dayMonth).join(', ');

  /// Bé có ăn không như Web `eatsLabel`; "—" khi không áp dụng.
  static String _eats(ClassLeaveEntry e) {
    if (e.eats == null || e.part == LeavePart.fullDay) return '—';
    final meals = e.eatsMeals.isEmpty
        ? ''
        : ' (${e.eatsMeals.map(mealSessionLabel).join(', ')})';
    return '${e.eats! ? 'Có ăn' : 'Không ăn'}$meals';
  }

  /// "Buổi chiều · Không ăn (Bữa trưa)"; cả ngày chỉ hiện "Cả ngày".
  static String _partLine(ClassLeaveEntry e) {
    final eats = _eats(e);
    return eats == '—' ? e.part.label : '${e.part.label} · $eats';
  }

  /// Hủy một phần: BE giữ ACTIVE, `effectiveTo` là ngày cuối còn hiệu lực.
  static DateTime? _cancelledFrom(ClassLeaveEntry e) =>
      e.status == LeaveRequestStatus.active &&
          e.effectiveTo != null &&
          e.effectiveTo!.isBefore(e.toDate)
      ? e.effectiveTo!.add(const Duration(days: 1))
      : null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    final cancelled = entry.status == LeaveRequestStatus.cancelled;
    final cancelledFrom = _cancelledFrom(entry);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space1,
            children: [
              Text(entry.childName, style: textTheme.titleSmall),
              AppStatusBadge(label: badge.$1, tone: badge.$2),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            DateLabels.range(entry.fromDate, entry.toDate),
            style: textTheme.bodyMedium?.copyWith(
              decoration: cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(_partLine(entry), style: muted),
          Text(entry.reason, style: muted),
          // Ngày bị bỏ qua vì đã qua giờ khóa (ATT-05b) — BE trả, APP chỉ hiển thị
          if (entry.skippedDates.isNotEmpty)
            Text('Không áp dụng: ${_dates(entry.skippedDates)}', style: muted),
          if (entry.noticeOnly)
            Text(
              'Báo nghỉ chiều sau giờ chốt · không đổi điểm danh/suất ăn',
              style: muted,
            ),
          if (cancelledFrom != null)
            Text(
              'Phụ huynh hủy từ ${DateLabels.date(cancelledFrom)}',
              style: muted,
            ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '${entry.createdByName} · ${DateLabels.time24(entry.createdAt)} ${DateLabels.dayMonth(entry.createdAt)}',
            style: textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
