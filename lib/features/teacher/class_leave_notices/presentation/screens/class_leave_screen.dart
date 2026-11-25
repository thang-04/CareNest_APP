import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/data/fake_class_leave_source.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/domain/class_leave_notice.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';

/// Đơn xin nghỉ của lớp — mockup T03, dạng BE `LeaveRequestResponse`. GV chỉ xem, không duyệt (ATT-05).
class ClassLeaveScreen extends StatefulWidget {
  const ClassLeaveScreen({
    super.key,
    this.classId = FakeClassRosterSource.classId,
    this.source = const FakeClassLeaveSource(),
    this.today,
  });

  final String classId;
  final ClassLeaveSource source;

  /// Mốc lọc "Hôm nay & sắp tới"; mặc định ngày giả của bản debug.
  final DateTime? today;

  @override
  State<ClassLeaveScreen> createState() => _ClassLeaveScreenState();
}

class _ClassLeaveScreenState extends State<ClassLeaveScreen> {
  List<ClassLeaveEntry>? _entries;
  Object? _error;
  bool _upcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final entries = await widget.source.load(widget.classId);
      if (mounted) setState(() => _entries = entries);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
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
        ? entries
              .where(
                (entry) => !entry.toDate.isBefore(
                  widget.today ?? FakeParentHomeSource.today,
                ),
              )
              .toList()
        : entries;
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn xin nghỉ của lớp')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
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
          const SizedBox(height: AppSpacing.space4),
          if (_error != null)
            AppErrorState(
              title: 'Chưa tải được đơn xin nghỉ',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    final cancelled = entry.status == LeaveRequestStatus.cancelled;
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
          Text(entry.reason, style: muted),
          // Ngày bị bỏ qua vì đã qua giờ khóa (ATT-05b) — BE trả, APP chỉ hiển thị
          if (entry.skippedDates.isNotEmpty)
            Text('Không áp dụng: ${_dates(entry.skippedDates)}', style: muted),
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
