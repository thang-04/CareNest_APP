import 'package:carenest_app/features/parent/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Nguồn dữ liệu đơn xin nghỉ; bản thật gọi BE `POST /leave-requests`, `GET /leave-requests/me`.
abstract interface class LeaveNoticeSource {
  DateTime get today;
  Future<List<LeaveNotice>> loadNotices(String childId);
  Future<LeaveNotice> submit(LeaveNoticeDraft draft);

  /// Bữa bị huỷ / bữa còn học của ngày nghỉ nửa buổi. BE chưa có API trả bữa nhóm tuổi trước
  /// khi gửi đơn (chỉ có `eatsMeals` sau khi tạo) ⇒ bản thật cần BE bổ sung.
  Future<LeaveMealPlan> loadMealPlan(
    String childId,
    DateTime date,
    LeaveSession session,
  );
}

/// Dữ liệu giả theo mockup P04, không phải dữ liệu thật của trẻ.
class FakeLeaveNoticeSource implements LeaveNoticeSource {
  FakeLeaveNoticeSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
  });

  /// Một bản dùng chung giữa form và danh sách trong app, để đơn vừa gửi hiện ở danh sách.
  static final shared = FakeLeaveNoticeSource();

  final FakeMode mode;
  final Duration delay;

  late final List<LeaveNotice> _notices = mode == FakeMode.empty
      ? []
      : [
          LeaveNotice(
            id: 'leave-3',
            childId: 'child-1',
            from: DateTime(2026, 10, 13),
            to: DateTime(2026, 10, 13),
            session: LeaveSession.fullDay,
            reason: 'Khám răng định kỳ',
            status: LeaveNoticeStatus.submitted,
          ),
          LeaveNotice(
            id: 'leave-2',
            childId: 'child-1',
            from: DateTime(2026, 9, 28),
            to: DateTime(2026, 9, 28),
            session: LeaveSession.afternoon,
            reason: 'Bé sốt nhẹ',
            status: LeaveNoticeStatus.submitted,
            seenByTeacher: true,
            eats: true,
            eatsMeals: [LeaveMeal.morningSnack, LeaveMeal.lunch],
          ),
          LeaveNotice(
            id: 'leave-1',
            childId: 'child-1',
            from: DateTime(2026, 9, 15),
            to: DateTime(2026, 9, 15),
            session: LeaveSession.fullDay,
            reason: 'Việc gia đình',
            status: LeaveNoticeStatus.submitted,
            seenByTeacher: true,
          ),
        ];

  @override
  DateTime get today => FakeParentHomeSource.today;

  @override
  Future<List<LeaveNotice>> loadNotices(String childId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) {
      throw StateError('Không tải được dữ liệu giả');
    }
    return _notices.where((notice) => notice.childId == childId).toList();
  }

  @override
  Future<LeaveMealPlan> loadMealPlan(
    String childId,
    DateTime date,
    LeaveSession session,
  ) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) {
      throw StateError('Không tải được dữ liệu giả');
    }
    return _mealPlan(session);
  }

  /// Giả lập cách BE chia (ATT-12): buổi sáng = Phụ sáng + Trưa, buổi chiều = Xế; nhóm tuổi giả có đủ 3 bữa.
  LeaveMealPlan _mealPlan(LeaveSession session) {
    const morning = [LeaveMeal.morningSnack, LeaveMeal.lunch];
    const afternoon = [LeaveMeal.afternoonSnack];
    return switch (session) {
      LeaveSession.fullDay => const LeaveMealPlan(
        offMeals: [...morning, ...afternoon],
        keptMeals: [],
      ),
      LeaveSession.morning => const LeaveMealPlan(
        offMeals: morning,
        keptMeals: afternoon,
      ),
      LeaveSession.afternoon => const LeaveMealPlan(
        offMeals: afternoon,
        keptMeals: morning,
      ),
    };
  }

  @override
  Future<LeaveNotice> submit(LeaveNoticeDraft draft) async {
    await Future<void>.delayed(delay);
    final kept = _mealPlan(draft.session).keptMeals;
    final notice = LeaveNotice(
      id: 'leave-${_notices.length + 1}',
      childId: draft.childId,
      from: draft.from,
      to: draft.to,
      session: draft.session,
      reason: draft.reason,
      status: LeaveNoticeStatus.submitted,
      eats: kept.isEmpty ? null : (draft.eats ?? true),
      eatsMeals: kept,
    );
    _notices.insert(0, notice);
    return notice;
  }
}
