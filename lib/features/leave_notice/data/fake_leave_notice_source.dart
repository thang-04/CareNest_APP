import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Nguồn dữ liệu đơn xin nghỉ; bản thật gọi API (`leave:create`, chưa có endpoint).
abstract interface class LeaveNoticeSource {
  DateTime get today;
  Future<List<LeaveNotice>> loadNotices(String childId);
  Future<LeaveNotice> submit(LeaveNoticeDraft draft);
  Future<LeaveNotice> cancel(String noticeId);
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
          _withCancel(
            LeaveNotice(
              id: 'leave-3',
              childId: 'child-1',
              from: DateTime(2026, 10, 13),
              to: DateTime(2026, 10, 13),
              reason: 'Khám răng định kỳ',
              status: LeaveNoticeStatus.submitted,
            ),
          ),
          LeaveNotice(
            id: 'leave-2',
            childId: 'child-1',
            from: DateTime(2026, 9, 28),
            to: DateTime(2026, 9, 28),
            reason: 'Bé sốt nhẹ',
            status: LeaveNoticeStatus.submitted,
          ),
          LeaveNotice(
            id: 'leave-1',
            childId: 'child-1',
            from: DateTime(2026, 9, 15),
            to: DateTime(2026, 9, 15),
            reason: 'Việc gia đình',
            status: LeaveNoticeStatus.cancelled,
          ),
        ];

  @override
  DateTime get today => FakeParentHomeSource.today;

  // Luật giả thay BE: còn hủy được khi ngày bắt đầu sau hôm nay
  LeaveNotice _withCancel(LeaveNotice notice) => notice.copyWith(
    canCancel:
        notice.status == LeaveNoticeStatus.submitted &&
        notice.from.isAfter(today),
  );

  @override
  Future<List<LeaveNotice>> loadNotices(String childId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) {
      throw StateError('Không tải được dữ liệu giả');
    }
    return _notices.where((notice) => notice.childId == childId).toList();
  }

  @override
  Future<LeaveNotice> submit(LeaveNoticeDraft draft) async {
    await Future<void>.delayed(delay);
    final notice = _withCancel(
      LeaveNotice(
        id: 'leave-${_notices.length + 1}',
        childId: draft.childId,
        from: draft.from,
        to: draft.to,
        reason: draft.reason,
        status: LeaveNoticeStatus.submitted,
      ),
    );
    _notices.insert(0, notice);
    return notice;
  }

  @override
  Future<LeaveNotice> cancel(String noticeId) async {
    await Future<void>.delayed(delay);
    final index = _notices.indexWhere((notice) => notice.id == noticeId);
    if (index < 0 || !_notices[index].canCancel) {
      throw StateError('Đơn không còn hủy được');
    }
    final cancelled = _notices[index].copyWith(
      status: LeaveNoticeStatus.cancelled,
      canCancel: false,
    );
    _notices[index] = cancelled;
    return cancelled;
  }
}
