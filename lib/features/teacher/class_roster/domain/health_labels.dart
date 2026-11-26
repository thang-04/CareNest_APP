import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Nhãn và tông hiển thị cho mã BE (cùng nhãn, tông với Web); APP không tự xếp loại.
typedef HealthLabel = ({String label, AppStatusTone tone});

/// `bmiStatus` BE (HLT-18).
HealthLabel? bmiStatusLabel(Object? code) => switch (code) {
  'SEVERE_THINNESS' => (label: 'Gầy còm nặng', tone: AppStatusTone.red),
  'THINNESS' => (label: 'Gầy còm', tone: AppStatusTone.orange),
  'NORMAL' => (label: 'Bình thường', tone: AppStatusTone.green),
  'OVERWEIGHT_RISK' => (label: 'Nguy cơ thừa cân', tone: AppStatusTone.orange),
  'OVERWEIGHT' => (label: 'Thừa cân', tone: AppStatusTone.orange),
  'OBESE' => (label: 'Béo phì', tone: AppStatusTone.red),
  _ => null,
};

/// `followUpLevel` BE (kết luận bác sĩ của đợt khám, HLT-10).
HealthLabel? followUpLabel(Object? code) => switch (code) {
  'NONE' => (label: 'Không ghi nhận bất thường', tone: AppStatusTone.green),
  'KNOWN_STABLE' => (
    label: 'Vấn đề đã biết, ổn định',
    tone: AppStatusTone.gray,
  ),
  'WATCH' => (label: 'Cần theo dõi', tone: AppStatusTone.orange),
  'CLOSE_WATCH' => (label: 'Cần theo dõi sát', tone: AppStatusTone.red),
  'UNAVAILABLE' => (label: 'Chưa có kết luận bác sĩ', tone: AppStatusTone.gray),
  _ => null,
};

/// `HealthCheckKind` BE.
String campaignKindLabel(Object? code) =>
    code == 'MEASUREMENT' ? 'Kỳ cân đo' : 'Đợt khám sức khỏe';

/// `HealthCheckStatus` BE.
HealthLabel campaignStatusLabel(Object? code) => switch (code) {
  'UPCOMING' => (label: 'Sắp diễn ra', tone: AppStatusTone.blue),
  'IN_PROGRESS' => (label: 'Đang diễn ra', tone: AppStatusTone.green),
  'CLOSED' => (label: 'Đã đóng', tone: AppStatusTone.gray),
  'CANCELLED' => (label: 'Đã hủy', tone: AppStatusTone.gray),
  _ => (label: '', tone: AppStatusTone.gray),
};
