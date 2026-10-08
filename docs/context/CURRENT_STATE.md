# Current State — CareNest_APP

Cập nhật: 2026-10-08. **Agent: cập nhật file này khi màn hình/feature bắt đầu có code hoặc xong, khi chốt thư viện nền, hoặc khi một PENDING ảnh hưởng APP được chốt.**

## Tổng quan

| Hạng mục | Trạng thái |
| --- | --- |
| Source code APP | Flutter project khởi tạo; đang làm nền móng UI (plan `docs/plans/active/2026-10-08-flutter-ui-foundation.md`) |
| AI context + docs | Bản đầu (routing, workflow, feature map theo role) |
| Framework | Flutter CONFIRMED (user, 2026-10-08) — quy chuẩn `DESIGN.md` |
| Thư viện nền | Navigation: `go_router` CONFIRMED · state, HTTP, secure storage, push: chưa chọn (`docs/architecture/MOBILE_ARCHITECTURE.md`) |
| Auth | Chờ BE chốt (`BE:docs/contracts/AUTH_CONTRACT.md` SKELETON; `docs/integration/AUTH_FLOW.md` SKELETON) — không tự chọn cơ chế, hỏi |
| Push provider | Chờ chốt (`docs/integration/PUSH_NOTIFICATION.md` SKELETON) — không tự chọn, hỏi |
| BE | Đã có skeleton nền móng (response chuẩn, prefix API, OpenAPI); chưa có auth và nghiệp vụ — xem `BE:docs/context/CURRENT_STATE.md` |

## Feature theo role

| Role | Thiết kế (docs) | Code | Chặn bởi |
| --- | --- | --- | --- |
| Parent | Map màn hình (báo nghỉ: ATT-05 đã chốt, không duyệt) | — | P-13b (field), OBS-07 (hoạt động hằng ngày), auth |
| Teacher | Map màn hình | — | P-03 (cut-off), P-11 (tiêu chí quan sát), auth |
| Kitchen | Map màn hình | — | P-04 (adjustment), P-06 (bếp theo campus), P-07 (thực đơn), auth |
| Chưa gán role | Xác nhận số suất (`meal-count:confirm`) | — | P-05 (ai xác nhận) |

## PENDING ảnh hưởng APP (nguồn: `BE:docs/business/BUSINESS_RULES.md` Pending register)

P-03 cut-off nhập · P-04 xử lý suất điều chỉnh · P-05 ai xác nhận số suất · P-06 bếp theo campus/trung tâm · P-07 thực đơn chung/riêng · P-11 tiêu chí quan sát · P-12 summary có gửi phụ huynh · P-13b field phụ huynh xem · P-17 dị ứng ai khai báo. OPEN: OBS-07 nguồn hoạt động (ADR-0006).

Màn hình phụ thuộc PENDING: UI theo dữ liệu BE trả, không hard-code; chưa đăng ký route cho tới khi chốt (`docs/architecture/NAVIGATION.md`).

Đã đóng: P-15 (2026-10-02) — đơn nghỉ là thông báo của phụ huynh qua app, không duyệt (ATT-05).

## Kế tiếp
- Chốt state/DI, HTTP client, secure storage (`docs/architecture/MOBILE_ARCHITECTURE.md` mục Còn mở).
- Chờ BE chốt auth ⇒ điền `docs/integration/AUTH_FLOW.md`.
- Tồn đọng harness (user hoãn 2026-10-08): khi bắt đầu code BE/FE, chép `scripts/verify.mjs` + `scripts/__tests__/verify.test.mjs` (thêm nhánh Flutter, sửa quote `.bat` trên Windows) sang hai repo đó; sửa `siblings` trong `.claude/hooks/harness.config.json` theo vị trí thật (`../../be/CareNest_BE`, `../../fe/CareNest_FE`) để `node scripts/check-ai-layer.mjs --cross-repo` chạy được. Hiện bản ở BE/FE cũ hơn nhưng không ảnh hưởng chạy Maven/npm.
