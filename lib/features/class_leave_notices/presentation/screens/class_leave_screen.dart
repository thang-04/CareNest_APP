import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/class_leave_notices/data/fake_class_leave_source.dart';
import 'package:carenest_app/features/class_leave_notices/domain/class_leave_notice.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';

/// Đơn xin nghỉ của lớp — mockup T03. Chỉ liệt kê đơn nghỉ của phụ huynh, không có trẻ vắng không đơn
/// (như Web). GV chỉ xem: không duyệt, không đánh dấu đã xem (ATT-05).
class ClassLeaveScreen extends StatefulWidget {
  const ClassLeaveScreen({
    super.key,
    this.classId = FakeClassRosterSource.classId,
    this.source = const FakeClassLeaveSource(),
  });

  final String classId;
  final ClassLeaveSource source;

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

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final visible = entries == null
        ? const <ClassLeaveEntry>[]
        : _upcomingOnly
        ? entries.where((entry) => entry.upcoming).toList()
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
              _EntryCard(entry: entry),
              const SizedBox(height: AppSpacing.space3),
            ],
            const AppBanner(
              message:
                  'Ngày có đơn tự ghi Vắng có phép, không có suất. GV chỉ xem đơn.',
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final ClassLeaveEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.85)),
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
              const AppStatusBadge(
                label: 'Vắng có phép',
                tone: AppStatusTone.blue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(entry.period, style: textTheme.bodyMedium),
          Text('Lý do: ${entry.reason}', style: muted),
          const SizedBox(height: AppSpacing.space1),
          Text(
            entry.meta,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
