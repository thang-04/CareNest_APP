# Current State — CareNest_APP

Cập nhật: 2026-10-13. **Agent: cập nhật file này khi màn hình/feature bắt đầu có code hoặc xong, khi chốt thư viện nền, hoặc khi một PENDING ảnh hưởng APP được chốt.**

## Tổng quan

| Hạng mục | Trạng thái |
| --- | --- |
| Source code APP | Đã dựng lại UI theo mockup 5 vai trò (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`, ảnh `docs/design/figma/`): Phase 1 xong khung tab 5 vai trò + widget chung mới; Phase 2 xong Đăng nhập, Quên mật khẩu/OTP/Đặt mật khẩu, Thông báo, Tài khoản, Thông tin cá nhân dùng chung; Phase 3 xong 10 màn Phụ huynh (P02–P05, P08–P13); Phase 4 xong 13 màn Giáo viên (T01–T07.1, T09, T10, T15–T16); Phase 5 xong 7 màn Bếp (K01–K07); Phase 6 xong 9 màn Phó HT (V01–V07, V10, V12); Phase 7 xong 6 màn Hiệu trưởng (H01, H02, H04, H06–H08); màn theo vai trò vẫn từ plan `docs/plans/completed/2026-10-10-ui-redesign-mobile.md`, **dữ liệu giả**, chưa gọi API. Màn theo role chỉ có trong debug (xem `docs/architecture/NAVIGATION.md`) |
| AI context + docs | Bản đầu (routing, workflow, feature map theo role) |
| Framework | Flutter CONFIRMED (user, 2026-10-08) — quy chuẩn `DESIGN.md` |
| Thư viện nền | Navigation: `go_router` CONFIRMED · state, HTTP, secure storage, push: chưa chọn (`docs/architecture/MOBILE_ARCHITECTURE.md`) |
| Auth | Chờ BE chốt (`BE:docs/contracts/AUTH_CONTRACT.md` SKELETON; `docs/integration/AUTH_FLOW.md` SKELETON) — không tự chọn cơ chế, hỏi |
| Push provider | Chờ chốt (`docs/integration/PUSH_NOTIFICATION.md` SKELETON) — không tự chọn, hỏi |
| BE | Đã có skeleton nền móng (response chuẩn, prefix API, OpenAPI); chưa có auth và nghiệp vụ — xem `BE:docs/context/CURRENT_STATE.md` |

## Feature theo role

| Role | Thiết kế (docs) | Code | Chặn bởi |
| --- | --- | --- | --- |
| Parent | Map màn hình (báo nghỉ: ATT-05 đã chốt, không duyệt) | UI dữ liệu giả theo mockup: Trang chủ, Xin nghỉ + Đơn đã gửi, Thực đơn tuần, Bé của tôi (Hôm nay/Sức khỏe/Phát triển), Hoạt động, Điểm danh tháng, Hồ sơ bé | P-13b (field), OBS-07 (hoạt động hằng ngày), auth |
| Teacher | Map màn hình | UI dữ liệu giả theo mockup: Trang chủ, Điểm danh & báo ăn, Đơn nghỉ lớp, Đánh giá hằng ngày, Đón trẻ, Đo sức khỏe, Lớp học, Lịch hoạt động, Ảnh bữa ăn | P-03 (cut-off), P-11 (tiêu chí quan sát), auth |
| Kitchen | Map màn hình | UI dữ liệu giả theo mockup: Trang chủ, Thực đơn theo nhóm tuổi, Suất ăn theo lớp, Định lượng, Nhận nguyên liệu + Báo thiếu (PROPOSED), Trạng thái nấu | P-04 (adjustment), P-06 (bếp theo campus), P-07 (thực đơn), auth |
| Vice Principal | Map màn hình (user chốt có trên app 2026-10-13) | UI dữ liệu giả theo mockup: Trang chủ cơ sở, Yêu cầu chờ duyệt, Duyệt điều chỉnh suất, Chốt suất, Trạng thái bếp, Thực đơn tuần, Cân đối dinh dưỡng, Trẻ của cơ sở, Đề xuất khen thưởng | P-05 (chốt suất), P-04, P-14, OBS-10, auth |
| Principal | Map màn hình (user chốt có trên app 2026-10-13) | UI dữ liệu giả theo mockup: Tổng quan toàn trường, Chờ Hiệu trưởng duyệt, Khen thưởng cuối năm, Danh sách trẻ toàn trường, Thực đơn tuần theo cơ sở, Cơ sở & Phó HT phụ trách | OBS-10, P-07, P-11, auth |
| Chưa gán role | Xác nhận số suất (`meal-count:confirm`) — mockup giao Phó HT | Màn giả ở nhánh Phó HT (V04), chỉ debug | P-05 (ai xác nhận) |

## PENDING ảnh hưởng APP (nguồn: `BE:docs/business/BUSINESS_RULES.md` Pending register)

P-03 cut-off nhập · P-04 xử lý suất điều chỉnh · P-05 ai xác nhận số suất · P-06 bếp theo campus/trung tâm · P-07 thực đơn chung/riêng · P-11 tiêu chí quan sát · P-12 summary có gửi phụ huynh · P-13b field phụ huynh xem · P-17 dị ứng ai khai báo. OPEN: OBS-07 nguồn hoạt động (ADR-0006).

Màn hình phụ thuộc PENDING: UI theo dữ liệu BE trả, không hard-code; chưa đăng ký route cho tới khi chốt (`docs/architecture/NAVIGATION.md`).

Đã đóng: P-15 (2026-10-02) — đơn nghỉ là thông báo của phụ huynh qua app, không duyệt (ATT-05).

## Kế tiếp
- UI mockup 5 vai trò xong (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`): đưa các khoảng trống contract / rule đã ghi ở `docs/features/*/README.md` sang BE (`BE:docs/knowledge/CROSS_MODULE_ISSUES.md`, cần user cho phép sửa BE), rồi nối API thay dữ liệu giả.
- Chốt state/DI, HTTP client, secure storage (`docs/architecture/MOBILE_ARCHITECTURE.md` mục Còn mở).
- Chờ BE chốt auth ⇒ điền `docs/integration/AUTH_FLOW.md`.
- Tồn đọng harness (user hoãn 2026-10-08): khi bắt đầu code BE/FE, chép `scripts/verify.mjs` + `scripts/__tests__/verify.test.mjs` (thêm nhánh Flutter, sửa quote `.bat` trên Windows) sang hai repo đó; sửa `siblings` trong `.claude/hooks/harness.config.json` theo vị trí thật (`../../be/CareNest_BE`, `../../fe/CareNest_FE`) để `node scripts/check-ai-layer.mjs --cross-repo` chạy được. Hiện bản ở BE/FE cũ hơn nhưng không ảnh hưởng chạy Maven/npm.
