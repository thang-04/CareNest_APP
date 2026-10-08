import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/brand/app_wordmark.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Màn tạm: chưa có nghiệp vụ, chỉ để kiểm tra khung app và theme.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.showUiKitEntry = false});

  final bool showUiKitEntry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const AppWordmark(fontSize: 20)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text('Trang chủ', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Các tính năng sẽ hiển thị tại đây sau khi đăng nhập.',
            style: textTheme.bodyLarge,
          ),
          if (showUiKitEntry) ...[
            const SizedBox(height: AppSpacing.space6),
            AppButton(
              label: 'Mở bộ UI',
              icon: Icons.widgets_outlined,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => context.push(RoutePaths.uiKit),
            ),
          ],
        ],
      ),
    );
  }
}
