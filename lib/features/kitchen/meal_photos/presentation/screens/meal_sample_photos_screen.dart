import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';

/// Bếp · Ảnh mẫu bữa ăn theo nhóm tuổi (user 17/11, canvas "Ảnh bữa ăn theo nhóm tuổi"):
/// chọn nhóm tuổi, mỗi bữa nhóm đó ăn cần ít nhất 1 ảnh, chụp bao nhiêu cũng được;
/// chỉ đăng trong khung giờ của bữa (NUT-16). BE chưa có API theo nhóm tuổi ⇒ dữ liệu giả.
class MealSamplePhotosScreen extends StatefulWidget {
  const MealSamplePhotosScreen({super.key, this.source});

  final KitchenPhotoSource? source;

  @override
  State<MealSamplePhotosScreen> createState() => _MealSamplePhotosScreenState();
}

class _MealSamplePhotosScreenState extends State<MealSamplePhotosScreen> {
  late final KitchenPhotoSource _source =
      widget.source ?? FakeKitchenPhotoSource();
  late Future<KitchenPhotoDay> _day = _source.loadToday();
  String? _groupId;

  static int _doneMeals(AgeGroupMeals group) =>
      group.meals.where((meal) => meal.photoIds.isNotEmpty).length;

  static (String, AppStatusTone) _badge(SampleMeal meal) =>
      meal.photoIds.isNotEmpty
      ? ('Đã có ${meal.photoIds.length} ảnh', AppStatusTone.green)
      : switch (meal.window) {
          PhotoWindow.upcoming => ('Chưa tới giờ', AppStatusTone.gray),
          PhotoWindow.open => ('Cần chụp', AppStatusTone.orange),
          PhotoWindow.closed => ('Quá giờ, chưa có ảnh', AppStatusTone.red),
        };

  static String _windowNote(SampleMeal meal) => switch (meal.window) {
    PhotoWindow.closed => 'Hết giờ đăng (${meal.windowLabel})',
    _ => 'Đăng được ${meal.windowLabel}',
  };

  /// Bữa đang đăng ảnh theo "nhóm|bữa": khoá nút để không đăng trùng.
  final Set<String> _posting = {};

  /// Bữa vừa đăng lỗi: báo ngay dưới nút, lần bấm sau thì xoá.
  final Set<String> _failed = {};

  static String _postingKey(AgeGroupMeals group, SampleMeal meal) =>
      '${group.id}|${meal.id}';

  Future<void> _addPhoto(AgeGroupMeals group, SampleMeal meal) async {
    final key = _postingKey(group, meal);
    setState(() {
      _posting.add(key);
      _failed.remove(key);
    });
    try {
      final day = await _source.addPhoto(groupId: group.id, mealId: meal.id);
      if (!mounted) return;
      setState(() {
        _posting.remove(key);
        _day = Future.value(day);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posting.remove(key);
        _failed.add(key);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ảnh mẫu bữa ăn')),
      body: FutureBuilder<KitchenPhotoDay>(
        future: _day,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được ảnh mẫu',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(() {
                  _day = _source.loadToday();
                }),
              ),
            );
          }
          final day = snapshot.data;
          if (day == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            );
          }
          if (day.groups.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: AppIcons.camera,
                title: 'Hôm nay không có bữa cần chụp',
                message: 'Nhà trường chưa cấu hình bữa ăn cho nhóm tuổi nào.',
              ),
            );
          }
          final group =
              day.groups.where((item) => item.id == _groupId).firstOrNull ??
              day.groups.first;
          return _content(context, day, group);
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    KitchenPhotoDay day,
    AgeGroupMeals group,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          '${DateLabels.weekdayDate(day.date)} · ${day.kitchenLabel}',
          style: secondary,
        ),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final item in day.groups)
              AppFilterChip(
                label: '${item.label} ${_doneMeals(item)}/${item.meals.length}',
                selected: item.id == group.id,
                onSelected: () => setState(() => _groupId = item.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          'Nhóm ${group.label} (${group.ageRange}) ăn ${group.meals.length} bữa mỗi ngày. Mỗi bữa cần ít nhất 1 ảnh, chụp bao nhiêu cũng được.',
          style: secondary,
        ),
        for (final meal in group.meals) ...[
          const SizedBox(height: AppSpacing.space3),
          _mealCard(context, group, meal),
        ],
      ],
    );
  }

  Widget _mealCard(BuildContext context, AgeGroupMeals group, SampleMeal meal) {
    final textTheme = Theme.of(context).textTheme;
    final title = '${meal.name} · ${meal.time}';
    final (badge, tone) = _badge(meal);
    return AppCard(
      key: ValueKey('meal-card-$title'),
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nhãn dài (vd. "Quá giờ, chưa có ảnh") xuống dòng khi máy hẹp hay chữ lớn
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              Text(title, style: textTheme.titleSmall),
              AppStatusBadge(label: badge, tone: tone),
            ],
          ),
          if (meal.photoIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            _PhotoTiles(count: meal.photoIds.length),
          ],
          const SizedBox(height: AppSpacing.space2),
          Text(
            _windowNote(meal),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          // Chỉ đăng trong khung giờ của bữa (NUT-16); máy thật cần plugin camera chưa duyệt
          if (meal.window == PhotoWindow.open) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: meal.photoIds.isEmpty ? 'Chụp ảnh' : 'Chụp thêm ảnh',
              icon: AppIcons.camera,
              variant: AppButtonVariant.secondary,
              small: true,
              expand: true,
              isLoading: _posting.contains(_postingKey(group, meal)),
              loadingLabel: 'Đang đăng ảnh…',
              onPressed: () => _addPhoto(group, meal),
            ),
            if (_failed.contains(_postingKey(group, meal))) ...[
              const SizedBox(height: AppSpacing.space2),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Chưa đăng được ảnh. Thử lại.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.dangerText,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Ảnh đã đăng của một bữa: ô vuông, ba ô một hàng.
class _PhotoTiles extends StatelessWidget {
  const _PhotoTiles({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tile = (constraints.maxWidth - AppSpacing.space2 * 2) / 3;
        return Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: tile,
                child: const AppPhotoPlaceholder(aspectRatio: 1),
              ),
          ],
        );
      },
    );
  }
}
