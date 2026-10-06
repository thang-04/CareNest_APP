# Workflow — Integrate API / auth / push (Mobile)

1. **Caller:** màn hình nào, role nào gọi (`docs/features/<role>/README.md`). Điểm chạm trong `BE:docs/system/CROSS_REPO_MAP.md`.
2. **Memory:** grep `docs/knowledge/ISSUE_INDEX.md` theo endpoint/màn hình; `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` (CMR-06: đổi DTO mà client không cập nhật).
3. **Contract nguồn:** snapshot `BE:docs/api/openapi.yaml` (BE khóa bằng test; diff = contract đổi) + OpenAPI của BE (springdoc, Swagger UI `/swagger-ui/index.html` khi BE chạy) + `BE:docs/backend-coding-guide.md` §7–8 (prefix, endpoint, response `{code, desc, data}`, `PageResponse`). Endpoint chưa có ⇒ ghi đề xuất cần thống nhất (path, request, `data`, status lỗi, ví dụ); **không bịa shape**, không tự sửa BE.
4. **Client:** theo `docs/integration/BACKEND_INTEGRATION.md` + `.claude/rules/api-client.md`: base URL + prefix từ config; parse envelope tập trung; xử lý theo HTTP status; timeout; hủy request khi rời màn hình.
5. **Auth:** `docs/integration/AUTH_FLOW.md` (SKELETON — cơ chế auth BE chưa chốt). Không tự chọn JWT/session/refresh; hỏi.
6. **Push:** `docs/integration/PUSH_NOTIFICATION.md` (SKELETON — provider chưa chốt). Payload chỉ chứa loại sự kiện + ID để deep link; không dữ liệu nhạy cảm.
7. **Ghi dữ liệu:** batch theo lớp/ngày là idempotent upsert theo lớp/ngày (BE PAT-IDEMPOTENT-BATCH; HTTP method TBD) ⇒ retry an toàn; ghi không idempotent (tạo, confirm) ⇒ chặn double-submit, không tự retry mù.
8. **Test:** parse thành công/lỗi (400 kèm field errors, 401, 403, 404, 409, 5xx, timeout, mất mạng). Mock dùng dữ liệu giả, đúng envelope.
9. **Docs & memory:** cập nhật feature doc (endpoint đã dùng), `BACKEND_INTEGRATION.md` nếu thêm quy ước. Contract lệch BE ⇒ incident APP + đề xuất mục cho `BE:docs/knowledge/CROSS_MODULE_ISSUES.md`.
10. Báo: đã test với BE thật hay mock; phần BE/FE cần đổi theo. Đối chiếu DoD.
