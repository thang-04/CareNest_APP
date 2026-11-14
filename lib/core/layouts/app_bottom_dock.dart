import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Vùng hành động ở đáy: nền màn, nút rộng cách mép 16, tránh home indicator (Figma App, DESIGN.md §8.1).
class AppBottomDock extends StatelessWidget {
  const AppBottomDock({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSizes.floatingBarInset,
          AppSpacing.space3,
          AppSizes.floatingBarInset,
          AppSizes.floatingBarInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.space2),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
