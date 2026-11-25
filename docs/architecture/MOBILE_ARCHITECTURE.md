# Mobile Architecture

> Quy chuẩn chi tiết: code (thư mục, luồng dữ liệu, auth) ở `docs/architecture/CODING_GUIDE.md`; giao diện (token, theme, widget) ở `DESIGN.md` gốc repo. File này chỉ ghi các quyết định đã chốt và phần còn mở.

## Quyết định đã chốt

| Hạng mục | Chọn | Status | Nguồn |
| --- | --- | --- | --- |
| Framework | Flutter (Dart), package `carenest_app` | CONFIRMED | user, 2026-10-08 |
| Kiến trúc | Feature-based + Clean Architecture: `lib/core/`, `lib/features/<feature>/{data,domain,presentation}`, `lib/routing/` | CONFIRMED | `CODING_GUIDE.md` §2, §3 |
| Thư mục feature theo vai trò | `lib/features/<vai trò>/<feature>/{data,domain,presentation}` với vai trò `auth`, `shared` (dùng chung nhiều vai trò), `teacher`, `parent`, `kitchen`, `management` (màn BGH cũ, giữ tham khảo); `test/features/` cùng cấu trúc | CONFIRMED | user, 2026-11-15 |
| Navigation | `go_router`; cấu hình ở `lib/routing/` | CONFIRMED | user, 2026-10-08 |
| Theme | Light theme duy nhất, token ở `lib/core/constants/`, theme ở `lib/core/theme/` | CONFIRMED | `DESIGN.md` §3, §B2 |
| Font | BeVietnamPro đóng gói trong `assets/fonts/` (OFL) | CONFIRMED | user, 2026-10-08 |
| Nền tảng build | Android, iOS; `web/` giữ để xem nhanh khi phát triển. Đã bỏ `linux/`, `macos/`, `windows/` (khôi phục: `flutter create --platforms=windows,macos,linux .`) | CONFIRMED | user, 2026-11-15 |
| Mở trình gọi điện | `url_launcher` (^6.3.2), chỉ dùng scheme `tel` cho nút Gọi phụ huynh ở màn Trả trẻ | CONFIRMED | user, 2026-11-15 |
| Chụp ảnh | `image_picker` (^1.2.4), chỉ mở camera cho bếp chụp ảnh mẫu bữa ăn; Android không khai quyền CAMERA (plugin gọi app camera của máy), iOS có `NSCameraUsageDescription`. Lock cần Flutter ≥ 3.47 | CONFIRMED | user, 2026-11-17 |
| Verify | `node scripts/verify.mjs` ⇒ `dart format` check + `flutter analyze` + `flutter test` | CONFIRMED | user, 2026-10-08 |
| State/DI | `ChangeNotifier` + `StatefulWidget`; dependency truyền qua constructor, ghép ở `lib/app.dart` + `lib/routing/app_router.dart` (Riverpod gỡ 2026-11-25) | CONFIRMED | user, 2026-11-24; plan `docs/plans/active/2026-11-16-app-be-integration.md` |
| HTTP | `MobileApi` (`lib/core/integration/mobile_api.dart`, `dart:io` `HttpClient`, PR #8 của Tiền): `json`, `publicJson`, `multipart`, `binary`; lỗi `ApiFailure` | CONFIRMED | user, 2026-11-24 |
| JSON | Map tay trong `Live<X>Source` (không code gen; `json_serializable` gỡ 2026-11-25) | CONFIRMED | user, 2026-11-24 |
| Auth | `MobileSession`: PKCE qua Keycloak bằng `flutter_appauth` (`prompt=login`), refresh token trong `flutter_secure_storage`; chế độ GV ↔ phụ huynh ở `LiveModeController` | CONFIRMED | user, 2026-11-13 / 2026-11-24; `docs/integration/AUTH_FLOW.md` |
| Push | FCM (`firebase_core` + `firebase_messaging`) qua `PushCoordinator` (PR #8); chạy thật cần `google-services.json` (không commit) và BE gửi FCM | CONFIRMED | user, 2026-11-13; Tiền 2026-11-17 |
| Môi trường | `--dart-define-from-file=env/local.json` (mẫu `env/local.example.json`, khóa `CARENEST_API_BASE_URL`, `CARENEST_OIDC_ISSUER`, `APP_ENV`); debug chưa cấu hình ⇒ Đăng nhập giả + Xem thử | CONFIRMED | plan 2026-11-16, cập nhật 2026-11-25 |

## Ràng buộc đã biết (dùng được)

- Client mỏng: BE sở hữu rule, authz, contract (`BE:docs/system/CROSS_REPO_MAP.md`). APP không chứa logic tính toán nghiệp vụ.
- Một app cho 3 role (Parent, Teacher, Kitchen Staff), tách luồng theo role sau đăng nhập (`NAVIGATION.md`).
- 1 trường / 2 campus — ngữ cảnh campus/lớp/con là dữ liệu từ BE, không cấu hình tenant.
- Dữ liệu trẻ, sức khỏe, ảnh, token: lưu tối thiểu, mã hóa, xóa khi logout (`.claude/rules/security-storage.md`).
- Push không mang dữ liệu nhạy cảm; deep link mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).
- Thiết bị: Android + iOS (PROPOSED); giáo viên nhập trên điện thoại cá nhân hoặc máy trường — chưa khảo sát.

## Còn mở (hỏi trước khi chọn)

- [x] State/DI, HTTP client, secure storage, push SDK — chốt (bảng trên)
- [x] Base URL + API prefix: `API_BASE_URL` gồm `/api` (`lib/core/config/env.dart`)
- [ ] Môi trường staging/prod (URL HTTPS của BE + Keycloak) — chốt ở Phase 9
- [ ] Integration test/E2E, CI build, phát hành (store/nội bộ)
- [ ] Crash report/analytics (nếu có) + chính sách dữ liệu
