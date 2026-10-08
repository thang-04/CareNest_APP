# CareNest Mobile — hướng dẫn cho AI coding agent

Repo này là **client Mobile** của CareNest (Trường Mầm non Thượng Hồng, Hải Phòng — **1 trường, 2 điểm trường**). Người dùng: Phụ huynh, Giáo viên, Nhân viên bếp (chức năng BGH trên app chỉ khi có yêu cầu sau). APP sở hữu màn hình, navigation, client state, tích hợp API, nhận push. **Business rule, authorization, API contract thuộc `CareNest_BE`** — repo sibling `../CareNest_BE/` hoặc https://github.com/thang-04/CareNest_BE.git.

Quy ước trong docs repo này: `BE:<path>` = file trong repo BE (vd. `BE:docs/modules/attendance.md` ⇒ `../CareNest_BE/docs/modules/attendance.md`).

## Bắt đầu mọi task — chọn làn

| Làn | Khi nào | Đọc | Plan · verify · báo cáo |
| --- | --- | --- | --- |
| **S** | ≤2 file, 1 màn hình, việc rõ, ngoài vùng rủi ro | File đích + test; bug: grep `ISSUE_INDEX.md` (+ BE nếu lỗi contract) | Không plan · `node scripts/verify.mjs` · ≤3 dòng |
| **M** | 3–8 file; màn hình/hành vi trong 1 nhóm | `.ai/ROUTER.md` → grep `.ai/CONTEXT_MAP.yaml` → feature doc theo role + BE card | Mini-plan chat · verify · ≤8 dòng |
| **L** | Thư viện nền, auth/token, API client chung, điều hướng theo role, dependency, ≥2 nhóm màn hình, đổi contract BE, >8 file | + `.ai/ESCALATION.md` L3–L4 | Plan `.ai/workflows/plan-change.md` user duyệt · Progress log |

- Đổi nghiệp vụ/thứ người dùng thấy ⇒ `.ai/workflows/clarify-business.md` trước khi code. Vượt tiêu chí ⇒ nâng làn, không hạ làn.
- Plan `docs/plans/active/` khớp branch ⇒ đọc Progress log cuối trước.
- Grep, không đọc cả file: CONTEXT_MAP, ISSUE_INDEX, BE guide mục 7–8.
- `.claude/rules/` theo file (Codex tự mở); `.agents/skills/` = mirror `.claude/skills/`.
- Báo xong: `docs/quality/VERIFICATION.md` + DoD theo làn.

## Nguyên tắc bất biến

1. **BE sở hữu rule, authorization, contract.** APP chỉ trình bày dữ liệu BE trả về và hỗ trợ nhập liệu. Thiếu contract ⇒ ghi khoảng trống, đề xuất thay đổi cần thống nhất; không tự giả định endpoint/field.
2. **Không sao chép rule** tính suất ăn, dị ứng, dinh dưỡng, định lượng, sức khỏe, hiển thị phụ huynh vào APP. Validation client chỉ để hỗ trợ nhập (format, bắt buộc); BE luôn kiểm tra lại.
3. **Ẩn UI ≠ phân quyền** (BE `AUTH-07`). Mọi quyết định quyền/phạm vi (scope) do BE; APP xử lý đúng 401/403/404.
4. **Không dữ liệu trẻ thật, ảnh trẻ, token, secret** trong prompt, log, crash report, fixture, screenshot test, commit. Dùng dữ liệu giả.
5. **Push tối thiểu:** không mang dữ liệu sức khỏe/chi tiết nhạy cảm của trẻ; chỉ "có cập nhật mới" + deep link, mở app mới tải dữ liệu qua API có auth.
6. **Chưa rõ / PENDING / OPEN / lệch tài liệu ⇒ hỏi user tới khi rõ**; cấu hình được chỉ khi user nói chưa chốt (vd. người xác nhận số suất `P-05`, bếp theo campus `P-06`, field phụ huynh xem `P-13b`). Status: CONFIRMED / ACCEPTED / PROPOSED / PENDING / OPEN.
7. **Tri thức mới, bug không hiển nhiên** (kể cả cách thử thất bại) ⇒ `.ai/workflows/update-knowledge.md` ngay trong lượt; lỗi contract/nghiệp vụ ⇒ đề xuất ghi `BE:docs/knowledge/CROSS_MODULE_ISSUES.md`.
8. **Ngoài scope:** chat (CareNest không thay Zalo), multi-school/multi-tenant, kho/NCC (OPEN — BE ADR-0009, chưa làm), giáo án, chẩn đoán y tế. AI chỉ hỗ trợ — APP không hiển thị AI draft như kết quả chính thức.

## Stack

Mobile framework: **Flutter — CONFIRMED** (user, 2026-10-08); package `carenest_app`, quy chuẩn UI/kiến trúc ở `DESIGN.md` (Feature-based + Clean Architecture). Navigation: `go_router` (CONFIRMED). State/cache, HTTP client, push provider, secure storage: chưa chọn (DESIGN đề xuất Riverpod, Dio, flutter_secure_storage — PROPOSED, hỏi trước khi thêm). BE: Java Spring Boot + PostgreSQL (CONFIRMED); response `{code, desc, data}` với `code` == HTTP status, prefix API cấu hình được — nguồn: `BE:docs/backend-coding-guide.md` §7–8 + source BE (APP tóm tắt ở `docs/integration/BACKEND_INTEGRATION.md`).

## Quy tắc chung CareNest (bắt buộc)

Khối này giống nhau ở cả ba repo `CareNest_BE`, `CareNest_FE`, `CareNest_APP`; chỉ mục "Hỏi trước khi làm" và "Phạm vi" khác theo repo. Sửa ở một repo thì đồng bộ sang hai repo còn lại.

### Git — nhánh và mã công việc

- Repo GitHub riêng tư, chỉ thành viên được cấp quyền. Nhánh: `main` = bản phát hành đã duyệt; `dev` = tích hợp; `release/*` = kiểm thử bản phát hành và sửa lỗi; mỗi task Jira làm trên 1 nhánh riêng, tạo từ `dev`.
- **Mã công việc:** mỗi việc có 1 task Jira với 2 định danh — mã Jira (vd. `G94-181`, để Jira gắn nhánh/commit/PR vào task) và mã công việc trong tên task = loại + số thứ tự (vd. `FE-FEAT-44`, để nhìn là biết loại việc). Loại: `FE-FEAT` (tính năng giao diện web/app), `BE-FEAT` (tính năng back-end), `FE-FIX`, `BE-FIX` (sửa lỗi). Số thứ tự tăng dần theo từng loại, không dùng lại. `CareNest_BE` dùng `BE-*`; `CareNest_FE`, `CareNest_APP` dùng `FE-*`.
- **Tên nhánh:** `<tiền-tố>/<mã-jira>-<mã-công-việc>-<tên-luồng>`; tiền tố `feature` cho `FE-FEAT`/`BE-FEAT`, `fix` cho `FE-FIX`/`BE-FIX`; tên luồng = tên ngắn của luồng nghiệp vụ, chữ thường, nối bằng `-`, lập trình viên chọn. Vd. `feature/G94-181-FE-FEAT-44-lesson-plan`, `fix/G94-190-BE-FIX-03-meal-count-validation`. Không dùng `[` `]` trong tên nhánh (Git không chấp nhận).
- KHÔNG tự `git commit` / `git push` / tạo-merge-đóng PR / tạo branch khi user chưa cho phép rõ **trong tin nhắn hiện tại** (được phép một lần ≠ lần sau). Cần commit mà đang ở `main`/`dev`/`release/*` hoặc nhánh sai định dạng ⇒ hỏi user dùng nhánh nào, không tự tạo.
- Cấm push trực tiếp lên `main`. KHÔNG lệnh git phá hủy khi chưa hỏi (`reset --hard`, `push --force`, `rebase`, `branch -D`, `clean -fd`, `checkout -- .`, `restore .`, `stash drop`); KHÔNG `--no-verify`/bỏ qua hook.

### Commit message

- Dòng đầu: `[<mã-công-việc>] <mã-jira>: <mô tả ngắn>` — mô tả tiếng Anh, mệnh lệnh, không dấu chấm cuối; cả dòng ≤72 ký tự. Body tùy chọn (cách 1 dòng trống) ≤~5 gạch đầu dòng nói lý do/tác động (không liệt kê file, không kể quá trình). 1 commit = 1 thay đổi logic.
- Mỗi commit chỉ thuộc 1 task; nhiều task ⇒ tách commit. Task cha dạng `[Module-NN]` không dùng để commit — dùng mã công việc của task con `FE-FEAT`/`BE-FEAT`.
- **User bảo commit/tạo PR:** (1) mã lấy từ tên nhánh nếu đúng định dạng (hook đầu phiên nêu sẵn); (2) nhánh không có mã và user chưa nêu ⇒ hỏi "Thay đổi này thuộc task Jira nào (mã Jira + mã công việc, vd. `G94-181` / `FE-FEAT-44`)?" rồi dừng chờ trả lời; (3) mã user nêu khác mã nhánh ⇒ hỏi lại. Không đoán/bịa mã; việc chưa có task ⇒ đề nghị tạo task trước khi commit. Claude hook chặn commit/PR sai định dạng, lệch mã nhánh hoặc PR không vào `dev`; git hook chặn message sai định dạng.
- KHÔNG ghi tên model/công cụ AI, `Co-Authored-By` AI, "Generated with ..." trong commit, PR hay comment code (ghi đè attribution mặc định của công cụ).

```text
[FE-FEAT-44] G94-181: complete half of the lesson plan UI
[BE-FIX-03] G94-190: correct meal-count validation
```

### Pull request

- Tiêu đề PR cùng định dạng commit: `[<mã-công-việc>] <mã-jira>: <mô tả ngắn>`. Mô tả PR gồm: link task Jira, các thay đổi, phần kiểm thử đã làm (lệnh + kết quả thật; chưa chạy ⇒ ghi rõ).
- PR của nhánh task gộp vào `dev`. Chỉ nhánh `release/*` được gộp vào `main`. Nhóm kiểm tra cài đặt bảo vệ nhánh và ghi lại giới hạn thực tế nếu có.
- Điều kiện gộp: ≥1 thành viên khác tác giả duyệt, mọi kiểm tra bắt buộc đạt, mọi góp ý chặn đã xử lý.

### Thông tin nhạy cảm

- KHÔNG commit thông tin nhạy cảm (secret, token, mật khẩu, khóa, thông tin xác thực, dữ liệu thật). Repo chỉ chứa mẫu cấu hình không nhạy cảm (vd. `.env.example`); thông tin xác thực thật quản lý qua cấu hình môi trường có kiểm soát truy cập hoặc dịch vụ lưu trữ bí mật.

### Comment trong code

- Chỉ comment ngắn (1 dòng, tối đa 2–3) ở logic chính/không hiển nhiên; nói *tại sao / quy tắc gì*, tiếng Việt, giữ identifier tiếng Anh. Không comment code tự giải thích, không Javadoc/JSDoc tràn lan.
- KHÔNG code comment-out, comment nhật ký, TODO mơ hồ (cần thì `// TODO(<người/issue>): <việc cụ thể>`), thông tin AI, dữ liệu thật/secret. Sửa code ⇒ sửa/xóa comment liên quan.

### Cổng chất lượng

- **Iron Law:** chưa có output `node scripts/verify.mjs` chạy sau lần sửa cuối ⇒ không báo "xong/pass/đã sửa"; skip = chưa kiểm chứng (`docs/quality/VERIFICATION.md`).
- Làn L ⇒ plan user duyệt mới code. Sửa bug thất bại 3 lần ⇒ dừng, ghi Attempts, hỏi.
- Sửa `.ai/ .claude/ .agents/ docs/` ⇒ `node scripts/check-ai-layer.mjs`. Cổng fail ⇒ sửa nguyên nhân, không lách.

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
