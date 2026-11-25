import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/health_book/presentation/widgets/growth_chart.dart';
import 'package:carenest_app/features/parent/health_book/presentation/widgets/health_widgets.dart';

/// Khoảng thời gian của biểu đồ, tính lùi từ lần đo mới nhất.
enum TrendPeriod {
  sixMonths(6, '6 tháng'),
  twelveMonths(12, '12 tháng'),
  all(null, 'Toàn bộ');

  const TrendPeriod(this.months, this.label);

  final int? months;
  final String label;

  /// Các lần đo trong khoảng; [points] cũ trước mới sau.
  List<GrowthPoint> pick(List<GrowthPoint> points) {
    final months = this.months;
    if (months == null || points.isEmpty) return points;
    final latest = points.last.date;
    final from = DateTime(latest.year, latest.month - months, latest.day);
    return [
      for (final point in points)
        if (!point.date.isBefore(from)) point,
    ];
  }
}

/// Tab Xu hướng (canvas "Sổ sức khỏe", user 17/11 chốt): biểu đồ chiều cao và cân nặng theo
/// khoảng chọn, rồi nhận định AI đã được giáo viên chủ nhiệm duyệt.
class HealthTrendTab extends StatefulWidget {
  const HealthTrendTab({
    super.key,
    required this.growth,
    required this.interpretation,
  });

  /// Cũ trước mới sau
  final List<GrowthPoint> growth;
  final TrendInterpretation? interpretation;

  @override
  State<HealthTrendTab> createState() => _HealthTrendTabState();
}

class _HealthTrendTabState extends State<HealthTrendTab> {
  TrendPeriod _period = TrendPeriod.all;

  void _choose(TrendPeriod period) {
    setState(() {
      _period = period;
    });
  }

  @override
  Widget build(BuildContext context) {
    const header = HealthSectionHeader(
      title: 'Xu hướng sức khỏe',
      caption: 'Tính từ các lần cân đo và khám đã công bố.',
    );
    if (widget.growth.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SizedBox(height: AppSpacing.space3),
          AppEmptyState(
            icon: AppIcons.heart,
            title: 'Chưa có số đo để vẽ xu hướng',
            message:
                'Biểu đồ hiện sau khi cô giáo công bố ít nhất 2 lần cân đo hoặc khám.',
          ),
        ],
      );
    }
    final points = _period.pick(widget.growth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final period in TrendPeriod.values)
              AppFilterChip(
                label: period.label,
                selected: period == _period,
                onSelected: () => _choose(period),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        if (points.length < 2)
          AppBanner(
            kind: AppBannerKind.neutral,
            message: points.isEmpty
                ? 'Khoảng này chưa có lần đo nào. Hãy chọn khoảng dài hơn.'
                : 'Khoảng này chỉ có 1 lần đo. Cần ít nhất 2 lần đo để vẽ xu hướng, hãy chọn khoảng dài hơn.',
          )
        else ...[
          GrowthChart(
            title: 'Chiều cao',
            unit: 'cm',
            points: points,
            valueOf: (point) => point.heightCm,
          ),
          const SizedBox(height: AppSpacing.space3),
          GrowthChart(
            title: 'Cân nặng',
            unit: 'kg',
            points: points,
            valueOf: (point) => point.weightKg,
          ),
          const SizedBox(height: AppSpacing.space3),
          const GrowthLegend(),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        switch (widget.interpretation) {
          final interpretation? => _InterpretationCard(
            interpretation: interpretation,
          ),
          null => const AppBanner(
            kind: AppBannerKind.neutral,
            title: 'Chưa có nhận định xu hướng',
            message:
                'Cô giáo sẽ gửi nhận định khi đủ số đo. Biểu đồ vẫn cập nhật sau mỗi lần đo.',
          ),
        },
      ],
    );
  }
}

/// Nhận định đã duyệt: Tổng quan, Cần chú ý, Điểm tích cực, Lưu ý về dữ liệu (HLT-04/05/21).
class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard({required this.interpretation});

  final TrendInterpretation interpretation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    const gap = SizedBox(height: AppSpacing.space4);
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Nhận định xu hướng',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${interpretation.periodLabel} · duyệt ngày ${DateLabels.date(interpretation.approvedOn)}',
                      style: muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              const AppStatusBadge(
                label: 'Đã duyệt',
                tone: AppStatusTone.green,
              ),
            ],
          ),
          if (interpretation.stale) ...[
            const SizedBox(height: AppSpacing.space3),
            const AppBanner(
              kind: AppBannerKind.info,
              message:
                  'Đã có số đo mới sau lần nhận định này. Nội dung nhận định chưa tính các lần đo mới.',
            ),
          ],
          gap,
          _Part(
            title: 'Tổng quan',
            child: Text(interpretation.overview, style: textTheme.bodyLarge),
          ),
          if (interpretation.attention.isNotEmpty) ...[
            gap,
            _Part(
              title: 'Cần chú ý',
              titleColor: AppColors.warningText,
              child: _Bullets(
                items: interpretation.attention,
                color: AppColors.warning,
              ),
            ),
          ],
          if (interpretation.positives.isNotEmpty) ...[
            gap,
            _Part(
              title: 'Điểm tích cực',
              child: _Bullets(
                items: interpretation.positives,
                color: AppColors.success,
              ),
            ),
          ],
          if (interpretation.limitations case final limitations?) ...[
            gap,
            _Part(
              title: 'Lưu ý về dữ liệu',
              child: Text(limitations, style: textTheme.bodyLarge),
            ),
          ],
          gap,
          Text(
            'AI soạn từ số đo, giáo viên chủ nhiệm đọc và duyệt trước khi gửi. Chỉ để tham khảo, không thay thế chẩn đoán y tế.',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({required this.title, required this.child, this.titleColor});

  final String title;
  final Widget child;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: titleColor),
        ),
        const SizedBox(height: AppSpacing.space1),
        child,
      ],
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items, required this.color});

  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
          const SizedBox(height: AppSpacing.space1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  '•',
                  style: textTheme.bodyLarge?.copyWith(color: color),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(child: Text(item, style: textTheme.bodyLarge)),
            ],
          ),
        ],
      ],
    );
  }
}
