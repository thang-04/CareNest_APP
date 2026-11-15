import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_month_calendar.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/leave_notice/presentation/leave_notice_status.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';

/// Xin nghỉ cho bé — bố cục D Clay: lịch tháng chọn khoảng ngày, thấy ngày đã báo nghỉ.
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
  late DateTime _month = DateTime(_from.year, _from.month);
  // Đã chạm ngày bắt đầu, chạm tiếp là ngày kết thúc
  bool _pickingEnd = false;

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

  bool _isSelectable(DateTime day) =>
      !day.isBefore(_source.today) && !day.isAfter(_lastDay);

  void _onDayTap(DateTime day) {
    setState(() {
      if (_pickingEnd && !day.isBefore(_from)) {
        _to = day;
        _pickingEnd = false;
      } else {
        _from = day;
        _to = day;
        _pickingEnd = true;
      }
    });
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  String get _rangeLabel => DateUtils.isSameDay(_from, _to)
      ? 'Nghỉ ngày ${DateLabels.date(_from)}'
      : 'Nghỉ từ ${DateLabels.dayMonth(_from)} đến ${DateLabels.date(_to)}';

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
          AppCard(
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Tháng trước',
                      onPressed:
                          _month.isAfter(
                            DateTime(_source.today.year, _source.today.month),
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
                            DateTime(_lastDay.year, _lastDay.month),
                          )
                          ? () => _shiftMonth(1)
                          : null,
                      icon: const Icon(AppIcons.chevronRight),
                    ),
                  ],
                ),
                AppMonthCalendar(
                  month: _month,
                  rangeStart: _from,
                  rangeEnd: _to,
                  isDayEnabled: _isSelectable,
                  markers: {
                    for (final day in _reportedDays)
                      if (day.year == _month.year && day.month == _month.month)
                        day.day: const AppDayMarker(
                          tone: AppStatusTone.approval,
                          label: 'Đã báo nghỉ',
                        ),
                  },
                  onSelected: _submitting ? null : _onDayTap,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(_rangeLabel, style: textTheme.titleSmall),
                Text(
                  _pickingEnd
                      ? 'Chạm ngày kết thúc nếu nghỉ nhiều ngày.'
                      : 'Chạm một ngày để đổi ngày bắt đầu.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                if (_reportedDays.isNotEmpty) ...[
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
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Buổi nghỉ',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
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
