---
paths:
  - "lib/routing/**/*.dart"
  - "lib/core/layouts/**/*.dart"
---

# Navigation rules

> Thư viện navigation: `go_router` (CONFIRMED 2026-10-08), cấu hình ở `lib/routing/`. Cây màn hình theo role: `docs/architecture/NAVIGATION.md` (nguồn chuẩn — cập nhật khi thêm màn hình).

- Tách stack/tab theo role (Parent / Teacher / Kitchen) sau đăng nhập; role lấy từ thông tin user BE trả, không từ input người dùng.
- Người dùng nhiều role (nếu có) ⇒ hỏi cách chọn role, không tự quyết.
- Chưa đăng nhập / hết phiên ⇒ về luồng auth và **xóa back stack** màn hình có dữ liệu trẻ.
- Deep link (từ push): parse an toàn, chỉ nhận ID + loại màn hình; kiểm tra đăng nhập + role trước khi mở; dữ liệu luôn tải lại qua API (BE kiểm tra scope). ID không thuộc scope ⇒ BE trả 403/404 ⇒ màn hình "không có quyền / không tìm thấy", không crash.
- Không truyền object dữ liệu nhạy cảm qua route params (có thể bị log/persist); truyền ID.
- Ngữ cảnh đang chọn (con, lớp, campus, ngày) là state, không hard-code trong route; đổi ngữ cảnh phải hủy request cũ.
- Màn hình PENDING (vd. field phụ huynh xem — P-13b) ⇒ không đăng ký route cho tới khi chốt, hoặc bật theo cờ cấu hình.
