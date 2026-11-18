---
paths:
  - "lib/core/network/**/*.dart"
  - "lib/features/**/data/**/*.dart"
---

# API client rules

> HTTP client: `dio` qua `ApiClient` (`lib/core/network/`, CONFIRMED — user 2026-11-13); lỗi chuẩn hóa thành `AppFailure`, phân nhánh theo status + `errorCode`. Contract nguồn: OpenAPI BE + `BE:docs/backend-coding-guide.md` §7–8 (`BE:` = `../CareNest_BE/`). Quy ước APP: `docs/integration/BACKEND_INTEGRATION.md`.

- Base URL **và prefix** (mặc định BE `/api`, cấu hình được qua `API_PREFIX`) lấy từ config theo môi trường; không hard-code trong từng call.
- Mọi response có envelope `{ code, errorCode, desc, data }`, `code` == HTTP status. Parse **một chỗ** (`ApiClient`), trả `data` cho caller; lỗi chuyển thành `AppFailure` (`status`, `errorCode`, `message` = desc, `fieldErrors`).
- Xử lý theo **HTTP status** + `errorCode` (`ApiErrorCodes`), không theo nội dung `desc` (desc là câu tiếng Việt để hiển thị). Thiếu mã để phân nhánh ⇒ đề xuất BE bổ sung, không parse chuỗi.
- 401 ⇒ luồng auth (`docs/integration/AUTH_FLOW.md`); 403 ⇒ màn hình không có quyền; 404 ⇒ không tìm thấy; 409 ⇒ refetch + thông báo trạng thái đã đổi; 400 ⇒ map `data` field errors; 5xx/503/504 ⇒ thông báo thử lại.
- Type request/response theo DTO BE; field không có trong contract ⇒ không dùng. Phân trang: `data` = `PageResponse {items, page, size, totalElements, totalPages}`.
- Timeout rõ ràng; hủy request khi rời màn hình/đổi ngữ cảnh.
- Retry tự động chỉ cho `GET` và ghi idempotent — batch điểm danh lớp/ngày là idempotent upsert theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH); HTTP method TBD. Tạo, confirm, approve không retry mù.
- Không log body request/response, header Authorization, token; log chỉ method + path template + status + thời gian.
- Mock/fixture: dữ liệu giả, đúng envelope; không copy response thật có dữ liệu trẻ.
