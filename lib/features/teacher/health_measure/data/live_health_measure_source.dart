import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/health_labels.dart';
import 'package:carenest_app/features/teacher/health_measure/domain/health_measure.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';

/// Cân đo từ BE (HLT-09, 11, 13): kỳ đang diễn ra `GET /health-checks?kind=MEASUREMENT&status=IN_PROGRESS`,
/// danh sách lớp `GET /health-checks/{campaignId}/classes/{classId}/children`, ghi
/// `POST|PUT /children/{id}/health/measurements`. Xếp loại BMI do BE tính; App không tự tính.
class LiveHealthMeasureSource implements HealthMeasureSource {
  LiveHealthMeasureSource(
    this._api, {
    DateTime Function()? clock,
    String? Function()? schoolYearId,
  }) : _clock = clock ?? DateTime.now,
       _schoolYearId = schoolYearId ?? (() => SelectedSchoolYear.apiYearId);

  final MobileApi _api;
  final DateTime Function() _clock;
  final String? Function() _schoolYearId;

  /// Id kỳ và id số đo của từng bé từ lần tải gần nhất, để biết lưu là tạo mới hay sửa.
  final Map<String, ({int? campaignId, int? measurementId})> _refs = {};

  @override
  Future<MeasureMonth> loadMonth(String classId) async {
    final campaigns =
        await _api.json(
              'GET',
              '/health-checks?kind=MEASUREMENT&status=IN_PROGRESS',
            )
            as List? ??
        const [];
    final open = campaigns.whereType<Map>().toList();
    // HLT-01: không có kỳ đang diễn ra ⇒ chỉ xem, không nhập
    if (open.isEmpty) return const MeasureMonth(title: '', kids: []);
    // GV có thể dạy ở 2 điểm trường, mỗi điểm một kỳ đang diễn ra: thử từng kỳ tới khi BE nhận lớp này
    // (kỳ của điểm trường khác trả 404 CLASS_NOT_FOUND).
    Map<Object?, Object?>? campaign;
    Map<Object?, Object?>? data;
    ApiFailure? lastFailure;
    for (final candidate in open) {
      try {
        data =
            await _api.json(
                  'GET',
                  '/health-checks/${candidate['id']}/classes/$classId/children',
                )
                as Map;
        campaign = candidate;
        break;
      } on ApiFailure catch (failure) {
        if (failure.status != 404) rethrow;
        lastFailure = failure;
      }
    }
    if (campaign == null || data == null) {
      throw lastFailure ?? ApiFailure(404, 'Không tìm thấy kỳ cân đo');
    }
    final campaignId = (campaign['id'] as num).toInt();
    _refs.clear();
    final kids = <MeasureKid>[];
    for (final c in (data['children'] as List? ?? const []).whereType<Map>()) {
      // Trẻ đã chuyển lớp: chỉ xem ở lớp cũ, không nhập
      if (c['movedTo'] != null) continue;
      final kid = _kid(c);
      _refs[kid.childId] = (
        campaignId: campaignId,
        measurementId: (c['measurementId'] as num?)?.toInt(),
      );
      kids.add(kid);
    }
    final info = data['campaign'] as Map? ?? campaign;
    final progress = info['progress'] as Map? ?? const {};
    final status = campaignStatusLabel(info['status']);
    return MeasureMonth(
      title: info['name']?.toString() ?? '',
      kids: kids,
      campaign: MeasureCampaign(
        name: info['name']?.toString() ?? '',
        kindLabel: campaignKindLabel(info['kind']),
        campusName: _campus(info['campusName']),
        dateRange: _range(info['startDate'], info['endDate']),
        statusLabel: status.label,
        recorded: (progress['recorded'] as num?)?.toInt() ?? 0,
        total: (progress['total'] as num?)?.toInt() ?? 0,
        absent: (progress['absent'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  Future<List<HealthCampaign>> loadCampaigns() async {
    final yearId = _schoolYearId();
    final data =
        await _api.json(
              'GET',
              '/health-checks${yearId == null ? '' : '?schoolYear=$yearId'}',
            )
            as List? ??
        const [];
    return [
      for (final c in data.whereType<Map>())
        () {
          final progress = c['progress'] as Map? ?? const {};
          final status = campaignStatusLabel(c['status']);
          final measurement = c['kind'] == 'MEASUREMENT';
          final bmi = progress['bmi'] as Map? ?? const {};
          // Số trẻ có cảnh báo do BE đếm: kỳ cân đo theo mức BMI, đợt khám theo kết luận bác sĩ
          final warnings = measurement
              ? bmi.values.whereType<num>().fold<int>(
                  0,
                  (a, b) => a + b.toInt(),
                )
              : ((progress['watch'] as num?)?.toInt() ?? 0) +
                    ((progress['closeWatch'] as num?)?.toInt() ?? 0);
          return HealthCampaign(
            id: '${c['id']}',
            name: c['name']?.toString() ?? '',
            kindLabel: campaignKindLabel(c['kind']),
            campusName: _campus(c['campusName']),
            dateRange: _range(c['startDate'], c['endDate']),
            statusLabel: status.label,
            statusTone: status.tone,
            recorded: (progress['recorded'] as num?)?.toInt() ?? 0,
            total: (progress['total'] as num?)?.toInt() ?? 0,
            warningLabel: warnings > 0
                ? measurement
                      ? '$warnings trẻ có cảnh báo BMI'
                      : '$warnings trẻ cần theo dõi'
                : null,
          );
        }(),
    ];
  }

  /// Web chỉ hiện phần trước " - " của tên điểm trường.
  static String _campus(Object? name) => '${name ?? ''}'.split(' - ').first;

  static String _range(Object? from, Object? to) {
    final a = DateTime.tryParse('$from');
    final b = DateTime.tryParse('$to');
    if (a == null || b == null) return '';
    return '${DateLabels.date(a)} – ${DateLabels.date(b)}';
  }

  MeasureKid _kid(Map<Object?, Object?> c) {
    final state = switch (c['result']) {
      'RECORDED' => MeasureState.measured,
      _ when c['absentToday'] == true => MeasureState.absent,
      'ABSENT' => MeasureState.absent,
      _ => MeasureState.pending,
    };
    final measured = state == MeasureState.measured;
    return MeasureKid(
      childId: '${c['childId']}',
      fullName: c['fullName']?.toString() ?? '',
      ageLabel: _age(c['dateOfBirth']),
      state: state,
      height: measured ? _decimal(c['heightCm']) : null,
      weight: measured ? _decimal(c['weightKg']) : null,
      measuredWhen: switch (c['date']) {
        final String d when measured => DateLabels.dayMonth(DateTime.parse(d)),
        _ => null,
      },
      published: c['published'] != false,
      result: measured ? _result(c) : null,
    );
  }

  /// BMI và mức BMI BE trả sau khi lưu (HLT-18); không có mức ⇒ null, APP không tự phân loại.
  static MeasureResult? _result(Map<Object?, Object?> c) {
    final status = bmiStatusLabel(c['bmiStatus']);
    if (status == null) return null;
    final bmi = _decimal(c['bmi']);
    return MeasureResult(
      label: status.label,
      tone: status.tone,
      detail: bmi == null ? '' : 'BMI $bmi',
    );
  }

  @override
  Future<void> saveMeasurement({
    required String childId,
    required String height,
    required String weight,
    String? note,
    String? reason,
  }) async {
    var ref = _refs[childId];
    if (ref == null) {
      final record = await _api.json('GET', '/children/$childId/health') as Map;
      final open = record['openCampaign'] as Map?;
      ref = (
        campaignId: (open?['id'] as num?)?.toInt(),
        measurementId: (open?['resultMeasurementId'] as num?)?.toInt(),
      );
    }
    final trimmedNote = note?.trim();
    final trimmedReason = reason?.trim();
    final body = {
      'heightCm': _number(height),
      'weightKg': _number(weight),
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      if (trimmedReason != null && trimmedReason.isNotEmpty)
        'reason': trimmedReason,
    };
    final measurementId = ref.measurementId;
    if (measurementId != null) {
      await _api.json(
        'PUT',
        '/children/$childId/health/measurements/$measurementId',
        body: body,
      );
    } else {
      await _api.json(
        'POST',
        '/children/$childId/health/measurements',
        body: {'campaignId': ?ref.campaignId, ...body},
      );
    }
    _refs.remove(childId);
  }

  /// BE nhận tối đa 1 số thập phân (`@Digits(fraction = 1)`): làm tròn trước khi gửi, tránh 400.
  static double? _number(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value == null ? null : (value * 10).round() / 10;
  }

  /// "104" hoặc "17,2": dấu phẩy thập phân như người dùng nhập.
  static String? _decimal(Object? value) {
    if (value is! num) return null;
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return text.replaceAll('.', ',');
  }

  String _age(Object? dateOfBirth) {
    if (dateOfBirth is! String) return '';
    final birth = DateTime.parse(dateOfBirth);
    final now = _clock();
    var months = (now.year - birth.year) * 12 + now.month - birth.month;
    if (now.day < birth.day) months--;
    if (months < 0) return '';
    final rest = months % 12;
    return rest == 0
        ? '${months ~/ 12} tuổi'
        : '${months ~/ 12} tuổi $rest tháng';
  }
}
