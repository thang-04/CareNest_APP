# Issue Index — CareNest_APP

Search đầu tiên khi gặp bug, crash, lỗi build/thiết bị, case lạ trên Mobile. Grep chuỗi lỗi nguyên văn, màn hình, role, HTTP status, `Android|iOS`, từ khóa VN/EN (vd. `Network request failed`). 1 issue = 1 dòng, **kể cả bug đang mở** (`open`). Chi tiết và các cách đã thử nằm trong `incidents/<ID>.md`. Cách ghi: `.ai/workflows/update-knowledge.md` T2. Lỗi contract/nghiệp vụ: grep thêm `BE:docs/knowledge/ISSUE_INDEX.md`.

ID: `APP-BUG-` (code) · `APP-CASE-` (edge case nghiệp vụ/UX) · `APP-ENV-` (build/thiết bị/môi trường) · `APP-CTR-` (lệch contract BE), dạng `<loại>-YYMMDD-<slug>` (vd. `APP-BUG-261004-attendance-double-submit`). Status: `open` | `workaround` | `fixed`.

| ID | Màn hình/feature | Triệu chứng (từ khóa + chuỗi lỗi + thiết bị/OS) | Root cause (1 câu, `?` nếu chưa rõ) | Status |
| --- | --- | --- | --- | --- |
| APP-ENV-261008-verify-quoted-bat | harness verify | `node scripts/verify.mjs` Windows: "The system cannot find the path specified." khi gọi flutter/dart | cmd + tên `.bat` trong ngoặc kép làm `%~dp0` sai | fixed |
| APP-ENV-261008-flutter-sdk-mismatch | toolchain | Windows: Dart 3.11.5, version solving failed; SDK mới: lockfile không khớp; 15/11: PATH chọn Flutter 3.44.0, enforce-lockfile exit 65 nhưng verify vẫn PASS | 10/08 đồng bộ 5 package với Flutter 3.47.6; 15/11 cài lại 3.47.6, enforce-lockfile và verify PASS qua PATH tiến trình; PATH mặc định/IDE còn 3.44.0 | workaround |
| APP-BUG-261014-greeting-bell-semantics-merge | parent-home | Trình đọc màn hình: lời chào + chuông gộp một nút, mất "Thông báo, N chưa đọc" sau khi bỏ hero | `Semantics(header/button)` thiếu `container: true` nên gộp vào nút cha chung | fixed |
