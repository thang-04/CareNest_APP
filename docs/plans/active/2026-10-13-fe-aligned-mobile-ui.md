---
title: Thiết kế lại giao diện CareNest Mobile đồng bộ FE
status: approved
owner: CareNest APP team
jira: pending
branch: dev
modules: []
rules: [AUTH-07, ATT-05, PAR-02]
risk: high
created: 2026-10-13
updated: 2026-10-14
---
# Thiết kế lại giao diện CareNest Mobile đồng bộ FE

> Plan thiết kế làn L. Brief duyệt 2026-10-13; wireframe chọn 2026-10-14 (đặc tả ở `docs/design/mobile-redesign-clay.md`). User duyệt plan 2026-10-14 (Q1–Q5 theo đề xuất).

## Context

User muốn toàn bộ APP hiện đại, dễ đọc và cùng nhận diện với FE. APP có 52 file màn hình ở `lib/features/**/presentation/screens/` và 26 file widget ở `lib/core/widgets/` (kiểm kê 2026-10-13). Bộ màu, font và khoảng cách đã có: `lib/core/constants/colors.dart:6-40`, `lib/core/constants/sizes.dart:3-70`, `lib/core/theme/app_theme.dart:9-43`, `lib/core/theme/app_text_styles.dart:7`. FE có token ba tầng ở FE src/styles/tokens.css:1-9, màu thương hiệu và vai màu ở dòng 234-263, font ở dòng 169, bán kính card ở dòng 327. APP hiện dùng card bo 24 có bóng (`lib/core/widgets/app_card.dart:8-42`) và hero nền thương hiệu (`lib/core/widgets/app_hero_header.dart:8-24`); mockup gốc nằm ở `docs/design/figma/`. Đây là audit source và mockup, chưa phải quan sát runtime.

Plan UI mockup 5 vai trò đã hoàn thành ở `docs/plans/completed/2026-10-13-ui-mockup-redesign.md:29-36`; trạng thái hiện tại ghi dữ liệu giả, chưa nối API ở `docs/context/CURRENT_STATE.md`. `lib/routing/app_router.dart:73-142` chứa route của năm vai trò trong bản preview/debug. Repo đang ở branch `dev` và có thay đổi khác chưa commit; mọi đợt thực hiện phải giữ nguyên các file đó.

## Quyết định đã chốt

1. Brief: đồng bộ nhận diện FE, làm mới bố cục và thứ bậc thông tin cho APP; phạm vi gồm Phụ huynh, Giáo viên, Nhân viên bếp, Phó Hiệu trưởng, Hiệu trưởng và màn dùng chung — user, 2026-10-13.
2. Giữ màu xanh trời/mint, Be Vietnam Pro và các quy tắc nghiệp vụ hiện có; không tự thêm API, dependency, tính năng hay thay đổi quyền — user, 2026-10-13; `AGENTS.md`.
3. BGH gồm hai vai trò trong APP; dữ liệu hiện tại là giả và màn theo role ở bản debug — quyết định từ plan hoàn thành ngày 2026-10-13, cần giữ khi đổi giao diện.
4. Không sửa `DESIGN.md` §4 hoặc mã màu đã chốt chỉ để tạo cảm giác mới; lấy semantic token FE làm chuẩn đối chiếu. Mọi sai khác màu thực tế phải được nêu riêng trước khi thay — quyết định UI trước đó ở plan hoàn thành ngày 2026-10-13.
5. Dùng widget Flutter sẵn có, không tạo bộ Button/Card/Badge thứ hai. Đây là lựa chọn triển khai đề xuất từ audit, sẽ kiểm tra lại khi chọn wireframe.
6. Style **Clay nổi** cho toàn app và cho cả 13 thành phần (đầu màn, thanh tiêu đề, dòng danh sách, badge, nút, ô nhập, thẻ số, ô tiện ích, banner, rỗng/lỗi, thanh dưới, ô icon/avatar, chip/ngày) — user, 2026-10-14, chọn trên wireframe.
7. Bố cục: Phụ huynh Trang chủ **H · Thẻ ví xếp chồng các bé**; Hiệu trưởng Tổng quan **D · Hai cơ sở cạnh nhau** — user, 2026-10-14. Đặc tả: `docs/design/mobile-redesign-clay.md`; wireframe lưu ở `docs/design/wireframes/carenest-mobile-wireframe.html`.

## Làm rõ nghiệp vụ

- **Actor/outcome:** năm vai trò hiện có xem và thao tác trên cùng các màn/luồng như trước, với UI rõ ưu tiên hơn. Parent xem dữ liệu trẻ thuộc phạm vi được phép; Teacher thao tác theo lớp; Kitchen xem số suất đã chốt; BGH xem phạm vi trường/cơ sở theo quyền BE.
- **Rule:** `AUTH-07` (BE quyết định quyền, ẩn UI không cấp quyền), `ATT-05` (đơn nghỉ là thông báo), `PAR-02` (chỉ dữ liệu phụ huynh được phép xem). Các mục PENDING/OPEN trong `docs/architecture/NAVIGATION.md` không được biến thành quy tắc xác nhận qua mockup.
- **Flow:** `[S]` mở màn hiện có → đọc thông tin ưu tiên → dùng hành động/route hiện có. Không đổi `[B]` rule, API contract hay trạng thái dữ liệu.
- **Đối chiếu:** FE là React/CSS desktop; APP là Flutter mobile. Đồng bộ token, typography, vai màu, component và cảm giác thị giác; bố cục đáp ứng tác vụ trên điện thoại, không sao chép lưới desktop.
- **Ảnh hưởng:** `lib/core/` và màn hiện có theo vai trò; không sửa repo FE/BE. Không đưa dữ liệu thật hoặc ảnh trẻ vào wireframe, screenshot, fixture.

### Câu hỏi mở

- [x] Sau khi xem wireframe, user chọn phương án hoặc tổ hợp cụ thể — user, 2026-10-14 (Quyết định 6, 7).
- [x] Q1 — Sáu màn user chỉ chọn style, chưa chọn bố cục: dùng bố cục khuyên dùng (Đăng nhập A, Xin nghỉ D, GV Trang chủ D, Điểm danh A, Bếp D, PHT F)?
- [x] Q2 — Nền màn: giữ `AppColors.background` `#F1F9FE` (cùng FE) hay đổi sang `#E6F2FC` như wireframe Clay? Đổi là màu mới, đụng Quyết định 4.
- [x] Q3 — Nút có bóng/gờ đáy kiểu clay (FE đã có `--shadow-clay-btn`): sửa luật "Nút không bóng" ở `DESIGN.md` §5.5, §7.1, §9.2 và checklist?
- [x] Q4 — Bo card 24 → 28, thanh dưới và vùng nút đáy nổi cách mép 12, bo 28: sửa `DESIGN.md` §5.3, §7.1, §8.1 theo?
- [x] Q5 — `DESIGN.md` §8.5 ghi Trang chủ PH có "chip chọn con" và Đăng nhập có "Tranh": đổi theo bố cục mới (thẻ ví; Đăng nhập A không tranh) hay giữ tranh ở Đăng nhập (chọn B)?
- [x] User duyệt bản plan đã cập nhật trước khi bắt đầu Phase 1 code — user, 2026-10-14.

| Câu hỏi | Trả lời | Ai | Ngày | Tài liệu |
| --- | --- | --- | --- | --- |
| Brief 5 vai trò và nhận diện FE | Đồng ý | user | 2026-10-13 | Plan này, mục Quyết định đã chốt |
| Chọn wireframe | Style Clay toàn app; PH Trang chủ H; HT Tổng quan D | user | 2026-10-14 | `docs/design/mobile-redesign-clay.md` |
| Q1 bố cục 6 màn | Dùng khuyên dùng: Đăng nhập A, Xin nghỉ D, GV Trang chủ D, Điểm danh A, Bếp D, PHT F | user ("ok") | 2026-10-14 | Plan này |
| Q2 nền màn | Giữ `#F1F9FE`, không thêm màu | user ("ok") | 2026-10-14 | `DESIGN.md` §4.1 |
| Q3 bóng nút | Cho phép bóng/gờ clay; sửa luật "Nút không bóng" | user ("ok") | 2026-10-14 | `DESIGN.md` §5.5 |
| Q4 bo góc, thanh nổi | Card bo 28; thanh dưới và vùng nút đáy nổi cách mép 12, bo 28 | user ("ok") | 2026-10-14 | `DESIGN.md` §5.3, §8.1 |
| Q5 §8.5 phụ huynh | Trang chủ thẻ ví xếp chồng; Đăng nhập A không tranh | user ("ok") | 2026-10-14 | `DESIGN.md` §8.5 |

## Màn mẫu và việc chính

| Màn | Việc chính phải thấy trước | Hành động cuối giữ nguyên |
| --- | --- | --- |
| Đăng nhập | Nhận diện CareNest, form và trạng thái lỗi rõ ràng | Đăng nhập |
| Phụ huynh: Trang chủ | Bé đang chọn và thông tin hôm nay | Mở việc cần xem |
| Phụ huynh: Xin nghỉ | Ngày nghỉ, nội dung, trạng thái thông báo | Gửi thông báo |
| Giáo viên: Trang chủ | Lớp/ngày và việc đến hạn | Mở việc ưu tiên |
| Giáo viên: Điểm danh | Tổng số theo trạng thái và từng trẻ | Lưu điểm danh |
| Bếp: Trang chủ | Cơ sở/bữa, số suất đã chốt, việc còn chờ | Mở công việc |
| Phó Hiệu trưởng: Trang chủ | Cơ sở và việc cần xử lý | Mở danh sách chờ |
| Hiệu trưởng: Tổng quan | Toàn trường và mục cần duyệt | Mở mục cần duyệt |

Các màn mẫu là bộ kiểm tra ngôn ngữ thiết kế. Sau khi thống nhất, kiểm kê từng route còn lại và áp cùng contract component/trạng thái; không bỏ màn trong phạm vi năm vai trò.

## Hướng thiết kế để dựng wireframe

- Nền xanh trời rất nhạt, bề mặt trắng, chữ đậm đủ tương phản; xanh `brand` cho hành động chính, xanh `primary` cho link/trạng thái chọn, mint làm điểm nhấn phụ có nghĩa. Nguồn màu là FE `tokens.css` và `AppColors`, không thêm palette trang trí theo từng vai trò.
- Bớt dải hero xanh đặc và các card lặp khi chúng làm nội dung chính bị đẩy xuống; thử 2–3 cách tổ chức khác nhau ở wireframe. Đây là giả thuyết từ mockup và source, chỉ chốt sau khi nhìn bản vẽ.
- Dùng một họ card, button, field, badge, list row, bottom navigation, empty/loading/error trên cả năm vai trò. Màu trạng thái luôn kèm chữ hoặc icon. Giữ nút chính và tác vụ quan trọng trong vùng thao tác thuận tay trên mobile.
- Không áp hiệu ứng glass/clay lên mọi bề mặt. FE dùng chúng có chọn lọc; APP ưu tiên độ rõ chữ, độ tương phản, hiệu năng và SafeArea.
- Copy tiếng Việt theo nhãn hiện có. Mặc định chỉ làm light mode vì APP hiện có `buildLightTheme()` và `ThemeMode.light`; dark mode là yêu cầu riêng.

| Giả thuyết wireframe | Điểm mạnh | Đánh đổi |
| --- | --- | --- |
| A — FE gọn cho mobile (đề xuất) | Nền sáng, ít card lặp, thứ bậc việc chính rõ; giữ cảm giác FE | Cần chỉnh nhiều màn hero hiện có |
| B — FE giàu hình ảnh | Nhiều mảng pastel/ảnh hơn, hợp Phụ huynh | Màn tác nghiệp của Giáo viên/Bếp dễ dài và loãng |
| C — Ưu tiên thao tác | Danh sách và số liệu cô đọng, nhanh cho nhân viên | Trang Phụ huynh kém gần gũi hơn |

Ba hướng này chỉ là đầu bài cho bản vẽ có nội dung thật; user chọn từ wireframe, không chọn từ mô tả chữ.

## Acceptance criteria

- **AC-1 — Hướng thiết kế:** 2–3 wireframe khác bố cục thật cho mỗi màn mẫu; có dữ liệu giả nhất quán và các trạng thái có dữ liệu/đang tải/rỗng/lỗi khi áp dụng; user chọn trước khi code.
- **AC-2 — Đồng bộ FE:** bảng ánh xạ semantic token FE → Flutter nêu rõ màu, font, bán kính, khoảng cách, bóng và ngoại lệ mobile; không đổi mã màu `DESIGN.md` §4 khi chưa có quyết định mới.
- **AC-3 — Hệ widget:** mỗi kiểu card, button, field, badge, list row, trạng thái, bottom navigation có một implementation dùng lại; không có bản thứ hai trong feature.
- **AC-4 — Công việc chính:** tám màn mẫu đặt đúng thông tin và hành động ở bảng trên; các màn còn lại theo cùng nguyên tắc và không đổi nghiệp vụ/route.
- **AC-5 — Mobile:** không overflow ở 320/360/390/430 logical px, text scale 1.0/1.3/2.0; SafeArea, bàn phím, thanh đáy và tap target dùng được. Kiểm tra bằng widget test ở rủi ro cụ thể và ảnh runtime, không chỉ đọc source.
- **AC-6 — Trạng thái/riêng tư:** loading, empty, error, offline, 401/403/404 có cách hiển thị thống nhất; không có dữ liệu trẻ thật; không làm AI draft hoặc rule PENDING thành kết quả chính thức.
- **AC-7 — Kiểm chứng:** mỗi đợt có `node scripts/verify.mjs` sau lần sửa cuối, so ảnh trước/sau trên màn mobile và `node scripts/check-ai-layer.mjs` khi sửa docs. Lỗi nền có sẵn được ghi riêng; không tuyên bố pass khi lệnh fail.

## Key decisions

| Quyết định | Chọn/đề xuất | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Phạm vi nhận diện | Giữ token FE/CareNest, thay hierarchy và hình thức widget | Đổi bảng màu/brand | Đã có màu và font dùng chung; yêu cầu là đồng bộ FE |
| Cách chọn bố cục | 2–3 wireframe theo việc chính cho từng màn mẫu | Áp một layout cho mọi role | Tác vụ Parent, Teacher, Kitchen và BGH khác nhau |
| Phạm vi triển khai | Chia ba gói: nền + dùng chung/Parent; Teacher/Kitchen; BGH + rà soát | Một đợt sửa hơn 50 màn | Mỗi gói có thể review và xác minh độc lập |
| Kỹ thuật | Flutter/Material 3, widget hiện có, không thêm dependency | Thêm UI package mới | Giảm hai bộ component và rủi ro build |

## Phases

### Phase 0 — Wireframe và hợp đồng thị giác
- Files: chỉ scratchpad tạm cho wireframe theo `ui-ux`; sau khi user chọn, tạo tài liệu thiết kế trong `docs/design/` để lưu lựa chọn, token mapping, component/states và ảnh tham chiếu không chứa dữ liệu thật.
- Steps: dựng 2–3 wireframe khác bố cục cho từng màn mẫu; kiểm tra mobile width và text dài; trình user chọn từng màn hoặc chọn tổ hợp; cập nhật plan theo kết quả.
- Evidence: link/ảnh từng phương án, bảng lý do và điểm đánh đổi; xác nhận của user.
- Exit: user đã chọn wireframe và duyệt plan cập nhật. **Dừng chờ review; chưa code Flutter.**

### Phase 1a — Nền Clay và widget dùng chung
- Files: M `lib/core/constants/shadows.dart` (thêm `AppShadows.clay`, `clayButton`), `lib/core/constants/sizes.dart` (bo card theo Q4), `lib/core/constants/colors.dart` (chỉ khi Q2 = đổi nền), `lib/core/theme/app_theme.dart` (AppBar trong suốt, nút, segmented, navigation); M `lib/core/widgets/{app_card,app_button,app_status_badge,app_text_field,app_segmented,app_stat_tile,app_banner,app_filter_chip,app_state_view}.dart`; M `lib/core/layouts/{app_shell,app_bottom_dock}.dart`; M `DESIGN.md` §5.3, §5.5, §7.1, §8.1, §9.2 theo câu trả lời Q2–Q4. Không thêm package.
- Steps: dựng thành phần theo bảng "Thành phần Clay → Flutter" của `docs/design/mobile-redesign-clay.md`; bóng trong (inset) dựng bằng viền/gradient vì `BoxShadow` không hỗ trợ; giữ API công khai của widget để mọi màn hiện có tự đổi theo.
- Tests/evidence: widget test cho `AppCard`, `AppButton` (có/không bóng, disabled, loading), `AppShell` (thanh dưới nổi không che nội dung, SafeArea), overflow ở 320/390 và text scale 2.0; ảnh runtime một màn mỗi vai trò để thấy widget đổi đồng loạt.
- Exit: `node scripts/verify.mjs` PASS, `node scripts/check-ai-layer.mjs` 0 lỗi. **Dừng chờ user review.**

### Phase 1b — Màn dùng chung và Phụ huynh
- Files: M `lib/features/auth/presentation/screens/{login,forgot_password,otp_verify,new_password}_screen.dart`; `lib/features/parent_home/presentation/screens/parent_home_screen.dart` + widget trong `lib/features/parent_home/presentation/widgets/` (bố cục H); `lib/features/leave_notice/presentation/screens/{leave_notice_form,leave_notice_list}_screen.dart` (bố cục theo Q1); `lib/features/my_child/presentation/screens/*.dart`, `lib/features/parent_menu/presentation/screens/weekly_menu_screen.dart`, `lib/features/notifications/presentation/screens/*.dart`, `lib/features/account/presentation/screens/*.dart` (chỉ đổi sang thành phần Clay, giữ bố cục); M `DESIGN.md` §8.5 theo Q5; M `docs/features/parent/README.md` nếu mô tả màn đổi.
- Steps: Đăng nhập và Xin nghỉ theo bố cục chốt ở Q1; Trang chủ PH bố cục H (thẻ bé đang chọn, thẻ bé kia ló ra để đổi, từ 3 bé thì "+N bé" mở sheet chọn bé hiện có, một bé thì không có phần ló); giữ dữ liệu giả và route hiện có, không đổi logic đăng nhập.
- Tests/evidence: widget test Trang chủ PH với 1 / 2 / 3 bé và bốn trạng thái; Xin nghỉ: chọn khoảng ngày, nút gửi khoá khi thiếu; Đăng nhập: lỗi, đang gửi; ảnh runtime 320/390/430, so với wireframe đúng tham số.
- Exit: `node scripts/verify.mjs` PASS, ảnh đã xem cạnh wireframe. **Dừng chờ user review.**

### Phase 2 — Gói B: Giáo viên và Nhân viên bếp
- Files dự kiến: M các màn hiện có dưới `lib/features/{teacher_home,attendance,daily_review,class_roster,health_measure,pickup,meal_photos,kitchen_home,kitchen_meals,school_menu,food_quantities,ingredient_receipt,cooking_status}/`; chỉ sửa widget chung khi Phase 1 còn thiếu pattern được duyệt.
- Steps: hoàn thiện hai màn mẫu Teacher, một màn mẫu Kitchen; áp dụng sang màn cùng vai trò, giữ nhãn nghiệp vụ và trạng thái rule hiện có.
- Tests/evidence: widget tests cho điểm danh, số liệu dài/0/rỗng và màn danh sách; ảnh runtime 320–430 px, text scale; không tính suất/dị ứng ở client.
- Exit: `node scripts/verify.mjs` PASS và review ảnh các nhóm màn. **Dừng chờ user review.**

### Phase 3 — Gói C: BGH và đối chiếu toàn app
- Files dự kiến: M các màn hiện có dưới `lib/features/{vice_principal_home,principal_overview,approvals,meal_count_confirm,school_children,campuses,school_menu,nutrition_balance,reward_proposals}/`; M docs thiết kế/feature nếu giao diện thay đổi.
- Steps: hoàn thiện hai màn mẫu BGH; áp dụng các màn còn lại; quét toàn bộ route của năm vai trò để tìm component lệch, màn thiếu trạng thái, overflow và copy không nhất quán.
- Tests/evidence: widget tests rủi ro cụ thể; bảng đối chiếu màn/ảnh; xác nhận nhãn PENDING/PROPOSED không trở thành rule đã chốt.
- Exit: `node scripts/verify.mjs` PASS, `node scripts/check-ai-layer.mjs` exit 0 khi docs đổi, kiểm tra runtime và DoD làn L. **Dừng chờ user review.**

> Vì phạm vi hơn 8 file và hơn 3 phase, sau Phase 0 lập ba execution plan ngắn A/B/C từ wireframe đã chọn. Plan này giữ vai trò roadmap và cổng quyết định; không thi công đồng loạt.

## Test matrix

| AC | Bằng chứng/test | Phase | Kết quả |
| --- | --- | --- | --- |
| AC-1 | Wireframe 2–3 phương án/màn và xác nhận user | 0 | đạt — user chọn 2026-10-14; Q1 chờ xác nhận bố cục 6 màn |
| AC-2 | Bảng mapping FE/APP + đối chiếu source | 0–1 | chờ |
| AC-3 | Audit widget dùng lại + widget test trạng thái cần thiết | 1–3 | chờ |
| AC-4 | Checklist việc chính theo tám màn mẫu + ảnh runtime | 1–3 | chờ |
| AC-5 | Widget test overflow rủi ro + ảnh 320/360/390/430, scale 1.0/1.3/2.0 | 1–3 | chờ |
| AC-6 | Soát dữ liệu giả, nhãn quyền/trạng thái, empty/error/offline | 1–3 | chờ |
| AC-7 | Output `verify.mjs`, `check-ai-layer.mjs`, Progress log từng phase | 1–3 | chờ |

## Rủi ro & rollback

| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Mockup hiện tại và FE có khác biệt hình thức | APP đẹp riêng nhưng không đồng bộ | Mapping token và ảnh so sánh trước/sau tại Phase 0 | Trả về widget/theme gốc trong file của gói tương ứng sau khi user duyệt phương án |
| Sửa widget chung ảnh hưởng hơn 50 màn | Overflow hoặc đổi hierarchy ngoài ý muốn | Gói A thử trên màn mẫu, sau đó quét toàn route | Hoàn nguyên hẹp từng widget/file có lỗi; giữ nguyên phần user đang sửa |
| Rule/contract PENDING xuất hiện như đã xác nhận | Hiểu sai nghiệp vụ | Giữ mock data và status nhãn; không thêm hành vi | Bỏ thay đổi UI liên quan và ghi gap với BE |
| SDK Flutter trên PATH có thể cũ | Verify fail không liên quan UI | Chọn Flutter SDK đáp ứng `pubspec.yaml` trong process; ghi đúng output | Không đổi toolchain hoặc lockfile trong plan UI |
| Repo đang có file user sửa | Ghi đè công việc chưa commit | So diff từng phase; chỉ sửa file trong gói | Hoàn nguyên riêng thay đổi của phase, không reset/stash toàn repo |

## Validation log
- [x] Khẳng định về code có `file:line` và kiểm kê file tại ngày lập plan.
- [x] Không đổi BE contract; FE/BE chỉ đọc để đối chiếu.
- [x] Mỗi AC có evidence/test và mỗi phase có Exit.
- [x] >8 file/>3 phase: đã tách đề xuất thành ba execution plan sau Phase 0.
- [x] Không dùng rule PENDING/OPEN như đã chốt.
- [x] Tự review: không có quyết định layout giả định là đã duyệt; hai cổng còn mở ghi rõ.

## Progress log
### 2026-10-13 — Draft plan
- Commit: chưa commit.
- Verify: `node scripts/verify.mjs` với Flutter SDK 3.47.6 trong PATH của tiến trình → `VERIFY PASS full | format ok | analyze ok | tests 168 fail 0 skip 0 | 76s | log verify.log` (chạy trước khi ghi dòng log này; sẽ chạy lại sau lần sửa cuối).
- AI layer: `node scripts/check-ai-layer.mjs --only E5` → 0 lỗi; full check còn 3 lỗi E2 ở `docs/features/principal/README.md` và `docs/features/vice-principal/README.md` đã có từ trước plan này. Hai lỗi liên kết do bản plan nháp ban đầu tạo đã được sửa; lần check cuối còn đúng 3 lỗi nền.
- Khác plan: chưa có; user yêu cầu lập plan trước khi vẽ wireframe nên Phase 0 được ghi là cổng thiết kế.
- Tiếp: user review plan; dựng wireframe Phase 0, user chọn phương án; cập nhật plan rồi mới xin duyệt để code.

### 2026-10-13 — Phase 0: wireframe đã gửi
- Wireframe một file HTML ở scratchpad phiên (không thuộc repo): 8 màn mẫu × 3 phương án A/B/C, token lấy nguyên từ FE `tokens.css`/`AppColors`, có nấc Xám/Màu, Gọn chữ, Bỏ lặp, trạng thái có dữ liệu/đang tải/rỗng/lỗi. Phương án B dùng tranh FE (`hero-scene`, `login-scene`, `scenes/*`) — nếu chọn B cần chép ảnh vào `assets/` APP (~0,2–0,5 MB/ảnh).
- Kiểm: ảnh chụp 8 màn ở 1280 và trạng thái rỗng/lỗi/đang tải; không tràn ngang ở 375; probe của skill `ui-ux` chưa chạy được vì Chromium Playwright đang tải.
- Verify: chưa sửa code Flutter nên chưa chạy lại `verify.mjs`.
- Tiếp: user chọn phương án từng màn (cổng 2), cập nhật mục Quyết định đã chốt rồi xin duyệt plan trước Phase 1.

### 2026-10-13 — Phase 0: thêm style và trang từng mục
- User yêu cầu thêm lựa chọn, style hiện đại hơn và chi tiết từng mục vì redesign toàn bộ. Wireframe thêm 7 style chỉ đổi dáng (FE mềm, Clay nổi, Kính trên tranh, Gradient thương hiệu, Bento pastel, Tối giản, Đêm), áp được cho mọi màn × bố cục A/B/C, và trang "Từng mục" vẽ 13 thành phần ở cả 7 style. Màu brand và font giữ nguyên theo Quyết định 2; style Đêm là chế độ thêm, cần quyết định riêng nếu chọn.
- Kiểm: ảnh 7 style ở PH chủ, Bếp, Điểm danh và trang Từng mục; không tràn ngang ở 375, không lỗi JS.
- Tiếp: user chọn bố cục từng màn + style chung hoặc style từng mục.

### 2026-10-13 — Phase 0: concept trang chủ khác hẳn + nút tích chọn
- User nhận xét A/B/C của các màn trang chủ chỉ là biến thể của bố cục cũ. Thêm D/E/F cho 5 trang chủ, khác chiến lược: đối tượng chính làm thẻ lớn (bé / lớp / cơ sở, chạm tên để đổi thay cho nút "Đổi bé"), story các bé, bảng tin + nút nổi, hộp việc, đếm ngược một việc, chữ lớn cho bếp, tab theo bữa, checklist ca, duyệt từng thẻ, mốc giờ buổi sáng, hai cơ sở cạnh nhau, bản tin bằng câu.
- Thêm nút "✓ Chọn" và bảng "Đã chọn" (góc trên phải, lưu tạm trong trình duyệt) để user chép kết quả gửi lại.
- Sửa wireframe HT: bỏ ô và mục duyệt "Nghỉ phép nhân sự" vì `docs/features/principal/README.md` ghi H05 không làm.
- Kiểm: ảnh "Mọi bố cục" của 5 trang chủ; không tràn ngang ở 375; không lỗi JS.

### 2026-10-14 — Phase 0: concept khác hẳn cho Đăng nhập, Xin nghỉ, Điểm danh + G/H trang chủ PH, HT
- Thêm D/E/F: Đăng nhập (hai bước; quay lại bằng sinh trắc — cần thư viện và cách lưu token chưa chốt; tiêu đề lớn + ô gạch chân), Xin nghỉ (lịch tháng chọn khoảng ngày; ba bước có màn xem lại; hỏi đáp từng câu — không phải chat), Điểm danh (từng bé một thẻ; chỉ chọn bé vắng — mặc định có mặt cần BE thống nhất; tab Báo ăn theo bữa — BE tính tổng).
- Thêm G/H: Phụ huynh (lịch tuần của bé; thẻ ví xếp chồng các bé), Hiệu trưởng (bản đồ màu các lớp — ngưỡng màu chờ nhà trường chốt; thẻ chỉ số lớn có xu hướng 7 ngày — cần dữ liệu 7 ngày).
- Kiểm: ảnh các màn ở "Mọi bố cục"; không tràn ngang ở 375 (cả trạng thái lỗi, rỗng, style Tối giản, Gradient); không lỗi JS.

### 2026-10-14 — Phase 0: user chọn wireframe
- User chọn: style Clay nổi toàn app và cho cả 13 thành phần; PH Trang chủ bố cục H; HT Tổng quan bố cục D. Sáu màn còn lại chỉ chọn style ⇒ tạm dùng bố cục khuyên dùng, chờ xác nhận (Q1).
- Lưu đặc tả `docs/design/mobile-redesign-clay.md` và wireframe `docs/design/wireframes/` (tranh/logo FE, không dữ liệu trẻ thật) vì bản ở scratchpad là tạm.
- Phát hiện lệch `DESIGN.md`: nền Clay `#E6F2FC` khác token, nút có bóng trái luật "Nút không bóng", bo card 28 và thanh dưới nổi, §8.5 (chip chọn con, tranh ở Đăng nhập). Ghi thành Q2–Q5, chưa sửa `DESIGN.md`.
- Tách Phase 1 thành 1a (nền + widget dùng chung) và 1b (màn dùng chung + Phụ huynh) vì mỗi phần đã hơn 8 file.
- Verify: chưa sửa code Flutter.
- Tiếp: user trả lời Q1–Q5 và duyệt plan ⇒ mới bắt đầu Phase 1a.

### 2026-10-14 — Phase 1a: nền Clay và widget dùng chung
- Commit: chưa commit.
- Sửa: `lib/core/constants/{shadows,sizes}.dart`, `lib/core/theme/app_theme.dart`, `lib/core/widgets/{app_card,app_button,app_status_badge,app_text_field,app_segmented,app_stat_tile,app_banner,app_filter_chip,app_day_strip}.dart`, `lib/core/layouts/{app_shell,app_bottom_dock}.dart`; `DESIGN.md` §5.3, §5.5, §7.1, §8.1, §9.2 và checklist. Thêm `test/core/widgets/app_clay_style_test.dart` (bóng nút theo trạng thái, badge không viền, vùng nút đáy nổi ở 320 + chữ x2).
- Khác plan: thêm `app_day_strip.dart` (ô ngày thuộc mục "Chip lọc & chọn ngày" user chọn); `app_state_view.dart` không cần sửa; `colors.dart` không sửa (Q2 giữ nền). `AppStatTile` bo 14 → 16 theo wireframe.
- Verify: `node scripts/verify.mjs` (Flutter 3.47.6 trong PATH tiến trình) → `VERIFY PASS full | format ok | analyze ok | tests 172 fail 0 skip 0 | 102s`; `node scripts/check-ai-layer.mjs` → 0 lỗi, 3 cảnh báo E7 có từ trước.
- Runtime: chụp bản web debug ở 390px các route `/parent`, `/teacher`, `/teacher/attendance`, `/kitchen`, `/vice-principal`, `/principal` — widget Clay đổi đồng loạt, không lỗi trang. Bố cục (dải hero xanh, danh sách cũ) chưa đổi: thuộc 1b/2/3. Chưa chụp 320/430 và chữ x1,3/x2 bằng ảnh runtime; chữ x2 ở 320 mới có widget test.
- Ghi chú: `pubspec.lock` đã ở trạng thái sửa từ trước phiên (nâng bản vá của gói test); lượt này không chủ động đổi.
- Tiếp: **dừng chờ user review** Phase 1a, rồi Phase 1b.

### 2026-10-14 — Phase 1b: màn dùng chung và Phụ huynh
- Commit: chưa commit.
- Sửa: Đăng nhập bố cục A (`lib/features/auth/presentation/screens/login_screen.dart`: logo trong ô trắng, form trong `AppCard`, bỏ icon trái theo wireframe); Trang chủ PH bố cục H (`lib/features/parent_home/presentation/screens/parent_home_screen.dart`, `.../widgets/parent_home_cards.dart`: thẻ bé đang chọn, bé khác ló ra, "+N bé khác" mở sheet, Việc nhanh); Xin nghỉ bố cục D (`lib/features/leave_notice/presentation/screens/leave_notice_form_screen.dart`; `lib/core/widgets/app_month_calendar.dart` thêm chọn khoảng ngày + khoá ngày, API cũ giữ nguyên). Docs: `DESIGN.md` §8.1, §8.5; `docs/features/parent/README.md`.
- Tests: viết lại `test/features/parent_home/parent_home_screen_test.dart` (1/2/3 bé, rỗng, lỗi, đang tải, khổ 320, chữ x2); thêm test bố cục A ở `test/features/auth/login_screen_test.dart`; thêm 3 test lịch ở `test/features/leave_notice/leave_notice_list_screen_test.dart` (chọn khoảng, ngày đã qua khoá, chấm ngày đã báo nghỉ) và cho test cũ cuộn tới phần dưới form.
- Khác plan: màn PH và màn dùng chung khác (bé của tôi, thực đơn, thông báo, tài khoản, quên mật khẩu) không sửa file — đã nhận Clay qua widget dùng chung ở 1a. Thẻ bé không hiện giờ bữa trưa/giờ hoạt động như wireframe vì `ParentToday` không có field đó; bé đang ló không hiện trạng thái điểm danh (cần gọi thêm dữ liệu). Nút gửi giữ "Gửi đơn xin nghỉ" (không đếm số ngày ở APP).
- Bug: lời chào và chuông gộp một nút semantics ⇒ incident `docs/knowledge/incidents/APP-BUG-261014-greeting-bell-semantics-merge.md` + 1 dòng `ISSUE_INDEX.md` + Known pitfalls PH.
- Verify: `node scripts/verify.mjs` (Flutter 3.47.6 trong PATH tiến trình) → `VERIFY PASS full | format ok | analyze ok | tests 179 fail 0 skip 0 | 25s`.
- Runtime: bản web debug, ảnh 320/390/430 của `/login`, `/parent`, `/parent/leave-notices/new` đã xem; sửa logo nền trắng, dải ba ô và ô Việc nhanh ở khổ 320, chụp lại. Chữ phóng lớn chỉ kiểm bằng widget test (x2), chưa có ảnh runtime.
- Tiếp: **dừng chờ user review** Phase 1b, rồi Phase 2 (GV, Bếp).

### 2026-10-14 — Phase 2: Giáo viên và Nhân viên bếp
- Commit: chưa commit.
- Sửa: GV Trang chủ bố cục D (`lib/features/teacher_home/presentation/screens/teacher_home_screen.dart`; `domain/teacher_today.dart` thêm `attendanceRecorded` do BE trả, `data/fake_teacher_home_source.dart`); Điểm danh bố cục A (`lib/features/attendance/presentation/screens/attendance_screen.dart`: dòng lớp trơn, badge khoá cam; `widgets/attendance_kid_row.dart`: dòng bé và nút Có mặt/Vắng dáng Clay); Bếp Trang chủ bố cục D (`lib/features/kitchen_home/presentation/screens/kitchen_home_screen.dart`: số suất chữ lớn, thẻ tiến độ nấu bốn bước `CookingStage`). Widget dùng chung mới: `AppFeaturedCard` (trong `lib/core/widgets/app_card.dart`, dùng lại cho thẻ bé PH) và `lib/core/widgets/app_progress_ring.dart`. Docs: `docs/features/teacher/README.md`, `docs/features/kitchen/README.md`.
- Tests: `test/features/teacher_home/teacher_home_screen_test.dart` (thẻ lớp, vòng, hạn, Việc tiếp theo, rỗng 28/28); K01 trong `test/features/kitchen_meals/kitchen_meals_screen_test.dart` (số suất, bước nấu, không lặp việc cập nhật). Test Điểm danh hiện có vẫn pass.
- Khác plan/wireframe: GV không có chuông (bản cũ cũng không; thông báo ở tab); Bếp chỉ hiện Thường/Thay thế, chưa tách theo chế độ ăn (thiếu dữ liệu); Bếp bỏ lời chào theo wireframe D; danh sách bé điểm danh vẫn mỗi bé một thẻ trong list lười (giữ ảo hoá theo `.claude/rules/component.md`) thay vì một card chia dòng. Các màn GV/Bếp khác nhận Clay qua widget dùng chung; viền còn lại trong màn là viền trạng thái (ô chọn, nút chụp), giữ nguyên.
- Verify: `node scripts/verify.mjs` (Flutter 3.47.6 trong PATH tiến trình) → `VERIFY PASS full | format ok | analyze ok | tests 180 fail 0 skip 0 | 21s`.
- Runtime: bản web debug, ảnh 320/390/430 của `/teacher`, `/teacher/attendance`, `/kitchen` đã xem; sửa nhãn nút tiến độ nấu bị cắt ở 320 ("Cập nhật trạng thái"). Chữ phóng lớn kiểm bằng widget test x2.
- Tiếp: **dừng chờ user review** Phase 2, rồi Phase 3 (PHT bố cục F, HT bố cục D, rà toàn app).

### 2026-10-14 — Phase 3: BGH và rà toàn app
- Commit: chưa commit.
- Sửa: PHT Trang chủ bố cục F (`lib/features/vice_principal_home/presentation/screens/vice_principal_home_screen.dart`: thẻ mốc buổi sáng, "Chờ duyệt (n)" từng yêu cầu, "Theo dõi khác"; `domain/campus_today.dart` thêm `MorningStep`, `CampusPendingItem`, `date`; `data/fake_campus_today_source.dart`). HT Tổng quan bố cục D (`lib/features/principal_overview/presentation/screens/principal_overview_screen.dart`: hai thẻ cơ sở có vòng có mặt, suất đã chốt, bếp; `domain/school_overview.dart` thêm `CampusSnapshot`; `data/fake_school_overview_source.dart`). Rà toàn app: thẻ danh sách còn dáng phẳng ⇒ Clay (bo 20, mép sáng, bóng card; viền màu trạng thái giữ) ở `notifications_screen.dart`, `class_leave_screen.dart`, `ingredient_receipt_screen.dart`, `cooking_status_screen.dart`; vệt chạm thẻ thực đơn HT bo theo card. Docs: `docs/features/vice-principal/README.md`, `docs/features/principal/README.md`, `DESIGN.md` §7.1 (dòng Đầu trang chủ).
- Tests: `test/features/vice_principal/vice_principal_screens_test.dart` (mốc, sau khi chốt suất, rỗng); `test/features/principal/principal_screens_test.dart` (hai thẻ cùng hàng, khổ 320). AC-10 chữ x2 của mọi màn BGH vẫn pass.
- Khác wireframe: PHT giữ mục "Theo dõi khác" (bếp, thực đơn, trẻ) vì ba màn này chỉ mở được từ Trang chủ; HT giữ thanh đánh giá và thêm mục "Toàn trường" (trẻ, thực đơn, cơ sở) để không mất đường vào H06/H07/H08; không có chuông (thông báo ở tab); badge bếp HT chỉ ghi trạng thái + icon bếp cho vừa khổ 320; badge "Suất ăn" ở PHT đổi xanh cho khớp tab Duyệt. Dòng mốc tự dựng, không dùng `AppTimeline` (thiếu trạng thái xong, badge, nút). Mốc giờ và số theo cơ sở là đề xuất BE (PROPOSED).
- Còn lại: `AppHeroHeader` không còn màn nào dùng (vẫn có test widget) — chờ user quyết xoá hay giữ.
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 183 fail 0 skip 0 | 26s`.
- Runtime: bản web debug, ảnh 320/390/430 của `/vice-principal`, `/principal`; ảnh 390 của 14 route rà (BGH, thông báo GV, đơn nghỉ lớp, nhận nguyên liệu, trạng thái nấu). Sửa sau ảnh: cột giờ mốc bị ngắt dòng, nút "Xem & chốt" bị cắt ở 320, badge bếp xuống dòng ở 320.
- Tiếp: **dừng chờ user review** Phase 3; xong thì chuyển plan sang `completed/` khi user đồng ý.
