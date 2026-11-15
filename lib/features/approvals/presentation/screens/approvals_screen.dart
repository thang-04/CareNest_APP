import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/approvals/presentation/widgets/approvals_header.dart';
import 'package:carenest_app/features/meal_count_confirm/data/fake_meal_count_confirm_source.dart';
import 'package:carenest_app/features/meal_count_confirm/domain/meal_count_draft.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';
import 'package:carenest_app/routing/route_paths.dart';

enum _Filter { all, meals, rewards }

/// Phó HT · tab Chờ xử lý — Figma PHT 02, chỉ xem (AUTH-21, BE ADR-0026): việc chờ PHT xử lý trên Web trong
/// cơ sở phụ trách (AUTH-02) — số suất chưa xác nhận (NUT-02), đề xuất khen thưởng chờ xét (OBS-14).
/// Không còn điều chỉnh suất chờ duyệt (NUT-04).
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key, this.mealSource, this.rewardSource});

  final MealCountConfirmSource? mealSource;
  final RewardProposalSource? rewardSource;

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  late final MealCountConfirmSource _meals =
      widget.mealSource ?? FakeMealCountConfirmSource.shared;
  late final RewardProposalSource _rewards =
      widget.rewardSource ?? FakeRewardProposalSource.shared;
  late Future<(MealCountDraft, int)> _data = _load();
  _Filter _filter = _Filter.all;

  Future<(MealCountDraft, int)> _load() async {
    final meals = await _meals.loadToday();
    final rewards = await _rewards.load();
    return (
      meals,
      rewards.where((item) => item.stage == RewardStage.pending).length,
    );
  }

  // Quay lại từ màn xem ⇒ tải lại theo số BE mới nhất
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) setState(() => _data = _load());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<(MealCountDraft, int)>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final newCount = data == null
            ? null
            : (data.$1.confirmed ? 0 : 1) + (data.$2 > 0 ? 1 : 0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApprovalsHeader(
              count: newCount,
              homePath: RoutePaths.vicePrincipalHome,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  AppSegmented<_Filter>(
                    segments: const [
                      (_Filter.all, 'Tất cả'),
                      (_Filter.meals, 'Suất ăn'),
                      (_Filter.rewards, 'Khen thưởng'),
                    ],
                    selected: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  if (snapshot.hasError)
                    AppErrorState(
                      title: 'Chưa tải được việc chờ xử lý',
                      message: 'Kiểm tra kết nối mạng rồi thử lại.',
                      onRetry: () => setState(() => _data = _load()),
                    )
                  else if (data == null)
                    const AppSkeletonList(rows: 3)
                  else
                    ..._cards(data.$1, data.$2),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    'Chỉ xem. Xác nhận số suất và xét đề xuất khen thưởng thực hiện trên CareNest Web.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _cards(MealCountDraft meals, int pendingRewards) {
    final showMeals = _filter != _Filter.rewards && !meals.confirmed;
    final showRewards = _filter != _Filter.meals && pendingRewards > 0;
    final cards = <Widget>[
      if (showMeals)
        AppTaskCard(
          icon: AppIcons.meal,
          title: 'Số suất chưa xác nhận',
          subtitle:
              '${meals.mealLabel} ${meals.total} suất · hạn ${DateLabels.time24(meals.deadline)}',
          // Số suất có hạn chốt trong ngày ⇒ viền nhấn như Figma
          highlighted: true,
          trailing: const AppStatusBadge(
            label: 'Suất ăn',
            tone: AppStatusTone.blue,
          ),
          onTap: () => _open(RoutePaths.vicePrincipalMealConfirm),
        ),
      if (showRewards)
        AppTaskCard(
          icon: AppIcons.trophy,
          title: 'Đề xuất khen thưởng',
          subtitle: '$pendingRewards đề xuất từ giáo viên chờ xét',
          trailing: const AppStatusBadge(
            label: 'Khen thưởng',
            tone: AppStatusTone.blue,
          ),
          onTap: () => _open(RoutePaths.vicePrincipalRewards),
        ),
    ];
    if (cards.isEmpty) {
      return const [
        AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không có việc chờ xử lý',
          message: 'Số suất cần xác nhận và đề xuất khen thưởng sẽ hiện ở đây.',
        ),
      ];
    }
    return [
      for (final card in cards) ...[
        card,
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }
}
