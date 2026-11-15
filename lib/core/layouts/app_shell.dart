import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/routing/navigation_destinations.dart';

/// Khung tab: nội dung một cột + thanh đáy nổi 4 đích, giữ trạng thái từng tab (DESIGN.md §8.1).
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
  });

  final StatefulNavigationShell navigationShell;
  final List<NavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // Thanh nổi cách mép 12, bo 28; SafeArea giữ khoảng với home indicator
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSizes.floatingBarInset,
          0,
          AppSizes.floatingBarInset,
          AppSizes.floatingBarInset,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: AppColors.surface.withValues(alpha: 0.85),
            ),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                // Bấm lại tab đang mở ⇒ về đầu tab đó
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
