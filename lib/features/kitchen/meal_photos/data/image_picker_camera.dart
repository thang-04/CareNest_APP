import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';

/// Mở app camera của máy qua `image_picker` (user duyệt 17/11), camera sau. Ảnh thu nhỏ
/// cạnh dài 1600 px, JPEG chất lượng 80; giới hạn upload thật chờ API (CODING_GUIDE §7.1).
/// Android không khai quyền CAMERA nên không phải xin quyền; huỷ chụp ⇒ null.
class ImagePickerSamplePhotoCamera implements SamplePhotoCamera {
  ImagePickerSamplePhotoCamera({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    return file?.readAsBytes();
  }
}
