---
title: Trang Khen thưởng của phụ huynh — 3 mục Tuần · Tháng · Cuối năm
status: done         # user 18/11 "sửa UI app luôn làm datamock" ⇒ làm ngay; draft → approved → in-progress → done | blocked | cancelled
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # mã tạm của nhánh (plan 2026-11-16) — đổi sang mã Jira thật trước khi mở PR
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [features]
rules: [OBS-10, OBS-14, OBS-23, PAR-03, PAR-09]
risk: medium         # thêm route vào lib/routing, thêm icon vào lib/core (vùng dùng chung); dữ liệu giả, không đổi contract BE
created: 2026-11-18
updated: 2026-11-18
---
# Trang Khen thưởng của phụ huynh

## Context
- User 18/11 duyệt canvas "Khen thưởng của bé" (https://claude.ai/artifact/2WM74tr1wVBDiCd4ecdYRA): trang Khen thưởng riêng, thanh 3 mục như trang Đánh giá.
- Hiện ô "Khen thưởng" ở Việc nhanh mở tab Phát triển của Bé của tôi, khối phiếu bé ngoan cũ ghi "Đã có 2 phiếu tuần · cần 3 phiếu để nhận bé ngoan" (lẫn cờ với phiếu) (`lib/features/parent/parent_home/presentation/screens/parent_home_screen.dart:223-230`, `lib/features/parent/my_child/presentation/screens/my_child_screen.dart:363-425`).
- BE: cờ nằm trong đánh giá ngày, chỉ tính ngày có mặt (`BE:src/main/java/com/carenest/service/observation/impl/BehaviourTicketServiceImpl.java:454-465`); phiếu tuần cần ≥ 3 cờ, phiếu tháng ≥ 3 phiếu tuần (`:62-63`, `:507-511`); danh hiệu cuối năm và ghi chú của cô ở `RewardListItem` (`BE:src/main/java/com/carenest/entity/observation/RewardListItem.java`), duyệt GV → PHT → HT (`RewardList.java`). Chưa có API cho phụ huynh ⇒ dữ liệu giả như trang Đánh giá.

## Quyết định đã chốt
1. Trang Khen thưởng riêng, 3 mục: Tuần · Tháng · Cuối năm; nút "?" mở phần giải thích — user 18/11 (canvas).
2. Ô "Khen thưởng" ở Trang chủ mở thẳng trang này; Bé của tôi giữ nguyên — user 18/11.
3. Phụ huynh xem ghi chú của cô trong danh sách khen thưởng (mục "Lời cô" ở Cuối năm) — user 18/11.
4. Phiếu tháng giữ tên "Bé ngoan toàn diện", không thêm nhãn "xuất sắc" — user 18/11.
5. Danh sách đã duyệt mà bé không có danh hiệu ⇒ câu nhẹ nhàng — user 18/11.
6. Có báo đẩy khi bé nhận phiếu tuần, phiếu tháng, danh hiệu — user 18/11; App chưa có push (Phase 7 plan 2026-11-16) ⇒ ghi khoảng trống, không làm ở plan này.
7. Dữ liệu giả, chưa nối BE — user 18/11 "làm datamock".

## Làm rõ nghiệp vụ
Theo `.ai/workflows/clarify-business.md`.
- **Hiểu nghiệp vụ:** OBS-10 (cờ ngày, phiếu tuần, phiếu tháng, không thu hồi, GV chọn trẻ nhận phiếu, phụ huynh thấy ngay khi phát), OBS-14 (danh hiệu cuối năm, GV → PHT → HT), PAR-03 (khen thưởng chỉ hiện sau công bố/xác nhận) — CONFIRMED. Ngưỡng 3 cờ / 3 phiếu lấy từ `rules` BE trả, App không ghi cứng.
- **Đối chiếu thiết kế ban đầu:** khối phiếu bé ngoan ở tab Phát triển giữ nguyên (user 18/11); trang mới thay đích của ô "Khen thưởng".
- **Ảnh hưởng:** APP: Trang chủ (ô Khen thưởng), route mới `/parent/rewards`, 4 icon mới trong `AppIcons`. BE không đổi; cần BE thêm API theo trẻ và loại báo đẩy (ghi ở README).

### Câu hỏi mở
Còn `- [ ]` ⇒ không được `approved` (check-ai-layer E5).
- [x] Lối vào trang Khen thưởng
- [x] Phụ huynh có xem ghi chú của cô không
- [x] Nhãn "3 phiếu trong tháng là xuất sắc" (OBS-10)
- [x] Đã duyệt nhưng bé không có danh hiệu
- [x] Báo đẩy khi có phiếu hoặc danh hiệu

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Lối vào | Ô "Khen thưởng" ở Trang chủ mở trang này | User | 18/11 | `docs/features/parent/README.md` |
| Ghi chú của cô | Cho phụ huynh xem | User | 18/11 | `docs/features/parent/README.md` |
| Nhãn xuất sắc | Giữ "Bé ngoan toàn diện" | User | 18/11 | `docs/features/parent/README.md` |
| Không có danh hiệu | Hiện câu nhẹ nhàng | User | 18/11 | `docs/features/parent/README.md` |
| Báo đẩy | Có (phiếu tuần, phiếu tháng, danh hiệu) | User | 18/11 | `docs/features/parent/README.md` |

## Acceptance criteria
- **AC-1** (`OBS-10`): Given mục Tuần, Then thẻ đầu là tuần mới nhất: số cờ (BE đếm), cờ từng ngày T2–T6 (có cờ, không cờ, nghỉ, chưa có — có chữ hoặc icon, không chỉ màu), câu "Từ N cờ trong tuần, cô xét phiếu Bé ngoan khi hết tuần" (N từ BE) hoặc "Bé nhận phiếu Bé ngoan" + người phát, ngày phát; nút "Xem đánh giá từng ngày". Bên dưới: các tuần trước nhóm theo tháng, tuần có phiếu có nhãn "Bé ngoan"; "Xem các tuần trước" mở thêm tháng cũ.
- **AC-2** (`OBS-10`): Given mục Tháng, Then thẻ đầu là tháng mới nhất: số phiếu Bé ngoan, ô từng tuần (có phiếu, không phiếu, đang diễn ra), câu ngưỡng hoặc "Bé nhận phiếu Bé ngoan toàn diện"; các tháng trước có số phiếu tuần và nhãn "Bé ngoan toàn diện".
- **AC-3** (`OBS-14`, `PAR-03`): Given mục Cuối năm và danh sách đã duyệt, Then thấy năm học, các danh hiệu, Lời cô, "Hiệu trưởng duyệt ngày …"; chưa duyệt ⇒ "Chưa có danh hiệu cuối năm"; duyệt mà không có danh hiệu ⇒ câu nhẹ nhàng. Thẻ "Cả năm học": số cờ, phiếu tuần, phiếu tháng.
- **AC-4**: Given nút "?" (Cách bé nhận khen thưởng), Then sheet giải thích 4 bậc với ngưỡng BE trả, nút "Đã hiểu" đóng sheet.
- **AC-5**: Given Trang chủ, When chạm "Khen thưởng", Then mở trang Khen thưởng mục Tuần; "Xem đánh giá từng ngày" mở trang Đánh giá; con lạ ⇒ màn không tìm thấy.
- **AC-6**: Đủ trạng thái tải, lỗi + "Thử lại", rỗng; chữ 1,3 và 2,0 không tràn.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Màu danh hiệu | Tông xanh lá như cờ, phiếu | Vàng như canvas | `.claude/rules/ui-style.md`: tông `approval` chỉ cho "chờ duyệt"; canvas sửa theo |
| Icon phiếu, huy chương, sao, hỏi | Thêm `ticket`, `medal`, `star`, `help` vào `AppIcons` | Mượn icon có sẵn (approval, sparkles) | Nghĩa rõ hơn; chỉ thêm hằng, không đổi icon cũ |
| Ô ngày, ô tuần khi chữ lớn | Chữ trong ô co lại vừa ô (`FittedBox`) | Đổi bố cục khi chữ lớn | Ô hẹp (5 ô / hàng); chữ khác vẫn theo cỡ người dùng |
| Nguồn dữ liệu | `RewardSource` + `FakeRewardSource` | Gọi API GV | API phiếu cần quyền ASSESSMENT_VIEW, không dành cho phụ huynh |

## Phases
### Phase 1 — Màn và dữ liệu giả
- Files: M `lib/core/constants/app_icons.dart` · C `lib/features/parent/rewards/domain/rewards.dart` · C `lib/features/parent/rewards/data/fake_reward_source.dart` · C `lib/features/parent/rewards/presentation/rewards_status.dart` · C `lib/features/parent/rewards/presentation/screens/rewards_screen.dart` · C `lib/features/parent/rewards/presentation/widgets/` (mục Tuần, Tháng, Cuối năm, khối dùng chung, sheet giải thích) · C `test/features/parent/rewards/rewards_screen_test.dart`
- Tests: AC-1 → AC-4, AC-6
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 2 — Route và ô Khen thưởng ở Trang chủ (vùng dùng chung)
- Files: M `lib/routing/route_paths.dart` · M `lib/routing/app_router.dart` · M `lib/features/parent/parent_home/presentation/screens/parent_home_screen.dart` · M `test/routing/app_router_test.dart`
- Tests: AC-5
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 3 — Tài liệu
- Files: M `docs/features/parent/README.md` · M `docs/architecture/NAVIGATION.md` · M `docs/context/CURRENT_STATE.md`
- Exit: `node scripts/check-ai-layer.mjs` + `node scripts/verify.mjs` → PASS

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | OBS-10 | `rewards_screen_test.dart` (widget) | 1 | pass |
| AC-2 | OBS-10 | `rewards_screen_test.dart` (widget) | 1 | pass |
| AC-3 | OBS-14, PAR-03 | `rewards_screen_test.dart` (widget) | 1 | pass |
| AC-4 | OBS-10, OBS-14 | `rewards_screen_test.dart` (widget) | 1 | pass |
| AC-5 | — | `app_router_test.dart` (widget) | 2 | pass |
| AC-6 | — | `rewards_screen_test.dart` (chữ 1,3 / 2,0, lỗi, rỗng) | 1 | pass |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Thêm route, icon vào vùng dùng chung | Router mọi vai trò; bộ icon | Chỉ thêm 1 route con phụ huynh theo mẫu Đánh giá và 4 hằng icon; test router | Gỡ route, trả ô Khen thưởng về `RoutePaths.parentChildAt('development', section: 'rewards')`, gỡ 4 hằng |
| Dữ liệu giả lệch contract khi BE thêm API | Sửa domain khi nối | Field theo entity BE (`BehaviourTicket`, `RewardListItem`); ghi khoảng trống ở README | Sửa `domain/rewards.dart` + nguồn dữ liệu |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ không đổi contract BE
- [x] Mỗi AC có test; mỗi phase có Exit = lệnh + kết quả mong đợi
- [x] >8 file: không tách plan — 3 phase nối tiếp của cùng một màn
- [x] Không dùng rule PENDING/OPEN như đã chốt (5 câu hỏi user trả lời 18/11)
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan · không câu mơ hồ

## Progress log
### 2026-11-18 — Phase 1 (done)
- Trang Khen thưởng 3 mục + sheet "Cách bé nhận khen thưởng", dữ liệu giả `FakeRewardSource` (Minh Anh Mầm 3A, Bảo Ngọc Lá 1; mốc thứ Sáu 28/05/2027; cờ tuần 24–28/05 khớp đánh giá ngày của trang Đánh giá).
- `AppIcons` thêm `ticket`, `medal`, `star`, `help` (chỉ thêm hằng, icon cũ không đổi).
- Khác canvas: danh hiệu tông xanh lá; nhãn "Bé ngoan toàn diện" ở các tháng trước đặt dưới số phiếu — nằm bên phải dòng thì test chữ 1,3 tràn 69 px (font test rộng hơn font thật, `AppListRow` chỉ xếp phần cuối xuống dưới khi chữ > 1,3). Canvas sửa theo.
- `flutter test test/features/parent/rewards/rewards_screen_test.dart` → 9 pass.

### 2026-11-18 — Phase 2 (done)
- Route `/parent/rewards` (ID con ở query, con lạ ⇒ 404); ô "Khen thưởng" ở Trang chủ mở trang mới; "Xem đánh giá từng ngày" mở `/parent/evaluation`. Route `/parent/child?tab=development&section=rewards` (khối cũ ở Bé của tôi) giữ nguyên.
- Test router: Việc nhanh › Khen thưởng › Xem đánh giá từng ngày; trang theo bé trên đường dẫn, bé lạ ⇒ 404.

### 2026-11-18 — Phase 3 (done)
- `docs/features/parent/README.md` (mục Trang Khen thưởng, chốt 18/11, lệch BE), `docs/architecture/NAVIGATION.md`, `docs/context/CURRENT_STATE.md`.
- `node scripts/verify.mjs` (Flutter 3.47.6) → `VERIFY PASS full | format ok | design ok | analyze ok | tests 445 fail 0 skip 0`.
- Chưa commit, chưa push: chờ user cho phép.
