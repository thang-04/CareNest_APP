import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';

/// Màn phụ chọn trẻ có ăn tại trường. Trẻ vắng không xuất hiện và luôn có `meals` rỗng.
/// Bữa chọn được do BE trả (nhóm tuổi / buổi còn học); trẻ có dị ứng hiện thẻ để cô lưu ý.
class MealParticipationScreen extends StatefulWidget {
  const MealParticipationScreen({
    super.key,
    required this.kids,
    required this.mealSessions,
    this.sessionsFor,
  });

  final List<KidAttendance> kids;
  final List<MealSession> mealSessions;

  /// Bữa của từng trẻ (nghỉ một buổi ⇒ chỉ bữa buổi còn học); null ⇒ [mealSessions].
  final List<MealSession> Function(KidAttendance kid)? sessionsFor;

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

  List<MealSession> _sessions(KidAttendance kid) =>
      widget.sessionsFor?.call(kid) ?? widget.mealSessions;

  void _update(String childId, KidAttendance Function(KidAttendance) change) {
    setState(() {
      _kids = [
        for (final kid in _kids) kid.childId == childId ? change(kid) : kid,
      ];
    });
  }

  void _setEating(KidAttendance kid, bool value) => _update(
    kid.childId,
    (item) => item.copyWith(
      meals: value ? {for (final s in _sessions(item)) s: true} : const {},
    ),
  );

  void _toggleMeal(KidAttendance kid, MealSession session) => _update(
    kid.childId,
    (item) => item.copyWith(
      meals: {...item.meals, session: !(item.meals[session] == true)},
    ),
  );

  void _finish() => Navigator.of(context).pop(_kids);

  Widget _row(KidAttendance kid) {
    final textTheme = Theme.of(context).textTheme;
    final registered = kid.mealRegistered;
    final sessions = _sessions(kid);
    return AppCard(
      flush: true,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              key: ValueKey('meal-${kid.childId}'),
              value: kid.eatsAtSchool,
              onChanged: registered ? (value) => _setEating(kid, value) : null,
              title: Text(kid.fullName, style: textTheme.titleSmall),
              subtitle: Wrap(
                spacing: AppSpacing.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    !registered
                        ? 'Không báo ăn'
                        : kid.eatsAtSchool
                        ? 'Có ăn'
                        : 'Không ăn',
                    style: textTheme.bodyMedium?.copyWith(
                      color: kid.eatsAtSchool
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                  if (kid.hasAllergy)
                    const AppStatusBadge(
                      label: 'Có dị ứng',
                      tone: AppStatusTone.orange,
                      icon: AppIcons.alertTriangle,
                    ),
                ],
              ),
              secondary: Icon(
                kid.eatsAtSchool ? AppIcons.checkCircle : AppIcons.circle,
                color: kid.eatsAtSchool
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
            ),
            if (kid.eatsAtSchool && sessions.length > 1)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.pagePadding,
                  right: AppSpacing.pagePadding,
                  bottom: AppSpacing.space3,
                ),
                child: Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    for (final session in sessions)
                      AppFilterChip(
                        label: session.label,
                        selected: kid.meals[session] == true,
                        onSelected: () => _toggleMeal(kid, session),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                  _row(kid),
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
