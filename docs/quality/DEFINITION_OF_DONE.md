# Definition of Done — CareNest_APP

Agent và developer đối chiếu trước khi báo hoàn thành, theo làn (`AGENTS.md`). Bỏ qua mục không áp dụng, nhưng nêu lý do. Bằng chứng: `docs/quality/VERIFICATION.md`.

## Làn S (3 mục)
- [ ] Đúng phạm vi, không đổi contract/hành vi ngoài yêu cầu (đổi ⇒ đã qua `clarify-business.md`).
- [ ] Có test/bước kiểm cho thay đổi; bug fix có regression fail-trước/pass-sau.
- [ ] Dòng `VERIFY` (hoặc `Verify: chưa chạy — <lý do>`) trong lượt, sau lần sửa cuối.

Làn M/L: các mục dưới.

## Code
- [ ] Không business rule ở client (suất ăn, định lượng, dị ứng, trend, field phụ huynh); dẫn chiếu rule ID BE khi màn hình phụ thuộc rule.
- [ ] Không implement rule PENDING/OPEN như đã chốt (P-03, P-04, P-05, P-06, P-07, P-13b, OBS-07...).
- [ ] Ẩn UI không thay phân quyền; 401/403/404 xử lý đúng.
- [ ] Gọi API qua lớp client chung; xử lý envelope `{code, desc, data}` theo HTTP status (`docs/integration/BACKEND_INTEGRATION.md`).
- [ ] Không thêm dependency/thư viện nền khi chưa được duyệt.
- [ ] Theo `.claude/rules/` và comment theo `AGENTS.md`.

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
- [ ] Sửa `.ai/`, `.claude/`, `.agents/`, `docs/` ⇒ `node scripts/check-ai-layer.mjs` exit 0.
- [ ] Đã chạy `.ai/workflows/update-knowledge.md` nếu có trigger T1/T2/T3 (hoặc nêu 1 dòng vì sao không cần).
- [ ] Sửa skill ⇒ `.agents/skills` và `.claude/skills` giống hệt nhau (`diff -r .agents/skills .claude/skills`).
