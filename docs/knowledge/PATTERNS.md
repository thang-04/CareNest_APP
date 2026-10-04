# Patterns & Lessons — CareNest_APP

Bài học tổng quát, mỗi pattern có nguồn. Pattern lấy từ thiết kế chỉ là 1 dòng trỏ tới nguồn; chi tiết đọc ở nguồn. Pattern rút ra từ incident thật thì ghi đủ: bối cảnh / quy tắc / ví dụ sai / nguồn. Pattern phía BE (`PAT-*`): `BE:docs/knowledge/PATTERNS.md`.

| ID | Quy tắc (1 dòng) | Nguồn |
| --- | --- | --- |
| AP-THIN-CLIENT | Không tính số suất, định lượng, trend, field phụ huynh được xem ở APP; hiển thị giá trị/trạng thái BE trả (sai: đếm trẻ có mặt để hiện số suất cho bếp) | `BE:docs/system/CROSS_REPO_MAP.md`, NUT-01, ADR-0010 |
| AP-STATUS-NOT-DESC | Phân nhánh theo HTTP status (`code`), không parse `desc`; cần phân biệt lỗi cùng status ⇒ đề xuất BE bổ sung | `BE:docs/backend-coding-guide.md` §8 |
| AP-IDEMPOTENT-RETRY | Chỉ tự retry `GET` và ghi idempotent (upsert lớp/ngày); tạo/confirm/approve không retry mù, chặn double-submit | BE PAT-IDEMPOTENT-BATCH |
| AP-CONTEXT-KEYED-CACHE | Cache key gồm user + role + con/lớp/campus + ngày; đổi ngữ cảnh hủy request cũ; logout xóa cache, queue, token | thiết kế |
| AP-PUSH-AS-POINTER | Push payload = loại + ID; mở màn hình rồi tải qua API có auth; không dữ liệu nhạy cảm trong push | `BE:docs/modules/notification.md` |

## Format pattern từ incident

```markdown
## AP-<SLUG> — <tên>
- Bối cảnh / Quy tắc / Ví dụ sai
- Nguồn: APP-BUG-YYMMDD-slug | APP-CASE-... | APP-ENV-... | APP-CTR-...
```
