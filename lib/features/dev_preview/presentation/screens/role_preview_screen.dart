import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Chỉ bản debug: mở màn theo vai trò khi chưa có đăng nhập thật.
/// Không phải chọn role khi đăng nhập — role thật do BE trả (DESIGN.md §8.4).
class RolePreviewScreen extends StatelessWidget {
  const RolePreviewScreen({super.key});

  static const _roles = [
    (
      'Phụ huynh',
      'Hôm nay của bé, thông báo nghỉ',
      AppIcons.child,
      RoutePaths.parentToday,
    ),
    (
      'Giáo viên',
      'Việc hôm nay, điểm danh và báo ăn',
      AppIcons.school,
      RoutePaths.teacherToday,
    ),
    (
      'Nhân viên bếp',
      'Suất ăn hôm nay, dị ứng',
      AppIcons.kitchen,
      RoutePaths.kitchenHome,
    ),
    (
      'Phó Hiệu trưởng',
      'Cơ sở phụ trách, chốt suất ăn, yêu cầu chờ duyệt',
      AppIcons.approval,
      RoutePaths.vicePrincipalHome,
    ),
    (
      'Hiệu trưởng',
      'Tổng quan toàn trường, chờ duyệt',
      AppIcons.shieldPerson,
      RoutePaths.principalHome,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xem thử theo vai trò')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          const AppBanner(
            message: 'Chỉ có trong bản debug. Mọi số liệu là dữ liệu giả.',
          ),
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(
            flush: true,
            child: AppDividedColumn(
              children: [
                for (final (title, subtitle, icon, path) in _roles)
                  AppListRow(
                    title: title,
                    subtitle: Text(subtitle),
                    leading: AppIconTile(icon: icon),
                    showChevron: true,
                    onTap: () => context.go(path),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
