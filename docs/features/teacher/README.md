# Teacher — màn hình Mobile

Giáo viên chỉ truy cập **lớp được phân công** (`BE:` AUTH-03, scope do BE kiểm tra). Teacher dùng cả Web và App; điểm danh chủ yếu trên App (ATT-01), màn hình mobile ưu tiên nhập nhanh tại lớp. Tổ trưởng chuyên môn là phân công trên tài khoản GV, không phải role đăng nhập (AUTH-23). App tập trung cho GV: điểm danh, sức khỏe, đánh giá, đón trẻ, thông báo (AUTH-21, user chốt 29/10); soạn kế hoạch giáo dục làm trên Web (EDU). GV cũ được xem lại lớp/năm học từng dạy, chỉ đọc (AUTH-03 mở rộng — BE chưa code).

### Chọn lớp / ngày
- BE: card `BE:docs/modules/school-structure.md`, `BE:docs/modules/identity-access.md` · rule AUTH-03
- Endpoint: chưa có

### Trang chủ giáo viên (bố cục D)
- Giao diện (user 2026-10-14, `docs/design/mobile-redesign-clay.md`): lời chào → thẻ lớp nổi bật (tên lớp, sĩ số, hoạt động đang diễn ra, vòng "x/N đã điểm danh", hạn điểm danh, nút "Điểm danh ngay") → "Việc tiếp theo" trượt ngang. Hết việc điểm danh ⇒ không còn nút và hạn.
- Vòng tiến độ cần **số bé đã điểm danh** do BE trả (`attendanceRecorded` ở `TeacherToday`, chưa có trong contract) ⇒ đề xuất khi viết endpoint trang chủ GV; APP không tự đếm. Không có số ⇒ không vẽ vòng.

### Điểm danh + nhiệt độ đầu ngày (nhập hàng loạt)
- Mục đích: nhập Có mặt / Vắng cho cả lớp/ngày cùng lúc. Có mặt là ăn tất cả các bữa đã cấu hình cho nhóm tuổi; GV không nhập tham gia ăn riêng (ATT-02). Vắng có phép tự động khi phụ huynh đã gửi đơn nghỉ, còn lại không phép (ATT-04, ATT-09). Khi nhận trẻ, GV đo nhiệt độ mọi trẻ và nhập cùng màn điểm danh; không chụp ảnh trẻ, dặn dò miệng của phụ huynh không ghi (HLT-07).
- BE: card `BE:docs/modules/attendance.md`, `BE:docs/modules/health.md` · flow `BE:docs/business/flows/attendance.md` · rule ATT-01, ATT-02, ATT-03, ATT-06, ATT-07, ATT-08, ATT-09, HLT-07
- Endpoint: chưa có. Hướng BE: idempotent upsert theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH, `BE:docs/knowledge/PATTERNS.md`); HTTP method TBD ⇒ retry an toàn (`docs/integration/BACKEND_INTEGRATION.md`).
- Giờ chốt: một giờ chung toàn trường, HT cấu hình theo mùa (ATT-06, đóng P-03) — BE trả/từ chối khi quá giờ, APP hiển thị lỗi, không tự khóa theo giờ máy. Sau giờ chốt không nhận trẻ đến muộn (ATT-03); điểm danh/sửa sau giờ chốt chỉ khi PHT mở lại, có lý do (ATT-08). Sửa sau khi suất đã xác nhận ⇒ BE đánh dấu cần xác nhận lại (ATT-07, NUT-03; đóng P-04); APP không cảnh báo theo logic riêng.
- PENDING: P-20 (trẻ có đơn nghỉ vẫn đến lớp) · P-21 (danh sách triệu chứng chọn nhanh) · P-22 (trẻ có dấu hiệu bất thường có nhận không) · P-23 (mức ưu tiên Capstone của sức khỏe đầu ngày).
- Không: tự tính số suất từ số trẻ có mặt (NUT-01 — BE làm).
- Figma sửa 13/11 (plan `docs/plans/active/2026-11-13-app-ui-redraw.md`): mỗi bé hai nút Có mặt / Vắng, không báo ăn, không "Ăn 1 bữa" (ATT-02); bé có mặt nhập nhiệt độ đầu ngày (°C, 1 chữ số thập phân, hiển thị dấu phẩy — HLT-07; khoảng 34,0–42,0 chỉ hỗ trợ nhập); bé có đơn nghỉ khóa ở "Có phép (theo đơn)", GV không đổi và không tự chọn Vắng có phép (ATT-04, ATT-09). Giờ khóa lấy từ field BE trả (`lockAt`), đúng ATT-06.

### Đánh giá hằng ngày (nhập hàng loạt)
- BE: card `BE:docs/modules/learning-observation.md` · flow `BE:docs/business/flows/child-observation.md` · rule OBS-01, OBS-02, OBS-07, OBS-10, OBS-12, OBS-13
- Endpoint: chưa có
- PENDING: P-11 — tiêu chí + thang giá trị là **data từ BE**, không enum cứng trong APP.
- Mockup T04 / T04.1: danh sách bé (đã / chưa đánh giá, bé vắng không cần), màn một bé + ghi chú cho phụ huynh + "Gắn cờ: Hành vi tốt" (phiếu bé ngoan OBS-10). Bỏ thẻ "Giáo án đã duyệt"; dòng hoạt động trong ngày lấy từ kế hoạch ngày (OBS-07).
- Figma sửa 13/11: 7 mặt (ăn uống, ngủ, cảm xúc, hành vi, tham gia hoạt động, kiến thức – kỹ năng, sức khỏe), mức Đạt / Cần cố gắng / Chưa đạt, mặc định Đạt (`defaultOption` BE trả), GV chỉ sửa bé khác thường (OBS-01, OBS-02). Hết ngày thì khóa (OBS-12) — chưa làm. Phiếu bé ngoan: GV tự chọn trẻ, hệ thống không gợi ý (OBS-10) — APP không tự đếm cờ, ngày đi học.

### Báo sự cố CSVC — **REMOVED ở BE (29/10)**
- BE: FAC-01..04 REMOVED (Report 1 v2, khảo sát team 27/10, user chốt 29/10). Không làm màn này.

### Báo nghỉ của lớp (chỉ xem)
- BE: flow `BE:docs/business/flows/leave-request.md` · rule ATT-05, ATT-04
- GV xem thông báo nghỉ của trẻ trong lớp được phân công; **không có bước duyệt**. GV không tạo đơn thay phụ huynh (ATT-05, chốt 27/10).
- Mockup T03 (Figma sửa 13/11): lọc "Hôm nay & sắp tới" / "Tất cả"; chỉ xem — không badge Mới / Đã xem, không nút đánh dấu đã xem, đơn theo ngày không chia buổi; ghi chú "Ngày có đơn tự ghi Vắng có phép, không có suất. GV chỉ xem đơn." (ATT-04). Danh sách gồm cả trẻ **vắng không đơn** kèm ghi chú GV đã gọi phụ huynh ⇒ BE chưa có bản ghi này, đề xuất BE.

### Nhận suất ăn từ bếp — **REMOVED ở BE (28/10)**
- BE: rule NUT-15 · flow `BE:docs/business/flows/meal-management.md` (bàn giao suất). GV xác nhận số suất nhận; thiếu/sai ⇒ bếp bàn giao lại.
- BE 28/10: NUT-15 REMOVED — không ghi nhận bàn giao, bếp chia suất theo danh sách lớp; GV không cần cảnh báo dị ứng khi chia ăn (NUT-23). Không làm màn này.

### Nhận xét định kỳ — chỉ nếu được yêu cầu trên mobile
- BE: card `BE:docs/modules/learning-observation.md` · rule OBS-04, OBS-05, OBS-06, AI-01..03, AI-07
- AI draft hiển thị rõ là bản nháp; luồng phải chạy khi AI tắt. GV xác nhận là xong, không có bước BGH duyệt (OBS-05); kỳ tuần/tháng/học kỳ/năm, phụ huynh nhận mọi kỳ (OBS-06). Mẫu của trường: P-30.

### Cân đo, sức khỏe trong ngày
- BE: card `BE:docs/modules/health.md` · flow `BE:docs/business/flows/health-check.md` · rule HLT-01 (mặc định 3 lần/năm, BE cấu hình — không hard-code chu kỳ), HLT-09 (GV cân đo lớp mình), HLT-10 (BE phân loại theo WHO, GV chỉnh kèm lý do), HLT-11 (phụ huynh thấy sau công bố), HLT-13 (sửa số đo kèm lý do, có lịch sử), HLT-14 (sức khỏe trong ngày: triệu chứng, xử trí, báo phụ huynh ngay). Nhiệt độ đầu ngày không thuộc màn này (HLT-07, mục Điểm danh).
- Mockup T07 / T07.1 dựng dữ liệu giả ở bản debug (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md` K1): danh sách đã / chưa đo, nhập chiều cao + cân nặng, câu "Không phải chẩn đoán y tế" (HLT-04).
- Figma sửa 13/11: không có công tắc công bố — "Lưu là công bố cho phụ huynh" (HLT-11); phân loại Thiếu cân / Bình thường / Thừa cân chỉ hiển thị, "Kết quả do hệ thống tính (chỉ hiển thị)", GV không chọn (HLT-12, HLT-18; P-40 chưa cho chỉnh tay); sửa số đo đã lưu bắt buộc "Lý do sửa", BE lưu lịch sử (HLT-13). Chưa có màn sức khỏe trong ngày (HLT-14).

### Chụp và gửi ảnh bữa ăn — **gỡ lối vào (13/11)**
- Figma sửa 13/11: ảnh bữa ăn là ảnh mẫu của bếp cơ sở (NUT-16) ⇒ gỡ việc "Ảnh bữa ăn" ở Trang chủ GV và route `/teacher/meal-photos*`; giữ code `lib/features/meal_photos` và test dựng màn trực tiếp.
- Ảnh bữa ăn — **PROPOSED** (user 2026-10-13): (1) bếp chụp ảnh món khi nấu xong; (2) giáo viên chụp khay khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món ăn trong thực đơn/lịch của con. BE NUT-16 hiện chỉ ghi bếp chụp ⇒ đề xuất cập nhật BE.
- Mockup: `docs/design/figma/teacher-15-16-meal-photo-capture-send.png` (chọn bữa, chụp suất thường / suất thay thế, gửi phụ huynh cả lớp hoặc riêng phụ huynh có suất thay thế).
- BE: rule NUT-16 · Endpoint: chưa có · upload theo `DESIGN.md` §16.1 (PROPOSED).
- Chưa chọn thư viện camera (hỏi trước khi thêm): khung ngắm là khối tĩnh, nút chụp chỉ thêm ảnh giữ chỗ.
- Lệch BE (28/10): NUT-16 CONFIRMED chỉ **bếp** chụp ảnh mẫu mỗi bữa, dùng chung toàn trường; phụ huynh xem trong thực đơn ngày (PAR-01). Màn T15/T16 của GV cần bỏ hoặc đề xuất BE khi tích hợp.

### Đón trẻ + xác minh người đón
- BE: card `BE:docs/modules/attendance.md` · flow pickup của BE (chưa merge nhánh chính BE) · rule PCK-01..04, ATT-10: màn đón hiện danh sách phụ huynh/người giám hộ; người lạ ⇒ gọi phụ huynh, ghi lý do; lưu người đón, giờ đón (cả đón muộn, về sớm); báo phụ huynh. Ảnh đối chiếu: P-33.
- Mockup T05 / T06 (plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md` K4): danh sách chờ đón / đã đón, xác minh người đón đã đăng ký (ảnh, tên, SĐT), "Đúng – giao bé" ⇒ BE ghi giờ, người đón và báo phụ huynh.
- Figma sửa 13/11: "Không khớp – gọi phụ huynh" mở phần ghi cuộc gọi: bắt buộc "Nội dung cuộc gọi" rồi chọn "Trả bé" (bắt buộc "Người đến đón"; ghi người đón, giờ đón, báo phụ huynh) hoặc "Không trả bé" (chỉ ghi lần đón, không giao bé) — PCK-02, PCK-04. Bản giả: `PickupCall` qua `PickupSource.recordCall`.
- Lệch BE (29/10): mock xác minh theo người đón đã đăng ký (ảnh, tên, SĐT); BE không đăng ký trước người đón hộ (PCK-03), chỉ dùng danh sách phụ huynh/người giám hộ; người lạ phải ghi lý do trước khi xác nhận (PCK-02). Ảnh người đón chỉ tải qua URL có auth; bản giả dùng icon. Gọi điện cần plugin quay số (chưa thêm).

### Lớp học (danh sách bé)
- Mockup T09: tên, tuổi, liên hệ phụ huynh, nhãn dị ứng / chế độ ăn / nghỉ (HLT-06, AUTH-03). Mở chi tiết bé: chưa có trong mockup ⇒ "Sắp có".
- Lệch BE (28/10): nhãn chế độ ăn "Ăn 1 bữa" — BE không có chế độ ăn đặc biệt ngoài dị ứng (HLT-06) và không báo ăn theo bữa (ATT-02) — cần sửa khi tích hợp.

### Lịch hoạt động
- Mockup T10, bỏ "Giáo án tuần đã duyệt", "Tổ trưởng & Phó HT ký duyệt", "Xem file". Nguồn lịch: kế hoạch ngày của module education-plan (OBS-07, EDU-01, ADR-0019; card BE chưa merge nhánh chính BE); soạn và duyệt làm trên Web. Chưa có API ⇒ dữ liệu giả ở bản debug.

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
