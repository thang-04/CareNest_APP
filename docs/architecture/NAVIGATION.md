# Navigation — cây màn hình theo role

Mức chi tiết: role → nhóm màn hình. Thư viện navigation: `go_router` (CONFIRMED); route thật ở mục "Route hiện có". Rule nghiệp vụ của từng màn hình: `docs/features/<role>/README.md` (map sang BE). Rule code: `.claude/rules/navigation.md`.

Ký hiệu: **[P]** = PENDING, chưa đăng ký route cho tới khi chốt (hoặc bật bằng cờ) · **[?]** = chỉ làm nếu được yêu cầu.

## Gốc

```text
App
├─ Auth (chưa đăng nhập)      Login · Quên mật khẩu → OTP → Đặt mật khẩu mới (UI có, chờ AUTH_CONTRACT BE)
└─ Main (đã đăng nhập) → chọn nhánh theo role BE trả về
   ├─ Parent
   ├─ Teacher
   ├─ Kitchen
   ├─ Vice Principal (Phó Hiệu trưởng)   chỉ xem (AUTH-21, BE ADR-0026) — màn chỉ ở bản debug
   └─ Principal (Hiệu trưởng)            chỉ xem (AUTH-21, BE ADR-0026) — màn chỉ ở bản debug
```

App cho Parent, Teacher, Kitchen và Ban giám hiệu; **BGH trên App chỉ xem** (`BE:` AUTH-21, ADR-0026, user chốt 13/11 thay câu "BGH chỉ dùng Web" 27/10): không nút duyệt/xác nhận/trả lại/gửi; mọi thao tác làm trên Web. BE chặn lệnh ghi (403 `errorCode` 1301) và chỉ mở các GET của màn BGH. Tổ trưởng chuyên môn là phân công trên tài khoản GV, không phải nhánh role (AUTH-23).

Dùng chung mọi role: Thông báo (danh sách in-app, nếu BE có) · Tài khoản/Đăng xuất · Màn hình lỗi: không có quyền (403) / không tìm thấy (404) / mất mạng.

## Parent

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Chọn con / Tổng quan con | Danh sách con có GuardianLink; tóm tắt hôm nay | Chỉ con của mình (AUTH-04) |
| Lịch sử điểm danh | Có mặt/vắng theo ngày | |
| Bữa ăn | Thực đơn tuần + thực đơn ngày của con; thực đơn ngày có ảnh suất ăn hôm đó do bếp chụp | Chỉ field được phép (PAR-01, PAR-02, NUT-16) |
| Sức khỏe | Số đo + trend đã **công bố**; diễn giải chỉ khi đã APPROVED | Không hiển thị AI DRAFT |
| Phát triển & hoạt động | Đánh giá ngày sau khi GV lưu (OBS-13); nhận xét định kỳ mọi kỳ (OBS-06); phiếu bé ngoan, khen thưởng (OBS-10, OBS-14); tên hoạt động trong ngày từ kế hoạch ngày (EDU-09) | Dữ liệu có công bố chỉ hiện sau công bố (PAR-03) |
| Báo nghỉ | Gửi (ngày bắt đầu–kết thúc + lý do) / hủy / xem thông báo nghỉ của con (`leave:create`); không có bước duyệt | ATT-05; `SUBMITTED → CANCELLED`; con có đơn vẫn đến [P] P-20 |
| Đón con | Ai đã đón con, giờ đón; thông báo khi con được đón | PCK-04; không đăng ký trước người đón hộ (PCK-03) |
| Thông báo của trường | BGH gửi, push + trong App | PAR-05; không có trạng thái đã đọc |
| Tài khoản | Sửa thông tin liên lạc của mình; thông tin trẻ do trường sửa | CHD-05; tên đăng nhập = SĐT (AUTH-18) |

Không có: chat, xem trẻ khác, trẻ đã thôi học (mất quyền xem ngay — CHD-04), dữ liệu chưa công bố.

## Teacher

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Chọn lớp / ngày | Lớp được phân công (AUTH-03) | |
| Điểm danh + nhiệt độ đầu ngày | Nhập hàng loạt Có mặt / Vắng cả lớp/ngày (có mặt là ăn mọi bữa, không báo ăn riêng — ATT-02; vắng có phép tự động theo đơn nghỉ — ATT-09); nhiệt độ mọi trẻ cùng màn (HLT-07). Sau giờ chốt không nhận trẻ muộn (ATT-03); PHT mở lại có lý do (ATT-08) | Giờ chốt chung HT cấu hình (ATT-06) — BE trả, không hard-code · triệu chứng/không nhận/ưu tiên [P] P-21, P-22, P-23 |
| Đánh giá hằng ngày | Mọi trẻ có mặt, mặc định bình thường; 7 mặt, 3 mức + nhận xét (OBS-01, OBS-02); cắm cờ bé ngoan (OBS-10); khóa hết ngày (OBS-12) | Tiêu chí [P] P-11 |
| ~~Báo sự cố CSVC~~ | — | BE FAC REMOVED 29/10; không làm |
| Báo nghỉ của lớp | Xem thông báo nghỉ của lớp (chỉ xem) | ATT-05; GV không tạo thay phụ huynh |
| Đón trẻ (xác nhận trả trẻ) | Danh sách phụ huynh/người giám hộ; người lạ ⇒ gọi phụ huynh, ghi lý do; lưu người đón, giờ đón, về sớm | PCK-02, PCK-04, ATT-10; ảnh đối chiếu [P] P-33 |
| Nhận xét định kỳ | Sửa nháp, GV xác nhận (không có bước BGH duyệt) | OBS-05 · **[?]** nếu làm trên mobile |
| Cân đo, sức khỏe trong ngày | Cân đo lớp mình, công bố (HLT-09, HLT-11), chu kỳ BE cấu hình (HLT-01); ghi triệu chứng, xử trí trong ngày (HLT-14) | Phân loại WHO do BE trả, GV chỉnh kèm lý do (HLT-10) |

## Kitchen

Bếp giữ màn tối thiểu (AUTH-21, user chốt 29/10): số suất theo lớp, thực đơn, ảnh mẫu, sổ lưu mẫu. Định lượng và dị ứng là dữ liệu bếp được xem theo BE USER_ROLES; hỏi trước khi thêm màn.

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Suất ăn hôm nay | Số suất **đã xác nhận** theo lớp, từng bữa của cơ sở mình | NUT-02, NUT-17; mỗi cơ sở bếp riêng, 1 tài khoản chung (AUTH-05, AUTH-22) |
| Thực đơn | Thực đơn **đã công bố** (một thực đơn chung hai cơ sở, nhà trẻ khác mẫu giáo, 4 tuần xoay vòng) | NUT-08, NUT-13 |
| Định lượng thực phẩm | Kế hoạch định lượng, tách Fresh / Stored | Chỉ hiển thị BE tính |
| Dị ứng cần cho nấu | Số suất dị ứng/thay thế theo món và lớp, không tên trẻ | AUTH-05, NUT-23 |
| Thay đổi số suất | Không có adjustment riêng: PHT mở lại điểm danh rồi xác nhận lại; bếp thấy số đã xác nhận lại | ATT-08, NUT-03, NUT-04 |
| Ảnh mẫu bữa | Chụp ảnh mẫu mỗi bữa (phụ huynh xem trong thực đơn ngày) | NUT-16 · chưa có màn |
| Sổ lưu mẫu | Ghi lưu mẫu thức ăn mỗi bữa | NUT-21 · mẫu sổ [P] P-26 · chưa có màn |

Không có trên App bếp (BE 28/10): trạng thái nấu (NUT-14 REMOVED), bàn giao suất (NUT-15 REMOVED), nhận nguyên liệu / kho / phiếu (PHT ghi trên Web — NUT-11, NUT-12), báo thiếu (Zalo/điện thoại — NUT-22). Lệch BE (28/10): route K05–K07 vẫn còn ở bản debug — cần sửa khi tích hợp.

## Vice Principal (Phó Hiệu trưởng)

> Chỉ xem trên App (AUTH-21, BE ADR-0026, user chốt 13/11/2026): không có thao tác ghi; duyệt, xác nhận làm trên CareNest Web.

User chốt 2026-10-13: BGH có trên app, tách 2 vai trò (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`) — AUTH-21 27/10 bỏ BGH khỏi App, user chốt 13/11 cho BGH dùng App chỉ xem. Phạm vi theo campus được phân công + mảng (AUTH-02, AUTH-20; đóng P-14). Rule màn: `docs/features/vice-principal/README.md`.

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Trang chủ cơ sở | Số liệu hôm nay của cơ sở + việc chờ xử lý trên Web | AUTH-08 |
| Chờ xử lý (tab, trước là "Duyệt") | Số suất chưa xác nhận, đề xuất khen thưởng — chỉ xem | NUT-02 · OBS-10, OBS-14; không có điều chỉnh suất chờ duyệt (NUT-04) |
| Số suất hôm nay | Bảng suất + trạng thái đã/chưa xác nhận; xác nhận trên Web | NUT-02 (đóng P-05) |
| Thực đơn, dinh dưỡng, trẻ của cơ sở | Chỉ xem | NUT-08, NUT-06; không có trạng thái bếp (NUT-14 REMOVED) |

## Principal (Hiệu trưởng)

> Chỉ xem trên App (AUTH-21, BE ADR-0026, user chốt 13/11/2026): không có thao tác ghi; duyệt, xác nhận làm trên CareNest Web.

Phạm vi toàn trường (AUTH-01). Rule màn: `docs/features/principal/README.md`.

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Tổng quan toàn trường | Số liệu các cơ sở, đánh giá trẻ theo khối | AUTH-08 |
| Chờ xử lý (tab, trước là "Duyệt") | Khen thưởng cuối năm chờ HT — chỉ xem, duyệt trên Web | OBS-10, OBS-14 (chốt 29/10); không có nghỉ phép nhân sự (ngoài phạm vi) |
| Trẻ toàn trường, thực đơn, cơ sở | Chỉ xem | AUTH-01, NUT-08, AUTH-02 |

## Xác nhận số suất (đã chốt — Web)

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Xác nhận số suất | Xác nhận MealCount trước khi chuyển bếp (NUT-02) | Đóng P-05: PHT cơ sở xác nhận, HT thay khi vắng — trên Web (AUTH-21), không có nhánh App |

## Route hiện có (`lib/routing/`, 2026-10-13)

Nhãn tab theo mockup `docs/design/figma/` (user 2026-10-13). Chưa có auth ⇒ màn theo role chỉ đăng ký khi `enablePreview` (mặc định `kDebugMode`). Bản release chỉ có Đăng nhập — đúng quy tắc [P] ở trên (user chốt 2026-10-10, plan `docs/plans/completed/2026-10-10-ui-redesign-mobile.md` Q1/Q2).

| Route | Màn | Release | Ghi chú |
| --- | --- | --- | --- |
| `/login` (`/` chuyển về đây) | Đăng nhập | có | Chưa nối AUTH_CONTRACT; debug có link "Xem thử theo vai trò" |
| `/forgot-password`, `/forgot-password/otp`, `/forgot-password/new-password` | Quên mật khẩu → Xác thực OTP → Đặt mật khẩu mới | có | Chưa nối AUTH_CONTRACT: release báo "chưa kết nối", debug đi hết luồng bằng dữ liệu giả. Phụ huynh nhận OTP qua SMS (BE AUTH-19, user chốt 13/11; BE chưa có API) |
| `/preview` | Xem thử theo vai trò | không | Chỉ debug; không phải chọn role khi đăng nhập |
| `/parent`, `/parent/child`, `/parent/notifications`, `/parent/account` | Tab Phụ huynh: Trang chủ · Bé của tôi · Thông báo · Tài khoản | không | Tab chưa làm hiện "Sắp có" |
| `/teacher`, `/teacher/class`, `/teacher/notifications`, `/teacher/account` | Tab Giáo viên: Trang chủ (T01) · Lớp học (T09) · Thông báo · Tài khoản | không | |
| `/kitchen`, `/kitchen/menu`, `/kitchen/notifications`, `/kitchen/account` | Tab Bếp: Trang chủ (K01) · Thực đơn (K02) · Thông báo · Tài khoản | không | |
| `/kitchen/meals`, `/kitchen/quantities`, `/kitchen/receipts`, `/kitchen/receipts/shortage`, `/kitchen/cooking` | Suất ăn đã chốt (K03) · Định lượng (K04) · Nhận nguyên liệu (K05) · Báo thiếu (K06) · Trạng thái nấu (K07) | không | Lệch BE (28/10): K05 nhận hàng do PHT ghi trên Web (NUT-11, NUT-12), K06 báo thiếu qua Zalo (NUT-22), K07 NUT-14 REMOVED — cần sửa khi tích hợp |
| `/vice-principal`, `/vice-principal/approvals`, `/vice-principal/notifications`, `/vice-principal/account` | Tab Phó HT: Trang chủ (V01) · Chờ xử lý (V02, trước là "Duyệt") · Thông báo · Tài khoản | không | Chỉ xem (AUTH-21, BE ADR-0026) — áp cho mọi route `/vice-principal/*`, `/principal/*`: không có nút ghi (plan `docs/plans/active/2026-11-13-bgh-view-only.md`) |
| `/vice-principal/approvals/rewards` | Đề xuất khen thưởng (V12, chỉ xem) | không | OBS-10, OBS-14 (chốt 29/10). V03 điều chỉnh suất đã gỡ 13/11 (NUT-04) |
| `/vice-principal/meal-confirm`, `/vice-principal/menu`, `/vice-principal/menu/nutrition?group=<id>&day=<yyyy-mm-dd>`, `/vice-principal/children` | Số suất hôm nay (V04, chỉ xem) · Thực đơn tuần (V06) · Cân đối dinh dưỡng (V07) · Trẻ của cơ sở (V10) | không | V04 không có nút xác nhận (NUT-02: trên Web); V05 trạng thái bếp đã gỡ 13/11 (NUT-14 REMOVED); nhóm tuổi + ngày là ngữ cảnh ở query |
| `/principal`, `/principal/approvals`, `/principal/notifications`, `/principal/account` | Tab Hiệu trưởng: Tổng quan (H01) · Chờ xử lý (H02, trước là "Duyệt") · Thông báo · Tài khoản | không | Tài khoản có thêm "Cơ sở của trường" |
| `/principal/approvals/rewards/<id>`, `/principal/children`, `/principal/children/class?campus=<id>&class=<id>`, `/principal/menu`, `/principal/menu/nutrition?campus=<id>&group=<id>&day=<yyyy-mm-dd>`, `/principal/campuses` | Khen thưởng cuối năm (H04, chỉ xem) · Danh sách trẻ (H06) · Trẻ của lớp · Thực đơn tuần (H07) · Cân đối dinh dưỡng · Cơ sở & Phó HT (H08) | không | OBS-10, OBS-14 (chốt 29/10); cơ sở, lớp, nhóm tuổi, ngày là ngữ cảnh ở query |
| `/parent/leave-notices?child=<id>`, `/parent/leave-notices/new?child=<id>` | Đơn xin nghỉ đã gửi · Xin nghỉ cho bé (P04, P03) | không | Màn con, chỉ mang ID con |
| `/parent/menu`, `/parent/activities`, `/parent/attendance`, `/parent/child-profile` (đều `?child=<id>`) | Thực đơn tuần · Hoạt động & đánh giá · Điểm danh & bữa ăn · Hồ sơ của bé (P05, P09, P10, P13) | không | ID không thuộc danh sách con ⇒ 404 |
| `/parent/child?tab=health` | Tab Bé của tôi mở sẵn Sức khỏe | không | Con đang xem là state (`SelectedChild`), không nằm trong route |
| `/teacher/attendance` | Điểm danh + nhiệt độ đầu ngày lớp đang chọn (T02) | không | Màn con; lớp là state, dữ liệu giả có một lớp. Không báo ăn (ATT-02); bé có đơn nghỉ khóa "Có phép (theo đơn)" (ATT-04, ATT-09) — Figma sửa 13/11 |
| `/teacher/leave-notices`, `/teacher/schedule` | Đơn xin nghỉ của lớp (T03) · Lịch hoạt động (T10) | không | |
| `/teacher/reviews[/<childId>]`, `/teacher/pickup[/<childId>]`, `/teacher/health[/<childId>]` | Đánh giá hằng ngày (T04, T04.1) · Đón trẻ (T05, T06) · Đo sức khỏe (T07, T07.1) | không | Màn chi tiết mang ID trẻ trên đường dẫn Lệch BE (29/10): đánh giá 3 tiêu chí (OBS-02), đón trẻ theo người đã đăng ký (PCK-03) |

Mọi vai trò dùng chung tab Thông báo (`<tab>/:id` mở chi tiết) và Tài khoản (`<tab>/profile` Thông tin cá nhân, `<tab>/password` Đổi mật khẩu); màn con mở trên navigator gốc nên ẩn thanh đáy. Đăng xuất (chưa có phiên thật) về `/login`.

Đích thanh đáy khai báo một lần ở `lib/routing/navigation_destinations.dart`.

## Deep link (từ push)

Đích PROPOSED: tổng quan con (Parent) · chi tiết cập nhật mới (Parent) · suất ăn đã xác nhận / xác nhận lại (Kitchen) · trạng thái sự cố (Teacher). Payload chỉ có loại + ID; mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).

Thêm/đổi màn hình ⇒ cập nhật file này + feature doc của role.
