import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_child_health_source.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/child_health.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/teacher/class_roster/presentation/widgets/growth_line_chart.dart';

enum _TrendView { chart, table }

/// Nhãn trạng thái trẻ như Web (`CHILD_STATUS_LABELS`).
String rosterStatusLabel(RosterKidStatus status) => switch (status) {
  RosterKidStatus.active => 'Đang học',
  RosterKidStatus.pendingPlacement => 'Chờ xếp lớp',
  RosterKidStatus.left => 'Đã nghỉ học',
};

/// Trẻ trong lớp (chỉ xem): thông tin chung, "Xu hướng sức khỏe" (Biểu đồ | Bảng số liệu) và
/// "Lịch sử khám, cân đo" như Web. Không hiện bản nháp AI.
class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({
    super.key,
    required this.kid,
    required this.className,
    this.source = const FakeChildHealthSource(),
  });

  final RosterKid kid;
  final String className;
  final ChildHealthSource source;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  ChildHealthHistory? _history;
  Object? _error;
  _TrendView _view = _TrendView.chart;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final history = await widget.source.load(widget.kid.id);
      if (mounted) setState(() => _history = history);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kid = widget.kid;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(kid.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppAvatar(name: kid.fullName),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Text(kid.fullName, style: textTheme.titleMedium),
                    ),
                    AppStatusBadge(
                      label: rosterStatusLabel(kid.status),
                      tone: kid.status == RosterKidStatus.active
                          ? AppStatusTone.green
                          : AppStatusTone.gray,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                _Field('Lớp', widget.className),
                if (kid.dateOfBirth != null)
                  _Field('Ngày sinh', DateLabels.date(kid.dateOfBirth!)),
                if (kid.ageLabel.isNotEmpty) _Field('Tuổi', kid.ageLabel),
                if (kid.guardianLine.isNotEmpty)
                  _Field('Phụ huynh', kid.guardianLine),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          ..._health(_history, textTheme),
        ],
      ),
    );
  }

  List<Widget> _health(ChildHealthHistory? history, TextTheme textTheme) {
    if (_error != null) {
      return [
        AppErrorState(
          title: 'Chưa tải được sổ sức khỏe',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    if (history == null) return const [AppSkeletonList(rows: 3)];
    if (history.entries.isEmpty) {
      return const [
        AppEmptyState(
          icon: AppIcons.heart,
          title: 'Chưa có số đo',
          message: 'Lịch sử khám, cân đo của trẻ sẽ hiện ở đây.',
        ),
      ];
    }
    final entries = history.entries;
    // BE trả mới nhất trước ⇒ đảo lại cho biểu đồ (cũ nhất bên trái)
    final oldestFirst = entries.reversed.toList();
    List<ChartPoint> series(double? Function(HealthEntry) pick) => [
      for (final e in oldestFirst)
        if (pick(e) != null) (e.date, pick(e)!),
    ];
    final heights = series((e) => e.heightCm);
    final weights = series((e) => e.weightKg);
    final status = AppStatusColors.of(context);
    return [
      Semantics(
        header: true,
        child: Text('Xu hướng sức khỏe', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      AppSegmented<_TrendView>(
        segments: const [
          (_TrendView.chart, 'Biểu đồ'),
          (_TrendView.table, 'Bảng số liệu'),
        ],
        selected: _view,
        onChanged: (view) => setState(() => _view = view),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (_view == _TrendView.chart) ...[
        if (heights.isEmpty && weights.isEmpty)
          const AppEmptyState(
            icon: AppIcons.heart,
            title: 'Chưa có số đo để vẽ biểu đồ',
            message: 'Biểu đồ hiện khi trẻ có số đo chiều cao, cân nặng.',
          ),
        if (heights.isNotEmpty)
          AppCard(
            child: GrowthLineChart(
              title: 'Chiều cao',
              unit: 'cm',
              points: heights,
              color: status.tone(AppStatusTone.blue).main,
            ),
          ),
        if (heights.isNotEmpty && weights.isNotEmpty)
          const SizedBox(height: AppSpacing.space3),
        if (weights.isNotEmpty)
          AppCard(
            child: GrowthLineChart(
              title: 'Cân nặng',
              unit: 'kg',
              points: weights,
              color: status.tone(AppStatusTone.green).main,
            ),
          ),
      ] else
        AppCard(child: _MeasureTable(entries: entries)),
      const SizedBox(height: AppSpacing.sectionGap),
      Semantics(
        header: true,
        child: Text('Lịch sử khám, cân đo', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      AppCard(
        flush: true,
        child: AppDividedColumn(
          children: [
            for (final e in entries)
              AppListRow(
                title: e.title.isEmpty ? e.kindLabel : e.title,
                subtitle: Text(
                  [
                    DateLabels.date(e.date),
                    e.kindLabel,
                    if (e.heightCm != null) '${formatMeasure(e.heightCm!)} cm',
                    if (e.weightKg != null) '${formatMeasure(e.weightKg!)} kg',
                  ].join(' · '),
                ),
                trailing: e.warningLabel == null
                    ? null
                    : AppStatusBadge(
                        label: e.warningLabel!,
                        tone: e.warningTone ?? AppStatusTone.gray,
                      ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(flex: 4, child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Bảng số liệu: Ngày đo, Chiều cao, Cân nặng, BMI, Cảnh báo — giá trị và cảnh báo do BE trả.
class _MeasureTable extends StatelessWidget {
  const _MeasureTable({required this.entries});

  final List<HealthEntry> entries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final head = textTheme.labelMedium?.copyWith(color: AppColors.textMuted);
    String num(double? v) => v == null ? '—' : formatMeasure(v);
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: child,
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(2.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            for (final h in [
              'Ngày đo',
              'Chiều cao',
              'Cân nặng',
              'BMI',
              'Cảnh báo',
            ])
              cell(Text(h, style: head)),
          ],
        ),
        for (final e in entries)
          TableRow(
            children: [
              cell(Text(DateLabels.date(e.date), style: textTheme.bodyMedium)),
              cell(Text(num(e.heightCm), style: textTheme.bodyMedium)),
              cell(Text(num(e.weightKg), style: textTheme.bodyMedium)),
              cell(Text(num(e.bmi), style: textTheme.bodyMedium)),
              cell(
                e.warningLabel == null
                    ? const Text('—')
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: AppStatusBadge(
                          label: e.warningLabel!,
                          tone: e.warningTone ?? AppStatusTone.gray,
                        ),
                      ),
              ),
            ],
          ),
      ],
    );
  }
}
