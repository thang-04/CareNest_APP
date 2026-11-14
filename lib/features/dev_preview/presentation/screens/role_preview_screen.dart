import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/account/domain/app_modes.dart';
import 'package:carenest_app/features/account/presentation/app_mode.dart';

/// Chỉ bản debug: mở màn theo vai trò khi chưa có đăng nhập thật.
/// Không phải chọn role khi đăng nhập — role thật do BE trả (DESIGN.md §8.4).
class RolePreviewScreen extends StatelessWidget {
  const RolePreviewScreen({super.key});

  static const _roles = [
    (
      'Phụ huynh',
      'Hôm nay của bé, thông báo nghỉ',
      AppIcons.child,
      [AppRole.parent],
    ),
    (
      'Giáo viên',
      'Việc hôm nay, điểm danh và báo ăn',
      AppIcons.school,
      [AppRole.teacher],
    ),
    (
      'Giáo viên kiêm phụ huynh',
      'Mở chế độ giáo viên, chuyển chế độ ở Tài khoản',
      AppIcons.school,
      [AppRole.teacher, AppRole.parent],
    ),
    (
      'Nhân viên bếp',
      'Suất ăn hôm nay, dị ứng',
      AppIcons.kitchen,
      [AppRole.kitchen],
    ),
    (
      'Phó Hiệu trưởng',
      'Chỉ xem: cơ sở phụ trách, số suất, việc chờ xử lý',
      AppIcons.approval,
      [AppRole.vicePrincipal],
    ),
    (
      'Hiệu trưởng',
      'Chỉ xem: tổng quan toàn trường, việc chờ xử lý',
      AppIcons.shieldPerson,
      [AppRole.principal],
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
                for (final (title, subtitle, icon, roles) in _roles)
                  AppListRow(
                    title: title,
                    subtitle: Text(subtitle),
                    leading: AppIconTile(icon: icon),
                    showChevron: true,
                    // Đặt chế độ của phiên giả như sau đăng nhập (AUTH-21)
                    onTap: () => context.go(homePathOf(AppMode.start(roles))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
