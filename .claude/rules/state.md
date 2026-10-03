---
paths:
  - "src/**/store/**/*.{ts,tsx,js,jsx}"
  - "src/**/state/**/*.{ts,tsx,js,jsx}"
  - "src/**/hooks/**/*.{ts,tsx,js,jsx}"
  - "src/**/queries/**/*.{ts,tsx,js,jsx}"
---

# State & cache rules

> Thư viện state/cache: chưa chọn (hỏi trước khi chọn). Nguyên tắc: `docs/architecture/STATE_MANAGEMENT.md`.

- **Server state** (dữ liệu từ BE) tách khỏi **UI state** (form đang nhập, tab đang chọn). BE là nguồn sự thật; client chỉ cache.
- Cache key gồm đủ ngữ cảnh: user + role + childId/classId/campusId + ngày. Đổi user/role/con/lớp không được thấy dữ liệu cũ.
- **Logout / hết phiên ⇒ xóa toàn bộ cache, state, offline queue, file tạm** chứa dữ liệu trẻ.
- Sau khi ghi thành công ⇒ invalidate/refetch dữ liệu liên quan; không tự cập nhật số liệu dẫn xuất (vd. số suất) ở client.
- Optimistic update chỉ cho thao tác idempotent và có rollback rõ; không dùng cho xác nhận/duyệt.
- Không persist dữ liệu sức khỏe/dị ứng/ảnh xuống storage thường; persist (nếu cần offline) theo `.claude/rules/security-storage.md`.
- Response đến muộn của request cũ không được ghi đè state của ngữ cảnh mới (hủy hoặc so khớp key).
- Không derive quyết định nghiệp vụ từ state client (vd. "đã quá giờ chốt" — cut-off P-03 PENDING, BE quyết định).
