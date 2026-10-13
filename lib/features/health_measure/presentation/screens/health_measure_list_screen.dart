import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/health_measure/domain/health_measure.dart';

/// Đo sức khỏe — danh sách bé (mockup T07). Người nhập số đo còn PENDING (NAVIGATION [P]).
class HealthMeasureListScreen extends StatefulWidget {
  const HealthMeasureListScreen({
    super.key,
    required this.onOpenKid,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final Future<void> Function(String childId) onOpenKid;
  final String classId;
  final HealthMeasureSource? source;

  @override
  State<HealthMeasureListScreen> createState() =>
      _HealthMeasureListScreenState();
}

class _HealthMeasureListScreenState extends State<HealthMeasureListScreen> {
  late final HealthMeasureSource _source =
      widget.source ?? FakeHealthMeasureSource.shared;
  MeasureMonth? _month;
  String _query = '';
  String? _lastSaved;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final month = await _source.loadMonth(widget.classId);
    if (mounted) setState(() => _month = month);
  }

  Future<void> _open(MeasureKid kid) async {
    await widget.onOpenKid(kid.childId);
    if (!mounted) return;
    await _load();
    final updated = _month?.kids.firstWhere((k) => k.childId == kid.childId);
    if (mounted && updated?.state == MeasureState.measured) {
      setState(
        () => _lastSaved = updated!.fullName.split(' ').skip(1).join(' '),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = _month;
    final measured =
        month?.kids.where((k) => k.state == MeasureState.measured).length ?? 0;
    final total = month?.kids.length ?? 0;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(month?.title ?? 'Đo sức khỏe'),
        actions: [
          if (month != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space4),
              child: Center(
                child: Text(
                  '$measured/$total bé',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (month == null)
            const AppSkeletonList(rows: 5)
          else ...[
            AppStatRow(
              tiles: [
                AppStatTile(
                  value: '$measured',
                  label: 'Đã đo',
                  tone: AppStatusTone.green,
                ),
                AppStatTile(
                  value: '${total - measured}',
                  label: 'Chưa đo',
                  tone: AppStatusTone.orange,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            AppSearchField(
              hint: 'Tìm tên bé…',
              onChanged: (value) => setState(() => _query = value),
            ),
            if (_lastSaved != null) ...[
              const SizedBox(height: AppSpacing.space3),
              AppBanner(
                kind: AppBannerKind.success,
                message: 'Cập nhật gần nhất: vừa xong · $_lastSaved',
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            for (final kid in month.kids.where(
              (k) => matchesSearch(k.fullName, _query),
            )) ...[
              AppCard(
                flush: true,
                child: AppListRow(
                  leading: AppAvatar(name: kid.fullName),
                  title: kid.fullName,
                  subtitle: Text(switch (kid.state) {
                    MeasureState.measured =>
                      '${kid.height} cm · ${kid.weight} kg · ${kid.measuredWhen}',
                    MeasureState.pending => 'Lần trước ${kid.previous}',
                    MeasureState.absent => 'Vắng hôm nay · đo bổ sung',
                  }),
                  trailing: switch (kid.state) {
                    MeasureState.measured => const AppStatusBadge(
                      label: 'Đã đo',
                      tone: AppStatusTone.green,
                    ),
                    MeasureState.pending => AppButton(
                      label: 'Đo',
                      small: true,
                      onPressed: () => _open(kid),
                    ),
                    MeasureState.absent => const AppStatusBadge(
                      label: 'Vắng',
                      tone: AppStatusTone.gray,
                    ),
                  },
                  onTap: kid.state == MeasureState.absent
                      ? null
                      : () => _open(kid),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Danh sách tự cập nhật sau mỗi lần lưu. Chạm một bé để nhập chiều cao, cân nặng.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
