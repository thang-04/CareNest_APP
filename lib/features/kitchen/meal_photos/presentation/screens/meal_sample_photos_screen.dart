import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/image_picker_camera.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';

/// Bếp · Ảnh mẫu bữa ăn (NUT-16): mỗi bữa một ảnh cho cả cơ sở, đăng lại thì thay ảnh cũ
/// (BE `MealPhoto`, user chốt 18/11). Chỉ đăng trong khung giờ của bữa.
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
      widget.source ?? FakeKitchenPhotoSource();
  late final SamplePhotoCamera _camera =
      widget.camera ?? ImagePickerSamplePhotoCamera();
  late Future<KitchenPhotoDay> _day = _source.loadToday();

  /// Bữa đang đăng ảnh: khoá nút để không đăng trùng.
  final Set<MealSession> _posting = {};

  /// Lỗi vừa gặp theo bữa: báo ngay dưới nút.
  final Map<MealSession, String> _errors = {};

  /// Ảnh vừa chụp mà đăng lỗi: giữ lại để đăng lại, không bắt chụp lại (CODING_GUIDE §7.1).
  final Map<MealSession, Uint8List> _unsent = {};

  static const _cameraError =
      'Không mở được camera. Kiểm tra quyền camera rồi thử lại.';
  static const _uploadError =
      'Chưa đăng được ảnh vừa chụp. Kiểm tra mạng rồi đăng lại.';

  static (String, AppStatusTone) _badge(SampleMeal meal) => meal.photo != null
      ? ('Đã có ảnh', AppStatusTone.green)
      : switch (meal.window) {
          PhotoWindow.upcoming => ('Chưa tới giờ', AppStatusTone.gray),
          PhotoWindow.open => ('Cần chụp', AppStatusTone.orange),
          PhotoWindow.closed => ('Quá giờ, chưa có ảnh', AppStatusTone.red),
        };

  Future<void> _takePhoto(MealSession session) async {
    setState(() => _posting.add(session));
    final Uint8List? bytes;
    try {
      bytes = await _camera.takePhoto();
    } catch (_) {
      // Bị từ chối quyền hoặc máy không có app camera
      if (!mounted) return;
      setState(() {
        _posting.remove(session);
        _errors[session] = _cameraError;
      });
      return;
    }
    if (!mounted) return;
    if (bytes == null) {
      // Bếp huỷ chụp: không đăng
      setState(() => _posting.remove(session));
      return;
    }
    await _post(session, bytes);
  }

  Future<void> _post(MealSession session, Uint8List bytes) async {
    setState(() {
      _posting.add(session);
      _errors.remove(session);
      _unsent.remove(session);
    });
    try {
      final day = await _source.upload(session: session, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _posting.remove(session);
        _day = Future.value(day);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posting.remove(session);
        _errors[session] = _uploadError;
        _unsent[session] = bytes;
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
          if (day.meals.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: AppIcons.camera,
                title: 'Hôm nay không có bữa cần chụp',
                message: 'Nhà trường chưa cấu hình giờ đăng ảnh.',
              ),
            );
          }
          final textTheme = Theme.of(context).textTheme;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Text(
                '${DateLabels.weekdayDate(day.date)} · ${day.kitchenLabel}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              for (final meal in day.meals) ...[
                const SizedBox(height: AppSpacing.space3),
                _mealCard(context, meal),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _mealCard(BuildContext context, SampleMeal meal) {
    final textTheme = Theme.of(context).textTheme;
    final session = meal.session;
    final photo = meal.photo;
    final (badge, tone) = _badge(meal);
    return AppCard(
      key: ValueKey('meal-card-${session.code}'),
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
              Text(session.label, style: textTheme.titleSmall),
              AppStatusBadge(label: badge, tone: tone),
            ],
          ),
          if (photo != null) ...[
            const SizedBox(height: AppSpacing.space3),
            _PhotoTile(photo: photo),
          ],
          const SizedBox(height: AppSpacing.space2),
          Text(
            [
              if (photo != null) 'Đăng ${DateLabels.time24(photo.uploadedAt)}',
              meal.window == PhotoWindow.closed
                  ? 'Hết giờ đăng (${meal.windowLabel})'
                  : 'Giờ đăng ${meal.windowLabel}',
            ].join(' · '),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          if (meal.window == PhotoWindow.open) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: photo == null ? 'Chụp ảnh' : 'Chụp lại',
              icon: AppIcons.camera,
              variant: photo == null
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              small: true,
              expand: true,
              isLoading: _posting.contains(session),
              loadingLabel: 'Đang đăng ảnh…',
              onPressed: () => _takePhoto(session),
            ),
            if (_errors[session] case final error?) ...[
              const SizedBox(height: AppSpacing.space2),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.dangerText,
                  ),
                ),
              ),
            ],
            if (_unsent[session] case final bytes?) ...[
              const SizedBox(height: AppSpacing.space2),
              AppButton(
                label: 'Đăng lại ảnh',
                icon: AppIcons.refresh,
                variant: AppButtonVariant.text,
                small: true,
                onPressed: () => _post(session, bytes),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Ảnh đã đăng của bữa, khung 4:3. Ảnh vừa chụp hiện ảnh thật để bếp xem lại;
/// ảnh chưa có tệp (dữ liệu giả, chưa có URL) là ô giữ chỗ.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final SamplePhoto photo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Giải mã ảnh ở cỡ khung, không giữ ảnh 1600 px trong bộ nhớ
        final cacheWidth =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .round();
        return switch (photo.bytes) {
          final bytes? => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                semanticLabel: 'Ảnh mẫu vừa chụp',
              ),
            ),
          ),
          null => const AppPhotoPlaceholder(aspectRatio: 4 / 3),
        };
      },
    );
  }
}
