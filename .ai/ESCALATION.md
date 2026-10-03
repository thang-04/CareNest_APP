# Mở rộng context có điều kiện

- **L1 — cục bộ:** đọc source, test, screen/navigation/state và thay đổi gần khu vực cần xử lý nếu đã có.
- **L2 — feature Mobile:** thêm `REPO_CONTEXT.md`, luồng người dùng, API client thực tế và quyền; tra BE khi cần business rule hoặc hợp đồng.
- **L3 — liên repo:** kiểm tra BE và tác động FE khi cùng dùng endpoint hoặc auth; liệt kê nguồn đã xem và phần chưa có checkout.
- **L4 — hệ thống:** đọc đầy đủ các nhóm nguồn liên quan khi thay đổi kiến trúc, security, dữ liệu trẻ, token, thông báo hoặc phát hành lớn.

Không đọc toàn bộ repo cho task nhỏ. Nếu source/docs chưa có, ghi rõ khoảng trống thay vì tạo rule giả. Nếu code và tài liệu mâu thuẫn, xác minh intended behavior trước khi sửa.

