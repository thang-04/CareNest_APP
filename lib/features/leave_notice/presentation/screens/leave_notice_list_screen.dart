import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/leave_notice/presentation/leave_notice_status.dart';

/// Đơn xin nghỉ đã gửi (Figma PH04 bản sửa). Không có trạng thái duyệt hay GV đã xem (ATT-05). Hủy đơn nhiều ngày
/// hủy phần còn lại: ngày đã qua giờ chốt vẫn Vắng có phép (ATT-04, BE quyết định ngày nào hủy được).
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
            'Đơn được hủy từ ngày đầu tiên chưa qua giờ chốt. Ngày đã qua giờ chốt vẫn ghi Vắng có phép.',
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
    } on LeaveCannotCancelException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Các ngày của đơn đã qua giờ chốt, không hủy được.'),
          ),
        );
        await _load();
      }
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
                _NoticeCard(
                  notice: notice,
                  cancelling: _cancellingId == notice.id,
                  onCancel: _cancellingId == null
                      ? () => _confirmCancel(notice)
                      : null,
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
              Text(
                'Hủy đơn được cho các ngày chưa qua giờ chốt; ngày đã qua giờ chốt vẫn ghi Vắng có phép.',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
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

/// Một đơn: ngày nghỉ + trạng thái, lý do; "Hủy đơn" bên phải khi đơn còn ngày hủy được (Figma PH04 bản sửa).
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.cancelling,
    required this.onCancel,
  });

  final LeaveNotice notice;
  final bool cancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(notice.periodLabel, style: textTheme.titleSmall),
            AppStatusBadge(label: notice.statusLabel, tone: notice.statusTone),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          notice.reason,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        if (notice.remainingLabel case final remain?) ...[
          const SizedBox(height: 2),
          Text(remain, style: textTheme.bodyMedium),
        ],
      ],
    );
    if (!notice.canCancel) return AppCard(dense: true, child: details);
    final cancel = _CancelButton(cancelling: cancelling, onPressed: onCancel);
    // Chữ lớn ⇒ nút xuống dưới để ngày và lý do không bị ép hẹp
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return AppCard(
      dense: true,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: AppSpacing.space2),
                cancel,
              ],
            )
          : Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: AppSpacing.space3),
                cancel,
              ],
            ),
    );
  }
}

/// Nút hủy gọn nền cảnh báo nhạt; vùng chạm vẫn ≥48.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.cancelling, required this.onPressed});

  final bool cancelling;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final warning = AppStatusColors.of(context).feedbackOf(AppFeedback.warning);
    return OutlinedButton(
      onPressed: cancelling ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: warning.foreground,
        backgroundColor: warning.background,
        side: BorderSide(color: warning.border),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3 + 2),
        tapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.compact,
        textStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(cancelling ? 'Đang hủy' : 'Hủy đơn'),
    );
  }
}
