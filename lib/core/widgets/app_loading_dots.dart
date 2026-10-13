import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';

/// Ba chấm primary/brand/accent nhảy lần lượt; không dùng spinner quay (DESIGN.md §5.5).
class AppLoadingDots extends StatefulWidget {
  const AppLoadingDots({super.key, this.size = 8});

  final double size;

  @override
  State<AppLoadingDots> createState() => _AppLoadingDotsState();
}

class _AppLoadingDotsState extends State<AppLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  static const _colors = [AppColors.primary, AppColors.brand, AppColors.accent];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : widget.size * 0.6),
                child: Transform.translate(
                  offset: Offset(0, -_lift(i) * widget.size * 0.6),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Mỗi chấm lệch pha 0,15 chu kỳ để nhảy lần lượt
  double _lift(int index) {
    final phase = (_controller.value - index * 0.15) % 1;
    return phase < 0.5
        ? Curves.easeInOut.transform(phase * 2) * (1 - phase * 2) * 2
        : 0;
  }
}
