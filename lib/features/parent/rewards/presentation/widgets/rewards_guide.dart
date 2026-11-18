import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';
import 'package:carenest_app/features/parent/rewards/presentation/rewards_status.dart';

/// Sheet "Cách bé nhận khen thưởng": 4 bậc theo OBS-10, OBS-14; ngưỡng do BE trả.
Future<void> showRewardsGuide(BuildContext context, RewardRules rules) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'Cách bé nhận khen thưởng',
    builder: (sheetContext) => RewardsGuide(
      rules: rules,
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class RewardsGuide extends StatelessWidget {
  const RewardsGuide({super.key, required this.rules, required this.onClose});

  final RewardRules rules;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    const weekly = RewardsStatus.weeklyTicket;
    const monthly = RewardsStatus.monthlyTicket;
    final steps = [
      (
        AppIcons.flag,
        'Cờ bé ngoan · mỗi ngày',
        'Ngày bé đi học, cô cắm cờ khi bé ngoan. Mỗi ngày tối đa 1 cờ.',
      ),
      (
        AppIcons.ticket,
        'Phiếu $weekly · mỗi tuần',
        'Bé có từ ${rules.weekMinFlags} cờ trong tuần được cô xét phiếu '
            'khi hết tuần.',
      ),
      (
        AppIcons.medal,
        'Phiếu $monthly · mỗi tháng',
        'Bé có từ ${rules.monthMinWeeklyTickets} phiếu $weekly trong tháng '
            'được cô xét phiếu khi hết tháng.',
      ),
      (
        AppIcons.trophy,
        'Danh hiệu cuối năm',
        'Cô đề xuất, nhà trường xét. Danh hiệu hiện ở mục Cuối năm sau khi '
            'Hiệu trưởng duyệt.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconTile(icon: steps[i].$1, tone: RewardsStatus.earned),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(steps[i].$2, style: textTheme.titleSmall),
                    Text(steps[i].$3, style: secondary),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPaddingDense,
            vertical: AppSpacing.cardGap,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            'Phiếu hiện ngay khi cô phát và không bị thu hồi.',
            style: secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        AppButton(label: 'Đã hiểu', onPressed: onClose, expand: true),
      ],
    );
  }
}
