import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/approvals/data/fake_meal_adjustment_source.dart';
import 'package:carenest_app/features/approvals/domain/meal_adjustment.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';
import 'package:carenest_app/routing/route_paths.dart';

enum _Filter { all, meals, rewards }

/// Phó HT · tab Duyệt — mockup V02: yêu cầu chờ duyệt trong cơ sở phụ trách (AUTH-02).
/// Điều chỉnh suất (NUT-03) và đề xuất khen thưởng (OBS-10 PROPOSED).
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key, this.mealSource, this.rewardSource});

  final MealAdjustmentSource? mealSource;
  final RewardProposalSource? rewardSource;

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  late final MealAdjustmentSource _meals =
      widget.mealSource ?? FakeMealAdjustmentSource.shared;
  late final RewardProposalSource _rewards =
      widget.rewardSource ?? FakeRewardProposalSource.shared;
  late Future<(List<MealAdjustment>, int)> _data = _load();
  _Filter _filter = _Filter.all;

  Future<(List<MealAdjustment>, int)> _load() async {
    final meals = await _meals.loadPending();
    final rewards = await _rewards.load();
    return (
      meals,
      rewards.where((item) => item.stage == RewardStage.pending).length,
    );
  }

  // Quay lại từ màn chi tiết ⇒ tải lại để yêu cầu đã xử lý biến khỏi danh sách
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) setState(() => _data = _load());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<(List<MealAdjustment>, int)>(
        future: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final newCount = data == null
              ? null
              : data.$1.length + (data.$2 > 0 ? 1 : 0);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.space2,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Yêu cầu chờ duyệt',
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  if (newCount != null && newCount > 0)
                    Text(
                      '$newCount mới',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
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
                  title: 'Chưa tải được yêu cầu',
                  message: 'Kiểm tra kết nối mạng rồi thử lại.',
                  onRetry: () => setState(() => _data = _load()),
                )
              else if (data == null)
                const AppSkeletonList(rows: 3)
              else
                ..._cards(data.$1, data.$2),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'Chạm một yêu cầu để xem chi tiết và Duyệt / Từ chối. Yêu cầu bị từ chối được trả về người gửi kèm lý do.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _cards(List<MealAdjustment> meals, int pendingRewards) {
    final cards = <Widget>[
      if (_filter != _Filter.rewards)
        for (final (i, item) in meals.indexed)
          AppTaskCard(
            icon: AppIcons.meal,
            title: 'Điều chỉnh suất · ${item.className}',
            subtitle: '${item.deltaLabel} · ${item.summary}',
            highlighted: i == 0,
            trailing: const AppStatusBadge(
              label: 'Suất ăn',
              tone: AppStatusTone.blue,
            ),
            onTap: () => _open(RoutePaths.vicePrincipalAdjustment(item.id)),
          ),
      if (_filter != _Filter.meals && pendingRewards > 0)
        AppTaskCard(
          icon: AppIcons.trophy,
          title: 'Đề xuất khen thưởng',
          subtitle: '$pendingRewards đề xuất từ giáo viên',
          trailing: const AppStatusBadge(
            label: 'Khen thưởng',
            tone: AppStatusTone.approval,
          ),
          onTap: () => _open(RoutePaths.vicePrincipalRewards),
        ),
    ];
    if (cards.isEmpty) {
      return const [
        AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không còn yêu cầu chờ duyệt',
          message: 'Yêu cầu mới từ giáo viên sẽ hiện ở đây.',
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
