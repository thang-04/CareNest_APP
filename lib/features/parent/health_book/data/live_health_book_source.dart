import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/health_book/data/exam_form_labels.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';

/// Sổ sức khỏe từ BE (PAR-03, HLT-11): `GET /children/{id}/health/published` — chỉ kết quả đã công bố.
/// Kỳ cân đo = kết quả `MEASUREMENT` đủ số đo; đợt khám = kết quả `EXAM` đã kết luận (chỉ phần kết luận);
/// biểu đồ = `growth`; xu hướng = giải thích đã duyệt.
class LiveHealthBookSource extends HealthBookSource {
  LiveHealthBookSource(this._api);

  final MobileApi _api;

  @override
  Future<HealthBook> load(String childId, {ChildSchoolYear? year}) async {
    final ofYear = year == null ? '' : '?schoolYearId=${year.id}';
    final data =
        await _api.json('GET', '/children/$childId/health/published$ofYear')
            as Map;
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

  /// Phiếu khám đã kết luận đủ các phần (`GET /children/{id}/health/published/exams/{resultId}`);
  /// BE trả 404 khi phiếu chưa kết luận hoặc không phải phiếu khám ⇒ null.
  @override
  Future<HealthExam?> loadExam(String childId, String examId) async {
    final Map<Object?, Object?> data;
    try {
      data =
          await _api.json(
                'GET',
                '/children/$childId/health/published/exams/$examId',
              )
              as Map;
    } on ApiFailure catch (failure) {
      if (failure.status == 404) return null;
      rethrow;
    }
    final conclusion = data['conclusion'] as Map? ?? const {};
    final specialty = _text(conclusion['specialty']);
    final action = examActionLabels[conclusion['action']];
    final nutrition = data['nutrition'] as Map? ?? const {};
    final statuses = [
      for (final code in nutrition['statuses'] as List? ?? const [])
        ?examNutritionStatus.option(code),
    ];
    return HealthExam(
      id: '${data['resultId']}',
      name: _text(data['campaignName']) ?? 'Khám sức khỏe',
      date: DateTime.parse(data['date']! as String),
      ageMonths: (data['ageMonths'] as num?)?.toInt() ?? 0,
      examiner: _text(data['examiner']),
      doctorName: _text(conclusion['doctorName']),
      followUp: _followUp(data['followUpLevel']),
      conclusion: examCategoryLabels[data['conclusionCategory']] ?? '',
      action: conclusion['action'] == 'REFERRAL' && specialty != null
          ? '$action: $specialty'
          : action,
      nutritionStatus: statuses.isEmpty
          ? null
          : statuses.map((option) => option.label).join(', '),
      issueText: _text(conclusion['issueText']),
      issueKind: examIssueKindLabels[conclusion['issueKind']],
      advice: _text(conclusion['adviceText']),
      parentOpinion: _text(conclusion['parentOpinion']),
      history: _history(data['history'] as Map? ?? const {}),
      vitals: _vitals(data['vitals'] as Map? ?? const {}),
      nutrition: _nutrition(data, nutrition),
      development: _fields(examDevelopment, data['development']),
      immunization: _fields(examImmunization, data['immunization']),
      clinical: [
        for (final group in examClinical)
          if (_fields(group.items, data['clinical']) case final items
              when items.isNotEmpty)
            ExamSection(group.title, items),
      ],
    );
  }

  /// Chữ rỗng ⇒ null (BE lưu "" cho ô chưa nhập).
  static String? _text(Object? value) => switch (value?.toString().trim()) {
    final String text when text.isNotEmpty => text,
    _ => null,
  };

  static String _decimal(num value) =>
      (value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toString())
          .replaceAll('.', ',');

  static FollowUpLevel _followUp(Object? code) => switch (code) {
    'KNOWN_STABLE' => FollowUpLevel.knownStable,
    'WATCH' => FollowUpLevel.watch,
    'CLOSE_WATCH' => FollowUpLevel.closeWatch,
    _ => FollowUpLevel.none,
  };

  /// Mục đã chọn của một phần phiếu; ô chưa chọn ("") không hiện.
  static List<ExamItem> _fields(List<ExamField> fields, Object? values) {
    final map = values as Map? ?? const {};
    return [
      for (final field in fields)
        if (field.option(map[field.key]) case final option?)
          ExamItem(field.label, option.label, abnormal: option.abnormal),
    ];
  }

  static List<ExamItem> _history(Map<Object?, Object?> history) => [
    for (final field in examHistory)
      if (field.option(history[field.key]) case final option?)
        ExamItem(field.label, switch ((option.value, field.key)) {
          ('YES', 'self') => [
            option.label,
            ?_text(history['selfText']),
          ].join(' · '),
          ('YES', 'family') => [
            option.label,
            ?_text(history['familyText']),
          ].join(' · '),
          ('YES', 'tbContact') => [
            option.label,
            if (_text(history['tbContactDate']) case final date?)
              DateLabels.date(DateTime.parse(date)),
          ].join(' · '),
          _ => option.label,
        }, abnormal: option.abnormal),
  ];

  static List<ExamVital> _vitals(Map<Object?, Object?> vitals) => [
    for (final field in examVitals)
      if (vitals[field.key] case final num value)
        ExamVital(
          label: field.label,
          value: _decimal(value),
          unit: field.unit,
          status:
              field.options
                  .where((o) => o.value == vitals[field.statusKey])
                  .firstOrNull
                  ?.label ??
              '',
          abnormal: field.options.any(
            (o) => o.value == vitals[field.statusKey] && o.abnormal,
          ),
        ),
  ];

  /// Số đo của lần khám + phần dinh dưỡng bác sĩ ghi; không tự tính BMI.
  static List<ExamItem> _nutrition(
    Map<Object?, Object?> data,
    Map<Object?, Object?> nutrition,
  ) {
    final head = examHeadStatus.option(nutrition['headStatus']);
    return [
      if (data['heightCm'] case final num v)
        ExamItem('Chiều cao', '${_decimal(v)} cm'),
      if (data['weightKg'] case final num v)
        ExamItem('Cân nặng', '${_decimal(v)} kg'),
      if (data['headCircumferenceCm'] case final num v)
        ExamItem(
          'Vòng đầu',
          ['${_decimal(v)} cm', ?head?.label].join(' · '),
          abnormal: head?.abnormal ?? false,
        ),
      if (nutrition['lengthForAgeSd'] case final num v)
        ExamItem('Chiều cao theo tuổi', '${_decimal(v)} SD'),
      if (nutrition['weightForAgeSd'] case final num v)
        ExamItem('Cân nặng theo tuổi', '${_decimal(v)} SD'),
      if (nutrition['armCircumferenceMm'] case final num v)
        ExamItem('Vòng cánh tay', '${_decimal(v)} mm'),
    ];
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
    final category = examCategoryLabels[r['conclusionCategory']];
    final age = (r['ageMonths'] as num?)?.toInt();
    if (conclusion == null || category == null || age == null) return null;
    final action = examActionLabels[conclusion['action']];
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
      issueKind: examIssueKindLabels[conclusion['issueKind']],
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
}
