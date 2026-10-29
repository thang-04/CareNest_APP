# Features — map màn hình Mobile → BE

Mỗi role 1 file. File **chỉ map** màn hình → BE flow / module card / rule ID + mục PENDING + Known pitfalls phía APP. **Không chép rule** — đọc rule ở BE.

`BE:<path>` = `../CareNest_BE/<path>` hoặc https://github.com/thang-04/CareNest_BE.git.

| Role | File | BE module chính |
| --- | --- | --- |
| Parent | [parent/README.md](parent/README.md) | child, attendance, nutrition, health, learning-observation (đọc theo PAR-*) |
| Teacher | [teacher/README.md](teacher/README.md) | attendance (gồm đón trẻ), learning-observation, health |
| Kitchen Staff | [kitchen/README.md](kitchen/README.md) | nutrition (số suất dị ứng không tên trẻ — AUTH-05, NUT-23) |
| Vice Principal — ngoài phạm vi App (AUTH-21), tham khảo | [vice-principal/README.md](vice-principal/README.md) | nutrition, attendance, child, learning-observation (scope campus) |
| Principal — ngoài phạm vi App (AUTH-21), tham khảo | [principal/README.md](principal/README.md) | school-structure, child, nutrition, learning-observation (toàn trường) |

App chỉ cho Phụ huynh, Giáo viên, Bếp; Ban giám hiệu chỉ dùng Web (`BE:` AUTH-21, user chốt 27/10). Màn lệch rule BE chốt 28/10, 29/10 ghi "Lệch BE (28/10)", "Lệch BE (29/10)" trong file của role — cần sửa khi tích hợp. Từ 29/10: App tập trung cho phụ huynh và GV (điểm danh, sức khỏe, đánh giá, đón trẻ, thông báo); bếp giữ màn tối thiểu (AUTH-21).

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
