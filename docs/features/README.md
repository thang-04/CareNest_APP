# Features — map màn hình Mobile → BE

Mỗi role 1 file. File **chỉ map** màn hình → BE flow / module card / rule ID + mục PENDING + Known pitfalls phía APP. **Không chép rule** — đọc rule ở BE.

`BE:<path>` = `../CareNest_BE/<path>` hoặc https://github.com/thang-04/CareNest_BE.git.

| Role | File | BE module chính |
| --- | --- | --- |
| Parent | [parent/README.md](parent/README.md) | child, attendance, nutrition, health, learning-observation (đọc theo PAR-*) |
| Teacher | [teacher/README.md](teacher/README.md) | attendance, learning-observation, facility-issue, health |
| Kitchen Staff | [kitchen/README.md](kitchen/README.md) | nutrition, child (dị ứng) |

## Nguồn BE dùng chung

| Cần | Đọc |
| --- | --- |
| Rule có ID + status, Pending register | `BE:docs/business/BUSINESS_RULES.md` (chỉ nhóm liên quan) |
| Role, scope, permission | `BE:docs/business/USER_ROLES.md` |
| Hiển thị phụ huynh | `BE:docs/decisions/ADR-0010-parent-visibility-policy.md` |
| Ownership BE/FE/APP | `BE:docs/system/CROSS_REPO_MAP.md` |
| Endpoint/response | OpenAPI BE + `BE:docs/backend-coding-guide.md` §7–8 |

## AI trong APP
AI output là DRAFT ở BE (AI-01, AI-02). APP **không** hiển thị DRAFT cho phụ huynh/bếp như kết quả chính thức; chỉ hiển thị nội dung đã được người có quyền duyệt. AI tắt/lỗi (503/504) ⇒ màn hình vẫn dùng được với luồng không AI (AI-03).

## Template mục màn hình

```markdown
### <Nhóm màn hình>
- Mục đích: 1 dòng
- BE: card `BE:docs/modules/<x>.md` · flow `BE:docs/business/flows/<y>.md` · rule <ID, ...>
- Endpoint: <path hoặc "chưa có">
- PENDING: <P-xx — ảnh hưởng UI gì>
- Known pitfalls: <1 dòng/bẫy, link incident>
```
