---
id: APP-ENV-261008-verify-quoted-bat
type: env
roles: [all]
screens: [harness-verify]
platforms: [both]
be_refs: []
status: fixed
date: 2026-10-08
keywords: [verify, windows, cmd, flutter.bat, dart.bat, "%~dp0", spawn, shell]
similar_to: []
---

# APP-ENV-261008-verify-quoted-bat — verify.mjs gọi flutter/dart trên Windows báo "cannot find the path"

## Symptom
`node scripts/verify.mjs` in `VERIFY FAIL full | format FAIL | analyze - | tests - | 0s`; `verify.log` chỉ có:
```text
The system cannot find the path specified.
```

## Điều kiện tái hiện
Windows 11, Flutter 3.44.0 / Dart 3.12.0 cài ở thư mục người dùng, `flutter`/`dart` có trên PATH dưới dạng `.bat`. Node `spawn(cmd, { shell: true })` với tên lệnh được bọc ngoặc kép.

## Attempts — đã thử (cập nhật mỗi phiên điều tra, để phiên sau không lặp lại)
| # | Cách thử | Kết quả | Vì sao không đúng / bài học |
| --- | --- | --- | --- |
| 1 | `"dart" --version` qua `spawnSync(..., { shell: true })` | Lỗi "cannot find the path" | Quote tên `.bat` không kèm đường dẫn |
| 2 | `"dart.bat" --version` / `"flutter.bat" --version` | Vẫn lỗi; flutter báo "not a clone of the GitHub project" | Thêm đuôi `.bat` không đủ, vẫn quote |
| 3 | `dart --version` không quote | Chạy đúng | — |

## Root cause
Thiết bị-môi trường: `cmd` chạy batch file được gọi bằng tên có ngoặc kép (tìm qua PATH) thì `%~dp0` trong `flutter.bat`/`dart.bat` trỏ sai thư mục. `scripts/verify.mjs` (`runToLog`) luôn bọc `exe` trong ngoặc kép.

## Fix
`scripts/verify.mjs` `runToLog`: chỉ quote `exe` khi đường dẫn có khoảng trắng. Nhánh Maven dùng đường dẫn tuyệt đối tới `mvnw.cmd`, không bị ảnh hưởng.

## Regression test
Kiểm tra tay: `node scripts/verify.mjs` trên Windows ⇒ `VERIFY PASS full | format ok | analyze ok | tests 1 fail 0 skip 0`. Chưa có test tự động (cần môi trường Windows + Flutter).

## Ảnh hưởng
`scripts/verify.mjs` là file dùng chung 3 repo; khi đồng bộ sang BE/FE mang theo fix này.

## Lesson
Trên Windows, không quote tên lệnh `.bat` tìm qua PATH khi spawn với `shell: true`; chỉ quote đường dẫn có khoảng trắng.
