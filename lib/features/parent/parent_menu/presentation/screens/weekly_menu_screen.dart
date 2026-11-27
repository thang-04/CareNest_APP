import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/parent_menu/data/fake_weekly_menu_source.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';
import 'package:carenest_app/features/parent/parent_menu/presentation/screens/meal_photo_viewer_screen.dart';

/// Thực đơn tuần của bé (PAR-14): món đã công bố theo lớp của bé từng ngày, cảnh báo món có chất
/// bé dị ứng (BE đối chiếu, NUT-23), ảnh bữa bếp đăng. Ngày trống hiện lý do theo cờ BE.
class WeeklyMenuScreen extends StatefulWidget {
  const WeeklyMenuScreen({
    super.key,
    required this.childId,
    required this.initialDay,
    this.source = const FakeWeeklyMenuSource(),
  });

  final String childId;
  final DateTime initialDay;
  final WeeklyMenuSource source;

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen> {
  /// null ⇒ tuần hiện tại theo BE.
  DateTime? _weekStart;
  late Future<WeeklyMenu> _week = widget.source.loadWeek(widget.childId);
  late DateTime _selected = widget.initialDay;

  /// Ảnh đã tải trong phiên màn (theo photoId), không lưu ra máy.
  final _photos = <String, Future<Uint8List?>>{};

  void _load() => setState(() {
    _week = widget.source.loadWeek(widget.childId, weekStart: _weekStart);
  });

  void _moveWeek(WeeklyMenu week, int weeks) {
    final start = week.weekStart.add(Duration(days: 7 * weeks));
    _weekStart = start;
    _selected = start;
    _load();
  }

  Future<Uint8List?> _photo(String photoId) => _photos.putIfAbsent(
    photoId,
    () => widget.source.loadPhoto(widget.childId, photoId),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thực đơn tuần')),
      body: FutureBuilder<WeeklyMenu>(
        future: _week,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppErrorState(
                  title: 'Chưa tải được thực đơn',
                  message: loadFailureMessage(snapshot.error),
                  onRetry: _load,
                ),
              ],
            );
          }
          final week = snapshot.data;
          if (week == null ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            );
          }
          final days = [for (final item in week.days) item.date];
          // Ngày đang chọn không thuộc tuần (vd. cuối tuần) ⇒ chọn thứ Hai
          final selected = days.any((d) => DateUtils.isSameDay(d, _selected))
              ? _selected
              : (days.firstOrNull ?? week.weekStart);
          final day = week.days
              .where((item) => DateUtils.isSameDay(item.date, selected))
              .firstOrNull;
          final weekEnd = week.weekStart.add(const Duration(days: 4));
          final textTheme = Theme.of(context).textTheme;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppCard(
                dense: true,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Tuần trước',
                      onPressed: () => _moveWeek(week, -1),
                      icon: const Icon(AppIcons.back),
                    ),
                    Expanded(
                      child: Text(
                        'Tuần ${DateLabels.dayMonth(week.weekStart)} – ${DateLabels.date(weekEnd)}',
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tuần sau',
                      onPressed: () => _moveWeek(week, 1),
                      icon: const Icon(AppIcons.chevronRight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              if (days.isNotEmpty) ...[
                AppDayStrip(
                  days: days,
                  selected: selected,
                  onChanged: (value) => setState(() => _selected = value),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
              if (week.unmatchedAllergies.isNotEmpty && week.published) ...[
                AppBanner(
                  kind: AppBannerKind.warning,
                  message:
                      'Dị ứng đã khai chưa khớp danh mục chất: '
                      '${week.unmatchedAllergies.join(', ')}. '
                      'Món có chất này không được cảnh báo tự động.',
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
              ..._dayContent(context, week, day),
            ],
          );
        },
      ),
    );
  }

  /// Lý do ngày trống theo cờ BE (contract PAR-14).
  List<Widget> _dayContent(
    BuildContext context,
    WeeklyMenu week,
    MenuDay? day,
  ) {
    final empty = !week.published
        ? (
            AppIcons.menuBook,
            'Thực đơn tuần này chưa công bố',
            'Nhà trường công bố thực đơn trước đầu tuần.',
          )
        : week.mealsHidden
        ? (
            AppIcons.meal,
            'Bé không báo ăn ở trường',
            'Bé không ăn tại trường nên không có thực đơn.',
          )
        : day == null
        ? (AppIcons.menuBook, 'Chưa có thực đơn', 'Ngày này chưa có món.')
        : day.dayOff
        ? (
            AppIcons.calendarOff,
            'Ngày nghỉ',
            'Trường không tổ chức ăn ngày này.',
          )
        : !day.enrolled
        ? (
            AppIcons.calendarOff,
            'Bé chưa học ngày này',
            'Chưa có thực đơn cho bé.',
          )
        : day.meals.isEmpty
        ? (AppIcons.menuBook, 'Chưa có thực đơn', 'Ngày này chưa có món.')
        : null;
    if (empty != null) {
      return [
        AppEmptyState(icon: empty.$1, title: empty.$2, message: empty.$3),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.textMuted);
    return [
      for (final meal in day!.meals) ...[
        AppCard(
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    AppIcons.meal,
                    size: AppSizes.iconTile,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      meal.session.label,
                      style: textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              for (final dish in meal.dishes) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(dish.name, style: textTheme.bodyMedium),
                if (dish.childAllergens.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space1),
                  // NUT-23: cảnh báo có biểu tượng + chữ, không chỉ màu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        AppIcons.alertTriangle,
                        size: AppSizes.iconBadge,
                        color: AppColors.dangerText,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                      Expanded(
                        child: Text(
                          'Có ${dish.childAllergens.join(', ')} — bé đã khai dị ứng',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (dish.allergens.isNotEmpty)
                  Text('Có ${dish.allergens.join(', ')}', style: muted),
              ],
              const SizedBox(height: AppSpacing.space3),
              ..._photoBlock(context, day, meal),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      Text(
        'Cảnh báo theo dị ứng phụ huynh đã khai; món không có cảnh báo chưa chắc an toàn.',
        style: muted,
      ),
    ];
  }

  List<Widget> _photoBlock(
    BuildContext context,
    MenuDay day,
    MenuMealEntry meal,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final photo = meal.photo;
    if (photo == null) {
      return [
        Row(
          children: [
            const Icon(
              AppIcons.image,
              size: AppSizes.iconInline,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                'Chưa có ảnh bữa ăn',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ];
    }
    final bytes = _photo(photo.photoId);
    return [
      FutureBuilder<Uint8List?>(
        future: bytes,
        builder: (context, snapshot) {
          final image = snapshot.data;
          return Semantics(
            container: true,
            button: true,
            label: 'Xem ảnh ${meal.session.label.toLowerCase()}',
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => MealPhotoViewerScreen(
                      date: day.date,
                      meal: meal,
                      bytes: image,
                    ),
                  ),
                ),
                child: image == null
                    ? const AppPhotoPlaceholder(aspectRatio: 16 / 9)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.memory(image, fit: BoxFit.cover),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: AppSpacing.space2),
      Text(
        'Bếp đăng ${DateLabels.time24(photo.uploadedAt)}',
        style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
    ];
  }
}
