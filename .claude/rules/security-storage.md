---
paths:
  - "lib/core/storage/**/*.dart"
  - "lib/core/notifications/**/*.dart"
  - "lib/features/auth/**/*.dart"
  - "lib/features/shared/notifications/**/*.dart"
  - "lib/**/*log*.dart"
  - "lib/**/offline/**/*.dart"
---

# Security & on-device storage rules

> Auth: PKCE qua Keycloak (`flutter_appauth`); token: access trong bộ nhớ, refresh/id trong `flutter_secure_storage` (CONFIRMED — user 2026-11-13). Push: FCM, làm ở Phase 7. Xem `docs/integration/AUTH_FLOW.md`, `PUSH_NOTIFICATION.md`.

## Token
- Token chỉ trong OS secure storage (Keychain/Keystore) qua `TokenStorage` (`lib/core/storage/`), không SharedPreferences, file thường hay state persist; access token chỉ trong bộ nhớ.
- Không log, không gửi token vào crash report/analytics; không đưa vào URL/query string.
- Logout ⇒ xóa token, cache, offline queue, device push token đăng ký với BE (khi có endpoint).

## Dữ liệu trẻ & sức khỏe
- Mặc định **không persist**. Nếu offline cần lưu (vd. batch điểm danh chưa gửi): chỉ ID + giá trị tối thiểu, lưu mã hóa, xóa ngay khi gửi thành công hoặc logout.
- Ảnh trẻ: không lưu vào thư viện ảnh/thư mục công khai; cache ảnh (nếu có) trong vùng riêng của app và xóa khi logout.
- Màn hình nhạy cảm (sức khỏe, dị ứng) cân nhắc ẩn nội dung trong app switcher — hỏi trước khi áp dụng toàn app.

## Log, crash report, analytics
- Không ghi tên trẻ, ngày sinh, dữ liệu sức khỏe, dị ứng, ảnh, nội dung quan sát. Dùng ID/kiểu sự kiện.
- Chọn SDK crash/analytics ⇒ hỏi trước; tắt tự thu thập network body/screenshot.

## Push
- Payload chỉ chứa loại sự kiện + ID để deep link; nội dung hiển thị chung ("Có cập nhật mới về con"). Không xử lý dữ liệu nhạy cảm từ payload — luôn tải lại qua API có auth.
