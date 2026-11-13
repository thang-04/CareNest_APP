import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/leave_notice/presentation/leave_notice_status.dart';

/// Đơn xin nghỉ đã gửi — mockup P04. Không có trạng thái duyệt hay GV đã xem (ATT-05).
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
  String? _cancellingId;

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

  Future<void> _confirmCancel(LeaveNotice notice) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      title: 'Hủy đơn nghỉ ${notice.periodLabel}?',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bé sẽ được ghi đi học bình thường các ngày này.',
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: 'Hủy đơn',
            variant: AppButtonVariant.danger,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.space2),
          AppButton(
            label: 'Giữ đơn',
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancellingId = notice.id);
    try {
      await _source.cancel(notice.id);
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa hủy được đơn. Kiểm tra mạng rồi thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Wrap: chữ phóng lớn thì badge xuống dòng thay vì tràn
                      Wrap(
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
                      if (notice.canCancel) ...[
                        const SizedBox(height: AppSpacing.space3),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            label: 'Hủy đơn',
                            loadingLabel: 'Đang hủy',
                            variant: AppButtonVariant.secondary,
                            small: true,
                            isLoading: _cancellingId == notice.id,
                            onPressed: _cancellingId == null
                                ? () => _confirmCancel(notice)
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
              Text(
                'Hủy đơn được trước giờ chốt của ngày nghỉ; ngày nghỉ ghi Vắng có phép.',
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
