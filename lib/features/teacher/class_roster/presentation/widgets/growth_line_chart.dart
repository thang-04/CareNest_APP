import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';

/// Một điểm của biểu đồ: ngày đo và giá trị BE trả.
typedef ChartPoint = (DateTime, double);

String formatMeasure(double value) => value
    .toStringAsFixed(1)
    .replaceAll('.', ',')
    .replaceFirst(RegExp(r',0$'), '');

/// Biểu đồ đường vẽ bằng CustomPaint (không thêm thư viện). Điểm cũ nhất bên trái; chỉ vẽ số đo,
/// không đánh giá. Nhãn trục là Text thường để chữ theo cỡ chữ hệ thống.
class GrowthLineChart extends StatelessWidget {
  const GrowthLineChart({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
    required this.color,
  });

  final String title;
  final String unit;

  /// Cũ nhất trước.
  final List<ChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final values = [for (final p in points) p.$2];
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final latest = points.last;
    final muted = textTheme.labelMedium?.copyWith(color: AppColors.textMuted);
    return Semantics(
      container: true,
      label:
          '$title ($unit): ${points.length} lần đo, từ ${DateLabels.date(points.first.$1)} '
          'đến ${DateLabels.date(latest.$1)}, lần gần nhất ${formatMeasure(latest.$2)} $unit',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('$title ($unit)', style: textTheme.titleSmall),
              ),
              Text(
                '${formatMeasure(latest.$2)} $unit',
                style: textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          AspectRatio(
            aspectRatio: 2.6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatMeasure(maxV), style: muted),
                    Text(formatMeasure(minV), style: muted),
                  ],
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: CustomPaint(
                    painter: _LinePainter(
                      points: points,
                      minV: minV,
                      maxV: maxV,
                      color: color,
                      grid: AppColors.border,
                      surface: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateLabels.date(points.first.$1), style: muted),
              if (points.length > 1)
                Text(DateLabels.date(points.last.$1), style: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.minV,
    required this.maxV,
    required this.color,
    required this.grid,
    required this.surface,
  });

  final List<ChartPoint> points;
  final double minV;
  final double maxV;
  final Color color;
  final Color grid;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = pad + (size.height - 2 * pad) * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final first = points.first.$1.millisecondsSinceEpoch;
    final span = points.last.$1.millisecondsSinceEpoch - first;
    final range = maxV - minV;
    Offset at(ChartPoint p) {
      final x = points.length == 1 || span == 0
          ? size.width / 2
          : pad +
                (size.width - 2 * pad) *
                    (p.$1.millisecondsSinceEpoch - first) /
                    span;
      final y = range == 0
          ? size.height / 2
          : pad + (size.height - 2 * pad) * (1 - (p.$2 - minV) / range);
      return Offset(x, y);
    }

    final path = Path();
    for (final (i, p) in points.indexed) {
      final o = at(p);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in points) {
      final o = at(p);
      canvas.drawCircle(o, 5, Paint()..color = surface);
      canvas.drawCircle(
        o,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.color != color;
}
