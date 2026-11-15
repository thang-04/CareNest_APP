---
title: Cổng kiểm thiết kế App trong verify
status: done
owner: CareNest APP team
jira: G94-379 / FE-FEAT-58
branch: dev
modules: []
rules: []
risk: medium
created: 2026-11-15
updated: 2026-11-15
---
# Cổng kiểm thiết kế App trong verify

## Context
- `DESIGN.md` hai phần đã nối (plan `docs/plans/completed/2026-11-15-design-system-sync-web.md`). AI layer, skill và PR template đã trỏ tới nó, nhưng **không có gì chặn tự động**: `scripts/verify.mjs:99-103` chỉ chạy format → analyze → test.
- Web đã có cổng: `CareNest_FE/scripts/check-design.mjs` đếm vi phạm theo file, so với `scripts/design-baseline.json`; file vượt baseline hoặc file mới có vi phạm ⇒ fail; `--update` chỉ hạ baseline. FE verify gọi nó qua `check:design`.
- Nợ App hiện tại (lệnh A §13.2, 2026-11-15): màu ngoài token 2 · `fontSize/fontWeight` ở feature 33 · số tay trong `BorderRadius/EdgeInsets/SizedBox` 38 · `Icons.*` ở feature 126 · `BackdropFilter` 0 · widget Material thô 7.
- `scripts/verify.mjs` của APP khác bản BE/FE (không nằm trong file đồng bộ chung) ⇒ sửa trong APP được.

## Quyết định đã chốt
1. Làm cổng tự động kiểu baseline như web: nợ cũ ghi nhận, code mới không được thêm vi phạm — user, 2026-11-15.
2. Trả nợ hiện tại để đợt sau, không trong plan này — user, 2026-11-15.

### Câu hỏi mở
- [x] User duyệt plan 2026-11-15.

## Acceptance criteria
- **AC-1:** `node scripts/check-design.mjs` đếm 6 luật A §13.2 theo file trong `lib/`; so `scripts/design-baseline.json`; vượt baseline hoặc file mới có vi phạm ⇒ exit 1, in file + luật + số.
- **AC-2:** `--update` ghi baseline khi số giảm; từ chối nâng số hoặc thêm file mới.
- **AC-3:** `node scripts/verify.mjs` chạy bước `design` sau `format`, dòng tóm tắt có `design ok|FAIL`; fail ⇒ `VERIFY FAIL`.
- **AC-4:** Baseline ban đầu = nợ hiện tại ⇒ verify trên `dev` PASS.
- **AC-5:** Thêm `Icons.add` vào một màn feature (thử, không commit) ⇒ verify FAIL đúng file và luật.
- **AC-6:** `DESIGN.md` §B8 ghi lệnh + cách hạ baseline.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Cách chặn | Baseline đếm theo file (port FE) | Fail toàn bộ ngay; chỉ cảnh báo | Fail ngay chặn mọi PR (206 chỗ nợ); cảnh báo thì bị lờ |
| Vị trí | Bước trong `verify.mjs` (Node, không cần Flutter) | `custom_lint` Dart | Không thêm dependency; giống web; chạy ở pre-push/hook sẵn có |
| Luật | Đúng 6 lệnh A §13.2 | Thêm luật mới | Phần A là nguồn chung; luật mới ⇒ sửa Design System trước |

## Phases
### Phase 1 — Checker + baseline
- Files: C `scripts/check-design.mjs` · C `scripts/design-baseline.json` · C `scripts/__tests__/check-design.test.mjs`
- Steps: 1. Port cấu trúc FE (`CHECKS`, đếm theo file, so baseline, `--update` chỉ hạ). 2. Luật Dart: `hex` (`Color(0x`, `Colors.<màu>` ngoài `core/constants/{colors,sizes,shadows}.dart`), `textStyle` (`fontSize:`/`fontWeight:` trong `lib/features`), `rawNumber` (`BorderRadius.circular([1-9]`, `EdgeInsets.*([^)]*[1-9]`, `SizedBox(width|height: [1-9]` trong `lib/features`), `icon` (`Icons.`/`TablerIcons.` trong `lib/features`), `blur` (`BackdropFilter` ngoài widget hero), `rawWidget` (`ElevatedButton(`, `AlertDialog(`, `SnackBar(`, `ListTile(`, `CircleAvatar(` trong `lib/features`). 3. Sinh baseline từ hiện trạng.
- Tests: AC-1, AC-2 bằng `node --test` với thư mục tạm.
- Exit: `node --test scripts/__tests__/check-design.test.mjs` pass.

### Phase 2 — Gắn vào verify + docs
- Files: M `scripts/verify.mjs` · M `scripts/__tests__/verify.test.mjs` · M `DESIGN.md` (§B8, Phần B)
- Steps: thêm bước `design` (node, sau format); parse output; thêm cột tóm tắt; test parse. Ghi §B8.
- Tests: AC-3, AC-4, AC-5 (thử tay rồi hoàn tác).
- Exit: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests … fail 0 skip 0`.
- **Dừng chờ user review.**

## Test matrix
| AC | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- |
| AC-1, AC-2 | `check-design.test.mjs` (node) | 1 | |
| AC-3 | `verify.test.mjs` (node) | 2 | |
| AC-4, AC-5 | chạy verify thật | 2 | |
| AC-6 | đọc §B8 | 2 | |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Regex bắt nhầm (comment, chuỗi) | Fail oan | Bỏ dòng comment `//`; baseline theo file nên chỉ file đang sửa bị ảnh hưởng | Sửa regex |
| Người nâng baseline tay để qua cổng | Mất tác dụng | `--update` từ chối nâng; baseline đổi hiện trong diff PR, review thấy | — |
| Bước design làm verify chậm | Nhỏ (đọc file, không build) | — | Bỏ bước trong `FLUTTER_STEPS` |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Không đổi contract BE
- [x] Mỗi AC có test; mỗi phase có Exit
- [x] 6 file, 2 phase
- [x] Không dùng rule PENDING/OPEN
- [x] Tự review: không placeholder · không mâu thuẫn

## Progress log
### 2026-11-15 — Phase 1–2 (done)
- User duyệt 2026-11-15, làm luôn cả hai phase.
- Phase 1: `scripts/check-design.mjs` (6 luật A §13.2, bỏ dòng comment, `--update` chỉ hạ), `scripts/design-baseline.json` (hex 2 · textStyle 33 · rawNumber 60 · icon 0 · blur 0 · rawWidget 7), `scripts/__tests__/check-design.test.mjs` 3 test.
- Phase 2: `scripts/verify.mjs` thêm bước `design` sau `format` + cột tóm tắt; `scripts/__tests__/verify.test.mjs` thêm test parse; `DESIGN.md` §B8.
- Khác plan: nợ `Icons.*` thật = 0. Con số 126 trước đó do grep khớp cả `AppIcons.`; regex `\bIcons\.` loại trường hợp này.
- AC-5: thêm `Icons.add` vào `account_screen.dart` ⇒ `VERIFY FAIL full | format ok | design FAIL | …` đúng file/luật; đã hoàn tác.
- Test script: `node --test scripts/__tests__/*.test.mjs` → 61 pass, 0 fail.
