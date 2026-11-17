import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Tiêu đề một phần của sổ kèm một câu giải thích.
class HealthSectionHeader extends StatelessWidget {
  const HealthSectionHeader({
    super.key,
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.space1),
          Text(
            caption,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Một ô số đo: nhãn, giá trị kèm đơn vị; dấu hiệu sinh tồn có thêm trạng thái.
@immutable
class HealthMetric {
  const HealthMetric(
    this.label,
    this.value, {
    this.status,
    this.abnormal = false,
  });

  final String label;
  final String value;
  final String? status;
  final bool abnormal;
}

/// Hàng ô số đo (chiều cao, cân nặng, BMI; nhiệt độ, mạch, nhịp thở); chữ lớn thì xếp dọc.
class HealthMetricRow extends StatelessWidget {
  const HealthMetricRow({super.key, required this.metrics});

  final List<HealthMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final tiles = [for (final metric in metrics) _MetricTile(metric: metric)];
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space2),
            tiles[i],
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.space2),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = metric.status;
    return Semantics(
      container: true,
      label: ['${metric.label}: ${metric.value}', ?status].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardGap),
          child: Column(
            children: [
              Text(
                metric.label,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                metric.value,
                textAlign: TextAlign.center,
                style:
                    (status == null
                            ? textTheme.headlineSmall
                            : textTheme.titleMedium)
                        ?.copyWith(color: AppColors.onBrand),
              ),
              if (status != null) ...[
                const SizedBox(height: AppSpacing.space1),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: metric.abnormal
                        ? AppColors.warningText
                        : AppColors.successText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
