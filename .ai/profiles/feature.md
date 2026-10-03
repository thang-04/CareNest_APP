# Profile FEATURE — màn hình / luồng mới, tích hợp API

Mức: L2. Bắt đầu từ **actor và outcome**, không từ component.

Đọc:
1. `docs/features/<role>/README.md` — nhóm màn hình, BE flow/card/rule ID, mục PENDING.
2. `docs/architecture/NAVIGATION.md` — vị trí màn hình trong cây điều hướng của role.
3. BE module card (`.ai/CONTEXT_MAP.yaml` → `keywords` → `be_module_card`) + flow trong card; rule ID trong `BE:docs/business/BUSINESS_RULES.md`.
4. `docs/integration/BACKEND_INTEGRATION.md` + `BE:docs/contracts/API_CONVENTIONS.md`, `ERROR_CONTRACT.md` khi gọi API.
5. `.claude/rules/` theo loại file.

Kiểm tra trước khi code:
- Rule cần dùng CONFIRMED/ACCEPTED? PENDING/OPEN ⇒ hỏi, hoặc thiết kế UI chịu được cả hai phương án (ẩn theo dữ liệu/permission BE trả về).
- Endpoint đã có trong contract BE? Chưa ⇒ ghi thay đổi cần thống nhất, không tự bịa shape.
- Trạng thái màn hình: loading / empty / error / offline / không có quyền (403) / hết phiên (401).
- Dữ liệu nhạy cảm: hiển thị gì, cache gì, log gì (`.claude/rules/security-storage.md`).
- Dữ liệu cho phụ huynh: chỉ field BE trả trong DTO phụ huynh (ADR-0010); không lọc/ẩn field ở client thay cho BE.
