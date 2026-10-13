import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_month_calendar.dart';
import 'package:carenest_app/core/widgets/app_otp_field.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/core/widgets/app_timeline.dart';
import 'package:carenest_app/core/constants/app_icons.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('AppButton đang gửi khóa nút để chặn gửi trùng', (tester) async {
    var taps = 0;
    await pumpWithTheme(
      tester,
      AppButton(
        label: 'Gửi',
        loadingLabel: 'Đang gửi',
        isLoading: true,
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.text('Đang gửi'), warnIfMissed: false);
    expect(taps, 0);
    expect(find.text('Gửi'), findsNothing);
  });

  testWidgets('AppButton thường gọi onPressed', (tester) async {
    var taps = 0;
    await pumpWithTheme(
      tester,
      AppButton(label: 'Gửi', onPressed: () => taps++),
    );
    await tester.tap(find.text('Gửi'));
    expect(taps, 1);
  });

  testWidgets('AppStatusBadge hiển thị đủ 7 tông', (tester) async {
    await pumpWithTheme(
      tester,
      Wrap(
        children: [
          for (final tone in AppStatusTone.values)
            AppStatusBadge(label: tone.name, tone: tone),
        ],
      ),
    );
    for (final tone in AppStatusTone.values) {
      expect(find.text(tone.name), findsOneWidget);
    }
  });

  testWidgets('AppSegmented đổi lựa chọn', (tester) async {
    var selected = 'a';
    await pumpWithTheme(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AppSegmented<String>(
          segments: const [('a', 'Đã gửi'), ('b', 'Đã hủy')],
          selected: selected,
          onChanged: (value) => setState(() => selected = value),
        ),
      ),
    );
    await tester.tap(find.text('Đã hủy'));
    await tester.pump();
    expect(selected, 'b');
  });

  testWidgets('AppTextField mật khẩu bật/tắt hiện chữ, hiện lỗi dưới ô', (
    tester,
  ) async {
    await pumpWithTheme(
      tester,
      const AppTextField(
        label: 'Mật khẩu',
        isPassword: true,
        errorText: 'Sai mật khẩu',
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.text('Sai mật khẩu'), findsOneWidget);
  });

  testWidgets('showAppBottomSheet mở và đóng bằng lựa chọn', (tester) async {
    await pumpWithTheme(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showAppBottomSheet<void>(
            context: context,
            title: 'Chọn con',
            builder: (sheetContext) => AppSheetOption(
              selected: true,
              onTap: () => Navigator.of(sheetContext).pop(),
              child: const Text('Minh An'),
            ),
          ),
          child: const Text('Mở'),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn con'), findsOneWidget);
    await tester.tap(find.text('Minh An'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn con'), findsNothing);
  });

  testWidgets('AppErrorState có nút Thử lại', (tester) async {
    var retried = false;
    await pumpWithTheme(
      tester,
      AppErrorState(
        title: 'Lỗi',
        message: 'Kiểm tra mạng',
        onRetry: () => retried = true,
      ),
    );
    await tester.tap(find.text('Thử lại'));
    expect(retried, isTrue);
  });

  test('AppAvatar tính tông và chữ cái giống web', () {
    expect(AppAvatar.initialsOf('Nguyễn Minh An'), 'MA');
    expect(AppAvatar.initialsOf('An'), 'A');
    // 'An' = 65 + 110 = 175 ⇒ 175 % 5 = 0
    expect(AppAvatar.toneOf('An'), 0);
    expect(AppAvatar.toneOf(''), 0);
  });

  // AC-10: widget mới không tràn ở 360 px với chữ phóng 2.0
  for (final scale in [1.0, 2.0]) {
    testWidgets('Widget Phase 1 không tràn, chữ x$scale', (tester) async {
      usePhoneSize(tester, textScale: scale);
      await pumpWithTheme(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              AppHeroHeader(
                greeting: 'Xin chào,',
                name: 'Chị Nguyễn Thị Phương Thảo',
                trailing: AppHeroBell(unread: 2, onPressed: () {}),
                card: const AppTaskCard(
                  icon: AppIcons.childFace,
                  title: 'Bé Nguyễn Hoàng Bảo Nam',
                  subtitle: 'Lớp Mầm 3A · 4 tuổi',
                ),
              ),
              const AppStatRow(
                tiles: [
                  AppStatTile(
                    value: '25',
                    label: 'Có mặt',
                    tone: AppStatusTone.green,
                  ),
                  AppStatTile(
                    value: '2',
                    label: 'Có phép',
                    tone: AppStatusTone.blue,
                  ),
                  AppStatTile(
                    value: '1',
                    label: 'Vắng',
                    tone: AppStatusTone.red,
                  ),
                  AppStatTile(value: '0', label: 'Chưa điểm danh'),
                ],
              ),
              AppDayStrip(
                days: [for (var d = 12; d <= 16; d++) DateTime(2026, 10, d)],
                selected: DateTime(2026, 10, 12),
                onChanged: (_) {},
              ),
              AppMonthCalendar(
                month: DateTime(2026, 10),
                selected: DateTime(2026, 10, 12),
                markers: const {
                  12: AppDayMarker(tone: AppStatusTone.green, label: 'Có mặt'),
                },
              ),
              const AppTimeline(
                entries: [
                  AppTimelineEntry(
                    time: '07:00',
                    title: 'Đón trẻ · Thể dục sáng',
                  ),
                  AppTimelineEntry(
                    time: '08:00',
                    title: 'Hoạt động học: Tạo hình',
                    subtitle: 'Tô màu chiếc lá mùa thu · Đang diễn ra',
                    isCurrent: true,
                  ),
                ],
              ),
              const AppOtpField(),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('AppDayStrip báo ngày được chọn', (tester) async {
    DateTime? picked;
    await pumpWithTheme(
      tester,
      AppDayStrip(
        days: [for (var d = 12; d <= 16; d++) DateTime(2026, 10, d)],
        selected: DateTime(2026, 10, 12),
        onChanged: (day) => picked = day,
      ),
    );
    await tester.tap(find.text('T4'));
    expect(picked, DateTime(2026, 10, 14));
  });

  testWidgets('AppMonthCalendar đọc trạng thái ngày bằng chữ, không chỉ màu', (
    tester,
  ) async {
    await pumpWithTheme(
      tester,
      AppMonthCalendar(
        month: DateTime(2026, 10),
        markers: const {
          13: AppDayMarker(tone: AppStatusTone.blue, label: 'Nghỉ có phép'),
        },
      ),
    );
    expect(
      find.bySemanticsLabel('Thứ Ba, 13/10/2026, Nghỉ có phép'),
      findsOneWidget,
    );
  });

  testWidgets('AppOtpField chỉ nhận số, đủ 6 số thì báo xong', (tester) async {
    String? done;
    await pumpWithTheme(
      tester,
      AppOtpField(onCompleted: (code) => done = code),
    );
    await tester.enterText(find.byType(TextField), '48a2615');
    await tester.pump();
    expect(done, '482615');
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('AppHeroBell đọc số chưa đọc', (tester) async {
    await pumpWithTheme(tester, AppHeroBell(unread: 3, onPressed: () {}));
    expect(find.bySemanticsLabel('Thông báo, 3 chưa đọc'), findsOneWidget);
  });
}
