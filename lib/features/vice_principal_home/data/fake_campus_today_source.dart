import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/approvals/data/fake_meal_adjustment_source.dart';
import 'package:carenest_app/features/approvals/domain/meal_adjustment.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/meal_count_confirm/data/fake_meal_count_confirm_source.dart';
import 'package:carenest_app/features/meal_count_confirm/domain/meal_count_draft.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';
import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';
import 'package:carenest_app/features/vice_principal_home/domain/campus_today.dart';

/// Dữ liệu giả mockup V01 / V05 — cơ sở chính 12/10: 196 trẻ, 182 có mặt (khớp K03), 9 có phép, 5 vắng.
/// Số chờ duyệt, mốc buổi sáng và việc "Chốt suất" đọc từ các nguồn giả dùng chung để đổi theo khi Phó HT xử lý.
class FakeCampusTodaySource implements CampusTodaySource {
  FakeCampusTodaySource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
    MealAdjustmentSource? meals,
    RewardProposalSource? rewards,
    MealCountConfirmSource? mealCount,
    CookingStatusSource? cooking,
  }) : _meals = meals ?? FakeMealAdjustmentSource.shared,
       _rewards = rewards ?? FakeRewardProposalSource.shared,
       _mealCount = mealCount ?? FakeMealCountConfirmSource.shared,
       _cooking = cooking ?? FakeCookingStatusSource.shared;

  final FakeMode mode;
  final Duration delay;
  final MealAdjustmentSource _meals;
  final RewardProposalSource _rewards;
  final MealCountConfirmSource _mealCount;
  final CookingStatusSource _cooking;

  @override
  Future<CampusToday> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final meals = await _meals.loadPending();
    final rewards = (await _rewards.load())
        .where((item) => item.stage == RewardStage.pending)
        .length;
    final draft = await _mealCount.loadToday();
    final children = FakeCampusChildrenSource.children;
    final special = children.where((child) => child.tag != null).length;
    final pending = meals.length + (rewards > 0 ? 1 : 0);
    final lunch = (await _cooking.loadToday())[MealSlot.lunch];
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
      pendingApprovals: pending,
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
              ? '${draft.total} suất chờ thầy xác nhận gửi bếp'
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
          note: lunch == null ? null : 'Bếp: ${lunch.stage.label}',
          state: confirmed == null
              ? MorningStepState.upcoming
              : MorningStepState.current,
        ),
      ],
      pending: mode == FakeMode.empty
          ? const []
          : [
              for (final meal in meals)
                CampusPendingItem(
                  kind: CampusPendingKind.mealAdjustment,
                  id: meal.id,
                  title: 'Điều chỉnh suất · ${meal.className}',
                  note:
                      '${meal.deltaLabel} · ${DateLabels.time24(meal.sentAt)}',
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
                kind: CampusTaskKind.confirmMeals,
                title: 'Chốt suất ăn hôm nay',
                subtitle: draft.confirmedAt == null
                    ? 'Tổng hợp ${DateLabels.time24(draft.summarizedAt)} · hạn ${DateLabels.time24(draft.deadline)}'
                    : 'Đã gửi bếp ${DateLabels.time24(draft.confirmedAt!)} · ${draft.total} suất',
                badge: draft.confirmed ? 'Đã gửi' : 'Cần làm',
                level: draft.confirmed
                    ? CampusBadgeLevel.done
                    : CampusBadgeLevel.todo,
                highlighted: !draft.confirmed,
              ),
              CampusTask(
                kind: CampusTaskKind.approvals,
                title: 'Yêu cầu chờ duyệt',
                subtitle: [
                  if (meals.isNotEmpty) '${meals.length} suất ăn',
                  if (rewards > 0) '1 đề xuất khen thưởng',
                  if (pending == 0) 'Không còn yêu cầu',
                ].join(' · '),
                badge: pending == 0 ? 'Xong' : '$pending mới',
                level: pending == 0
                    ? CampusBadgeLevel.done
                    : CampusBadgeLevel.fresh,
              ),
              const CampusTask(
                kind: CampusTaskKind.kitchen,
                title: 'Trạng thái bếp',
                subtitle: 'Bữa trưa',
                badge: 'Theo dõi',
                level: CampusBadgeLevel.watch,
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
                subtitle:
                    '${children.length} bé · $special bé dị ứng / ăn kiêng',
                badge: 'Xem',
                level: CampusBadgeLevel.view,
              ),
            ],
    );
  }

  @override
  Future<CampusKitchen> loadKitchen() async => const CampusKitchen(
    kitchenLabel: 'Bếp cơ sở chính · Cô Nguyễn Thị Mai',
    slipNote: 'Phiếu xuất kho PXK-1012 · đã duyệt 07:30',
    shortageTitle: 'Báo thiếu từ bếp · 07:55',
    shortageNote: 'Cá basa thiếu 0,7 kg · bếp đã đổi 13 suất sang thịt gà',
  );
}
