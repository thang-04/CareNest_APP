import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';

/// Màn phụ chọn trẻ có ăn tại trường. Trẻ vắng không xuất hiện và luôn có `meals` rỗng.
class MealParticipationScreen extends StatefulWidget {
  const MealParticipationScreen({
    super.key,
    required this.kids,
    required this.mealSessions,
  });

  final List<KidAttendance> kids;
  final List<MealSession> mealSessions;

  @override
  State<MealParticipationScreen> createState() =>
      _MealParticipationScreenState();
}

class _MealParticipationScreenState extends State<MealParticipationScreen> {
  late List<KidAttendance> _kids = List<KidAttendance>.of(widget.kids);

  List<KidAttendance> get _present => _kids
      .where((kid) => kid.status == AttendanceStatus.present)
      .toList(growable: false);

  int get _eatingCount => _present.where((kid) => kid.eatsAtSchool).length;

  Map<MealSession, bool> _allMeals(bool value) => {
    for (final session in widget.mealSessions) session: value,
  };

  void _setEating(String childId, bool value) {
    setState(() {
      _kids = [
        for (final kid in _kids)
          kid.childId == childId
              ? kid.copyWith(meals: value ? _allMeals(true) : const {})
              : kid,
      ];
    });
  }

  void _finish() => Navigator.of(context).pop(_kids);

  @override
  Widget build(BuildContext context) {
    final present = _present;
    return Scaffold(
      appBar: AppBar(title: const Text('Trẻ tham gia ăn')),
      body: present.isEmpty
          ? const Center(
              child: SingleChildScrollView(
                child: AppEmptyState(
                  title: 'Chưa có trẻ có mặt',
                  message: 'Điểm danh trẻ Có mặt trước.',
                  icon: AppIcons.meal,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppBanner(
                  kind: AppBannerKind.info,
                  title: '$_eatingCount/${present.length} trẻ có ăn',
                  message:
                      'Trẻ có mặt được chọn ăn mặc định. Tắt công tắc nếu hôm nay trẻ không ăn tại trường.',
                ),
                const SizedBox(height: AppSpacing.space3),
                for (final kid in present) ...[
                  AppCard(
                    flush: true,
                    child: Material(
                      color: Colors.transparent,
                      child: SwitchListTile.adaptive(
                        key: ValueKey('meal-${kid.childId}'),
                        value: kid.eatsAtSchool,
                        onChanged: (value) => _setEating(kid.childId, value),
                        title: Text(
                          kid.fullName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          kid.eatsAtSchool ? 'Có ăn' : 'Không ăn',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: kid.eatsAtSchool
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
                              ),
                        ),
                        secondary: Icon(
                          kid.eatsAtSchool
                              ? AppIcons.checkCircle
                              : AppIcons.circle,
                          color: kid.eatsAtSchool
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pagePadding,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                ],
              ],
            ),
      bottomNavigationBar: present.isEmpty
          ? null
          : AppBottomDock(
              children: [
                AppButton(
                  label: 'Xong · $_eatingCount trẻ có ăn',
                  icon: AppIcons.check,
                  expand: true,
                  onPressed: _finish,
                ),
              ],
            ),
    );
  }
}
