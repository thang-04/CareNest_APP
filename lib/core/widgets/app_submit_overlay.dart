import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_loading_dots.dart';

/// Phủ trắng khi đang gửi form, giữ form bên dưới (DESIGN.md §7.1).
class AppSubmitOverlay extends StatelessWidget {
  const AppSubmitOverlay({super.key, this.label = 'Đang gửi…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xEBFFFFFF),
        child: Semantics(
          liveRegion: true,
          label: label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLoadingDots(),
              const SizedBox(height: AppSpacing.space4),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
