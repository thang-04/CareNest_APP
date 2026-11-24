import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/media/photo_picker.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/features/shared/account/data/profile_photo_api.dart';

/// Phụ huynh chưa có ảnh chân dung (BE `profileUpdateRequired`, PCK-02): phải cập nhật trước
/// khi dùng App, để cô giáo nhận đúng người khi đón bé. Chỉ ảnh của chính phụ huynh.
class ProfilePhotoRequiredScreen extends StatefulWidget {
  const ProfilePhotoRequiredScreen({
    super.key,
    required this.api,
    required this.picker,
    required this.onSaved,
    required this.onSignOut,
  });

  final ProfilePhotoGateway api;
  final PhotoPicker picker;

  /// Tải lại tài khoản sau khi lưu; router tự rời màn này khi BE hết đòi ảnh.
  final Future<void> Function() onSaved;
  final Future<void> Function() onSignOut;

  @override
  State<ProfilePhotoRequiredScreen> createState() =>
      _ProfilePhotoRequiredScreenState();
}

class _ProfilePhotoRequiredScreenState
    extends State<ProfilePhotoRequiredScreen> {
  PickedPhoto? _photo;
  String? _error;
  bool _saving = false;

  Future<void> _pick(PhotoSource source) async {
    final photo = await widget.picker.pick(source);
    if (photo == null || !mounted) return;
    setState(() {
      _photo = photo;
      _error = null;
    });
  }

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.upload(photo);
      await widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        // 400 (vd. 1131 sai định dạng) ⇒ câu BE; còn lại coi như lỗi mạng
        _error = error is ApiFailure && error.status == 400
            ? error.message
            : 'Chưa lưu được ảnh. Kiểm tra mạng rồi thử lại.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photo = _photo;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Cập nhật ảnh chân dung'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            'Nhà trường cần ảnh chân dung của phụ huynh để cô giáo nhận đúng người khi đón bé.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppCard(
            child: photo == null
                ? const AppPhotoPlaceholder(caption: 'chân dung chưa chọn')
                : ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.memory(
                      photo.bytes,
                      height: AppSizes.heroHeight,
                      fit: BoxFit.cover,
                      semanticLabel: 'Ảnh chân dung đã chọn',
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: 'Chụp ảnh',
            icon: AppIcons.camera,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: _saving ? null : () => _pick(PhotoSource.camera),
          ),
          const SizedBox(height: AppSpacing.space3),
          AppButton(
            label: 'Chọn ảnh có sẵn',
            icon: AppIcons.gallery,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: _saving ? null : () => _pick(PhotoSource.gallery),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.space4),
            AppBanner(kind: AppBannerKind.danger, message: _error!),
          ],
          const SizedBox(height: AppSpacing.space4),
          Center(
            child: AppLinkButton(
              label: 'Đăng xuất',
              onPressed: _saving ? null : widget.onSignOut,
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Lưu ảnh',
            loadingLabel: 'Đang lưu ảnh',
            isLoading: _saving,
            expand: true,
            onPressed: photo == null ? null : _save,
          ),
        ],
      ),
    );
  }
}
