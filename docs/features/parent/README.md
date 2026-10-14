# Parent — màn hình Mobile

Phụ huynh chỉ xem **con có GuardianLink** và **chỉ dữ liệu nhà trường cho phép** (default-deny). Rule: `BE:docs/business/BUSINESS_RULES.md` nhóm PAR + AUTH-04; quyết định: `BE:docs/decisions/ADR-0010-parent-visibility-policy.md`. API phụ huynh là endpoint/DTO riêng — APP hiển thị đúng field DTO có, **không tự lọc/ẩn field thay BE**.

Không có chat (PAR-04) — trao đổi tức thời vẫn qua Zalo.

### Chọn con / Tổng quan con
- Mục đích: chọn con (nếu nhiều), xem tóm tắt hôm nay.
- BE: card `BE:docs/modules/child.md`, `BE:docs/modules/identity-access.md` · rule AUTH-04, PAR-01, PAR-02
- Endpoint: chưa có
- PENDING: P-13b — tóm tắt gồm field nào
- Giao diện (bố cục H, user 2026-10-14, `docs/design/mobile-redesign-clay.md`): thẻ bé đang chọn là thẻ lớn; bé khác ló ra dưới thẻ, chạm để đổi; từ 3 bé thì phần ló ghi "+N bé khác" mở sheet chọn bé. Ba ô hôm nay chỉ hiện field đang có (điểm danh, thực đơn đã công bố hay chưa, tên hoạt động); trạng thái của bé đang ló không hiện vì cần thêm một lần gọi dữ liệu.

### Lịch sử điểm danh
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/attendance.md` · rule PAR-01, ATT-03 (trẻ đến muộn ⇒ dữ liệu có thể đổi sau lần nhập đầu)
- Endpoint: chưa có

### Bữa ăn
- BE: card `BE:docs/modules/nutrition.md` · flow `BE:docs/business/flows/meal-management.md` · rule PAR-01, NUT-08 (chỉ MealPlan (thực đơn) APPROVED)
- Endpoint: chưa có
- PENDING: P-07 (thực đơn chung/riêng campus), P-13b
- Ảnh bữa ăn — **PROPOSED** (user 2026-10-13): (1) bếp chụp ảnh món khi nấu xong; (2) giáo viên chụp khay khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món ăn trong thực đơn/lịch của con. BE NUT-16 hiện chỉ ghi bếp chụp ⇒ đề xuất cập nhật BE. Ảnh chỉ tải qua URL có auth; ảnh chụp khay suất ăn, không chụp mặt trẻ.

### Sức khỏe (đã công bố)
- BE: card `BE:docs/modules/health.md` · flow `BE:docs/business/flows/health-check.md` · rule HLT-02 (trend do BE tính), HLT-04, HLT-05 (diễn giải AI chỉ hiện khi đã duyệt), PAR-02
- Endpoint: chưa có
- PENDING: P-13 (ngưỡng tham chiếu — APP không tự tô màu "bất thường"), P-13b
- Nhãn "Tình trạng dinh dưỡng" chỉ hiện khi BE trả nhãn (field null ⇒ ẩn dòng); bản giả có "Bình thường" ở debug. Biểu đồ cân nặng tự vẽ, không tô vùng chuẩn.
- Dị ứng của con: card `BE:docs/modules/child.md` · HLT-06, P-17

### Cập nhật phát triển (đã duyệt) & Hoạt động hằng ngày
- BE: card `BE:docs/modules/learning-observation.md` · flow `BE:docs/business/flows/child-observation.md` · rule OBS-03, OBS-05, PAR-01..03
- Endpoint: chưa có
- PENDING: P-12 (summary có gửi phụ huynh không), P-13b
- "Hoạt động hằng ngày" (OBS-07, ADR-0006 OPEN): đã dựng UI dữ liệu giả `/parent/activities`, chỉ có ở bản debug (user cho dựng giả 2026-10-13, plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md` K1). Không bật ở release khi OBS-07 chưa chốt.
- Phiếu bé ngoan / khen thưởng cuối năm (tab Phát triển): OBS-10 PROPOSED, tiêu chí P-11 — số phiếu và ngưỡng là BE trả.

### Báo nghỉ (đơn nghỉ)
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/leave-request.md` · rule ATT-05 (CONFIRMED), ATT-04, ATT-05b (PROPOSED) · permission `leave:create`
- Mục đích: phụ huynh gửi **thông báo nghỉ** cho con (từ ngày, đến ngày, lý do), xem danh sách đã gửi, hủy thông báo. **Không có bước duyệt** — không hiển thị trạng thái chờ duyệt/duyệt/từ chối.
- Trạng thái: `SUBMITTED → CANCELLED` (phụ huynh hủy). Ảnh hưởng điểm danh/suất ăn (ATT-04) và ngày đã qua cut-off/đã xác nhận suất (ATT-05b) do BE xử lý — APP hiển thị kết quả/lỗi BE trả, không tự tính.
- Endpoint: chưa có. PENDING: P-03 (giờ cut-off — BE quyết định, APP không khóa theo giờ máy).
- Mockup P03–P04 (user 2026-10-13) thêm **buổi nghỉ** (cả ngày / sáng / chiều), **lý do tự nhập** (≤500 ký tự) và trạng thái **GV đã xem / GV chưa xem** — BE chưa có field `session`, `seenByTeacher` ⇒ đề xuất BE. Nghỉ nửa buổi xử lý suất ăn ra sao chưa có rule ⇒ form chỉ báo huỷ suất khi nghỉ cả ngày (ATT-04). Mockup chưa có thao tác huỷ đơn; danh sách vẫn hiển thị "Đã huỷ" nếu BE trả.
- Giao diện form (bố cục D, user 2026-10-14): lịch tháng chạm ngày đầu rồi ngày cuối để chọn khoảng; ngày đã qua và quá 180 ngày không chọn được (hỗ trợ nhập, BE vẫn kiểm tra cut-off); ngày đã có đơn nghỉ có chấm + nhãn "Đã báo nghỉ" lấy từ danh sách đơn BE trả.

### Nhận thông báo
- `docs/integration/PUSH_NOTIFICATION.md` — nội dung chung + deep link, không dữ liệu sức khỏe.

## Known pitfalls
- Lời chào đặt cạnh nút chuông (không còn hero): `Semantics` phải có `container: true`, không thì gộp thành một câu đọc — `docs/knowledge/incidents/APP-BUG-261014-greeting-bell-semantics-merge.md`.
