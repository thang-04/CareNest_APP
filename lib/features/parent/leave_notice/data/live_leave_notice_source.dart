import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/domain/leave_notice.dart';

/// Đơn xin nghỉ từ BE (ATT-04, ATT-05, ATT-12): `GET /leave-requests/me`, `POST /leave-requests`,
/// `POST /leave-requests/preview` (bữa bị huỷ / bữa còn học của đơn nửa buổi).
class LiveLeaveNoticeSource implements LeaveNoticeSource {
  LiveLeaveNoticeSource(this._api);

  final MobileApi _api;

  @override
  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Future<List<LeaveNotice>> loadNotices(String childId) async {
    final data = await _api.json('GET', '/leave-requests/me');
    return [
      for (final item in (data as List? ?? const []).whereType<Map>())
        if ('${item['childId']}' == childId) _notice(item),
    ];
  }

  @override
  Future<LeaveNotice> cancel(String noticeId) async {
    final data = await _api.json('PATCH', '/leave-requests/$noticeId/cancel');
    return _notice(data! as Map);
  }

  @override
  Future<LeaveNotice> submit(LeaveNoticeDraft draft) async {
    final data = await _api.json(
      'POST',
      '/leave-requests',
      body: {
        ..._range(draft.childId, draft.from, draft.to),
        'reason': draft.reason,
        'part': _part(draft.session),
        'eats': ?draft.eats,
      },
    );
    return _notice(data! as Map);
  }

  @override
  Future<LeaveMealPlan> loadMealPlan(
    String childId,
    DateTime date,
    LeaveSession session,
  ) async {
    final data =
        await _api.json(
              'POST',
              '/leave-requests/preview',
              body: {..._range(childId, date, date), 'part': _part(session)},
            )
            as Map;
    return LeaveMealPlan(
      noticeOnly: data['noticeOnly'] == true,
      offMeals: _meals(data['offMeals']),
      // eatsApplies false ⇒ buổi còn học không có bữa của nhóm tuổi, không hỏi ăn
      keptMeals: data['eatsApplies'] == true
          ? _meals(data['keptMeals'])
          : const [],
    );
  }

  static Map<String, Object?> _range(
    String childId,
    DateTime from,
    DateTime to,
  ) => {
    'childId': int.parse(childId),
    'fromDate': apiDate(from),
    'toDate': apiDate(to),
  };

  static String _part(LeaveSession session) => switch (session) {
    LeaveSession.fullDay => 'FULL_DAY',
    LeaveSession.morning => 'MORNING',
    LeaveSession.afternoon => 'AFTERNOON',
  };

  static List<LeaveMeal> _meals(Object? codes) => [
    for (final code in codes as List? ?? const [])
      ?switch (code) {
        'MORNING' => LeaveMeal.morningSnack,
        'LUNCH' => LeaveMeal.lunch,
        'AFTERNOON' => LeaveMeal.afternoonSnack,
        _ => null,
      },
  ];

  static LeaveNotice _notice(Map<Object?, Object?> item) => LeaveNotice(
    id: '${item['id']}',
    childId: '${item['childId']}',
    from: DateTime.parse(item['fromDate']! as String),
    to: DateTime.parse(item['toDate']! as String),
    session: switch (item['part']) {
      'MORNING' => LeaveSession.morning,
      'AFTERNOON' => LeaveSession.afternoon,
      _ => LeaveSession.fullDay,
    },
    reason: item['reason']?.toString() ?? '',
    status: item['status'] == 'CANCELLED'
        ? LeaveNoticeStatus.cancelled
        : LeaveNoticeStatus.submitted,
    seenByTeacher: item['teacherSeenAt'] != null,
    eats: item['eats'] as bool?,
    eatsMeals: _meals(item['eatsMeals']),
    noticeOnly: item['noticeOnly'] == true,
    effectiveTo: switch (item['effectiveTo']) {
      final String date => DateTime.parse(date),
      _ => null,
    },
    skippedDates: [
      for (final date in item['skippedDates'] as List? ?? const [])
        DateTime.parse('$date'),
    ],
  );
}
