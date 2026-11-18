import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/health_book/presentation/health_labels.dart';

/// Biểu đồ đường một chỉ số (chiều cao hoặc cân nặng) theo thời gian thật: khoảng cách giữa
/// hai chấm đúng bằng khoảng cách ngày đo. Chấm đặc là kỳ cân đo, chấm rỗng là đợt khám.
/// Tự vẽ vì App chưa chọn thư viện chart; không tô vùng "chuẩn" khi chưa chốt ngưỡng.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
    required this.valueOf,
  }) : assert(points.length >= 2, 'Cần ít nhất 2 lần đo để vẽ');

  /// "Chiều cao"
  final String title;

  /// "cm"
  final String unit;

  /// Cũ trước mới sau
  final List<GrowthPoint> points;
  final double Function(GrowthPoint point) valueOf;

  /// "Năm 2026" khi mọi lần đo cùng năm, "2025 – 2026" khi trải nhiều năm.
  static String yearCaption(List<GrowthPoint> points) {
    final first = points.first.date.year;
    final last = points.last.date.year;
    return first == last ? 'Năm $first' : '$first – $last';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.labelMedium?.copyWith(color: AppColors.textMuted);
    final singleYear = points.first.date.year == points.last.date.year;
    final values = [for (final point in points) valueOf(point)];
    final summary = [
      for (var i = 0; i < points.length; i++)
        'tháng ${points[i].date.month}/${points[i].date.year}'
            '${points[i].fromExam ? ' khám' : ''} '
            '${HealthLabels.number(values[i])} $unit',
    ].join('; ');
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            children: [
              Text('$title ($unit)', style: textTheme.titleSmall),
              Text(yearCaption(points), style: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Semantics(
            container: true,
            label: '$title ${points.length} lần đo: $summary',
            excludeSemantics: true,
            child: SizedBox(
              height: AppSizes.chartHeight,
              child: CustomPaint(
                size: Size.infinite,
                painter: _GrowthPainter(
                  dates: [for (final point in points) point.date],
                  values: values,
                  fromExam: [for (final point in points) point.fromExam],
                  xLabels: [
                    for (final point in points)
                      singleYear
                          ? 'T${point.date.month}'
                          : '${point.date.month}/${point.date.year % 100}',
                  ],
                  axisStyle: muted!.copyWith(
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                  valueStyle: textTheme.labelLarge!.copyWith(
                    color: AppColors.primary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mốc trục tung "tròn" (bước 0,1 / 0,2 / 0,25 / 0,5 / 1 / 2 / 2,5 / 5 / 10…), khoảng 4 mốc.
List<double> growthTicks(double min, double max) {
  const steps = [0.1, 0.2, 0.25, 0.5, 1.0, 2.0, 2.5, 5.0, 10.0, 20.0, 50.0];
  final range = max - min == 0 ? 1.0 : max - min;
  final step = steps.firstWhere(
    (candidate) => candidate >= range / 3,
    orElse: () => steps.last,
  );
  final low = (min / step + 1e-9).floorToDouble();
  var high = (max / step - 1e-9).ceilToDouble();
  if (high <= low) high = low + 1;
  return [
    for (var i = low; i <= high; i++) (i * step * 100).roundToDouble() / 100,
  ];
}

class _GrowthPainter extends CustomPainter {
  _GrowthPainter({
    required this.dates,
    required this.values,
    required this.fromExam,
    required this.xLabels,
    required this.axisStyle,
    required this.valueStyle,
    required this.textScaler,
  });

  final List<DateTime> dates;
  final List<double> values;
  final List<bool> fromExam;
  final List<String> xLabels;
  final TextStyle axisStyle;
  final TextStyle valueStyle;
  final TextScaler textScaler;

  static const _dotRadius = 4.5;
  static const _lineWidth = 2.5;
  static const _gap = AppSpacing.space1;

  TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final ticks = growthTicks(values.reduce(math.min), values.reduce(math.max));
    final tickLabels = [
      for (final tick in ticks) _text(HealthLabels.number(tick), axisStyle),
    ];
    final xPainters = [for (final label in xLabels) _text(label, axisStyle)];
    final valueLabel = _text(HealthLabels.number(values.last), valueStyle);

    // Lề: trái chứa nhãn trục tung, trên chứa số đo mới nhất, dưới chứa nhãn tháng
    final left = tickLabels.map((p) => p.width).reduce(math.max) + _gap * 2;
    final right = size.width - _dotRadius;
    final top = valueLabel.height + _gap * 2;
    final bottom = size.height - xPainters.first.height - _gap * 2;
    if (bottom <= top || right <= left) return;

    final lowTick = ticks.first;
    final tickSpan = ticks.last - lowTick;
    double yOf(double value) =>
        bottom - (value - lowTick) / tickSpan * (bottom - top);

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < ticks.length; i++) {
      final y = yOf(ticks[i]);
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
      final label = tickLabels[i];
      label.paint(
        canvas,
        Offset(left - _gap * 2 - label.width, y - label.height / 2),
      );
    }

    final start = dates.first.millisecondsSinceEpoch;
    final timeSpan = dates.last.millisecondsSinceEpoch - start;
    final offsets = [
      for (var i = 0; i < dates.length; i++)
        Offset(
          timeSpan == 0
              ? (left + right) / 2
              : left +
                    (dates[i].millisecondsSinceEpoch - start) /
                        timeSpan *
                        (right - left),
          yOf(values[i]),
        ),
    ];

    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = _lineWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..addPolygon(offsets, false), line);
    final filled = Paint()..color = AppColors.primary;
    final hollow = Paint()..color = AppColors.surface;
    for (var i = 0; i < offsets.length; i++) {
      if (fromExam[i]) {
        canvas
          ..drawCircle(offsets[i], _dotRadius, hollow)
          ..drawCircle(offsets[i], _dotRadius, line);
      } else {
        canvas.drawCircle(offsets[i], _dotRadius, filled);
      }
    }

    // Số đo mới nhất nằm trên chấm cuối, không tràn mép phải
    final lastDot = offsets.last;
    valueLabel.paint(
      canvas,
      Offset(
        (lastDot.dx - valueLabel.width / 2).clamp(
          left,
          size.width - valueLabel.width,
        ),
        lastDot.dy - _dotRadius - _gap - valueLabel.height,
      ),
    );

    // Nhãn tháng: vẽ từ phải sang trái, bỏ nhãn chạm nhãn đã vẽ (luôn giữ lần đo mới nhất)
    var nextLeft = size.width + _gap;
    for (var i = offsets.length - 1; i >= 0; i--) {
      final label = xPainters[i];
      final x = (offsets[i].dx - label.width / 2).clamp(
        0.0,
        size.width - label.width,
      );
      if (x + label.width + _gap > nextLeft) continue;
      label.paint(canvas, Offset(x, size.height - label.height));
      nextLeft = x;
    }
  }

  @override
  bool shouldRepaint(_GrowthPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.dates != dates ||
      oldDelegate.axisStyle != axisStyle ||
      oldDelegate.valueStyle != valueStyle ||
      oldDelegate.textScaler != textScaler;
}

/// Chú thích: chấm đặc = kỳ cân đo, chấm rỗng = đợt khám sức khỏe.
class GrowthLegend extends StatelessWidget {
  const GrowthLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    Widget item({required bool hollow, required String label}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: AppSpacing.space3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hollow ? AppColors.surface : AppColors.primary,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        // Chữ lớn: nhãn xuống dòng thay vì tràn
        Flexible(child: Text(label, style: style)),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        spacing: AppSpacing.space4,
        runSpacing: AppSpacing.space2,
        children: [
          item(hollow: false, label: 'Kỳ cân đo'),
          item(hollow: true, label: 'Đợt khám sức khỏe'),
        ],
      ),
    );
  }
}
