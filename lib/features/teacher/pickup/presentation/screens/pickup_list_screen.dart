import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';
import 'package:carenest_app/features/teacher/shared/class_date_bar.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

/// Trả trẻ — bảng đón của lớp (mockup T05), dạng theo BE `PickupBoardResponse`: bé có mặt chia
/// Chờ đón / Đã đón; chạm "Trả trẻ" để đối chiếu phụ huynh trên hồ sơ (PCK-02).
/// Thêm theo BE: chọn ngày xem lại (ngày khác hôm nay chỉ xem), số lần gọi phụ huynh không trả,
/// liên kết sang Kết quả trả trẻ.
class PickupListScreen extends StatefulWidget {
  const PickupListScreen({
    super.key,
    required this.onVerify,
    this.onCall,
    this.onOpenResults,
    this.onOpenHealth,
    this.onOpenAttendance,
    this.classId = FakeClassRosterSource.classId,
    this.classes = const [],
    this.today,
    this.source,
  });

  /// Mở màn xác minh người đón; trả về khi đóng để tải lại.
  final Future<void> Function(String childId) onVerify;

  /// Không dùng ở bản mẫu gốc: gọi phụ huynh nằm trong màn Trả trẻ ("Ghi kết quả gọi").
  final Future<void> Function(String childId)? onCall;

  /// Mở "Kết quả trả trẻ"; null ⇒ ẩn nút.
  final VoidCallback? onOpenResults;

  /// Không dùng ở bản mẫu gốc (giữ để router không đổi).
  final void Function(String childId, DateTime date)? onOpenHealth;

  /// Mở Điểm danh khi còn bé chưa điểm danh; null ⇒ ẩn nút.
  final VoidCallback? onOpenAttendance;
  final String classId;

  /// Lớp của giáo viên; chỉ để lấy tên lớp và cờ chỉ xem.
  final List<ClassOption> classes;

  /// Hôm nay theo giờ nhà trường; mặc định ngày máy (bản giả: ngày giả).
  final DateTime? today;
  final PickupSource? source;

  @override
  State<PickupListScreen> createState() => _PickupListScreenState();
}

class _PickupListScreenState extends State<PickupListScreen> {
  late final PickupSource _source = widget.source ?? FakePickupSource.shared;
  late final DateTime _today = _dayOf(
    widget.today ??
        (_source is FakePickupSource ? FakePickupSource.today : DateTime.now()),
  );
  late DateTime _date = _today;
  PickupBoard? _board;
  Object? _error;
  String _query = '';
  int _seq = 0;

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isToday => _date == _today;

  List<ClassOption> get _classes => widget.classes.isEmpty
      ? [ClassOption(id: widget.classId, name: _board?.className ?? 'Lớp')]
      : widget.classes;

  bool get _classReadOnly => _classes
      .where((item) => item.id == widget.classId)
      .any((item) => item.readOnly);

  Future<void> _load({bool silent = false}) async {
    if (widget.classId.isEmpty) return;
    final seq = ++_seq;
    if (!silent) {
      setState(() {
        _board = null;
        _error = null;
      });
    }
    try {
      final board = await _source.loadBoard(
        widget.classId,
        date: _isToday ? null : _date,
      );
      if (mounted && seq == _seq) {
        setState(() {
          _board = board;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && seq == _seq) setState(() => _error = error);
    }
  }

  Future<void> _verify(PickupRow kid) async {
    await widget.onVerify(kid.childId);
    if (mounted) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    final readOnly =
        _classReadOnly || !_isToday || (board != null && !board.canRecord);
    return Scaffold(
      appBar: AppBar(title: const Text('Trả trẻ')),
      body: widget.classId.isEmpty
          ? const Center(
              child: AppEmptyState(
                icon: AppIcons.classGroup,
                title: 'Bạn chưa được phân công lớp',
                message: 'Chỉ giáo viên của lớp trả trẻ cho người đón.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                ClassDateBar(
                  classes: _classes,
                  classId: widget.classId,
                  date: _date,
                  today: _today,
                  onDateChanged: (day) {
                    _date = day;
                    _load();
                  },
                ),
                const SizedBox(height: AppSpacing.space3),
                if (readOnly) ...[
                  const AppBanner(
                    message: 'Đang xem lịch sử, không sửa được',
                    kind: AppBannerKind.neutral,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                if (_error != null)
                  AppErrorState(
                    title: 'Chưa tải được bảng đón',
                    message: loadFailureMessage(_error),
                    onRetry: _load,
                  )
                else if (board == null)
                  const AppSkeletonList(rows: 5)
                else
                  ..._content(board, readOnly),
              ],
            ),
    );
  }

  List<Widget> _content(PickupBoard board, bool readOnly) {
    final rows = board.rows;
    int count(PickupStatus status) =>
        rows.where((row) => row.status == status).length;
    final picked = count(PickupStatus.pickedUp);
    final waiting = count(PickupStatus.waiting);
    final unmarked = count(PickupStatus.unmarked);
    final visible = rows
        .where((row) => matchesSearch(row.fullName, _query))
        .toList();
    return [
      AppStatRow(
        tiles: [
          AppStatTile(
            value: '$picked',
            label: 'Đã đón',
            tone: AppStatusTone.green,
          ),
          AppStatTile(
            value: '$waiting',
            label: 'Chờ đón',
            tone: AppStatusTone.orange,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space3),
      AppSearchField(
        hint: 'Tìm tên bé…',
        onChanged: (value) => setState(() => _query = value),
      ),
      const SizedBox(height: AppSpacing.space3),
      // Chưa ai có mặt để trả: nói rõ vì sao (chỉ bé điểm danh Có mặt mới chờ đón)
      if (waiting == 0 && unmarked > 0 && _query.trim().isEmpty) ...[
        AppBanner(
          kind: AppBannerKind.warning,
          message:
              'Còn $unmarked bé chưa điểm danh. Chỉ bé Có mặt mới trả được.',
        ),
        if (!readOnly && widget.onOpenAttendance != null) ...[
          const SizedBox(height: AppSpacing.space2),
          AppButton(
            label: 'Điểm danh ngay',
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: widget.onOpenAttendance,
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
      ],
      if (visible.isEmpty)
        const AppEmptyState(
          icon: AppIcons.walk,
          title: 'Không có bé phù hợp',
          message: 'Thử đổi từ khóa tìm kiếm hoặc chờ bé điểm danh Có mặt.',
        )
      else
        for (final kid in visible) ...[
          AppCard(
            flush: true,
            child: AppListRow(
              leading: AppAvatar(name: kid.fullName),
              title: kid.fullName,
              subtitle: Text(_subtitle(kid)),
              // PCK-01: chỉ bé có mặt (WAITING) mới trả được; ngày cũ/lớp chỉ xem ⇒ không có nút
              trailing: switch (kid.status) {
                PickupStatus.pickedUp => const AppStatusBadge(
                  label: 'Đã đón',
                  tone: AppStatusTone.green,
                ),
                PickupStatus.waiting when !readOnly => AppButton(
                  label: 'Trả trẻ',
                  small: true,
                  onPressed: () => _verify(kid),
                ),
                PickupStatus.waiting => const AppStatusBadge(
                  label: 'Chờ đón',
                  tone: AppStatusTone.orange,
                ),
                _ => null,
              },
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
      if (widget.onOpenResults != null) ...[
        const SizedBox(height: AppSpacing.space2),
        AppButton(
          label: 'Kết quả trả trẻ hôm nay',
          icon: AppIcons.clipboardCheck,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: widget.onOpenResults,
        ),
      ],
    ];
  }

  /// "Đã đón 16:35 · Mẹ Nguyễn Thu Lan"; chờ đón kèm "N lần không trả trẻ" nếu BE có attempts.
  static String _subtitle(PickupRow kid) {
    final failed = kid.failedAttempts;
    return switch (kid.status) {
      PickupStatus.pickedUp => _pickedLine(kid.pickup!),
      PickupStatus.waiting =>
        failed > 0 ? 'Chờ đón · $failed lần không trả trẻ' : 'Chờ đón',
      PickupStatus.absent => 'Vắng hôm nay',
      PickupStatus.unmarked => 'Chưa điểm danh',
    };
  }

  static String _pickedLine(PickupRecord record) {
    final time = record.handedOverAt == null
        ? ''
        : ' ${DateLabels.time24(record.handedOverAt!)}';
    final who = record.pickupPersonName == null
        ? 'đã gọi xác nhận'
        : pickupPersonLabel(record);
    return 'Đã đón$time · $who';
  }
}

/// Người đón như Web `PickupPerson`: "Mẹ Nguyễn Thu Lan"; gọi phụ huynh ⇒ "Theo nội dung cuộc gọi".
String pickupPersonLabel(PickupRecord record) {
  final name = record.pickupPersonName;
  if (name == null) return 'Theo nội dung cuộc gọi';
  return '${record.pickupPersonRelationship?.label ?? ''} $name'.trim();
}

/// Tông badge xác minh như Web: thông tin = teal, không trả = đỏ, không liên lạc được = cam.
AppStatusTone pickupVerificationTone(PickupVerification verification) =>
    switch (verification) {
      PickupVerification.photoMatch ||
      PickupVerification.phoneConfirmed => AppStatusTone.teal,
      PickupVerification.phoneDeclined => AppStatusTone.red,
      PickupVerification.phoneUnreachable => AppStatusTone.orange,
    };
