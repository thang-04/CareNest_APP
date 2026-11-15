# Parent — màn hình Mobile

Phụ huynh chỉ xem **con có GuardianLink** và **chỉ dữ liệu nhà trường cho phép** (default-deny). Rule: `BE:docs/business/BUSINESS_RULES.md` nhóm PAR + AUTH-04; quyết định: `BE:docs/decisions/ADR-0010-parent-visibility-policy.md`. API phụ huynh là endpoint/DTO riêng — APP hiển thị đúng field DTO có, **không tự lọc/ẩn field thay BE**.

Không có chat (PAR-04) — trao đổi tức thời vẫn qua Zalo.

### Chọn con / Tổng quan con
- Mục đích: chọn con (nếu nhiều), xem tóm tắt hôm nay.
- BE: card `BE:docs/modules/child.md`, `BE:docs/modules/identity-access.md` · rule AUTH-04, PAR-01, PAR-02
- Endpoint: chưa có
- Field: PAR-01 (chốt 29/10, đóng P-13b) — tóm tắt chỉ gồm các mục trong danh sách; một tài khoản xem mọi con (PAR-06).
- Giao diện (bố cục H, user 2026-10-14, `docs/design/mobile-redesign-clay.md`): thẻ bé đang chọn là thẻ lớn; bé khác ló ra dưới thẻ, chạm để đổi; từ 3 bé thì phần ló ghi "+N bé khác" mở sheet chọn bé. Ba ô hôm nay chỉ hiện field đang có (điểm danh, thực đơn đã công bố hay chưa, tên hoạt động); trạng thái của bé đang ló không hiện vì cần thêm một lần gọi dữ liệu.

### Lịch sử điểm danh
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/attendance.md` · rule PAR-01, ATT-09 (Có mặt / Vắng; vắng có phép khi có đơn nghỉ), ATT-03 (sau giờ chốt không nhận trẻ muộn), ATT-08 (PHT mở lại ⇒ dữ liệu có thể đổi sau lần nhập đầu)
- Endpoint: chưa có

### Bữa ăn
- BE: card `BE:docs/modules/nutrition.md` · flow `BE:docs/business/flows/meal-management.md` · rule PAR-01 (thực đơn tuần + thực đơn ngày, ngày có ảnh suất ăn hôm đó), NUT-08 (chỉ thực đơn đã công bố), NUT-13 (một thực đơn chung hai cơ sở — đóng P-07), NUT-16
- Endpoint: chưa có
- Field: PAR-01 (thực đơn tuần/ngày, ảnh suất ăn — chốt 29/10, đóng P-13b).
- Ảnh bữa ăn — **PROPOSED** (user 2026-10-13): (1) bếp chụp ảnh món khi nấu xong; (2) giáo viên chụp khay khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món ăn trong thực đơn/lịch của con. BE NUT-16 hiện chỉ ghi bếp chụp ⇒ đề xuất cập nhật BE. Ảnh chỉ tải qua URL có auth; ảnh chụp khay suất ăn, không chụp mặt trẻ.
- Lệch BE (28/10): NUT-16 CONFIRMED chỉ bếp chụp ảnh mẫu mỗi bữa, dùng chung toàn trường; dữ liệu giả `MealPhotoSet` ghi ảnh "GV đăng khi nhận suất" — cần sửa khi tích hợp.

### Sức khỏe (đã công bố)
- BE: card `BE:docs/modules/health.md` · flow `BE:docs/business/flows/health-check.md` · rule HLT-02 (trend do BE tính), HLT-04, HLT-05 (diễn giải AI chỉ hiện khi đã duyệt), PAR-02
- Endpoint: chưa có
- Phân loại theo WHO do BE trả (HLT-03, HLT-10; đóng P-13) — APP không tự tô màu "bất thường". Cân đo chỉ hiện sau khi GV/PHT công bố (HLT-11, PAR-03).
- Từ 29/10 PAR-01 có thêm sức khỏe trong ngày và xử trí (HLT-14, báo ngay, không chờ công bố) — đối chiếu màn Hôm nay khi tích hợp.
- Nhãn "Tình trạng dinh dưỡng" chỉ hiện khi BE trả nhãn (field null ⇒ ẩn dòng); bản giả có "Bình thường" ở debug. Biểu đồ cân nặng tự vẽ, không tô vùng chuẩn.
- Dị ứng của con: card `BE:docs/modules/child.md` · HLT-06 (phụ huynh khai khi nhập học, mức nhẹ/nặng — đóng P-17), NUT-23

### Cập nhật phát triển (đã duyệt) & Hoạt động hằng ngày
- BE: card `BE:docs/modules/learning-observation.md` · flow `BE:docs/business/flows/child-observation.md` · rule OBS-03, OBS-05, OBS-06, OBS-10, OBS-13, OBS-14, EDU-09, PAR-01, PAR-03
- Endpoint: chưa có
- Đã chốt 29/10: phụ huynh nhận mọi kỳ nhận xét (OBS-06, đóng P-12); đánh giá ngày hiện sau khi GV lưu (OBS-13); dữ liệu có công bố chỉ hiện sau khi công bố (PAR-03, đóng P-13b).
- "Hoạt động hằng ngày": phụ huynh thấy tên các hoạt động trong ngày của lớp (EDU-09), lấy từ kế hoạch ngày (OBS-07, ADR-0019). UI dữ liệu giả `/parent/activities` chỉ có ở bản debug (user cho dựng giả 2026-10-13, plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md` K1); bật ở release khi BE có API kế hoạch ngày.
- Phiếu bé ngoan / khen thưởng cuối năm (tab Phát triển): OBS-10 (phiếu tuần, phụ huynh thấy ngay khi GV xác nhận), OBS-14 (khen cuối năm); làm cả hai: P-31 — số phiếu và ngưỡng là BE trả.

### Báo nghỉ (đơn nghỉ)
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/leave-request.md` · rule ATT-05 (CONFIRMED), ATT-04, ATT-09, ATT-05b (PROPOSED) · permission `leave:create`
- Mục đích: phụ huynh gửi **thông báo nghỉ** cho con (từ ngày, đến ngày, lý do), xem danh sách đã gửi, hủy thông báo. **Không có bước duyệt** — không hiển thị trạng thái chờ duyệt/duyệt/từ chối. Chỉ phụ huynh tạo; GV không tạo thay (ATT-05).
- Trạng thái: `SUBMITTED → CANCELLED` (phụ huynh hủy). Ngày có đơn ⇒ trẻ Vắng có phép tự động, không có suất (ATT-04, ATT-09); ngày đã qua giờ chốt/đã xác nhận suất (ATT-05b) do BE xử lý — APP hiển thị kết quả/lỗi BE trả, không tự tính.
- Endpoint: chưa có. Giờ chốt: một giờ chung toàn trường, HT cấu hình (ATT-06, đóng P-03) — BE quyết định, APP không khóa theo giờ máy. PENDING: P-20 (con có đơn nghỉ vẫn đến lớp).
- Mockup P03–P04 (user 2026-10-13) thêm **buổi nghỉ** (cả ngày / sáng / chiều), **lý do tự nhập** (≤500 ký tự) và trạng thái **GV đã xem / GV chưa xem** — BE chưa có field `session`, `seenByTeacher` ⇒ đề xuất BE. Nghỉ nửa buổi xử lý suất ăn ra sao chưa có rule ⇒ form chỉ báo huỷ suất khi nghỉ cả ngày (ATT-04). Mockup chưa có thao tác huỷ đơn; danh sách vẫn hiển thị "Đã huỷ" nếu BE trả.
- Lệch BE (28/10): ATT-05 chỉ có ngày bắt đầu–kết thúc + lý do, không có buổi nghỉ; suất tính theo điểm danh cả ngày (ATT-02) — field `session` (`LeaveSession`) cần bỏ hoặc đề xuất BE khi tích hợp.

### Tài khoản phụ huynh
- BE: card `BE:docs/modules/identity-access.md` · rule AUTH-18 (tên đăng nhập = SĐT; tài khoản + mật khẩu tạm gửi qua SMS, in phiếu dự phòng — code BE hiện chỉ có in phiếu), CHD-05 (chỉ sửa thông tin liên lạc của mình; thông tin trẻ do trường sửa), CHD-04 (trẻ thôi học ⇒ mất quyền xem trẻ đó ngay; tài khoản vẫn dùng cho trẻ khác) · PENDING P-28 (số tài khoản mỗi trẻ)
- Endpoint: chưa có. Danh sách con và field được sửa là BE trả; APP không tự lọc trẻ thôi học. Màn "Thông tin cá nhân" dùng chung đang cho sửa họ tên, SĐT, email — field nào phụ huynh được sửa và đổi SĐT (là tên đăng nhập) theo contract BE.
- Giao diện form (bố cục D, user 2026-10-14): lịch tháng chạm ngày đầu rồi ngày cuối để chọn khoảng; ngày đã qua và quá 180 ngày không chọn được (hỗ trợ nhập, BE vẫn kiểm tra cut-off); ngày đã có đơn nghỉ có chấm + nhãn "Đã báo nghỉ" lấy từ danh sách đơn BE trả.

### Đón con
- BE: card `BE:docs/modules/attendance.md` · rule PCK-04 (ai đã đón, giờ đón; thông báo khi con được đón), PCK-03 (không đăng ký trước người đón hộ trên App — báo GV qua gọi/nhắn).
- Endpoint: chưa có.

### Nhận thông báo
- `docs/integration/PUSH_NOTIFICATION.md` — nội dung chung + deep link, không dữ liệu sức khỏe.
- Thông báo của trường do BGH gửi, push + trong App, không có trạng thái đã đọc (PAR-05). Phụ huynh gửi ý kiến cho trường: P-32 (chưa làm).

## Known pitfalls
- Lời chào đặt cạnh nút chuông (không còn hero): `Semantics` phải có `container: true`, không thì gộp thành một câu đọc — `docs/knowledge/incidents/APP-BUG-261014-greeting-bell-semantics-merge.md`.
