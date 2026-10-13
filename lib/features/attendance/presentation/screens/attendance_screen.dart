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
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/attendance/domain/attendance.dart';
import 'package:carenest_app/features/attendance/presentation/widgets/attendance_kid_row.dart';

enum _SaveState { idle, saving, saved, failed }

/// Điểm danh & báo ăn cả lớp — mockup T02. APP không tính số suất (NUT-01): các ô đếm chỉ là
/// tổng lựa chọn đang nhập; ngoài mặc định "có ăn", bấm tên bé để báo ăn (ATT-02).
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
      if (_saveState != _SaveState.saving) _saveState = _SaveState.idle;
    });
  }

  void _setPresent(KidAttendance kid) => _update(
    kid.childId,
    (item) => item.copyWith(status: AttendanceStatus.present, eats: true),
  );

  // Có đơn nghỉ ⇒ vắng vẫn là có phép (ATT-04); không đơn ⇒ vắng không phép
  void _setAbsent(KidAttendance kid) => _update(
    kid.childId,
    (item) => item.copyWith(
      status: item.hasLeaveNotice
          ? AttendanceStatus.excused
          : AttendanceStatus.unexcused,
      eats: false,
    ),
  );

  void _markAllPresent() {
    setState(() {
      _kids = [
        for (final kid in _kids)
          kid.status == AttendanceStatus.notRecorded
              ? kid.copyWith(status: AttendanceStatus.present, eats: true)
              : kid,
      ];
      _saveState = _SaveState.idle;
    });
  }

  void _pickMeals(KidAttendance kid) {
    if (kid.status != AttendanceStatus.present) return;
    showAppBottomSheet<void>(
      context: context,
      title: 'Báo ăn: ${kid.fullName}',
      builder: (sheetContext) => Column(
        children: [
          for (final (eats, label) in const [
            (true, 'Có ăn'),
            (false, 'Không ăn'),
          ])
            AppSheetOption(
              selected: kid.eats == eats,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _update(kid.childId, (item) => item.copyWith(eats: eats));
              },
              child: Align(alignment: Alignment.centerLeft, child: Text(label)),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final sheet = _sheet;
    if (sheet == null) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm danh & báo ăn')),
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
                      style: textTheme.titleSmall,
                    ),
                    if (sheet.lockAt != null)
                      AppStatusBadge(
                        label: 'Khoá lúc ${sheet.lockAt}',
                        tone: AppStatusTone.approval,
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
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              AppButton(
                label: 'Đánh dấu tất cả có mặt',
                icon: AppIcons.checks,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: saving || _count(AttendanceStatus.notRecorded) == 0
                    ? null
                    : _markAllPresent,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Chạm 1 lần cho cả lớp, sau đó chỉ sửa các bé vắng / có phép. Chạm tên bé để báo ăn.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
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
            onTapMeals: () => _pickMeals(kid),
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
