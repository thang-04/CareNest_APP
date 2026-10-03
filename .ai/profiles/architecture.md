# Profile ARCHITECTURE — kiến trúc client, thư viện nền, push, bảo mật thiết bị, release

Mức: L3–L4. Ưu tiên đủ bằng chứng hơn tiết kiệm token.

Đọc:
1. `docs/context/REPOSITORY_CONTEXT.md`, `docs/context/CURRENT_STATE.md`.
2. `docs/architecture/` (MOBILE_ARCHITECTURE, STATE_MANAGEMENT, NAVIGATION).
3. `docs/integration/` (BACKEND_INTEGRATION, AUTH_FLOW, PUSH_NOTIFICATION).
4. `BE:docs/system/CROSS_REPO_MAP.md`, `BE:docs/architecture/SECURITY.md`, `BE:docs/contracts/AUTH_CONTRACT.md`.
5. Source/config thực tế (package manifest, native project) nếu đã có.

Kiểm tra: lựa chọn có phụ thuộc quyết định BE chưa chốt (auth mechanism, push provider)? Lưu gì trên thiết bị, mã hóa ra sao? Ảnh hưởng cả 3 role? Chi phí build native/CI?

Chọn thư viện nền (navigation, state/cache, HTTP, push, secure storage) hoặc đổi kiến trúc ⇒ **hỏi người dùng trước**, trình bày phương án + trade-off; khi chốt cập nhật doc tương ứng (bỏ header SKELETON) và `CURRENT_STATE.md`. Quyết định ảnh hưởng BE ⇒ đề xuất ADR ở BE, không tự sửa BE.
