---
title: Đồng bộ DESIGN.md của App với Design System web 3.4
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
# Đồng bộ DESIGN.md của App với Design System web 3.4

## Context
- Web `CareNest_FE` (origin/dev) giữ bản gốc **CareNest Design System — web + app v3.4 (2026-11-04)**. Theo Phụ lục A của bản gốc, app chép nguyên file này thành `DESIGN.md` và tách phần code sang `docs/architecture/CODING_GUIDE.md`. Việc này chưa làm: mục 15 #8 của bản gốc ghi "Chưa nối".
- App `DESIGN.md` hiện là "Design & Coding Guide 2.0", đồng bộ theo DS **3.1** (`DESIGN.md:5-6`), dài 1343 dòng, gộp UI với code/auth/API/push (mục 1–2, 10–12, 15–16).
- Từ 3.1 đến 3.4 app còn thiếu: thang bo góc gọn của web (ghi chú 3.2–3.3), dòng "Mức BMI theo tuổi" trong bảng map badge (3.4).
- Token trong code đã khớp màu và tông 3.x: `lib/core/constants/colors.dart:7-40`, `lib/core/theme/app_status_colors.dart:6`. Bo góc app vẫn theo style Clay: `lib/core/constants/sizes.dart:27-37` (card 28, nút pill).
- Có 36 comment `DESIGN.md §x.y` trong `lib/` theo số mục của guide cũ (§1.2–§8.5).
- Bản gốc tự mâu thuẫn: mục 1.3 ghi bo card web 32 / app 24, còn mục 3.6 ghi web 3xl = 20.

## Quyết định đã chốt
1. Ngôn ngữ thiết kế (màu, font, icon, badge, chuyển động, câu chữ) giống web; bố cục app là của app (khung, công thức màn, Clay) — user, 2026-11-15.
2. `DESIGN.md` app gồm hai phần: **Phần A** là DS chung chép nguyên từ web, không sửa tay; **Phần B** là phần riêng App do APP sở hữu. Code tách sang `docs/architecture/CODING_GUIDE.md` — user, 2026-11-15.
3. Bo góc: app giữ pill (nút/ô nhập) và card 28 (Clay), ghi là điểm "được khác" ở Phần B; không đổi code token — user, 2026-11-15.
4. Phạm vi: docs, AI layer và đánh số lại 36 comment `§` trong `lib/`; không sửa repo FE — user, 2026-11-15.

## Làm rõ nghiệp vụ
- Không đổi nghiệp vụ, quyền hay contract BE; chỉ đổi tài liệu và comment. Không có màn hình nào đổi hành vi.
- Ảnh hưởng: người và AI code APP đọc DESIGN.md mới. Comment trong `lib/core/**` thuộc vùng dùng chung (cần in bản tác động trước khi sửa).

### Câu hỏi mở
- [x] Mã Jira: không cần; làm thẳng trên `dev` — user 2026-11-15.
- [x] Merge `origin/main` vào `dev`: không làm trong đợt này (user không yêu cầu).

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |

## Acceptance criteria
- **AC-1:** Phần A của `CareNest_APP/DESIGN.md` trùng từng byte với `CareNest_FE` origin/dev `DESIGN.md` v3.4 (so bằng `diff` đoạn giữa hai marker).
- **AC-2:** Phần B có đủ: B1 các điểm được khác bổ sung (bo góc Clay, những điểm khác app đang dùng); B2 khung app (thanh đáy theo role, AppBar, hero, sheet, SafeArea, bàn phím); B3 công thức màn Phụ huynh / Giáo viên / Bếp; B4 style Clay (rút từ `docs/design/mobile-redesign-clay.md`); B5 tự kiểm riêng app; B6 đề xuất gửi FE (mâu thuẫn bo góc 1.3/3.6, đánh dấu "đã nối App").
- **AC-3:** Nội dung code của guide cũ (mục 1–2, 10–12, 15–16, phần code của 17–18) nằm ở `docs/architecture/CODING_GUIDE.md`, không mất mục nào (đối chiếu theo bảng mục lục cũ → mới).
- **AC-4:** `AGENTS.md` Stack trỏ `DESIGN.md` (UI) + `CODING_GUIDE.md` (code); `.claude/rules/ui-style.md` tự nạp theo paths presentation/widgets/theme/constants; ROUTER, INDEX, CONTEXT_MAP, `component.md` và các doc tham chiếu không còn trỏ số mục cũ.
- **AC-5:** 36 comment `DESIGN.md §` trong `lib/` trỏ đúng mục mới; `grep` không còn số mục của guide cũ.
- **AC-6:** `node scripts/check-ai-layer.mjs` pass; `node scripts/verify.mjs` → `VERIFY PASS`.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Cấu trúc | 1 file, Phần A chép nguyên + Phần B riêng App | Vá delta 3.1→3.4; trỏ link FE; tách Phần B ra file riêng | Một nguồn UI, web đổi chỉ cần thay Phần A, người đọc mở 1 file |
| Bo góc | App giữ Clay, ghi ở Phần B | App theo thang gọn của web | Vùng chạm ngón tay, style Clay đã duyệt 2026-10-14; không đổi code |
| Marker | `<!-- DS-SHARED:BEGIN v3.4 -->` / `<!-- DS-SHARED:END -->` | Không marker | So `diff` được, AI biết không được sửa tay Phần A |

## Phases
### Phase 1 — Tách code và dựng DESIGN.md hai phần
- Files: C `docs/architecture/CODING_GUIDE.md` · M `DESIGN.md`
- Steps: 1. Chuyển mục code của guide cũ sang CODING_GUIDE (giữ nguyên nội dung, đổi số mục, thêm link về DESIGN.md cho phần UI). 2. Chép DS 3.4 từ `git -C ../CareNest_FE show origin/dev:DESIGN.md` vào giữa hai marker. 3. Viết Phần B từ guide cũ §3, §5.3, §5.6, §8, §13–14 (phần app) + `docs/design/mobile-redesign-clay.md`; bỏ những gì Phần A đã nói. 4. Thêm bảng đổi số mục cũ → mới cuối Phần B.
- Tests: AC-1 (diff marker), AC-2, AC-3 (đối chiếu mục lục).
- Exit: `node scripts/check-ai-layer.mjs` pass.
- **Dừng chờ user review.**

### Phase 2 — Nối AI layer và tham chiếu docs
- Files: M `AGENTS.md` · C `.claude/rules/ui-style.md` (+ mirror nếu harness yêu cầu) · M `.claude/rules/component.md` · M `.ai/ROUTER.md`, `.ai/CONTEXT_MAP.yaml`, `.ai/profiles/code.md` · M `docs/INDEX.md`, `README.md`, `docs/architecture/MOBILE_ARCHITECTURE.md`, `docs/context/*.md`, `docs/features/teacher/README.md`, `docs/design/mobile-redesign-clay.md`
- Steps: thay tham chiếu số mục cũ theo bảng đổi số mục; plan cũ (active/completed) giữ nguyên vì là lịch sử.
- Tests: AC-4 (`grep -rn "DESIGN.md §"` trên docs/.ai/.claude).
- Exit: `node scripts/check-ai-layer.mjs` pass.
- **Dừng chờ user review.**

### Phase 3 — Đánh số lại comment trong lib/
- Files: M 36 file `lib/**` chỉ đổi comment `DESIGN.md §…` (danh sách lấy từ `grep -rln "DESIGN.md §" lib`).
- Steps: 1. In bản tác động (vùng chung `lib/core/**`, `lib/routing/**`; dán `node scripts/ai-layer/impact.mjs`). 2. Thay theo bảng đổi số mục. Không đổi code.
- Tests: AC-5 (`git diff` chỉ dòng comment); AC-6.
- Exit: `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0.
- **Dừng chờ user review.**

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | — | diff Phần A với FE origin/dev | 1 | |
| AC-2, AC-3 | — | rà mục lục cũ → mới | 1 | |
| AC-4 | — | grep tham chiếu + check-ai-layer | 2 | |
| AC-5, AC-6 | — | grep lib + verify.mjs | 3 | |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Mất nội dung code khi tách | Thành viên thiếu hướng dẫn auth/API | Đối chiếu mục lục cũ → mới (AC-3) | `git checkout` DESIGN.md cũ |
| Ai đó sửa tay Phần A | Lệch web lần nữa | Marker + luật trong `ui-style.md`; đổi ở FE trước rồi chép | Chép lại từ FE |
| Đổi số mục làm comment sai | AI đọc nhầm mục | Bảng đổi số mục + grep AC-5 | Revert Phase 3 |
| Plan active 2026-10-13 trỏ mục cũ | Đọc nhầm | Ghi chú đổi số mục ở Progress log của plan đó | — |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ không có (chỉ docs/comment)
- [x] Mỗi AC có cách kiểm; mỗi phase có Exit
- [x] >8 file: đã chia 3 phase, mỗi phase dừng review; không tách plan vì cùng một mục tiêu
- [x] Không dùng rule PENDING/OPEN như đã chốt
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan

## Progress log
### 2026-11-15 — Phase 1–3 (done)
- User duyệt plan 2026-11-15 và yêu cầu làm hết rồi đẩy lên `dev`.
- Phase 1: `DESIGN.md` = lời dẫn + Phần A (DS 3.4, `cmp` trùng byte với `CareNest_FE` origin/dev) + Phần B (B1–B11); `docs/architecture/CODING_GUIDE.md` tách từ guide cũ, đánh số 1–9.
- Phase 2: `AGENTS.md`, `README.md`, `.ai/CONTEXT_MAP.yaml`, `.ai/profiles/code.md`, `.claude/rules/component.md`, rule mới `.claude/rules/ui-style.md`, `docs/architecture/MOBILE_ARCHITECTURE.md`, `docs/design/mobile-redesign-clay.md`, `docs/features/teacher/README.md`. Plan cũ giữ nguyên số mục cũ (lịch sử; tra `DESIGN.md` §B10).
- Phase 3: 36 file `lib/`, chỉ comment (45 dòng). Impact `sizes.dart`: vùng chung, 81 file dùng — không đổi hành vi.
- Verify: `node scripts/check-ai-layer.mjs` → 0 lỗi, 3 cảnh báo cũ; `node scripts/verify.mjs` (Flutter 3.47.7 trên PATH, xem APP-ENV-261008-flutter-sdk-mismatch) → `VERIFY PASS full | format ok | analyze ok | tests 183 fail 0 skip 0`.
- Khác plan: `route_access_policy.dart` guide cũ nhắc không tồn tại ⇒ Phần B ghi "chưa có guard".
- Tiếp: đề xuất B9 gửi FE khi user cho phép sửa `CareNest_FE`.
