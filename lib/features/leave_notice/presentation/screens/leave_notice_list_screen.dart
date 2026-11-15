import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/leave_notice/presentation/leave_notice_status.dart';

/// Đơn xin nghỉ đã gửi — mockup P04. Không có trạng thái duyệt (ATT-05).
class LeaveNoticeListScreen extends StatefulWidget {
  const LeaveNoticeListScreen({
    super.key,
    required this.childId,
    required this.onCreate,
    this.source,
  });

  final String childId;

  /// Mở form tạo đơn; trả về khi form đóng để tải lại danh sách.
  final Future<void> Function() onCreate;
  final LeaveNoticeSource? source;

  @override
  State<LeaveNoticeListScreen> createState() => _LeaveNoticeListScreenState();
}

class _LeaveNoticeListScreenState extends State<LeaveNoticeListScreen> {
  late final LeaveNoticeSource _source =
      widget.source ?? FakeLeaveNoticeSource.shared;
  List<LeaveNotice>? _notices;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final notices = await _source.loadNotices(widget.childId);
      if (mounted) setState(() => _notices = notices);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _create() async {
    await widget.onCreate();
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final notices = _notices;
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn xin nghỉ')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            if (_error != null)
              AppErrorState(
                title: 'Chưa tải được đơn xin nghỉ',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: _load,
              )
            else if (notices == null)
              const AppSkeletonList(rows: 3)
            else if (notices.isEmpty)
              const AppEmptyState(
                icon: AppIcons.calendarOff,
                title: 'Chưa có đơn xin nghỉ',
                message: 'Khi bé cần nghỉ, tạo đơn để cô giáo biết trước.',
              )
            else ...[
              for (final notice in notices) ...[
                AppCard(
                  dense: true,
                  // Wrap: chữ phóng lớn thì badge xuống dòng thay vì tràn
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 160),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.periodLabel,
                              style: textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              notice.reason,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppStatusBadge(
                        label: notice.statusLabel,
                        tone: notice.statusTone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
              Text(
                'Suất ăn của các ngày nghỉ được huỷ tự động ngay khi gửi đơn.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Tạo đơn xin nghỉ mới',
            expand: true,
            onPressed: _error != null ? null : _create,
          ),
        ],
      ),
    );
  }
}
