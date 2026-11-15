import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/my_child/domain/my_child.dart';

/// Nhãn đánh giá hằng ngày; tông theo tiêu chí, nghĩa nằm ở chữ (không chỉ màu).
class ReviewTagWrap extends StatelessWidget {
  const ReviewTagWrap({super.key, required this.tags});

  final List<ReviewTag> tags;

  static AppStatusTone toneOf(ReviewCriterion criterion) => switch (criterion) {
    // Không dùng tông blue: badge blue không icon tự có chấm, lệch với các nhãn khác
    ReviewCriterion.health ||
    ReviewCriterion.emotion ||
    ReviewCriterion.behavior => AppStatusTone.green,
    ReviewCriterion.learning => AppStatusTone.teal,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: [
        for (final tag in tags)
          AppStatusBadge(label: tag.label, tone: toneOf(tag.criterion)),
      ],
    );
  }
}

/// Biểu đồ đường một màu `primary` (DESIGN.md §8.5 Sức khỏe), tự vẽ vì chưa chọn thư viện chart.
/// Chỉ vẽ số BE trả; không tô vùng "chuẩn" khi chưa chốt ngưỡng (HLT-03, P-13).
class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({super.key, required this.points});

  final List<WeightPoint> points;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final summary = points
        .map((point) => '${point.monthLabel}: ${_kg(point.kg)} kg')
        .join(', ');
    return Semantics(
      container: true,
      label: 'Cân nặng các tháng: $summary',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _WeightPainter(
                points: points,
                lastLabel: _kg(points.last.kg),
                labelStyle: textTheme.labelMedium!.copyWith(
                  color: AppColors.primary,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              for (final point in points)
                Expanded(
                  child: Text(
                    point.monthLabel,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _kg(double kg) => kg.toStringAsFixed(1).replaceAll('.', ',');
}

class _WeightPainter extends CustomPainter {
  _WeightPainter({
    required this.points,
    required this.lastLabel,
    required this.labelStyle,
  });

  final List<WeightPoint> points;
  final String lastLabel;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final values = points.map((point) => point.kg);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min) == 0 ? 1.0 : max - min;
    // Mỗi điểm nằm giữa cột nhãn tháng tương ứng bên dưới
    final step = size.width / points.length;
    final top = 24.0;
    final bottom = size.height - 12;
    final offsets = [
      for (var i = 0; i < points.length; i++)
        Offset(
          step * i + step / 2,
          bottom - (points[i].kg - min) / span * (bottom - top),
        ),
    ];
    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..addPolygon(offsets, false), line);
    final dot = Paint()..color = AppColors.primary;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 4, dot);
    }
    final painter = TextPainter(
      text: TextSpan(text: lastLabel, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      offsets.last - Offset(painter.width / 2, painter.height + 6),
    );
  }

  @override
  bool shouldRepaint(_WeightPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lastLabel != lastLabel;
}

/// Dòng nhãn – giá trị trong card thông tin (hồ sơ bé, ngày điểm danh).
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space1),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          children: [
            TextSpan(
              text: value,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
