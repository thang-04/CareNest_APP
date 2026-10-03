# Teacher — màn hình Mobile

Giáo viên chỉ truy cập **lớp được phân công** (`BE:` AUTH-03, scope do BE kiểm tra). Teacher dùng cả Web và App; màn hình mobile ưu tiên nhập nhanh tại lớp.

### Chọn lớp / ngày
- BE: card `docs/modules/school-structure.md`, `docs/modules/identity-access.md` · rule AUTH-03
- Endpoint: chưa có

### Điểm danh + báo ăn (nhập hàng loạt)
- Mục đích: nhập có mặt + tham gia ăn cho cả lớp/ngày cùng lúc; cập nhật trẻ đến muộn.
- BE: card `docs/modules/attendance.md` · flow `docs/business/flows/attendance.md` · rule ATT-01, ATT-02, ATT-03, ATT-07
- Endpoint: chưa có. Hướng BE: `PUT` idempotent theo lớp/ngày (pattern P-IDEMPOTENT-BATCH trong `BE:docs/knowledge/PATTERNS.md`) ⇒ retry an toàn (`docs/integration/BACKEND_INTEGRATION.md`).
- PENDING: P-03 cut-off (BE từ chối khi quá giờ — APP hiển thị lỗi, không tự khóa theo giờ máy) · P-04 sửa sau khi bếp đã chốt suất (BE xử lý adjustment; APP không cảnh báo theo logic riêng).
- Không: tự tính số suất từ số trẻ có mặt (NUT-01 — BE làm).

### Quan sát hằng ngày (nhập hàng loạt)
- BE: card `docs/modules/learning-observation.md` · flow `docs/business/flows/child-observation.md` · rule OBS-01, OBS-02
- Endpoint: chưa có
- PENDING: P-11 — tiêu chí + thang giá trị là **data từ BE**, không enum cứng trong APP.

### Báo sự cố CSVC
- BE: card `docs/modules/facility-issue.md` · flow `docs/business/flows/facility-issue.md` · rule FAC-01, FAC-04 (PROPOSED trạng thái)
- Endpoint: chưa có
- Ngoài scope: tài sản, khấu hao, bảo trì (FAC-03). Ảnh đính kèm (nếu có) theo giới hạn upload BE.

### Đơn nghỉ của lớp — **PENDING**
- BE: flow `docs/business/flows/leave-request.md` · rule ATT-04, ATT-05 · **P-15** (ai tạo/duyệt).

### Duyệt summary — chỉ nếu được yêu cầu trên mobile
- BE: card `docs/modules/learning-observation.md` · rule OBS-04, OBS-05 (DRAFT → GV sửa → APPROVED), AI-01..03
- AI draft hiển thị rõ là bản nháp; luồng phải chạy khi AI tắt. PENDING: P-12.

### Nhập số đo sức khỏe — **PENDING**
- BE: card `docs/modules/health.md` · flow `docs/business/flows/health-check.md` · rule HLT-01 · người nhập chưa chốt (`BE:docs/business/USER_ROLES.md`).

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
