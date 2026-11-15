# Current State — CareNest_APP

Cập nhật: 2026-10-29 (đối chiếu rule BE chốt 29/10: đánh giá, sức khỏe, đón trẻ, hiển thị phụ huynh, thông báo; App tập trung cho phụ huynh và GV, bếp giữ màn tối thiểu — chỉ docs, code chưa đổi). Trước đó 2026-10-28 (đối chiếu rule BE chốt 27–28/10: AUTH-21 App chỉ cho Phụ huynh, Giáo viên, Bếp; điểm danh, sức khỏe đầu ngày, đơn nghỉ, bếp, thực đơn, dị ứng — chỉ docs, code chưa đổi). **Agent: cập nhật file này khi màn hình/feature bắt đầu có code hoặc xong, khi chốt thư viện nền, hoặc khi một PENDING ảnh hưởng APP được chốt.**

## Tổng quan

| Hạng mục | Trạng thái |
| --- | --- |
| Source code APP | Đã dựng lại UI theo mockup 5 vai trò (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`, ảnh `docs/design/figma/`): Phase 1 xong khung tab 5 vai trò + widget chung mới; Phase 2 xong Đăng nhập, Quên mật khẩu/OTP/Đặt mật khẩu, Thông báo, Tài khoản, Thông tin cá nhân dùng chung; Phase 3 xong 10 màn Phụ huynh (P02–P05, P08–P13); Phase 4 xong 13 màn Giáo viên (T01–T07.1, T09, T10, T15–T16); Phase 5 xong 7 màn Bếp (K01–K07); Phase 6 xong 9 màn Phó HT (V01–V07, V10, V12); Phase 7 xong 6 màn Hiệu trưởng (H01, H02, H04, H06–H08); màn theo vai trò vẫn từ plan `docs/plans/completed/2026-10-10-ui-redesign-mobile.md`, **dữ liệu giả**, chưa gọi API. Màn theo role chỉ có trong debug (xem `docs/architecture/NAVIGATION.md`). Từ 27/10 App chỉ cho Phụ huynh, Giáo viên, Bếp (`BE:` AUTH-21): màn Phó HT/Hiệu trưởng giữ làm tham khảo, không phát triển tiếp; một số màn lệch rule BE 28/10 (bảng dưới) |
| AI context + docs | Bản đầu (routing, workflow, feature map theo role) |
| Framework | Flutter CONFIRMED (user, 2026-10-08) — quy chuẩn `DESIGN.md` |
| Thư viện nền | Navigation: `go_router` CONFIRMED · state, HTTP, secure storage, push: chưa chọn (`docs/architecture/MOBILE_ARCHITECTURE.md`) |
| Auth | Chờ BE chốt (`BE:docs/contracts/AUTH_CONTRACT.md` SKELETON; `docs/integration/AUTH_FLOW.md` SKELETON) — không tự chọn cơ chế, hỏi |
| Push provider | Chờ chốt (`docs/integration/PUSH_NOTIFICATION.md` SKELETON) — không tự chọn, hỏi |
| BE | Đã có skeleton nền móng (response chuẩn, prefix API, OpenAPI); chưa có auth và nghiệp vụ — xem `BE:docs/context/CURRENT_STATE.md` |

## Feature theo role

| Role | Thiết kế (docs) | Code | Chặn bởi |
| --- | --- | --- | --- |
| Parent | Map màn hình (báo nghỉ: ATT-05 đã chốt, không duyệt; thực đơn tuần + ngày có ảnh suất — PAR-01, NUT-16; tài khoản theo SĐT — AUTH-18, sửa liên lạc của mình — CHD-05) | UI dữ liệu giả theo mockup: Trang chủ, Xin nghỉ + Đơn đã gửi, Thực đơn tuần, Bé của tôi (Hôm nay/Sức khỏe/Phát triển), Hoạt động, Điểm danh tháng, Hồ sơ bé. Lệch BE (28/10): ảnh bữa do GV đăng, đơn nghỉ có buổi — cần sửa khi tích hợp. Từ 29/10: danh sách mục phụ huynh xem đã chốt (PAR-01, PAR-03); hoạt động lấy từ kế hoạch ngày (OBS-07, EDU-09); thêm ai đã đón con (PCK-04), sức khỏe trong ngày (HLT-14) | P-20 (con có đơn nghỉ vẫn đến), P-32 (kênh ý kiến phụ huynh), auth |
| Teacher | Map màn hình | UI dữ liệu giả theo mockup: Trang chủ, Điểm danh & báo ăn, Đơn nghỉ lớp, Đánh giá hằng ngày, Đón trẻ, Đo sức khỏe, Lớp học, Lịch hoạt động, Ảnh bữa ăn. Lệch BE (28/10): báo ăn theo bé (ATT-02), chưa có nhiệt độ đầu ngày (HLT-07), GV chụp ảnh bữa (NUT-16) — cần sửa khi tích hợp. Lệch BE (29/10): đánh giá 3 tiêu chí (OBS-02: 7 mặt, 3 mức), đón trẻ theo người đón đã đăng ký (PCK-03: không đăng ký trước), đo sức khỏe chưa có GV chỉnh phân loại kèm lý do (HLT-10), chưa có màn sức khỏe trong ngày (HLT-14) | P-20, P-21/P-22/P-23 (sức khỏe đầu ngày), P-11 (tiêu chí đánh giá), P-33 (ảnh đối chiếu người đón), auth |
| Kitchen | Map màn hình (1 tài khoản chung mỗi cơ sở — AUTH-22) | UI dữ liệu giả theo mockup: Trang chủ, Thực đơn theo nhóm tuổi, Suất ăn theo lớp, Định lượng, Nhận nguyên liệu + Báo thiếu, Trạng thái nấu. Lệch BE (28/10): trạng thái nấu (NUT-14 REMOVED), nhận nguyên liệu (PHT ghi trên Web — NUT-11, NUT-12), báo thiếu (Zalo — NUT-22); chưa có ảnh mẫu bữa (NUT-16), sổ lưu mẫu (NUT-21) — cần sửa khi tích hợp. Từ 29/10: bếp giữ màn tối thiểu (AUTH-21, user chốt) | P-26 (mẫu sổ lưu mẫu), auth |
| Vice Principal | **Ngoài phạm vi App** (AUTH-21, user chốt 27/10; thay quyết định có trên app 2026-10-13) | UI dữ liệu giả theo mockup (giữ tham khảo): Trang chủ cơ sở, Yêu cầu chờ duyệt, Duyệt điều chỉnh suất, Chốt suất, Trạng thái bếp, Thực đơn tuần, Cân đối dinh dưỡng, Trẻ của cơ sở, Đề xuất khen thưởng | Không phát triển tiếp |
| Principal | **Ngoài phạm vi App** (AUTH-21, user chốt 27/10; thay quyết định có trên app 2026-10-13) | UI dữ liệu giả theo mockup (giữ tham khảo): Tổng quan toàn trường, Chờ Hiệu trưởng duyệt, Khen thưởng cuối năm, Danh sách trẻ toàn trường, Thực đơn tuần theo cơ sở, Cơ sở & Phó HT phụ trách | Không phát triển tiếp |
| Xác nhận số suất | Đã chốt (NUT-02, đóng P-05): PHT cơ sở xác nhận, HT thay khi vắng — trên Web, không có trên App | Màn giả ở nhánh Phó HT (V04), chỉ debug, giữ tham khảo | — |

## PENDING ảnh hưởng APP (nguồn: `BE:docs/business/BUSINESS_RULES.md` Pending register)

P-11 tiêu chí đánh giá ngày · P-20 trẻ có đơn nghỉ vẫn đến lớp · P-21 danh sách triệu chứng đầu ngày · P-22 trẻ bất thường có nhận không · P-23 mức ưu tiên sức khỏe đầu ngày · P-26 mẫu sổ lưu mẫu · P-28 số tài khoản phụ huynh mỗi trẻ · P-30 mẫu nhận xét định kỳ · P-31 làm cả phiếu bé ngoan và khen cuối năm · P-32 kênh ý kiến phụ huynh · P-33 ảnh đối chiếu người đón.

Màn hình phụ thuộc PENDING: UI theo dữ liệu BE trả, không hard-code; chưa đăng ký route cho tới khi chốt (`docs/architecture/NAVIGATION.md`).

Đã đóng: P-15 (2026-10-02) — đơn nghỉ là thông báo của phụ huynh qua app, không duyệt (ATT-05). P-14 (2026-10-27) — PHT theo cơ sở + mảng (AUTH-02, AUTH-20). 2026-10-28: P-03 giờ chốt chung HT cấu hình (ATT-06) · P-04 không nhận trẻ muộn, thay đổi qua mở lại điểm danh + xác nhận lại (ATT-03, ATT-08, NUT-04) · P-05 PHT xác nhận số suất (NUT-02) · P-06 bếp riêng mỗi cơ sở, 1 tài khoản chung (AUTH-05, AUTH-22) · P-07 một thực đơn chung hai cơ sở, 4 tuần xoay vòng (NUT-13) · P-08/P-09 kho, hàng tươi do PHT ghi trên Web (NUT-11, NUT-12) · P-10 định lượng (NUT-18) · P-17 phụ huynh khai dị ứng khi nhập học, 2 mức (HLT-06, NUT-23). 2026-10-29: P-01 hoạt động lấy từ kế hoạch ngày trong CareNest (OBS-07, EDU-01; ADR-0006 SUPERSEDED bởi ADR-0019) · P-02 nhà cung cấp AI (AI-09) · P-12 phụ huynh nhận mọi kỳ nhận xét (OBS-06) · P-13 chuẩn WHO (HLT-03) · P-13b danh sách mục phụ huynh xem, dữ liệu có công bố (PAR-01, PAR-03) · P-16b nhận xét theo kỳ (OBS-09).

## Kế tiếp
- UI mockup 5 vai trò xong (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`): đưa các khoảng trống contract / rule đã ghi ở `docs/features/*/README.md` sang BE (`BE:docs/knowledge/CROSS_MODULE_ISSUES.md`, cần user cho phép sửa BE), rồi nối API thay dữ liệu giả.
- Trước khi nối API: sửa các màn ghi "Lệch BE (28/10)", "Lệch BE (29/10)" ở `docs/features/{parent,teacher,kitchen}/README.md` (cần user duyệt phạm vi).
- Chốt state/DI, HTTP client, secure storage (`docs/architecture/MOBILE_ARCHITECTURE.md` mục Còn mở).
- Chờ BE chốt auth ⇒ điền `docs/integration/AUTH_FLOW.md`.
- Tồn đọng harness (user hoãn 2026-10-08): khi bắt đầu code BE/FE, chép `scripts/verify.mjs` + `scripts/__tests__/verify.test.mjs` (thêm nhánh Flutter, sửa quote `.bat` trên Windows) sang hai repo đó; sửa `siblings` trong `.claude/hooks/harness.config.json` theo vị trí thật (`../../be/CareNest_BE`, `../../fe/CareNest_FE`) để `node scripts/check-ai-layer.mjs --cross-repo` chạy được. Hiện bản ở BE/FE cũ hơn nhưng không ảnh hưởng chạy Maven/npm.
