# CareNest Mobile — hướng dẫn cho AI coding agent

Repo này là **client Mobile** của CareNest (Trường Mầm non Thượng Hồng, Hải Phòng — **1 trường, 2 điểm trường**). Người dùng: Phụ huynh, Giáo viên, Nhân viên bếp (chức năng BGH trên app chỉ khi có yêu cầu sau). APP sở hữu màn hình, navigation, client state, tích hợp API, nhận push. **Business rule, authorization, API contract thuộc `CareNest_BE`** — repo sibling `../CareNest_BE/` hoặc https://github.com/thang-04/CareNest_BE.git.

Quy ước trong docs repo này: `BE:<path>` = file trong repo BE (vd. `BE:docs/modules/attendance.md` ⇒ `../CareNest_BE/docs/modules/attendance.md`).

## Bắt đầu mọi task

1. Phân loại task bằng `.ai/ROUTER.md` → profile, workflow, skill, mức context (L1–L4).
2. Grep từ khóa trong `.ai/CONTEXT_MAP.yaml` mục `keywords` → đọc **APP feature doc** (`docs/features/<role>/README.md`) + **BE module card** được trỏ tới. Card BE là nguồn rule; doc APP chỉ map màn hình → flow/rule.
3. Bug/lỗi/case lạ: **search `docs/knowledge/ISSUE_INDEX.md` trước** (chuỗi lỗi, màn hình, mã lỗi BE, thiết bị). Lỗi contract/nghiệp vụ: search thêm `BE:docs/knowledge/ISSUE_INDEX.md` và `BE:docs/knowledge/CROSS_MODULE_ISSUES.md`. Incident cũ là manh mối — kiểm chứng lại với code hiện tại.
4. Kết thúc: đối chiếu `docs/quality/DEFINITION_OF_DONE.md`, gồm cập nhật engineering memory.

**Tri thức mới** — user đưa nghiệp vụ mới / chốt PENDING, hoặc gặp **bug mới** / edge case ⇒ chạy `.ai/workflows/update-knowledge.md` ngay trong lượt (không đợi cuối task).

## Đọc tiết kiệm token

- **`.ai/CONTEXT_MAP.yaml`: grep, không đọc cả file** — `grep -iE "<từ khóa>" .ai/CONTEXT_MAP.yaml` để ra module/card. Chỉ mở cả file khi cần sửa map.
- **Contract BE**: chỉ đọc `BE:docs/backend-coding-guide.md` mục 7–8 khi đụng API (grep tiêu đề `^## 7\.`/`^## 8\.`); không đọc cả guide.
- **Engineering memory:** grep `docs/knowledge/ISSUE_INDEX.md` (+ `BE:docs/knowledge/ISSUE_INDEX.md` nếu lỗi contract/nghiệp vụ) theo chuỗi lỗi/từ khóa; chỉ mở `incidents/<ID>-*.md` khi dòng index khớp. Ghi mới: 1 issue = 1 dòng ngắn trong index, chi tiết để trong file incident.
- **Coding rule theo loại file** ở `.claude/rules/<tên>.md` (frontmatter `paths`). Claude tự nạp; agent khác (Codex) tự mở rule khớp file đang sửa.
- `.agents/skills/` là bản mirror của `.claude/skills/` — sửa một bên thì chép y hệt sang bên kia.
- Không đọc toàn bộ `docs/` trừ profile `full`. Mức đọc theo `.ai/ESCALATION.md`.

## Nguyên tắc bất biến

1. **BE sở hữu rule, authorization, contract.** APP chỉ trình bày dữ liệu BE trả về và hỗ trợ nhập liệu. Thiếu contract ⇒ ghi khoảng trống, đề xuất thay đổi cần thống nhất; không tự giả định endpoint/field.
2. **Không sao chép rule** tính suất ăn, dị ứng, dinh dưỡng, định lượng, sức khỏe, hiển thị phụ huynh vào APP. Validation client chỉ để hỗ trợ nhập (format, bắt buộc); BE luôn kiểm tra lại.
3. **Ẩn UI ≠ phân quyền** (BE `AUTH-07`). Mọi quyết định quyền/phạm vi (scope) do BE; APP xử lý đúng 401/403/404.
4. **Không dữ liệu trẻ thật, ảnh trẻ, token, secret** trong prompt, log, crash report, fixture, screenshot test, commit. Dùng dữ liệu giả.
5. **Push tối thiểu:** không mang dữ liệu sức khỏe/chi tiết nhạy cảm của trẻ; chỉ "có cập nhật mới" + deep link, mở app mới tải dữ liệu qua API có auth.
6. **PENDING / OPEN ⇒ hỏi** hoặc làm cấu hình được — không đoán (vd. người xác nhận số suất `P-05`, bếp theo campus `P-06`, field phụ huynh xem `P-13b`). Status: CONFIRMED / ACCEPTED / PROPOSED / PENDING / OPEN.
7. **Ghi lại bug không hiển nhiên**, kể cả các cách đã thử thất bại (`docs/knowledge/`). Lỗi contract/nghiệp vụ phát hiện ở APP ⇒ ghi ở `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` (đề xuất nội dung nếu không được sửa BE).
8. **Ngoài scope:** chat (CareNest không thay Zalo), multi-school/multi-tenant, kho/NCC (OPEN — BE ADR-0009, chưa làm), giáo án, chẩn đoán y tế. AI chỉ hỗ trợ — APP không hiển thị AI draft như kết quả chính thức.

## Stack

Mobile framework: **React Native — PROPOSED** (chưa chốt). Navigation, state/cache, HTTP client, push provider, secure storage: chưa chọn. Đọc source thực tế trước khi áp rule framework. BE: Java Spring Boot + PostgreSQL (CONFIRMED); response `{code, desc, data}` với `code` == HTTP status, prefix API cấu hình được — nguồn: `BE:docs/backend-coding-guide.md` §7–8 + source BE (APP tóm tắt ở `docs/integration/BACKEND_INTEGRATION.md`). Coding rule: `.claude/rules/` (dùng chung cho mọi agent).

## Quy tắc chung CareNest (bắt buộc)

Khối này giống nhau ở cả ba repo `CareNest_BE`, `CareNest_FE`, `CareNest_APP`; chỉ mục "Hỏi trước khi làm" và "Phạm vi" khác theo repo. Sửa ở một repo thì đồng bộ sang hai repo còn lại.

### Git — commit, push, pull request

- KHÔNG tự `git commit` / `git push` / tạo-merge-đóng PR / tạo branch khi user chưa cho phép rõ **trong tin nhắn hiện tại** (được phép một lần ≠ lần sau). Branch khi được phép: `feature/<KEY>-<mo-ta>`, `fix/<KEY>-<mo-ta>`, `chore/<mo-ta>`; làm trên branch khác `main` ⇒ hỏi trước.
- KHÔNG lệnh git phá hủy khi chưa hỏi (`reset --hard`, `push --force`, `rebase`, `branch -D`, `clean -fd`, `checkout -- .`, `restore .`, `stash drop`); KHÔNG `--no-verify`/bỏ qua hook.

### Commit message

- Conventional Commits tiếng Anh `<type>(<scope>): <subject>`, `type` ∈ `feat|fix|refactor|test|docs|chore|build|ci`; subject ≤72 ký tự, mệnh lệnh, không dấu chấm cuối; body tùy chọn ≤~5 gạch đầu dòng nói lý do/tác động (không liệt kê file, không kể quá trình). 1 commit = 1 thay đổi logic.
- **Jira:** user bảo commit mà chưa nêu task ⇒ hỏi "Thay đổi này thuộc task Jira nào (vd. `CN-123`)?". 1 commit = đúng 1 key ở footer `Refs: <KEY>`; nhiều task ⇒ tách commit; user xác nhận không có task ⇒ commit không key và nói rõ. Không đoán/bịa key.
- KHÔNG ghi tên model/công cụ AI, `Co-Authored-By` AI, "Generated with ..." trong commit, PR hay comment code (ghi đè attribution mặc định của công cụ).

```text
feat(response): add PageResponse for paginated APIs

- Avoid exposing Spring Page structure to clients

Refs: CN-123
```

### Comment trong code

- Chỉ comment ngắn (1 dòng, tối đa 2–3) ở logic chính/không hiển nhiên; nói *tại sao / quy tắc gì*, tiếng Việt, giữ identifier tiếng Anh. Không comment code tự giải thích, không Javadoc/JSDoc tràn lan.
- KHÔNG code comment-out, comment nhật ký, TODO mơ hồ (cần thì `// TODO(<người/issue>): <việc cụ thể>`), thông tin AI, dữ liệu thật/secret. Sửa code ⇒ sửa/xóa comment liên quan.

### Hỏi trước khi làm

- Thêm/xóa/nâng dependency (`package.json`, lockfile, native module) hoặc đổi version công cụ build.
- Chọn framework/thư viện nền khi team chưa chốt: navigation, state/cache, push provider, cách lưu token.
- Gọi API khác contract BE hoặc cần BE đổi contract — nêu thay đổi cần thống nhất thay vì tự giả định.

### Phạm vi

- Chỉ sửa trong phạm vi task; KHÔNG xóa/đổi tên/di chuyển file ngoài phạm vi khi chưa hỏi.
- KHÔNG sửa repo `CareNest_BE`, `CareNest_FE` trừ khi user cho phép rõ trong tin nhắn hiện tại (vd. đồng bộ tri thức theo `update-knowledge.md`).
- KHÔNG tự thêm thư viện/hạ tầng mới khi team chưa chốt.

### Giao tiếp

- Trả lời user tiếng Việt; commit, branch, identifier tiếng Anh. Yêu cầu chưa rõ ⇒ hỏi trước. Báo kết quả đúng sự thật (test fail/skip/chưa chạy phải nói rõ).
