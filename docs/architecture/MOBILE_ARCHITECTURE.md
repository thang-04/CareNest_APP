# Mobile Architecture

> Quy chuẩn chi tiết (cấu trúc thư mục, theme, widget, luồng dữ liệu): `DESIGN.md` ở gốc repo. File này chỉ ghi các quyết định đã chốt và phần còn mở.

## Quyết định đã chốt

| Hạng mục | Chọn | Status | Nguồn |
| --- | --- | --- | --- |
| Framework | Flutter (Dart), package `carenest_app` | CONFIRMED | user, 2026-10-08 |
| Kiến trúc | Feature-based + Clean Architecture: `lib/core/`, `lib/features/<feature>/{data,domain,presentation}`, `lib/routing/` | CONFIRMED | `DESIGN.md` §2, §10 |
| Navigation | `go_router`; cấu hình ở `lib/routing/` | CONFIRMED | user, 2026-10-08 |
| Theme | Light theme duy nhất, token ở `lib/core/constants/`, theme ở `lib/core/theme/` | CONFIRMED | `DESIGN.md` §4, §9 |
| Font | BeVietnamPro đóng gói trong `assets/fonts/` (OFL) | CONFIRMED | user, 2026-10-08 |
| Verify | `node scripts/verify.mjs` ⇒ `dart format` check + `flutter analyze` + `flutter test` | CONFIRMED | user, 2026-10-08 |

## Ràng buộc đã biết (dùng được)

- Client mỏng: BE sở hữu rule, authz, contract (`BE:docs/system/CROSS_REPO_MAP.md`). APP không chứa logic tính toán nghiệp vụ.
- Một app cho 3 role (Parent, Teacher, Kitchen Staff), tách luồng theo role sau đăng nhập (`NAVIGATION.md`).
- 1 trường / 2 campus — ngữ cảnh campus/lớp/con là dữ liệu từ BE, không cấu hình tenant.
- Dữ liệu trẻ, sức khỏe, ảnh, token: lưu tối thiểu, mã hóa, xóa khi logout (`.claude/rules/security-storage.md`).
- Push không mang dữ liệu nhạy cảm; deep link mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).
- Thiết bị: Android + iOS (PROPOSED); giáo viên nhập trên điện thoại cá nhân hoặc máy trường — chưa khảo sát.

## Còn mở (hỏi trước khi chọn)

- [ ] State/DI (DESIGN đề xuất `flutter_riverpod` — PROPOSED)
- [ ] HTTP client (DESIGN đề xuất `dio` — PROPOSED), secure storage (`flutter_secure_storage` — PROPOSED), push SDK
- [ ] Môi trường (dev/staging/prod), base URL + API prefix (`lib/core/config/env.dart` đọc `--dart-define`)
- [ ] Integration test/E2E, CI build, phát hành (store/nội bộ)
- [ ] Crash report/analytics (nếu có) + chính sách dữ liệu
