# Definition of Done — CareNest_APP

Agent và developer đối chiếu trước khi báo hoàn thành. Bỏ qua mục không áp dụng, nhưng nêu lý do.

## Code
- [ ] Không business rule ở client (suất ăn, định lượng, dị ứng, trend, field phụ huynh); dẫn chiếu rule ID BE khi màn hình phụ thuộc rule.
- [ ] Không implement rule PENDING/OPEN như đã chốt (P-03, P-04, P-06, P-07, P-13b, P-15...).
- [ ] Ẩn UI không thay phân quyền; 401/403/404 xử lý đúng.
- [ ] Gọi API qua lớp client chung; xử lý envelope `{code, desc, data}` theo HTTP status (`docs/integration/BACKEND_INTEGRATION.md`).
- [ ] Không thêm dependency/thư viện nền khi chưa được duyệt.
- [ ] Theo `.claude/rules/` và comment theo `CLAUDE.md`.

## Privacy & security
- [ ] Token chỉ trong secure storage; logout xóa token, cache, offline queue.
- [ ] Không dữ liệu trẻ thật, ảnh trẻ, token, secret trong code, fixture, log, crash report, screenshot.
- [ ] Push (nếu chạm) không mang dữ liệu nhạy cảm; deep link tải lại qua API.

## UX states
- [ ] Loading / empty / error / offline / 403 / hết phiên đều có xử lý.
- [ ] Nhập hàng loạt: chặn double-submit, giữ dữ liệu khi lỗi mạng, rõ đã lưu/chưa lưu.
- [ ] Tiếng Việt hiển thị đúng, chữ dài không vỡ layout; không truyền thông tin chỉ bằng màu.

## Test & kiểm chứng
- [ ] Test cho hành vi chính; bug fix có regression test fail-trước/pass-sau (hoặc bước kiểm tra tay ghi rõ khi chưa có test runner).
- [ ] Đã chạy test/build, báo kết quả thật; nêu nền tảng (Android/iOS), emulator hay máy thật, BE thật hay mock.

## Contract & docs
- [ ] Endpoint mới/thiếu ⇒ đề xuất contract cho BE; không tự sửa BE/FE.
- [ ] Màn hình mới/đổi ⇒ `docs/architecture/NAVIGATION.md` + `docs/features/<role>/README.md`.
- [ ] Feature bắt đầu/xong, chốt thư viện, PENDING được chốt ⇒ `docs/context/CURRENT_STATE.md`.
- [ ] Chốt thư viện nền/auth/push ⇒ bỏ header SKELETON và điền doc tương ứng.

## Engineering memory
- [ ] Lỗi không hiển nhiên / thử >1 cách / chỉ trên 1 nền tảng / lỗi môi trường >15 phút ⇒ incident + dòng `ISSUE_INDEX.md` (kèm các cách đã thử thất bại).
- [ ] Lỗi môi trường ⇒ mục `TROUBLESHOOTING.md`.
- [ ] Bẫy của màn hình ⇒ 1 dòng "Known pitfalls" trong feature doc.
- [ ] Bài học tổng quát ⇒ `PATTERNS.md`. Giới hạn còn tồn tại ⇒ `KNOWN_ISSUES.md`.
- [ ] Lỗi contract/nghiệp vụ ⇒ đề xuất mục cho `BE:docs/knowledge/CROSS_MODULE_ISSUES.md`.
