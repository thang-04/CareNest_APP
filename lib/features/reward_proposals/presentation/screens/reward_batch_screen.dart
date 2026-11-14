import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_principal_reward_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_batch.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';

/// Hiệu trưởng · Khen thưởng cuối năm — H04, chỉ xem (AUTH-21, BE ADR-0026; OBS-14).
/// Danh sách đề xuất Phó HT đã xét và trạng thái đợt; duyệt / trả về Phó HT thực hiện trên CareNest Web.
class RewardBatchScreen extends StatefulWidget {
  const RewardBatchScreen({super.key, required this.id, this.source});

  final String id;
  final PrincipalRewardSource? source;

  @override
  State<RewardBatchScreen> createState() => _RewardBatchScreenState();
}

class _RewardBatchScreenState extends State<RewardBatchScreen> {
  static const _collapsedCount = 5;

  late final PrincipalRewardSource _source =
      widget.source ?? FakePrincipalRewardSource.shared;
  late Future<RewardBatch?> _batch = _source.loadBatch(widget.id);
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<RewardBatch?>(
      future: _batch,
      builder: (context, snapshot) {
        final batch = snapshot.data;
        final pending = batch?.status == RewardBatchStatus.pending;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch?.title ?? 'Khen thưởng'),
                if (batch != null)
                  Text(
                    '${batch.campusName} · ${batch.proposals.length} đề xuất hợp lệ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true) => Center(
              child: AppErrorState(
                title: 'Chưa tải được đề xuất',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () =>
                    setState(() => _batch = _source.loadBatch(widget.id)),
              ),
            ),
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: AppSkeletonList(rows: 5),
              ),
            _ when batch == null => const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không tìm thấy đợt đề xuất',
                message: 'Đợt này không còn hoặc đã được xử lý ở nơi khác.',
              ),
            ),
            _ => _body(context, batch, pending),
          },
        );
      },
    );
  }

  Widget _body(BuildContext context, RewardBatch batch, bool pending) {
    final textTheme = Theme.of(context).textTheme;
    final shown = _expanded || batch.proposals.length <= _collapsedCount
        ? batch.proposals
        : batch.proposals.take(_collapsedCount).toList();
    final hidden = batch.proposals.length - shown.length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppBanner(
          kind: pending ? AppBannerKind.success : AppBannerKind.neutral,
          icon: pending ? AppIcons.checkCircle : null,
          message: pending
              ? '${batch.reviewNote} Chỉ xem — Hiệu trưởng duyệt trên CareNest Web.'
              : batch.decisionNote ?? 'Đợt này đã được xử lý.',
        ),
        const SizedBox(height: AppSpacing.space3),
        for (final item in shown) ...[
          _ProposalTile(item: item),
          const SizedBox(height: AppSpacing.space2),
        ],
        if (hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space1,
                ),
              ),
              child: Text.rich(
                TextSpan(
                  text: '+ $hidden đề xuất khác · ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  children: [
                    TextSpan(
                      text: 'Xem tất cả',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (batch.proposals.isEmpty)
          Text(
            'Đợt này không còn đề xuất để xem trên app.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}

class _ProposalTile extends StatelessWidget {
  const _ProposalTile({required this.item});

  final RewardProposal item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final award = AppStatusColors.of(context).tone(AppStatusTone.orange);
    return AppCard(
      dense: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: item.childName,
                    children: [
                      TextSpan(
                        text: ' · ${item.className}',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  style: textTheme.titleSmall,
                ),
                Text(item.awardTitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Icon(
            AppIcons.trophy,
            size: AppSizes.iconTile,
            color: award.foreground,
          ),
        ],
      ),
    );
  }
}
