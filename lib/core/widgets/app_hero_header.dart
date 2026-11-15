import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Đầu màn trang chủ: dải nền `brand`, lời chào + tên, card ngữ cảnh đè lên mép dưới dải.
/// Chưa có tranh hero (DESIGN.md §3.2) ⇒ dùng nền thương hiệu trơn theo mockup.
class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({
    super.key,
    required this.greeting,
    required this.name,
    this.trailing,
    this.card,
  });

  /// Dòng nhỏ phía trên, vd. "Xin chào," hoặc "Chào cô,".
  final String greeting;
  final String name;

  /// Nút thông báo hoặc hành động gọn ở góc phải.
  final Widget? trailing;

  /// Card ngữ cảnh (bé, lớp, cơ sở); nửa dưới nằm trên nền màn.
  final Widget? card;

  static const double _overlap = AppSpacing.space8;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        topInset + AppSpacing.space5,
        AppSpacing.pagePadding,
        card == null ? AppSpacing.space6 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.onBrand,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        name,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.onBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.space2),
                IconTheme.merge(
                  data: const IconThemeData(color: AppColors.onBrand),
                  child: trailing!,
                ),
              ],
            ],
          ),
          if (card != null) ...[
            const SizedBox(height: AppSpacing.space5),
            card!,
          ],
        ],
      ),
    );
    return Stack(
      children: [
        // Dải nền dừng cách đáy một đoạn cố định ⇒ card luôn đè nửa dưới, cao thấp nào cũng được
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: card == null ? 0 : _overlap,
          child: const ColoredBox(color: AppColors.brand),
        ),
        content,
      ],
    );
  }
}

/// Chuông thông báo trên hero, có số chưa đọc (DESIGN.md §8.1).
class AppHeroBell extends StatelessWidget {
  const AppHeroBell({super.key, required this.unread, required this.onPressed});

  final int unread;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = unread > 0 ? 'Thông báo, $unread chưa đọc' : 'Thông báo';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          backgroundColor: AppColors.danger,
          textColor: AppColors.surface,
          child: const Icon(AppIcons.bell, size: AppSizes.iconNavigation),
        ),
      ),
    );
  }
}
