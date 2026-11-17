import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:carenest_app/features/kitchen/meal_photos/data/image_picker_camera.dart';

/// Ghi lại cách camera được mở; trả [file] (null = bếp huỷ).
class _FakePicker extends ImagePicker {
  _FakePicker(this.file);

  final XFile? file;
  ImageSource? source;
  double? maxWidth;
  double? maxHeight;
  int? imageQuality;
  CameraDevice? device;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    this.imageQuality = imageQuality;
    device = preferredCameraDevice;
    return file;
  }
}

void main() {
  test(
    'Camera ảnh mẫu: mở camera sau, thu nhỏ ảnh, trả đúng ảnh vừa chụp',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final picker = _FakePicker(XFile.fromData(bytes));
      final photo = await ImagePickerSamplePhotoCamera(
        picker: picker,
      ).takePhoto();
      expect(photo, bytes);
      expect(picker.source, ImageSource.camera);
      expect(picker.device, CameraDevice.rear);
      expect(picker.maxWidth, 1600);
      expect(picker.maxHeight, 1600);
      expect(picker.imageQuality, 80);
    },
  );

  test('Camera ảnh mẫu: bếp huỷ ⇒ không có ảnh', () async {
    final camera = ImagePickerSamplePhotoCamera(picker: _FakePicker(null));
    expect(await camera.takePhoto(), isNull);
  });
}
