import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/meal_participation_screen.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/widgets/attendance_kid_row.dart';

enum _SaveState { idle, saving, saved, failed }

/// Điểm danh cả lớp — màn chính giữ Có mặt / Vắng như Web. APP có màn phụ để chọn lại trẻ
/// có tham gia ăn; contract BE hiện vẫn cần đổi vì ATT-02 đang suy ra bữa ăn từ trạng thái.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.classId,
    this.source,
    this.onSaved,
  });

  final String classId;
  final AttendanceSource? source;

  /// Gọi sau khi lưu thành công — router mở màn Sức khỏe đầu ngày.
  final VoidCallback? onSaved;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceSource _source = widget.source ?? FakeAttendanceSource();
  AttendanceSheet? _sheet;
  List<KidAttendance> _kids = const [];
  bool _loading = true;
  Object? _loadError;
  _SaveState _saveState = _SaveState.idle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final sheet = await _source.loadSheet(widget.classId);
      if (!mounted) return;
      setState(() {
        _sheet = sheet;
        _kids = [
          for (final kid in sheet.kids) _withDefault(kid, sheet.mealSessions),
        ];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  /// Như Web: bé chưa ghi giữ "Chưa điểm danh"; bé có đơn nghỉ là Vắng có phép, không sửa (ATT-04).
  static KidAttendance _withDefault(
    KidAttendance kid,
    List<MealSession> sessions,
  ) {
    if (kid.status != AttendanceStatus.notRecorded || !kid.hasLeaveNotice) {
      return kid;
    }
    return kid.copyWith(status: AttendanceStatus.excused, meals: const {});
  }

  static Map<MealSession, bool> _allMeals(List<MealSession> sessions) => {
    for (final session in sessions) session: true,
  };

  List<MealSession> get _sessions => _sheet?.mealSessions ?? MealSession.values;

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
          : _allMeals(_sessions),
    ),
  );

  /// Có mặt tất cả: bé chưa điểm danh thành Có mặt.
  void _markAllPresent() {
    setState(() {
      // Như Web: chỉ áp cho bé chưa điểm danh
      _kids = [
        for (final kid in _kids)
          kid.status == AttendanceStatus.notRecorded
              ? kid.copyWith(
                  status: AttendanceStatus.present,
                  meals: _allMeals(_sessions),
                )
              : kid,
      ];
      _saveState = _SaveState.idle;
    });
  }

  // Có đơn nghỉ ⇒ vắng vẫn là có phép (ATT-04); không đơn ⇒ vắng không phép
  void _setAbsent(KidAttendance kid) => _update(
    kid.childId,
    (item) => item.copyWith(
      status: item.hasLeaveNotice
          ? AttendanceStatus.excused
          : AttendanceStatus.unexcused,
      meals: const {},
    ),
  );

  Future<void> _save() async {
    final sheet = _sheet;
    if (sheet == null) return;
    setState(() => _saveState = _SaveState.saving);
    try {
      await _source.save(widget.classId, sheet.date, _kids);
      if (!mounted) return;
      setState(() => _saveState = _SaveState.saved);
      widget.onSaved?.call();
    } catch (_) {
      // Giữ nguyên lựa chọn để gửi lại (component.md: nhập hàng loạt)
      if (!mounted) return;
      setState(() => _saveState = _SaveState.failed);
    }
  }

  int _count(AttendanceStatus status) =>
      _kids.where((kid) => kid.status == status).length;

  int get _presentCount => _count(AttendanceStatus.present);

  int get _mealCount => _kids.where((kid) => kid.eatsAtSchool).length;

  Future<void> _chooseMealParticipation() async {
    final updated = await Navigator.of(context).push<List<KidAttendance>>(
      MaterialPageRoute(
        builder: (_) =>
            MealParticipationScreen(kids: _kids, mealSessions: _sessions),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _kids = updated;
      if (_saveState != _SaveState.saving) _saveState = _SaveState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm danh')),
      body: _buildBody(),
      bottomNavigationBar: _loading || _loadError != null || _kids.isEmpty
          ? null
          : _buildDock(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: AppSkeletonList(rows: 7),
      );
    }
    if (_loadError != null) {
      return Center(
        child: SingleChildScrollView(
          child: AppErrorState(
            title: 'Chưa tải được danh sách lớp',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            onRetry: _load,
          ),
        ),
      );
    }
    if (_kids.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            title: 'Lớp chưa có trẻ',
            message:
                'Danh sách trẻ của lớp do nhà trường cập nhật. Liên hệ BGH nếu thấy thiếu.',
          ),
        ),
      );
    }
    final sheet = _sheet!;
    final textTheme = Theme.of(context).textTheme;
    final saving = _saveState == _SaveState.saving;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: _kids.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bố cục A: dòng lớp/ngày trơn trên nền, badge khoá cam có icon
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
                  if (sheet.lockAt != null)
                    AppStatusBadge(
                      label: 'Khóa lúc ${sheet.lockAt}',
                      tone: AppStatusTone.orange,
                      icon: AppIcons.lock,
                    ),
                ],
              ),
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
                    label: 'Vắng',
                    tone: AppStatusTone.red,
                  ),
                  AppStatTile(
                    value: '${_count(AttendanceStatus.notRecorded)}',
                    label: 'Chưa ĐD',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              // Hai nút đủ rộng để đọc hết chữ và dễ bấm một tay
              AppButton(
                label: 'Có mặt tất cả',
                icon: AppIcons.checks,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: saving || _count(AttendanceStatus.notRecorded) == 0
                    ? null
                    : _markAllPresent,
              ),
              const SizedBox(height: AppSpacing.space2),
              AppButton(
                label: 'Chọn trẻ ăn ($_mealCount/$_presentCount)',
                icon: AppIcons.meal,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: saving || _presentCount == 0
                    ? null
                    : _chooseMealParticipation,
              ),
              const SizedBox(height: AppSpacing.space2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    AppIcons.meal,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
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
              const SizedBox(height: AppSpacing.space3),
              if (_saveState == _SaveState.failed) ...[
                const AppBanner(
                  kind: AppBannerKind.danger,
                  title: 'Chưa lưu được điểm danh',
                  message:
                      'Lựa chọn vẫn giữ nguyên. Kiểm tra mạng rồi lưu lại.',
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
        final kid = _kids[index - 1];
        return Padding(
          key: ValueKey(kid.childId),
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: AttendanceKidRow(
            kid: kid,
            enabled: !saving,
            onPresent: () => _setPresent(kid),
            onAbsent: () => _setAbsent(kid),
          ),
        );
      },
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
