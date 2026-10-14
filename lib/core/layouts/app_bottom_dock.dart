import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Vùng hành động nổi ở đáy, cách mép 12, bo 28, tránh home indicator (DESIGN.md §8.1).
class AppBottomDock extends StatelessWidget {
  const AppBottomDock({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSizes.floatingBarInset,
        0,
        AppSizes.floatingBarInset,
        AppSizes.floatingBarInset,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.surface.withValues(alpha: 0.85)),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space3,
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
      ),
    );
  }
}
