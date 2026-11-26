abstract final class RoutePaths {
  static const login = '/login';

  /// Chỉ có khi chạy với BE thật (`USE_MOCK=false`): chờ khôi phục phiên, kích hoạt tài khoản,
  /// tài khoản không dùng được trên App.
  static const splash = '/splash';
  static const activate = '/activate';
  static const blocked = '/blocked';

  /// Phiên thật (PR #8): lối vào cố định cho đăng nhập và push, tài khoản chỉ dùng Web.
  static const liveNotifications = '/live/notifications';
  static const liveUnsupported = '/live/unsupported';

  /// Luồng quên mật khẩu có ở cả bản release; chưa nối máy chủ thì màn tự báo.
  static const forgotPassword =
      '/forgot-password'; // carenest:allow-secret — đường dẫn route, không phải mật khẩu
  static const otpSegment = 'otp';
  static const newPasswordSegment = 'new-password';
  static const forgotPasswordOtp = '$forgotPassword/$otpSegment';
  static const forgotPasswordNew = '$forgotPassword/$newPasswordSegment';

  /// Màn con của tab Tài khoản (mọi vai trò).
  static const profileSegment = 'profile';
  static const passwordSegment = 'password';

  /// Chỉ đăng ký khi bật xem thử (debug) — docs/architecture/NAVIGATION.md.
  static const preview = '/preview';

  static const parentToday = '/parent';
  static const parentChild = '/parent/child';
  static const parentNotifications = '/parent/notifications';
  static const parentAccount = '/parent/account';
  static const parentLeaveNotices = '/parent/leave-notices';
  static const parentLeaveNew = '/parent/leave-notices/new';
  static const parentMenu = '/parent/menu';
  static const parentActivities = '/parent/activities';
  static const parentAttendance = '/parent/attendance';

  /// Sổ sức khỏe (Kỳ cân đo | Đợt khám | Xu hướng); ID con ở query như các màn con khác.
  static const parentHealthBook = '/parent/health';
  static const parentHealthExams = '$parentHealthBook/exams';

  /// Chi tiết một đợt khám: ID đợt trên đường dẫn, ID con ở query.
  static String parentHealthExam(String examId, {required String childId}) =>
      withChild('$parentHealthExams/$examId', childId);

  /// Trang Đánh giá (Ngày | Tuần | Chủ đề | Học kỳ | Cuối năm); ID con ở query.
  static const parentEvaluation = '/parent/evaluation';
  static const parentEvaluationThemes = '$parentEvaluation/themes';

  /// Kết quả một chủ đề: ID chủ đề trên đường dẫn, ID con ở query.
  static String parentEvaluationTheme(
    String themeId, {
    required String childId,
  }) => withChild('$parentEvaluationThemes/$themeId', childId);

  /// Trang Khen thưởng (Tuần | Tháng | Cuối năm); ID con ở query.
  static const parentRewards = '/parent/rewards';

  static const teacherToday = '/teacher';
  static const teacherClass = '/teacher/class';
  static const teacherNotifications = '/teacher/notifications';
  static const teacherAccount = '/teacher/account';
  static const teacherAttendance = '/teacher/attendance';
  static const teacherDailyHealth = '/teacher/daily-health';
  static const teacherAttendanceSummary = '/teacher/attendance/summary';
  static const teacherLeaveNotices = '/teacher/leave-notices';
  static const teacherReviews = '/teacher/reviews';
  static const teacherMenu = '/teacher/menu';
  static const teacherRewards = '/teacher/rewards';
  static const teacherPickup = '/teacher/pickup';
  static const teacherHealth = '/teacher/health';
  static const teacherSchedule = '/teacher/schedule';

  /// Màn chi tiết theo trẻ của Giáo viên: `<danh sách>/<childId>`.
  static String kidDetail(String listPath, String childId) =>
      '$listPath/$childId';

  static const kitchenHome = '/kitchen';
  static const kitchenMenu = '/kitchen/menu';
  static const kitchenNotifications = '/kitchen/notifications';
  static const kitchenAccount = '/kitchen/account';
  static const kitchenMeals = '/kitchen/meals';
  static const kitchenQuantities = '/kitchen/quantities';
  static const kitchenPhotos = '/kitchen/photos';
  static const kitchenSamples = '/kitchen/samples';

  static const vicePrincipalHome = '/vice-principal';
  static const vicePrincipalApprovals = '/vice-principal/approvals';
  static const vicePrincipalNotifications = '/vice-principal/notifications';
  static const vicePrincipalAccount = '/vice-principal/account';
  static const vicePrincipalAdjustments = '/vice-principal/approvals/meals';
  static const vicePrincipalRewards = '/vice-principal/approvals/rewards';
  static const vicePrincipalMealConfirm = '/vice-principal/meal-confirm';
  static const vicePrincipalKitchen = '/vice-principal/kitchen';
  static const vicePrincipalMenu = '/vice-principal/menu';
  static const vicePrincipalNutrition = '/vice-principal/menu/nutrition';
  static const vicePrincipalChildren = '/vice-principal/children';

  /// Chi tiết yêu cầu điều chỉnh suất: chỉ mang ID, dữ liệu tải lại.
  static String vicePrincipalAdjustment(String id) =>
      '$vicePrincipalAdjustments/$id';

  /// Cân đối dinh dưỡng theo nhóm tuổi + ngày đang chọn (ngữ cảnh ở query, không phải dữ liệu).
  static String vicePrincipalNutritionOf(String groupId, DateTime day) => Uri(
    path: vicePrincipalNutrition,
    queryParameters: {'group': groupId, 'day': _isoDay(day)},
  ).toString();

  static const principalHome = '/principal';
  static const principalApprovals = '/principal/approvals';
  static const principalNotifications = '/principal/notifications';
  static const principalAccount = '/principal/account';
  static const principalRewardBatches = '/principal/approvals/rewards';
  static const principalChildren = '/principal/children';
  static const principalClassChildren = '/principal/children/class';
  static const principalMenu = '/principal/menu';
  static const principalCampuses = '/principal/campuses';
  static const principalNutrition = '/principal/menu/nutrition';

  /// Cân đối dinh dưỡng của một cơ sở + nhóm tuổi + ngày (ngữ cảnh ở query).
  static String principalNutritionOf(
    String campusId,
    String groupId,
    DateTime day,
  ) => Uri(
    path: principalNutrition,
    queryParameters: {
      'campus': campusId,
      'group': groupId,
      'day': _isoDay(day),
    },
  ).toString();

  static String _isoDay(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  /// Đợt đề xuất khen thưởng: chỉ mang ID, dữ liệu tải lại.
  static String principalRewardBatch(String id) =>
      '$principalRewardBatches/$id';

  /// Trẻ một lớp: cơ sở + lớp là ngữ cảnh ở query.
  static String principalClassChildrenOf(String campusId, String classId) =>
      Uri(
        path: principalClassChildren,
        queryParameters: {'campus': campusId, 'class': classId},
      ).toString();

  /// Màn con của phụ huynh chỉ mang ID con trong query, dữ liệu tải lại theo ID.
  static String withChild(String path, String childId) =>
      Uri(path: path, queryParameters: {'child': childId}).toString();
}
