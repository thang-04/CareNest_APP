import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance_summary.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/domain/class_leave_notice.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/child_health.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_teacher_classes.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/teacher/health_measure/domain/health_measure.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';
import 'package:carenest_app/features/teacher/rewards/domain/teacher_rewards.dart';
import 'package:carenest_app/features/teacher/school_year/domain/school_year.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';
import 'package:carenest_app/features/teacher/teacher_home/domain/teacher_today.dart';
import 'package:flutter/material.dart';

/// Nguồn dữ liệu các màn giáo viên. Mặc định (Xem thử) mọi nguồn null ⇒ màn dùng bản giả;
/// phiên thật truyền bản gọi BE (`Live…Source`), `live: true` và [loadClass].
class TeacherSources {
  const TeacherSources({
    this.live = false,
    this.loadClasses,
    this.loadYearClasses,
    this.home,
    this.roster,
    this.attendance,
    this.attendanceSummary,
    this.childHealth,
    this.dailyHealth,
    this.pickup,
    this.leave,
    this.measure,
    this.review,
    this.evaluation,
    this.rewards,
  });

  /// Phiên thật: màn chưa có API ở BE (lịch hoạt động, thực đơn) hiện "Sắp có".
  final bool live;

  /// Lớp giáo viên xem được (GET /attendance/classes); lớp `teaches` xếp trước. Chọn lớp đầu có `teaches`.
  final Future<List<TeacherClass>> Function()? loadClasses;

  /// Như [loadClasses] nhưng theo năm học đang chọn (`schoolYearId` null ⇒ năm đang chạy); ưu tiên hơn [loadClasses].
  final Future<List<TeacherClass>> Function(String? schoolYearId)?
  loadYearClasses;
  final TeacherHomeSource? home;
  final ClassRosterSource? roster;
  final AttendanceSource? attendance;
  final AttendanceSummarySource? attendanceSummary;
  final ChildHealthSource? childHealth;
  final DailyHealthSource? dailyHealth;
  final PickupSource? pickup;
  final ClassLeaveSource? leave;
  final HealthMeasureSource? measure;
  final DailyReviewSource? review;
  final EvaluationSource? evaluation;
  final TeacherRewardSource? rewards;
}

/// Chờ lớp của giáo viên rồi mới dựng màn; bản giả dùng lớp giả, không gọi mạng.
/// Đổi năm học ([SelectedSchoolYear]) ⇒ tải lại lớp của năm đó và dựng lại màn; năm không phải năm đang chạy ⇒ chỉ xem.
class TeacherClassGate extends StatefulWidget {
  const TeacherClassGate({
    super.key,
    required this.sources,
    required this.builder,
  });

  final TeacherSources sources;

  /// `classId` = lớp mặc định; `classes` = mọi lớp chọn được trên thanh Lớp · Ngày.
  final Widget Function(String classId, List<ClassOption> classes) builder;

  @override
  State<TeacherClassGate> createState() => _TeacherClassGateState();
}

class _TeacherClassGateState extends State<TeacherClassGate> {
  late Future<List<TeacherClass>>? _classes;
  late String? _yearKey;

  @override
  void initState() {
    super.initState();
    _yearKey = SelectedSchoolYear.apiYearId;
    _classes = _load();
    SelectedSchoolYear.notifier.addListener(_onYearChanged);
  }

  @override
  void dispose() {
    SelectedSchoolYear.notifier.removeListener(_onYearChanged);
    super.dispose();
  }

  Future<List<TeacherClass>>? _load() {
    final sources = widget.sources;
    final byYear = sources.loadYearClasses;
    if (byYear != null) return byYear(SelectedSchoolYear.apiYearId);
    return sources.loadClasses?.call();
  }

  void _onYearChanged() {
    final key = SelectedSchoolYear.apiYearId;
    // Chỉ năm khác nhau về id gửi BE mới cần tải lại lớp; vẫn dựng lại màn để áp chế độ chỉ xem
    setState(() {
      if (key != _yearKey) {
        _yearKey = key;
        _classes = _load();
      }
    });
  }

  Widget _scaffold(Widget body) => Scaffold(
    appBar: AppBar(),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: SchoolYearChip(),
        ),
        Expanded(child: body),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final year = SelectedSchoolYear.value;
    final future = _classes;
    if (future == null) {
      return KeyedSubtree(
        key: ValueKey('fake|${year.id}'),
        child: widget.builder(FakeAttendanceSource.classId, [
          ClassOption(
            id: FakeAttendanceSource.classId,
            name: year.status == SchoolYearStatus.active
                ? 'Lớp Mầm 3A'
                : 'Lớp ${year.className}',
            readOnly: year.readOnly,
          ),
        ]),
      );
    }
    return FutureBuilder<List<TeacherClass>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _scaffold(
            AppErrorState(
              title: 'Chưa tải được lớp của bạn',
              message: loadFailureMessage(snapshot.error),
              onRetry: () => setState(() => _classes = _load()),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return _scaffold(
            const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            ),
          );
        }
        final classes = snapshot.data ?? const <TeacherClass>[];
        // Năm đang chạy: lớp đang dạy; năm khác: lớp BE cho xem lại (historicalReadOnly)
        final main = classes
            .where(
              (item) => year.status == SchoolYearStatus.active
                  ? item.teaches
                  : item.teaches || item.historicalReadOnly,
            )
            .firstOrNull;
        if (main == null) {
          return _scaffold(
            year.status == SchoolYearStatus.active
                ? const AppEmptyState(
                    title: 'Bạn chưa được phân công lớp',
                    message: 'Liên hệ Phó hiệu trưởng để kiểm tra phân công.',
                  )
                : const AppEmptyState(
                    title: 'Bạn chưa có lớp trong năm học này',
                    message: 'Chọn năm học khác để xem dữ liệu lớp của bạn.',
                  ),
          );
        }
        // Một giáo viên một lớp (user 26/11): chỉ truyền lớp phụ trách
        return KeyedSubtree(
          key: ValueKey('${year.id}|${main.id}'),
          child: widget.builder(main.id, [
            ClassOption(
              id: main.id,
              name: main.name,
              readOnly:
                  year.readOnly || main.historicalReadOnly || !main.canRecord,
            ),
          ]),
        );
      },
    );
  }
}
