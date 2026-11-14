---
paths:
  - "lib/core/storage/**/*.dart"
  - "lib/core/notifications/**/*.dart"
  - "lib/features/auth/**/*.dart"
  - "lib/features/notifications/**/*.dart"
  - "lib/**/*log*.dart"
  - "lib/**/offline/**/*.dart"
---

# Security & on-device storage rules

> Đã chốt: đăng nhập PKCE, `flutter_secure_storage`, push FCM (user 13–14/11). Phần auth/push còn trống: hỏi trước khi chọn. Xem `docs/integration/AUTH_FLOW.md`, `PUSH_NOTIFICATION.md`.

## Token
- Token chỉ trong OS secure storage (Keychain/Keystore) qua `flutter_secure_storage` (user 2026-11-13), không SharedPreferences, file thường hay state persist.
- Không log, không gửi token vào crash report/analytics; không đưa vào URL/query string.
- Logout ⇒ xóa token, cache, offline queue, device push token đăng ký với BE (khi có endpoint).

## Dữ liệu trẻ & sức khỏe
- **Không persist** dữ liệu trẻ. Không có offline (user 2026-11-14): batch điểm danh chưa gửi chỉ giữ trong state của màn, không ghi xuống máy.
- Ảnh trẻ: không lưu vào thư viện ảnh/thư mục công khai; cache ảnh (nếu có) trong vùng riêng của app và xóa khi logout.
- Màn hình nhạy cảm (sức khỏe, dị ứng) cân nhắc ẩn nội dung trong app switcher — hỏi trước khi áp dụng toàn app.

## Log, crash report, analytics
- Không ghi tên trẻ, ngày sinh, dữ liệu sức khỏe, dị ứng, ảnh, nội dung quan sát. Dùng ID/kiểu sự kiện.
- Chọn SDK crash/analytics ⇒ hỏi trước; tắt tự thu thập network body/screenshot.

## Push
- Payload chỉ chứa loại sự kiện + ID để deep link; nội dung hiển thị chung ("Có cập nhật mới về con"). Không xử lý dữ liệu nhạy cảm từ payload — luôn tải lại qua API có auth.
