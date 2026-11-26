import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/teacher/health_measure/domain/health_measure.dart';

/// Cân đo — danh sách bé của kỳ cân đo đang mở; GV nhập số đo lớp mình (HLT-09).
/// Không có kỳ đang mở ⇒ chỉ xem ("Chưa mở kỳ cân đo"), không nhập. Phía dưới: các đợt khám (chỉ xem).
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
  List<HealthCampaign>? _campaigns;
  Object? _error;
  String _query = '';
  String? _lastSaved;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final month = await _source.loadMonth(widget.classId);
      if (mounted) setState(() => _month = month);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
    // Danh sách đợt khám chỉ là phần phụ: lỗi ⇒ ẩn mục, không chặn màn
    try {
      final campaigns = await _source.loadCampaigns();
      if (mounted) setState(() => _campaigns = campaigns);
    } catch (_) {
      if (mounted) setState(() => _campaigns = const []);
    }
  }

  Future<void> _open(MeasureKid kid) async {
    await widget.onOpenKid(kid.childId);
    if (!mounted) return;
    await _load();
    final updated = _month?.kids
        .where((k) => k.childId == kid.childId)
        .firstOrNull;
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
        title: Text(
          month?.title.isNotEmpty == true
              ? month!.title
              : 'Cân nặng & chiều cao',
        ),
        actions: [
          if (month != null && month.isOpen)
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
          if (_error != null)
            AppErrorState(
              title: 'Chưa tải được kỳ cân đo',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: _load,
            )
          else if (month == null)
            const AppSkeletonList(rows: 5)
          else ...[
            ..._kidsBody(month, measured, total),
            ..._campaignSection(),
          ],
        ],
      ),
    );
  }

  List<Widget> _kidsBody(MeasureMonth month, int measured, int total) {
    final textTheme = Theme.of(context).textTheme;
    final campaign = month.campaign;
    final open = month.isOpen;
    final kids = month.kids.where((k) => matchesSearch(k.fullName, _query));
    return [
      if (campaign != null) ...[
        AppBanner(
          icon: AppIcons.info,
          message: [
            campaign.kindLabel,
            campaign.dateRange,
            campaign.campusName,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        const SizedBox(height: AppSpacing.space3),
      ] else ...[
        const AppBanner(
          icon: AppIcons.info,
          message: 'Chưa mở kỳ cân đo. Bạn chỉ xem được số đo, chưa nhập được.',
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      if (open) ...[
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
      ],
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
      if (month.kids.isEmpty || kids.isEmpty)
        const AppEmptyState(
          icon: AppIcons.searchOff,
          title: 'Không có bé nào',
          message: 'Chưa có bé nào khớp trong lớp.',
        ),
      for (final kid in kids) ...[
        AppCard(
          flush: true,
          child: AppListRow(
            leading: AppAvatar(name: kid.fullName),
            title: kid.fullName,
            subtitle: Text(switch (kid.state) {
              MeasureState.measured =>
                '${kid.height} cm · ${kid.weight} kg · ${kid.measuredWhen}'
                    '${kid.result == null || kid.result!.detail.isEmpty ? '' : ' · ${kid.result!.detail}'}',
              MeasureState.pending =>
                kid.previous == null
                    ? 'Chưa có số đo'
                    : 'Lần trước ${kid.previous}',
              MeasureState.absent => 'Vắng hôm nay · đo bổ sung',
            }),
            trailing: switch (kid.state) {
              MeasureState.measured => AppStatusBadge(
                label: kid.result?.label ?? 'Đã đo',
                tone: kid.result?.tone ?? AppStatusTone.green,
              ),
              MeasureState.pending => const AppStatusBadge(
                label: 'Chưa đo',
                tone: AppStatusTone.orange,
              ),
              MeasureState.absent => const AppStatusBadge(
                label: 'Vắng',
                tone: AppStatusTone.gray,
              ),
            },
            // Chỉ nhập khi có kỳ đang mở; bé vắng không mở như demo
            onTap: open && kid.state != MeasureState.absent
                ? () => _open(kid)
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
      const SizedBox(height: AppSpacing.space2),
      Text(
        open
            ? 'Danh sách tự cập nhật sau mỗi lần lưu. Chạm một bé để nhập chiều cao, cân nặng.'
            : 'Khi nhà trường mở kỳ cân đo, bạn nhập chiều cao, cân nặng của bé ở đây.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
    ];
  }

  List<Widget> _campaignSection() {
    final campaigns = _campaigns;
    if (campaigns == null || campaigns.isEmpty) return const [];
    final textTheme = Theme.of(context).textTheme;
    return [
      const SizedBox(height: AppSpacing.sectionGap),
      Semantics(
        header: true,
        child: Text('Đợt khám và kỳ cân đo', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      AppCard(
        flush: true,
        child: AppDividedColumn(
          children: [
            for (final c in campaigns)
              AppListRow(
                title: c.name,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        c.kindLabel,
                        c.campusName,
                        c.dateRange,
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                    Text(
                      c.total == 0
                          ? 'Đã nhập kết quả: —'
                          : 'Đã nhập kết quả: ${c.recorded}/${c.total}',
                    ),
                    if (c.warningLabel != null) Text(c.warningLabel!),
                  ],
                ),
                trailing: AppStatusBadge(
                  label: c.statusLabel,
                  tone: c.statusTone,
                ),
              ),
          ],
        ),
      ),
    ];
  }
}
