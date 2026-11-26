import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/teacher/pickup/data/live_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  final session = FakeLiveSession(['TEACHER']);

  Map<String, Object?> waitingRow() => {
    'child': {'id': 5, 'code': 'C5', 'fullName': 'Nguyễn Minh Anh'},
    'attendanceStatus': 'PRESENT',
    'status': 'WAITING',
    'pickup': null,
    'attempts': <Object>[],
  };

  test('loadBoard_mapsRowsAndPickup', () async {
    final api = ScriptedApi(session, {
      'GET /classes/12/pickups': (_) => {
        'classId': 12,
        'date': '2026-11-25',
        'today': '2026-11-25',
        'rows': [
          waitingRow(),
          {
            'child': {'id': 6, 'fullName': 'Lê Hoàng Nam'},
            'status': 'PICKED_UP',
            'pickup': {
              'verification': 'PHOTO_MATCH',
              'guardianPosition': 1,
              'pickupPersonName': 'Lê Thị Mai',
              'pickupPersonRelationship': 'MOTHER',
              'handedOverAt': '2026-11-25T09:30:00Z',
              'note': null,
            },
          },
        ],
      },
    });

    final board = await LivePickupSource(api).loadBoard('12');
    final rows = board.rows;

    expect(board.canRecord, isTrue);
    expect(rows[0].childId, '5');
    expect(rows[0].status, PickupStatus.waiting);
    expect(rows[0].pickup, isNull);
    expect(rows[1].status, PickupStatus.pickedUp);
    expect(rows[1].pickup!.verification, PickupVerification.photoMatch);
    expect(
      rows[1].pickup!.pickupPersonRelationship,
      GuardianRelationship.mother,
    );
    expect(rows[1].pickup!.handedOverAt!.toUtc().hour, 9);
  });

  test('loadBoard_sendsDateAndMapsAttempts_notToday', () async {
    final api = ScriptedApi(session, {
      'GET /classes/12/pickups?date=2026-11-20': (_) => {
        'date': '2026-11-20',
        'today': '2026-11-25',
        'rows': [
          {
            ...waitingRow(),
            'attempts': [
              {'verification': 'PHONE_DECLINED', 'note': 'Không giao'},
              {'verification': 'PHONE_UNREACHABLE'},
            ],
          },
        ],
      },
    });

    final board = await LivePickupSource(
      api,
    ).loadBoard('12', date: DateTime(2026, 11, 20));

    expect(board.canRecord, isFalse);
    expect(board.rows.single.code, 'C5');
    expect(board.rows.single.failedAttempts, 2);
    expect(
      board.rows.single.attempts.last.verification,
      PickupVerification.phoneUnreachable,
    );
  });

  test('loadResults_mapsRecords', () async {
    final api = ScriptedApi(session, {
      'GET /pickups': (_) => [
        {
          'childName': 'Lê Hoàng Nam',
          'className': 'Mầm 3A',
          'verification': 'PHONE_DECLINED',
          'note': 'Không giao',
          'recordedAt': '2026-11-25T09:30:00Z',
        },
      ],
    });

    final results = await LivePickupSource(api).loadResults();

    expect(results.single.childName, 'Lê Hoàng Nam');
    expect(results.single.verification.handedOver, isFalse);
    expect(results.single.recordedAt, isNotNull);
  });

  test('loadChild_mapsGuardiansWithoutPhoto', () async {
    final api = ScriptedApi(session, {
      'GET /pickups/children/5': (_) => {
        'row': waitingRow(),
        'classId': 12,
        'className': 'Mầm 3A',
        'guardians': [
          {
            'position': 1,
            'fullName': 'Trần Thu Lan',
            'relationship': 'MOTHER',
            'phone': '0900000001',
            'photoUrl': '/files/g1',
          },
          {
            'position': 2,
            'fullName': 'Nguyễn Văn Hùng',
            'relationship': 'FATHER',
            'phone': '0900000002',
            'photoUrl': null,
          },
        ],
      },
    });

    final child = await LivePickupSource(api).loadChild('5');

    expect(child.className, 'Mầm 3A');
    expect(child.guardians, hasLength(2));
    expect(child.guardians[0].photoUrl, '/files/g1');
    expect(child.guardians[1].photoUrl, isNull);
    expect(child.guardians[1].relationship, GuardianRelationship.father);
  });

  test('record_postsBodyWithoutNullFields', () async {
    Object? sent;
    final api = ScriptedApi(session, {
      'POST /pickups': (body) {
        sent = body;
        return <String, Object?>{};
      },
    });

    await LivePickupSource(api).record(
      const PickupRequest(
        childId: '5',
        verification: PickupVerification.phoneDeclined,
        note: 'Không khớp người đón',
      ),
    );

    expect(sent, {
      'childId': 5,
      'verification': 'PHONE_DECLINED',
      'note': 'Không khớp người đón',
    });
    expect(api.calls, ['POST /pickups']);
  });
}
