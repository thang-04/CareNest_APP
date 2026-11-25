---
title: Bé của tôi — một trang hồ sơ và hành trình năm học
status: done         # user 18/11 "làm luôn"; draft → approved → in-progress → done | blocked | cancelled
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # mã tạm của nhánh (plan 2026-11-16) — đổi sang mã Jira thật trước khi mở PR
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [features]
rules: [PAR-01, PAR-03, HLT-11, OBS-06, OBS-10, OBS-14, OBS-27, OBS-29, AUTH-04]
risk: medium         # đổi route Bé của tôi trong lib/routing (vùng dùng chung); dữ liệu giả, không đổi contract BE
created: 2026-11-18
updated: 2026-11-18
---
# Bé của tôi — một trang hồ sơ và hành trình năm học

## Context
- User 18/11 duyệt bảng "Bé của tôi · hành trình" trên canvas "Trang chủ và Bé của tôi" (https://claude.ai/artifact/EcfJG4Ko49qJtq2WBpcAoA); Trang chủ giữ nguyên.
- Hiện tại Bé của tôi có thanh Hôm nay | Phát triển (`lib/features/parent/my_child/presentation/screens/my_child_screen.dart:106-131`); tab Phát triển trùng trang Đánh giá và Khen thưởng mới làm 18/11. Route nhận `tab`, `section` (`lib/routing/app_router.dart:250-256`, `lib/routing/route_paths.dart:28-34`); Trang chủ không còn dùng `parentChildAt`.
- BE chưa có API tổng hợp cho phụ huynh ⇒ dữ liệu giả, số liệu khớp các trang Đánh giá, Khen thưởng (mốc cuối năm học 28/05/2027).

## Quyết định đã chốt
1. Trang chủ giữ nguyên, kể cả 6 ô Việc nhanh — user 18/11.
2. Bé của tôi một trang, không chia tab, không có phần Hôm nay: thanh chọn bé, thẻ hồ sơ (Gọi cô, Hồ sơ của bé), Hành trình năm học (chiều cao, cân nặng, phiếu Bé ngoan, ngày đi học), Phát triển (nhận xét tuần mới nhất, học kỳ, chủ đề), Danh hiệu — user 18/11.
3. Hành trình chỉ hiện số đo gần nhất; đổi bé dùng chung bé đang chọn với Trang chủ — mặc định ghi trên canvas.

## Làm rõ nghiệp vụ
Theo `.ai/workflows/clarify-business.md`.
- **Hiểu nghiệp vụ:** phụ huynh xem đúng danh mục PAR-01; cân đo đã công bố (HLT-11), nhận xét tuần đã gửi (OBS-29), học kỳ đã xác nhận (OBS-06), chủ đề (OBS-27), phiếu (OBS-10), danh hiệu sau khi Hiệu trưởng duyệt (OBS-14, PAR-03); chỉ con của mình (AUTH-04). Số liệu do BE đếm, App không tự tính.
- **Ảnh hưởng:** APP: màn Bé của tôi, route `/parent/child` bỏ tham số `tab`, `section` (link cũ vẫn mở Bé của tôi). Trang chủ không đổi giao diện; đổi bé ở Bé của tôi thì Trang chủ đổi theo như trước (`SelectedChild`). BE không đổi.

### Câu hỏi mở
Còn `- [ ]` ⇒ không được `approved` (check-ai-layer E5).
- [x] Trang chủ có đổi không
- [x] Bé của tôi theo bản nào

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Trang chủ | Giữ nguyên | User | 18/11 | `docs/features/parent/README.md` |
| Bé của tôi | Theo bảng "Bé của tôi · hành trình" | User | 18/11 | `docs/features/parent/README.md` |

## Acceptance criteria
- **AC-1** (`PAR-01`): Given tab Bé của tôi, Then thấy thẻ hồ sơ (tên, lớp, tuổi, cô chủ nhiệm, Gọi cô, Hồ sơ của bé), 4 ô Hành trình năm học, thẻ Phát triển, phần Danh hiệu; không còn thanh Hôm nay | Phát triển.
- **AC-2** (`AUTH-04`): Given phụ huynh có 2 bé, When chạm tên bé ở thanh trên đầu, Then trang và bé đang chọn của Trang chủ đổi theo; đổi bé ở Trang chủ thì Bé của tôi đổi theo.
- **AC-3** (`OBS-14`, `PAR-03`): Given danh sách khen thưởng chưa duyệt, Then hiện "Chưa có danh hiệu cuối năm"; đã duyệt mà không có danh hiệu ⇒ câu nhẹ nhàng.
- **AC-4**: When chạm ô chiều cao / cân nặng, phiếu, ngày đi học, link Đánh giá, Khen thưởng, Hồ sơ của bé, Then mở Sổ sức khỏe, Khen thưởng, Điểm danh, Đánh giá, Hồ sơ của bé theo bé đang chọn.
- **AC-5**: Đủ trạng thái tải, lỗi + "Thử lại"; chữ 1,3 và 2,0 không tràn (4 ô xếp 1 cột khi chữ lớn).

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Nguồn dữ liệu | `MyChildSource.loadJourney` + model `ChildJourney` | Ghép từ nguồn giả của Đánh giá, Khen thưởng, Sổ sức khỏe | Một API tổng hợp cho phụ huynh sau này; không để feature này phụ thuộc dữ liệu của feature khác |
| Thanh chọn bé | `AppSegmented` (tên bé) | Thanh có ảnh chữ cái như canvas | Dùng widget chung có sẵn, không sửa `lib/core` |
| Route cũ `?tab=&section=` | Bỏ tham số, link cũ vẫn mở Bé của tôi | Giữ tham số không dùng | Màn không còn tab; Trang chủ đã mở trang Khen thưởng riêng |

## Phases
### Phase 1 — Màn và dữ liệu giả
- Files: M `lib/features/parent/my_child/domain/my_child.dart` · M `lib/features/parent/my_child/data/fake_my_child_source.dart` · M `lib/features/parent/my_child/presentation/screens/my_child_screen.dart` · M `test/features/parent/my_child/my_child_screens_test.dart`
- Tests: AC-1, AC-2, AC-3, AC-5
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 2 — Route (vùng dùng chung)
- Files: M `lib/routing/app_router.dart` · M `lib/routing/route_paths.dart` · M `test/routing/app_router_test.dart`
- Tests: AC-4
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 3 — Tài liệu
- Files: M `docs/features/parent/README.md` · M `docs/architecture/NAVIGATION.md` · M `docs/context/CURRENT_STATE.md`
- Exit: `node scripts/check-ai-layer.mjs` + `node scripts/verify.mjs` → PASS

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | PAR-01 | `my_child_screens_test.dart` (widget) | 1 | pass |
| AC-2 | AUTH-04 | `my_child_screens_test.dart` (widget) | 1 | pass |
| AC-3 | OBS-14, PAR-03 | `my_child_screens_test.dart` (widget) | 1 | pass |
| AC-4 | — | `app_router_test.dart` (widget) | 2 | pass |
| AC-5 | — | `my_child_screens_test.dart` (chữ 1,3 / 2,0, lỗi) | 1 | pass |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Sửa route trong vùng dùng chung | Router mọi vai trò | Chỉ đổi builder của `/parent/child` và bỏ hàm `parentChildAt` không còn ai gọi; test router | Trả builder cũ và `parentChildAt` |
| Mất phần Hôm nay ở Bé của tôi | Phụ huynh tìm chi tiết ngày | Trang chủ giữ thẻ bé + ô "Hoạt động & đánh giá"; trang Đánh giá › Ngày | Khôi phục tab Hôm nay từ git |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ không đổi contract BE
- [x] Mỗi AC có test; mỗi phase có Exit = lệnh + kết quả mong đợi
- [x] >8 file: không tách plan — 3 phase nối tiếp của cùng một màn
- [x] Không dùng rule PENDING/OPEN như đã chốt
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan · không câu mơ hồ

## Progress log
### 2026-11-18 — Phase 1 (done)
- `MyChildSource` bỏ `loadToday`, `loadDevelopment` (cùng model `ChildToday`, `DevelopmentSummary`, `DayEvent`, `LeaveSummary`), thêm `loadJourney` → `ChildJourney` (số đo, phiếu tuần / tháng, ngày đi học, nhận xét tuần, học kỳ, chủ đề, danh hiệu; field nào null thì ẩn). Dữ liệu giả khớp trang Đánh giá, Khen thưởng (mốc 28/05/2027).
- `MyChildScreen` một trang: thanh chọn bé (`AppSegmented`, khi có từ 2 bé), thẻ hồ sơ, Hành trình năm học (4 ô có `Semantics` nút, 1 cột khi chữ > 1,3), Phát triển, Danh hiệu (chưa duyệt / không có danh hiệu / có danh hiệu).
- Chữ 2,0: tiêu đề mục kèm link "Khen thưởng ›" tràn 55 px khi đặt trong `Row` ⇒ đổi `_SectionHeader` sang `Wrap`.
- Không sửa thêm `lib/core`: dùng icon đã có (`ticket`, `star` thêm từ trang Khen thưởng).

### 2026-11-18 — Phase 2 (done)
- Router: `/parent/child` không đọc `tab`, `section` (link cũ vẫn mở Bé của tôi); xoá `RoutePaths.parentChildAt` (không còn chỗ gọi). Trang chủ không đổi file nào.
- Test router: link cũ `/parent/child?tab=development&section=rewards` mở Bé của tôi; ô Phiếu Bé ngoan ⇒ Khen thưởng; "Đánh giá ›" ⇒ Đánh giá; ô Chiều cao ⇒ Sổ sức khỏe.

### 2026-11-18 — Phase 3 (done)
- `docs/features/parent/README.md` (mục Bé của tôi, lệch BE; sửa các câu "khối cũ"), `docs/architecture/NAVIGATION.md`, `docs/context/CURRENT_STATE.md`.
- `node scripts/verify.mjs` (Flutter 3.47.6) → `VERIFY PASS full | format ok | design ok | analyze ok | tests 445 fail 0 skip 0`.
- Chưa commit, chưa push: chờ user cho phép.

### 2026-11-18 — Thay thế
- User duyệt canvas "Bé của tôi gộp Hồ sơ": Bé của tôi là hồ sơ của bé, bỏ hành trình năm học ⇒ plan `docs/plans/completed/2026-11-18-parent-my-child-profile.md`.
