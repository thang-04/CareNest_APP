import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả mockup T04 / T04.1. Ba trẻ vắng khớp màn Điểm danh (Khánh Linh, Minh Châu có phép;
/// Đức Huy không phép); 8 trẻ đã đánh giá. Một bản dùng chung để danh sách thấy kết quả vừa lưu.
class FakeDailyReviewSource implements DailyReviewSource {
  FakeDailyReviewSource();

  static final shared = FakeDailyReviewSource();

  static const levels = ['Đạt', 'Cần cố gắng', 'Chưa đạt'];

  // 7 mặt theo OBS-02, mặc định Đạt (OBS-01)
  static final criteria = [
    for (final (id, title) in [
      ('eating', 'Ăn uống'),
      ('sleep', 'Ngủ'),
      ('emotion', 'Cảm xúc'),
      ('behavior', 'Hành vi'),
      ('participation', 'Tham gia hoạt động'),
      ('learning', 'Kiến thức – kỹ năng'),
      ('health', 'Sức khỏe'),
    ])
      ReviewCriterionDef(
        id: id,
        title: title,
        options: levels,
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
                      for (final criterion in criteria)
                        criterion.id: criterion.defaultOption,
                    }
                  : const {},
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

  @override
  Future<void> save(KidReview review) async {
    _reviews[review.childId] = review;
  }
}
