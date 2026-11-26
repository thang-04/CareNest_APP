import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả dạng BE `DailySheetResponse.Row`, mỗi mặt một thang riêng, nhãn như Web
/// (`dailyObservationOptions.js`, `EMOTION_LABELS`). Trẻ vắng chỉ hiện (`absentChildren`).
/// Kiến thức kỹ năng theo từng MT chỉ Đạt / Chưa đạt, ở tab định kỳ.
class FakeDailyReviewSource implements DailyReviewSource {
  FakeDailyReviewSource();

  static final shared = FakeDailyReviewSource();

  static const _eating = ['Ăn hết', 'Ăn ít', 'Không ăn'];

  /// `meals` theo bữa (EatingLevel), `nap` (NapLevel), `emotion` (Emotion), `participation`
  /// (Participation), `health.signs` rỗng = Bình thường.
  static const criteria = [
    ReviewCriterionDef(
      id: 'meal-morning',
      title: 'Ăn bữa sáng',
      options: _eating,
      defaultOption: 'Ăn hết',
    ),
    ReviewCriterionDef(
      id: 'meal-lunch',
      title: 'Ăn bữa trưa',
      options: _eating,
      defaultOption: 'Ăn hết',
    ),
    ReviewCriterionDef(
      id: 'meal-afternoon',
      title: 'Ăn bữa chiều',
      options: _eating,
      defaultOption: 'Ăn hết',
    ),
    ReviewCriterionDef(
      id: 'nap',
      title: 'Ngủ trưa',
      options: ['Ngủ tốt', 'Ngủ ít', 'Không ngủ'],
      defaultOption: 'Ngủ tốt',
    ),
    ReviewCriterionDef(
      id: 'emotion',
      title: 'Cảm xúc',
      options: ['Vui vẻ', 'Bình thường', 'Buồn', 'Quấy khóc'],
      defaultOption: 'Vui vẻ',
    ),
    ReviewCriterionDef(
      id: 'participation',
      title: 'Tham gia hoạt động',
      options: ['Tích cực', 'Bình thường', 'Chưa tích cực'],
      defaultOption: 'Tích cực',
    ),
    ReviewCriterionDef(
      id: 'health',
      title: 'Sức khỏe',
      options: ['Bình thường', 'Có biểu hiện'],
      defaultOption: 'Bình thường',
    ),
  ];

  static const _absent = {
    'k-03': 'Vắng có phép',
    'k-08': 'Vắng có phép',
    'k-04': 'Vắng không phép',
  };
  static const _done = {
    'child-1',
    'k-02',
    'k-05',
    'k-06',
    'k-07',
    'k-09',
    'k-10',
    'k-11',
    'k-12',
    'k-13',
    'k-14',
    'k-15',
    'k-16',
    'k-17',
  };

  late final Map<String, KidReview> _reviews = {
    for (final kid in FakeClassRosterSource.kids)
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
              // BE chỉ trả attendanceStatus, không có giờ đến
              presenceLine: 'Có mặt',
              answers: _done.contains(kid.id)
                  ? {
                      for (final c in criteria) c.id: c.defaultOption,
                      if (kid.id == 'k-06') 'health': 'Có biểu hiện',
                      if (kid.id == 'k-06') 'nap': 'Ngủ ít',
                      if (kid.id == 'k-02') 'meal-lunch': 'Ăn ít',
                    }
                  : const {},
              comment: _done.contains(kid.id)
                  ? switch (kid.id) {
                      'k-06' => 'Bé tham gia tốt, cần ổn định giờ ngủ trưa.',
                      'k-02' => 'Bé hòa đồng, hôm nay ăn ít hơn thường lệ.',
                      _ => 'Bé vui vẻ, tham gia tốt các hoạt động.',
                    }
                  : '',
              attentionNotes: switch (kid.id) {
                'k-06' => const ['Không tập trung'],
                'k-02' => const ['Hợp tác tốt', 'Giúp đỡ bạn'],
                _ => const [],
              },
              flagged: kid.id == 'k-07',
              healthSigns: kid.id == 'k-06' ? const ['Ho'] : const [],
            ),
  };

  @override
  Future<ReviewDay> loadDay(
    String classId, {
    DateTime? date,
  }) async => ReviewDay(
    date: date ?? FakeParentHomeSource.today,
    activityLine: 'Tạo hình: Bé tô màu chiếc lá mùa thu',
    criteria: criteria,
    flagLabel: 'Hành vi tốt',
    classComment:
        'Các bé tham gia tích cực hoạt động tạo hình; lưu ý nhắc trẻ uống đủ nước.',
    kids: [for (final kid in FakeClassRosterSource.kids) _reviews[kid.id]!],
  );

  @override
  Future<List<PeriodReview>> loadPeriods(String classId) async => [
    for (final kid in FakeClassRosterSource.kids)
      PeriodReview(
        childId: kid.id,
        fullName: kid.fullName,
        kind: ReviewPeriodKind.week,
        periodLabel: 'Tuần 12–16/10',
        summary: kid.id == 'k-06'
            ? 'Hòa đồng; cần ổn định giờ ngủ trưa.'
            : 'Tham gia tốt các hoạt động trong tuần.',
        statusLabel: 'Đã gửi',
        attentionNote: kid.id == 'k-06' ? 'Theo dõi thêm giấc ngủ trưa.' : '',
      ),
    for (final kid in FakeClassRosterSource.kids)
      PeriodReview(
        childId: kid.id,
        fullName: kid.fullName,
        kind: ReviewPeriodKind.theme,
        periodLabel: 'Cuối chủ đề · Mùa thu của bé',
        summary: kid.id == 'k-06'
            ? 'Đạt 5/6 mục tiêu; cần thêm thời gian ở hoạt động kể chuyện.'
            : 'Đạt các mục tiêu chính của chủ đề.',
        statusLabel: 'Đã xác nhận',
        goals: [
          const ReviewGoalResult(
            code: 'MT1',
            title: 'Nhận biết một số dấu hiệu nổi bật của mùa thu',
            met: true,
          ),
          const ReviewGoalResult(
            code: 'MT2',
            title: 'Phối hợp tay – mắt khi tô, vẽ và xé dán',
            met: true,
          ),
          ReviewGoalResult(
            code: 'MT3',
            title: 'Kể lại sự việc theo trình tự đơn giản',
            met: kid.id == 'k-06' ? false : true,
          ),
          const ReviewGoalResult(
            code: 'MT4',
            title: 'Chủ động tham gia hoạt động cùng nhóm',
            met: true,
          ),
          const ReviewGoalResult(
            code: 'MT5',
            title: 'Giữ gìn sản phẩm của mình và của bạn',
            met: true,
          ),
          const ReviewGoalResult(
            code: 'MT6',
            title: 'Biết lựa chọn trang phục phù hợp thời tiết',
            met: true,
          ),
        ],
      ),
    for (final kid in FakeClassRosterSource.kids)
      PeriodReview(
        childId: kid.id,
        fullName: kid.fullName,
        kind: ReviewPeriodKind.semester,
        periodLabel: 'Học kỳ I',
        summary: 'Đang cập nhật theo đợt đánh giá của trường.',
        statusLabel: 'Đang cập nhật',
      ),
    for (final kid in FakeClassRosterSource.kids)
      PeriodReview(
        childId: kid.id,
        fullName: kid.fullName,
        kind: ReviewPeriodKind.yearEnd,
        periodLabel: 'Cuối năm học 2025–2026',
        summary: 'Hoàn thành tốt các mục tiêu phát triển theo độ tuổi.',
        statusLabel: 'Đã xác nhận',
        measurement: const ReviewMeasurement(
          dateLabel: '20/05/2026',
          weightKg: '17,2',
          heightCm: '104',
        ),
        domains: [
          const ReviewDomainResult(
            title: 'Phát triển thể chất',
            comment: 'Vận động tự tin, phối hợp cơ thể tốt.',
            goals: [
              ReviewGoalResult(
                code: 'TC1',
                title: 'Thực hiện đúng các động tác vận động cơ bản',
                met: true,
                source: 'Chủ đề Bản thân và Mùa thu',
              ),
              ReviewGoalResult(
                code: 'TC2',
                title: 'Có thói quen vệ sinh và tự phục vụ',
                met: true,
              ),
            ],
          ),
          ReviewDomainResult(
            title: 'Phát triển ngôn ngữ',
            comment: kid.id == 'k-06'
                ? 'Cần khuyến khích bé kể chuyện trọn câu hơn.'
                : 'Diễn đạt rõ ý và mạnh dạn trao đổi.',
            goals: [
              const ReviewGoalResult(
                code: 'NN1',
                title: 'Nghe hiểu và thực hiện yêu cầu phù hợp độ tuổi',
                met: true,
              ),
              ReviewGoalResult(
                code: 'NN2',
                title: 'Kể lại câu chuyện hoặc sự việc đã biết',
                met: kid.id == 'k-06' ? false : true,
                source: 'Tổng hợp đánh giá cuối chủ đề',
              ),
            ],
          ),
          const ReviewDomainResult(
            title: 'Tình cảm và kỹ năng xã hội',
            comment: 'Hòa đồng, biết chia sẻ và hỗ trợ bạn.',
            goals: [
              ReviewGoalResult(
                code: 'XH1',
                title: 'Hợp tác với bạn trong hoạt động nhóm',
                met: true,
              ),
              ReviewGoalResult(
                code: 'XH2',
                title: 'Biết thể hiện cảm xúc phù hợp',
                met: true,
              ),
            ],
          ),
        ],
        notes: const [
          ReviewLabeledNote(
            label: 'Đối với trẻ',
            text: 'Tiếp tục tạo cơ hội để trẻ chủ động trình bày ý kiến.',
          ),
          ReviewLabeledNote(
            label: 'Đối với giáo viên',
            text: 'Tăng hoạt động kể chuyện và làm việc theo nhóm nhỏ.',
          ),
          ReviewLabeledNote(
            label: 'Đối với cha mẹ',
            text: 'Khuyến khích trẻ kể lại hoạt động trong ngày.',
          ),
        ],
      ),
  ];
}
