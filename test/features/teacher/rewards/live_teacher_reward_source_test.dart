import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/teacher/rewards/data/live_teacher_reward_source.dart';
import 'package:carenest_app/features/teacher/rewards/domain/teacher_rewards.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  test('load_mapsClassDetail', () async {
    final api = ScriptedApi(FakeLiveSession(['TEACHER']), {
      'GET /assessment/reward-lists/classes/12': (_) => {
        'className': 'Mầm 3A',
        'schoolYearId': 2,
        'status': 'DRAFT',
        'titleOptions': ['Bé ngoan', 'Bé chăm'],
        'children': [
          {
            'childId': 5,
            'fullName': 'Nguyễn Minh Anh',
            'schoolDays': 100,
            'presentDays': 96.5,
            'weeklyTickets': 4,
            'monthlyTickets': 1,
            'suggested': ['Bé chăm'],
            'titles': <String>[],
            'note': null,
          },
        ],
      },
      'GET /school-years': (_) => [
        {'id': 2, 'name': '2026-2027'},
      ],
    });
    final data = await LiveTeacherRewardSource(api).load('12');
    expect(data.className, 'Mầm 3A');
    expect(data.schoolYearLabel, '2026–2027');
    expect(data.status, RewardStatus.draft);
    expect(data.titleOptions, ['Bé ngoan', 'Bé chăm']);
    final kid = data.children.single;
    expect(kid.childId, '5');
    expect(kid.presentDays, 97);
    expect(kid.suggested, ['Bé chăm']);
    expect(kid.note, '');
  });
}
