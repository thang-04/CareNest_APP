import 'package:flutter/material.dart';

import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/features/parent/school_year/presentation/parent_selected_year.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/leave_notice_status.dart';

/// Đơn xin nghỉ đã gửi — mockup P04. Không có trạng thái duyệt (ATT-05).
class LeaveNoticeListScreen extends StatefulWidget {
  const LeaveNoticeListScreen({
    super.key,
    required this.childId,
    required this.onCreate,
    this.source,
    this.year,
  });

  final String childId;

  /// Mở form tạo đơn; trả về khi form đóng để tải lại danh sách.
  final Future<void> Function() onCreate;
  final LeaveNoticeSource? source;

  /// Năm học đang chọn: chỉ đơn có ngày trong năm; năm không đang chạy chỉ xem (AUTH-03). Null ⇒ mọi đơn.
  final ChildSchoolYear? year;

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
      final year = widget.year;
      final notices = [
        for (final notice in await _source.loadNotices(widget.childId))
          if (year == null ||
              (!notice.to.isBefore(year.startDate) &&
                  !notice.from.isAfter(year.endDate)))
            notice,
      ];
      if (mounted) setState(() => _notices = notices);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _create() async {
    await widget.onCreate();
    if (mounted) _load();
  }

  /// Đơn đang huỷ (khoá nút) và lỗi huỷ theo đơn (câu BE).
  final Set<String> _cancelling = {};
  final Map<String, String> _cancelErrors = {};

  /// Đơn chưa huỷ còn ngày chưa qua; năm học đã đóng chỉ xem. BE quyết định phần nào huỷ được
  /// (giờ chốt do HT cấu hình — ATT-06).
  bool _cancellable(LeaveNotice notice) =>
      notice.status == LeaveNoticeStatus.submitted &&
      !notice.to.isBefore(_source.today) &&
      !(widget.year?.readOnly ?? false);

  Future<void> _cancel(LeaveNotice notice) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      title: 'Huỷ đơn xin nghỉ?',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Các ngày chưa qua giờ chốt sẽ được huỷ và bé được tính đi học lại; ngày đã qua giờ chốt vẫn là vắng có phép.',
            style: Theme.of(
              sheetContext,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: 'Huỷ đơn nghỉ',
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.space2),
          AppButton(
            label: 'Giữ đơn',
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _cancelling.add(notice.id);
      _cancelErrors.remove(notice.id);
    });
    try {
      await _source.cancel(notice.id);
      if (!mounted) return;
      setState(() => _cancelling.remove(notice.id));
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cancelling.remove(notice.id);
        _cancelErrors[notice.id] = loadFailureMessage(error);
      });
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
            const ParentYearChip(),
            const SizedBox(height: AppSpacing.space3),
            if (_error != null)
              AppErrorState(
                title: 'Chưa tải được đơn xin nghỉ',
                message: loadFailureMessage(_error),
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
                            if (notice.mealLabel case final meal?) ...[
                              const SizedBox(height: AppSpacing.space1),
                              Text(meal, style: textTheme.bodyMedium),
                            ],
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
                if (_cancelErrors[notice.id] case final error?) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    error,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.dangerText,
                    ),
                  ),
                ],
                if (_cancellable(notice)) ...[
                  const SizedBox(height: AppSpacing.space2),
                  AppButton(
                    label: 'Huỷ đơn',
                    variant: AppButtonVariant.secondary,
                    small: true,
                    isLoading: _cancelling.contains(notice.id),
                    loadingLabel: 'Đang huỷ…',
                    onPressed: () => _cancel(notice),
                  ),
                ],
                const SizedBox(height: AppSpacing.space3),
              ],
              Text(
                'Suất ăn của buổi nghỉ được huỷ tự động ngay khi gửi đơn; '
                'nghỉ nửa buổi thì bữa của buổi còn học theo lựa chọn trong đơn.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: widget.year?.readOnly ?? false
          ? null
          : AppBottomDock(
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
