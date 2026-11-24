import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Ảnh người dùng chọn, sẵn để gửi `multipart/form-data`.
@immutable
class PickedPhoto {
  const PickedPhoto({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

abstract interface class PhotoPicker {
  /// Huỷ chọn ⇒ null.
  Future<PickedPhoto?> pick(PhotoSource source);
}

/// Chụp hoặc chọn ảnh qua `image_picker` (user duyệt 17/11); thu nhỏ cạnh dài 1080 px, JPEG 85.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file == null) return null;
    final type = _typeOf(file.name);
    // Tên cố định: tên ảnh trong máy có thể chứa dấu nháy, chữ có dấu làm hỏng header multipart
    return PickedPhoto(
      bytes: await file.readAsBytes(),
      filename: 'photo.${type.split('/').last.replaceAll('jpeg', 'jpg')}',
      contentType: type,
    );
  }

  // BE nhận JPG, PNG, WEBP (mã 1131); image_picker nén lại thành JPEG trừ PNG/WEBP gốc
  static String _typeOf(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
