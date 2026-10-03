# Workflow — Review code (Mobile)

Đọc mục tiêu thay đổi + diff + feature doc của role liên quan. Kiểm tra theo thứ tự ưu tiên:

1. **Business rule ở client:** APP có tự tính/quyết định thay BE không (số suất, định lượng, dị ứng, trend sức khỏe, field phụ huynh được xem)? Implement rule PENDING như đã chốt?
2. **Security & privacy:** token lưu ở đâu (`.claude/rules/security-storage.md`); dữ liệu trẻ/ảnh/sức khỏe trong log, crash report, analytics, cache không mã hóa; nội dung push; dữ liệu giả trong fixture. Ẩn nút có bị coi là phân quyền?
3. **Contract:** đọc đúng `{code, desc, data}`; xử lý theo HTTP status; không giả định field ngoài contract; phân trang `PageResponse`. Đối chiếu `docs/integration/BACKEND_INTEGRATION.md`.
4. **Async & state:** race khi đổi con/lớp/ngày; request cũ ghi đè state mới; double-submit; retry không idempotent; cache stale sau khi ghi; logout không xóa cache/state.
5. **UX states:** loading / empty / error / offline / 401 / 403; tiếng Việt; accessibility cơ bản.
6. **Navigation:** deep link có kiểm tra đăng nhập/role; back stack sau login/logout; màn hình theo role không lộ sang role khác.
7. **Test:** có test cho hành vi chính, regression cho bug fix?
8. **Convention:** `.claude/rules/`; không thêm dependency khi chưa được duyệt.
9. **Memory:** fix bug không hiển nhiên có incident + dòng `ISSUE_INDEX.md` chưa? Đối chiếu Known pitfalls + `PATTERNS.md`.

Mỗi phát hiện: vị trí, kịch bản gây lỗi, cách sửa. Phân biệt lỗi đã chứng minh với câu hỏi/giả định. Không tuyên bố đã chạy trên thiết bị nếu chỉ đọc tĩnh.
