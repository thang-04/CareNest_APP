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
   ├─ Vice Principal (Phó Hiệu trưởng)   ngoài phạm vi App (AUTH-21) — màn cũ chỉ debug, tham khảo
   └─ Principal (Hiệu trưởng)            ngoài phạm vi App (AUTH-21) — màn cũ chỉ debug, tham khảo
```

App chỉ cho Parent, Teacher, Kitchen (`BE:` AUTH-21, user chốt 27/10); BGH chỉ dùng Web. Tổ trưởng chuyên môn là phân công trên tài khoản GV, không phải nhánh role (AUTH-23).

Dùng chung mọi role: Thông báo (danh sách in-app, nếu BE có) · Tài khoản/Đăng xuất · Màn hình lỗi: không có quyền (403) / không tìm thấy (404) / mất mạng.

## Parent

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Chọn con / Tổng quan con | Danh sách con có GuardianLink; tóm tắt hôm nay | Chỉ con của mình (AUTH-04) |
| Lịch sử điểm danh | Có mặt/vắng theo ngày | |
| Bữa ăn | Thực đơn tuần + thực đơn ngày của con; thực đơn ngày có ảnh suất ăn hôm đó do bếp chụp | Chỉ field được phép (PAR-01, PAR-02, NUT-16) |
| Sổ sức khỏe | Màn riêng từ Trang chủ (user 17/11): Kỳ cân đo · Đợt khám (+ chi tiết đợt khám) · Xu hướng; số đo + trend đã **công bố**; diễn giải chỉ khi đã APPROVED | Không hiển thị AI DRAFT |
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

Bếp giữ màn tối thiểu (AUTH-21, user chốt 29/10): số suất theo lớp, thực đơn, ảnh mẫu, sổ lưu mẫu. Lượng thực phẩm và dị ứng là dữ liệu bếp được xem theo BE USER_ROLES; hỏi trước khi thêm màn. Các màn bếp làm lại theo BE `GET /nutrition/kitchen/day`, `/nutrition/food-samples` ngày 18/11 (dữ liệu giả, chưa nối).

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Trang chủ bếp | Số suất **đã xác nhận** từng bữa + giờ PHT xác nhận; Việc hôm nay (ảnh mẫu, lưu mẫu, hủy mẫu); Xem nhanh | NUT-02, NUT-16, NUT-21 · canvas "Trang chủ bếp (theo BE)" (user 18/11) |
| Suất ăn theo lớp | Số suất **đã xác nhận** theo lớp, chọn bữa Phụ sáng / Trưa / Chiều | NUT-02, NUT-17; mỗi cơ sở bếp riêng, 1 tài khoản chung (AUTH-05, AUTH-22) |
| Thực đơn | Thực đơn **đã công bố** (một thực đơn chung hai cơ sở, nhà trẻ khác mẫu giáo, 4 tuần xoay vòng) | NUT-08, NUT-13 |
| Lượng thực phẩm | Lượng cần cả ngày, chia Hàng tươi / Hàng khô | Chỉ hiển thị BE tính (NUT-07, NUT-10); không phiếu xuất kho |
| Dị ứng cần cho nấu | Số suất dị ứng/thay thế theo món và lớp, không tên trẻ | AUTH-05, NUT-23 |
| Thay đổi số suất | Không có adjustment riêng: PHT mở lại điểm danh rồi xác nhận lại; bếp thấy số đã xác nhận lại | ATT-08, NUT-03, NUT-04 |
| Ảnh mẫu bữa | Chụp ảnh mẫu theo nhóm tuổi: mỗi bữa nhóm đó ăn cần ít nhất 1 ảnh, chụp bao nhiêu cũng được (phụ huynh xem trong thực đơn ngày) | NUT-16, NUT-17 · bữa theo cấu hình nhóm tuổi của HT; hết giờ chưa có ảnh chỉ báo đỏ · màn dữ liệu giả `/kitchen/photos` (user 17/11, bố cục B 18/11) |
| Sổ lưu mẫu | Ghi lưu mẫu mỗi bữa (khối lượng, dụng cụ chứa, nhiệt độ từng món), sửa khi chưa duyệt, ghi hủy mẫu khi đủ 24 giờ; PHT duyệt trên Web | NUT-21 · mẫu sổ [P] P-26 · màn dữ liệu giả `/kitchen/samples` (user 18/11) |

Không có trên App bếp (BE 28/10): trạng thái nấu (NUT-14 REMOVED), bàn giao suất (NUT-15 REMOVED), nhận nguyên liệu / kho / phiếu (PHT ghi trên Web — NUT-11, NUT-12), báo thiếu (Zalo/điện thoại — NUT-22). Route K05–K07 đã bỏ 18/11.

## Vice Principal (Phó Hiệu trưởng)

> Ngoài phạm vi App theo AUTH-21 (user chốt 27/10): BGH chỉ dùng Web. Màn hình hiện có giữ làm tham khảo, không phát triển tiếp.

User chốt 2026-10-13: BGH có trên app, tách 2 vai trò (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`) — đã thay bởi AUTH-21. Phạm vi theo campus được phân công + mảng (AUTH-02, AUTH-20; đóng P-14). Rule màn: `docs/features/vice-principal/README.md`.

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Trang chủ cơ sở | Số liệu hôm nay của cơ sở + việc cần làm | AUTH-08 |
| Yêu cầu chờ duyệt | Điều chỉnh suất, đề xuất khen thưởng | NUT-03, NUT-04 (đóng P-04: không có điều chỉnh chờ duyệt) · OBS-10, OBS-14 (chốt 29/10) |
| Chốt suất ăn | Xác nhận số suất gửi bếp | NUT-02 (đóng P-05: PHT xác nhận, trên Web) |
| Bếp, thực đơn, dinh dưỡng, trẻ của cơ sở | Chỉ xem | NUT-08, NUT-06, NUT-14 REMOVED |

## Principal (Hiệu trưởng)

> Ngoài phạm vi App theo AUTH-21 (user chốt 27/10): BGH chỉ dùng Web. Màn hình hiện có giữ làm tham khảo, không phát triển tiếp.

Phạm vi toàn trường (AUTH-01). Rule màn: `docs/features/principal/README.md`.

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Tổng quan toàn trường | Số liệu các cơ sở, đánh giá trẻ theo khối | AUTH-08 |
| Chờ Hiệu trưởng duyệt | Khen thưởng cuối năm | OBS-10, OBS-14 (chốt 29/10); không có nghỉ phép nhân sự (ngoài phạm vi) |
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
| `/forgot-password`, `/forgot-password/otp`, `/forgot-password/new-password` | Quên mật khẩu → Xác thực OTP → Đặt mật khẩu mới | có | Chưa nối AUTH_CONTRACT: release báo "chưa kết nối", debug đi hết luồng bằng dữ liệu giả |
| `/preview` | Xem thử theo vai trò | không | Chỉ debug; không phải chọn role khi đăng nhập |
| `/parent`, `/parent/child`, `/parent/notifications`, `/parent/account` | Tab Phụ huynh: Trang chủ · Bé của tôi · Thông báo · Tài khoản | không | Tab chưa làm hiện "Sắp có" |
| `/teacher`, `/teacher/class`, `/teacher/notifications`, `/teacher/account` | Tab Giáo viên: Trang chủ (T01) · Lớp học (T09) · Thông báo · Tài khoản | không | |
| `/kitchen`, `/kitchen/menu`, `/kitchen/notifications`, `/kitchen/account` | Tab Bếp: Trang chủ (K01) · Thực đơn (K02) · Thông báo · Tài khoản | không | |
| `/kitchen/meals`, `/kitchen/quantities` | Suất ăn theo lớp (K03, chọn bữa) · Lượng thực phẩm (K04, hàng tươi / hàng khô) | không | Dữ liệu giả theo BE `GET /nutrition/kitchen/day` (18/11). K05–K07 (`/kitchen/receipts`, `/kitchen/receipts/shortage`, `/kitchen/cooking`) đã bỏ 18/11 |
| `/kitchen/samples` | Sổ lưu mẫu: ghi, sửa lưu mẫu từng bữa; ghi hủy mẫu (mở từ việc "Sổ lưu mẫu" / "Hủy mẫu" trên Trang chủ bếp) | không | Dữ liệu giả theo BE `/nutrition/food-samples` (user 18/11) |
| `/kitchen/photos` | Ảnh mẫu bữa ăn theo nhóm tuổi: chọn nhóm tuổi rồi chụp từng bữa (mở từ việc trên Trang chủ bếp) | không | Dữ liệu giả (user 17/11, bố cục B 18/11). Lệch BE: MealPhoto 1 ảnh mỗi bữa theo cơ sở, chưa theo nhóm tuổi — cần BE trước khi tích hợp |
| `/vice-principal`, `/vice-principal/approvals`, `/vice-principal/notifications`, `/vice-principal/account` | Tab Phó HT: Trang chủ (V01) · Duyệt (V02) · Thông báo · Tài khoản | không | Ngoài phạm vi App (AUTH-21), tham khảo — áp cho mọi route `/vice-principal/*`, `/principal/*` |
| `/vice-principal/approvals/meals/<id>`, `/vice-principal/approvals/rewards` | Duyệt điều chỉnh suất (V03) · Đề xuất khen thưởng (V12) | không | Chi tiết chỉ mang ID; OBS-10, OBS-14 (chốt 29/10) |
| `/vice-principal/meal-confirm`, `/vice-principal/kitchen`, `/vice-principal/menu`, `/vice-principal/menu/nutrition?group=<id>&day=<yyyy-mm-dd>`, `/vice-principal/children` | Chốt suất (V04) · Trạng thái bếp (V05) · Thực đơn tuần (V06) · Cân đối dinh dưỡng (V07) · Trẻ của cơ sở (V10) | không | V04 phụ thuộc P-05; nhóm tuổi + ngày là ngữ cảnh ở query |
| `/principal`, `/principal/approvals`, `/principal/notifications`, `/principal/account` | Tab Hiệu trưởng: Tổng quan (H01) · Duyệt (H02) · Thông báo · Tài khoản | không | Tài khoản có thêm "Cơ sở của trường" |
| `/principal/approvals/rewards/<id>`, `/principal/children`, `/principal/children/class?campus=<id>&class=<id>`, `/principal/menu`, `/principal/menu/nutrition?campus=<id>&group=<id>&day=<yyyy-mm-dd>`, `/principal/campuses` | Khen thưởng cuối năm (H04) · Danh sách trẻ (H06) · Trẻ của lớp · Thực đơn tuần (H07) · Cân đối dinh dưỡng · Cơ sở & Phó HT (H08) | không | OBS-10, OBS-14 (chốt 29/10); cơ sở, lớp, nhóm tuổi, ngày là ngữ cảnh ở query |
| `/parent/leave-notices?child=<id>`, `/parent/leave-notices/new?child=<id>` | Đơn xin nghỉ đã gửi · Xin nghỉ cho bé (P04, P03) | không | Màn con, chỉ mang ID con |
| `/parent/menu`, `/parent/activities`, `/parent/attendance` (đều `?child=<id>`) | Thực đơn tuần · Hoạt động & đánh giá · Điểm danh & bữa ăn (P05, P09, P10) | không | ID không thuộc danh sách con ⇒ 404. Hồ sơ của bé (P13, `/parent/child-profile`) gộp vào tab Bé của tôi 18/11, route đã bỏ |
| `/parent/health?child=<id>`, `/parent/health/exams/<examId>?child=<id>` | Sổ sức khỏe: Kỳ cân đo · Đợt khám · Xu hướng (ô "Sổ sức khỏe" ở Trang chủ) · Chi tiết đợt khám | không | User 17/11, thay tab Sức khỏe cũ của Bé của tôi. Màn con ẩn thanh đáy, chỉ mang ID; con lạ ⇒ 404, đợt khám lạ ⇒ "Không tìm thấy đợt khám" |
| `/parent/evaluation?child=<id>`, `/parent/evaluation/themes/<themeId>?child=<id>` | Trang Đánh giá: Ngày · Tuần · Chủ đề · Học kỳ · Cuối năm (ô "Đánh giá" ở Trang chủ) · Kết quả một chủ đề | không | User 18/11. Màn con ẩn thanh đáy, chỉ mang ID; con lạ ⇒ 404, chủ đề lạ hoặc đang học ⇒ "Không tìm thấy kết quả chủ đề" |
| `/parent/rewards?child=<id>` | Trang Khen thưởng: Tuần · Tháng · Cuối năm, sheet "Cách bé nhận khen thưởng" (ô "Khen thưởng" ở Trang chủ) | không | User 18/11. Màn con ẩn thanh đáy, chỉ mang ID; con lạ ⇒ 404; "Xem đánh giá từng ngày" mở `/parent/evaluation` |
| `/parent/child?tab=…&section=…` (link cũ) | Tab Bé của tôi (hồ sơ của bé, một trang) | không | User 18/11: bỏ qua `tab`, `section`; `RoutePaths.parentChildAt` đã xoá. Tab theo bé đang chọn ở Trang chủ; link "Xem hồ sơ của <bé> ›" trên thẻ bé ở Trang chủ chuyển sang tab này (`context.go`) |
| `/teacher/attendance` | Điểm danh + báo ăn lớp đang chọn (T02) | không | Màn con; lớp là state, dữ liệu giả có một lớp. Lệch BE (28/10): còn báo ăn theo bé (ATT-02), chưa có nhiệt độ (HLT-07) — cần sửa khi tích hợp |
| `/teacher/leave-notices`, `/teacher/schedule` | Đơn xin nghỉ của lớp (T03) · Lịch hoạt động (T10) | không | |
| `/teacher/reviews[/<childId>]`, `/teacher/pickup[/<childId>]`, `/teacher/health[/<childId>]` | Đánh giá hằng ngày (T04, T04.1) · Đón trẻ (T05, T06) · Đo sức khỏe (T07, T07.1) | không | Màn chi tiết mang ID trẻ trên đường dẫn Lệch BE (29/10): đánh giá 3 tiêu chí (OBS-02), đón trẻ theo người đã đăng ký (PCK-03) |
| `/teacher/meal-photos`, `/teacher/meal-photos/send?slot=<bữa>` | Chụp ảnh bữa ăn (T15) · Gửi phụ huynh (T16) | không | Gửi xong về Trang chủ. Lệch BE (28/10): NUT-16 chỉ bếp chụp ảnh mẫu — cần sửa khi tích hợp |

Mọi vai trò dùng chung tab Thông báo (`<tab>/:id` mở chi tiết) và Tài khoản (`<tab>/profile` Thông tin cá nhân, `<tab>/password` Đổi mật khẩu); màn con mở trên navigator gốc nên ẩn thanh đáy. Đăng xuất (chưa có phiên thật) về `/login`.

Đích thanh đáy khai báo một lần ở `lib/routing/navigation_destinations.dart`.

### Phiên đăng nhập thật (`/live/...`, cập nhật 18/11/2026)

Sau đăng nhập Keycloak, App dùng cùng khung thanh đáy với bản xem thử, đường dẫn thêm tiền tố `/live` (vd. `/live/teacher/notifications`). Vai trò lấy từ `roles` của `/accounts/me`: `PARENT`, `TEACHER`, `KITCHEN_STAFF` ⇒ khung 4 tab tương ứng; vai trò khác (BGH, Admin — AUTH-21) ⇒ `/live/unsupported` báo dùng Web, có Đăng xuất.

| Route | Màn | Ghi chú |
| --- | --- | --- |
| `/live/notifications`, `/live/notifications/:id` | Lối vào cố định cho đăng nhập và push | Chuyển sang tab Thông báo (hoặc chi tiết) của đúng vai trò |
| `/live/<vai trò>/notifications[/:id]` | Thông báo / chi tiết (dữ liệu `/me/notifications`, `/me/announcements`) | Chi tiết mở trên navigator gốc (ẩn thanh đáy), Back về danh sách |
| `/live/<vai trò>/account` | Tài khoản từ `/accounts/me`, Đăng xuất thật | Thông tin cá nhân, Đổi mật khẩu: "Sắp có" |
| Tab Trang chủ, Bé của tôi / Lớp học / Thực đơn | "Sắp có" | Chưa nối API ⇒ không hiện dữ liệu giả trong phiên thật |

Tài khoản vừa là phụ huynh vừa là giáo viên: lấy vai trò hỗ trợ đầu tiên trong `roles` BE trả — **OPEN**, cần chốt cách chọn vai trò.

## Deep link (từ push)

Đích PROPOSED: tổng quan con (Parent) · chi tiết cập nhật mới (Parent) · suất ăn đã xác nhận / xác nhận lại (Kitchen) · trạng thái sự cố (Teacher). Payload chỉ có loại + ID; mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).

Thêm/đổi màn hình ⇒ cập nhật file này + feature doc của role.
