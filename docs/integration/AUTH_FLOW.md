# Auth Flow — Mobile

> **Cập nhật 2026-11-16:** BE `docs/contracts/AUTH_CONTRACT.md` xác định Mobile dùng Keycloak authorization code + PKCE, client `carenest-mobile`, redirect `carenest://oauth/callback`. Tiền duyệt `flutter_appauth` và `flutter_secure_storage` cho spec 902. Tích hợp đang kiểm thử; chưa xác nhận trên Android thật.

## Đã biết (dùng được)
- Quyền = Role × Permission ∩ Access scope, kiểm tra ở BE (`BE:docs/business/USER_ROLES.md`, AUTH-07). APP chỉ ẩn/hiện UI theo dữ liệu BE.
- 401 / 403 trả envelope `{code, desc, data}` như mọi lỗi khác (`BACKEND_INTEGRATION.md`).
- Refresh token trong OS secure storage; access token ở bộ nhớ. Đăng xuất xóa phiên cục bộ và cố gắng hủy đăng ký thiết bị bằng phiên cũ; ngoại tuyến không khẳng định server đã hủy.

## Điền khi BE chốt
- [ ] Đăng nhập: tài khoản do trường cấp? SĐT/OTP cho phụ huynh?
- [ ] Endpoint login / refresh / logout / me (user + role + scope tóm tắt)
- [ ] Thời hạn access/refresh token; xoay vòng refresh; thu hồi
- [ ] Luồng 401: refresh 1 lần, hàng đợi request song song, thất bại ⇒ Login
- [ ] User nhiều role (vd. GV đồng thời là phụ huynh) ⇒ chọn role thế nào
- [ ] Đăng ký/hủy device push token gắn với phiên
- [ ] Đổi/quên mật khẩu
