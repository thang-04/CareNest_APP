# Patterns & Lessons — CareNest_APP

Bài học **đã tổng quát hóa** từ incident hoặc quyết định thiết kế. Mỗi pattern có nguồn. Pattern từ thiết kế (chưa có incident) đánh dấu `nguồn: thiết kế`. Pattern phía BE: `BE:docs/knowledge/PATTERNS.md`.

## P-THIN-CLIENT — Client không tự quyết nghiệp vụ
- Quy tắc: không tính số suất, định lượng, trend, field phụ huynh được xem ở APP; hiển thị giá trị/trạng thái BE trả.
- Ví dụ sai: đếm trẻ có mặt để hiển thị số suất cho bếp.
- Nguồn: thiết kế (CROSS_REPO_MAP, NUT-01, ADR-0010).

## P-STATUS-NOT-DESC — Phân nhánh theo HTTP status, không theo chuỗi
- Quy tắc: envelope `{code, desc, data}` có `code` == HTTP status; `desc` chỉ để hiển thị. Cần phân biệt lỗi cùng status ⇒ đề xuất BE bổ sung, không parse `desc`.
- Nguồn: thiết kế (`BE:docs/backend-coding-guide.md` §8).

## P-IDEMPOTENT-RETRY — Chỉ retry thao tác idempotent
- Quy tắc: retry tự động cho `GET` và `PUT` batch lớp/ngày; `POST` confirm/approve/tạo không retry mù, chặn double-submit.
- Nguồn: thiết kế (BE P-IDEMPOTENT-BATCH).

## P-CONTEXT-KEYED-CACHE — Cache theo đủ ngữ cảnh, xóa khi logout
- Quy tắc: key gồm user + role + con/lớp/campus + ngày; đổi ngữ cảnh hủy request cũ; logout xóa cache, queue, token.
- Nguồn: thiết kế.

## P-PUSH-AS-POINTER — Push chỉ là con trỏ
- Quy tắc: payload = loại + ID; mở màn hình rồi tải qua API có auth; không dữ liệu nhạy cảm trong push.
- Nguồn: thiết kế (`BE:docs/modules/notification.md`).

## Format thêm mới

```markdown
## P-<SLUG> — <tên>
- Bối cảnh / Quy tắc / Ví dụ sai
- Nguồn: BUG-xxx, CASE-xxx, ENV-xxx hoặc thiết kế
```
