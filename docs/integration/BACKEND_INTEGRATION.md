# Backend Integration

BE (`CareNest_BE`) là **nguồn duy nhất** của contract. File này chỉ nêu cách APP tiêu thụ contract; khi khác BE ⇒ BE đúng, cập nhật file này.

## Nguồn contract (theo thứ tự ưu tiên)

1. **Source BE đã implement** — `BE:src/main/java/com/carenest/utils/ResponseJson.java`, `ApiCode.java`, `exception/GlobalExceptionHandler.java`, `dto/common/PageResponse.java`.
2. **OpenAPI** sinh bởi springdoc — Swagger UI `/swagger-ui/index.html` khi chạy BE. Danh sách endpoint BE đã có: grep `docs/integration/BE_API_INDEX.md` (ảnh chụp sinh tự động, mỗi dòng `METHOD /path · controller#method`; cập nhật: `node scripts/ai-layer/api-index.mjs --from <repo BE ở origin/dev>`). APP đã gọi `GET /accounts/me`, `POST /parent-activation` khi `USE_MOCK=false`; màn nghiệp vụ còn dữ liệu giả (plan `docs/plans/active/2026-11-16-app-be-integration.md`).
3. `BE:docs/backend-coding-guide.md` §7 (API), §8 (response chuẩn), §11 (exception).
4. `BE:docs/contracts/API_CONVENTIONS.md`, `ERROR_CONTRACT.md` — tóm tắt guide (`{code, desc, data}`, prefix `/api`). Mâu thuẫn ⇒ theo 1–3.

## Base URL & prefix
- Quy ước URL/resource/prefix/endpoint hành động/phân trang: `BE:docs/contracts/API_CONVENTIONS.md` (không chép ở đây).
- Phía APP: base URL theo môi trường (dev/staging/prod) **và prefix** lấy từ config app, không hard-code trong từng call (prefix BE cấu hình được).

## Envelope

Mọi response (thành công và lỗi) có đúng dạng (`BE:docs/contracts/ERROR_CONTRACT.md`):

```json
{ "code": 409, "errorCode": 4007, "desc": "Điểm danh và báo ăn đã khóa sau 08:30", "data": null }
```

| Trường | APP xử lý |
| --- | --- |
| `code` | Integer, **luôn bằng HTTP status**; `code` ≠ status ⇒ `ContractFailure` (lỗi contract, ghi incident) |
| `errorCode` | Mã lỗi nghiệp vụ 4 số; `null` khi thành công. Phân nhánh lỗi theo status + `errorCode` (hằng ở `ApiErrorCodes`), **không so `desc`** |
| `desc` | Câu tiếng Việt hiển thị được cho người dùng (`ApiFailure.message`) |
| `data` | Luôn có mặt; `null` khi không có dữ liệu. Lỗi 400 `9001`: mảng `[{field, message}]` (`ValidationFailure.fieldErrors`) |

## Client (`lib/core/network/`)
- Mọi lời gọi qua `MobileApi` (`lib/core/integration/mobile_api.dart`): `json` / `publicJson` (không Bearer) / `multipart` / `binary`; trả `data` đã decode; lỗi ném `ApiFailure(status, desc, errorCode)`; 401 ⇒ refresh 1 lần rồi gửi lại.
- `AuthInterceptor` gắn Bearer + refresh khi 401 (`docs/integration/AUTH_FLOW.md`); request công khai dùng `skipAuth: true`.
- Timeout: kết nối 10 s, nhận 20 s, gửi 30 s. Log debug: `METHOD /path-đã-che-id status ms`, không header/body/query.
- Test: `test/helpers/fake_http_adapter.dart` trả envelope giả.

Phân trang: `data` = `{ items, page, size, totalElements, totalPages }`; query `?page=0&size=20` (+ lọc `date`, `classId`...).

## Xử lý theo status (mã từ `ApiCode`)

| Status | APP làm |
| --- | --- |
| 200 / 201 | Dùng `data`; sau ghi ⇒ refetch dữ liệu liên quan |
| 400 | Map `data` field errors vào form; không có field ⇒ hiển thị `desc` |
| 401 | Refresh một lần rồi gửi lại; refresh bị từ chối ⇒ về Đăng nhập + xóa dữ liệu phiên (`AUTH_FLOW.md`) |
| 403 | Màn hình "không có quyền"; không retry. `1014`/`1015` ⇒ tài khoản chưa dùng được; `1101` ở `/accounts/me` ⇒ tài khoản dùng Web |
| 404 | "Không tìm thấy" (BE có thể trả 404 thay 403 để ẩn dữ liệu trẻ ngoài scope) |
| 409 | Trạng thái đã đổi (vd. số suất đã xác nhận) ⇒ refetch + thông báo |
| 413 / 415 | Ảnh/tệp quá lớn hoặc sai loại ⇒ báo người dùng |
| 500 | Thông báo lỗi chung, cho thử lại; log status + path template |
| 503 / 504 | Dịch vụ ngoài (AI/storage) không khả dụng/quá giờ ⇒ luồng không AI vẫn dùng được (AI-03) |
| Timeout / mất mạng | Thông báo offline; giữ dữ liệu form; retry theo mục dưới |

Ngôn ngữ `desc`: BE trả câu tiếng Việt (từ 27/10/2026) ⇒ hiển thị được; câu riêng của App chỉ cho các `errorCode` màn hình cần hướng dẫn thêm (vd. `1006` ở Kích hoạt tài khoản).

## Retry & offline (PROPOSED)

- Tự retry (có backoff, giới hạn số lần) chỉ cho `GET` và thao tác ghi idempotent.
- **Batch điểm danh lớp/ngày** (có mặt là ăn — ATT-02, không gửi báo ăn riêng; kèm nhiệt độ đầu ngày — HLT-07): idempotent upsert theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH, `BE:docs/knowledge/PATTERNS.md`); HTTP method TBD ⇒ gửi lại toàn bộ payload an toàn, không tạo trùng. Mất mạng ⇒ giữ batch, đánh dấu "chưa lưu", gửi lại khi có mạng; lưu tạm theo `.claude/rules/security-storage.md`.
- Gửi lại sau giờ chốt (ATT-06, HT cấu hình) ⇒ BE từ chối trừ khi PHT đã mở lại điểm danh (ATT-08) — hiển thị `desc`, không tự sửa giờ. Sửa sau khi suất đã xác nhận ⇒ BE đánh dấu cần xác nhận lại (ATT-07, NUT-03); APP không cần logic riêng.
- Ghi không idempotent (tạo, confirm, approve): không retry mù; chặn double-submit; mất kết nối giữa chừng ⇒ refetch để kiểm tra trước khi gửi lại.
- Offline toàn app: **không** trong scope hiện tại; chỉ batch nhập của giáo viên (PROPOSED, cần chốt).

## Khi contract thiếu hoặc lệch
Không bịa shape. Ghi đề xuất (path, request, `data`, status lỗi, ví dụ) để thống nhất với BE; lệch thực tế ⇒ incident APP + đề xuất mục `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` (CMR-06).
