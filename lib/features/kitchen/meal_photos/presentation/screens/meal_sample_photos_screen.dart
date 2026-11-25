import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/image_picker_camera.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/meal_photos_status.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/widgets/meal_photo_widgets.dart';

/// Bếp · Ảnh mẫu bữa ăn của điểm trường (NUT-16, user 25/11): mỗi bữa 1 ảnh như BE, chụp lại thì
/// thay ảnh cũ (có hộp xác nhận). Chỉ đăng trong giờ đăng do Hiệu trưởng đặt; ngoài giờ BE chặn.
class MealSamplePhotosScreen extends StatefulWidget {
  const MealSamplePhotosScreen({super.key, this.source, this.camera});

  final KitchenPhotoSource? source;

  /// Mặc định mở app camera của máy (`image_picker`).
  final SamplePhotoCamera? camera;

  @override
  State<MealSamplePhotosScreen> createState() => _MealSamplePhotosScreenState();
}

class _MealSamplePhotosScreenState extends State<MealSamplePhotosScreen> {
  late final KitchenPhotoSource _source =
      widget.source ?? FakeKitchenPhotoSource.shared;
  late final SamplePhotoCamera _camera =
      widget.camera ?? ImagePickerSamplePhotoCamera();
  late Future<KitchenPhotoDay> _day = _source.loadToday();

  /// Bữa đang chụp hoặc đang đăng: khoá nút để không đăng trùng.
  final Set<String> _posting = {};

  /// Lỗi vừa gặp theo bữa: báo ngay trong thẻ bữa.
  final Map<String, String> _errors = {};

  /// Ảnh vừa chụp mà đăng lỗi: giữ lại để đăng lại, không bắt chụp lại (CODING_GUIDE §7.1).
  final Map<String, Uint8List> _unsent = {};

  static const _cameraError =
      'Không mở được camera. Kiểm tra quyền camera rồi thử lại.';
  static const _uploadError =
      'Chưa đăng được ảnh vừa chụp. Kiểm tra mạng rồi đăng lại.';

  /// Lỗi BE (ngoài giờ đăng, ảnh quá lớn…) hiện câu BE; mất mạng hiện câu đăng lại.
  static String _uploadMessage(Object error) => switch (error) {
    ApiFailure(:final status, :final message)
        when status >= 400 && status < 500 && status != 401 =>
      message,
    _ => _uploadError,
  };

  /// Bữa đã có ảnh: BE thay ảnh cũ ⇒ hỏi trước khi chụp lại.
  Future<bool> _confirmRetake(SampleMeal meal) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      title: 'Chụp lại ảnh ${MealPhotosStatus.inSentence(meal)}?',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mỗi bữa chỉ giữ 1 ảnh. Ảnh mới sẽ thay ảnh đã đăng, ảnh cũ không xem lại được.',
            style: Theme.of(
              sheetContext,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: 'Chụp ảnh mới',
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.space2),
          AppButton(
            label: 'Giữ ảnh cũ',
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _takePhoto(SampleMeal meal) async {
    if (meal.photos.isNotEmpty && !await _confirmRetake(meal)) return;
    if (!mounted) return;
    setState(() => _posting.add(meal.id));
    final Uint8List? bytes;
    try {
      bytes = await _camera.takePhoto();
    } catch (_) {
      // Bị từ chối quyền hoặc máy không có app camera
      if (!mounted) return;
      setState(() {
        _posting.remove(meal.id);
        _errors[meal.id] = _cameraError;
      });
      return;
    }
    if (!mounted) return;
    if (bytes == null) {
      // Bếp huỷ chụp: không đăng, giữ nguyên báo lỗi cũ (nếu có)
      setState(() => _posting.remove(meal.id));
      return;
    }
    await _post(meal, bytes);
  }

  Future<void> _post(SampleMeal meal, Uint8List bytes) async {
    setState(() {
      _posting.add(meal.id);
      _errors.remove(meal.id);
      _unsent.remove(meal.id);
    });
    try {
      final day = await _source.addPhoto(mealId: meal.id, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _posting.remove(meal.id);
        _day = Future.value(day);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _posting.remove(meal.id);
        _errors[meal.id] = _uploadMessage(error);
        _unsent[meal.id] = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<KitchenPhotoDay>(
      future: _day,
      builder: (context, snapshot) {
        final day = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ảnh mẫu bữa ăn'),
            actions: [
              if (day != null && day.campusLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.pagePadding),
                  child: Center(child: _CampusLabel(label: day.campusLabel)),
                ),
            ],
          ),
          body: _body(context, snapshot),
        );
      },
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<KitchenPhotoDay> snapshot) {
    if (snapshot.hasError) {
      return Center(
        child: AppErrorState(
          title: 'Chưa tải được ảnh mẫu',
          message: loadFailureMessage(snapshot.error),
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
    if (day.isDayOff) {
      return const Center(
        child: AppEmptyState(
          title: 'Hôm nay trường nghỉ',
          message: 'Không có bữa nào cần ảnh mẫu.',
        ),
      );
    }
    if (day.meals.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: AppIcons.camera,
          title: 'Hôm nay không có bữa cần chụp',
          message: 'Hiệu trưởng chưa cấu hình bữa ăn cho nhóm tuổi nào.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _DayProgress(day: day),
        const SizedBox(height: AppSpacing.sectionGap),
        for (final (i, meal) in day.meals.indexed)
          MealTimelineItem(
            status: meal.status,
            isLast: i == day.meals.length - 1,
            child: MealPhotoCard(
              key: ValueKey('meal-card-${meal.name}'),
              meal: meal,
              posting: _posting.contains(meal.id),
              error: _errors[meal.id],
              unsent: _unsent[meal.id],
              loadPhoto: _source.loadPhoto,
              onCapture: () => _takePhoto(meal),
              onRetry: () {
                if (_unsent[meal.id] case final bytes?) _post(meal, bytes);
              },
            ),
          ),
      ],
    );
  }
}

/// Điểm trường của bếp; bếp gắn với một điểm trường nên không đổi được ở đây.
class _CampusLabel extends StatelessWidget {
  const _CampusLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.badgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardGap),
      alignment: Alignment.center,
      decoration: const ShapeDecoration(
        color: AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Tiến độ cả ngày: số bữa đã có ảnh trên tổng số bữa.
class _DayProgress extends StatelessWidget {
  const _DayProgress({required this.day});

  final KitchenPhotoDay day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = day.meals.length;
    final done = day.doneMeals;
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hôm nay · ${DateLabels.weekdayDayMonth(day.date)}',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text('$done/$total bữa đã có ảnh mẫu', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.space3),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: AppSpacing.space2,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              color: AppColors.toneGreen,
              backgroundColor: AppColors.track,
            ),
          ),
        ],
      ),
    );
  }
}
