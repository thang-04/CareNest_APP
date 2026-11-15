import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';

/// Một việc trong danh sách "Việc cần làm": ô icon + tên + mô tả + badge, cả card bấm được.
class AppTaskCard extends StatelessWidget {
  const AppTaskCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.tone,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Thường là `AppStatusBadge`.
  final Widget? trailing;
  final AppStatusTone? tone;

  /// Việc cần làm ngay ⇒ viền `primary`.
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      flush: true,
      borderColor: highlighted ? AppColors.primary : null,
      child: AppListRow(
        title: title,
        leading: AppIconTile(icon: icon, tone: tone),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
