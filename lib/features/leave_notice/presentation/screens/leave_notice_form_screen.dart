import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_month_calendar.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';

/// Xin nghỉ cho bé (Figma PH03 bản sửa): Từ ngày / Đến ngày mở lịch tháng có dấu ngày đã báo nghỉ.
/// Ngày qua cut-off hay đã chốt suất do BE từ chối (ATT-05b); form chỉ hỗ trợ nhập.
class LeaveNoticeFormScreen extends StatefulWidget {
  const LeaveNoticeFormScreen({
    super.key,
    required this.child,
    required this.onOpenSent,
    required this.onSubmitted,
    this.source,
  });

  final ChildSummary child;
  final VoidCallback onOpenSent;
  final VoidCallback onSubmitted;
  final LeaveNoticeSource? source;

  static const reasonMaxLength = 500;

  @override
  State<LeaveNoticeFormScreen> createState() => _LeaveNoticeFormScreenState();
}

class _LeaveNoticeFormScreenState extends State<LeaveNoticeFormScreen> {
  late final LeaveNoticeSource _source =
      widget.source ?? FakeLeaveNoticeSource.shared;
  late DateTime _from = _source.today.add(const Duration(days: 1));
  late DateTime _to = _from;

  /// Ngày đã có đơn nghỉ (để không báo trùng); tải lỗi ⇒ để trống, không chặn form.
  Set<DateTime> _reportedDays = const {};
  final _reason = TextEditingController();
  String? _reasonError;
  String? _rangeError;
  String? _submitError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadReported();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadReported() async {
    try {
      final notices = await _source.loadNotices(widget.child.id);
      final days = <DateTime>{};
      for (final notice in notices) {
        if (notice.status == LeaveNoticeStatus.cancelled) continue;
        for (
          var day = notice.from;
          !day.isAfter(notice.effectiveTo);
          day = day.add(const Duration(days: 1))
        ) {
          days.add(DateTime(day.year, day.month, day.day));
        }
      }
      if (mounted) setState(() => _reportedDays = days);
    } catch (_) {
      // Thiếu dấu ngày đã báo vẫn gửi được đơn; BE kiểm tra trùng
    }
  }

  DateTime get _lastDay => _source.today.add(const Duration(days: 180));

  int get _dayCount => _to.difference(_from).inDays + 1;

  Future<void> _pickFrom() async {
    final day = await _pickDay(
      title: 'Chọn ngày bắt đầu nghỉ',
      initial: _from,
      firstDay: _source.today,
    );
    if (day == null || !mounted) return;
    setState(() {
      _rangeError = null;
      _from = day;
      if (_to.isBefore(day)) _to = day;
    });
  }

  Future<void> _pickTo() async {
    final day = await _pickDay(
      title: 'Chọn ngày cuối nghỉ',
      initial: _to,
      firstDay: _from,
    );
    if (day == null || !mounted) return;
    setState(() {
      _rangeError = null;
      _to = day;
    });
  }

  Future<DateTime?> _pickDay({
    required String title,
    required DateTime initial,
    required DateTime firstDay,
  }) {
    return showAppBottomSheet<DateTime>(
      context: context,
      title: title,
      builder: (sheetContext) => _DayPicker(
        initial: initial,
        firstDay: firstDay,
        lastDay: _lastDay,
        reportedDays: _reportedDays,
        onPicked: (day) => Navigator.of(sheetContext).pop(day),
      ),
    );
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    setState(() {
      _reasonError = reason.isEmpty ? 'Nhập lý do nghỉ.' : null;
      _rangeError = _dayCount > LeaveNoticeDraft.maxDays
          ? 'Mỗi đơn tối đa ${LeaveNoticeDraft.maxDays} ngày. Chọn lại ngày kết thúc.'
          : null;
      _submitError = null;
    });
    if (_reasonError != null || _rangeError != null) return;
    setState(() => _submitting = true);
    try {
      await _source.submit(
        LeaveNoticeDraft(
          childId: widget.child.id,
          from: _from,
          to: _to,
          reason: reason,
        ),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      widget.onSubmitted();
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = 'Chưa gửi được đơn. Kiểm tra mạng rồi gửi lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final child = widget.child;
    final fromField = AppDateField(
      label: 'Từ ngày *',
      value: DateLabels.date(_from),
      onTap: _submitting ? null : _pickFrom,
    );
    final toField = AppDateField(
      label: 'Đến ngày *',
      value: DateLabels.date(_to),
      onTap: _submitting ? null : _pickTo,
    );
    // Chữ lớn ⇒ hai ô ngày xếp dọc để ngày không bị cắt
    final stackDates = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xin nghỉ cho bé'),
        actions: [
          AppLinkButton(label: 'Đơn đã gửi', onPressed: widget.onOpenSent),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppCard(
            dense: true,
            child: Row(
              children: [
                const AppIconTile(icon: AppIcons.childFace),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bé ${child.fullName}', style: textTheme.titleSmall),
                      Text(
                        'Lớp ${child.className}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          if (stackDates) ...[
            fromField,
            const SizedBox(height: AppSpacing.space4),
            toField,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fromField),
                const SizedBox(width: AppSpacing.space3),
                Expanded(child: toField),
              ],
            ),
          if (_rangeError != null) ...[
            const SizedBox(height: AppSpacing.space1 + 2),
            Text(
              _rangeError!,
              style: textTheme.bodyMedium?.copyWith(
                color: status.feedbackOf(AppFeedback.danger).foreground,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Lý do',
            labelSuffix: '*',
            hint: 'Ví dụ: gia đình đưa bé đi khám răng',
            controller: _reason,
            multiline: true,
            enabled: !_submitting,
            errorText: _reasonError,
            maxLength: LeaveNoticeFormScreen.reasonMaxLength,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.space1 + 2),
          Text(
            '${_reason.text.length}/${LeaveNoticeFormScreen.reasonMaxLength} ký tự',
            textAlign: TextAlign.right,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          // ATT-04: ngày có đơn ghi Vắng có phép; ATT-05: tối đa 30 ngày mỗi đơn
          AppBanner(
            kind: AppBannerKind.warning,
            icon: AppIcons.info,
            title:
                'Ngày nghỉ ghi Vắng có phép. Tối đa ${LeaveNoticeDraft.maxDays} ngày mỗi đơn.',
            message:
                '${child.homeroomTeacher} (GV lớp ${child.className}) sẽ nhận được thông báo về đơn này.',
          ),
          if (_submitError != null) ...[
            const SizedBox(height: AppSpacing.space3),
            AppBanner(kind: AppBannerKind.danger, message: _submitError!),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Gửi đơn xin nghỉ',
            loadingLabel: 'Đang gửi',
            isLoading: _submitting,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Lịch tháng trong sheet chọn ngày: ngày ngoài [firstDay]–[lastDay] mờ, ngày đã báo nghỉ có dấu kèm chữ.
class _DayPicker extends StatefulWidget {
  const _DayPicker({
    required this.initial,
    required this.firstDay,
    required this.lastDay,
    required this.reportedDays,
    required this.onPicked,
  });

  final DateTime initial;
  final DateTime firstDay;
  final DateTime lastDay;
  final Set<DateTime> reportedDays;
  final ValueChanged<DateTime> onPicked;

  @override
  State<_DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<_DayPicker> {
  late DateTime _month = DateTime(widget.initial.year, widget.initial.month);

  bool _isSelectable(DateTime day) =>
      !day.isBefore(widget.firstDay) && !day.isAfter(widget.lastDay);

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = DateTime(widget.firstDay.year, widget.firstDay.month);
    final last = DateTime(widget.lastDay.year, widget.lastDay.month);
    final hasReported = widget.reportedDays.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Tháng trước',
              onPressed: _month.isAfter(first) ? () => _shiftMonth(-1) : null,
              icon: const Icon(AppIcons.back),
            ),
            Expanded(
              child: Text(
                'Tháng ${_month.month}, ${_month.year}',
                textAlign: TextAlign.center,
                style: textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Tháng sau',
              onPressed: _month.isBefore(last) ? () => _shiftMonth(1) : null,
              icon: const Icon(AppIcons.arrowRight),
            ),
          ],
        ),
        AppMonthCalendar(
          month: _month,
          selected: widget.initial,
          isDayEnabled: _isSelectable,
          markers: {
            for (final day in widget.reportedDays)
              if (day.year == _month.year && day.month == _month.month)
                day.day: const AppDayMarker(
                  tone: AppStatusTone.approval,
                  label: 'Đã báo nghỉ',
                ),
          },
          onSelected: widget.onPicked,
        ),
        if (hasReported) ...[
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppStatusColors.of(
                    context,
                  ).tone(AppStatusTone.approval).main,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  'Ngày đã báo nghỉ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
