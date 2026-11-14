import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/school_menu/presentation/screens/school_menu_screen.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Phó HT · Thực đơn tuần theo nhóm tuổi — Figma PHT 06: màn thực đơn dùng chung với bếp, thêm trạng thái
/// duyệt và nút xem cân đối dinh dưỡng của nhóm + ngày đang chọn. Lập và duyệt trên Web (NUT-08).
class CampusMenuScreen extends StatelessWidget {
  const CampusMenuScreen({super.key});

  static const _viewOnly = 'Lập và duyệt trên CareNest Web · App chỉ xem';

  @override
  Widget build(BuildContext context) {
    return SchoolMenuScreen(
      initialDay: FakeParentHomeSource.today,
      // Câu chỉ xem nằm trong khối cuối (banner đã duyệt) như Figma ⇒ không lặp ở chân màn
      footerNote: '',
      bottom: (context, week, groupId, day) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (week.publishedNote case final note?)
            AppBanner(
              kind: AppBannerKind.success,
              icon: AppIcons.checkCircle,
              title: note,
              message: _viewOnly,
            )
          else
            Text(
              '$_viewOnly.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          const SizedBox(height: AppSpacing.space3),
          AppButton(
            label: 'Xem cân đối dinh dưỡng',
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () =>
                context.push(RoutePaths.vicePrincipalNutritionOf(groupId, day)),
          ),
        ],
      ),
    );
  }
}
