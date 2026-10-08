import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/widgets/app_empty_state.dart';
import 'package:carenest_app/features/home/presentation/screens/home_screen.dart';
import 'package:carenest_app/features/ui_kit/presentation/screens/ui_kit_screen.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// `enableUiKit` mặc định theo debug: bản release không đăng ký route UI Kit (DESIGN.md §7).
GoRouter buildAppRouter({bool enableUiKit = kDebugMode}) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => HomeScreen(showUiKitEntry: enableUiKit),
      ),
      if (enableUiKit)
        GoRoute(
          path: RoutePaths.uiKit,
          builder: (context, state) => const UiKitScreen(),
        ),
    ],
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AppEmptyState(
        icon: Icons.search_off,
        title: 'Không tìm thấy trang',
        message: 'Trang bạn mở không tồn tại hoặc đã bị gỡ.',
        actionLabel: 'Về trang chủ',
        onAction: () => context.go(RoutePaths.home),
      ),
    );
  }
}
