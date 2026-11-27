import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';

/// Xem ảnh một bữa toàn màn (BE: mỗi bữa một ảnh, NUT-16); phóng to bằng hai ngón.
/// Byte ảnh do màn thực đơn đã tải truyền vào, chỉ giữ trong bộ nhớ.
class MealPhotoViewerScreen extends StatelessWidget {
  const MealPhotoViewerScreen({
    super.key,
    required this.date,
    required this.meal,
    required this.bytes,
  });

  final DateTime date;
  final MenuMealEntry meal;

  /// null ⇒ khối giữ chỗ (Xem thử).
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photo = meal.photo;
    final image = bytes;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(AppIcons.close),
        ),
        title: Text(meal.session.label),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Semantics(
                  container: true,
                  image: true,
                  label: 'Ảnh ${meal.session.label.toLowerCase()}',
                  excludeSemantics: true,
                  child: image == null
                      ? const Center(child: AppPhotoPlaceholder(aspectRatio: 1))
                      : InteractiveViewer(
                          child: Image.memory(image, fit: BoxFit.contain),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateLabels.weekdayDayMonth(date)} · '
                    '${meal.dishes.map((d) => d.name).join(' · ')}',
                    style: textTheme.titleSmall,
                  ),
                  if (photo != null) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      'Bếp đăng lúc ${DateLabels.time24(photo.uploadedAt)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
