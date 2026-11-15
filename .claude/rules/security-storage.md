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

> Cơ chế auth (BE) và push provider chưa chốt; thư viện secure storage chưa chọn — hỏi trước khi chọn. Xem `docs/integration/AUTH_FLOW.md`, `PUSH_NOTIFICATION.md`.

## Token
- Policy PROPOSED: token chỉ trong OS secure storage (Keychain/Keystore), không SharedPreferences, file thường hay state persist; thư viện chưa chọn.
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
