# Verification — bằng chứng trước khi báo xong (APP)

## Iron Law
Không nói "xong / pass / đã sửa" khi chưa có **output lệnh chạy trong lượt này, sau lần sửa cuối**. Suy luận, kết quả lượt trước không phải bằng chứng. **Skip hoặc chưa chạy = chưa kiểm chứng** — báo đúng (`Verify: chưa chạy — <lý do>`).

Lệnh chuẩn: `node scripts/verify.mjs`. Repo Flutter (có `pubspec.yaml`): kiểm format Dart, `flutter analyze`, `flutter test`; repo Node (có `package.json`): `npm run verify`; chưa có code ⇒ `VERIFY SKIP`. Output tóm tắt, log ở `verify.log`.

## Bằng chứng
| Claim | Bằng chứng |
| --- | --- |
| Xong (khi có code) | Dòng `VERIFY PASS …` trong lượt |
| Bug đã sửa | Output test **fail trước fix** + **pass sau fix** (chưa có test runner ⇒ bước kiểm tay ghi rõ, emulator/máy thật) |
| Khớp contract BE | Đối chiếu `BE:docs/api/openapi.yaml` (snapshot BE khóa bằng test) + source DTO BE, dẫn `file:line` |
| Chạy trên emulator/máy thật | Bước + kết quả `x/y`, môi trường (BE thật hay mock) |
| AI layer nhất quán | `node scripts/check-ai-layer.mjs` exit 0 |

## Báo cáo cuối task
```text
Làn S (≤3 dòng):  Đã làm: … · Verify: <dòng VERIFY | chưa chạy — lý do> · Memory: <chỉ khi có trigger>
Làn M (≤8 dòng):  Đã làm · Rule/AC · Verify · Chưa kiểm chứng (emulator/máy thật, BE thật) · Chờ BE · Memory
Làn L:            ghi đủ vào Progress log của plan; chat chỉ tóm tắt + link plan
```


## 2026-10-08 — Đồng bộ Flutter SDK và lockfile
- Làn L; user duyệt cập nhật lockfile trên dev.
- Môi trường kiểm tra: Windows 11, Flutter 3.47.6 / Dart 3.13.5, PATH của tiến trình chọn D:\Flutter_Setup\stable-3.47.6\flutter\bin.
- Dependency đã đổi đúng 5 package: intl 0.20.3, matcher 0.12.20, meta 1.19.0, test_api 0.7.12, vector_math 2.4.3. pubspec.yaml, lib/ và test/ không đổi.
- Flutter tự bổ sung analyzer.exclude cho thư mục build và nền tảng sinh tự động.
- Trước sửa: VERIFY FAIL full | format ok | analyze FAIL | tests - | 7s | log verify.log. SDK mới với lockfile cũ: enforce-lockfile exit 65.
- Sau sửa: node scripts/verify.mjs → VERIFY PASS full | format ok | analyze ok | tests 27 fail 0 skip 0 | 47s | log verify.log.
- flutter pub get --enforce-lockfile → exit 0, lockfile giữ nguyên; git diff --check → exit 0.
- node scripts/check-ai-layer.mjs → exit 0: 0 lỗi, 4 cảnh báo E7 về glob data/offline/controllers/providers chưa có file.
- Chưa kiểm chứng: build Android/iOS, emulator/máy thật, API BE, cấu hình SDK trong IDE và PATH mặc định. Android còn license chưa chấp nhận.
- Plan: docs/plans/completed/2026-10-08-flutter-sdk-3-47-6.md.