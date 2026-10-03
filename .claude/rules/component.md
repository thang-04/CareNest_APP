---
paths:
  - "src/**/screens/**/*.{ts,tsx,js,jsx}"
  - "src/**/components/**/*.{ts,tsx,js,jsx}"
  - "src/**/features/**/*.tsx"
---

# Screen & component rules

> Glob và cấu trúc thư mục là PROPOSED (chưa có source; React Native PROPOSED). Source thực tế khác ⇒ theo source, cập nhật `paths`.

- Screen = điều phối: lấy dữ liệu qua hook/state layer, xử lý loading / empty / error / offline / 403, truyền props xuống. Component trình bày không gọi API, không đọc token.
- **Không business rule trong UI:** không tính số suất, định lượng, trend sức khỏe, không quyết định trẻ nào/field nào phụ huynh được xem. Hiển thị đúng giá trị BE trả (vd. trạng thái `CONFIRMED`, `APPROVED`).
- Ẩn/disable nút theo permission/trạng thái BE trả về chỉ là UX — BE vẫn kiểm tra (AUTH-07). Không hard-code role → quyền hành động trong component.
- Form nhập liệu: validation client chỉ để hỗ trợ (bắt buộc, format ngày, độ dài); lỗi 400 từ BE (`data` = `[{field, message}]`) phải map về đúng field.
- Màn hình nhập hàng loạt (điểm danh, báo ăn, quan sát): chặn double-submit, giữ dữ liệu đang nhập khi lỗi mạng, hiển thị rõ đã lưu / chưa lưu.
- Danh sách dài (lớp, thực đơn, lịch sử) dùng list ảo hóa của framework; key ổn định theo ID từ BE.
- Text hiển thị tiếng Việt, tập trung để dễ i18n sau; không ghép chuỗi chứa dữ liệu nhạy cảm vào log.
- Ảnh trẻ: chỉ hiển thị từ URL/API có auth; không lưu vào gallery/cache công khai; không đưa vào snapshot test.
- Accessibility cơ bản: nhãn cho nút icon, vùng chạm đủ lớn, không truyền thông tin chỉ bằng màu (vd. dị ứng phải có chữ/icon).
- Comment: theo `CLAUDE.md` mục "Comment trong code".
