# Issue Index — CareNest_APP

Search đầu tiên khi gặp bug, crash, lỗi build/thiết bị, case lạ trên Mobile. Grep chuỗi lỗi nguyên văn, màn hình, role, HTTP status, `Android|iOS`, từ khóa VN/EN (vd. `Network request failed`). 1 issue = 1 dòng, **kể cả bug đang mở** (`open`). Chi tiết và các cách đã thử nằm trong `incidents/<ID>.md`. Cách ghi: `.ai/workflows/update-knowledge.md` T2. Lỗi contract/nghiệp vụ: grep thêm `BE:docs/knowledge/ISSUE_INDEX.md`.

ID: `APP-BUG-` (code) · `APP-CASE-` (edge case nghiệp vụ/UX) · `APP-ENV-` (build/thiết bị/môi trường) · `APP-CTR-` (lệch contract BE), dạng `<loại>-YYMMDD-<slug>` (vd. `APP-BUG-261004-attendance-double-submit`). Status: `open` | `workaround` | `fixed`.

| ID | Màn hình/feature | Triệu chứng (từ khóa + chuỗi lỗi + thiết bị/OS) | Root cause (1 câu, `?` nếu chưa rõ) | Status |
| --- | --- | --- | --- | --- |
| APP-ENV-261008-verify-quoted-bat | harness verify | `node scripts/verify.mjs` Windows: "The system cannot find the path specified." khi gọi flutter/dart | cmd + tên `.bat` trong ngoặc kép làm `%~dp0` sai | fixed |
| APP-ENV-261008-flutter-sdk-mismatch | toolchain | Windows: Dart 3.11.5, version solving failed; SDK mới: lockfile không khớp | Đã đồng bộ 5 package và verify PASS với SDK mới; IDE/PATH mặc định còn cần chọn SDK mới | workaround |
| APP-ENV-261117-kotlin-ic-cross-drive | build Android | `flutter build apk` Windows: `:image_picker_android:compileDebugKotlin` / `:url_launcher_android:compileDebugKotlin` "Could not close incremental caches", "Daemon compilation failed" | Kotlin incremental compilation hỏng khi project (ổ D:) và Pub cache (ổ C:) khác ổ; tắt bằng `kotlin.incremental=false` | fixed |
| APP-BUG-261118-setstate-future-retry | màn có "Thử lại" (Bé của tôi, bếp Suất ăn, các màn quản lý) | debug/widget test: bấm "Thử lại" không tải lại, "setState() callback argument returned a Future." | Closure mũi tên `setState(() => _future = load())` trả Future; dùng thân khối | fixed |
| APP-BUG-261014-greeting-bell-semantics-merge | parent-home | Trình đọc màn hình: lời chào + chuông gộp một nút, mất "Thông báo, N chưa đọc" sau khi bỏ hero | `Semantics(header/button)` thiếu `container: true` nên gộp vào nút cha chung | fixed |
