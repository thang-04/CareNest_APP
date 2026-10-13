---
title: Dựng lại UI CareNest Mobile theo wireframe đã chọn
status: done
owner: ATPX48-69
jira: none
branch: dev
modules: []
rules: [AUTH-03, AUTH-04, AUTH-05, AUTH-07, ATT-01, ATT-02, ATT-03, ATT-04, ATT-05, NUT-01, NUT-02, NUT-08, PAR-01, PAR-02, HLT-06]
risk: high
created: 2026-10-10
updated: 2026-10-13
---
# Dựng lại UI CareNest Mobile theo wireframe đã chọn

## Context
User yêu cầu xóa toàn bộ UI hiện có và thiết kế lại (2026-10-10). Đã qua hai cổng thiết kế:
- Cổng 1 (brief + việc chính từng màn): user đồng ý 5 điểm mặc định, đã thêm logo `assets/image/Logo.jpg`.
- Cổng 2 (wireframe HTML, 6 màn × 2 phương án): user chọn **Đăng nhập B · Phụ huynh Hôm nay A · Báo nghỉ B · Giáo viên Hôm nay A · Điểm danh A · Bếp Suất ăn A**.

Hiện trạng code:
- 2 màn: `lib/features/home/presentation/screens/home_screen.dart` (giữ chỗ, 43 dòng), `lib/features/ui_kit/presentation/screens/ui_kit_screen.dart` (388 dòng).
- 11 widget ở `lib/core/widgets/`. Theme ở `lib/core/theme/`.
- Router `lib/routing/app_router.dart:11` chỉ có `/` và `/ui-kit` (debug).
- Màu `lib/core/constants/colors.dart:6-16` (primary `#1565E0`) **lệch** `DESIGN.md` §4.1 (brand `#4FB0F5`, primary `#0B72BC`, cùng mã web). Cổng 1 chốt theo `DESIGN.md`.
- `lib/core/constants/sizes.dart:9` còn `space7 = 32`, DESIGN §5.2 yêu cầu `space8`. Bo góc `sizes.dart:15-19` khác thang §5.3.

Wireframe (tham chiếu bố cục, khoảng cách, chữ) nằm ở scratchpad của phiên, ngoài repo. Plan chép lại nội dung từng màn ở mục Phases để không phụ thuộc file đó.

## Quyết định đã chốt
1. Xóa `lib/core/widgets/*`, `lib/core/theme/*`, `features/home`, `features/ui_kit` + test đi kèm; giữ `go_router`, `lib/core/config/env.dart`, font, cấu trúc thư mục — user, 2026-10-10.
2. Màu theo `DESIGN.md` §4.1–4.2, tông badge §6.1; font Be Vietnam Pro — user, 2026-10-10.
3. Phạm vi đợt 1: 6 màn trên + khung tab cho Phụ huynh, Giáo viên, Bếp; Bếp chỉ xem — user, 2026-10-10.
4. Dữ liệu giả tĩnh; không nối API, không thêm Riverpod/Dio/thư viện mới — user, 2026-10-10.
5. Hero chưa có tranh ⇒ khối màu nhạt chừa chỗ; logo dùng `assets/image/Logo.jpg` — user, 2026-10-10.
6. Phương án bố cục theo cổng 2 (xem Context) — user, 2026-10-10.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:**
  - Actor: Phụ huynh / Giáo viên / Nhân viên bếp.
  - Outcome: thấy và thao tác trên giao diện mới với dữ liệu giả. Không đổi nghiệp vụ, không gọi BE.
  - Rule: AUTH-03/04 (CONFIRMED), AUTH-05 (CONFIRMED), AUTH-07 (ACCEPTED), ATT-01..05 (CONFIRMED), NUT-01 (CONFIRMED), NUT-02 (CONFIRMED; người xác nhận PENDING P-05), NUT-08 (CONFIRMED), PAR-01 (CONFIRMED), PAR-02 (ACCEPTED), HLT-06 (CONFIRMED / P-17 PENDING) — nguồn `BE:docs/business/BUSINESS_RULES.md:15-98`.
  - Flow: [S] mở app → Đăng nhập (chưa có auth: nút không gọi API) → màn theo role.
- **Đối chiếu thiết kế ban đầu:**
  - `docs/architecture/NAVIGATION.md` ghi màn phụ thuộc PENDING **[P] chưa đăng ký route cho tới khi chốt (hoặc bật bằng cờ)**. Các màn trong đợt này phụ thuộc P-13b (Phụ huynh Hôm nay), P-03/P-04 (Điểm danh), P-05/P-06 (Bếp) ⇒ xem Câu hỏi 1.
  - `DESIGN.md` §7.4 yêu cầu có UiKitScreen; quyết định 1 xóa UiKit cũ ⇒ xem Câu hỏi 3.
  - `DESIGN.md` §3.1 ghi logo ở `assets/brand/logo-full.png`; file thật là `assets/image/Logo.jpg` ⇒ xem Câu hỏi 4.
- **Ảnh hưởng:**
  - APP: toàn bộ `lib/core/{constants,theme,widgets,layouts}`, `lib/routing/*`, 6 màn mới, test.
  - Không đổi BE contract. FE không bị ảnh hưởng: token đã trùng mã web.
  - Không có dữ liệu cũ.

### Câu hỏi mở
- [x] Q1. Màn phụ thuộc PENDING đăng ký route thế nào?
- [x] Q2. Từ màn Đăng nhập vào màn theo role thế nào khi chưa có auth?
- [x] Q3. UiKitScreen: dựng lại hay bỏ?
- [x] Q4. Logo: giữ đường dẫn `assets/image/Logo.jpg` hay đổi sang `assets/brand/`?
- [x] Q5. Tab ngoài phạm vi (Bé, Thông báo, Tài khoản, Lớp…) hiển thị gì?
- [x] Q6. Giữ 1 plan 4 phase (dừng review sau mỗi phase) hay tách thành 2 plan (nền + màn)?

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Q1 + Q2 | Màn theo role chỉ đăng ký khi `enablePreview` (mặc định `kDebugMode`); màn Đăng nhập bản debug có link "Xem thử theo vai trò" → chọn Phụ huynh / Giáo viên / Bếp. Release chỉ có Đăng nhập. | user | 2026-10-10 | `docs/architecture/NAVIGATION.md` (Phase 2) |
| Q3 | Bỏ UiKitScreen. Sửa `DESIGN.md` §7.4 và các chỗ nhắc UiKitScreen; ghi đề xuất đồng bộ Design System bên FE (không sửa repo FE). | user | 2026-10-10 | `DESIGN.md` §7.4 (Phase 1) |
| Q4 | Giữ `assets/image/Logo.jpg`, khai báo một chỗ ở `AppAssets`. | user | 2026-10-10 | `DESIGN.md` §3.1 ghi đường dẫn thật (Phase 1) |
| Q6 | Giữ 1 plan 4 phase, dừng review sau mỗi phase. User duyệt plan. | user | 2026-10-10 | — |
| Q5 | Hiện đủ 4 tab; tab chưa làm mở màn "Sắp có" (trạng thái rỗng: "Tính năng này sẽ có trong bản sau"). | user | 2026-10-10 | — |

## Acceptance criteria
- **AC-1** (DESIGN §4.1): Given theme mới, When build app, Then `ColorScheme.primary` = `#4FB0F5`, `onPrimary` = `#0E3F63`, nền Scaffold = `#F1F9FE`, font `BeVietnamPro`, chỉ Light theme.
- **AC-2** (DESIGN §6.1): Given 7 tông badge, When đo tương phản chữ/nền, Then mỗi cặp ≥ 4.5:1.
- **AC-3** (Đăng nhập B): Given màn Đăng nhập, Then có logo, ô "Số điện thoại hoặc tên đăng nhập", ô "Mật khẩu" (ẩn/hiện), "Quên mật khẩu?", nút "Đăng nhập"; không có đăng ký. Trạng thái đang gửi khóa nút; trạng thái lỗi hiện banner và giữ nội dung đã nhập.
- **AC-4** (PAR-01, AUTH-04): Given dữ liệu giả của một con, When mở Phụ huynh · Hôm nay, Then thứ tự là hero (lời chào, ngày, chip chọn con) → card Điểm danh (badge theo dữ liệu) → card Bữa ăn hôm nay → card Cập nhật mới → nút "Báo nghỉ cho bé". Chip mở sheet chọn con. Có đủ trạng thái đang tải / rỗng / lỗi.
- **AC-5** (ATT-05): Given danh sách thông báo nghỉ giả, When mở Thông báo nghỉ, Then có segmented "Đã gửi / Đã hủy", badge `blue` "Đã gửi" / `gray` "Đã hủy", **không có chữ "chờ duyệt"** ở bất kỳ đâu. Nút dính đáy "Báo nghỉ mới" mở sheet form (chip ngày, Từ/Đến, chip lý do, ghi chú, nút "Gửi thông báo nghỉ"). Khi danh sách rỗng hiện trạng thái rỗng có lời mời gửi.
- **AC-6** (ATT-01, ATT-02, ATT-03, ATT-04, NUT-01): Given lớp giả 15 trẻ, When mở Điểm danh, Then:
  - Mỗi dòng có tên, trạng thái (Có mặt / Có phép / Không phép / Chưa nhập) lấy từ dữ liệu, và ô "Ăn".
  - Trẻ có thông báo nghỉ hiện lý do dưới tên. Trạng thái có phép và ăn = không là dữ liệu đã có sẵn, không phải APP tự tính.
  - Bấm trạng thái mở sheet để đổi. Lọc "Chưa nhập" và "Vắng" hoạt động.
  - Có một nút "Lưu điểm danh". Trạng thái lỗi giữ nguyên lựa chọn.
  - Không có số suất ăn nào do APP tính.
- **AC-7** (AUTH-03): Given dữ liệu giả lớp Mầm 2, When mở Giáo viên · Hôm nay, Then card "Điểm danh và báo ăn" hiện số trẻ chưa nhập từ dữ liệu và nút "Tiếp tục điểm danh" dẫn tới màn Điểm danh. Card "Nghỉ có báo hôm nay" liệt kê trẻ. Ngày trường nghỉ hiện banner xám.
- **AC-8** (AUTH-05, NUT-02, HLT-06): Given dữ liệu bếp giả, When mở Bếp · Suất ăn hôm nay, Then:
  - Bữa đã chốt hiện tổng suất + badge "Đã chốt <giờ>" + dòng theo điểm trường.
  - Bữa chưa chốt hiện badge "Chưa chốt" và **không hiện số**.
  - Dị ứng hiện bằng chữ + icon, kèm lớp và số suất, **không có tên trẻ**.
- **AC-9** (NAVIGATION [P]): Given bản release (`kDebugMode == false`), When dựng router, Then chỉ đăng ký các route đã được phép theo Q1/Q2.
- **AC-10** (DESIGN §5.1): Given text scale 2.0, When render 6 màn ở khổ 360×800, Then không có lỗi tràn layout.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Bố cục từng màn | Theo cổng 2 | Phương án còn lại trong wireframe | User chọn sau khi xem wireframe có dữ liệu |
| State cho màn | `StatefulWidget` + dữ liệu giả hằng số | Riverpod (PROPOSED) | Quyết định 4: chưa thêm thư viện; đổi sau không ảnh hưởng widget trình bày |
| Nơi đặt dữ liệu giả | `features/<f>/data/fake_<f>_data.dart`, trả model presentation | Hard-code trong widget | Màn chỉ nhận model nên lúc nối API chỉ thay nguồn dữ liệu |
| Icon | `AppIcons` ánh xạ `Icons.*_rounded` (DESIGN §7.2 ngoại lệ tạm) | Thêm gói Tabler | Gói Tabler còn OPEN, không thêm dependency |
| Avatar tông 0 (`#0B72BC`/`#E2F2FD` = 4.43:1) | Giữ token DS; chữ avatar là trang trí, có tên bên cạnh | Tự đổi màu | Token chung web/app, đổi phải qua Design System |

## Phases
Mỗi phase dừng chờ user review.

### Phase 1 — Nền: xóa UI cũ, token, theme, widget chung, UiKit
- **Files:**
  - D: `lib/core/widgets/**`, `lib/core/theme/*`, `lib/features/home/**`, `lib/features/ui_kit/**`, test tương ứng (`test/core/**`, `test/features/ui_kit/**`).
  - M: `lib/core/constants/colors.dart` (theo §4.1, §4.2, §6.1, avatar §7.3), `lib/core/constants/sizes.dart` (§5.2–5.4, bỏ `space7`), `pubspec.yaml` (khai báo asset logo).
  - C: `lib/core/constants/{motion,app_icons,asset_paths,shadows}.dart`, `lib/core/theme/{app_theme,app_text_styles,app_status_colors}.dart`.
  - C `lib/core/widgets/`: `app_button`, `app_text_field` (một dòng, nhiều dòng, mật khẩu, ô ngày), `app_card`, `app_status_badge`, `app_filter_chip`, `app_segmented`, `app_banner`, `app_avatar`, `app_list_row`, `app_context_chip`, `app_bottom_sheet`, `app_state_view` (rỗng / lỗi), `app_skeleton`, `app_loading_dots`, `app_submit_overlay`, `brand/app_logo`.
  - M: `DESIGN.md` §7.4, §3.1, §1 (bỏ UiKitScreen, ghi đường dẫn logo thật) theo Q3, Q4.
- **Steps:**
  1. Xóa file cũ.
  2. Viết token, rồi theme (ColorScheme ánh xạ §4.3), rồi widget.
  3. Sửa `DESIGN.md` theo Q3, Q4; chạy `node scripts/check-ai-layer.mjs`.
  4. Viết test.
- **Tests:** AC-1 → `test/core/theme/app_theme_test.dart`; AC-2 → `test/core/constants/colors_contrast_test.dart`; widget → `test/core/widgets/*_test.dart` (nút khóa khi loading, badge đủ 7 tông, segmented đổi chọn, sheet mở/đóng).
- **Exit:** `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0.

### Phase 2 — Khung app, điều hướng, Đăng nhập B
- **Files:**
  - M: `lib/routing/{app_router,route_paths}.dart`, `lib/app.dart`.
  - C: `lib/core/layouts/app_shell.dart` (thanh đáy 4 tab theo role, DESIGN §8.1), `lib/core/layouts/app_bottom_dock.dart`, `lib/features/auth/presentation/screens/login_screen.dart`, `lib/features/dev_preview/presentation/screens/role_preview_screen.dart` (Q1/Q2, chỉ debug), `lib/core/widgets/app_coming_soon.dart` (Q5).
  - M: `docs/architecture/NAVIGATION.md` (route thật + cờ `enablePreview`).
- **Bố cục Đăng nhập B:**
  - Nền trắng, một cột lề 24.
  - Logo đầy đủ 168×168 ở giữa → "Đăng nhập" 22/700 → "Trường Mầm non Thượng Hồng" 14 muted.
  - 2 ô nhập cao 52 bo viên thuốc, nhãn trên → "Quên mật khẩu?" dạng nút chữ căn phải → nút chính "Đăng nhập" full width → dòng "Chưa có tài khoản? Liên hệ nhà trường để được cấp."
  - Handler `onSubmit` / `onForgotPassword` để rỗng: chờ AUTH_CONTRACT.
- **Tests:** AC-3 → `test/features/auth/login_screen_test.dart`; AC-9 → `test/routing/app_router_test.dart`.
- **Exit:** `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0.

### Phase 3 — Phụ huynh: Hôm nay A + Thông báo nghỉ B
- **Files:** C `lib/features/parent_home/{data/fake_parent_home_data.dart,presentation/screens/parent_home_screen.dart,presentation/widgets/*}`, C `lib/features/leave_notice/{data/fake_leave_notice_data.dart,presentation/screens/leave_notice_list_screen.dart,presentation/widgets/leave_notice_form_sheet.dart}`, M router.
- **Bố cục:** như AC-4, AC-5. Dữ liệu giả: chị Hoa, con Nguyễn Minh An (Mầm 2) và Nguyễn Hoàng Bảo Ngọc (Lá 1), ngày Thứ Hai 12/10/2026, đến lớp 7:42, 3 bữa, 2 cập nhật, 3 thông báo nghỉ.
- **Tests:** AC-4 → `test/features/parent_home/parent_home_screen_test.dart`; AC-5 → `test/features/leave_notice/leave_notice_list_screen_test.dart` (kể cả tìm không thấy chữ "chờ duyệt"); AC-10 phần màn phụ huynh.
- **Exit:** `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0.

### Phase 4 — Giáo viên Hôm nay A + Điểm danh A + Bếp A
- **Files:** C `lib/features/teacher_home/**`, `lib/features/attendance/**`, `lib/features/kitchen_meals/**` (mỗi feature có `data/fake_*.dart` + `presentation/screens` + `presentation/widgets`), M router.
- **Bố cục:** như AC-6, AC-7, AC-8. Dữ liệu giả khớp nhau:
  - Lớp Mầm 2 có 15 trẻ: 8 có mặt, 2 có phép, 1 không phép, 4 chưa nhập.
  - Bếp: trưa 273 suất (Điểm trường 1: 141, Điểm trường 2: 132), sáng đã chốt, chiều chưa chốt.
  - Dị ứng: hải sản 2, sữa bò 1, trứng 3.
- **Tests:** AC-6 → `test/features/attendance/attendance_screen_test.dart`; AC-7 → `test/features/teacher_home/teacher_home_screen_test.dart`; AC-8 → `test/features/kitchen_meals/kitchen_meals_screen_test.dart`; AC-10 phần còn lại.
- **Exit:** `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0. Cập nhật `docs/context/CURRENT_STATE.md`, `DESIGN.md` §7.1 (danh sách widget đã có), `docs/architecture/NAVIGATION.md` (route thật).

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | DESIGN §4.1 | `app_theme_test.dart` (unit/widget) | 1 | pass |
| AC-2 | DESIGN §6.1 | `app_theme_test.dart` (unit) | 1 | pass |
| AC-3 | — | `login_screen_test.dart` (widget) | 2 | pass |
| AC-9 | NAVIGATION [P] | `app_router_test.dart` (widget) | 2 | pass |
| AC-4 | PAR-01, AUTH-04 | `parent_home_screen_test.dart` (widget) | 3 | pass |
| AC-5 | ATT-05 | `leave_notice_list_screen_test.dart` (widget) | 3 | pass |
| AC-6 | ATT-01..04, NUT-01 | `attendance_screen_test.dart` (widget) | 4 | pass |
| AC-7 | AUTH-03 | `teacher_home_screen_test.dart` (widget) | 4 | pass |
| AC-8 | AUTH-05, NUT-02, HLT-06 | `kitchen_meals_screen_test.dart` (widget) | 4 | pass |
| AC-10 | DESIGN §5.1 | test text scale 2.0 trong từng file màn | 3, 4 | pass |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Xóa widget/theme cũ làm vỡ build giữa phase | App không chạy | Phase 1 xóa và dựng lại trong cùng phase, verify trước khi dừng | `git restore` các file trong phase (hỏi user trước) |
| Dữ liệu giả bị hiểu là dữ liệu thật hoặc là rule | Sai nghiệp vụ khi nối API | Dữ liệu giả chỉ nằm ở `data/fake_*`; màn chỉ nhận model, không tự tính số | Thay nguồn dữ liệu khi có API |
| Đăng ký route cho màn [P] trái `NAVIGATION.md` | Lộ màn chưa chốt trong release | Theo Q1 (đề xuất: chỉ bật trong debug) | Tắt cờ |
| Lệch wireframe khi dịch HTML sang Flutter | User chọn A mà nhận khác | Chép số đo (lề 16, card bo 24 pad 20, ô cao 52, nút 52, thanh đáy 72) từ DESIGN §5 + wireframe; chụp màn so sánh | Sửa từng màn |
| Không có emulator Android | Chưa xem trên máy thật | Chạy `flutter run -d chrome` để xem; widget test ở 360×800 | — |

## Validation log
- [x] Khẳng định về code có `file:line` (colors.dart:6-16, sizes.dart:9/15-19, app_router.dart:11, BUSINESS_RULES.md:15-98)
- [x] Đổi contract ⇒ không đổi contract BE
- [x] Mỗi AC có test; mỗi phase có Exit = lệnh + kết quả mong đợi
- [x] >8 file hoặc >3 phase ⇒ đã đề xuất tách plan (Q6: user chọn giữ 1 plan)
- [x] Không dùng rule PENDING/OPEN như đã chốt (P-03, P-05, P-06, P-13b, P-17 chỉ ảnh hưởng hiển thị theo dữ liệu)
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan · không câu mơ hồ

## Progress log
### 2026-10-10 — Phase 1 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 14 fail 0 skip 0 | 10s | log verify.log`; `node scripts/check-ai-layer.mjs` → 0 lỗi, 5 cảnh báo E7 (glob rule chưa có file khớp).
- Đã làm:
  - Xóa `lib/core/widgets`, `lib/core/theme`, `features/home`, `features/ui_kit` và test cũ.
  - Viết lại `colors.dart` (§4.1, §4.2, §6.1, §7.3) và `sizes.dart` (§5.2–5.4, bỏ `space7`). Thêm `motion.dart`, `shadows.dart` (overlay lấy `--shadow-xl` của web), `app_icons.dart`, `asset_paths.dart`.
  - Theme mới: `ColorScheme.primary` = brand, extension `AppStatusColors` (7 tông + 4 nhóm phản hồi).
  - 17 widget chung. `pubspec.yaml` khai báo `assets/image/Logo.jpg`.
  - `DESIGN.md`: bỏ UiKitScreen (§7.4 và 9 chỗ nhắc), ghi đường dẫn logo thật (§2, §3.1).
- Khác plan:
  - `app_coming_soon.dart` làm sớm từ Phase 2, để route `/` tạm có màn trong khi chưa có Đăng nhập.
  - Thêm các widget phụ nằm trong file đã định: `AppCardHeader`, `AppIconTile`, `AppLinkButton` (`app_card.dart`), `AppDateField`, `AppFieldFrame` (`app_text_field.dart`), `AppSheetOption` (`app_bottom_sheet.dart`), `AppDividedColumn` (`app_list_row.dart`), `AppSkeletonCard`, `AppSkeletonList` (`app_skeleton.dart`).
  - Avatar hiện **2 chữ cái** (hai từ cuối, giống hàm `initials` của web), wireframe vẽ 1 chữ. Lý do: DESIGN §7.3 yêu cầu cùng người thì cùng hình ở web và app.
- Chưa kiểm chứng: chưa xem bằng mắt (Phase 1 chưa có màn), sẽ chụp màn ở Phase 2.
- Đề xuất đồng bộ (không sửa repo FE): Design System chung đang yêu cầu UiKitScreen; app đã bỏ, cần ghi ngoại lệ ở nguồn chung.
- Tiếp: Phase 2.
### 2026-10-10 — Phase 2 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 24 fail 0 skip 0 | 12s | log verify.log`
- Đã làm:
  - `AppShell` dùng `NavigationBar` (theme cao 72, viên `primarySoft`, nhãn luôn hiện), `AppBottomDock`, `navigation_destinations.dart`.
  - Router: `/login`; khi `enablePreview` thêm `/preview` và 3 `StatefulShellRoute` theo role. Tab chưa làm hiện "Sắp có".
  - `LoginScreen` theo phương án B; `RolePreviewScreen` (chỉ debug); cập nhật `NAVIGATION.md`.
- Xem bằng mắt: `flutter run -d web-server`, chụp 375×812 các màn Đăng nhập, Xem thử, tab Bếp. Bố cục khớp wireframe B.
- Khác plan:
  - Chưa nối auth ⇒ bấm "Đăng nhập" (đã nhập đủ) hoặc "Quên mật khẩu?" hiện banner thông tin "Đăng nhập chưa được kết nối với máy chủ trong bản này." Wireframe không có banner này. Thêm để nút không trông như bị hỏng.
  - Kiểm bắt buộc ở client (ô trống ⇒ lỗi dưới ô): chỉ hỗ trợ nhập, theo `.claude/rules/component.md`.
- Còn thấy: `Logo.jpg` có nền trắng ngà ⇒ trên nền trắng lộ khung vuông mờ quanh logo. Cần file PNG nền trong (`assets/brand/logo-full.png`), sau đó chỉ đổi một dòng ở `AppAssets`.
- Tiếp: Phase 3.
### 2026-10-10 — Phase 3 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 35 fail 0 skip 0 | 14s | log verify.log`
- Đã làm:
  - `parent_home` (domain `ParentToday`/`ChildSummary`, `FakeParentHomeSource` có 3 chế độ dữ liệu/rỗng/lỗi, `parent_home_status.dart`, `ParentHomeScreen` + các card).
  - `leave_notice` (domain, `FakeLeaveNoticeSource`, `leave_notice_status.dart`, `LeaveNoticeListScreen`, `LeaveNoticeForm` trong sheet).
  - Route `/parent/leave-notices?child=<id>`: route chỉ mang ID con.
  - `core/utils/date_labels.dart` (định dạng ngày tiếng Việt, không thêm intl); `openComingSoon()` cho lối vào màn chưa làm (Thực đơn, chi tiết cập nhật).
- Xem bằng mắt (web debug 375 px): Hôm nay khớp phương án A (hero → Điểm danh → Bữa ăn → Cập nhật → nút Báo nghỉ); Thông báo nghỉ khớp phương án B; sheet form đủ chip ngày, Từ/Đến, lý do, ghi chú, nút Gửi.
- Khác plan / wireframe:
  - `AppCardHeader` khi phóng chữ >1,3 đưa badge/link xuống dòng dưới tiêu đề (test chữ 2.0 bắt được tràn 77 px).
  - Hero chưa có tranh ⇒ khối trắng mờ có icon thay cho ô gạch đứt của wireframe.
  - Chưa có số "2" trên tab Thông báo: con số này cần BE trả, chưa có dữ liệu.
  - Dòng thông báo nghỉ chưa bấm được (chi tiết + "Hủy thông báo nghỉ" chưa có trong wireframe đã chọn).
  - Ô ngày dùng `showDatePicker` của Material theo theme app.
- Tiếp: Phase 4.
### 2026-10-10 — Phase 4 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 56 fail 0 skip 0 | 24s | log verify.log`; `check-ai-layer` 0 lỗi
- Đã làm:
  - `attendance`: domain, `FakeAttendanceSource` (lớp Mầm 2, 15 trẻ), `attendance_status.dart`, `AttendanceScreen`, `AttendanceKidRow`. Danh sách dựng lười bằng `DecoratedSliver` + `SliverList`.
  - `teacher_home`: domain, nguồn giả, `TeacherHomeScreen`.
  - `kitchen_meals`: domain (`MealCountView` chỉ có số khi đã chốt), nguồn giả, `KitchenMealsScreen`.
  - Route `/teacher/attendance`.
  - Cập nhật `docs/context/CURRENT_STATE.md`, `DESIGN.md` §7.1 (bỏ "cần bổ sung" ở 7 widget đã có), `docs/architecture/NAVIGATION.md`.
- Xem bằng mắt (web debug 375 px): Giáo viên Hôm nay khớp phương án A; Điểm danh khớp A; Bếp khớp A.
- Khác plan / wireframe:
  - Đổi tên trẻ giả "Nguyễn Hoàng Bảo Ngọc" trong lớp Mầm 2 thành "Nguyễn Hoàng Bảo Nam": Bảo Ngọc là con thứ hai của phụ huynh giả, học Lá 1.
  - Dị ứng dùng một icon cảnh báo chung. Wireframe có icon riêng cho cá/sữa/trứng, nhưng chọn icon theo chuỗi tên là đoán; khi BE có mã nhóm dị ứng thì ánh xạ.
  - Hàng đếm ở đáy màn Điểm danh là tổng lựa chọn đang nhập, **không phải số suất** (NUT-01); có test kiểm không có chữ "suất" trên màn.
  - `AttendanceKidRow` và `AppCardHeader` có bố cục riêng khi phóng chữ >1,3 (test chữ 2.0 bắt được tràn 24 px và 38 px).
  - `AppButton` dạng chữ được xuống dòng thay vì cắt "…" (nút "Đánh dấu các trẻ chưa nhập là có mặt" bị cắt ở 375 px).
  - Chọn lớp chỉ có một lớp (dữ liệu giả); bấm dòng "Nghỉ có báo hôm nay" và link "Tất cả" mở màn "Sắp có".
- Tiếp: user review toàn bộ. Sau khi user đồng ý ⇒ `status: done`, chuyển plan sang `docs/plans/completed/` (commit khi user cho phép).
### 2026-10-13 — Đóng plan (done)
- User đóng plan sau Phase 4. Bố cục 6 màn sẽ được thay theo mockup mới ở plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`.
- Commit: chưa commit
