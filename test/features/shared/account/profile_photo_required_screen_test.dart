import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/media/photo_picker.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/shared/account/data/profile_photo_api.dart';
import 'package:carenest_app/features/shared/account/presentation/screens/profile_photo_required_screen.dart';

import '../../../helpers/pump_app.dart';

class _FakePicker implements PhotoPicker {
  PhotoSource? last;
  Object? failure;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    last = source;
    if (failure != null) throw failure!;
    return PickedPhoto(
      bytes: Uint8List.fromList(_png),
      filename: 'a.png',
      contentType: 'image/png',
    );
  }
}

class _FakeUpload implements ProfilePhotoGateway {
  Object? failure;
  PickedPhoto? uploaded;
  var calls = 0;

  @override
  Future<void> upload(PickedPhoto photo) async {
    calls++;
    if (failure != null) throw failure!;
    uploaded = photo;
  }
}

// PNG 1x1 trong suốt để Image.memory vẽ được
const _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

class _Setup {
  _Setup(this.picker, this.upload, this.events);

  final _FakePicker picker;
  final _FakeUpload upload;
  final List<String> events;
}

Future<_Setup> _pump(
  WidgetTester tester, {
  Future<void> Function()? onSaved,
}) async {
  usePhoneSize(tester);
  final picker = _FakePicker();
  final upload = _FakeUpload();
  final events = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: ProfilePhotoRequiredScreen(
        api: upload,
        picker: picker,
        onSaved: () async {
          events.add('saved');
          await onSaved?.call();
        },
        onSignOut: () async => events.add('signOut'),
      ),
    ),
  );
  await tester.pump();
  return _Setup(picker, upload, events);
}

Finder get _save => find.widgetWithText(AppButton, 'Lưu ảnh');

void main() {
  testWidgets('noPhoto_saveDisabled', (tester) async {
    await _pump(tester);
    expect(find.text('Cập nhật ảnh chân dung'), findsOneWidget);
    expect(tester.widget<AppButton>(_save).onPressed, isNull);
  });

  testWidgets('save_success_uploadsAndCallsOnSaved', (tester) async {
    final setup = await _pump(tester);
    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(setup.picker.last, PhotoSource.camera);
    expect(setup.upload.uploaded?.filename, 'a.png');
    expect(setup.events, ['saved']);
  });

  testWidgets('gallery_button_picksFromGallery', (tester) async {
    final setup = await _pump(tester);
    await tester.tap(find.text('Chọn ảnh có sẵn'));
    await tester.pumpAndSettle();
    expect(setup.picker.last, PhotoSource.gallery);
  });

  testWidgets('save_1131_showsBeMessage', (tester) async {
    final setup = await _pump(tester);
    setup.upload.failure = ApiFailure(
      400,
      'Chọn ảnh chân dung JPG, PNG hoặc WEBP',
      1131,
    );
    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(find.text('Chọn ảnh chân dung JPG, PNG hoặc WEBP'), findsOneWidget);
    expect(setup.events, isEmpty);
  });

  testWidgets('save_networkError_showsRetry', (tester) async {
    final setup = await _pump(tester);
    setup.upload.failure = const SocketException('offline');
    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa lưu được ảnh. Kiểm tra mạng rồi thử lại.'),
      findsOneWidget,
    );
  });

  testWidgets('signOut_link_callsSignOut', (tester) async {
    final setup = await _pump(tester);
    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(setup.events, ['signOut']);
  });

  testWidgets('pick_cameraError_showsMessage', (tester) async {
    final setup = await _pump(tester);
    setup.picker.failure = PlatformException(code: 'no_available_camera');

    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();

    expect(
      find.text('Không mở được camera hoặc thư viện ảnh. Thử lại.'),
      findsOneWidget,
    );
  });

  testWidgets('save_uploadOkReloadFails_retryReloadsOnly', (tester) async {
    var reloadFails = true;
    final setup = await _pump(
      tester,
      onSaved: () async {
        if (reloadFails) throw const SocketException('offline');
      },
    );
    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Đã lưu ảnh. Chưa tải lại được tài khoản, bấm Lưu ảnh để thử lại.',
      ),
      findsOneWidget,
    );

    reloadFails = false;
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(setup.upload.calls, 1);
    expect(setup.events, ['saved', 'saved']);
  });
}
