import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/leave_notice/data/live_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/domain/leave_notice.dart';

import '../../../helpers/live_fakes.dart';

Map<String, Object?> _leave({
  required int id,
  int childId = 5,
  String part = 'FULL_DAY',
  bool? eats,
  List<String> eatsMeals = const [],
  String status = 'ACTIVE',
  String? seenAt,
  String toDate = '2026-11-27',
  String? effectiveTo,
  List<String> skippedDates = const [],
  bool noticeOnly = false,
}) => {
  'id': id,
  'childId': childId,
  'fromDate': '2026-11-27',
  'toDate': toDate,
  'effectiveTo': effectiveTo ?? toDate,
  'skippedDates': skippedDates,
  'noticeOnly': noticeOnly,
  'reason': 'Bé đi khám',
  'status': status,
  'part': part,
  'eats': eats,
  'eatsMeals': eatsMeals,
  'offMeals': <String>[],
  'teacherSeenAt': seenAt,
};

void main() {
  late ScriptedApi api;
  late LiveLeaveNoticeSource source;
  Object? sentBody;

  setUp(() {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    api = ScriptedApi(session, {});
    source = LiveLeaveNoticeSource(api);
    sentBody = null;
  });

  test('loadNotices_filtersChildAndMapsFields', () async {
    api.routes['GET /leave-requests/me'] = (_) => [
      _leave(
        id: 9,
        part: 'AFTERNOON',
        eats: false,
        eatsMeals: ['MORNING', 'LUNCH'],
        seenAt: '2026-11-26T02:00:00Z',
      ),
      _leave(id: 8, childId: 3),
      _leave(id: 7, status: 'CANCELLED'),
    ];

    final notices = await source.loadNotices('5');

    expect(notices.map((n) => n.id), ['9', '7']);
    final first = notices.first;
    expect(first.childId, '5');
    expect(first.from, DateTime(2026, 11, 27));
    expect(first.session, LeaveSession.afternoon);
    expect(first.eats, isFalse);
    expect(first.eatsMeals, [LeaveMeal.morningSnack, LeaveMeal.lunch]);
    expect(first.seenByTeacher, isTrue);
    expect(first.status, LeaveNoticeStatus.submitted);
    expect(notices.last.status, LeaveNoticeStatus.cancelled);
    expect(notices.last.seenByTeacher, isFalse);
  });

  test('submit_postsPartAndEats', () async {
    api.routes['POST /leave-requests'] = (body) {
      sentBody = body;
      return _leave(id: 10, part: 'MORNING', eats: true);
    };

    final notice = await source.submit(
      LeaveNoticeDraft(
        childId: '5',
        from: DateTime(2026, 11, 27),
        to: DateTime(2026, 11, 27),
        session: LeaveSession.morning,
        reason: 'Bé đi khám',
        eats: true,
      ),
    );

    expect(sentBody, {
      'childId': 5,
      'fromDate': '2026-11-27',
      'toDate': '2026-11-27',
      'reason': 'Bé đi khám',
      'part': 'MORNING',
      'eats': true,
    });
    expect(notice.id, '10');
  });

  test('loadMealPlan_mapsPreview', () async {
    api.routes['POST /leave-requests/preview'] = (body) {
      sentBody = body;
      return {
        'part': 'MORNING',
        'offMeals': ['MORNING', 'LUNCH'],
        'keptMeals': ['AFTERNOON'],
        'eatsApplies': true,
        'appliedDates': ['2026-11-27'],
        'skippedDates': <String>[],
      };
    };

    final plan = await source.loadMealPlan(
      '5',
      DateTime(2026, 11, 27),
      LeaveSession.morning,
    );

    expect(plan.offMeals, [LeaveMeal.morningSnack, LeaveMeal.lunch]);
    expect(plan.keptMeals, [LeaveMeal.afternoonSnack]);
    expect(sentBody, {
      'childId': 5,
      'fromDate': '2026-11-27',
      'toDate': '2026-11-27',
      'part': 'MORNING',
    });
  });

  test('loadMealPlan_eatsNotApplies_noKeptMeals', () async {
    api.routes['POST /leave-requests/preview'] = (_) => {
      'part': 'MORNING',
      'offMeals': ['LUNCH'],
      'keptMeals': <String>[],
      'eatsApplies': false,
      'appliedDates': ['2026-11-27'],
      'skippedDates': <String>[],
    };

    final plan = await source.loadMealPlan(
      '5',
      DateTime(2026, 11, 27),
      LeaveSession.morning,
    );

    expect(plan.keptMeals, isEmpty);
  });

  test('submit_4031_keepsBeError', () async {
    api.routes['POST /leave-requests'] = (_) => throw ApiFailure(
      400,
      'Nghỉ buổi sáng hoặc buổi chiều chỉ chọn cho một ngày',
      4031,
    );

    await expectLater(
      source.submit(
        LeaveNoticeDraft(
          childId: '5',
          from: DateTime(2026, 11, 27),
          to: DateTime(2026, 11, 28),
          session: LeaveSession.morning,
          reason: 'x',
        ),
      ),
      throwsA(isA<ApiFailure>().having((e) => e.errorCode, 'code', 4031)),
    );
  });

  test('cancel_patchesAndMapsCancelled (ATT-05)', () async {
    api.routes['PATCH /leave-requests/9/cancel'] = (_) =>
        _leave(id: 9, status: 'CANCELLED');
    final notice = await source.cancel('9');
    expect(api.calls, contains('PATCH /leave-requests/9/cancel'));
    expect(notice.status, LeaveNoticeStatus.cancelled);
  });

  test(
    'ATT-05b: preview after cutoff today ⇒ noticeOnly, no meal change',
    () async {
      api.routes['POST /leave-requests/preview'] = (_) => {
        'offMeals': ['AFTERNOON'],
        'keptMeals': ['MORNING', 'LUNCH'],
        'eatsApplies': true,
        'appliedDates': <String>[],
        'skippedDates': ['2026-11-26'],
        'noticeOnly': true,
      };
      final plan = await source.loadMealPlan(
        '5',
        DateTime(2026, 11, 26),
        LeaveSession.afternoon,
      );
      expect(plan.noticeOnly, isTrue);
    },
  );

  test('ATT-05b: notice maps noticeOnly, effectiveTo, skippedDates', () async {
    api.routes['GET /leave-requests/me'] = (_) => [
      _leave(id: 9, part: 'AFTERNOON', noticeOnly: true),
      _leave(
        id: 8,
        toDate: '2026-11-30',
        effectiveTo: '2026-11-28',
        skippedDates: ['2026-11-27'],
      ),
    ];
    final notices = await source.loadNotices('5');
    expect(notices.first.noticeOnly, isTrue);
    expect(notices.last.effectiveTo, DateTime(2026, 11, 28));
    expect(notices.last.skippedDates, [DateTime(2026, 11, 27)]);
  });

  test('cancel_afterCutoff_surfaces4024', () async {
    api.routes['PATCH /leave-requests/9/cancel'] = (_) => throw ApiFailure(
      409,
      'Các ngày của đơn đã qua giờ chốt, không hủy được',
      4024,
    );
    expect(
      () => source.cancel('9'),
      throwsA(isA<ApiFailure>().having((e) => e.errorCode, 'code', 4024)),
    );
  });
}
