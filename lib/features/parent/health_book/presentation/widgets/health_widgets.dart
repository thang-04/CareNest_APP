import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';

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
    this.unit,
    this.status,
    this.abnormal = false,
  });

  final String label;
  final String value;

  /// Đơn vị dài ("lần/phút") hiện riêng một dòng dưới số để ô hẹp không bẻ đôi chữ
  final String? unit;
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
    final unit = metric.unit;
    final reading = unit == null ? metric.value : '${metric.value} $unit';
    return Semantics(
      container: true,
      label: ['${metric.label}: $reading', ?status].join(', '),
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
              if (unit != null)
                Text(
                  unit,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
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

/// Dòng nhãn – giá trị của phiếu khám; giá trị bất thường hiện thành nhãn cam.
class HealthDetailRow extends StatelessWidget {
  const HealthDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.abnormal = false,
  });

  final String label;
  final String value;
  final bool abnormal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.space2),
        // Giá trị canh phải, dài tối đa nửa dòng; nhãn lấy phần còn lại
        LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: abnormal ? textTheme.titleSmall : textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: abnormal
                    ? AppStatusBadge(label: value, tone: AppStatusTone.orange)
                    : Text(
                        value,
                        textAlign: TextAlign.end,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    );
  }
}

/// Thẻ một phần của phiếu khám: tiêu đề và nội dung.
class HealthDetailCard extends StatelessWidget {
  const HealthDetailCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.space1),
          ...children,
        ],
      ),
    );
  }
}
