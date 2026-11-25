import 'package:flutter/widgets.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

/// Nhãn/tông điểm danh cho người đọc là phụ huynh (DESIGN.md §B4.2).
extension ParentAttendanceStatusView on ParentAttendanceStatus {
  String get label => switch (this) {
    ParentAttendanceStatus.present => 'Có mặt',
    ParentAttendanceStatus.absentExcused => 'Nghỉ có phép',
    ParentAttendanceStatus.absentUnexcused => 'Vắng',
    ParentAttendanceStatus.notRecorded => 'Chưa điểm danh',
    ParentAttendanceStatus.noSchool => 'Không phải ngày học',
    ParentAttendanceStatus.notEnrolled => 'Bé chưa vào lớp',
  };

  AppStatusTone get tone => switch (this) {
    ParentAttendanceStatus.present => AppStatusTone.green,
    ParentAttendanceStatus.absentExcused => AppStatusTone.blue,
    ParentAttendanceStatus.absentUnexcused => AppStatusTone.red,
    ParentAttendanceStatus.notRecorded ||
    ParentAttendanceStatus.noSchool ||
    ParentAttendanceStatus.notEnrolled => AppStatusTone.gray,
  };

  IconData? get icon => switch (this) {
    ParentAttendanceStatus.present => AppIcons.check,
    _ => null,
  };
}

/// Nghỉ một buổi theo đơn (ATT-13): badge là trạng thái buổi còn lại, dòng này nói buổi nghỉ.
extension AbsentPartView on AbsentPart {
  String get label => switch (this) {
    AbsentPart.morning => 'Nghỉ buổi sáng theo đơn',
    AbsentPart.afternoon => 'Nghỉ buổi chiều theo đơn',
  };
}
