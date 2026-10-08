import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';

/// Card chuẩn: màu, viền, bo góc lấy từ CardTheme; có `onTap` thì có hiệu ứng nhấn.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Semantics(
              button: true,
              label: semanticLabel,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}
