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
   ├─ Vice Principal (Phó Hiệu trưởng)
   └─ Principal (Hiệu trưởng)
```

Dùng chung mọi role: Thông báo (danh sách in-app, nếu BE có) · Tài khoản/Đăng xuất · Màn hình lỗi: không có quyền (403) / không tìm thấy (404) / mất mạng.

## Parent

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Chọn con / Tổng quan con | Danh sách con có GuardianLink; tóm tắt hôm nay | Chỉ con của mình (AUTH-04) |
| Lịch sử điểm danh | Có mặt/vắng theo ngày | |
| Bữa ăn | Thực đơn/bữa ăn của con | Chỉ field được phép (PAR-02) |
| Sức khỏe | Số đo + trend đã **công bố**; diễn giải chỉ khi đã APPROVED | Không hiển thị AI DRAFT |
| Cập nhật phát triển & hoạt động | Cập nhật phát triển **đã duyệt**; "Hoạt động hằng ngày" chỉ hiển thị khi OBS-07 được chốt (ADR-0006 OPEN) | Field cụ thể [P] P-13b · Hoạt động hằng ngày [P] OBS-07 |
| Báo nghỉ | Gửi / hủy / xem thông báo nghỉ của con (`leave:create`); không có bước duyệt | ATT-05; `SUBMITTED → CANCELLED` |

Không có: chat, xem trẻ khác, dữ liệu chưa công bố.

## Teacher

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Chọn lớp / ngày | Lớp được phân công (AUTH-03) | |
| Điểm danh + báo ăn | Nhập hàng loạt cả lớp/ngày; cập nhật trẻ đến muộn | Cut-off [P] P-03 — BE quyết định |
| Quan sát hằng ngày | Nhập hàng loạt theo tiêu chí có cấu trúc + ghi chú | Tiêu chí là data từ BE (P-11) |
| Báo sự cố CSVC | Tạo báo cáo hỏng/thiếu/không đủ + vị trí; xem trạng thái | |
| Báo nghỉ của lớp | Xem thông báo nghỉ của lớp (chỉ xem) | ATT-05; GV tạo thay phụ huynh PROPOSED — chưa làm || Duyệt summary | Xem/sửa/duyệt summary DRAFT của lớp | **[?]** nếu làm trên mobile |
| Nhập số đo sức khỏe | Chiều cao, cân nặng | **[P]** người nhập chưa chốt (USER_ROLES) |

## Kitchen

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Suất ăn hôm nay | Số suất **đã chốt** theo campus / bữa | Bếp theo campus hay trung tâm [P] P-06 |
| Thực đơn | MealPlan (thực đơn) **đã duyệt** | Thực đơn chung/riêng [P] P-07 |
| Định lượng thực phẩm | Kế hoạch định lượng, tách Fresh / Stored | Chỉ hiển thị BE tính |
| Dị ứng cần cho nấu | Danh sách dị ứng ở mức cần để nấu | Không xem hồ sơ trẻ (AUTH-05) |
| Điều chỉnh suất | Adjustment sau khi chốt | Cách xử lý/báo bếp [P] P-04 |

## Vice Principal (Phó Hiệu trưởng)

User chốt 2026-10-13: BGH có trên app, tách 2 vai trò (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`). Phạm vi theo campus được phân công (AUTH-02; cố định hay luân phiên [P] P-14). Rule màn: `docs/features/vice-principal/README.md`.

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Trang chủ cơ sở | Số liệu hôm nay của cơ sở + việc cần làm | AUTH-08 |
| Yêu cầu chờ duyệt | Điều chỉnh suất, đề xuất khen thưởng | NUT-03, NUT-04 [P] P-04 · OBS-10 PROPOSED |
| Chốt suất ăn | Xác nhận số suất gửi bếp | NUT-02 · **[P] P-05**: mockup giao Phó HT, chưa chốt |
| Bếp, thực đơn, dinh dưỡng, trẻ của cơ sở | Chỉ xem | NUT-08, NUT-06, NUT-14 PROPOSED |

## Principal (Hiệu trưởng)

Phạm vi toàn trường (AUTH-01). Rule màn: `docs/features/principal/README.md`.

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Tổng quan toàn trường | Số liệu các cơ sở, đánh giá trẻ theo khối | AUTH-08 |
| Chờ Hiệu trưởng duyệt | Khen thưởng cuối năm | OBS-10 PROPOSED; không có nghỉ phép nhân sự (ngoài phạm vi) |
| Trẻ toàn trường, thực đơn, cơ sở | Chỉ xem | AUTH-01, NUT-08, AUTH-02 |

## Chưa gán role

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Xác nhận số suất | Xác nhận MealCount trước khi chuyển bếp (NUT-02) | **[P] P-05**, permission `meal-count:confirm` — role chưa chốt, không gán nhánh |

## Route hiện có (`lib/routing/`, 2026-10-13)

Nhãn tab theo mockup `docs/design/figma/` (user 2026-10-13). Chưa có auth ⇒ màn theo role chỉ đăng ký khi `enablePreview` (mặc định `kDebugMode`). Bản release chỉ có Đăng nhập — đúng quy tắc [P] ở trên (user chốt 2026-10-10, plan `docs/plans/completed/2026-10-10-ui-redesign-mobile.md` Q1/Q2).

| Route | Màn | Release | Ghi chú |
| --- | --- | --- | --- |
| `/login` (`/` chuyển về đây) | Đăng nhập | có | Chưa nối AUTH_CONTRACT; debug có link "Xem thử theo vai trò" |
| `/forgot-password`, `/forgot-password/otp`, `/forgot-password/new-password` | Quên mật khẩu → Xác thực OTP → Đặt mật khẩu mới | có | Chưa nối AUTH_CONTRACT: release báo "chưa kết nối", debug đi hết luồng bằng dữ liệu giả |
| `/preview` | Xem thử theo vai trò | không | Chỉ debug; không phải chọn role khi đăng nhập |
| `/parent`, `/parent/child`, `/parent/notifications`, `/parent/account` | Tab Phụ huynh: Trang chủ · Bé của tôi · Thông báo · Tài khoản | không | Tab chưa làm hiện "Sắp có" |
| `/teacher`, `/teacher/class`, `/teacher/notifications`, `/teacher/account` | Tab Giáo viên: Trang chủ (T01) · Lớp học (T09) · Thông báo · Tài khoản | không | |
| `/kitchen`, `/kitchen/menu`, `/kitchen/notifications`, `/kitchen/account` | Tab Bếp: Trang chủ (K01) · Thực đơn (K02) · Thông báo · Tài khoản | không | |
| `/kitchen/meals`, `/kitchen/quantities`, `/kitchen/receipts`, `/kitchen/receipts/shortage`, `/kitchen/cooking` | Suất ăn đã chốt (K03) · Định lượng (K04) · Nhận nguyên liệu (K05) · Báo thiếu (K06) · Trạng thái nấu (K07) | không | Nhận nguyên liệu / báo thiếu là nghiệp vụ mới PROPOSED |
| `/vice-principal`, `/vice-principal/approvals`, `/vice-principal/notifications`, `/vice-principal/account` | Tab Phó HT: Trang chủ (V01) · Duyệt (V02) · Thông báo · Tài khoản | không | |
| `/vice-principal/approvals/meals/<id>`, `/vice-principal/approvals/rewards` | Duyệt điều chỉnh suất (V03) · Đề xuất khen thưởng (V12) | không | Chi tiết chỉ mang ID; OBS-10 PROPOSED |
| `/vice-principal/meal-confirm`, `/vice-principal/kitchen`, `/vice-principal/menu`, `/vice-principal/menu/nutrition?group=<id>&day=<yyyy-mm-dd>`, `/vice-principal/children` | Chốt suất (V04) · Trạng thái bếp (V05) · Thực đơn tuần (V06) · Cân đối dinh dưỡng (V07) · Trẻ của cơ sở (V10) | không | V04 phụ thuộc P-05; nhóm tuổi + ngày là ngữ cảnh ở query |
| `/principal`, `/principal/approvals`, `/principal/notifications`, `/principal/account` | Tab Hiệu trưởng: Tổng quan (H01) · Duyệt (H02) · Thông báo · Tài khoản | không | Tài khoản có thêm "Cơ sở của trường" |
| `/principal/approvals/rewards/<id>`, `/principal/children`, `/principal/children/class?campus=<id>&class=<id>`, `/principal/menu`, `/principal/menu/nutrition?campus=<id>&group=<id>&day=<yyyy-mm-dd>`, `/principal/campuses` | Khen thưởng cuối năm (H04) · Danh sách trẻ (H06) · Trẻ của lớp · Thực đơn tuần (H07) · Cân đối dinh dưỡng · Cơ sở & Phó HT (H08) | không | OBS-10 PROPOSED; cơ sở, lớp, nhóm tuổi, ngày là ngữ cảnh ở query |
| `/parent/leave-notices?child=<id>`, `/parent/leave-notices/new?child=<id>` | Đơn xin nghỉ đã gửi · Xin nghỉ cho bé (P04, P03) | không | Màn con, chỉ mang ID con |
| `/parent/menu`, `/parent/activities`, `/parent/attendance`, `/parent/child-profile` (đều `?child=<id>`) | Thực đơn tuần · Hoạt động & đánh giá · Điểm danh & bữa ăn · Hồ sơ của bé (P05, P09, P10, P13) | không | ID không thuộc danh sách con ⇒ 404 |
| `/parent/child?tab=health` | Tab Bé của tôi mở sẵn Sức khỏe | không | Con đang xem là state (`SelectedChild`), không nằm trong route |
| `/teacher/attendance` | Điểm danh + báo ăn lớp đang chọn (T02) | không | Màn con; lớp là state, dữ liệu giả có một lớp |
| `/teacher/leave-notices`, `/teacher/schedule` | Đơn xin nghỉ của lớp (T03) · Lịch hoạt động (T10) | không | |
| `/teacher/reviews[/<childId>]`, `/teacher/pickup[/<childId>]`, `/teacher/health[/<childId>]` | Đánh giá hằng ngày (T04, T04.1) · Đón trẻ (T05, T06) · Đo sức khỏe (T07, T07.1) | không | Màn chi tiết mang ID trẻ trên đường dẫn |
| `/teacher/meal-photos`, `/teacher/meal-photos/send?slot=<bữa>` | Chụp ảnh bữa ăn (T15) · Gửi phụ huynh (T16) | không | Gửi xong về Trang chủ |

Mọi vai trò dùng chung tab Thông báo (`<tab>/:id` mở chi tiết) và Tài khoản (`<tab>/profile` Thông tin cá nhân, `<tab>/password` Đổi mật khẩu); màn con mở trên navigator gốc nên ẩn thanh đáy. Đăng xuất (chưa có phiên thật) về `/login`.

Đích thanh đáy khai báo một lần ở `lib/routing/navigation_destinations.dart`.

## Deep link (từ push)

Đích PROPOSED: tổng quan con (Parent) · chi tiết cập nhật mới (Parent) · suất ăn/điều chỉnh (Kitchen) · trạng thái sự cố (Teacher). Payload chỉ có loại + ID; mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).

Thêm/đổi màn hình ⇒ cập nhật file này + feature doc của role.
