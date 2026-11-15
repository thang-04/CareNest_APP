import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/meal_count_confirm/data/fake_meal_count_confirm_source.dart';
import 'package:carenest_app/features/meal_count_confirm/domain/meal_count_draft.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';
import 'package:carenest_app/features/vice_principal_home/domain/campus_today.dart';

/// Dữ liệu giả mockup V01 — cơ sở chính 12/10: 196 trẻ, 182 có mặt (khớp K03), 9 có phép, 5 vắng.
/// Việc chờ xử lý và mốc "Chốt suất" đọc từ các nguồn giả dùng chung; PHT chỉ xem, xử lý trên Web.
class FakeCampusTodaySource implements CampusTodaySource {
  FakeCampusTodaySource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
    RewardProposalSource? rewards,
    MealCountConfirmSource? mealCount,
  }) : _rewards = rewards ?? FakeRewardProposalSource.shared,
       _mealCount = mealCount ?? FakeMealCountConfirmSource.shared;

  final FakeMode mode;
  final Duration delay;
  final RewardProposalSource _rewards;
  final MealCountConfirmSource _mealCount;

  @override
  Future<CampusToday> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final rewards = (await _rewards.load())
        .where((item) => item.stage == RewardStage.pending)
        .length;
    final draft = await _mealCount.loadToday();
    final children = FakeCampusChildrenSource.children;
    final special = children.where((child) => child.tag != null).length;
    final pending = (draft.confirmed ? 0 : 1) + (rewards > 0 ? 1 : 0);
    final day = FakeParentHomeSource.today;
    final confirmed = draft.confirmedAt;
    return CampusToday(
      staffName: 'Lê Văn Bình',
      campusName: 'Cơ sở chính – Thượng Hồng',
      date: day,
      classCount: 6,
      enrolled: children.length,
      present: 182,
      excused: 9,
      absent: 5,
      pendingCount: mode == FakeMode.empty ? 0 : pending,
      morning: [
        MorningStep(
          kind: MorningStepKind.attendanceLock,
          time: day.add(const Duration(hours: 8)),
          title: 'Khoá điểm danh',
          note: '6/6 lớp đã điểm danh · 182/${children.length} bé có mặt',
          state: MorningStepState.done,
        ),
        MorningStep(
          kind: MorningStepKind.mealSummary,
          time: draft.summarizedAt,
          title: 'Tổng hợp suất ăn',
          note: '${draft.total} suất · ${draft.alternative} thay thế',
          state: MorningStepState.done,
        ),
        MorningStep(
          kind: MorningStepKind.mealConfirm,
          time: draft.deadline,
          title: 'Chốt suất ăn',
          note: confirmed == null
              ? '${draft.total} suất chờ xác nhận trên Web'
              : 'Đã gửi bếp ${DateLabels.time24(confirmed)}',
          state: confirmed == null
              ? MorningStepState.current
              : MorningStepState.done,
        ),
        MorningStep(
          kind: MorningStepKind.kitchenReceive,
          time: confirmed ?? draft.deadline.add(const Duration(minutes: 10)),
          title: 'Bếp nhận số',
          note: confirmed == null
              ? 'Sau khi chốt suất'
              : 'Bếp đã nhận ${draft.total} suất',
          state: confirmed == null
              ? MorningStepState.upcoming
              : MorningStepState.done,
        ),
        MorningStep(
          kind: MorningStepKind.lunch,
          time: day.add(const Duration(hours: 10, minutes: 45)),
          title: draft.mealLabel,
          state: confirmed == null
              ? MorningStepState.upcoming
              : MorningStepState.current,
        ),
      ],
      pending: mode == FakeMode.empty
          ? const []
          : [
              if (!draft.confirmed)
                CampusPendingItem(
                  kind: CampusPendingKind.mealCount,
                  title: 'Số suất chưa xác nhận',
                  note:
                      '${draft.total} suất · hạn ${DateLabels.time24(draft.deadline)}',
                ),
              if (rewards > 0)
                CampusPendingItem(
                  kind: CampusPendingKind.rewards,
                  title: 'Đề xuất khen thưởng',
                  note: '$rewards đề xuất chờ xét',
                ),
            ],
      tasks: mode == FakeMode.empty
          ? const []
          : [
              CampusTask(
                kind: CampusTaskKind.mealCount,
                title: 'Số suất hôm nay',
                subtitle: draft.confirmedAt == null
                    ? 'Tổng hợp ${DateLabels.time24(draft.summarizedAt)} · hạn ${DateLabels.time24(draft.deadline)}'
                    : 'Đã gửi bếp ${DateLabels.time24(draft.confirmedAt!)} · ${draft.total} suất',
                badge: draft.confirmed ? 'Đã xác nhận' : 'Chưa xác nhận',
                level: draft.confirmed
                    ? CampusBadgeLevel.done
                    : CampusBadgeLevel.watch,
                highlighted: !draft.confirmed,
              ),
              CampusTask(
                kind: CampusTaskKind.approvals,
                title: 'Chờ xử lý trên Web',
                subtitle: pending == 0
                    ? 'Không còn việc chờ'
                    : [
                        if (!draft.confirmed) 'Số suất',
                        if (rewards > 0) '$rewards đề xuất khen thưởng',
                      ].join(' · '),
                badge: pending == 0 ? 'Xong' : '$pending việc',
                level: pending == 0
                    ? CampusBadgeLevel.done
                    : CampusBadgeLevel.fresh,
              ),
              const CampusTask(
                kind: CampusTaskKind.menu,
                title: 'Thực đơn tuần này',
                subtitle: '12–16/10 · đã công bố',
                badge: 'Xem',
                level: CampusBadgeLevel.done,
              ),
              CampusTask(
                kind: CampusTaskKind.children,
                title: 'Trẻ của cơ sở',
                subtitle: '${children.length} bé · $special bé dị ứng',
                badge: 'Xem',
                level: CampusBadgeLevel.view,
              ),
            ],
    );
  }
}
