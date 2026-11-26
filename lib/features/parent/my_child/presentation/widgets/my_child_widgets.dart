import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Dòng nhãn – giá trị trong card thông tin (hồ sơ bé, ngày điểm danh).
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space1),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          children: [
            TextSpan(
              text: value,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
