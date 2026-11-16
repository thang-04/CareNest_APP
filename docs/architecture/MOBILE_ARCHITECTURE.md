# Mobile Architecture

> Quy chuẩn chi tiết: code (thư mục, luồng dữ liệu, auth) ở `docs/architecture/CODING_GUIDE.md`; giao diện (token, theme, widget) ở `DESIGN.md` gốc repo. File này chỉ ghi các quyết định đã chốt và phần còn mở.

## Quyết định đã chốt

| Hạng mục | Chọn | Status | Nguồn |
| --- | --- | --- | --- |
| Framework | Flutter (Dart), package `carenest_app` | CONFIRMED | user, 2026-10-08 |
| Kiến trúc | Feature-based + Clean Architecture: `lib/core/`, `lib/features/<feature>/{data,domain,presentation}`, `lib/routing/` | CONFIRMED | `CODING_GUIDE.md` §2, §3 |
| Navigation | `go_router`; cấu hình ở `lib/routing/` | CONFIRMED | user, 2026-10-08 |
| Theme | Light theme duy nhất, token ở `lib/core/constants/`, theme ở `lib/core/theme/` | CONFIRMED | `DESIGN.md` §3, §B2 |
| Font | BeVietnamPro đóng gói trong `assets/fonts/` (OFL) | CONFIRMED | user, 2026-10-08 |
| Verify | `node scripts/verify.mjs` ⇒ `dart format` check + `flutter analyze` + `flutter test` | CONFIRMED | user, 2026-10-08 |
| State/DI | `flutter_riverpod` 3.x (`Provider`, `Notifier`); ghép ở `lib/bootstrap.dart` + `authOverrides` | CONFIRMED | user, 2026-11-13; plan `docs/plans/active/2026-11-16-app-be-integration.md` |
| HTTP | `dio` qua `ApiClient` (`lib/core/network/`) | CONFIRMED | user, 2026-11-13 |
| JSON | `json_serializable` + `json_annotation`, `build_runner`; file `*.g.dart` được commit | CONFIRMED | user, 2026-11-13 / 2026-11-16 |
| Auth | PKCE qua Keycloak bằng `flutter_appauth`; token trong `flutter_secure_storage` | CONFIRMED | user, 2026-11-13; `docs/integration/AUTH_FLOW.md` |
| Push | FCM (`firebase_core` + `firebase_messaging`), làm ở Phase 7 sau khi BE gửi FCM thật | CONFIRMED (chưa thêm gói) | user, 2026-11-13 / 2026-11-16 |
| Môi trường | `--dart-define-from-file=env/local.json` (mẫu `env/local.example.json`); `USE_MOCK=true` mặc định giữ dữ liệu giả | CONFIRMED | plan 2026-11-16 |

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
