// Chạy các Live…Source phụ huynh với BE local thật để bắt lỗi map dữ liệu; chỉ in số đếm, không in dữ liệu trẻ.
// Không nằm trong test/ (verify không chạy). Gọi qua: node scripts/check-parent-api.mjs --sources
// (script đăng nhập rồi truyền token qua biến môi trường, không in token).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/parent/evaluation/data/live_evaluation_source.dart';
import 'package:carenest_app/features/parent/health_book/data/live_health_book_source.dart';
import 'package:carenest_app/features/parent/leave_notice/data/live_leave_notice_source.dart';
import 'package:carenest_app/features/parent/my_child/data/live_my_child_source.dart';
import 'package:carenest_app/features/parent/rewards/data/live_reward_source.dart';

class _Bearer implements MobileCredentials {
  _Bearer(this._token);

  final String _token;

  // MobileApi chỉ cần có người dùng; ID thật do BE lấy từ token
  @override
  int? get userId => 0;

  @override
  int get generation => 0;

  @override
  Future<String> accessToken({bool force = false}) async => _token;
}

void main() {
  final env = Platform.environment;
  final token = env['CARENEST_TEST_BEARER'];
  final childId = env['CARENEST_TEST_CHILD'];
  final api = MobileApi(
    _Bearer(token ?? ''),
    baseUrl: env['CARENEST_API_BASE_URL'] ?? 'http://localhost:8080/api',
  );
  final skip = token == null || childId == null
      ? 'Chỉ chạy qua scripts/check-parent-api.mjs --sources'
      : null;

  test('Bé của tôi: hồ sơ, điểm danh tháng', () async {
    final source = LiveMyChildSource(api);
    final profile = await source.loadProfile(childId!);
    final month = await source.loadAttendance(childId);
    stdout.writeln(
      'my_child: guardians ${profile.guardians.length}, '
      'allergy ${profile.health.allergyState.name}, '
      'days ${month.days.length}, present ${month.presentCount}, '
      'excused ${month.excusedCount}, health lines '
      '${month.days.where((d) => d.healthLine != null).length}',
    );
  }, skip: skip);

  test('Xin nghỉ: đơn đã gửi', () async {
    final notices = await LiveLeaveNoticeSource(api).loadNotices(childId!);
    stdout.writeln(
      'leave: notices ${notices.length}, seen '
      '${notices.where((n) => n.seenByTeacher).length}',
    );
  }, skip: skip);

  test('Đánh giá: tuần, nhận xét, chủ đề', () async {
    final book = await LiveEvaluationSource(api).load(childId!);
    final days = book.weeks.expand((w) => w.days).toList();
    stdout.writeln(
      'evaluation: weeks ${book.weeks.length}, days ${days.length}, '
      'goals ${days.expand((d) => d.goals).length}, '
      'flagged ${days.where((d) => d.flagged).length}, '
      'comments ${book.weeklyComments.length}, themes ${book.themes.length}, '
      'semesters ${book.semesters.length}, yearEnd ${book.yearEnd != null}',
    );
  }, skip: skip);

  test('Khen thưởng: tuần, tháng, cuối năm', () async {
    final book = await LiveRewardSource(api).load(childId!);
    stdout.writeln(
      'rewards: weeks ${book.weeks.length}, '
      'flags ${book.weeks.fold<int>(0, (sum, w) => sum + w.flags)}, '
      'weekly tickets ${book.weeks.where((w) => w.ticket != null).length}, '
      'months ${book.months.length}, yearEnd ${book.yearEnd != null}',
    );
  }, skip: skip);

  test('Sổ sức khỏe: kỳ cân đo, đợt khám, biểu đồ', () async {
    final book = await LiveHealthBookSource(api).load(childId!);
    stdout.writeln(
      'health_book: rounds ${book.rounds.length}, exams ${book.exams.length}, '
      'growth ${book.growth.length}, trend ${book.interpretation != null}',
    );
  }, skip: skip);
}
