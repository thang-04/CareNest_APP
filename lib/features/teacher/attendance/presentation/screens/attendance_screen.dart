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
import 'package:carenest_app/core/widgets/app_context_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/meal_participation_screen.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/widgets/attendance_kid_row.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

enum _SaveState { idle, saving, saved, failed }

/// Điểm danh cả lớp — màn chính giữ Có mặt / Vắng như Web; "Tham gia ăn" mở màn phụ chọn lại trẻ có ăn.
/// Lưu xong sang Sức khỏe đầu ngày. Chỉ nhập khi là lớp được dạy, đúng hôm nay và BE chưa khóa; còn lại chỉ xem.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.classId,
    this.classes = const [],
    this.today,
    this.source,
    this.onSaved,
    this.onOpenHealth,
    this.onOpenSummary,
  });

  final String classId;

  /// Lớp của giáo viên (để biết lớp chỉ xem); rỗng ⇒ chỉ lớp [classId].
  final List<ClassOption> classes;

  /// Hôm nay theo giờ trường (mặc định ngày máy).
  final DateTime? today;
  final AttendanceSource? source;

  /// Gọi sau khi lưu thành công.
  final VoidCallback? onSaved;

  /// Mở Sức khỏe đầu ngày cùng lớp, ngày đang xem: sau khi lưu, hoặc từ nút ở chế độ chỉ xem.
  final void Function(String classId, DateTime date)? onOpenHealth;

  /// Mở Tổng hợp điểm danh của lớp.
  final ValueChanged<String>? onOpenSummary;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceSource _source = widget.source ?? FakeAttendanceSource();
  late final DateTime _today = _dateOnly(widget.today ?? DateTime.now());
  late DateTime _date = _today;
  AttendanceSheet? _sheet;
  List<KidAttendance> _kids = const [];
  Map<String, KidAttendance> _saved = const {};
  bool _loading = true;
  Object? _loadError;
  _SaveState _saveState = _SaveState.idle;
  int _loadSeq = 0;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isToday => _date == _today;

  bool get _classReadOnly =>
      widget.classes
          .where((item) => item.id == widget.classId)
          .firstOrNull
          ?.readOnly ??
      false;

  bool get _editable =>
      (_sheet?.editable ?? false) && !_classReadOnly && _isToday;

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _loadError = null;
      _saveState = _SaveState.idle;
    });
    try {
      final sheet = await _source.loadSheet(
        widget.classId,
        date: _isToday ? null : _date,
      );
      // Bỏ phản hồi muộn của ngày đã đổi
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _sheet = sheet;
        _kids = sheet.kids;
        _saved = {for (final kid in sheet.kids) kid.childId: kid};
        _loading = false;
      });
    } catch (error) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    if (_saveState == _SaveState.saving) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_today.year - 2),
      lastDate: _today,
      helpText: 'Chọn ngày',
    );
    if (picked == null || !mounted) return;
    setState(() => _date = _dateOnly(picked));
    _load();
  }

  List<MealSession> _sessionsFor(KidAttendance kid) {
    final sessions = _sheet?.mealSessions ?? MealSession.values;
    final leave = kid.leave;
    // Nghỉ một buổi: bữa của buổi còn học do BE trả (`eatsMeals`)
    if (leave != null && leave.isHalfDay && leave.eatsMeals.isNotEmpty) {
      return leave.eatsMeals;
    }
    return sessions;
  }

  Map<MealSession, bool> _presentMeals(KidAttendance kid) => kid.mealRegistered
      ? {for (final session in _sessionsFor(kid)) session: true}
      : const {};

  /// Đơn nghỉ buổi sáng: trạng thái giữ theo đơn, GV chỉ chỉnh bữa ăn (như Web).
  bool _statusLocked(KidAttendance kid) {
    final leave = kid.leave;
    return leave != null &&
        leave.isHalfDay &&
        leave.part == DayPartCode.morning;
  }

  void _update(String childId, KidAttendance Function(KidAttendance) change) {
    setState(() {
      _kids = [
        for (final kid in _kids) kid.childId == childId ? change(kid) : kid,
      ];
      if (_saveState != _SaveState.saving) _saveState = _SaveState.idle;
    });
  }

  void _setPresent(KidAttendance kid) => _update(
    kid.childId,
    (item) => item.copyWith(
      status: AttendanceStatus.present,
      meals: item.status == AttendanceStatus.present
          ? item.meals
          : _presentMeals(item),
    ),
  );

  // Đơn nghỉ cả ngày ⇒ vắng có phép (ATT-04); còn lại vắng không phép
  void _setAbsent(KidAttendance kid) => _update(
    kid.childId,
    (item) => item.copyWith(
      status:
          item.leave != null &&
              !item.leave!.noticeOnly &&
              item.leave!.part == DayPartCode.fullDay
          ? AttendanceStatus.excused
          : AttendanceStatus.unexcused,
      meals: const {},
    ),
  );

  /// Có mặt tất cả: chỉ trẻ chưa điểm danh (như Web), bật ăn các bữa của lớp trừ trẻ không báo ăn.
  void _markAllPresent() {
    setState(() {
      _kids = [
        for (final kid in _kids)
          kid.status == AttendanceStatus.notRecorded && !_statusLocked(kid)
              ? kid.copyWith(
                  status: AttendanceStatus.present,
                  meals: _presentMeals(kid),
                )
              : kid,
      ];
      _saveState = _SaveState.idle;
    });
  }

  /// Chỉ gửi trẻ đã điểm danh và khác bản BE trả (đơn nghỉ cả ngày BE đã ghi sẵn).
  List<KidAttendance> get _dirtyKids => [
    for (final kid in _kids)
      if (_saved[kid.childId] case final saved? when kid.changedFrom(saved))
        kid,
  ];

  Future<void> _save() async {
    final sheet = _sheet;
    if (sheet == null || _saveState == _SaveState.saving) return;
    setState(() => _saveState = _SaveState.saving);
    try {
      final entries = _dirtyKids;
      if (entries.isNotEmpty) {
        await _source.save(widget.classId, sheet.date, entries);
      }
      if (!mounted) return;
      setState(() {
        _saved = {for (final kid in _kids) kid.childId: kid};
        _saveState = _SaveState.saved;
      });
      widget.onSaved?.call();
      widget.onOpenHealth?.call(widget.classId, sheet.date);
    } catch (_) {
      // Giữ nguyên lựa chọn để gửi lại (component.md: nhập hàng loạt)
      if (!mounted) return;
      setState(() => _saveState = _SaveState.failed);
    }
  }

  Future<void> _chooseMealParticipation() async {
    final updated = await Navigator.of(context).push<List<KidAttendance>>(
      MaterialPageRoute(
        builder: (_) => MealParticipationScreen(
          kids: _kids,
          mealSessions: _sheet?.mealSessions ?? MealSession.values,
          sessionsFor: _sessionsFor,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _kids = updated;
      if (_saveState != _SaveState.saving) _saveState = _SaveState.idle;
    });
  }

  Future<void> _openLeave(KidAttendance kid) async {
    final leave = kid.leave;
    if (leave == null) return;
    await showAppBottomSheet<void>(
      context: context,
      title: 'Thông tin báo nghỉ',
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        final eats = leave.eats;
        final details = [
          '${DateLabels.date(leave.fromDate)} – ${DateLabels.date(leave.toDate)}',
          if (leave.isHalfDay) leave.part.label,
          if (leave.isHalfDay && eats != null)
            'Trẻ tham gia ăn: ${eats ? 'Có' : 'Không'}'
                '${leave.eatsMeals.isEmpty ? '' : ' (${leave.eatsMeals.map((s) => s.label).join(', ')})'}',
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(kid.fullName, style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.space1),
            Text(details.join(' · '), style: textTheme.bodyMedium),
            if (leave.noticeOnly) ...[
              const SizedBox(height: AppSpacing.space3),
              const AppBanner(
                message:
                    'Báo nghỉ chiều sau giờ chốt: chỉ thông báo cho lớp, không thay đổi điểm danh hoặc suất ăn đã chốt.',
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            Text(
              leave.reason.isEmpty ? 'Không có ghi chú.' : leave.reason,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            AppButton(
              label: 'Đóng',
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );
  }

  int _count(AttendanceStatus status) =>
      _kids.where((kid) => kid.status == status).length;

  int get _presentCount => _count(AttendanceStatus.present);

  int get _mealCount => _kids.where((kid) => kid.eatsAtSchool).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm danh')),
      body: _buildBody(),
      bottomNavigationBar:
          _loading || _loadError != null || _kids.isEmpty || !_editable
          ? null
          : _buildDock(),
    );
  }

  Widget _dateChip() => Align(
    alignment: Alignment.centerLeft,
    child: AppContextChip(
      label: _isToday ? 'Hôm nay' : DateLabels.date(_date),
      leading: const Icon(AppIcons.calendar, size: 20),
      onTap: _pickDate,
    ),
  );

  Widget _buildBody() {
    if (_sheet == null && _loading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: AppSkeletonList(rows: 7),
      );
    }
    if (_loadError != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _dateChip(),
          AppErrorState(
            title: 'Chưa tải được danh sách lớp',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            onRetry: _load,
          ),
        ],
      );
    }
    final sheet = _sheet!;
    if (!_loading && _kids.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _dateChip(),
          const AppEmptyState(
            title: 'Lớp chưa có trẻ',
            message:
                'Danh sách trẻ của lớp do nhà trường cập nhật. Liên hệ BGH nếu thấy thiếu.',
          ),
        ],
      );
    }
    final saving = _saveState == _SaveState.saving;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: _loading ? 2 : _kids.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(sheet);
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.space3),
            child: AppSkeletonList(rows: 5),
          );
        }
        final kid = _kids[index - 1];
        return Padding(
          key: ValueKey(kid.childId),
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: AttendanceKidRow(
            kid: kid,
            enabled: !saving && _editable && !_statusLocked(kid),
            onPresent: () => _setPresent(kid),
            onAbsent: () => _setAbsent(kid),
            onOpenLeave: () => _openLeave(kid),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AttendanceSheet sheet) {
    final textTheme = Theme.of(context).textTheme;
    final saving = _saveState == _SaveState.saving;
    final historyOnly = _classReadOnly || !_isToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateChip(),
        const SizedBox(height: AppSpacing.space3),
        // Bố cục A: dòng lớp/ngày trơn trên nền, badge khoá có icon
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            Text(
              '${sheet.classSummary.name} · ${DateLabels.weekdayDayMonth(sheet.date)}',
              style: textTheme.titleSmall,
            ),
            if (!sheet.schoolDay)
              const AppStatusBadge(
                label: 'Không phải ngày học',
                tone: AppStatusTone.gray,
              )
            else if (sheet.locked)
              const AppStatusBadge(
                label: 'Đã khóa',
                tone: AppStatusTone.red,
                icon: AppIcons.lock,
              )
            else if (sheet.lockAt != null)
              AppStatusBadge(
                label: 'Khóa lúc ${sheet.lockAt}',
                tone: AppStatusTone.orange,
                icon: AppIcons.lock,
              ),
          ],
        ),
        if (historyOnly) ...[
          const SizedBox(height: AppSpacing.space3),
          const AppBanner(
            icon: AppIcons.lock,
            message: 'Đang xem lịch sử, không sửa được',
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        AppStatRow(
          tiles: [
            AppStatTile(
              value: '${_count(AttendanceStatus.present)}',
              label: 'Có mặt',
              tone: AppStatusTone.green,
            ),
            AppStatTile(
              value: '${_count(AttendanceStatus.excused)}',
              label: 'Có phép',
              tone: AppStatusTone.blue,
            ),
            AppStatTile(
              value: '${_count(AttendanceStatus.unexcused)}',
              label: 'Không phép',
              tone: AppStatusTone.red,
            ),
            AppStatTile(
              value: '${_count(AttendanceStatus.notRecorded)}',
              label: 'Chưa ĐD',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        // Các nút đủ rộng để đọc hết chữ và dễ bấm một tay
        AppButton(
          label: 'Có mặt tất cả',
          icon: AppIcons.checks,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed:
              saving || !_editable || _count(AttendanceStatus.notRecorded) == 0
              ? null
              : _markAllPresent,
        ),
        const SizedBox(height: AppSpacing.space2),
        AppButton(
          label: 'Tham gia ăn ($_mealCount/$_presentCount)',
          icon: AppIcons.meal,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: saving || !_editable || _presentCount == 0
              ? null
              : _chooseMealParticipation,
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.meal, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.space1),
            Flexible(
              child: Text(
                'Suất ăn: $_mealCount/$_presentCount trẻ có mặt',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        if (widget.onOpenSummary != null ||
            (!_editable && widget.onOpenHealth != null)) ...[
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.space2,
            children: [
              if (!_editable && widget.onOpenHealth != null)
                AppButton(
                  label: 'Sức khỏe đầu ngày',
                  icon: AppIcons.heart,
                  variant: AppButtonVariant.text,
                  small: true,
                  onPressed: () =>
                      widget.onOpenHealth!(widget.classId, sheet.date),
                ),
              if (widget.onOpenSummary case final open?)
                AppButton(
                  label: 'Tổng hợp lớp',
                  icon: AppIcons.clipboardCheck,
                  variant: AppButtonVariant.text,
                  small: true,
                  onPressed: () => open(widget.classId),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        if (_saveState == _SaveState.failed) ...[
          const AppBanner(
            kind: AppBannerKind.danger,
            title: 'Chưa lưu được điểm danh',
            message: 'Lựa chọn vẫn giữ nguyên. Kiểm tra mạng rồi lưu lại.',
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
        if (_saveState == _SaveState.saved) ...[
          const AppBanner(
            kind: AppBannerKind.success,
            message: 'Đã lưu điểm danh cả lớp.',
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
      ],
    );
  }

  Widget _buildDock() {
    return AppBottomDock(
      children: [
        AppButton(
          label: _saveState == _SaveState.failed
              ? 'Lưu lại'
              : 'Lưu và sang Sức khỏe đầu ngày',
          loadingLabel: 'Đang lưu',
          isLoading: _saveState == _SaveState.saving,
          expand: true,
          onPressed: _save,
        ),
      ],
    );
  }
}
