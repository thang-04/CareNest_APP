import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';

/// Xem ảnh mẫu một bữa toàn màn (đề xuất A, user 17/11): vuốt hoặc bấm mũi tên qua các
/// ảnh của cùng bữa; đầu màn có tên bữa và "2/3". Ảnh thật tải qua URL có auth khi có API.
class MealPhotoViewerScreen extends StatefulWidget {
  const MealPhotoViewerScreen({
    super.key,
    required this.date,
    required this.meal,
    required this.photos,
    this.initialIndex = 0,
  });

  final DateTime date;
  final MenuMeal meal;
  final PostedMealPhotos photos;
  final int initialIndex;

  @override
  State<MealPhotoViewerScreen> createState() => _MealPhotoViewerScreenState();
}

class _MealPhotoViewerScreenState extends State<MealPhotoViewerScreen> {
  late int _index = widget.initialIndex;
  late final _pages = PageController(initialPage: widget.initialIndex);

  int get _count => widget.photos.photoIds.length;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) => _pages.animateToPage(
    index,
    duration: AppMotion.base,
    curve: AppMotion.curve,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(AppIcons.close),
        ),
        title: Text(widget.meal.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.pagePadding),
            child: Center(
              child: Text(
                '${_index + 1}/$_count',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _count,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  // Ảnh vuông lớn nhất vừa khung: chữ hệ thống lớn làm khung thấp đi
                  child: LayoutBuilder(
                    builder: (context, constraints) => Center(
                      child: SizedBox.square(
                        dimension: constraints.biggest.shortestSide,
                        child: Semantics(
                          container: true,
                          image: true,
                          label:
                              'Ảnh ${index + 1} trong $_count của ${widget.meal.name.toLowerCase()}',
                          excludeSemantics: true,
                          child: const AppPhotoPlaceholder(aspectRatio: 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Ảnh trước',
                  onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                  icon: const Icon(AppIcons.back),
                ),
                for (var i = 0; i < _count; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.space2),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? AppColors.primary
                          : AppColors.borderStrong,
                    ),
                  ),
                ],
                IconButton(
                  tooltip: 'Ảnh sau',
                  onPressed: _index < _count - 1
                      ? () => _goTo(_index + 1)
                      : null,
                  icon: const Icon(AppIcons.chevronRight),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateLabels.weekdayDayMonth(widget.date)} · ${widget.meal.dishes}',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    'Ảnh mẫu nhóm ${widget.photos.ageGroup} · Bếp đăng lúc ${DateLabels.time24(widget.photos.postedAt)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
