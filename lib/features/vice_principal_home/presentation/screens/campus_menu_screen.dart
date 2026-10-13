import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/school_menu/presentation/screens/school_menu_screen.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Phó HT · Thực đơn tuần theo nhóm tuổi — mockup V06: màn K02, thêm trạng thái duyệt và
/// nút xem cân đối dinh dưỡng của nhóm + ngày đang chọn. Lập và duyệt trên Web (NUT-08).
class CampusMenuScreen extends StatelessWidget {
  const CampusMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SchoolMenuScreen(
      initialDay: FakeParentHomeSource.today,
      footerNote: 'Lập và duyệt trên CareNest Web · App chỉ xem.',
      bottom: (context, week, groupId, day) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (week.publishedNote case final note?) ...[
            AppBanner(
              kind: AppBannerKind.success,
              icon: AppIcons.checkCircle,
              message: note,
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
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
