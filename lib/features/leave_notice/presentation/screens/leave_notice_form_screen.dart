import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/leave_notice/presentation/leave_notice_status.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';

/// Xin nghỉ cho bé — mockup P03. Ngày qua cut-off hay đã chốt suất do BE từ chối (ATT-05b);
/// form chỉ hỗ trợ nhập.
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
  LeaveSession _session = LeaveSession.fullDay;
  final _reason = TextEditingController();
  String? _reasonError;
  String? _submitError;
  bool _submitting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final today = _source.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: isFrom ? today : _from,
      lastDate: today.add(const Duration(days: 180)),
      helpText: isFrom ? 'Nghỉ từ ngày' : 'Nghỉ đến ngày',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
      }
    });
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
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final fromField = AppDateField(
      label: 'Từ ngày *',
      value: DateLabels.date(_from),
      onTap: _submitting ? null : () => _pickDate(isFrom: true),
    );
    final toField = AppDateField(
      label: 'Đến ngày *',
      value: DateLabels.date(_to),
      onTap: _submitting ? null : () => _pickDate(isFrom: false),
    );
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
                      Text(
                        'Bé ${widget.child.fullName}',
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        'Lớp ${widget.child.className}',
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
          if (stacked) ...[
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
