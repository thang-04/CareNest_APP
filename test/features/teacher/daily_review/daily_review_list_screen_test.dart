import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/teacher/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/data/live_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_list_screen.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

import '../../../helpers/live_fakes.dart';
import '../../../helpers/pump_app.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  usePhoneSize(tester);
  tester.view.physicalSize = const Size(360, 8000);
  await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
  await tester.pumpAndSettle();
}

class _StubSource implements DailyReviewSource {
  _StubSource(this.day);
  final ReviewDay day;
  final dates = <DateTime?>[];

  @override
  Future<ReviewDay> loadDay(String classId, {DateTime? date}) async {
    dates.add(date);
    return day;
  }

  @override
  Future<List<PeriodReview>> loadPeriods(String classId) async => [];
}

void main() {
  final today = DateTime(2026, 11, 25);

  test('loadDay_sendsDateParamAndMapsFlags', () async {
    final api = ScriptedApi(FakeLiveSession(['TEACHER']), {
      'GET /classes/12/daily-assessment?date=2026-11-20': (_) => {
        'date': '2026-11-20',
        'attendanceTaken': false,
        'locked': true,
        'yearReadOnly': false,
        'mealSessions': <String>[],
        'rows': <Object>[],
        'absentChildren': <Object>[],
      },
    });
    final day = await LiveDailyReviewSource(
      api,
    ).loadDay('12', date: DateTime(2026, 11, 20));
    expect(day.attendanceTaken, isFalse);
    expect(day.locked, isTrue);
    expect(day.yearReadOnly, isFalse);
  });

  testWidgets('bản gốc: Đã có / Chưa có, nhận xét chung, biểu hiện từ BE', (
    tester,
  ) async {
    await _pump(
      tester,
      DailyReviewListScreen(
        onOpenKid: (_) async {},
        source: FakeDailyReviewSource(),
        today: today,
      ),
    );
    expect(find.text('Đã có'), findsWidgets);
    expect(find.text('Chưa có'), findsWidgets);
    expect(find.text('Nhận xét chung của lớp'), findsOneWidget);
    expect(find.textContaining('Sức khỏe: Ho'), findsOneWidget);
    expect(find.textContaining('Có cờ bé ngoan'), findsOneWidget);
    expect(find.textContaining('Đang xem lịch sử'), findsNothing);
  });

  testWidgets('chưa điểm danh ⇒ thông báo, không có thẻ trẻ', (tester) async {
    final source = _StubSource(
      ReviewDay(
        date: today,
        activityLine: '',
        criteria: const [],
        flagLabel: '',
        kids: const [],
        attendanceTaken: false,
      ),
    );
    await _pump(
      tester,
      DailyReviewListScreen(
        onOpenKid: (_) async {},
        source: source,
        today: today,
      ),
    );
    expect(find.text('Lớp chưa điểm danh ngày 25/11/2026'), findsOneWidget);
  });

  testWidgets('cả lớp vắng ⇒ trẻ hiện badge Vắng', (tester) async {
    final source = _StubSource(
      ReviewDay(
        date: today,
        activityLine: '',
        criteria: const [],
        flagLabel: '',
        kids: const [
          KidReview(
            childId: '1',
            fullName: 'Trần Bảo',
            state: KidReviewState.absent,
            presenceLine: 'Vắng không phép',
          ),
        ],
      ),
    );
    await _pump(
      tester,
      DailyReviewListScreen(
        onOpenKid: (_) async {},
        source: source,
        today: today,
      ),
    );
    expect(find.text('Vắng'), findsOneWidget);
    expect(find.text('Vắng không phép'), findsOneWidget);
  });

  testWidgets('lớp chỉ xem hoặc ngày khóa ⇒ banner; ngày cũ gửi date', (
    tester,
  ) async {
    final source = _StubSource(
      ReviewDay(
        date: today,
        activityLine: '',
        criteria: const [],
        flagLabel: '',
        kids: const [],
        locked: true,
      ),
    );
    await _pump(
      tester,
      DailyReviewListScreen(
        onOpenKid: (_) async {},
        source: source,
        today: today,
        classes: const [
          ClassOption(id: 'a', name: 'Mầm 3A'),
          ClassOption(id: 'b', name: 'Mầm 3B', readOnly: true),
        ],
        classId: 'b',
      ),
    );
    expect(source.dates, [null]);
    expect(find.text('Ngày 25/11/2026 đã khóa.'), findsOneWidget);
  });

  testWidgets('lớp chỉ xem ⇒ Đang xem lịch sử, không sửa được', (tester) async {
    await _pump(
      tester,
      DailyReviewListScreen(
        onOpenKid: (_) async {},
        source: FakeDailyReviewSource(),
        today: today,
        classes: const [ClassOption(id: 'x', name: 'Mầm 3A', readOnly: true)],
        classId: 'x',
      ),
    );
    expect(find.text('Đang xem lịch sử, không sửa được.'), findsOneWidget);
  });

  testWidgets('chưa được phân công lớp', (tester) async {
    await _pump(
      tester,
      DailyReviewListScreen(onOpenKid: (_) async {}, classId: ''),
    );
    expect(find.text('Bạn chưa được phân công lớp'), findsOneWidget);
  });
}
