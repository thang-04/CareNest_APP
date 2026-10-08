# Backend Integration

BE (`CareNest_BE`) là **nguồn duy nhất** của contract. File này chỉ nêu cách APP tiêu thụ contract; khi khác BE ⇒ BE đúng, cập nhật file này.

## Nguồn contract (theo thứ tự ưu tiên)

1. **Source BE đã implement** — `BE:src/main/java/com/carenest/utils/ResponseJson.java`, `ApiCode.java`, `exception/GlobalExceptionHandler.java`, `dto/common/PageResponse.java`.
2. **OpenAPI** sinh bởi springdoc — Swagger UI `/swagger-ui/index.html` khi chạy BE. Endpoint nghiệp vụ: chưa có.
3. `BE:docs/backend-coding-guide.md` §7 (API), §8 (response chuẩn), §11 (exception).
4. `BE:docs/contracts/API_CONVENTIONS.md`, `ERROR_CONTRACT.md` — tóm tắt guide (`{code, desc, data}`, prefix `/api`). Mâu thuẫn ⇒ theo 1–3.

## Base URL & prefix
- Quy ước URL/resource/prefix/endpoint hành động/phân trang: `BE:docs/contracts/API_CONVENTIONS.md` (không chép ở đây).
- Phía APP: base URL theo môi trường (dev/staging/prod) **và prefix** lấy từ config app, không hard-code trong từng call (prefix BE cấu hình được).

## Envelope

Mọi response (thành công và lỗi) có đúng dạng:

```json
{ "code": 200, "desc": "Get child profile success", "data": { } }
```

| Trường | APP xử lý |
| --- | --- |
| `code` | Integer, **luôn bằng HTTP status**. APP phân nhánh theo HTTP status (= `code`); `code` ≠ status ⇒ coi là lỗi contract, ghi incident |
| `desc` | Thông báo ngắn. Chỉ để hiển thị/log, **không parse để phân nhánh** (lỗi cùng status chỉ khác nhau ở desc, không phải mã ổn định) |
| `data` | Luôn có mặt; `null` khi không có dữ liệu. Lỗi 400 validation: mảng `[{field, message}]` |

Phân trang: `data` = `{ items, page, size, totalElements, totalPages }`; query `?page=0&size=20` (+ lọc `date`, `classId`...).

## Xử lý theo status (mã từ `ApiCode`)

| Status | APP làm |
| --- | --- |
| 200 / 201 | Dùng `data`; sau ghi ⇒ refetch dữ liệu liên quan |
| 400 | Map `data` field errors vào form; không có field ⇒ hiển thị `desc` |
| 401 | Luồng auth (`AUTH_FLOW.md` — SKELETON): làm mới phiên nếu có cơ chế, không thì về Login + xóa dữ liệu phiên |
| 403 | Màn hình "không có quyền"; không retry |
| 404 | "Không tìm thấy" (BE có thể trả 404 thay 403 để ẩn dữ liệu trẻ ngoài scope) |
| 409 | Trạng thái đã đổi (vd. số suất đã xác nhận) ⇒ refetch + thông báo |
| 413 / 415 | Ảnh/tệp quá lớn hoặc sai loại ⇒ báo người dùng |
| 500 | Thông báo lỗi chung, cho thử lại; log status + path template |
| 503 / 504 | Dịch vụ ngoài (AI/storage) không khả dụng/quá giờ ⇒ luồng không AI vẫn dùng được (AI-03) |
| Timeout / mất mạng | Thông báo offline; giữ dữ liệu form; retry theo mục dưới |

Ngôn ngữ `desc`: ví dụ trong guide BE là tiếng Anh — hiển thị trực tiếp hay map sang thông điệp tiếng Việt theo status là **OPEN** (hỏi trước khi chọn).

## Retry & offline (PROPOSED)

- Tự retry (có backoff, giới hạn số lần) chỉ cho `GET` và thao tác ghi idempotent.
- **Batch điểm danh/báo ăn lớp/ngày**: idempotent upsert theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH, `BE:docs/knowledge/PATTERNS.md`); HTTP method TBD ⇒ gửi lại toàn bộ payload an toàn, không tạo trùng. Mất mạng ⇒ giữ batch, đánh dấu "chưa lưu", gửi lại khi có mạng; lưu tạm theo `.claude/rules/security-storage.md`.
- Gửi lại sau cut-off (P-03 PENDING) ⇒ BE có thể từ chối — hiển thị `desc`, không tự sửa giờ. Sửa sau khi suất đã chốt ⇒ BE tự xử lý adjustment (ATT-07, NUT-03); APP không cần logic riêng.
- Ghi không idempotent (tạo, confirm, approve): không retry mù; chặn double-submit; mất kết nối giữa chừng ⇒ refetch để kiểm tra trước khi gửi lại.
- Offline toàn app: **không** trong scope hiện tại; chỉ batch nhập của giáo viên (PROPOSED, cần chốt).

## Khi contract thiếu hoặc lệch
Không bịa shape. Ghi đề xuất (path, request, `data`, status lỗi, ví dụ) để thống nhất với BE; lệch thực tế ⇒ incident APP + đề xuất mục `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` (CMR-06).
