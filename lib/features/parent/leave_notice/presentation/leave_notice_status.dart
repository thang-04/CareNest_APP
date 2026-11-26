import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/leave_notice/domain/leave_notice.dart';

/// Không có trạng thái chờ duyệt (ATT-05, DESIGN.md §B4.2): chỉ GV đã xem / chưa xem / đã huỷ.
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

  /// Ghi chú thêm theo BE (ATT-05b): đơn chỉ báo cô giáo, ngày đã qua giờ chốt, huỷ một phần.
  List<String> get notes => [
    if (noticeOnly) 'Chỉ báo cô giáo (gửi sau giờ chốt)',
    if (!noticeOnly && skippedDates.isNotEmpty)
      'Ngày ${skippedDates.map(DateLabels.dayMonth).join(', ')} '
          'đã qua giờ chốt khi gửi: giữ nguyên điểm danh',
    if (status == LeaveNoticeStatus.submitted && lastDay.isBefore(to))
      'Hiệu lực tới ${DateLabels.dayMonth(lastDay)} (đã huỷ phần còn lại)',
  ];

  /// Dòng bữa ăn của đơn nửa buổi theo `eats` BE trả; cả ngày hoặc không áp dụng ⇒ null.
  String? get mealLabel {
    final value = eats;
    if (value == null || eatsMeals.isEmpty) return null;
    final meals = eatsMeals.labels;
    return value ? 'Bé ăn bữa $meals ở trường' : 'Bé không ăn bữa $meals';
  }
}

extension LeaveMealView on LeaveMeal {
  String get label => switch (this) {
    LeaveMeal.morningSnack => 'Phụ sáng',
    LeaveMeal.lunch => 'Trưa',
    LeaveMeal.afternoonSnack => 'Xế',
  };
}

extension LeaveMealListView on List<LeaveMeal> {
  /// "Phụ sáng, Trưa"
  String get labels => map((meal) => meal.label).join(', ');
}

extension LeaveSessionView on LeaveSession {
  String get label => switch (this) {
    LeaveSession.fullDay => 'Cả ngày',
    LeaveSession.morning => 'Buổi sáng',
    LeaveSession.afternoon => 'Buổi chiều',
  };
}
