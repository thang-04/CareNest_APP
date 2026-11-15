import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Nguồn dữ liệu đơn xin nghỉ; bản thật gọi API (`leave:create`, chưa có endpoint).
abstract interface class LeaveNoticeSource {
  DateTime get today;
  Future<List<LeaveNotice>> loadNotices(String childId);
  Future<LeaveNotice> submit(LeaveNoticeDraft draft);
  Future<LeaveNotice> cancel(String noticeId);
}

/// Dữ liệu giả theo mockup P04, không phải dữ liệu thật của trẻ. Bé 2 có đơn nhiều ngày đang diễn ra để
/// thử hủy phần còn lại (ATT-04).
class FakeLeaveNoticeSource implements LeaveNoticeSource {
  FakeLeaveNoticeSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
    List<LeaveNotice>? notices,
  }) : _seed = notices;

  /// Một bản dùng chung giữa form và danh sách trong app, để đơn vừa gửi hiện ở danh sách.
  static final shared = FakeLeaveNoticeSource();

  final FakeMode mode;
  final Duration delay;
  final List<LeaveNotice>? _seed;

  late final List<LeaveNotice> _notices = mode == FakeMode.empty
      ? []
      : _seed != null
      ? [for (final notice in _seed) _withCancel(notice)]
      : [
          _withCancel(
            LeaveNotice(
              id: 'leave-4',
              childId: 'child-2',
              from: DateTime(2026, 10, 9),
              to: DateTime(2026, 10, 14),
              reason: 'Về quê cùng gia đình',
              status: LeaveNoticeStatus.submitted,
            ),
          ),
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

  // Luật giả thay BE: còn ngày từ hôm nay trở đi thì hiện nút hủy
  LeaveNotice _withCancel(LeaveNotice notice) => notice.copyWith(
    canCancel:
        notice.status == LeaveNoticeStatus.submitted &&
        !notice.effectiveTo.isBefore(today),
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

  /// Luật giả thay BE `cancelLeaveRequest` (ATT-04): hủy từ ngày đầu tiên chưa qua giờ chốt tới hết đơn;
  /// giả lập hôm nay chưa qua giờ chốt, ngày trước hôm nay đã khóa.
  @override
  Future<LeaveNotice> cancel(String noticeId) async {
    await Future<void>.delayed(delay);
    final index = _notices.indexWhere((notice) => notice.id == noticeId);
    if (index < 0 || _notices[index].status != LeaveNoticeStatus.submitted) {
      throw StateError('Không tìm thấy đơn');
    }
    final notice = _notices[index];
    final first = notice.from.isBefore(today) ? today : notice.from;
    if (first.isAfter(notice.effectiveTo)) {
      throw const LeaveCannotCancelException();
    }
    final cancelled = notice.copyWith(
      status: first == notice.from
          ? LeaveNoticeStatus.cancelled
          : LeaveNoticeStatus.submitted,
      effectiveTo: first.subtract(const Duration(days: 1)),
      canCancel: false,
    );
    _notices[index] = cancelled;
    return cancelled;
  }
}
