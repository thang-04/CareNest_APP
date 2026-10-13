import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_card.dart';

/// Khối chờ đúng hình nội dung, nhịp thở 0,6↔1 (DESIGN.md §5.5).
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.pill,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
    lowerBound: 0.6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.track,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Card chờ: ô icon + tiêu đề + vài dòng.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    const widths = [0.92, 0.7, 0.8, 0.6];
    return Semantics(
      label: 'Đang tải',
      child: AppCard(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppSkeleton(width: 40, height: 40),
                  SizedBox(width: AppSpacing.space3),
                  AppSkeleton(width: 140, height: 16),
                ],
              ),
              for (var i = 0; i < lines; i++) ...[
                const SizedBox(height: AppSpacing.space3),
                AppSkeleton(
                  width: constraints.maxWidth * widths[i % widths.length],
                  height: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Danh sách chờ: dòng avatar + hai dòng chữ + khối bên phải.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải',
      child: AppCard(
        flush: true,
        child: Column(
          children: [
            for (var i = 0; i < rows; i++) ...[
              if (i > 0) const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                child: Row(
                  children: [
                    AppSkeleton(width: 40, height: 40),
                    SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: 0.6,
                            child: AppSkeleton(height: 14),
                          ),
                          SizedBox(height: AppSpacing.space2),
                          FractionallySizedBox(
                            widthFactor: 0.35,
                            child: AppSkeleton(height: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.space3),
                    AppSkeleton(width: 96, height: 32),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
