import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/routing/navigation_destinations.dart';

/// Khung tab: nội dung một cột + thanh đáy phẳng 4 đích, giữ trạng thái từng tab (Figma App, DESIGN.md §8.1).
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
    this.badges = const {},
  });

  final StatefulNavigationShell navigationShell;
  final List<NavDestination> destinations;

  /// Số trên icon tab (vd. thông báo chưa đọc); 0 hoặc không có ⇒ không hiện.
  final Map<NavTab, int> badges;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // Thanh trắng sát đáy, kẻ trên mảnh tách khỏi nội dung
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
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
                icon: _TabIcon(
                  icon: destination.icon,
                  count: badges[destination.tab] ?? 0,
                ),
                label: destination.label,
                tooltip: (badges[destination.tab] ?? 0) > 0
                    ? '${destination.label}, ${badges[destination.tab]} mới'
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon),
    );
  }
}
