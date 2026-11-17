import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_month_calendar.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/parent/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/leave_notice_status.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

/// Xin nghỉ cho bé — bố cục Figma PH03 (chốt 17/11), style Clay của DESIGN.md:
/// ô Từ ngày / Đến ngày mở lịch tháng trong sheet, lịch có dấu ngày đã báo nghỉ.
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
  LeaveSession _session = LeaveSession.fullDay;
  final _reason = TextEditingController();
  String? _reasonError;
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
          !day.isAfter(notice.to);
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

  Future<void> _pickFrom() async {
    final day = await _pickDay(
      title: 'Chọn ngày bắt đầu nghỉ',
      initial: _from,
      firstDay: _source.today,
    );
    if (day == null || !mounted) return;
    setState(() {
      _from = day;
      // Đến ngày không được trước Từ ngày
      if (_to.isBefore(day)) _to = day;
    });
  }

  Future<void> _pickTo() async {
    final day = await _pickDay(
      title: 'Chọn ngày kết thúc nghỉ',
      initial: _to,
      firstDay: _from,
    );
    if (day == null || !mounted) return;
    setState(() => _to = day);
  }

  Future<DateTime?> _pickDay({
    required String title,
    required DateTime initial,
    required DateTime firstDay,
  }) {
    return showAppBottomSheet<DateTime>(
      context: context,
      title: title,
      builder: (sheetContext) => _LeaveDayPicker(
        initial: initial,
        firstDay: firstDay,
        lastDay: _lastDay,
        reportedDays: _reportedDays,
        onPicked: (day) => Navigator.of(sheetContext).pop(day),
      ),
    );
  }

  Widget _dateFields(BuildContext context) {
    final from = AppDateField(
      label: 'Từ ngày',
      labelSuffix: '*',
      value: DateLabels.date(_from),
      onTap: _submitting ? null : _pickFrom,
    );
    final to = AppDateField(
      label: 'Đến ngày',
      labelSuffix: '*',
      value: DateLabels.date(_to),
      onTap: _submitting ? null : _pickTo,
    );
    // Chữ hệ thống lớn: hai ô cạnh nhau phải ngắt ngày giữa chừng ⇒ xếp dọc
    if (MediaQuery.textScalerOf(context).scale(1) > 1.2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          from,
          const SizedBox(height: AppSpacing.space4),
          to,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: from),
        const SizedBox(width: AppSpacing.space3),
        Expanded(child: to),
      ],
    );
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    setState(() {
      _reasonError = reason.isEmpty ? 'Nhập lý do nghỉ.' : null;
      _submitError = null;
    });
    if (_reasonError != null) return;
    setState(() => _submitting = true);
    try {
      await _source.submit(
        LeaveNoticeDraft(
          childId: widget.child.id,
          from: _from,
          to: _to,
          session: _session,
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

  String get _noticeMessage {
    final teacher =
        '${widget.child.homeroomTeacher} (GV lớp ${widget.child.className}) sẽ nhận được thông báo về đơn này.';
    if (_session != LeaveSession.fullDay) return teacher;
    // ATT-04 CONFIRMED: nghỉ cả ngày ⇒ huỷ suất các ngày đó
    final days = DateLabels.dayMonth(_from) == DateLabels.dayMonth(_to)
        ? 'ngày ${DateLabels.dayMonth(_from)}'
        : 'từ ${DateLabels.dayMonth(_from)} đến ${DateLabels.dayMonth(_to)}';
    return 'Suất ăn $days sẽ được huỷ tự động. $teacher';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                AppAvatar(name: widget.child.fullName),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    '${widget.child.shortName} · ${widget.child.className}',
                    style: textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _dateFields(context),
          const SizedBox(height: AppSpacing.space4),
          Text('Buổi nghỉ', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.space2),
          AppSegmented<LeaveSession>(
            segments: [
              for (final session in LeaveSession.values)
                (session, session.label),
            ],
            selected: _session,
            onChanged: (value) => setState(() => _session = value),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Lý do',
            labelSuffix: '*',
            hint: 'Ví dụ: gia đình đưa bé đi khám răng',
            controller: _reason,
            multiline: true,
            enabled: !_submitting,
            errorText: _reasonError,
            helperText:
                '${_reason.text.length}/${LeaveNoticeFormScreen.reasonMaxLength} ký tự',
            maxLength: LeaveNoticeFormScreen.reasonMaxLength,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppBanner(kind: AppBannerKind.warning, message: _noticeMessage),
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

/// Lịch tháng trong sheet của ô Từ ngày / Đến ngày: chạm một ngày là chọn và đóng sheet.
/// Ngày ngoài `firstDay`…`lastDay` không chọn được; ngày đã báo nghỉ có chấm và chữ.
class _LeaveDayPicker extends StatefulWidget {
  const _LeaveDayPicker({
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
  State<_LeaveDayPicker> createState() => _LeaveDayPickerState();
}

class _LeaveDayPickerState extends State<_LeaveDayPicker> {
  late DateTime _month = DateTime(widget.initial.year, widget.initial.month);

  bool _isSelectable(DateTime day) =>
      !day.isBefore(widget.firstDay) && !day.isAfter(widget.lastDay);

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Tháng trước',
              onPressed:
                  _month.isAfter(
                    DateTime(widget.firstDay.year, widget.firstDay.month),
                  )
                  ? () => _shiftMonth(-1)
                  : null,
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
              onPressed:
                  _month.isBefore(
                    DateTime(widget.lastDay.year, widget.lastDay.month),
                  )
                  ? () => _shiftMonth(1)
                  : null,
              icon: const Icon(AppIcons.chevronRight),
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
        if (widget.reportedDays.isNotEmpty) ...[
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
