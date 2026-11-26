import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/health_measure/data/live_health_measure_source.dart';
import 'package:carenest_app/features/teacher/health_measure/domain/health_measure.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  final session = FakeLiveSession(['TEACHER']);
  final clock = DateTime(2026, 11, 25);
  const campaignsPath =
      'GET /health-checks?kind=MEASUREMENT&status=IN_PROGRESS';

  Map<String, Object?> roster() => {
    'campaign': {
      'id': 3,
      'kind': 'MEASUREMENT',
      'name': 'Kỳ cân đo quý IV',
      'campusName': 'Cơ sở chính - Thượng Hồng',
      'startDate': '2026-11-05',
      'endDate': '2026-11-20',
      'status': 'IN_PROGRESS',
      'progress': {'total': 3, 'recorded': 1, 'absent': 1},
    },
    'cls': {'id': 12, 'name': 'Mầm 3A'},
    'canRecord': true,
    'children': [
      {
        'childId': 5,
        'fullName': 'Nguyễn Minh Anh',
        'dateOfBirth': '2022-09-10',
        'result': 'RECORDED',
        'measurementId': 40,
        'date': '2026-11-20',
        'heightCm': 104.0,
        'weightKg': 17.2,
        'bmi': 15.9,
        'bmiStatus': 'OVERWEIGHT_RISK',
        'published': true,
        'absentToday': false,
      },
      {
        'childId': 6,
        'fullName': 'Lê Hoàng Nam',
        'dateOfBirth': '2021-11-25',
        'result': 'NOT_RECORDED',
        'measurementId': null,
        'absentToday': false,
      },
      {
        'childId': 7,
        'fullName': 'Phạm Khánh Linh',
        'dateOfBirth': '2022-01-01',
        'result': 'NOT_RECORDED',
        'absentToday': true,
      },
      {
        'childId': 8,
        'fullName': 'Trẻ chuyển lớp',
        'result': 'NOT_RECORDED',
        'movedTo': {'className': 'Mầm 3B'},
      },
    ],
  };

  Map<String, Object? Function(Object?)> routes([
    void Function(String, Object?)? onWrite,
  ]) => {
    campaignsPath: (_) => [
      {'id': 3, 'name': 'Kỳ cân đo quý IV'},
    ],
    'GET /health-checks/3/classes/12/children': (_) => roster(),
    'POST /children/6/health/measurements': (b) {
      onWrite?.call('POST', b);
      return <String, Object?>{};
    },
    'PUT /children/5/health/measurements/40': (b) {
      onWrite?.call('PUT', b);
      return <String, Object?>{};
    },
  };

  test('loadMonth_mapsStatesAndNumbers', () async {
    final source = LiveHealthMeasureSource(
      ScriptedApi(session, routes()),
      clock: () => clock,
    );

    final month = await source.loadMonth('12');

    expect(month.title, 'Kỳ cân đo quý IV');
    expect(month.kids.map((k) => k.childId), ['5', '6', '7']);
    expect(month.kids[0].state, MeasureState.measured);
    expect(month.kids[0].height, '104');
    expect(month.kids[0].weight, '17,2');
    expect(month.kids[0].ageLabel, '4 tuổi 2 tháng');
    expect(month.kids[1].state, MeasureState.pending);
    expect(month.kids[1].ageLabel, '5 tuổi');
    expect(month.kids[2].state, MeasureState.absent);
    expect(month.isOpen, isTrue);
    final campaign = month.campaign!;
    expect(campaign.kindLabel, 'Kỳ cân đo');
    expect(campaign.campusName, 'Cơ sở chính');
    expect(campaign.dateRange, '05/11/2026 – 20/11/2026');
    expect(campaign.statusLabel, 'Đang diễn ra');
    expect((campaign.recorded, campaign.total, campaign.absent), (1, 3, 1));
    // Nhãn và BMI do BE trả, App chỉ đổi mã sang chữ
    expect(month.kids[0].result!.label, 'Nguy cơ thừa cân');
    expect(month.kids[0].result!.detail, 'BMI 15,9');
    expect(month.kids[1].result, isNull);
  });

  test('loadCampaigns_mapsListLikeWeb', () async {
    final source = LiveHealthMeasureSource(
      ScriptedApi(session, {
        'GET /health-checks': (_) => [
          {
            'id': 3,
            'kind': 'MEASUREMENT',
            'name': 'Kỳ cân đo quý IV',
            'campusName': 'Cơ sở chính - Thượng Hồng',
            'startDate': '2026-11-05',
            'endDate': '2026-11-20',
            'status': 'CLOSED',
            'progress': {
              'total': 28,
              'recorded': 25,
              'bmi': {'thinness': 1, 'obese': 2},
            },
          },
          {
            'id': 4,
            'kind': 'EXAM',
            'name': 'Khám sức khỏe định kỳ',
            'campusName': 'Cơ sở 2',
            'startDate': '2026-10-01',
            'endDate': '2026-10-03',
            'status': 'UPCOMING',
            'progress': {
              'total': 28,
              'recorded': 0,
              'watch': 1,
              'closeWatch': 1,
            },
          },
        ],
      }),
    );

    final list = await source.loadCampaigns();

    expect(list[0].kindLabel, 'Kỳ cân đo');
    expect(list[0].statusLabel, 'Đã đóng');
    expect((list[0].recorded, list[0].total), (25, 28));
    expect(list[0].warningLabel, '3 trẻ có cảnh báo BMI');
    expect(list[1].kindLabel, 'Đợt khám sức khỏe');
    expect(list[1].campusName, 'Cơ sở 2');
    expect(list[1].warningLabel, '2 trẻ cần theo dõi');
  });

  test('loadMonth_noOpenCampaign_returnsEmpty', () async {
    final source = LiveHealthMeasureSource(
      ScriptedApi(session, {campaignsPath: (_) => <Object>[]}),
    );

    final month = await source.loadMonth('12');

    expect(month.kids, isEmpty);
    expect(month.isOpen, isFalse);
  });

  test('loadMonth_otherCampusCampaign404_triesNextCampaign', () async {
    final source = LiveHealthMeasureSource(
      ScriptedApi(session, {
        campaignsPath: (_) => [
          {'id': 2, 'name': 'Kỳ điểm trường khác'},
          {'id': 3, 'name': 'Kỳ cân đo quý IV'},
        ],
        'GET /health-checks/2/classes/12/children': (_) =>
            throw ApiFailure(404, 'Không tìm thấy lớp'),
        'GET /health-checks/3/classes/12/children': (_) => roster(),
      }),
      clock: () => clock,
    );

    final month = await source.loadMonth('12');

    expect(month.title, 'Kỳ cân đo quý IV');
    expect(month.kids, hasLength(3));
  });

  test('saveMeasurement_roundsToOneDecimalForBe', () async {
    Object? sent;
    final source = LiveHealthMeasureSource(
      ScriptedApi(session, routes((_, b) => sent = b)),
      clock: () => clock,
    );
    await source.loadMonth('12');

    await source.saveMeasurement(
      childId: '6',
      height: '99,46',
      weight: '15,04',
    );

    expect(sent, {'campaignId': 3, 'heightCm': 99.5, 'weightKg': 15.0});
  });

  test('saveMeasurement_newChild_postsWithCampaign', () async {
    String? method;
    Object? sent;
    final source = LiveHealthMeasureSource(
      ScriptedApi(
        session,
        routes((m, b) {
          method = m;
          sent = b;
        }),
      ),
      clock: () => clock,
    );
    await source.loadMonth('12');

    await source.saveMeasurement(childId: '6', height: '99,5', weight: '15');

    expect(method, 'POST');
    expect(sent, {'campaignId': 3, 'heightCm': 99.5, 'weightKg': 15.0});
  });

  test('saveMeasurement_existing_putsWithReason', () async {
    String? method;
    Object? sent;
    final source = LiveHealthMeasureSource(
      ScriptedApi(
        session,
        routes((m, b) {
          method = m;
          sent = b;
        }),
      ),
      clock: () => clock,
    );
    await source.loadMonth('12');

    await source.saveMeasurement(
      childId: '5',
      height: '105',
      weight: '17,5',
      note: ' ',
      reason: 'Cân lại',
    );

    expect(method, 'PUT');
    expect(sent, {'heightCm': 105.0, 'weightKg': 17.5, 'reason': 'Cân lại'});
  });
}
