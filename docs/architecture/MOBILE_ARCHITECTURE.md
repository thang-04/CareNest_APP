# Mobile Architecture

> **Status: CHƯA CÓ NỘI DUNG — không dùng làm nguồn.** Chưa có source; framework (React Native) và thư viện nền chưa chốt. Agent không tự chọn — hỏi người dùng, trình bày phương án + trade-off.

## Ràng buộc đã biết (dùng được)

- Client mỏng: BE sở hữu rule, authz, contract (`BE:docs/system/CROSS_REPO_MAP.md`). APP không chứa logic tính toán nghiệp vụ.
- Một app cho 3 role (Parent, Teacher, Kitchen Staff), tách luồng theo role sau đăng nhập (`NAVIGATION.md`).
- 1 trường / 2 campus — ngữ cảnh campus/lớp/con là dữ liệu từ BE, không cấu hình tenant.
- Dữ liệu trẻ, sức khỏe, ảnh, token: lưu tối thiểu, mã hóa, xóa khi logout (`.claude/rules/security-storage.md`).
- Push không mang dữ liệu nhạy cảm; deep link mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).
- Thiết bị: Android + iOS (PROPOSED); giáo viên nhập trên điện thoại cá nhân hoặc máy trường — chưa khảo sát.

## Điền khi chốt

- [ ] Framework + phiên bản; Expo hay bare (nếu React Native)
- [ ] Cấu trúc thư mục `src/` (cập nhật `paths` trong `.claude/rules/`)
- [ ] Navigation, state/cache, HTTP client, form, secure storage, push SDK
- [ ] Môi trường (dev/staging/prod), cấu hình base URL + API prefix
- [ ] Test (unit/component/E2E), CI build, phát hành (store/nội bộ)
- [ ] Crash report/analytics (nếu có) + chính sách dữ liệu
