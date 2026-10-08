import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';

/// Chữ thương hiệu: "Care" xanh đậm, "Nest" xanh trời (DESIGN.md §3). Màu cố định theo nhận diện.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 24});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: const [
          TextSpan(
            text: 'Care',
            style: TextStyle(color: AppColors.brandBlue700),
          ),
          TextSpan(
            text: 'Nest',
            style: TextStyle(color: AppColors.brandSky400),
          ),
        ],
      ),
      semanticsLabel: 'CareNest',
    );
  }
}
