# Vice Principal (Phó Hiệu trưởng) — màn hình Mobile

User chốt 2026-10-13: BGH có trên app, tách Phó Hiệu trưởng và Hiệu trưởng (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`). `BE:docs/business/USER_ROLES.md:21` còn ghi Vice Principal chỉ dùng Web ⇒ cần BE cập nhật trước khi nối API.

Phó HT chỉ thấy campus được phân công qua StaffAssignment (`BE:` AUTH-02; cố định hay luân phiên PENDING P-14). Số tổng hợp chỉ trong scope (AUTH-08). Mockup: `docs/design/figma/vice-principal-*.png`.

### Trang chủ cơ sở (V01)
- BE: rule AUTH-02, AUTH-08 · Endpoint: chưa có
- Số có mặt / có phép / vắng / chờ duyệt là số BE trả, không tự đếm.
- Mockup V01 (dữ liệu giả, bản debug): thẻ cơ sở (số lớp, có mặt / sĩ số), 4 ô số, 5 việc: Chốt suất · Yêu cầu chờ duyệt · Trạng thái bếp · Thực đơn tuần · Trẻ của cơ sở. Việc "Yêu cầu chờ duyệt" chuyển sang tab Duyệt.

### Yêu cầu chờ duyệt (V02) + Duyệt điều chỉnh suất (V03)
- BE: rule NUT-03 (ACCEPTED), ATT-07 · **P-04** cách xử lý thay đổi muộn (NUT-04)
- Endpoint: chưa có. Số "sau khi duyệt" là BE tính; APP không cộng/trừ.
- Mockup V02–V03: tab Duyệt lọc Tất cả / Suất ăn / Khen thưởng. Chi tiết điều chỉnh có trẻ liên quan (Phó HT thấy tên trong cơ sở phụ trách), tình trạng bếp ("còn kịp chia thêm"), tổng hiện tại / sau khi duyệt / thường – thay thế. **Từ chối bắt buộc lý do** (trả về người gửi); duyệt xong BE gửi số mới tới bếp.
- Contract cần đề xuất: field tình trạng bếp trong yêu cầu điều chỉnh (đang nấu, còn kịp hay không) — chưa có ở BE.

### Chốt suất ăn trong ngày (V04) — **PENDING P-05**
- BE: rule NUT-01, NUT-02 · permission `meal-count:confirm` chưa gán role
- Mockup giao Phó HT; chưa chốt ⇒ chỉ dữ liệu giả ở bản debug.
- Mockup V04: bảng theo lớp dùng chung với bếp (`MealCountTable`), nút "Xác nhận gửi bếp (N suất)", xác nhận xong hiện "Đã gửi bếp lúc …" và ẩn nút. Bản giả: tổng hợp 08:15, giờ chốt 08:30 (khớp K03); mockup ghi 08:45 / 09:00 và có banner điều chỉnh 09:05 — bỏ banner vì điều chỉnh chỉ có sau khi chốt.

### Trạng thái bếp (V05) — **PROPOSED**
- BE: rule NUT-14 (PROPOSED) · Phiếu xuất kho và báo thiếu: nghiệp vụ mới PROPOSED (`docs/features/kitchen/README.md`)
- Mockup V05: màn K07 ở chế độ chỉ xem + thẻ bếp / phiếu xuất kho + banner báo thiếu gần nhất. Câu "Giáo viên không cần nhận suất" lệch NUT-15 (như K07).

### Thực đơn tuần (V06) + Cân đối dinh dưỡng (V07)
- BE: rule NUT-08 (chỉ thực đơn đã duyệt), NUT-06 (tính xác định ở BE)
- "Đạt / Thiếu" là nhãn BE trả; APP không so chuẩn.
- Mockup V06: màn K02 + banner "Đã duyệt & công bố" + nút "Xem cân đối dinh dưỡng" mang nhóm tuổi và ngày đang chọn (query `group`, `day`). V07: năng lượng cả ngày (thanh vẽ theo tỉ lệ BE trả), Protein / Lipid / Glucid / Canxi kèm chuẩn, năng lượng theo bữa, cảnh báo BE trả. Sửa định lượng làm trên Web.

### Trẻ của cơ sở (V10)
- BE: card `BE:docs/modules/child.md` · rule AUTH-02, HLT-06 · Endpoint: chưa có
- Mockup V10: tìm tên, chọn lớp, lọc Dị ứng / Ăn kiêng (số trong chip đếm theo danh sách đang xem), nhãn dị ứng có chữ. Chạm bé ⇒ "Sắp có" (hồ sơ cho Phó HT chưa có mockup). Bản giả 196 trẻ, Mầm 3A dùng chung danh sách lớp của Giáo viên.

### Đề xuất khen thưởng (V12) — **PROPOSED**
- BE: rule OBS-10 (PROPOSED), tiêu chí PENDING P-11 · "Hợp lệ / Không hợp lệ" là kết quả BE trả.
- Mockup V12: tab Chờ xét / Đã gửi HT / Trả lại; nút "Trả lại (n)" trả mọi đề xuất không hợp lệ (lý do BE ghi), "Gửi HT (n)" gửi mọi đề xuất hợp lệ. Thẻ `RewardProposalCard` dùng lại cho Hiệu trưởng.

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
