# Teacher — màn hình Mobile

Giáo viên chỉ truy cập **lớp được phân công** (`BE:` AUTH-03, scope do BE kiểm tra). Teacher dùng cả Web và App; màn hình mobile ưu tiên nhập nhanh tại lớp.

### Chọn lớp / ngày
- BE: card `BE:docs/modules/school-structure.md`, `BE:docs/modules/identity-access.md` · rule AUTH-03
- Endpoint: chưa có

### Trang chủ giáo viên (bố cục D)
- Giao diện (user 2026-10-14, `docs/design/mobile-redesign-clay.md`): lời chào → thẻ lớp nổi bật (tên lớp, sĩ số, hoạt động đang diễn ra, vòng "x/N đã điểm danh", hạn điểm danh, nút "Điểm danh ngay") → "Việc tiếp theo" trượt ngang. Hết việc điểm danh ⇒ không còn nút và hạn.
- Vòng tiến độ cần **số bé đã điểm danh** do BE trả (`attendanceRecorded` ở `TeacherToday`, chưa có trong contract) ⇒ đề xuất khi viết endpoint trang chủ GV; APP không tự đếm. Không có số ⇒ không vẽ vòng.

### Điểm danh + báo ăn (nhập hàng loạt)
- Mục đích: nhập có mặt + tham gia ăn cho cả lớp/ngày cùng lúc; cập nhật trẻ đến muộn.
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/attendance.md` · rule ATT-01, ATT-02, ATT-03, ATT-07
- Endpoint: chưa có. Hướng BE: idempotent upsert theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH, `BE:docs/knowledge/PATTERNS.md`); HTTP method TBD ⇒ retry an toàn (`docs/integration/BACKEND_INTEGRATION.md`).
- PENDING: P-03 cut-off (BE từ chối khi quá giờ — APP hiển thị lỗi, không tự khóa theo giờ máy) · P-04 sửa sau khi bếp đã chốt suất (BE xử lý adjustment; APP không cảnh báo theo logic riêng).
- Không: tự tính số suất từ số trẻ có mặt (NUT-01 — BE làm).
- Mockup T02 (user 2026-10-13): mỗi bé hai nút Có mặt / Vắng; bé có đơn nghỉ bấm "Vắng" vẫn là có phép (ATT-04); báo ăn mặc định "có ăn", bấm tên bé để đổi. Mockup có "Ăn 1 bữa · Trưa" ⇒ báo ăn theo từng bữa chưa có trong BE (MealParticipation hiện là có/không) — đề xuất BE; APP hiện là ghi chú BE trả.

### Quan sát hằng ngày (nhập hàng loạt)
- BE: card `BE:docs/modules/learning-observation.md` · flow `BE:docs/business/flows/child-observation.md` · rule OBS-01, OBS-02
- Endpoint: chưa có
- PENDING: P-11 — tiêu chí + thang giá trị là **data từ BE**, không enum cứng trong APP.
- Mockup T04 / T04.1: danh sách bé (đã / chưa đánh giá, bé vắng không cần), màn một bé với 3 tiêu chí + ghi chú cho phụ huynh + "Gắn cờ: Hành vi tốt" (phiếu bé ngoan OBS-10 PROPOSED). Bỏ thẻ "Giáo án đã duyệt" (OBS-08); dòng hoạt động trong ngày chỉ là ngữ cảnh (OBS-07 OPEN).

### Báo sự cố CSVC
- BE: card `BE:docs/modules/facility-issue.md` · flow `BE:docs/business/flows/facility-issue.md` · rule FAC-01, FAC-04 (PROPOSED trạng thái)
- Endpoint: chưa có
- Ngoài scope: tài sản, khấu hao, bảo trì (FAC-03). Ảnh đính kèm (nếu có) theo giới hạn upload BE.

### Báo nghỉ của lớp (chỉ xem)
- BE: flow `BE:docs/business/flows/leave-request.md` · rule ATT-05, ATT-04
- GV xem thông báo nghỉ của trẻ trong lớp được phân công; **không có bước duyệt**. GV tạo thay phụ huynh: PROPOSED (ATT-05) — chưa làm.
- Mockup T03: lọc "Hôm nay & sắp tới" / "Tất cả", badge Mới / Đã xem, nút "Đánh dấu đã xem" (ghi nhận, không duyệt). Danh sách gồm cả trẻ **vắng không đơn** kèm ghi chú GV đã gọi phụ huynh ⇒ BE chưa có bản ghi này, đề xuất BE.

### Nhận suất ăn từ bếp — **PROPOSED**
- BE: rule NUT-15 · flow `BE:docs/business/flows/meal-management.md` (bàn giao suất). GV xác nhận số suất nhận; thiếu/sai ⇒ bếp bàn giao lại.

### Duyệt summary — chỉ nếu được yêu cầu trên mobile
- BE: card `BE:docs/modules/learning-observation.md` · rule OBS-04, OBS-05, AI-01..03
- AI draft hiển thị rõ là bản nháp; luồng phải chạy khi AI tắt. PENDING: P-12.

### Nhập số đo sức khỏe — **PENDING**
- BE: card `BE:docs/modules/health.md` · flow `BE:docs/business/flows/health-check.md` · rule HLT-01 · người nhập chưa chốt (`BE:docs/business/USER_ROLES.md`).
- Mockup T07 / T07.1 dựng dữ liệu giả ở bản debug (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md` K1): danh sách đã / chưa đo, nhập chiều cao + cân nặng, "Kết quả tính theo quy tắc của trường" là **BE trả** (HLT-03 / P-13 PENDING — APP không so chuẩn), công tắc "Công bố cho phụ huynh" (PAR-02), câu "Không phải chẩn đoán y tế" (HLT-04).

### Chụp và gửi ảnh bữa ăn — **PROPOSED**
- Ảnh bữa ăn — **PROPOSED** (user 2026-10-13): (1) bếp chụp ảnh món khi nấu xong; (2) giáo viên chụp khay khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món ăn trong thực đơn/lịch của con. BE NUT-16 hiện chỉ ghi bếp chụp ⇒ đề xuất cập nhật BE.
- Mockup: `docs/design/figma/teacher-15-16-meal-photo-capture-send.png` (chọn bữa, chụp suất thường / suất thay thế, gửi phụ huynh cả lớp hoặc riêng phụ huynh có suất thay thế).
- BE: rule NUT-16 (PROPOSED) · Endpoint: chưa có · upload theo `DESIGN.md` §16.1 (PROPOSED).
- Chưa chọn thư viện camera (hỏi trước khi thêm): khung ngắm là khối tĩnh, nút chụp chỉ thêm ảnh giữ chỗ.

### Đón trẻ + xác minh người đón — **chưa có rule BE**
- Mockup T05 / T06 (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md` K4): danh sách chờ đón / đã đón, xác minh người đón đã đăng ký (ảnh, tên, SĐT), "Đúng – giao bé" ⇒ BE ghi giờ, người đón và báo phụ huynh; "Không khớp – gọi phụ huynh".
- BE: chưa có rule/module ⇒ đề xuất BE. Ảnh người đón chỉ tải qua URL có auth; bản giả dùng icon. Gọi điện cần plugin quay số (chưa thêm).

### Lớp học (danh sách bé)
- Mockup T09: tên, tuổi, liên hệ phụ huynh, nhãn dị ứng / chế độ ăn / nghỉ (HLT-06, AUTH-03). Mở chi tiết bé: chưa có trong mockup ⇒ "Sắp có".

### Lịch hoạt động
- Mockup T10, bỏ "Giáo án tuần đã duyệt", "Tổ trưởng & Phó HT ký duyệt", "Xem file" (OBS-08). Nguồn lịch còn OPEN (OBS-07, ADR-0006) ⇒ dữ liệu giả ở bản debug.

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
