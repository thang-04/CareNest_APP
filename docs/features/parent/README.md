# Parent — màn hình Mobile

Phụ huynh chỉ xem **con có GuardianLink** và **chỉ dữ liệu nhà trường cho phép** (default-deny). Rule: `BE:docs/business/BUSINESS_RULES.md` nhóm PAR + AUTH-04; quyết định: `BE:docs/decisions/ADR-0010-parent-visibility-policy.md`. API phụ huynh là endpoint/DTO riêng — APP hiển thị đúng field DTO có, **không tự lọc/ẩn field thay BE**.

Không có chat (PAR-04) — trao đổi tức thời vẫn qua Zalo.

### Chọn con / Tổng quan con
- Mục đích: chọn con (nếu nhiều), xem tóm tắt hôm nay.
- BE: card `docs/modules/child.md`, `docs/modules/identity-access.md` · rule AUTH-04, PAR-01, PAR-02
- Endpoint: chưa có
- PENDING: P-13b — tóm tắt gồm field nào

### Lịch sử điểm danh
- BE: card `docs/modules/attendance.md` · flow `docs/business/flows/attendance.md` · rule PAR-01, ATT-03 (trẻ đến muộn ⇒ dữ liệu có thể đổi sau lần nhập đầu)
- Endpoint: chưa có

### Bữa ăn
- BE: card `docs/modules/nutrition.md` · flow `docs/business/flows/meal-management.md` · rule PAR-01, NUT-08 (chỉ menu APPROVED)
- Endpoint: chưa có
- PENDING: P-07 (menu chung/riêng campus), P-13b

### Sức khỏe (đã công bố)
- BE: card `docs/modules/health.md` · flow `docs/business/flows/health-check.md` · rule HLT-02 (trend do BE tính), HLT-04, HLT-05 (diễn giải AI chỉ hiện khi đã duyệt), PAR-02
- Endpoint: chưa có
- PENDING: P-13 (ngưỡng tham chiếu — APP không tự tô màu "bất thường"), P-13b
- Dị ứng của con: card `docs/modules/child.md` · HLT-06, P-17

### Hoạt động hằng ngày & cập nhật phát triển (đã duyệt)
- BE: card `docs/modules/learning-observation.md` · flow `docs/business/flows/child-observation.md` · rule OBS-03, OBS-05, PAR-01..03
- Endpoint: chưa có
- PENDING: P-12 (summary có gửi phụ huynh không), P-13b, OBS-07 OPEN (nguồn hoạt động)

### Đơn nghỉ — **PENDING**
- BE: card `docs/modules/attendance.md` · flow `docs/business/flows/leave-request.md` · rule ATT-04 (PROPOSED), ATT-05
- **P-15**: phụ huynh gửi qua app hay GV nhập? có duyệt không? ⇒ không làm màn hình tạo đơn cho tới khi chốt.

### Nhận thông báo
- `docs/integration/PUSH_NOTIFICATION.md` — nội dung chung + deep link, không dữ liệu sức khỏe.

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
