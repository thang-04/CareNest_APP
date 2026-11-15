import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';

/// Phó HT · Đề xuất khen thưởng — mockup V12 (OBS-10 PROPOSED, tiêu chí P-11 PENDING).
/// "Hợp lệ" là kết quả BE; Phó HT gửi đề xuất hợp lệ cho Hiệu trưởng, trả lại đề xuất không hợp lệ.
class RewardProposalsScreen extends StatefulWidget {
  const RewardProposalsScreen({super.key, this.source});

  final RewardProposalSource? source;

  @override
  State<RewardProposalsScreen> createState() => _RewardProposalsScreenState();
}

class _RewardProposalsScreenState extends State<RewardProposalsScreen> {
  late final RewardProposalSource _source =
      widget.source ?? FakeRewardProposalSource.shared;
  late Future<List<RewardProposal>> _items = _source.load();
  RewardStage _tab = RewardStage.pending;

  /// Nút đang chạy: true = gửi HT, false = trả lại.
  bool? _busy;

  Future<void> _run({required bool send}) async {
    setState(() => _busy = send);
    try {
      await (send ? _source.sendValidToPrincipal() : _source.returnInvalid());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Chưa gửi được. Thử lại sau.')),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = null;
      _items = _source.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<List<RewardProposal>>(
      future: _items,
      builder: (context, snapshot) {
        final items = snapshot.data;
        int count(RewardStage stage) =>
            items?.where((item) => item.stage == stage).length ?? 0;
        final pending =
            items
                ?.where((item) => item.stage == RewardStage.pending)
                .toList() ??
            const <RewardProposal>[];
        final valid = pending.where((item) => item.isValid).length;
        final invalid = pending.length - valid;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đề xuất khen thưởng'),
                Text(
                  'Năm học ${_source.schoolYear} · từ giáo viên',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppSegmented<RewardStage>(
                segments: [
                  (
                    RewardStage.pending,
                    'Chờ xét (${count(RewardStage.pending)})',
                  ),
                  (RewardStage.sentToPrincipal, 'Đã gửi HT'),
                  (RewardStage.returned, 'Trả lại'),
                ],
                selected: _tab,
                onChanged: (value) => setState(() => _tab = value),
              ),
              const SizedBox(height: AppSpacing.space3),
              if (snapshot.hasError)
                AppErrorState(
                  title: 'Chưa tải được đề xuất',
                  message: 'Kiểm tra kết nối mạng rồi thử lại.',
                  onRetry: () => setState(() => _items = _source.load()),
                )
              else if (items == null)
                const AppSkeletonList(rows: 4)
              else
                ..._list(items.where((item) => item.stage == _tab).toList()),
              if (_tab == RewardStage.pending && pending.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                const AppBanner(
                  message:
                      'Đề xuất không hợp lệ được trả về giáo viên kèm lý do. Đề xuất hợp lệ gửi Hiệu trưởng phê duyệt.',
                ),
              ],
            ],
          ),
          bottomNavigationBar: _tab != RewardStage.pending || pending.isEmpty
              ? null
              : AppBottomDock(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Trả lại ($invalid)',
                            variant: AppButtonVariant.danger,
                            isLoading: _busy == false,
                            loadingLabel: 'Đang gửi',
                            expand: true,
                            onPressed: invalid == 0 || _busy != null
                                ? null
                                : () => _run(send: false),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: AppButton(
                            label: 'Gửi HT ($valid)',
                            isLoading: _busy == true,
                            loadingLabel: 'Đang gửi',
                            expand: true,
                            onPressed: valid == 0 || _busy != null
                                ? null
                                : () => _run(send: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  List<Widget> _list(List<RewardProposal> items) {
    if (items.isEmpty) {
      return [
        AppEmptyState(
          icon: AppIcons.trophy,
          title: switch (_tab) {
            RewardStage.pending => 'Không còn đề xuất chờ xét',
            RewardStage.sentToPrincipal =>
              'Chưa gửi đề xuất nào cho Hiệu trưởng',
            RewardStage.returned => 'Chưa trả lại đề xuất nào',
          },
          message: 'Đề xuất mới từ giáo viên sẽ hiện ở tab Chờ xét.',
        ),
      ];
    }
    return [
      for (final item in items) ...[
        RewardProposalCard(item: item),
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }
}

/// Thẻ một đề xuất; dùng lại ở Hiệu trưởng. Hợp lệ / không hợp lệ có chữ, không chỉ màu.
class RewardProposalCard extends StatelessWidget {
  const RewardProposalCard({super.key, required this.item});

  final RewardProposal item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final danger = status.feedbackOf(AppFeedback.danger);
    final validity = item.isValid ? 'Hợp lệ' : 'Không hợp lệ';
    final evidence = item.invalidReason == null
        ? item.evidence
        : '${item.evidence} – ${item.invalidReason}';
    return Semantics(
      container: true,
      label:
          '${item.childName}, ${item.className}, ${item.awardTitle}, $evidence, $validity',
      excludeSemantics: true,
      child: AppCard(
        dense: true,
        borderColor: item.isValid ? null : danger.border,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.trophy,
              size: AppSizes.iconTile,
              color: item.isValid
                  ? status.tone(AppStatusTone.orange).foreground
                  : danger.foreground,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.childName,
                          style: textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      AppStatusBadge(
                        label: validity,
                        tone: item.isValid
                            ? AppStatusTone.green
                            : AppStatusTone.red,
                      ),
                    ],
                  ),
                  Text(
                    '${item.className} · ${item.awardTitle}',
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    evidence,
                    style: textTheme.labelMedium?.copyWith(
                      color: item.isValid
                          ? AppColors.textMuted
                          : danger.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
