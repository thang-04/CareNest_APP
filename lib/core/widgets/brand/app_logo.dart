import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/asset_paths.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Logo CareNest đầy đủ; giữ tỷ lệ, không đổi màu/thêm bóng, chỉ trên nền sáng (DESIGN.md §3.1).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = AppSizes.logoFull});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logoFull,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'CareNest',
    );
  }
}
