import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/home/presentation/screens/home_screen.dart';
import 'package:carenest_app/features/ui_kit/presentation/screens/ui_kit_screen.dart';
import 'package:carenest_app/routing/app_router.dart';
import 'package:carenest_app/routing/route_paths.dart';

Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  required bool enableUiKit,
}) async {
  final router = buildAppRouter(enableUiKit: enableUiKit);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: buildLightTheme(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('AC-7: app mở HomeScreen', (tester) async {
    await pumpRouter(tester, enableUiKit: false);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('AC-7: debug ⇒ có lối vào và mở được UiKitScreen', (
    tester,
  ) async {
    await pumpRouter(tester, enableUiKit: true);
    await tester.tap(find.text('Mở bộ UI'));
    await tester.pumpAndSettle();
    expect(find.byType(UiKitScreen), findsOneWidget);
  });

  testWidgets('AC-7: release ⇒ không có lối vào, route /ui-kit không tồn tại', (
    tester,
  ) async {
    final router = await pumpRouter(tester, enableUiKit: false);
    expect(find.text('Mở bộ UI'), findsNothing);

    router.go(RoutePaths.uiKit);
    await tester.pumpAndSettle();
    expect(find.byType(UiKitScreen), findsNothing);
    expect(find.text('Không tìm thấy trang'), findsOneWidget);

    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
