---
title: Màn Ban giám hiệu trên App chỉ xem
status: approved
owner: chưa gán
jira: TBD-3 / FE-FEAT-0   # mã tạm (chưa có task Jira APP, khác task BE); sửa khi user cung cấp mã thật
branch: feature/TBD-3-FE-FEAT-0-bgh-view-only   # tên tạm, tạo từ origin/dev
modules: [vice-principal, principal]
rules: [AUTH-21, AUTH-07, NUT-02, NUT-04, NUT-14, OBS-10, OBS-14]
risk: medium
created: 2026-11-13
updated: 2026-11-13
---
# Màn Ban giám hiệu trên App chỉ xem

Plan chính (BE): `BE:docs/plans/active/2026-11-13-bgh-mobile-view-only.md`, ADR `BE:docs/decisions/ADR-0026-staff-mobile-read-only.md`. Plan này chỉ phần client.

## Context
User chốt ngày 13/11/2026: BGH vẫn dùng App, nhưng chỉ xem. BE đã làm 3 lớp chặn: lệnh ghi bị chặn; tài khoản chỉ có role BGH chỉ gọi được 18 GET; transaction chỉ đọc. Mã lỗi: 1301 `MOBILE_STAFF_READ_ONLY`, 1302 `MOBILE_STAFF_WRITE_BLOCKED`. Ngoại lệ: đăng ký/hủy thiết bị nhận push, đánh dấu thông báo đã đọc.

Hiện trạng APP (`origin/dev` 4419486, code giống `dev` local):
- Tài liệu ghi BGH ngoài phạm vi App: `docs/context/REPOSITORY_CONTEXT.md:35`, `docs/architecture/NAVIGATION.md:16-20,69-86`, `docs/features/vice-principal/README.md:3`, `docs/features/principal/README.md:3`.
- Màn BGH chỉ đăng ký ở bản debug (`enablePreview`); bản release chỉ có Đăng nhập. Mọi màn đọc dữ liệu giả, chưa có API client.
- Nút thao tác còn trên màn BGH:
  - V01 "Xem & chốt" / "Xem bếp": `lib/features/vice_principal_home/presentation/screens/vice_principal_home_screen.dart:473-479`
  - V03 "Từ chối" / "Duyệt": `lib/features/approvals/presentation/screens/meal_adjustment_screen.dart:167-193`
  - V04 "Xác nhận gửi bếp": `lib/features/meal_count_confirm/presentation/screens/meal_count_confirm_screen.dart:138-143`
  - V12 "Trả lại" / "Gửi HT": `lib/features/reward_proposals/presentation/screens/reward_proposals_screen.dart:129-147`
  - H04 "Trả về Phó HT" / "Duyệt": `lib/features/reward_proposals/presentation/screens/reward_batch_screen.dart:180-198`
  - Tab "Duyệt": `lib/routing/navigation_destinations.dart:111,138`
- Màn trái rule kể cả khi chỉ xem:
  - V03 điều chỉnh suất (NUT-04: không có điều chỉnh chờ duyệt): route `lib/routing/app_router.dart:336`.
  - V05 trạng thái bếp (NUT-14 REMOVED): route `lib/routing/app_router.dart:351`.

## Quyết định đã chốt
1. BGH dùng App chỉ xem, không có thao tác nghiệp vụ — user, 13/11/2026 (AUTH-21, ADR-0026).
2. Bỏ PHT 03 (duyệt điều chỉnh suất), PHT 05 (trạng thái bếp), HT 05 (nghỉ phép nhân sự) — user, 13/11/2026 (review Figma).
3. Task Jira APP riêng, khác task BE — user hỏi 13/11/2026; mã chưa có.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** actor HT, PHT · outcome: xem số liệu trên App, thao tác trên Web · AUTH-21 (CONFIRMED, sửa 13/11).
- **Đối chiếu thiết kế ban đầu:** mockup 13/10 có duyệt trên App; AUTH-21 27/10 bỏ BGH khỏi App; quyết định 13/11: có App, chỉ xem.
- **Ảnh hưởng:** chỉ nhánh PHT, HT; Parent/Teacher/Kitchen không đổi. Không đổi contract BE (APP chưa gọi API).

### Câu hỏi mở
(không còn — đã trả lời 13/11/2026)

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| V03, V05 và code liên quan | Xóa file + test liên quan | user | 13/11 | NAVIGATION, feature PHT (Phase 1) |
| Tên tab thứ hai của BGH | "Chờ xử lý" | user | 13/11 | NAVIGATION (Phase 1) |
| Mã Jira APP | Chưa có, dùng tên tạm | user | 13/11 | front matter |

## Acceptance criteria
- **AC-1** (`AUTH-21`): Given bản debug ở vai trò PHT hoặc HT. When mở mọi màn BGH. Then không có nút nào gửi thao tác ghi (duyệt, từ chối, xác nhận, trả lại, gửi); nút điều hướng xem vẫn còn.
- **AC-2** (`NUT-02`): Given PHT mở Số suất hôm nay (V04). Then thấy bảng suất và trạng thái "Đã xác nhận lúc …" hoặc "Chưa xác nhận — xác nhận trên CareNest Web".
- **AC-3** (`OBS-10`, `OBS-14`): Given PHT mở V12 hoặc HT mở H04. Then thấy danh sách đề xuất và trạng thái; không có ô chọn, không có nút.
- **AC-4** (`NUT-04`, `NUT-14`): Given bản debug. When đi tới `/vice-principal/approvals/meals/<id>` hoặc `/vice-principal/kitchen`. Then route không còn (màn "không tìm thấy"); V01 và V02 không còn lối vào hai màn này.
- **AC-5** (`AUTH-21`): Given tab thứ hai của BGH. Then nhãn là "Chờ xử lý"; nội dung là danh sách việc chờ xử lý trên Web, chỉ xem.
- **AC-6**: Tài liệu APP (REPOSITORY_CONTEXT, NAVIGATION, feature PHT/HT, BACKEND_INTEGRATION) ghi BGH chỉ xem và cách xử lý 1301/1302.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Xử lý 1301/1302 | Ghi vào `docs/integration/BACKEND_INTEGRATION.md`: 403 kèm `errorCode` 1301/1302 ⇒ báo "Thao tác này làm trên CareNest Web", không retry | Viết code xử lý ngay | APP chưa có API client; viết code lỗi lúc này là đoán; làm khi có client |
| Nút "Xem & chốt" ở V01 | Đổi thành nút xem "Xem số suất" (mở V04 chỉ xem) | Bỏ hẳn | Vẫn cần lối vào bảng suất |
| Release | Giữ như cũ: màn BGH chỉ ở bản debug | Mở cho release | Chưa có auth thật (AUTH_CONTRACT APP SKELETON) |

## Phases
### Phase 1 — Tài liệu
- Files: M `docs/context/REPOSITORY_CONTEXT.md` · M `docs/architecture/NAVIGATION.md` · M `docs/features/vice-principal/README.md` · M `docs/features/principal/README.md` · M `docs/integration/BACKEND_INTEGRATION.md` · M `docs/context/CURRENT_STATE.md`
- Exit: `node scripts/check-ai-layer.mjs` → PASS. Repo APP chưa có chỉ đạo bỏ harness như BE (07/11).
- **Dừng chờ user review.**

### Phase 2 — Màn hình và test
- Files: M `vice_principal_home_screen.dart` (V01) · M `approvals_screen.dart`, `principal_approvals_screen.dart` (V02, H02) · M `meal_count_confirm_screen.dart` (V04) · M `reward_proposals_screen.dart` (V12), `reward_batch_screen.dart` (H04) · M `lib/routing/app_router.dart`, `route_paths.dart`, `navigation_destinations.dart` · D V03, V05 (`meal_adjustment_screen.dart`, `fake_meal_adjustment_source.dart`, `meal_adjustment.dart`, `campus_kitchen_screen.dart`) + test liên quan · M `test/features/vice_principal/vice_principal_screens_test.dart`, `test/features/principal/principal_screens_test.dart`, `test/routing/app_router_test.dart`
- Tests: AC-1 → kiểm không còn chữ nút ghi trên từng màn · AC-2 → V04 hiện trạng thái · AC-3 → V12/H04 không có `Checkbox`/nút · AC-4 → `app_router_test` route cũ ⇒ không tìm thấy · AC-5 → nhãn tab.
- Exit: `node scripts/verify.mjs` → PASS (gồm `flutter analyze`, `flutter test`).
- **Dừng chờ user review.**

Ước lượng 6 file tài liệu + khoảng 14 file code/test (>8): 1 plan, 2 phase, review riêng.

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1, AC-2, AC-3 | AUTH-21, NUT-02, OBS-10/14 | widget test PHT/HT | 2 | chưa chạy |
| AC-4, AC-5 | NUT-04, NUT-14, AUTH-21 | `app_router_test` | 2 | chưa chạy |
| AC-6 | AUTH-21 | `check-ai-layer.mjs` | 1 | chưa chạy |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Bỏ nút nhưng còn lối gọi ghi khác (deep link, thẻ ở trang chủ) | BGH bấm được thao tác | Grep mọi `onPressed`/`onTap` trong feature BGH; BE vẫn chặn (1301) | Gỡ thêm |
| Lệch mockup Figma cũ | Review nhầm | Figma vẽ lại sau (user 13/11) | — |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Không đổi contract BE; consumer: chỉ APP
- [x] Mỗi AC có test; mỗi phase có Exit
- [x] >8 file ⇒ 2 phase
- [x] Không dùng rule PENDING/OPEN như đã chốt
- [x] Câu hỏi mở đã trả lời hết

## Progress log
### 2026-11-13 — Plan draft
- Commit: chưa commit
- Verify: chưa chạy
- Tiếp: user trả lời câu hỏi mở, cho mã Jira APP, duyệt plan

### 2026-11-13 — Plan approved
- User duyệt plan ("Duyệt, làm luôn"); xóa V03/V05; tab "Chờ xử lý"; nhánh tạm.
- Chặn: `git switch -c feature/G94-TBD-FE-FEAT-TBD-bgh-view-only origin/dev` bị từ chối vì 2 file chưa commit không phải của plan (`.claude/settings.json`, `.githooks/pre-push`) — chờ user chọn cách xử lý.
- Xử lý (user chọn): `git stash push` 2 file (`stash@{0}` "local harness before bgh-view-only (13/11)", chưa drop) → `git switch -c feature/G94-TBD-FE-FEAT-TBD-bgh-view-only origin/dev` (4419486), bỏ upstream → thêm lại `enabledPlugins` vào `.claude/settings.json` (khớp bản stash; cấu hình cá nhân, không commit). `.githooks/pre-push` dùng bản `origin/dev`.

### 2026-11-13 — Phase 1 (chờ review)
- Commit: chưa commit
- Sửa: `docs/architecture/NAVIGATION.md` (cây role, mục PHT/HT, bảng route), `docs/context/REPOSITORY_CONTEXT.md`, `docs/context/CURRENT_STATE.md`, `docs/features/vice-principal/README.md`, `docs/features/principal/README.md`, `docs/integration/BACKEND_INTEGRATION.md` (403 + `errorCode` 1301/1302).
- Khác plan: sửa thêm `docs/features/README.md`, `AGENTS.md` (dòng giới thiệu + mục Ngoài scope), `.ai/CONTEXT_MAP.yaml`, `.ai/ROUTER.md`, `DESIGN.md` — cùng câu "BGH không dùng App".
- Verify: `node scripts/check-ai-layer.mjs` → `0 lỗi, 3 cảnh báo` (E7 glob rule không khớp file, có từ trước); `git grep` "BGH chỉ dùng Web|ngoài phạm vi App" ngoài plan/completed → chỉ còn câu trích "thay …".
- Tiếp: user review Phase 1 → Phase 2 (sửa `lib/routing/**` là vùng dùng chung ⇒ in bản tác động trước khi sửa).

### 2026-11-13 — Phase 2 (chờ review)
- Commit: chưa commit
- Code: V01 (`vice_principal_home_screen.dart`, `campus_today.dart`, `fake_campus_today_source.dart`: bỏ bếp, mục "Chờ xử lý", nút "Xem số suất"), V02/H02 (`approvals_screen.dart`, `principal_approvals_screen.dart`: chỉ xem, số suất chưa xác nhận + khen thưởng), V04 (`meal_count_confirm_screen.dart`: bỏ nút xác nhận; `MealCountConfirmSource` bỏ `confirm()`), V12/H04 (`reward_proposals_screen.dart`, `reward_batch_screen.dart`: bỏ nút, ô chọn, ô ghi chú; nguồn bỏ hàm ghi), H01 (`principal_overview_screen.dart`: "Chờ xử lý"), `role_preview_screen.dart` (mô tả vai trò), routing (`app_router.dart`, `route_paths.dart`, `navigation_destinations.dart`: gỡ V03/V05, tab "Chờ xử lý").
- Xóa: `approvals/presentation/screens/meal_adjustment_screen.dart`, `approvals/data/fake_meal_adjustment_source.dart`, `approvals/domain/meal_adjustment.dart`, `vice_principal_home/presentation/screens/campus_kitchen_screen.dart`.
- Test: `vice_principal_screens_test.dart` (viết lại: không nút ghi, V04 chỉ xem, bỏ V03/V05), `principal_screens_test.dart` (H04 chỉ xem), `app_router_test.dart` (tab "Chờ xử lý", route V03/V05 ⇒ "Không tìm thấy trang").
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 181 fail 0 skip 0`.
- Khác plan: sửa thêm H01 (`principal_overview_screen.dart`) và `role_preview_screen.dart` (chữ "chờ duyệt"); `cooking_status` (K07 bếp) giữ nguyên — ngoài phạm vi plan.
- Tiếp: user review; mã Jira APP ⇒ đổi tên nhánh, commit khi user cho phép; Figma vẽ lại.

### 2026-11-13 — Commit và push (user cho phép)
- Đổi tên nhánh tạm `feature/G94-TBD-FE-FEAT-TBD-bgh-view-only` thành `feature/TBD-3-FE-FEAT-0-bgh-view-only`: hook `commit-msg` chỉ nhận mã `[A-Z][A-Z0-9]+-[0-9]+`. Commit `TBD-3` (màn BGH chỉ xem); commit riêng `TBD-2` ghi quyết định 13/11 (OTP SMS phụ huynh, không bắt tải ảnh) vào `AUTH_FLOW.md`, `NAVIGATION.md`. Không commit `.claude/settings.json` (khối plugin cá nhân), `docs/architecture/package-diagram-mobile.drawio` (không thuộc task); `stash@{0}` giữ nguyên.
- Tiếp: user cung cấp mã Jira thật ⇒ đổi tên nhánh/commit; Figma bản Phụ huynh chờ hạn mức MCP.
