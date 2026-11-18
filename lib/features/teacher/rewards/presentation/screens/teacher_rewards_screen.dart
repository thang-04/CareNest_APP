import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/rewards/data/fake_teacher_reward_source.dart';
import 'package:carenest_app/features/teacher/rewards/domain/teacher_rewards.dart';

enum _RewardView { tickets, proposals }

class TeacherRewardsScreen extends StatefulWidget {
  const TeacherRewardsScreen({
    super.key,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final String classId;
  final TeacherRewardSource? source;

  @override
  State<TeacherRewardsScreen> createState() => _TeacherRewardsScreenState();
}

class _TeacherRewardsScreenState extends State<TeacherRewardsScreen> {
  late final TeacherRewardSource _source =
      widget.source ?? FakeTeacherRewardSource.shared;
  late Future<TeacherRewards> _data = _source.load(widget.classId);
  _RewardView _view = _RewardView.tickets;

  void _retry() => setState(() => _data = _source.load(widget.classId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khen thưởng')),
      body: FutureBuilder<TeacherRewards>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được khen thưởng',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: _retry,
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 5),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppSegmented<_RewardView>(
                segments: const [
                  (_RewardView.tickets, 'Phiếu bé ngoan'),
                  (_RewardView.proposals, 'Đề xuất'),
                ],
                selected: _view,
                onChanged: (value) => setState(() => _view = value),
              ),
              const SizedBox(height: AppSpacing.space3),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: [
                  Text(
                    '${data.className} · ${data.schoolYearLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // Trạng thái theo cả danh sách lớp (BE RewardClassDetail.status)
                  AppStatusBadge(
                    label: data.status?.label ?? 'Chưa lập',
                    tone: _statusTone(data.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              if (_view == _RewardView.tickets)
                ..._tickets(data.children)
              else
                ..._proposals(data.children),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _tickets(List<TeacherRewardChild> children) {
    final weekly = children.fold(0, (sum, child) => sum + child.weeklyTickets);
    final monthly = children.fold(
      0,
      (sum, child) => sum + child.monthlyTickets,
    );
    return [
      AppStatRow(
        tiles: [
          AppStatTile(
            value: '$weekly',
            label: 'Phiếu tuần',
            tone: AppStatusTone.blue,
          ),
          AppStatTile(
            value: '$monthly',
            label: 'Phiếu tháng',
            tone: AppStatusTone.green,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space3),
      for (final child in children) ...[
        AppCard(
          flush: true,
          child: AppListRow(
            leading: AppAvatar(name: child.fullName),
            title: child.fullName,
            subtitle: Text(
              '${child.weeklyTickets} tuần · ${child.monthlyTickets} tháng',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }

  List<Widget> _proposals(List<TeacherRewardChild> children) => [
    for (final child in children) ...[
      AppCard(
        flush: true,
        child: AppListRow(
          leading: AppAvatar(name: child.fullName),
          title: child.fullName,
          subtitle: Text(_proposalLine(child)),
        ),
      ),
      const SizedBox(height: AppSpacing.space2),
    ],
  ];

  /// "Có mặt 152/160 · Bé chăm ngoan"; chưa chọn ⇒ danh hiệu gợi ý kèm chữ "gợi ý" (OBS-14).
  static String _proposalLine(TeacherRewardChild child) {
    final attendance = 'Có mặt ${child.presentDays}/${child.schoolDays}';
    if (child.titles.isNotEmpty) {
      return '$attendance · ${child.titles.join(' · ')}';
    }
    if (child.suggested.isNotEmpty) {
      return '$attendance · ${child.suggested.join(' · ')} (gợi ý)';
    }
    return '$attendance · Chưa có danh hiệu';
  }

  static AppStatusTone _statusTone(RewardStatus? status) => switch (status) {
    null => AppStatusTone.gray,
    RewardStatus.draft => AppStatusTone.gray,
    RewardStatus.pendingVp ||
    RewardStatus.pendingPrincipal => AppStatusTone.approval,
    RewardStatus.approved => AppStatusTone.green,
    RewardStatus.returned => AppStatusTone.orange,
  };
}
