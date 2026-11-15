import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/cooking_status/presentation/screens/cooking_status_screen.dart';
import 'package:carenest_app/features/vice_principal_home/data/fake_campus_today_source.dart';
import 'package:carenest_app/features/vice_principal_home/domain/campus_today.dart';

/// Phó HT · Trạng thái bếp — mockup V05: màn K07 ở chế độ chỉ xem (NUT-14 PROPOSED),
/// thêm bếp nào, phiếu xuất kho và báo thiếu gần nhất (nghiệp vụ nhận nguyên liệu mới, PROPOSED).
class CampusKitchenScreen extends StatefulWidget {
  const CampusKitchenScreen({super.key, this.source, this.cookingSource});

  final CampusTodaySource? source;
  final CookingStatusSource? cookingSource;

  @override
  State<CampusKitchenScreen> createState() => _CampusKitchenScreenState();
}

class _CampusKitchenScreenState extends State<CampusKitchenScreen> {
  late final Future<CampusKitchen> _kitchen =
      (widget.source ?? FakeCampusTodaySource()).loadKitchen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<CampusKitchen>(
      future: _kitchen,
      builder: (context, snapshot) {
        final kitchen = snapshot.data;
        return CookingStatusScreen(
          readOnly: true,
          title: 'Trạng thái bếp',
          source: widget.cookingSource,
          footerNote:
              'Chỉ xem: bếp tự cập nhật trạng thái và xử lý thiếu hàng. Giáo viên không cần nhận suất vì bếp giao tận lớp.',
          header: kitchen == null
              ? null
              : AppCard(
                  dense: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kitchen.kitchenLabel, style: textTheme.titleSmall),
                      Text(
                        kitchen.slipNote,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
          notice: kitchen?.shortageNote == null
              ? null
              : AppBanner(
                  kind: AppBannerKind.warning,
                  title: kitchen!.shortageTitle,
                  message: kitchen.shortageNote!,
                ),
        );
      },
    );
  }
}
