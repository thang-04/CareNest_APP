import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/principal_overview/domain/school_overview.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_principal_reward_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_batch.dart';

/// Dữ liệu giả mockup H01 — 12/10: 334 trẻ (196 cơ sở chính + 138 cơ sở 2), 312 có mặt
/// (182 + 130), 306 suất đã chốt. Đợt chờ duyệt đọc từ nguồn khen thưởng dùng chung.
class FakeSchoolOverviewSource implements SchoolOverviewSource {
  FakeSchoolOverviewSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
    PrincipalRewardSource? rewards,
  }) : _rewards = rewards ?? FakePrincipalRewardSource.shared;

  final FakeMode mode;
  final Duration delay;
  final PrincipalRewardSource _rewards;

  @override
  Future<SchoolOverview> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final batches = await _rewards.loadBatches();
    return SchoolOverview(
      staffName: 'Nguyễn Thị Hồng',
      schoolName: 'Trường MN Thượng Hồng',
      campusCount: FakeCampusChildrenSource.campusNames.length,
      schoolYear: '2026–2027',
      date: FakeParentHomeSource.today,
      present: 312,
      enrolled:
          FakeCampusChildrenSource.children.length +
          FakeCampusChildrenSource.secondCampusChildren.length,
      presentRate: '93%',
      confirmedMeals: 306,
      mealCampuses: 2,
      menusPublished: 2,
      evaluationTitle: 'Đánh giá trẻ tháng 9',
      evaluations: const [
        GroupEvaluation(groupLabel: 'Nhà trẻ', ratio: 0.86, percent: '86%'),
        GroupEvaluation(groupLabel: 'Mầm', ratio: 0.91, percent: '91%'),
        GroupEvaluation(groupLabel: 'Chồi', ratio: 0.88, percent: '88%'),
        GroupEvaluation(groupLabel: 'Lá', ratio: 0.94, percent: '94%'),
      ],
      pending: mode == FakeMode.empty
          ? const []
          : batches
                .where((batch) => batch.status == RewardBatchStatus.pending)
                .toList(),
    );
  }
}
