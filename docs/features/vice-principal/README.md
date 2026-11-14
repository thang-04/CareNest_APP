# Vice Principal (Phó Hiệu trưởng) — màn hình Mobile

> **Chỉ xem trên App (AUTH-21, `BE:docs/decisions/ADR-0026-staff-mobile-read-only.md`, user chốt 13/11/2026).** Không có nút ghi (duyệt, từ chối, xác nhận, trả lại, gửi); mọi thao tác làm trên CareNest Web. BE chặn lệnh ghi (403 `errorCode` 1301) và chỉ mở các GET của màn BGH; ngoại lệ: đăng ký/hủy thiết bị nhận push, đánh dấu thông báo đã đọc. Plan client: `docs/plans/active/2026-11-13-bgh-view-only.md`.

User chốt 2026-10-13: BGH có trên app, tách Phó Hiệu trưởng và Hiệu trưởng (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`) — AUTH-21 27/10 bỏ BGH khỏi App; user chốt 13/11 cho dùng App chỉ xem (`BE:docs/business/USER_ROLES.md`: "Web; App chỉ xem").

Phó HT chỉ thấy campus được phân công qua StaffAssignment, mỗi người một mảng; quyền theo mảng là mã quyền (`BE:` AUTH-02, AUTH-20; đóng P-14). Số tổng hợp chỉ trong scope (AUTH-08). Mockup: `docs/design/figma/vice-principal-*.png`.

### Trang chủ cơ sở (V01)
- BE: rule AUTH-02, AUTH-08 · Endpoint: chưa có
- Số có mặt / có phép / vắng / chờ duyệt là số BE trả, không tự đếm.
- Giao diện bố cục F (user 2026-10-14, `docs/design/mobile-redesign-clay.md`): "Sáng nay" + cơ sở · ngày → thẻ mốc buổi sáng (Khoá điểm danh → Tổng hợp suất ăn → Chốt suất ăn → Bếp nhận số → Bữa trưa; mốc đã xong có "Xong", chốt suất đang chờ có nhãn trạng thái và nút xem "Xem số suất" — từ 13/11 không còn "Xem & chốt") → "Chờ xử lý (n)" liệt kê việc chờ trên Web, chỉ xem → "Theo dõi khác" (Thực đơn tuần · Trẻ của cơ sở; bỏ Trạng thái bếp — NUT-14). Không có chuông: thông báo ở tab.
- Mốc buổi sáng cần BE trả danh sách `MorningStep` (giờ theo cấu hình cơ sở, tên, ghi chú, trạng thái done/current/upcoming) và danh sách mục chờ duyệt `CampusPendingItem` ⇒ **PROPOSED**, đề xuất khi viết endpoint trang chủ Phó HT. APP không suy trạng thái mốc từ giờ máy. Rỗng ⇒ ẩn thẻ mốc.
- Dòng mốc tự dựng trong màn, không dùng `AppTimeline`: widget chung chưa có trạng thái "đã xong", badge và nút trong mốc, và gộp hết semantics nên sẽ che nút.

### Chờ xử lý (V02, trước là "Yêu cầu chờ duyệt") — chỉ xem
- Từ 13/11: tab "Chờ xử lý" liệt kê số suất chưa xác nhận và đề xuất khen thưởng chờ PHT; chạm mở màn xem (V04, V12). Không lọc "Suất ăn" theo điều chỉnh vì không còn điều chỉnh chờ duyệt (NUT-04).

### ~~Duyệt điều chỉnh suất (V03)~~ — **bỏ 13/11/2026** (NUT-04; user review Figma). Phần dưới giữ làm lịch sử.

#### Lịch sử: Yêu cầu chờ duyệt (V02) + Duyệt điều chỉnh suất (V03)
- BE: rule NUT-03 (ACCEPTED), ATT-07 · NUT-04 (đóng P-04 28/10: không có điều chỉnh chờ duyệt; thay đổi qua mở lại điểm danh — ATT-08 — rồi xác nhận lại)
- Endpoint: chưa có. Số "sau khi duyệt" là BE tính; APP không cộng/trừ.
- Mockup V02–V03: tab Duyệt lọc Tất cả / Suất ăn / Khen thưởng. Chi tiết điều chỉnh có trẻ liên quan (Phó HT thấy tên trong cơ sở phụ trách), tình trạng bếp ("còn kịp chia thêm"), tổng hiện tại / sau khi duyệt / thường – thay thế. **Từ chối bắt buộc lý do** (trả về người gửi); duyệt xong BE gửi số mới tới bếp.
- Contract cần đề xuất: field tình trạng bếp trong yêu cầu điều chỉnh (đang nấu, còn kịp hay không) — chưa có ở BE.

### Số suất hôm nay (V04) — chỉ xem; **NUT-02 (đóng P-05): PHT xác nhận trên Web**
- Từ 13/11: bảng theo lớp (`MealCountTable`) + trạng thái "Đã xác nhận lúc …" hoặc "Chưa xác nhận — xác nhận trên CareNest Web"; không có nút "Xác nhận gửi bếp". BE: GET `/meal-counts`, `/meal-counts/class`.

#### Lịch sử mockup V04
- BE: rule NUT-01, NUT-02 · permission `meal-count:confirm` chưa gán role
- Mockup giao Phó HT; chưa chốt ⇒ chỉ dữ liệu giả ở bản debug.
- Mockup V04: bảng theo lớp dùng chung với bếp (`MealCountTable`), nút "Xác nhận gửi bếp (N suất)", xác nhận xong hiện "Đã gửi bếp lúc …" và ẩn nút. Bản giả: tổng hợp 08:15, giờ chốt 08:30 (khớp K03); mockup ghi 08:45 / 09:00 và có banner điều chỉnh 09:05 — bỏ banner vì điều chỉnh chỉ có sau khi chốt.

### ~~Trạng thái bếp (V05)~~ — **bỏ 13/11/2026** (NUT-14 REMOVED; user review Figma). Phần dưới giữ làm lịch sử.
- BE: rule NUT-14 (REMOVED 28/10) · Phiếu xuất kho và báo thiếu: nghiệp vụ mới PROPOSED (`docs/features/kitchen/README.md`)
- Mockup V05: màn K07 ở chế độ chỉ xem + thẻ bếp / phiếu xuất kho + banner báo thiếu gần nhất. Câu "Giáo viên không cần nhận suất" lệch NUT-15 (như K07).

### Thực đơn tuần (V06) + Cân đối dinh dưỡng (V07)
- BE: rule NUT-08 (chỉ thực đơn đã duyệt), NUT-06 (tính xác định ở BE)
- "Đạt / Thiếu" là nhãn BE trả; APP không so chuẩn.
- Mockup V06: màn K02 + banner "Đã duyệt & công bố" + nút "Xem cân đối dinh dưỡng" mang nhóm tuổi và ngày đang chọn (query `group`, `day`). V07: năng lượng cả ngày (thanh vẽ theo tỉ lệ BE trả), Protein / Lipid / Glucid / Canxi kèm chuẩn, năng lượng theo bữa, cảnh báo BE trả. Sửa định lượng làm trên Web.

### Trẻ của cơ sở (V10)
- BE: card `BE:docs/modules/child.md` · rule AUTH-02, HLT-06 · Endpoint: chưa có
- Mockup V10: tìm tên, chọn lớp, lọc Dị ứng / Ăn kiêng (số trong chip đếm theo danh sách đang xem), nhãn dị ứng có chữ. Chạm bé ⇒ "Sắp có" (hồ sơ cho Phó HT chưa có mockup). Bản giả 196 trẻ, Mầm 3A dùng chung danh sách lớp của Giáo viên.

### Đề xuất khen thưởng (V12) — chỉ xem
- Từ 13/11: tab Chờ xét / Đã gửi HT / Trả lại chỉ để xem; không có nút "Trả lại (n)", "Gửi HT (n)" (xét trên Web — OBS-14). BE: GET `/assessment/reward-lists`, `/assessment/reward-lists/classes/{classId}`.

#### Lịch sử mockup V12 (PROPOSED)
- BE: rule OBS-10, OBS-14 (chốt 29/10), tiêu chí P-11 · "Hợp lệ / Không hợp lệ" là kết quả BE trả.
- Mockup V12: tab Chờ xét / Đã gửi HT / Trả lại; nút "Trả lại (n)" trả mọi đề xuất không hợp lệ (lý do BE ghi), "Gửi HT (n)" gửi mọi đề xuất hợp lệ. Thẻ `RewardProposalCard` dùng lại cho Hiệu trưởng.

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
