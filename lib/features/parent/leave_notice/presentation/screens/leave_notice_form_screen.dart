import 'package:flutter/material.dart';

import 'package:carenest_app/core/utils/class_labels.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
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

  /// Bữa của ngày nghỉ nửa buổi do BE chia (ATT-12); null khi cả ngày, đang tải hoặc lỗi.
  LeaveMealPlan? _mealPlan;
  bool _mealPlanFailed = false;
  int _mealPlanRequest = 0;

  /// Buổi khoá khi chọn hôm nay (ATT-05b), suy từ BE preview: Cả ngày 4021 ⇒ qua giờ chốt; chiều
  /// cũng 4021 (không học) hoặc 4032 (đã tới giờ chiều) ⇒ khoá cả 3. Lỗi mạng ⇒ không khoá.
  Set<LeaveSession> _locked = const {};
  String? _lockNote;
  int _todayRequest = 0;

  /// Công tắc "Bé tham gia ăn" cho bữa của buổi còn học; BE mặc định có ăn.
  bool _eats = true;
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

  bool get _isHalfDay => _session != LeaveSession.fullDay;

  Future<void> _loadMealPlan() async {
    final request = ++_mealPlanRequest;
    setState(() {
      _mealPlan = null;
      _mealPlanFailed = false;
    });
    if (!_isHalfDay) return;
    try {
      final plan = await _source.loadMealPlan(widget.child.id, _from, _session);
      // Bỏ kết quả của lần chọn buổi/ngày cũ
      if (mounted && request == _mealPlanRequest) {
        setState(() => _mealPlan = plan);
      }
    } catch (_) {
      if (mounted && request == _mealPlanRequest) {
        setState(() => _mealPlanFailed = true);
      }
    }
  }

  bool get _allLocked => _locked.length == LeaveSession.values.length;

  Future<void> _checkToday() async {
    final request = ++_todayRequest;
    setState(() {
      _locked = const {};
      _lockNote = null;
    });
    if (_from != _source.today) return;
    bool current() => mounted && request == _todayRequest;
    try {
      await _source.loadMealPlan(widget.child.id, _from, LeaveSession.fullDay);
      return;
    } on ApiFailure catch (error) {
      if (error.errorCode != _noSchoolDay) return;
    } catch (_) {
      return;
    }
    LeaveMealPlan? afternoon;
    try {
      afternoon = await _source.loadMealPlan(
        widget.child.id,
        _from,
        LeaveSession.afternoon,
      );
    } on ApiFailure catch (error) {
      // Không học hôm nay, hoặc đã tới giờ chiều (BE 4032) ⇒ không còn buổi nào báo được
      final note = switch (error.errorCode) {
        _noSchoolDay => 'Hôm nay không có buổi học',
        _afternoonStarted => error.message,
        _ => null,
      };
      if (note != null) {
        if (!current()) return;
        setState(() {
          _locked = LeaveSession.values.toSet();
          _lockNote = note;
        });
        return;
      }
      // Lỗi khác (vd. bé đã vắng hôm nay): vẫn khoá Cả ngày, Buổi sáng; BE báo lý do khi gửi
    } catch (_) {
      return;
    }
    if (!current()) return;
    setState(() {
      _locked = const {LeaveSession.fullDay, LeaveSession.morning};
      _lockNote =
          'Đã qua giờ chốt hôm nay: chỉ báo nghỉ được buổi chiều, '
          'đơn chỉ báo cô giáo.';
      _session = LeaveSession.afternoon;
      _to = _from;
      _eats = true;
    });
    if (afternoon == null) {
      _loadMealPlan();
    } else {
      // Bỏ kết quả preview cũ đang chờ, dùng luôn bản buổi chiều vừa tải
      _mealPlanRequest++;
      setState(() {
        _mealPlan = afternoon;
        _mealPlanFailed = false;
      });
    }
  }

  /// BE `LEAVE_NO_SCHOOL_DAY`: khoảng chọn không còn ngày học (gồm hôm nay đã qua giờ chốt).
  static const _noSchoolDay = 4021;

  /// BE: đã tới giờ bắt đầu buổi chiều, không gửi hoặc hủy báo nghỉ chiều hôm nay.
  static const _afternoonStarted = 4032;

  void _selectSession(LeaveSession session) {
    setState(() {
      _session = session;
      _eats = true;
      // ATT-12: nghỉ nửa buổi chỉ cho đơn 1 ngày (BE 4031)
      if (_isHalfDay) _to = _from;
    });
    _loadMealPlan();
  }

  Future<void> _pickFrom() async {
    final day = await _pickDay(
      title: 'Chọn ngày bắt đầu nghỉ',
      initial: _from,
      firstDay: _source.today,
    );
    if (day == null || !mounted) return;
    setState(() {
      _from = day;
      // Đến ngày không được trước Từ ngày; nửa buổi luôn 1 ngày
      if (_to.isBefore(day) || _isHalfDay) _to = day;
    });
    if (_isHalfDay) _loadMealPlan();
    _checkToday();
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
      onTap: _submitting || _isHalfDay ? null : _pickTo,
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
          eats: _sentEats,
        ),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      widget.onSubmitted();
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          // BE từ chối (trùng ngày, qua giờ chốt, quá dài…) ⇒ câu BE; còn lại coi như lỗi mạng
          _submitError = error is ApiFailure && error.status < 500
              ? error.message
              : 'Chưa gửi được đơn. Kiểm tra mạng rồi gửi lại.';
        });
      }
    }
  }

  String get _teacherNotice => widget.child.homeroomTeacher == null
      ? 'Giáo viên ${classLabel(widget.child.className, lower: true)} sẽ nhận được thông báo về đơn này.'
      : '${widget.child.homeroomTeacher} (GV ${classLabel(widget.child.className, lower: true)}) sẽ nhận được thông báo về đơn này.';

  /// `eats` gửi BE: chỉ đơn nửa buổi; buổi còn học không có bữa ⇒ null (BE bỏ qua).
  bool? get _sentEats {
    if (!_isHalfDay) return null;
    final plan = _mealPlan;
    // ATT-05b: đơn chỉ báo cô giáo không đổi suất ⇒ không gửi lựa chọn ăn
    if (plan != null && plan.noticeOnly) return null;
    return plan == null || plan.keptMeals.isNotEmpty ? _eats : null;
  }

  /// Dòng đậm đầu hộp (Figma PH03): bữa nào huỷ theo đơn, lấy từ cách chia bữa BE trả.
  String? get _mealNotice {
    final day = 'ngày ${DateLabels.dayMonth(_from)}';
    if (_allLocked) return null;
    if (!_isHalfDay) {
      // ATT-04 CONFIRMED: nghỉ cả ngày ⇒ huỷ suất các ngày đó
      final days = DateLabels.dayMonth(_from) == DateLabels.dayMonth(_to)
          ? day
          : 'từ ${DateLabels.dayMonth(_from)} đến ${DateLabels.dayMonth(_to)}';
      return 'Suất ăn $days sẽ được huỷ tự động.';
    }
    final plan = _mealPlan;
    if (plan == null) return null;
    if (plan.noticeOnly) {
      return 'Đã qua giờ chốt: đơn chỉ báo cô giáo, '
          'không đổi điểm danh và suất ăn $day.';
    }
    final cancelled = [...plan.offMeals, if (!_eats) ...plan.keptMeals];
    if (cancelled.isEmpty) return 'Suất ăn $day không đổi.';
    final kept = _eats && plan.keptMeals.isNotEmpty
        ? ', bé vẫn ăn bữa ${plan.keptMeals.labels} ở trường'
        : '';
    return 'Suất ${cancelled.labels} $day sẽ được huỷ tự động$kept.';
  }

  /// Lựa chọn ăn của đơn nửa buổi (ATT-12): một công tắc cho các bữa của buổi còn học.
  List<Widget> _mealChoice(TextTheme textTheme) {
    if (!_isHalfDay) return const [];
    final plan = _mealPlan;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    if (_mealPlanFailed) {
      return [
        const SizedBox(height: AppSpacing.space4),
        const AppBanner(
          kind: AppBannerKind.danger,
          message: 'Chưa tải được bữa ăn của buổi còn học.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: AppLinkButton(label: 'Thử lại', onPressed: _loadMealPlan),
        ),
      ];
    }
    if (plan == null || plan.noticeOnly) return const [];
    if (plan.keptMeals.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.space4),
        Text('Buổi còn học không có bữa ăn của nhóm tuổi bé.', style: muted),
      ];
    }
    return [
      const SizedBox(height: AppSpacing.space4),
      Text(
        'Bé có ăn bữa ${plan.keptMeals.labels} ở trường không?',
        style: textTheme.labelLarge,
      ),
      const SizedBox(height: AppSpacing.space2),
      AppSegmented<bool>(
        segments: const [(true, 'Có ăn'), (false, 'Không ăn')],
        selected: _eats,
        onChanged: (value) => setState(() => _eats = value),
      ),
    ];
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bé ${widget.child.fullName}',
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        classLabel(widget.child.className),
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
            disabled: _locked,
            onChanged: _submitting ? (_) {} : _selectSession,
          ),
          if (_lockNote != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              _lockNote!,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          ..._mealChoice(textTheme),
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
          AppBanner(
            kind: AppBannerKind.warning,
            title: _mealNotice,
            message: _teacherNotice,
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
            onPressed: _allLocked ? null : _submit,
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
