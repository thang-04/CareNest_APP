# Auth Flow — Mobile

> **Status: CHƯA CÓ NỘI DUNG — không dùng làm nguồn.** Cơ chế auth BE chưa chốt (`BE:docs/contracts/AUTH_CONTRACT.md` SKELETON; `BE:docs/backend-coding-guide.md` §2 chỉ định hướng JWT access + refresh, chưa triển khai). Agent không tự chọn cơ chế/thư viện — hỏi.

## Đã biết (dùng được)
- Quyền = Role × Permission ∩ Access scope, kiểm tra ở BE (`BE:docs/business/USER_ROLES.md`, AUTH-07). APP chỉ ẩn/hiện UI theo dữ liệu BE.
- 401 / 403 trả envelope `{code, desc, data}` như mọi lỗi khác (`BACKEND_INTEGRATION.md`).
- Token lưu secure storage của OS; logout xóa token + cache + offline queue (`.claude/rules/security-storage.md`).

## Điền khi BE chốt
- [ ] Đăng nhập: tài khoản do trường cấp? SĐT/OTP cho phụ huynh?
- [ ] Endpoint login / refresh / logout / me (user + role + scope tóm tắt)
- [ ] Thời hạn access/refresh token; xoay vòng refresh; thu hồi
- [ ] Luồng 401: refresh 1 lần, hàng đợi request song song, thất bại ⇒ Login
- [ ] User nhiều role (vd. GV đồng thời là phụ huynh) ⇒ chọn role thế nào
- [ ] Đăng ký/hủy device push token gắn với phiên
- [ ] Đổi/quên mật khẩu
