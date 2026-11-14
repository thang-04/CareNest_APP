import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/leave_notice/domain/leave_notice.dart';

/// Không có trạng thái chờ duyệt hay GV đã xem (ATT-05): đã gửi / đã hủy / hủy phần còn lại (ATT-04).
extension LeaveNoticeView on LeaveNotice {
  String get statusLabel => switch (status) {
    LeaveNoticeStatus.submitted when isPartlyCancelled =>
      'Hủy từ ${DateLabels.dayMonth(effectiveTo.add(const Duration(days: 1)))}',
    LeaveNoticeStatus.submitted => 'Đã gửi',
    LeaveNoticeStatus.cancelled => 'Đã hủy',
  };

  AppStatusTone get statusTone => switch (status) {
    LeaveNoticeStatus.submitted when isPartlyCancelled => AppStatusTone.orange,
    LeaveNoticeStatus.submitted => AppStatusTone.green,
    LeaveNoticeStatus.cancelled => AppStatusTone.gray,
  };

  /// "13/10/2026" hoặc "11/10 – 13/10/2026"
  String get periodLabel => DateLabels.range(from, to);

  /// Hủy phần còn lại: các ngày đầu vẫn Vắng có phép (BE `effectiveTo`).
  String? get remainingLabel => isPartlyCancelled
      ? 'Vẫn nghỉ có phép: ${DateLabels.range(from, effectiveTo)}'
      : null;
}
