import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:carenest_app/core/media/photo_picker.dart';

/// `image_picker` giả: ghi lại tham số, trả tệp có sẵn.
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.file);

  final XFile? file;
  ImageSource? source;
  double? maxWidth;
  int? quality;

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
    quality = imageQuality;
    return file;
  }
}

void main() {
  test('pick_camera_shrinksAndReturnsJpeg', () async {
    final fake = _FakeImagePicker(
      XFile.fromData(Uint8List.fromList([7, 8]), path: 'IMG_1.jpg'),
    );
    final photo = await ImagePickerPhotoPicker(
      picker: fake,
    ).pick(PhotoSource.camera);

    expect(fake.source, ImageSource.camera);
    expect(fake.maxWidth, 1080);
    expect(fake.quality, 85);
    expect(photo!.bytes, [7, 8]);
    expect(photo.filename, 'photo.jpg');
    expect(photo.contentType, 'image/jpeg');
  });

  test('pick_galleryPng_keepsPngType', () async {
    final fake = _FakeImagePicker(
      XFile.fromData(Uint8List.fromList([1]), path: 'anh.PNG'),
    );
    final photo = await ImagePickerPhotoPicker(
      picker: fake,
    ).pick(PhotoSource.gallery);

    expect(fake.source, ImageSource.gallery);
    expect(photo!.contentType, 'image/png');
  });

  test('pick_oddName_sendsFixedSafeFilename', () async {
    final fake = _FakeImagePicker(
      XFile.fromData(Uint8List.fromList([1]), path: 'Ảnh "mới".webp'),
    );
    final photo = await ImagePickerPhotoPicker(
      picker: fake,
    ).pick(PhotoSource.gallery);

    expect(photo!.filename, 'photo.webp');
    expect(photo.contentType, 'image/webp');
  });

  test('pick_cancelled_returnsNull', () async {
    final photo = await ImagePickerPhotoPicker(
      picker: _FakeImagePicker(null),
    ).pick(PhotoSource.camera);
    expect(photo, isNull);
  });
}
