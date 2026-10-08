# Issue Index — CareNest_APP

Search đầu tiên khi gặp bug, crash, lỗi build/thiết bị, case lạ trên Mobile. Grep chuỗi lỗi nguyên văn, màn hình, role, HTTP status, `Android|iOS`, từ khóa VN/EN (vd. `Network request failed`). 1 issue = 1 dòng, **kể cả bug đang mở** (`open`). Chi tiết và các cách đã thử nằm trong `incidents/<ID>.md`. Cách ghi: `.ai/workflows/update-knowledge.md` T2. Lỗi contract/nghiệp vụ: grep thêm `BE:docs/knowledge/ISSUE_INDEX.md`.

ID: `APP-BUG-` (code) · `APP-CASE-` (edge case nghiệp vụ/UX) · `APP-ENV-` (build/thiết bị/môi trường) · `APP-CTR-` (lệch contract BE), dạng `<loại>-YYMMDD-<slug>` (vd. `APP-BUG-261004-attendance-double-submit`). Status: `open` | `workaround` | `fixed`.

| ID | Màn hình/feature | Triệu chứng (từ khóa + chuỗi lỗi + thiết bị/OS) | Root cause (1 câu, `?` nếu chưa rõ) | Status |
| --- | --- | --- | --- | --- |
| APP-ENV-261008-verify-quoted-bat | harness verify | `node scripts/verify.mjs` Windows: "The system cannot find the path specified." khi gọi flutter/dart | cmd + tên `.bat` trong ngoặc kép làm `%~dp0` sai | fixed |
