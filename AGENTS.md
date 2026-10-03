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
- Không đọc toàn bộ `docs/` trừ profile `full`. Mức đọc theo `.ai/ESCALATION.md`.

## Nguyên tắc bất biến

1. **BE sở hữu rule, authorization, contract.** APP chỉ trình bày dữ liệu BE trả về và hỗ trợ nhập liệu. Thiếu contract ⇒ ghi khoảng trống, đề xuất thay đổi cần thống nhất; không tự giả định endpoint/field.
2. **Không sao chép rule** tính suất ăn, dị ứng, dinh dưỡng, định lượng, sức khỏe, hiển thị phụ huynh vào APP. Validation client chỉ để hỗ trợ nhập (format, bắt buộc); BE luôn kiểm tra lại.
3. **Ẩn UI ≠ phân quyền** (BE `AUTH-07`). Mọi quyết định quyền/phạm vi (scope) do BE; APP xử lý đúng 401/403/404.
4. **Không dữ liệu trẻ thật, ảnh trẻ, token, secret** trong prompt, log, crash report, fixture, screenshot test, commit. Dùng dữ liệu giả.
5. **Push tối thiểu:** không mang dữ liệu sức khỏe/chi tiết nhạy cảm của trẻ; chỉ "có cập nhật mới" + deep link, mở app mới tải dữ liệu qua API có auth.
6. **PENDING / OPEN ⇒ hỏi** hoặc làm cấu hình được — không đoán (vd. người tạo đơn nghỉ `P-15`, bếp theo campus `P-06`, field phụ huynh xem `P-13b`). Status: CONFIRMED / ACCEPTED / PROPOSED / PENDING / OPEN.
7. **Ghi lại bug không hiển nhiên**, kể cả các cách đã thử thất bại (`docs/knowledge/`). Lỗi contract/nghiệp vụ phát hiện ở APP ⇒ ghi ở BE `docs/knowledge/CROSS_MODULE_ISSUES.md` (đề xuất nội dung nếu không được sửa BE).
8. **Ngoài scope:** chat (CareNest không thay Zalo), multi-school/multi-tenant, kho/NCC, giáo án, chẩn đoán y tế. AI chỉ hỗ trợ — APP không hiển thị AI draft như kết quả chính thức.

## Stack

Mobile framework: **React Native — PROPOSED** (chưa chốt). Navigation, state/cache, HTTP client, push provider, secure storage: chưa chọn. Đọc source thực tế trước khi áp rule framework. BE: Java Spring Boot + PostgreSQL (CONFIRMED); response `{code, desc, data}` với `code` == HTTP status, prefix API cấu hình được — nguồn: `BE:docs/backend-coding-guide.md` §7–8 + source BE (APP tóm tắt ở `docs/integration/BACKEND_INTEGRATION.md`). Coding rule: `.claude/rules/` (dùng chung cho mọi agent).

## Git, commit và comment (bắt buộc)

Bản đầy đủ (đồng bộ BE/FE/APP): `CLAUDE.md` mục "Quy tắc chung CareNest" — Claude tự nạp; **Codex phải đọc mục đó trước khi chạy lệnh git hoặc commit.** Tối thiểu:

- Không tự commit/push/tạo-merge PR khi user chưa cho phép rõ trong tin nhắn hiện tại; không tự tạo branch mới khi chưa được cho phép (hỏi trước); không lệnh git phá hủy hay `--no-verify` khi chưa hỏi.
- Conventional Commits tiếng Anh, footer `Refs: <JIRA-KEY>` (chưa có key ⇒ hỏi, không bịa); không ghi tên/attribution công cụ AI.
- Hỏi trước khi đổi dependency, contract hoặc thứ ảnh hưởng cả nhóm; không sửa repo CareNest khác. Trả lời user bằng tiếng Việt.
