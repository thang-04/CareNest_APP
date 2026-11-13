import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';

/// Không có trạng thái chờ duyệt hay GV đã xem (ATT-05): chỉ đã gửi / đã hủy.
extension LeaveNoticeView on LeaveNotice {
  String get statusLabel => switch (status) {
    LeaveNoticeStatus.submitted => 'Đã gửi',
    LeaveNoticeStatus.cancelled => 'Đã hủy',
  };

  AppStatusTone get statusTone => switch (status) {
    LeaveNoticeStatus.submitted => AppStatusTone.green,
    LeaveNoticeStatus.cancelled => AppStatusTone.gray,
  };

  /// "13/10/2026" hoặc "11/10 – 13/10/2026"
  String get periodLabel => DateLabels.range(from, to);
}
