import 'package:flutter/widgets.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';

/// Nhãn/tông điểm danh cho người đọc là phụ huynh (DESIGN.md §6.2).
extension ParentAttendanceStatusView on ParentAttendanceStatus {
  String get label => switch (this) {
    ParentAttendanceStatus.present => 'Có mặt',
    ParentAttendanceStatus.absentExcused => 'Nghỉ có phép',
    ParentAttendanceStatus.absentUnexcused => 'Vắng',
    ParentAttendanceStatus.notRecorded => 'Chưa điểm danh',
  };

  AppStatusTone get tone => switch (this) {
    ParentAttendanceStatus.present => AppStatusTone.green,
    ParentAttendanceStatus.absentExcused => AppStatusTone.blue,
    ParentAttendanceStatus.absentUnexcused => AppStatusTone.red,
    ParentAttendanceStatus.notRecorded => AppStatusTone.gray,
  };

  IconData? get icon => switch (this) {
    ParentAttendanceStatus.present => AppIcons.check,
    _ => null,
  };
}
