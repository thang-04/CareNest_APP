import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/daily_health/data/fake_daily_health_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/teacher/daily_health/presentation/screens/daily_health_entry_screen.dart';
import 'package:carenest_app/features/teacher/shared/class_date_bar.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';
import 'package:carenest_app/routing/route_paths.dart';

enum _Filter {
  all('Tất cả'),
  unchecked('Chưa kiểm tra'),
  normal('Bình thường'),
  noted('Có dấu hiệu');

  const _Filter(this.label);
  final String label;
}

/// Sức khỏe trong ngày (HLT-07, HLT-14): trẻ có mặt của lớp/ngày, chạm một trẻ để ghi thân nhiệt, biểu hiện,
/// xử trí và xem lịch sử. Trẻ chưa ghi hiện "Chưa kiểm tra" — APP không tự coi là bình thường.
/// Chỉ ghi khi đúng hôm nay, lớp được dạy và BE cho phép; còn lại chỉ xem.
class DailyHealthScreen extends StatefulWidget {
  const DailyHealthScreen({
    super.key,
    required this.classId,
    this.classes = const [],
    this.today,
    this.source,
    this.initialDate,
  });

  final String classId;

  /// Lớp chọn được trên thanh Lớp · Ngày; rỗng ⇒ chỉ lớp [classId].
  final List<ClassOption> classes;

  /// Hôm nay theo giờ trường (mặc định ngày máy).
  final DateTime? today;
  final DailyHealthSource? source;

  /// Ngày mở sẵn (vd. từ màn điểm danh); mặc định hôm nay.
  final DateTime? initialDate;

  @override
  State<DailyHealthScreen> createState() => _DailyHealthScreenState();
}

class _DailyHealthScreenState extends State<DailyHealthScreen> {
  late final DailyHealthSource _source =
      widget.source ?? FakeDailyHealthSource.shared;
  late final DateTime _today = _dateOnly(widget.today ?? DateTime.now());
  late String _classId = widget.classId;
  late DateTime _date = widget.initialDate == null
      ? _today
      : _dateOnly(widget.initialDate!);
  DailyHealthSheet? _sheet;
  bool _loading = true;
  Object? _error;
  int _loadSeq = 0;
  _Filter _filter = _Filter.all;
  String _query = '';

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isToday => _date == _today;

  List<ClassOption> get _classOptions => widget.classes.isEmpty
      ? [ClassOption(id: widget.classId, name: _sheet?.className ?? '')]
      : widget.classes;

  bool get _classReadOnly =>
      _classOptions
          .where((item) => item.id == _classId)
          .firstOrNull
          ?.readOnly ??
      false;

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sheet = await _source.loadSheet(
        _classId,
        date: _isToday ? null : _date,
      );
      // Bỏ phản hồi muộn của lớp/ngày đã đổi
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _sheet = sheet;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _changeContext({String? classId, DateTime? date}) {
    setState(() {
      if (classId != null) _classId = classId;
      if (date != null) _date = _dateOnly(date);
    });
    _load();
  }

  Future<void> _open(DailyHealthSheet sheet, DailyHealthKid kid) async {
    final readOnly =
        !sheet.canRecord || _classReadOnly || !_isToday || kid.pickedUp;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailyHealthEntryScreen(
          sheet: sheet,
          kid: kid,
          source: _source,
          readOnly: readOnly,
        ),
      ),
    );
    if (saved == true) _load();
  }

  bool _matches(DailyHealthKid kid) {
    if (!matchesSearch('${kid.fullName} ${kid.code ?? ''}', _query)) {
      return false;
    }
    final observation = kid.latest?.observation;
    return switch (_filter) {
      _Filter.all => true,
      _Filter.unchecked => !kid.checked,
      _Filter.normal => observation == HealthObservation.noConcern,
      _Filter.noted => observation == HealthObservation.noted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sức khỏe trong ngày')),
      body: _buildBody(context),
    );
  }

  Widget _contextBar() => ClassDateBar(
    classes: _classOptions,
    classId: _classId,
    date: _date,
    today: _today,
    onClassChanged: (id) => _changeContext(classId: id),
    onDateChanged: (date) => _changeContext(date: date),
  );

  Widget _buildBody(BuildContext context) {
    final sheet = _sheet;
    if (sheet == null && _error == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: AppSkeletonList(rows: 6),
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _contextBar(),
          AppErrorState(
            title: 'Chưa tải được danh sách',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            onRetry: _load,
          ),
        ],
      );
    }
    final data = sheet!;
    final visible = [
      for (final kid in data.kids)
        if (_matches(kid)) kid,
    ];
    final checked = data.kids.where((kid) => kid.checked).length;
    final noted = data.kids
        .where((kid) => kid.latest?.observation == HealthObservation.noted)
        .length;
    final historyOnly = _classReadOnly || !_isToday;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: _loading || data.kids.isEmpty ? 2 : visible.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _contextBar(),
              const SizedBox(height: AppSpacing.space3),
              if (historyOnly) ...[
                const AppBanner(
                  icon: AppIcons.lock,
                  message: 'Đang xem lịch sử, không sửa được',
                ),
                const SizedBox(height: AppSpacing.space3),
              ] else if (!data.canRecord) ...[
                const AppBanner(icon: AppIcons.lock, message: 'Chỉ xem'),
                const SizedBox(height: AppSpacing.space3),
              ],
              AppStatRow(
                tiles: [
                  AppStatTile(
                    value: '${data.kids.length}',
                    label: 'Có mặt',
                    tone: AppStatusTone.green,
                  ),
                  AppStatTile(value: '$checked', label: 'Đã kiểm tra'),
                  AppStatTile(
                    value: '$noted',
                    label: 'Có dấu hiệu',
                    tone: AppStatusTone.orange,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                flush: true,
                child: AppListRow(
                  leading: const AppIconTile(
                    icon: AppIcons.heart,
                    tone: AppStatusTone.blue,
                  ),
                  title: 'Cân nặng & chiều cao',
                  subtitle: const Text('Nhập nhanh trong đợt cân đo'),
                  showChevron: true,
                  onTap: () => context.push(RoutePaths.teacherHealth),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppSearchField(
                hint: 'Tìm tên hoặc mã trẻ',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppSpacing.space3),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _Filter.values) ...[
                      AppFilterChip(
                        label: filter.label,
                        selected: _filter == filter,
                        onSelected: () => setState(() => _filter = filter),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
          );
        }
        if (_loading) return const AppSkeletonList(rows: 4);
        if (data.kids.isEmpty || visible.isEmpty) {
          return AppEmptyState(
            icon: AppIcons.heart,
            title: data.kids.isEmpty
                ? 'Chưa có trẻ có mặt'
                : 'Không tìm thấy trẻ',
            message: data.kids.isEmpty
                ? 'Lưu điểm danh trước, trẻ có mặt sẽ hiện ở đây.'
                : 'Thử đổi bộ lọc hoặc tìm kiếm.',
          );
        }
        if (index == visible.length + 1) return const SizedBox.shrink();
        final kid = visible[index - 1];
        return Padding(
          key: ValueKey(kid.childId),
          padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
          child: AppCard(
            flush: true,
            child: AppListRow(
              leading: AppAvatar(name: kid.fullName),
              title: kid.fullName,
              subtitle: Text(_subtitle(kid)),
              trailing: _badge(kid),
              showChevron: true,
              onTap: () => _open(data, kid),
            ),
          ),
        );
      },
    );
  }

  static String _subtitle(DailyHealthKid kid) {
    if (kid.handedOverAt case final at?) {
      return 'Đã trả trẻ lúc ${DateLabels.time24(at)}';
    }
    final latest = kid.latest;
    if (latest == null) return 'Chưa kiểm tra';
    return [
      if (latest.temperature != null) formatTemperature(latest.temperature!),
      ...latest.symptoms.map((s) => s.label),
      if (latest.recordedAt != null) DateLabels.time24(latest.recordedAt!),
    ].join(' · ');
  }

  static Widget? _badge(DailyHealthKid kid) =>
      switch (kid.latest?.observation) {
        null => null,
        HealthObservation.noConcern => const AppStatusBadge(
          label: 'Bình thường',
          tone: AppStatusTone.green,
        ),
        HealthObservation.noted => const AppStatusBadge(
          label: 'Có dấu hiệu',
          tone: AppStatusTone.orange,
          icon: AppIcons.heart,
        ),
      };
}

/// "37,8 °C" — dấu phẩy thập phân theo tiếng Việt.
String formatTemperature(double value) =>
    '${value.toStringAsFixed(1).replaceAll('.', ',')} °C';
