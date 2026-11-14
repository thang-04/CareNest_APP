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
| State/DI | `flutter_riverpod` | CONFIRMED (chưa thêm vào `pubspec.yaml`) | user, 2026-11-13 |
| HTTP client · JSON | `dio` · `json_serializable` | CONFIRMED (chưa thêm) | user, 2026-11-13 |
| Đăng nhập | PKCE qua trang Keycloak (theme CareNest), `flutter_appauth`; không password grant | CONFIRMED (chưa thêm) | user, 2026-11-13 |
| Lưu token | `flutter_secure_storage` (Keystore/Keychain) | CONFIRMED (chưa thêm) | user, 2026-11-13 |
| Push | FCM: `firebase_core` + `firebase_messaging` | CONFIRMED (chưa thêm) | user, 2026-11-13 |
| Nền tảng | Sản phẩm Android + iOS; Capstone chỉ build và kiểm thử Android (iOS cần tài khoản Apple Developer cho APNs) | CONFIRMED | user, 2026-11-14 |
| Offline | Không hỗ trợ. Mất mạng ⇒ báo lỗi, giữ dữ liệu đã nhập trên màn để gửi lại; không lưu xuống máy, không hàng đợi | CONFIRMED | user, 2026-11-14 |
| Tài khoản nhiều role | Mở chế độ GV sau đăng nhập; chuyển sang chế độ phụ huynh ở màn Tài khoản; nhớ chế độ lần cuối (`docs/architecture/NAVIGATION.md`) | CONFIRMED | user, 2026-11-14 |

## Ràng buộc đã biết (dùng được)

- Client mỏng: BE sở hữu rule, authz, contract (`BE:docs/system/CROSS_REPO_MAP.md`). APP không chứa logic tính toán nghiệp vụ.
- Một app cho 3 role (Parent, Teacher, Kitchen Staff), tách luồng theo role sau đăng nhập (`NAVIGATION.md`).
- 1 trường / 2 campus — ngữ cảnh campus/lớp/con là dữ liệu từ BE, không cấu hình tenant.
- Dữ liệu trẻ, sức khỏe, ảnh, token: lưu tối thiểu, mã hóa, xóa khi logout (`.claude/rules/security-storage.md`).
- Push không mang dữ liệu nhạy cảm; deep link mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).
- Thiết bị: giáo viên nhập trên điện thoại cá nhân hoặc máy trường — chưa khảo sát.

## Còn mở (hỏi trước khi chọn)

- [ ] Thêm dependency đã duyệt 13/11 vào `pubspec.yaml` — làm trong plan nền App (cần mã Jira)
- [ ] Môi trường (dev/staging/prod), base URL + API prefix (`lib/core/config/env.dart` đọc `--dart-define`)
- [ ] Integration test/E2E, CI build, phát hành (store/nội bộ)
- [ ] Crash report/analytics (nếu có) + chính sách dữ liệu
