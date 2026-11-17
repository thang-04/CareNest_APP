import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả mockup T04 / T04.1. Ba trẻ vắng khớp màn Điểm danh (Khánh Linh, Minh Châu có phép;
/// Đức Huy không phép); 8 trẻ đã đánh giá. Chỉ đọc; bé k-06 có một mặt Cần cố gắng và nhận xét.
class FakeDailyReviewSource implements DailyReviewSource {
  FakeDailyReviewSource();

  static final shared = FakeDailyReviewSource();

  static const _levels = ['Đạt', 'Cần cố gắng', 'Chưa đạt'];

  /// 7 mặt theo OBS-02; mức Đạt / Cần cố gắng / Chưa đạt, mặc định Đạt (OBS-01).
  static const criteria = [
    ReviewCriterionDef(
      id: 'eating',
      title: 'Ăn uống',
      options: _levels,
      defaultOption: 'Đạt',
    ),
    ReviewCriterionDef(
      id: 'sleep',
      title: 'Ngủ',
      options: _levels,
      defaultOption: 'Đạt',
    ),
    ReviewCriterionDef(
      id: 'emotion',
      title: 'Cảm xúc',
      options: _levels,
      defaultOption: 'Đạt',
    ),
    ReviewCriterionDef(
      id: 'behavior',
      title: 'Hành vi, quan hệ với bạn',
      options: _levels,
      defaultOption: 'Đạt',
    ),
    ReviewCriterionDef(
      id: 'participation',
      title: 'Tham gia hoạt động',
      options: _levels,
      defaultOption: 'Đạt',
    ),
    ReviewCriterionDef(
      id: 'knowledge',
      title: 'Kiến thức, kỹ năng theo bài học',
      options: _levels,
      defaultOption: 'Đạt',
    ),
    ReviewCriterionDef(
      id: 'health',
      title: 'Sức khỏe',
      options: _levels,
      defaultOption: 'Đạt',
    ),
  ];

  static const _absent = {
    'k-03': 'Vắng có phép',
    'k-08': 'Vắng có phép',
    'k-04': 'Vắng không phép',
  };
  static const _done = {
    'k-06',
    'k-07',
    'k-09',
    'k-10',
    'k-11',
    'k-12',
    'k-13',
    'k-14',
  };

  late final Map<String, KidReview> _reviews = {
    for (final (i, kid) in FakeClassRosterSource.kids.indexed)
      kid.id: _absent.containsKey(kid.id)
          ? KidReview(
              childId: kid.id,
              fullName: kid.fullName,
              state: KidReviewState.absent,
              presenceLine: _absent[kid.id]!,
            )
          : KidReview(
              childId: kid.id,
              fullName: kid.fullName,
              state: _done.contains(kid.id)
                  ? KidReviewState.done
                  : KidReviewState.pending,
              presenceLine:
                  'Có mặt 07:${((42 + i) % 60).toString().padLeft(2, '0')}',
              answers: _done.contains(kid.id)
                  ? {
                      for (final c in criteria) c.id: c.defaultOption,
                      if (kid.id == 'k-06') 'sleep': 'Cần cố gắng',
                    }
                  : const {},
              note: kid.id == 'k-06' ? 'Bé ngủ trưa muộn, hơi quấy.' : '',
            ),
  };

  @override
  Future<ReviewDay> loadDay(String classId) async => ReviewDay(
    date: FakeParentHomeSource.today,
    activityLine: 'Tạo hình: Bé tô màu chiếc lá mùa thu',
    criteria: criteria,
    flagLabel: 'Hành vi tốt',
    kids: [for (final kid in FakeClassRosterSource.kids) _reviews[kid.id]!],
  );
}
