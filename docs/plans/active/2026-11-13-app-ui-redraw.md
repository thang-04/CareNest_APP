---
title: UI App theo bản sửa Figma 13/11 (phụ huynh, giáo viên) — dữ liệu giả
status: approved
owner: Giáp
jira: G94-194 / FE-FEAT-49
branch: feature/G94-194-FE-FEAT-49-app-ui-redraw
modules: [leave_notice, parent_menu, my_child, auth, attendance, class_leave_notices, daily_review, pickup, health_measure, teacher_home, meal_photos]
rules: [ATT-02, ATT-04, ATT-05, ATT-09, HLT-07, HLT-11, HLT-12, HLT-13, OBS-01, OBS-02, OBS-06, OBS-10, OBS-13, PCK-02, PCK-04, NUT-16, PAR-01, AUTH-19]
risk: medium
created: 2026-11-13
updated: 2026-11-14
---
# UI App theo bản sửa Figma 13/11 (phụ huynh, giáo viên) — dữ liệu giả

## Context
- Figma "CareNest App (Moqups)" (`8DzWya6TsjSge4CBpERBxb`, trang App `0:1`) có khung "Bản sửa theo rule – 13/11" cho Phụ huynh (`157:2`) và GV & Bếp (`154:2`); user đã chỉnh tay khung Phụ huynh (bỏ PH 15, 17, 18b; giữ PH 01 ghi "Lần đầu đăng nhập: đổi mật khẩu").
- Code App hiện vẽ theo bản gốc: còn "Ăn 1 bữa" (`lib/features/attendance/data/fake_attendance_source.dart`), "Suất huỷ" (`lib/features/my_child/presentation/screens/child_attendance_screen.dart`), "Đánh dấu đã xem" (`lib/features/class_leave_notices/presentation/screens/class_leave_screen.dart`), "Công bố" (`lib/features/health_measure/presentation/screens/health_measure_detail_screen.dart`), buổi nghỉ (`lib/features/leave_notice/presentation/screens/leave_notice_form_screen.dart`), "Nhận xét tuần" (`lib/features/my_child/presentation/screens/my_child_screen.dart`).
- Chưa nối BE (user tạm dừng 13/11); mọi màn dùng `FakeXxxSource`.

## Quyết định đã chốt
1. Màn conflict làm theo bản sửa user đã chỉnh; màn "Giữ nguyên" (PH 02, 06, 07, 11, 13, 14, 15–17, 18, 19; GV 04, 05, 07, 09) không đổi — user 13/11.
2. Quên mật khẩu phụ huynh giữ luồng OTP SMS PH 15 → 16 → 17 như bản gốc (BE AUTH-19, user chốt 13/11); không bắt tải ảnh chân dung khi đăng nhập lần đầu (BE PCK-02).
3. Màn bếp để task khác; không đụng `kitchen_*`, `cooking_status`, `ingredient_receipt`, `food_quantities` — user 13/11.
4. GV chụp ảnh bữa (GV 15–16): gỡ lối vào trên màn GV, giữ code `lib/features/meal_photos` — user 13/11.
5. Làm liền các phase, báo một lần — user 13/11.
6. Mở rộng 13/11 (user): làm thêm màn bếp theo bản sửa, đưa màn BGH chỉ xem (nhánh TBD-3) vào cùng bản — giữ Hiệu trưởng và Phó hiệu trưởng là 2 role/shell riêng, không gộp; so các màn giữ nguyên với Figma rồi sửa chỗ lệch. Màn có cả bản gốc và bản sửa ⇒ theo bản sửa. Việc mở rộng ghi mã Jira G94-87.
7. Theo đúng Figma toàn App (user 14/11): bỏ style Clay nổi (lựa chọn 14/10), đổi style dùng chung `lib/core` sang style phẳng của Figma (xanh `#1565E0`, nền `#F5F8FC`, card trắng viền mảnh bo 12, nút/ô nhập bo 8, thanh tiêu đề trắng, thanh dưới trắng sát đáy); màn có bản sửa theo bản sửa, bỏ khung cũ; màn không có bản sửa theo khung gốc — kể cả PH 02, PHT 01, HT 01 trước đây giữ bố cục Clay. Nội dung nghiệp vụ đã chốt (Quyết định 1–4, quyết định 14/11 ở plan `2026-11-14-app-business-decisions.md`) thắng chữ trên Figma khi lệch. Làm liền cả 4 nhóm vai trò, báo một lần (user 14/11). Mã Jira: G94-194.

## Acceptance criteria
- **AC-1 (AUTH-19, PCK-02)** PH 01: chú thích "Tài khoản do nhà trường cấp qua SMS. Lần đầu đăng nhập: đổi mật khẩu."; không nhắc ảnh chân dung.
- **AC-2 (ATT-05, ATT-04)** PH 03: form chỉ có từ ngày, đến ngày, lý do; không chọn buổi; ghi chú "Ngày nghỉ ghi Vắng có phép. Tối đa 30 ngày mỗi đơn."
- **AC-3 (ATT-04, ATT-05)** PH 04: đơn còn hủy được có nút "Hủy đơn"; không còn "GV đã xem / chưa xem"; ghi chú hủy trước giờ chốt.
- **AC-4 (NUT-16, PAR-01)** PH 05: ảnh bữa ghi "Ảnh mẫu của bếp cơ sở · HH:mm", không ghi GV đăng.
- **AC-5 (OBS-02, ATT-04, ATT-05)** PH 08: mức đánh giá Đạt / Cần cố gắng / Chưa đạt; đơn nghỉ hiện "Vắng có phép dd/MM"; không "GV chưa xem", không "Suất ăn đã huỷ".
- **AC-6 (OBS-02, OBS-13)** PH 09: mức đánh giá Đạt / Cần cố gắng / Chưa đạt.
- **AC-7 (ATT-02)** PH 10: không đánh dấu ăn từng bữa, không ô "Suất huỷ".
- **AC-8 (OBS-06, OBS-10)** PH 12: nhận xét định kỳ theo tháng (không nhận xét tuần).
- **AC-9** GV 01: không có việc "Cơ sở vật chất"; không lối vào chụp ảnh bữa.
- **AC-10 (ATT-02, HLT-07, ATT-04, ATT-09)** GV 02: không "Ăn 1 bữa"; nhập nhiệt độ đầu ngày cho bé có mặt; bé có đơn nghỉ khóa ở "Có phép (theo đơn)", GV không đổi.
- **AC-11 (ATT-05)** GV 03: chỉ xem; không "Mới / Đã xem", không "Đánh dấu đã xem"; ghi chú "Ngày có đơn tự ghi Vắng có phép, không có suất (ATT-04). GV chỉ xem đơn."
- **AC-12 (OBS-01, OBS-02)** GV 04.1: 7 mặt (ăn uống, ngủ, cảm xúc, hành vi, tham gia hoạt động, kiến thức – kỹ năng, sức khỏe), mức Đạt / Cần cố gắng / Chưa đạt, mặc định Đạt.
- **AC-13 (PCK-02, PCK-04)** GV 06: nhánh không khớp bắt ghi nội dung cuộc gọi rồi chọn Trả bé / Không trả bé; trả bé ghi người đón, giờ đón, báo phụ huynh.
- **AC-14 (HLT-11, HLT-12, HLT-13)** GV 07.1: không công tắc "Công bố" (lưu là công bố); phân loại chỉ hiển thị (hệ thống tính); sửa số đo đã lưu bắt buộc nhập lý do.

## Phases
### Phase 1 — Phụ huynh (PH 01, 03, 04, 05, 08, 09, 10, 12)
- Files: M màn + domain + fake source của `auth`, `leave_notice`, `parent_menu`, `my_child`; test tương ứng.
- Exit: `node scripts/verify.mjs` pass.

### Phase 2 — Giáo viên (GV 01, 02, 03, 04.1, 06, 07.1)
- Files: M màn + domain + fake source của `teacher_home`, `attendance`, `class_leave_notices`, `daily_review`, `pickup`, `health_measure`; gỡ lối vào `meal_photos` ở màn/route GV; test tương ứng.
- Exit: `node scripts/verify.mjs` pass; `node scripts/check-ai-layer.mjs` pass (docs đổi).

### Phase 3 — BGH chỉ xem (từ nhánh TBD-3, G94-87)
- Áp `74f647c` (BGH chỉ xem) và `3253153` (ghi chú OTP SMS phụ huynh) bằng `git cherry-pick -n`; plan chi tiết: `docs/plans/active/2026-11-13-bgh-view-only.md`. HT và PHT giữ 2 shell riêng (`/principal`, `/vice-principal`).
- Exit: `node scripts/verify.mjs` pass.

### Phase 4 — Bếp theo bản sửa (G94-87)
- AC-15 (NUT-07, AUTH-05) Bếp 01: thẻ "Định lượng thực phẩm · Theo N suất đã xác nhận · Xem"; "Ảnh mẫu bữa · Bữa trưa · chụp 10:30–11:30"; "Sổ lưu mẫu · Bữa trưa chưa ghi mẫu · Ghi"; không còn trạng thái nấu, nhận nguyên liệu, phiếu xuất kho.
- AC-16 (NUT-11) Bếp 04: tiêu đề "Bữa trưa · N suất đã xác nhận", "Định lượng hệ thống tính theo số suất"; nút "Xem cách chế biến"; không phiếu xuất kho.
- AC-17 (NUT-16, PAR-01) Ảnh mẫu bữa (mới): bếp cơ sở chụp mẫu suất thường + suất thay thế trong khung giờ, không tên trẻ, "Lưu ảnh mẫu".
- AC-18 (NUT-21) Sổ lưu mẫu (mới): bữa · món, khối lượng · dụng cụ chứa, nhiệt độ bảo quản, giờ lấy mẫu; ghi chú PHT dinh dưỡng duyệt, hủy sau ≥ 24 giờ; "Ghi lưu mẫu".
- AC-19: gỡ lối vào + route Bếp 05 Nhận nguyên liệu, 06 Báo thiếu, 07 Trạng thái nấu (NUT-11, NUT-12, NUT-22, NUT-14 REMOVED).
- Exit: `node scripts/verify.mjs` pass.

### Phase 5 — So màn giữ nguyên với Figma (G94-87)
- PH 02, 06, 07, 11, 13, 14, 15–19; GV 04, 05, 07, 09; Bếp 02, 03; BGH theo khung bản sửa `151:2`. Chụp App (dữ liệu giả) và Figma, sửa chỗ lệch nội dung/bố cục; ghi danh sách lệch vào Progress log.
- Exit: `node scripts/verify.mjs` pass.

### Phase 6 — Style phẳng và bố cục đúng Figma toàn App (G94-194)
- Files: M `lib/core/constants/{colors,shadows,sizes,app_icons}.dart`, `lib/core/theme/app_theme.dart`, `lib/core/widgets/*` (card, nút, ô nhập, banner, badge, chip, segmented, ô số, dải ngày, tìm kiếm), `lib/core/layouts/{app_shell,app_bottom_dock}.dart` (thêm `badges` cho số trên tab), `lib/routing/app_router.dart` (số chưa đọc tab GV/bếp từ dữ liệu giả); M màn mọi vai trò theo ảnh Figma; M `DESIGN.md` §4.1, §5.3–5.5, §7, §8.1, §9.2; ghi chú thay thế ở `docs/design/mobile-redesign-clay.md`.
- Cách so: build web (`flutter build web`), chạy tĩnh, chụp khổ 360×760 và so với ảnh khung Figma (link xem công khai, MCP Figma hết hạn mức gói Starter); ảnh để ngoài repo.
- Exit: `node scripts/verify.mjs` pass; `node scripts/check-ai-layer.mjs` pass.

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Đổi enum mức đánh giá dùng chung parent/teacher | Màn khác hiển thị sai nhãn | Grep mọi nơi dùng, chạy toàn bộ test | Revert commit phase |
| Nhánh tạo từ `dev`, chưa có code BGH (TBD-3) | Xung đột khi gộp | Không sửa màn BGH | — |

## Validation log
- [x] Khẳng định về code có `file:line`/file
- [x] Không đổi contract BE (chỉ dữ liệu giả)
- [x] Mỗi AC có test widget/unit ở phase
- [x] ≤3 phase; >8 file nhưng cùng mục tiêu UI theo Figma, user duyệt làm liền
- [x] Không dùng rule PENDING/OPEN như đã chốt

## Progress log
### 2026-11-13 — Plan được user duyệt (làm liền các phase)
- Commit: chưa commit

### 2026-11-13 — Phase 1 + 2 (chờ review)
- Xong AC-1..AC-14; mỗi AC có test "Redraw AC-n". `node scripts/verify.mjs` → `VERIFY PASS full | tests 191 fail 0 skip 0`; `node scripts/check-ai-layer.mjs` → 0 lỗi, 3 cảnh báo E7 có sẵn (glob rule `state.md`, `security-storage.md` chưa khớp file).
- Khác plan / quyết định khi làm: không hiện mã rule trong chữ cho người dùng (App chưa từng hiện); tiêu đề GV "Điểm danh & nhiệt độ" thay "& báo ăn" (ATT-02); trạng thái đơn "Đã gửi / Đã hủy"; ngày có đơn ở phụ huynh ghi "Vắng có phép"; khoảng nhiệt độ 34,0–42,0 °C chỉ cảnh báo nhập, không chặn lưu.
- Còn để ý: GV 04 (danh sách đánh giá, giữ nguyên) nối mọi câu trả lời nên hiện "Đạt · Đạt · …" 7 mục; chữ "báo ăn" còn ở `dev_preview`.
- Chưa so ảnh chụp màn hình với Figma.
- Commit: chưa commit

### 2026-11-13 — Phase 5 (so màn giữ nguyên với Figma, chờ review)
- Cách so: chạy App web (`flutter run -d web-server`, dữ liệu giả, khổ 360×760) và chụp Figma (link xem công khai) từng màn; ảnh chụp để ngoài repo.
- Đã sửa (test "Figma audit: …"):
  - PH 06, PH 11: ngày đo sức khỏe 05/10/2026 (thông báo 05/10 · 15:20, "Lần đo gần nhất · 05/10/2026").
  - PH 19: Đăng xuất hỏi lại "Đăng xuất khỏi CareNest?" với "Ở lại" / "Đăng xuất" (mọi vai trò; câu "thông báo của bé" chỉ cho phụ huynh).
  - GV 04: bé đã đánh giá hiện tóm tắt ngắn ("Đạt cả 7 mặt" hoặc mặt khác mức mặc định), không lặp 7 mức.
  - GV 09: bỏ nhãn "Ăn 1 bữa" (ATT-02).
  - Bếp 03: banner "09:05 · Mầm 3A +1 suất (giáo viên sửa điểm danh)", không "xin … chờ Phó HT duyệt" (NUT-04).
  - PHT 04: trạng thái "Chưa xác nhận — xác nhận trên CareNest Web" nằm dưới bảng, tông cảnh báo.
  - HT 01: thẻ cơ sở bỏ trạng thái bếp (NUT-14 REMOVED); việc chờ ghi "đã qua Phó HT · duyệt trên Web".
  - HT 02: đầu màn đếm "1 việc" như PHT 02.
- Giữ App (lệch có chủ đích): PH 02, PHT 01, HT 01 giữ bố cục user chọn 14/10 (`docs/design/mobile-redesign-clay.md`); HT 08 không nhãn CSVC (FAC REMOVED); PH 17 banner theo ngữ cảnh mở màn.
- Chưa sửa: chấm số chưa đọc trên tab Thông báo/Chờ xử lý (cần sửa `AppShell` vùng dùng chung + số chưa đọc từ nguồn thông báo); HT 02 không có lọc "Tất cả / Khen thưởng" (chỉ một loại việc); Bếp 02 nhóm Mầm chỉ có thực đơn thay thế dị ứng hải sản (Figma 02 và 03 lệch nhau về số suất thay thế nhóm Mầm, App giữ khớp Bếp 03); thông báo bếp/PHT "xin điều chỉnh +1 suất … chờ duyệt" (màn Thông báo ngoài danh sách so).
- Commit: chưa commit

### 2026-11-14 — Phase 6 bắt đầu (user: theo Figma toàn bộ, làm liền 4 vai trò)
- Đã đổi style dùng chung sang Figma phẳng (`lib/core`), Đăng nhập theo PH 01 bản sửa (logo + form trên nền, ô có icon điện thoại/khóa, nút xanh đặc, phiên bản ở đáy). `flutter test` → `All tests passed!` (219) sau khi đổi core; test style đổi tên `app_flat_style_test.dart`.
- Số trên tab: GV và bếp hiện số chưa đọc ở tab Thông báo (Figma GV 01, Bếp 01); PHT/HT "Chờ xử lý" chưa có số vì danh sách việc chờ tải bất đồng bộ ⇒ chờ BE có API đếm.
- Commit: chưa commit

### 2026-11-14 — Phase 6 xong (chờ review)
- Màn sửa theo Figma: PH 02–19 (PH 05, 09, 17 vốn đã khớp), GV 01–09 + Lịch hoạt động, Bếp 01–06, PHT 01/02/04/06/07/10/12, HT 01/02/04/06/07/08. Bỏ bố cục Clay đã chọn 14/10: PH 02 (thẻ ví), GV 01 (vòng tiến độ, việc trượt ngang), Bếp 01 (bố cục D), PHT 01 (mốc buổi sáng F), HT 01 (hai thẻ cơ sở D).
- Core theo đề nghị khi so ảnh: chip lọc đang chọn nền xanh đặc chữ trắng; segmented viên thuốc; avatar một chữ nền `primarySoft`; badge cao 24 chữ 12, bỏ chấm tông xanh; dòng danh sách tên 15/600, mô tả 13, đệm 12; ô icon việc 36; nhãn ô nhập 14/600; nút nhỏ đệm 16; dải xanh đặt icon thanh trạng thái trắng; bỏ `contentPadding` ở theme (bị cộng vào ô `isCollapsed`). Số trên tab: GV/bếp tab Thông báo, PHT/HT tab Chờ xử lý (đếm từ dữ liệu giả, tải một lần mỗi vai trò).
- Lệch Figma có chủ đích (nghiệp vụ đã chốt): không "báo ăn"/"Ăn 1 bữa"/"Ăn chay"/"Suất huỷ"; điểm danh có phần sức khỏe đầu ngày như Web nên thẻ bé cao hơn; đơn nghỉ không chọn buổi, trạng thái Đã gửi/Đã hủy; chi tiết thông báo không ảnh, không người gửi; đánh giá đủ 7 mặt; không mã rule trong chữ (bỏ "(ATT-04)"); BGH không nút ghi, HT 02 nhãn "Trả về"; HT 07 giữ dải ngày; Bếp 05 không nút thư viện ảnh và ô "+"; không CSVC.
- Còn chờ dữ liệu/BE: cách xưng hô "Chào thầy/cô" đang viết cứng; cờ dòng điều chỉnh ở PHT 04; giờ đón (GV 06), "Đổi bé" ở GV 07.1, đơn "mới" ở GV 03 chưa có field.
- `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 219 fail 0 skip 0`; `node scripts/check-ai-layer.mjs` → 0 lỗi (8 cảnh báo E2/E7 có sẵn). So ảnh: build web, chụp 44 màn khổ 360×760 cạnh ảnh khung Figma (ảnh ngoài repo).
- Commit: chưa commit
