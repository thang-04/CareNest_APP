import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';

/// Sổ sức khỏe từ BE (PAR-03, HLT-11): `GET /children/{id}/health/published` — chỉ kết quả đã công bố.
/// Kỳ cân đo = kết quả `MEASUREMENT` đủ số đo; đợt khám = kết quả `EXAM` đã kết luận (chỉ phần kết luận);
/// biểu đồ = `growth`; xu hướng = giải thích đã duyệt.
class LiveHealthBookSource implements HealthBookSource {
  LiveHealthBookSource(this._api);

  final MobileApi _api;

  @override
  Future<HealthBook> load(String childId) async {
    final data =
        await _api.json('GET', '/children/$childId/health/published') as Map;
    final results = _maps(data['results']).toList();
    final examIds = {
      for (final r in results)
        if (r['campaignKind'] == 'EXAM') '${r['id']}',
    };
    return HealthBook(
      rounds: [
        for (final r in results)
          if (r['campaignKind'] == 'MEASUREMENT') ?_round(r),
      ],
      exams: [
        for (final r in results)
          if (r['campaignKind'] == 'EXAM') ?_exam(r),
      ],
      growth: [
        for (final point in _maps(data['growth']))
          if ((_number(point['heightCm']), _number(point['weightKg'])) case (
            final height?,
            final weight?,
          ))
            GrowthPoint(
              date: DateTime.parse(point['date']! as String),
              heightCm: height,
              weightKg: weight,
              fromExam: examIds.contains('${point['measurementId']}'),
            ),
      ],
      interpretation: switch (data['interpretation']) {
        final Map item => _interpretation(item),
        _ => null,
      },
    );
  }

  static Iterable<Map<Object?, Object?>> _maps(Object? list) =>
      (list as List? ?? const []).whereType<Map>();

  static double? _number(Object? value) => (value as num?)?.toDouble();

  /// Thiếu số đo hoặc tuổi ⇒ không thành kỳ cân đo (không hiện số trống).
  static MeasurementRound? _round(Map<Object?, Object?> r) {
    final height = _number(r['heightCm']);
    final weight = _number(r['weightKg']);
    final bmi = _number(r['bmi']);
    final age = (r['ageMonths'] as num?)?.toInt();
    if (height == null || weight == null || bmi == null || age == null) {
      return null;
    }
    return MeasurementRound(
      id: '${r['id']}',
      name: r['campaignName']?.toString() ?? 'Cân đo',
      date: DateTime.parse(r['date']! as String),
      ageMonths: age,
      heightCm: height,
      weightKg: weight,
      bmi: bmi,
      bmiLevel: switch (r['bmiStatus']) {
        'SEVERE_THINNESS' => BmiLevel.severeThinness,
        'THINNESS' => BmiLevel.thinness,
        'NORMAL' => BmiLevel.normal,
        'OVERWEIGHT_RISK' => BmiLevel.overweightRisk,
        'OVERWEIGHT' => BmiLevel.overweight,
        'OBESE' => BmiLevel.obese,
        _ => null,
      },
      note: r['note']?.toString(),
    );
  }

  /// Chỉ phiếu đã kết luận; API phụ huynh chỉ trả phần kết luận (nhãn cùng Web).
  static HealthExam? _exam(Map<Object?, Object?> r) {
    final conclusion = r['conclusion'] as Map?;
    final category = _categoryLabels[r['conclusionCategory']];
    final age = (r['ageMonths'] as num?)?.toInt();
    if (conclusion == null || category == null || age == null) return null;
    final action = _actionLabels[conclusion['action']];
    final specialty = conclusion['specialty']?.toString();
    return HealthExam(
      id: '${r['id']}',
      name: r['campaignName']?.toString() ?? 'Khám sức khỏe',
      date: DateTime.parse(r['date']! as String),
      ageMonths: age,
      examiner: null,
      doctorName: conclusion['doctorName']?.toString(),
      followUp: switch (r['followUpLevel']) {
        'KNOWN_STABLE' => FollowUpLevel.knownStable,
        'WATCH' => FollowUpLevel.watch,
        'CLOSE_WATCH' => FollowUpLevel.closeWatch,
        _ => FollowUpLevel.none,
      },
      conclusion: category,
      action: conclusion['action'] == 'REFERRAL' && specialty != null
          ? '$action: $specialty'
          : action,
      nutritionStatus: null,
      issueText: conclusion['issueText']?.toString(),
      issueKind: _issueKindLabels[conclusion['issueKind']],
      advice: conclusion['adviceText']?.toString(),
    );
  }

  static TrendInterpretation _interpretation(Map<Object?, Object?> item) {
    final content = item['content'] as Map?;
    return TrendInterpretation(
      periodLabel: switch (item['period']) {
        'MONTHS_6' => 'Phân tích 6 tháng',
        'MONTHS_12' => 'Phân tích 12 tháng',
        _ => 'Phân tích toàn bộ quá trình',
      },
      approvedOn: DateTime.parse(item['approvedAt']! as String).toLocal(),
      overview: (content?['overview'] ?? item['summary'])?.toString() ?? '',
      attention: [
        for (final point in _maps(content?['attentionPoints']))
          if (point['text'] case final String text) text,
      ],
      positives: [
        for (final text in content?['positives'] as List? ?? const []) '$text',
      ],
      limitations: content?['limitations']?.toString(),
      stale: item['stale'] == true,
    );
  }

  // Nhãn giống Web (CareNest_FE healthExamForm.js): cùng mã BE ⇒ cùng nhãn
  static const _categoryLabels = {
    'NORMAL': 'Bình thường',
    'ISSUE': 'Có vấn đề, tư vấn',
    'REFERRAL': 'Chuyển khám chuyên khoa',
    'TB_RISK': 'Nguy cơ lao',
    'FOLLOWING_NO_NEW': 'Đang theo dõi, chưa ghi nhận thêm',
    'FOLLOWING_NEW': 'Đang theo dõi, có bất thường mới',
  };
  static const _actionLabels = {
    'NONE': 'Không cần tư vấn hay chuyển khám',
    'ADVICE': 'Tư vấn',
    'REFERRAL': 'Chuyển khám chuyên khoa',
  };
  static const _issueKindLabels = {
    'NEW': 'Vấn đề mới hoặc có thay đổi',
    'KNOWN': 'Vấn đề đã biết, không thay đổi so với trước',
  };
}
