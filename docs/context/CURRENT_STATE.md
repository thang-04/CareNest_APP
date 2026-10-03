# Current State — CareNest_APP

Cập nhật: 2026-10-03. **Agent: cập nhật file này khi màn hình/feature bắt đầu có code hoặc xong, khi chốt thư viện nền, hoặc khi một PENDING ảnh hưởng APP được chốt.**

## Tổng quan

| Hạng mục | Trạng thái |
| --- | --- |
| Source code APP | Chưa có |
| AI context + docs | Bản đầu (routing, workflow, feature map theo role) |
| Framework | React Native PROPOSED |
| Thư viện nền (navigation, state, HTTP, secure storage, push) | Chưa chọn |
| Auth | Chờ BE chốt (`BE:docs/contracts/AUTH_CONTRACT.md` SKELETON) |
| Push provider | Chờ chốt |
| BE | Đã có skeleton nền móng (response chuẩn, prefix API, OpenAPI); chưa có auth và nghiệp vụ — xem `BE:docs/context/CURRENT_STATE.md` |

## Feature theo role

| Role | Thiết kế (docs) | Code | Chặn bởi |
| --- | --- | --- | --- |
| Parent | Map màn hình | — | P-13b (field), P-15 (đơn nghỉ), auth |
| Teacher | Map màn hình | — | P-03 (cut-off), P-11 (tiêu chí quan sát), auth |
| Kitchen | Map màn hình | — | P-04 (adjustment), P-06 (bếp theo campus), P-07 (menu), auth |

## PENDING ảnh hưởng APP (nguồn: `BE:docs/business/BUSINESS_RULES.md` Pending register)

P-03 cut-off nhập · P-04 xử lý suất điều chỉnh · P-06 bếp theo campus/trung tâm · P-07 menu chung/riêng · P-11 tiêu chí quan sát · P-12 summary có gửi phụ huynh · P-13b field phụ huynh xem · P-15 đơn nghỉ ai tạo/duyệt · P-17 dị ứng ai khai báo.

## Kế tiếp
- Chốt framework + thư viện nền (ADR/ghi vào `docs/architecture/`).
- Chờ BE chốt auth ⇒ điền `docs/integration/AUTH_FLOW.md`.
