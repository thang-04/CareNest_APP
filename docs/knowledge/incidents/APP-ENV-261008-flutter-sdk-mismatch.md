---
id: APP-ENV-261008-flutter-sdk-mismatch
type: env
roles: [all]
screens: [toolchain]
platforms: [both]
be_refs: []
status: workaround
date: 2026-10-08
keywords: [Flutter, Dart, SDK, version solving failed, enforce-lockfile, Windows]
similar_to: []
---
# APP-ENV-261008-flutter-sdk-mismatch — SDK cũ chặn resolve package

## Symptom
    The current Dart SDK version is 3.11.5.
    Because carenest_app requires SDK version ^3.12.0, version solving failed.

SDK mới thử với lockfile cũ:
    Would change 5 dependencies.
    Unable to satisfy `pubspec.yaml` using `pubspec.lock`.

## Điều kiện tái hiện
Windows 11 25H2 (10.0.26200.9457), repo branch dev; chưa chạy app Android/iOS.
PATH/IDE chọn Flutter 3.41.8 / Dart 3.11.5 tại D:\Flutter_Setup\flutter.
Dự án yêu cầu Dart ^3.12.0; chưa có package config, analyzer báo không resolve được flutter_lints.

## Attempts — đã thử
| # | Cách thử | Kết quả | Bài học |
| --- | --- | --- | --- |
| 1 | flutter doctor -v bằng SDK trên PATH | Flutter 3.41.8 / Dart 3.11.5; Android SDK có, license chưa đủ | SDK có nhưng phiên bản không đáp ứng |
| 2 | flutter pub get --offline bằng SDK cũ | Exit 1, version solving failed | Lỗi xảy ra trước bước mạng hoặc tải package |
| 3 | node scripts/verify.mjs bằng SDK cũ | Format ok, analyze FAIL, test chưa chạy | Cảnh báo import là hệ quả resolve thất bại |
| 4 | Tải Flutter stable mới nhất theo manifest chính thức | Flutter 3.47.6 / Dart 3.13.5 chạy được; SHA256 ZIP khớp | Manifest dùng /flutter_infra_release/releases/releases_windows.json; URL cũ có thêm /flutter/ trả 404 |
| 5 | SDK mới: flutter pub get --enforce-lockfile trước khi được duyệt đổi dependency | Exit 65; lockfile không đổi; cần cập nhật 5 package | Chuyển SDK còn cần đồng bộ dependency SDK |
| 6 | User duyệt; flutter pub get bằng SDK mới | Exit 0; đúng 5 package đổi; SDK tự thêm analyzer.exclude | Giữ migration bỏ qua thư mục build/nền tảng sinh tự động |
| 7 | node scripts/verify.mjs bằng SDK mới | PASS: format/analyze ok, 27 test, fail 0, skip 0 | Đã kiểm chứng dự án với SDK mới |
| 8 | enforce-lockfile sau cập nhật | Exit 0, hash lockfile không đổi | Dependency đã đồng bộ và ổn định |

## Root cause
Thiết bị/môi trường: SDK trên PATH thấp hơn pubspec.yaml:22 (Dart ^3.12.0) và pubspec.lock:262-263 (Flutter >=3.44.0). Lỗi lộ trong checkout này vì máy chọn SDK 3.41.8, trong khi dự án/lockfile được tạo bằng SDK mới hơn.
Flutter 3.47.6 cần intl 0.20.3, matcher 0.12.20, meta 1.19.0, test_api 0.7.12, vector_math 2.4.3. Bằng chứng: output pub get và pubspec flutter/flutter_localizations/flutter_test của SDK mới.

## Fix
SDK mới: D:\Flutter_Setup\stable-3.47.6\flutter. User đã duyệt cập nhật lockfile trên dev. Đã đồng bộ đúng 5 package, pub get/enforce-lockfile exit 0 và verify PASS 27 test. Flutter tự cập nhật analyzer.exclude trong analysis_options.yaml. Status workaround vì các lệnh kiểm tra chỉ chọn SDK qua PATH tiến trình; SDK IDE/PATH mặc định chưa đổi hoặc kiểm chứng.

## Regression test
Trước sửa: pub get bằng SDK cũ exit 1; enforce-lockfile bằng SDK mới với lock cũ exit 65.
Sau sửa: pub get và enforce-lockfile exit 0; node scripts/verify.mjs → VERIFY PASS full | format ok | analyze ok | tests 27 fail 0 skip 0 | 47s | log verify.log. Lockfile ổn định sau enforce-lockfile; manifest/source/test không đổi.
Emulator/máy thật Android/iOS và SDK trong IDE chưa kiểm chứng.

## Ảnh hưởng
Chặn resolve, analyze và test toàn APP; không cần đổi BE/FE hay nghiệp vụ.
Android license và thiếu C++ workload cho Windows desktop là vấn đề riêng.

## Lesson
Đối chiếu SDK thực sự được PATH/IDE nhận với pubspec và lockfile. Tải SDK mới còn cần chọn đúng SDK, resolve package và chạy verify.