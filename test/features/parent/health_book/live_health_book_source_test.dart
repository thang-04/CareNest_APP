import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/health_book/data/live_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;

  setUp(() => session = FakeLiveSession(['PARENT'], childIds: [5]));

  Future<HealthBook> load(Map<String, Object?> published) =>
      LiveHealthBookSource(
        ScriptedApi(session, {
          'GET /children/5/health/published': (_) => published,
        }),
      ).load('5');

  Map<String, Object?> measurement(int id, String date, {double? height}) => {
    'id': id,
    'date': date,
    'ageMonths': 50,
    'campaignKind': 'MEASUREMENT',
    'campaignName': 'Cân đo tháng 10/2026',
    'heightCm': height,
    'weightKg': 16.2,
    'bmi': 15.4,
    'bmiStatus': 'NORMAL',
    'note': 'Bé hợp tác',
  };

  final exam = <String, Object?>{
    'id': 9,
    'date': '2026-09-20',
    'ageMonths': 49,
    'campaignKind': 'EXAM',
    'campaignName': 'Khám sức khỏe đầu năm',
    'heightCm': 101.0,
    'weightKg': 16.0,
    'followUpLevel': 'CLOSE_WATCH',
    'conclusionCategory': 'REFERRAL',
    'conclusion': {
      'doctorName': 'BS. Lê Hằng',
      'issueText': 'Sâu răng',
      'tbRisk': false,
      'action': 'REFERRAL',
      'adviceText': 'Đưa bé khám răng.',
      'specialty': 'Răng hàm mặt',
      'issueKind': 'NEW',
    },
  };

  test('load_mapsRoundsAndGrowth', () async {
    final book = await load({
      'results': [
        measurement(3, '2026-10-15', height: 102.5),
        // Thiếu chiều cao ⇒ không đủ số đo, không thành kỳ cân đo
        measurement(2, '2026-10-01'),
        exam,
      ],
      'growth': [
        {
          'measurementId': 9,
          'date': '2026-09-20',
          'heightCm': 101.0,
          'weightKg': 16.0,
        },
        {
          'measurementId': 3,
          'date': '2026-10-15',
          'heightCm': 102.5,
          'weightKg': 16.2,
        },
        {
          'measurementId': 2,
          'date': '2026-10-01',
          'heightCm': null,
          'weightKg': 16.1,
        },
      ],
      'interpretation': {
        'period': 'MONTHS_6',
        'summary': 'Tóm tắt',
        'content': {
          'overview': 'Bé tăng cân đều.',
          'attentionPoints': [
            {'warningCode': null, 'text': 'Chiều cao tăng chậm.'},
          ],
          'positives': ['Cân nặng ổn định.'],
          'limitations': null,
        },
        'stale': true,
        'approvedAt': '2026-10-20T03:00:00Z',
      },
    });

    final round = book.rounds.single;
    expect(round.id, '3');
    expect(round.name, 'Cân đo tháng 10/2026');
    expect(round.date, DateTime(2026, 10, 15));
    expect(round.ageMonths, 50);
    expect(round.heightCm, 102.5);
    expect(round.weightKg, 16.2);
    expect(round.bmi, 15.4);
    expect(round.bmiLevel, BmiLevel.normal);
    expect(round.note, 'Bé hợp tác');

    expect(book.growth.map((p) => '${p.date.day}|${p.fromExam}'), [
      '20|true',
      '15|false',
    ]);

    final trend = book.interpretation!;
    expect(trend.periodLabel, 'Phân tích 6 tháng');
    expect(trend.approvedOn, DateTime.utc(2026, 10, 20, 3).toLocal());
    expect(trend.overview, 'Bé tăng cân đều.');
    expect(trend.attention, ['Chiều cao tăng chậm.']);
    expect(trend.positives, ['Cân nặng ổn định.']);
    expect(trend.stale, isTrue);
  });

  test('load_examOnlyConclusion', () async {
    final book = await load({
      'results': [exam],
      'growth': <Object>[],
      'interpretation': null,
    });

    final result = book.exams.single;
    expect(result.id, '9');
    expect(result.name, 'Khám sức khỏe đầu năm');
    expect(result.date, DateTime(2026, 9, 20));
    expect(result.followUp, FollowUpLevel.closeWatch);
    // Cùng mã BE ⇒ cùng nhãn với Web
    expect(result.conclusion, 'Chuyển khám chuyên khoa');
    expect(result.action, 'Chuyển khám chuyên khoa: Răng hàm mặt');
    expect(result.issueText, 'Sâu răng');
    expect(result.issueKind, 'Vấn đề mới hoặc có thay đổi');
    expect(result.advice, 'Đưa bé khám răng.');
    expect(result.doctorName, 'BS. Lê Hằng');
    // API phụ huynh chỉ trả phần kết luận
    expect(result.examiner, isNull);
    expect(result.nutritionStatus, isNull);
    expect(result.history, isEmpty);
    expect(result.vitals, isEmpty);
    expect(result.clinical, isEmpty);
    expect(book.rounds, isEmpty);
    expect(book.interpretation, isNull);
  });

  test('load_examWithoutConclusion_skipped', () async {
    final book = await load({
      'results': [
        {...exam, 'conclusion': null, 'conclusionCategory': null},
      ],
      'growth': <Object>[],
    });

    expect(book.exams, isEmpty);
  });
}
