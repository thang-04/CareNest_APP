import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/media/photo_picker.dart';

abstract interface class ProfilePhotoGateway {
  Future<void> upload(PickedPhoto photo);
}

/// Ảnh chân dung của tài khoản đang đăng nhập: `PUT /accounts/me/photo`, part `file` (PCK-02).
class ProfilePhotoApi implements ProfilePhotoGateway {
  const ProfilePhotoApi(this._api);

  final MobileApi _api;

  @override
  Future<void> upload(PickedPhoto photo) => _api.multipart(
    'PUT',
    '/accounts/me/photo',
    field: 'file',
    bytes: photo.bytes,
    filename: photo.filename,
    contentType: photo.contentType,
  );
}
