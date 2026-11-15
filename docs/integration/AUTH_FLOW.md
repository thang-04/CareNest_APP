# Auth Flow — Mobile

> **Status: MỘT PHẦN.** Đã chốt cách đăng nhập, lưu token, quên mật khẩu (có API trên nhánh BE), tài khoản nhiều role (mục "Đã chốt"). Endpoint me/logout, thời hạn token chờ BE (`BE:docs/contracts/AUTH_CONTRACT.md`). Phần còn trống: không tự chọn — hỏi.

## Đã chốt
- **Đăng nhập:** PKCE qua trang đăng nhập Keycloak có theme CareNest, thư viện `flutter_appauth` (user 2026-11-13). BE mobile client không cho password grant (`directAccessGrantsEnabled` = false). Theme Keycloak là task BE riêng.
- **Lưu token:** chỉ trong OS secure storage qua `flutter_secure_storage` (user 2026-11-13); không SharedPreferences. Logout xóa token, cache, device push token (`.claude/rules/security-storage.md`). Không offline nên không có hàng đợi dữ liệu (user 2026-11-14).
- **Đăng nhập lần đầu:** chỉ đổi mật khẩu tạm; không bắt tải ảnh chân dung (BE PCK-02, `profileUpdateRequired` luôn `false`, user 2026-11-13).
- **Quên mật khẩu (BE AUTH-27, user 2026-11-13/14):** phụ huynh, GV, bếp cùng một luồng; mã OTP gửi SMS tới SĐT đăng nhập (nhân sự và phụ huynh đều đăng nhập bằng SĐT). Tài khoản bếp dùng chung (AUTH-22): SĐT đăng nhập là SĐT tổ trưởng bếp do HT/PHT nhập khi tạo tài khoản, BE không có field riêng. Màn nằm trong App (P-41 đóng 14/11), UI có sẵn ở `/forgot-password`.
  - API (`BE:docs/contracts/AUTH_CONTRACT.md`): `GET /auth/csrf` ⇒ `POST /auth/password/forgot/sms` `{phone}` ⇒ `POST /auth/password/otp/{requestId}/verify` `{otp}` ⇒ `POST /auth/password/reset` `{token,newPassword,confirmPassword}` ⇒ đăng nhập lại qua PKCE. Gửi lại mã: `POST /auth/password/otp/{requestId}/resend` (cách 60 giây).
  - Mọi POST `/auth/**` gửi header `X-XSRF-TOKEN` và cookie `XSRF-TOKEN` lấy từ `GET /auth/csrf`; nhận 403 `FORBIDDEN` 1101 ⇒ lấy CSRF mới, gửi lại 1 lần.
  - OTP 6 số, hạn 5 phút, sai tối đa 5 lần; tối đa 5 lần gửi mỗi 30 phút theo SĐT. Phản hồi giống nhau dù SĐT có tài khoản hay không (không lộ tài khoản); SĐT sai định dạng ⇒ 400.
  - Code BE ở nhánh `feature/G94-87-BE-FEAT-0-app-rules-sms-reset`, chưa vào `dev`; môi trường phải bật `CARENEST_AUTH_ENABLED=true`. SMS hiện là cổng giả (`FakeSmsGateway`); SMS thật chờ nhánh BE G94-298 (Twilio).
- **Tài khoản nhiều role** (GV kiêm phụ huynh, user 2026-11-14): sau đăng nhập mở chế độ GV; màn Tài khoản có nút chuyển chế độ phụ huynh/GV; App nhớ chế độ dùng lần cuối. BE không nhận vai trò đang chọn từ client, lọc role theo client của token (`azp`, ADR-0022). BGH chỉ xem trên App (ADR-0026).
- Quyền = Role × Permission ∩ Access scope, kiểm tra ở BE (`BE:docs/business/USER_ROLES.md`, AUTH-07). APP chỉ ẩn/hiện UI theo dữ liệu BE.
- 401 / 403 trả envelope `{code, desc, data}` như mọi lỗi khác (`BACKEND_INTEGRATION.md`).

## Điền khi BE chốt
- [ ] Endpoint me (user + role + scope tóm tắt), logout/thu hồi phiên
- [ ] Thời hạn access/refresh token; xoay vòng refresh; thu hồi
- [ ] Luồng 401: refresh 1 lần, hàng đợi request song song, thất bại ⇒ Login
- [ ] Đăng ký/hủy device push token gắn với phiên
- [x] API SMS OTP: gửi mã, xác minh, đặt mật khẩu mới; số lần thử, thời hạn mã; màn nằm trong App (mục "Quên mật khẩu" ở trên)
