import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/attendance/domain/arrival_health.dart';
import 'package:carenest_app/features/attendance/domain/attendance.dart';
import 'package:carenest_app/features/attendance/presentation/widgets/attendance_kid_row.dart';

enum _SaveState { idle, saving, saved, failed, invalid }

/// Điểm danh & sức khỏe đầu ngày cả lớp — mockup T02, form sức khỏe như Web (HLT-07). Có mặt là ăn đủ
/// các bữa, không báo ăn riêng (ATT-02); APP không tính số suất (NUT-01): các ô đếm chỉ là tổng lựa chọn
/// đang nhập. Ngày nghỉ theo lịch trường không điểm danh (P-19).
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.classId, this.source});

  final String classId;
  final AttendanceSource? source;

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
        _kids = sheet.kids;
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

  void _update(String childId, KidAttendance Function(KidAttendance) change) {
    setState(() {
      _kids = [
        for (final kid in _kids) kid.childId == childId ? change(kid) : kid,
      ];
      // Đang báo lỗi sức khỏe thì giữ báo lỗi (cập nhật theo ô vừa sửa) tới khi hết lỗi
      if (_saveState == _SaveState.invalid) {
        if (_invalidCount == 0) _saveState = _SaveState.idle;
      } else if (_saveState != _SaveState.saving) {
        _saveState = _SaveState.idle;
      }
    });
  }

  void _setPresent(KidAttendance kid) => _update(
    kid.childId,
    (item) => item.copyWith(status: AttendanceStatus.present),
  );

  // GV chỉ có Có mặt / Vắng không phép; có phép do đơn nghỉ đặt (ATT-09). Trẻ vắng không có sức khỏe.
  void _setAbsent(KidAttendance kid) => _update(
    kid.childId,
    (item) => item.copyWith(
      status: AttendanceStatus.unexcused,
      health: const ArrivalHealth(),
    ),
  );

  void _setHealth(KidAttendance kid, ArrivalHealth health) =>
      _update(kid.childId, (item) => item.copyWith(health: health));

  Map<ArrivalHealthField, String> _errorsOf(KidAttendance kid) =>
      kid.status == AttendanceStatus.present
      ? validateArrivalHealth(kid.health)
      : const {};

  int get _invalidCount =>
      _kids.where((kid) => _errorsOf(kid).isNotEmpty).length;

  void _markAllPresent() {
    setState(() {
      _kids = [
        for (final kid in _kids)
          kid.status == AttendanceStatus.notRecorded
              ? kid.copyWith(status: AttendanceStatus.present)
              : kid,
      ];
      _saveState = _SaveState.idle;
    });
  }

  Future<void> _save() async {
    final sheet = _sheet;
    if (sheet == null) return;
    // Ghi sức khỏe chưa đủ ⇒ chỉ ra ô lỗi, giữ nguyên dữ liệu, chưa gửi
    if (_invalidCount > 0) {
      setState(() => _saveState = _SaveState.invalid);
      return;
    }
    setState(() => _saveState = _SaveState.saving);
    try {
      await _source.save(widget.classId, sheet.date, _kids);
      if (!mounted) return;
      setState(() => _saveState = _SaveState.saved);
    } catch (_) {
      // Giữ nguyên lựa chọn để gửi lại (component.md: nhập hàng loạt)
      if (!mounted) return;
      setState(() => _saveState = _SaveState.failed);
    }
  }

  int _count(AttendanceStatus status) =>
      _kids.where((kid) => kid.status == status).length;

  int get _healthChecked => _kids
      .where(
        (kid) =>
            kid.status == AttendanceStatus.present &&
            kid.health.observation != null,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final holiday = _sheet != null && !_sheet!.isSchoolDay;
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm danh & sức khỏe')),
      body: _buildBody(),
      bottomNavigationBar:
          _loading || _loadError != null || _kids.isEmpty || holiday
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
    if (!_sheet!.isSchoolDay) {
      return const Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            icon: AppIcons.calendarOff,
            title: 'Hôm nay trường nghỉ',
            message: 'Ngày nghỉ theo lịch của trường nên không điểm danh.',
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
              // Figma GV02: thẻ lớp/ngày + badge giờ khoá cùng dòng; chữ lớn thì badge xuống dòng
              AppCard(
                dense: true,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    Text(
                      '${sheet.classSummary.name} · ${DateLabels.weekdayDayMonth(sheet.date)}',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sheet.lockAt != null)
                      AppStatusBadge(
                        label: 'Khoá lúc ${sheet.lockAt}',
                        tone: AppStatusTone.orange,
                      ),
                  ],
                ),
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
                    tone: AppStatusTone.gray,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              _SoftOutlined(
                child: AppButton(
                  label: 'Đánh dấu tất cả có mặt',
                  icon: AppIcons.checks,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: saving || _count(AttendanceStatus.notRecorded) == 0
                      ? null
                      : _markAllPresent,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Chạm 1 lần cho cả lớp, rồi kiểm tra sức khỏe đầu ngày từng bé có mặt.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'Sức khỏe đầu ngày: $_healthChecked/${_count(AttendanceStatus.present)} bé có mặt đã kiểm tra',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              if (_saveState == _SaveState.invalid) ...[
                AppBanner(
                  kind: AppBannerKind.danger,
                  title: 'Còn $_invalidCount bé ghi sức khỏe chưa đủ',
                  message: 'Sửa các ô báo lỗi rồi lưu lại.',
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
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
            onHealthChanged: (health) => _setHealth(kid, health),
            // Chỉ hiện lỗi sau lần bấm Lưu đầu tiên
            healthErrors: _saveState == _SaveState.invalid
                ? _errorsOf(kid)
                : const {},
          ),
        );
      },
    );
  }

  Widget _buildDock() {
    final recorded = _kids.length - _count(AttendanceStatus.notRecorded);
    return AppBottomDock(
      children: [
        AppButton(
          label: _saveState == _SaveState.failed
              ? 'Lưu lại'
              : 'Lưu điểm danh ($recorded/${_kids.length})',
          loadingLabel: 'Đang lưu',
          isLoading: _saveState == _SaveState.saving,
          expand: true,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// Nút viền nền `primarySoft` như Figma GV02 (nút phụ chung nền trắng).
class _SoftOutlined extends StatelessWidget {
  const _SoftOutlined({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
          ).merge(theme.outlinedButtonTheme.style),
        ),
      ),
      child: child,
    );
  }
}
