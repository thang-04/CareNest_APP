# Teacher — màn hình Mobile

Giáo viên chỉ truy cập **lớp được phân công** (`BE:` AUTH-03, scope do BE kiểm tra). Teacher dùng cả Web và App; màn hình mobile ưu tiên nhập nhanh tại lớp.

### Chọn lớp / ngày
- BE: card `BE:docs/modules/school-structure.md`, `BE:docs/modules/identity-access.md` · rule AUTH-03
- Endpoint: chưa có

### Điểm danh + báo ăn (nhập hàng loạt)
- Mục đích: nhập có mặt + tham gia ăn cho cả lớp/ngày cùng lúc; cập nhật trẻ đến muộn.
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/attendance.md` · rule ATT-01, ATT-02, ATT-03, ATT-07
- Endpoint: chưa có. Hướng BE: idempotent upsert theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH, `BE:docs/knowledge/PATTERNS.md`); HTTP method TBD ⇒ retry an toàn (`docs/integration/BACKEND_INTEGRATION.md`).
- PENDING: P-03 cut-off (BE từ chối khi quá giờ — APP hiển thị lỗi, không tự khóa theo giờ máy) · P-04 sửa sau khi bếp đã chốt suất (BE xử lý adjustment; APP không cảnh báo theo logic riêng).
- Không: tự tính số suất từ số trẻ có mặt (NUT-01 — BE làm).

### Quan sát hằng ngày (nhập hàng loạt)
- BE: card `BE:docs/modules/learning-observation.md` · flow `BE:docs/business/flows/child-observation.md` · rule OBS-01, OBS-02
- Endpoint: chưa có
- PENDING: P-11 — tiêu chí + thang giá trị là **data từ BE**, không enum cứng trong APP.

### Báo sự cố CSVC
- BE: card `BE:docs/modules/facility-issue.md` · flow `BE:docs/business/flows/facility-issue.md` · rule FAC-01, FAC-04 (PROPOSED trạng thái)
- Endpoint: chưa có
- Ngoài scope: tài sản, khấu hao, bảo trì (FAC-03). Ảnh đính kèm (nếu có) theo giới hạn upload BE.

### Báo nghỉ của lớp (chỉ xem)
- BE: flow `BE:docs/business/flows/leave-request.md` · rule ATT-05, ATT-04
- GV xem thông báo nghỉ của trẻ trong lớp được phân công; **không có bước duyệt**. GV tạo thay phụ huynh: PROPOSED (ATT-05) — chưa làm.

### Nhận suất ăn từ bếp — **PROPOSED**
- BE: rule NUT-15 · flow `BE:docs/business/flows/meal-management.md` (bàn giao suất). GV xác nhận số suất nhận; thiếu/sai ⇒ bếp bàn giao lại.

### Duyệt summary — chỉ nếu được yêu cầu trên mobile
- BE: card `BE:docs/modules/learning-observation.md` · rule OBS-04, OBS-05, AI-01..03
- AI draft hiển thị rõ là bản nháp; luồng phải chạy khi AI tắt. PENDING: P-12.

### Nhập số đo sức khỏe — **PENDING**
- BE: card `BE:docs/modules/health.md` · flow `BE:docs/business/flows/health-check.md` · rule HLT-01 · người nhập chưa chốt (`BE:docs/business/USER_ROLES.md`).

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
