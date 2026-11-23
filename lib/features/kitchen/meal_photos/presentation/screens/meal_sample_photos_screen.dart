import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/image_picker_camera.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/meal_photos_status.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/widgets/meal_photo_widgets.dart';

/// Bếp · Ảnh mẫu bữa ăn theo nhóm tuổi (canvas "Màn bếp theo nhóm tuổi (B)", user duyệt 18/11):
/// chọn nhóm tuổi trước, rồi chụp từng bữa nhóm đó ăn theo cấu hình của Hiệu trưởng. Mỗi bữa
/// ít nhất 1 ảnh, chỉ đăng trong giờ đăng (NUT-16). BE chưa có API theo nhóm tuổi ⇒ dữ liệu giả.
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

  /// Nhóm bếp đã chọn; chưa chọn ⇒ mở nhóm đầu tiên còn bữa cần chụp
  String? _groupId;

  /// Bữa đang chụp hoặc đang đăng theo "nhóm|bữa": khoá nút để không đăng trùng.
  final Set<String> _posting = {};

  /// Lỗi vừa gặp theo "nhóm|bữa": báo ngay trong thẻ bữa.
  final Map<String, String> _errors = {};

  /// Ảnh vừa chụp mà đăng lỗi: giữ lại để đăng lại, không bắt chụp lại (CODING_GUIDE §7.1).
  final Map<String, Uint8List> _unsent = {};

  static const _cameraError =
      'Không mở được camera. Kiểm tra quyền camera rồi thử lại.';
  static const _uploadError =
      'Chưa đăng được ảnh vừa chụp. Kiểm tra mạng rồi đăng lại.';

  static String _key(AgeGroupMeals group, SampleMeal meal) =>
      '${group.id}|${meal.id}';

  static AgeGroupMeals _defaultGroup(KitchenPhotoDay day) =>
      day.groups
          .where(
            (group) => group.meals.any(
              (meal) => meal.status == MealPhotoStatus.needed,
            ),
          )
          .firstOrNull ??
      day.groups.first;

  Future<void> _takePhoto(AgeGroupMeals group, SampleMeal meal) async {
    final key = _key(group, meal);
    setState(() {
      // Giữ nhóm đang chụp, không nhảy sang nhóm khác khi nhóm này đủ ảnh
      _groupId = group.id;
      _posting.add(key);
    });
    final Uint8List? bytes;
    try {
      bytes = await _camera.takePhoto();
    } catch (_) {
      // Bị từ chối quyền hoặc máy không có app camera
      if (!mounted) return;
      setState(() {
        _posting.remove(key);
        _errors[key] = _cameraError;
      });
      return;
    }
    if (!mounted) return;
    if (bytes == null) {
      // Bếp huỷ chụp: không đăng, giữ nguyên báo lỗi cũ (nếu có)
      setState(() {
        _posting.remove(key);
      });
      return;
    }
    await _post(group, meal, bytes);
  }

  Future<void> _post(
    AgeGroupMeals group,
    SampleMeal meal,
    Uint8List bytes,
  ) async {
    final key = _key(group, meal);
    setState(() {
      _posting.add(key);
      _errors.remove(key);
      _unsent.remove(key);
    });
    try {
      final day = await _source.addPhoto(
        groupId: group.id,
        mealId: meal.id,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _posting.remove(key);
        _day = Future.value(day);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posting.remove(key);
        _errors[key] = _uploadError;
        _unsent[key] = bytes;
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
              if (day != null)
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
    if (day.isDayOff) {
      return const Center(
        child: AppEmptyState(
          title: 'Hôm nay trường nghỉ',
          message: 'Không có bữa nào cần ảnh mẫu.',
        ),
      );
    }
    if (day.groups.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: AppIcons.camera,
          title: 'Hôm nay không có bữa cần chụp',
          message: 'Hiệu trưởng chưa cấu hình bữa ăn cho nhóm tuổi nào.',
        ),
      );
    }
    final group =
        day.groups.where((item) => item.id == _groupId).firstOrNull ??
        _defaultGroup(day);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _DayProgress(day: day),
        const SizedBox(height: AppSpacing.space5),
        _GroupTiles(
          groups: day.groups,
          selectedId: group.id,
          onSelect: (id) => setState(() {
            _groupId = id;
          }),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _GroupHeader(group: group),
        const SizedBox(height: AppSpacing.space4),
        for (final (i, meal) in group.meals.indexed)
          MealTimelineItem(
            status: meal.status,
            isLast: i == group.meals.length - 1,
            child: MealPhotoCard(
              key: ValueKey('meal-card-${meal.name}'),
              groupName: group.name,
              meal: meal,
              posting: _posting.contains(_key(group, meal)),
              error: _errors[_key(group, meal)],
              unsent: _unsent[_key(group, meal)],
              onCapture: () => _takePhoto(group, meal),
              onRetry: () {
                if (_unsent[_key(group, meal)] case final bytes?) {
                  _post(group, meal, bytes);
                }
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

/// Tiến độ cả ngày: số phần (nhóm × bữa) đã có ảnh trên tổng số phần.
class _DayProgress extends StatelessWidget {
  const _DayProgress({required this.day});

  final KitchenPhotoDay day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = day.groups.fold(0, (sum, group) => sum + group.meals.length);
    final done = day.groups.fold(0, (sum, group) => sum + group.doneMeals);
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
          Text('$done/$total phần đã có ảnh mẫu', style: textTheme.titleMedium),
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

/// Ô nhóm tuổi xếp 2 cột, các ô cùng hàng cao bằng nhau.
class _GroupTiles extends StatelessWidget {
  const _GroupTiles({
    required this.groups,
    required this.selectedId,
    required this.onSelect,
  });

  final List<AgeGroupMeals> groups;
  final String selectedId;
  final ValueChanged<String> onSelect;

  Widget _tile(AgeGroupMeals group) => AgeGroupTile(
    key: ValueKey('group-tile-${group.id}'),
    group: group,
    selected: group.id == selectedId,
    onTap: () => onSelect(group.id),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < groups.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space2),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _tile(groups[i])),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: i + 1 < groups.length
                      ? _tile(groups[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Tên nhóm đang xem và các bữa nhóm ăn theo cấu hình của Hiệu trưởng.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final AgeGroupMeals group;

  /// "bữa phụ sáng, bữa trưa và bữa chiều"
  static String _mealList(List<SampleMeal> meals) {
    final names = meals.map(MealPhotosStatus.inSentence).toList();
    if (names.length < 2) return names.join();
    return '${names.take(names.length - 1).join(', ')} và ${names.last}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(group.name, style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '${group.ageRange} · ăn ${_mealList(group.meals)}',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.info, size: AppSizes.iconBadge, color: muted?.color),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                'Bữa theo cấu hình của Hiệu trưởng · mỗi bữa ít nhất 1 ảnh',
                style: muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
