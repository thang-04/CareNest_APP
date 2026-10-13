# Principal (Hiệu trưởng) — màn hình Mobile

User chốt 2026-10-13: BGH có trên app, tách Phó Hiệu trưởng và Hiệu trưởng (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`). `BE:docs/business/USER_ROLES.md:20` còn ghi Principal chỉ dùng Web ⇒ cần BE cập nhật trước khi nối API.

Hiệu trưởng có scope toàn trường, mọi campus (`BE:` AUTH-01). Số tổng hợp chỉ trong scope (AUTH-08). Mockup: `docs/design/figma/principal-*.png`.

### Tổng quan toàn trường (H01)
- BE: rule AUTH-01, AUTH-08 · Endpoint: chưa có
- Tỉ lệ đánh giá theo khối là số BE trả. Không có ô "Nghỉ phép nhân sự" (ngoài phạm vi CareNest).
- Mockup H01 (dữ liệu giả, bản debug): 4 ô Trẻ có mặt · Suất ăn đã chốt · Thực đơn tuần · **Cơ sở** (thay ô nghỉ phép, dẫn tới H08), thanh đánh giá theo khối, mục "Chờ Hiệu trưởng duyệt". Thang và tiêu chí đánh giá theo P-11 (PENDING).

### Chờ Hiệu trưởng duyệt (H02) + Khen thưởng cuối năm (H04) — **PROPOSED**
- BE: rule OBS-10 (PROPOSED), tiêu chí PENDING P-11 · luồng Phó HT xét → Hiệu trưởng duyệt theo mockup, BE chưa ghi.
- Mockup H02: bỏ tab và mục "Nghỉ phép" (K5) ⇒ không còn bộ lọc; danh sách đợt chờ duyệt + "Đã xử lý gần đây".
- Mockup H04: chọn sẵn mọi đề xuất hợp lệ; bỏ chọn ⇒ đề xuất đó trả về Phó HT, **cần ghi chú**; "Trả về Phó HT" trả cả đợt, bắt buộc ghi chú. Duyệt từng phần là đề xuất của APP theo mockup (có ô chọn) — cần BE xác nhận khi viết OBS-10.
- Contract cần đề xuất: đợt đề xuất (batch) gửi Hiệu trưởng, trạng thái đợt, ghi chú khi trả về.

### Đơn nghỉ phép nhân sự (H05) — **không làm**
- Quản lý nhân sự không thuộc phạm vi CareNest (`BE:docs/context/PROJECT_CONTEXT.md:66`), không có module BE (plan K5).

### Danh sách trẻ toàn trường (H06)
- BE: card `BE:docs/modules/child.md` · rule AUTH-01 · Endpoint: chưa có
- Mockup H06: lọc theo cơ sở, danh sách lớp kèm sĩ số; gõ tìm ⇒ thêm trẻ khớp tên. Chạm lớp ⇒ màn trẻ của lớp (dùng lại màn V10, cơ sở + lớp ở query); chạm bé ⇒ "Sắp có".

### Thực đơn tuần (H07)
- BE: rule NUT-08 (chỉ đã duyệt), NUT-13 / P-07 (chung hay theo campus) · chỉ xem.
- Mockup H07: chọn cơ sở và ngày, mỗi nhóm tuổi một thẻ bữa trưa + năng lượng ngày; tóm tắt dinh dưỡng tuần là chuỗi BE trả (APP không tự tổng hợp). Chạm thẻ ⇒ cân đối dinh dưỡng (V07) của cơ sở đó.

### Cơ sở & Phó HT phụ trách (H08)
- BE: card `BE:docs/modules/school-structure.md` · rule AUTH-02 · chỉ xem; đổi phân công trên Web.
- Mockup H08: mở từ Tài khoản → "Cơ sở của trường" (chỉ Hiệu trưởng) hoặc ô Cơ sở ở H01. Bỏ mảng "CSVC" (cơ sở vật chất ngoài phạm vi CareNest).

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
