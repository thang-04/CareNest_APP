import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';
import 'package:carenest_app/features/shared/account/presentation/screens/account_screen.dart';

import '../../../helpers/pump_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  List<AccountModeSwitch> modeSwitches = const [],
  VoidCallback? onLogout,
}) async {
  usePhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: AccountScreen(
          role: AppRole.teacher,
          onOpenProfile: () {},
          onChangePassword: () {},
          onLogout: onLogout ?? () {},
          modeSwitches: modeSwitches,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('account_switchMode_onlyForMultiMode', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Chuyển sang chế độ'), findsNothing);
  });

  testWidgets('account_switchMode_tapCallsSwitch', (tester) async {
    var switched = false;
    await _pump(
      tester,
      modeSwitches: [
        AccountModeSwitch(
          label: 'Chuyển sang chế độ phụ huynh',
          onTap: () => switched = true,
        ),
      ],
    );

    await tester.tap(find.text('Chuyển sang chế độ phụ huynh'));
    await tester.pump();

    expect(switched, isTrue);
  });

  testWidgets('account_logout_confirm_callsSignOut', (tester) async {
    var loggedOut = false;
    await _pump(tester, onLogout: () => loggedOut = true);

    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất khỏi CareNest?'), findsOneWidget);
    expect(loggedOut, isFalse);

    await tester.tap(find.widgetWithText(AppButton, 'Đăng xuất').last);
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
  });

  testWidgets('account_logout_cancel_staysSignedIn', (tester) async {
    var loggedOut = false;
    await _pump(tester, onLogout: () => loggedOut = true);

    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Ở lại'));
    await tester.pumpAndSettle();

    expect(loggedOut, isFalse);
    expect(find.text('Đăng xuất khỏi CareNest?'), findsNothing);
  });
}
