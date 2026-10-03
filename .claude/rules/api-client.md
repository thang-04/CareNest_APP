---
paths:
  - "src/**/api/**/*.{ts,tsx,js,jsx}"
  - "src/**/services/**/*.{ts,tsx,js,jsx}"
  - "src/**/*client*.{ts,js}"
---

# API client rules

> HTTP client: chưa chọn. Contract nguồn: OpenAPI BE + `BE:docs/backend-coding-guide.md` §7–8 (`BE:` = `../CareNest_BE/`). Quy ước APP: `docs/integration/BACKEND_INTEGRATION.md`.

- Base URL **và prefix** (mặc định BE `/api`, cấu hình được qua `API_PREFIX`) lấy từ config theo môi trường; không hard-code trong từng call.
- Mọi response có envelope `{ code, desc, data }`, `code` == HTTP status. Parse **một chỗ** (interceptor/wrapper), trả `data` cho caller; lỗi chuyển thành error object `{status, desc, fieldErrors?}`.
- Xử lý theo **HTTP status**, không theo nội dung `desc` (desc chỉ để hiển thị/log; lỗi cùng status phân biệt bằng desc nhưng không phải mã ổn định). Cần phân nhánh theo loại lỗi mà status không đủ ⇒ đề xuất BE bổ sung, không parse chuỗi.
- 401 ⇒ luồng auth (`docs/integration/AUTH_FLOW.md`); 403 ⇒ màn hình không có quyền; 404 ⇒ không tìm thấy; 409 ⇒ refetch + thông báo trạng thái đã đổi; 400 ⇒ map `data` field errors; 5xx/503/504 ⇒ thông báo thử lại.
- Type request/response theo DTO BE; field không có trong contract ⇒ không dùng. Phân trang: `data` = `PageResponse {items, page, size, totalElements, totalPages}`.
- Timeout rõ ràng; hủy request khi rời màn hình/đổi ngữ cảnh.
- Retry tự động chỉ cho `GET` và `PUT` idempotent (vd. batch điểm danh lớp/ngày); `POST` (tạo, confirm, approve) không retry mù.
- Không log body request/response, header Authorization, token; log chỉ method + path template + status + thời gian.
- Mock/fixture: dữ liệu giả, đúng envelope; không copy response thật có dữ liệu trẻ.
