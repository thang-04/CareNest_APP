import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';

/// Không có trạng thái chờ duyệt (ATT-05, DESIGN.md §6.2): chỉ GV đã xem / chưa xem / đã huỷ.
extension LeaveNoticeView on LeaveNotice {
  String get statusLabel => switch (status) {
    LeaveNoticeStatus.cancelled => 'Đã huỷ',
    _ when seenByTeacher => 'GV đã xem',
    _ => 'GV chưa xem',
  };

  AppStatusTone get statusTone => switch (status) {
    LeaveNoticeStatus.cancelled => AppStatusTone.gray,
    _ when seenByTeacher => AppStatusTone.green,
    _ => AppStatusTone.approval,
  };

  /// "13/10/2026 · Cả ngày" hoặc "11/10 – 13/10/2026 · Cả ngày"
  String get periodLabel => '${DateLabels.range(from, to)} · ${session.label}';
}

extension LeaveSessionView on LeaveSession {
  String get label => switch (this) {
    LeaveSession.fullDay => 'Cả ngày',
    LeaveSession.morning => 'Buổi sáng',
    LeaveSession.afternoon => 'Buổi chiều',
  };
}
