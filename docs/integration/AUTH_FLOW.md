# Auth Flow — Mobile

> **Cập nhật 2026-11-25:** nền đăng nhập là code PR #8 của Tiền (`lib/core/integration/mobile_session.dart`), thêm kích hoạt tài khoản, chế độ GV ↔ phụ huynh, `prompt=login`, hết phiên (plan `docs/plans/active/2026-11-16-app-be-integration.md`, Phase R). BE `docs/contracts/AUTH_CONTRACT.md`: Keycloak authorization code + PKCE, client `carenest-mobile`, redirect `carenest://oauth/callback`. Chưa chạy trên Android thật.

## Đã biết (dùng được)
- Quyền = Role × Permission ∩ Access scope, kiểm tra ở BE (`BE:docs/business/USER_ROLES.md`, AUTH-07). APP chỉ ẩn/hiện UI theo dữ liệu BE.
- 401 / 403 trả envelope `{code, errorCode, desc, data}` như mọi lỗi khác (`BACKEND_INTEGRATION.md`).
- Refresh token trong OS secure storage (khóa `auth.refresh`); access token ở bộ nhớ. Đăng xuất xóa phiên cục bộ và cố gắng hủy đăng ký thiết bị bằng phiên cũ; ngoại tuyến không khẳng định server đã hủy.

## Luồng
1. **Cấu hình:** `--dart-define-from-file=env/local.json` với `CARENEST_API_BASE_URL`, `CARENEST_OIDC_ISSUER` (`MobileConfig`). Bản debug thiếu cấu hình ⇒ Đăng nhập giả + Xem thử; có cấu hình (hoặc bản release) ⇒ router phiên thật (`_buildLiveRouter`).
2. **Đăng nhập:** `MobileSession.signIn({loginHint})` mở trang Keycloak (`flutter_appauth`, scope `openid profile`, `promptValues: ['login']` — máy dùng chung luôn hỏi mật khẩu, AUTH-22). Xong ⇒ `GET /accounts/me` lưu ở `session.account`.
3. **Chọn chế độ** (`LiveModeController`, ADR-0022): `TEACHER` → `KITCHEN_STAFF` → `PARENT` (phụ huynh cần `childIds` không rỗng); chế độ cuối lưu theo `userId` (`LastModeStore`); chuyển bằng nút ở Trang chủ (G94-385). Không có chế độ nào (BGH, Admin — AUTH-21) ⇒ `/live/unsupported` "dùng trên Web".
4. **Ảnh chân dung:** App **không buộc** cập nhật khi đăng nhập (user chốt 13/11); `profileUpdateRequired` của `/accounts/me` không chặn phiên. Ảnh phụ huynh lấy ở hồ sơ tiếp nhận (PCK-02).
5. **Kích hoạt tài khoản** (AUTH-18, ADR-0026): link trên màn Đăng nhập ⇒ `/activate`; `POST /parent-activation` (công khai, `MobileApi.publicJson`) trả `username` ⇒ mở Keycloak có sẵn tên. 400/1006 ⇒ "Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã."
6. **Làm mới token:** token còn < 30 giây ⇒ refresh trước khi gửi; 401 ⇒ refresh 1 lần rồi gửi lại 1 lần (`MobileApi`). Keycloak trả `invalid_grant` ⇒ xóa phiên, `expired = true`, về Đăng nhập kèm "Phiên đăng nhập đã hết. Vui lòng đăng nhập lại."; lỗi mạng giữ phiên.
7. **Mở lại App:** `restore()` dùng refresh token trong secure storage; hỏng ⇒ coi như chưa đăng nhập.
8. **Đăng xuất:** hủy đăng ký thiết bị push, POST `{issuer}/protocol/openid-connect/logout` (lỗi mạng vẫn xóa trên máy), xóa phiên và con đang chọn.

## Còn chờ
- [ ] Quên mật khẩu qua SMS: chờ BE G94-87; bản thật không có lối vào.
- [ ] Hồ sơ cá nhân, Đổi mật khẩu ở chế độ thật: hiện "Sắp có".
- [ ] Chạy trên Android thật theo checklist Task R7 của plan.

## Kiểm contract với Keycloak local
`CARENEST_SEED_PASSWORD=<mật khẩu seed> node scripts/check-auth-contract.mjs` (đổi đích bằng `CARENEST_OIDC_ISSUER`, `CARENEST_API_BASE_URL`).
