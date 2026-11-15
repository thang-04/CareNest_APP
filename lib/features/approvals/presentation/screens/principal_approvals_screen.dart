import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_principal_reward_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_batch.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Hiệu trưởng · tab Duyệt — mockup H02: đợt khen thưởng Phó HT đã xét (OBS-10 PROPOSED)
/// và mục đã xử lý gần đây. Không có nghỉ phép nhân sự (ngoài phạm vi CareNest, plan K5).
class PrincipalApprovalsScreen extends StatefulWidget {
  const PrincipalApprovalsScreen({super.key, this.source});

  final PrincipalRewardSource? source;

  @override
  State<PrincipalApprovalsScreen> createState() =>
      _PrincipalApprovalsScreenState();
}

class _PrincipalApprovalsScreenState extends State<PrincipalApprovalsScreen> {
  late final PrincipalRewardSource _source =
      widget.source ?? FakePrincipalRewardSource.shared;
  late Future<List<RewardBatch>> _batches = _source.loadBatches();

  // Quay lại từ màn chi tiết ⇒ tải lại để đợt đã xử lý chuyển xuống mục dưới
  Future<void> _open(String id) async {
    await context.push<void>(RoutePaths.principalRewardBatch(id));
    if (mounted) setState(() => _batches = _source.loadBatches());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<RewardBatch>>(
        future: _batches,
        builder: (context, snapshot) {
          final batches = snapshot.data;
          final pending = batches
              ?.where((batch) => batch.status == RewardBatchStatus.pending)
              .toList();
          final done = batches
              ?.where((batch) => batch.status != RewardBatchStatus.pending)
              .toList();
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
                      'Chờ Hiệu trưởng duyệt',
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  if (pending != null && pending.isNotEmpty)
                    Text(
                      '${pending.length} mới',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              if (snapshot.hasError)
                AppErrorState(
                  title: 'Chưa tải được yêu cầu',
                  message: 'Kiểm tra kết nối mạng rồi thử lại.',
                  onRetry: () =>
                      setState(() => _batches = _source.loadBatches()),
                )
              else if (pending == null || done == null)
                const AppSkeletonList(rows: 3)
              else ...[
                if (pending.isEmpty)
                  const AppEmptyState(
                    icon: AppIcons.checkCircle,
                    title: 'Không còn yêu cầu chờ duyệt',
                    message: 'Đề xuất Phó HT gửi lên sẽ hiện ở đây.',
                  )
                else
                  for (final (i, batch) in pending.indexed) ...[
                    AppTaskCard(
                      icon: AppIcons.trophy,
                      title: '${batch.title} · ${batch.proposals.length} bé',
                      subtitle: '${batch.campusName} · Phó HT đã xét',
                      highlighted: i == 0,
                      trailing: const AppStatusBadge(
                        label: 'Khen thưởng',
                        tone: AppStatusTone.blue,
                      ),
                      onTap: () => _open(batch.id),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                  ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Semantics(
                    header: true,
                    child: Text(
                      'Đã xử lý gần đây',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  for (final batch in done) ...[
                    _DoneCard(batch: batch),
                    const SizedBox(height: AppSpacing.space2),
                  ],
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.batch});

  final RewardBatch batch;

  @override
  Widget build(BuildContext context) {
    final approved = batch.status == RewardBatchStatus.approved;
    return AppTaskCard(
      icon: approved ? AppIcons.checkCircle : AppIcons.close,
      tone: approved ? AppStatusTone.green : AppStatusTone.red,
      title: batch.title,
      subtitle: [batch.campusName, ?batch.decisionNote].join(' · '),
      trailing: AppStatusBadge(
        label: approved ? 'Đã duyệt' : 'Trả về',
        tone: approved ? AppStatusTone.green : AppStatusTone.red,
      ),
    );
  }
}
