---
title: Nền móng Flutter — cấu trúc, theme, widget chung, điều hướng cơ bản
status: in-progress
owner: ATPX48-69
jira: none
branch: main
modules: []
rules: []
risk: high
created: 2026-10-08
updated: 2026-10-08
---
# Nền móng Flutter — cấu trúc, theme, widget chung, điều hướng cơ bản

## Context
Repo vừa có project Flutter mặc định (`lib/main.dart:1` là app counter mẫu, `pubspec.yaml:30-36` chỉ có `cupertino_icons`). Chưa có `assets/`, theme, widget chung hay router. `DESIGN.md` đã có quy chuẩn Flutter (Feature-based + Clean Architecture, token màu §4.1, typography §5.1, spacing §5.2, widget §7, theme mẫu §9.1).

Docs repo còn ghi framework React Native PROPOSED (`AGENTS.md` mục Stack, `docs/architecture/MOBILE_ARCHITECTURE.md:3`, `docs/context/CURRENT_STATE.md`, `.ai/CONTEXT_MAP.yaml:95`). Glob trong `.claude/rules/*.md` trỏ `src/**/*.{ts,tsx}` nên không áp được vào code Dart. `scripts/verify.mjs:186-203` chỉ hiểu `pom.xml`/`package.json`, nên với Flutter luôn in `VERIFY SKIP`, Iron Law không thỏa được.

Yêu cầu: tạo cấu trúc thư mục `core/`, `features/`, cấu hình app; theme chung (màu, font, cỡ chữ, khoảng cách); widget dùng chung (AppButton, AppTextField, AppCard, loading…); điều hướng cơ bản + màn mẫu kiểm tra bộ UI. Nguồn: `DESIGN.md`.

## Quyết định đã chốt
1. Framework = **Flutter (CONFIRMED)**; cập nhật docs đang ghi React Native — user, 2026-10-08.
2. Chỉ thêm `go_router` ở bước này; `flutter_riverpod` để tới task auth/API — user, 2026-10-08.
3. Font BeVietnamPro: tải TTF 400/500/600/700 (license OFL) vào `assets/fonts/`, đóng gói trong app — user, 2026-10-08.
4. Thêm nhánh Flutter vào `scripts/verify.mjs` trong plan này — user, 2026-10-08.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** Actor: dev nội bộ (không phải người dùng cuối) · Outcome: nền UI dùng chung để các màn sau tái sử dụng · Rule: không chạm rule nghiệp vụ BE · Flow: không có `[B]`/`[S]`.
- **Đối chiếu thiết kế ban đầu:** `DESIGN.md` §2 (cấu trúc), §4–§7, §9.1. Lệch: docs repo ghi React Native, source là Flutter ⇒ user chốt Flutter.
- **Ảnh hưởng:** chưa có màn nghiệp vụ. Không làm điều hướng theo role (DESIGN §8.4 PROPOSED/NEEDS VERIFICATION, `docs/architecture/NAVIGATION.md`). Không gọi API, không lưu token, không dữ liệu trẻ. Màn UI Kit chỉ đăng ký route trong debug (DESIGN §7 cuối).

### Câu hỏi mở
- [x] Framework — Flutter CONFIRMED.
- [x] Dependency — chỉ `go_router`.
- [x] Font — tải TTF vào `assets/fonts/`.
- [x] Verify — thêm nhánh Flutter vào `scripts/verify.mjs`.

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Framework | Flutter CONFIRMED | user | 2026-10-08 | Phase 1: AGENTS.md, docs/architecture, CURRENT_STATE |
| Dependency | Chỉ `go_router` | user | 2026-10-08 | Phase 1: MOBILE_ARCHITECTURE.md |
| Font | TTF đóng gói | user | 2026-10-08 | Phase 2 |
| Verify | Nhánh Flutter trong verify.mjs | user | 2026-10-08 | Phase 1 |

## Acceptance criteria
- **AC-1** (harness): Given repo có `pubspec.yaml` When chạy `node scripts/verify.mjs` Then chạy `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, ghi log `verify.log`, in đúng 1 dòng `VERIFY PASS|FAIL full | …`.
- **AC-2** (theme): Given `buildLightTheme()` Then `colorScheme.primary == #1565E0`, `onPrimary == #FFFFFF`, `error == #E03131`, `surface == #FFFFFF`, `scaffoldBackgroundColor == #F5F8FC`, `fontFamily == BeVietnamPro`, cỡ chữ đúng bảng DESIGN §5.1, có `AppStatusColors` trong `extensions`.
- **AC-3** (AppButton): Given `isLoading: true` Then hiện vòng tải, `onPressed` không gọi khi bấm; Given `onPressed: null` Then nút disabled; chiều cao tối thiểu 48.
- **AC-4** (AppTextField / AppPasswordField): hiện label (không thay bằng placeholder), hiện `errorText` dưới trường; password có nút ẩn/hiện với tooltip.
- **AC-5** (AppStatusBadge): mỗi tone hiện chữ; màu lấy từ `AppStatusColors`.
- **AC-6** (AppEmptyState / AppErrorState / AppLoading): empty có message + CTA tùy chọn; error có nút "Thử lại" gọi callback; loading có semantics label.
- **AC-7** (routing): app mở `HomeScreen`; ở debug có lối vào `/ui-kit`; khi `kDebugMode == false` route `/ui-kit` không được đăng ký.
- **AC-8** (UiKitScreen): hiển thị bảng màu, thang chữ, mọi widget chung và biến thể; không dữ liệu thật.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Framework | Flutter | React Native | Source + DESIGN.md đã là Flutter (user chốt) |
| Điều hướng | `go_router` | Navigator có sẵn | Đúng DESIGN §1.3; redirect cho auth sau này |
| State | Chưa thêm | `flutter_riverpod` ngay | Theme/widget/màn mẫu chưa cần state chung |
| Font | TTF đóng gói | `google_fonts` | Chữ Việt ổn định khi offline (DESIGN §3) |
| ColorScheme | `fromSeed(...).copyWith(...)` ghi đè role đã duyệt | `fromSeed` thuần | `fromSeed` không giữ đúng `#1565E0` (DESIGN §4.2) |
| Theme mode | Chỉ light, `ThemeMode.light` | Dark/System | Chưa có token tối (DESIGN §4.3) |
| Widget ngoài phạm vi | Hoãn `AppAsyncView`, `AppAvatar`, `AppFilterSheet`, `AppShell` theo role | Làm luôn | `AppAsyncView` cần `AppFailure`/state; shell theo role chờ §8.4 chốt |

Quyết định framework ghi vào `docs/architecture/MOBILE_ARCHITECTURE.md` (repo APP không có thư mục ADR).

## Phases

### Phase 1 — Harness + tri thức (Flutter CONFIRMED)
- Files:
  - M `scripts/verify.mjs` — nhánh `pubspec.yaml`: chạy 3 lệnh tuần tự, dừng ở lệnh fail đầu; `parseFlutterOutput` lấy số test pass/fail từ dòng cuối `flutter test` (`+N -M: …`), số issue của `flutter analyze`, kết quả format.
  - M `scripts/__tests__/verify.test.mjs` — test `parseFlutterOutput` + `formatFlutterSummary`.
  - M `.claude/hooks/harness.config.json` — `verify.activeWhen` + `pubspec.yaml`; `verify.globs` + `lib/**`, `test/**`, `assets/**`, `pubspec.yaml`; `riskGlobs`/`dependencyGlobs` + `pubspec.yaml`, `pubspec.lock`.
  - M `.gitignore` — thêm `.dart_tool/`, `.flutter-plugins*`, `.packages`, `*.iml`, `ios/Pods/`, `ios/Flutter/ephemeral/`, `linux|macos|windows/flutter/ephemeral/`.
  - M `AGENTS.md` (mục Stack), `docs/architecture/MOBILE_ARCHITECTURE.md`, `docs/context/CURRENT_STATE.md`, `.ai/CONTEXT_MAP.yaml:95`, `.ai/profiles/code.md:13`.
  - M `.claude/rules/{api-client,component,navigation,security-storage,state}.md` — đổi `paths` sang `lib/**/*.dart` theo cấu trúc DESIGN §2; bỏ ghi chú "React Native PROPOSED"; không đổi nội dung rule.
- Steps: 1. Viết test parser trước (fail). 2. Thêm nhánh Flutter. 3. Cập nhật config + docs. 4. `node --test scripts/__tests__/` + `node scripts/check-ai-layer.mjs`.
- Tests: AC-1 → `scripts/__tests__/verify.test.mjs`.
- Exit: `node --test scripts/__tests__/` pass; `node scripts/check-ai-layer.mjs` exit 0; `node scripts/verify.mjs` in `VERIFY PASS full` trên project hiện tại (test counter mặc định).
- **Dừng chờ user review.**

### Phase 2 — Cấu trúc, cấu hình, theme
- Files:
  - M `pubspec.yaml` (+ `go_router`, khai báo `assets/fonts` và font BeVietnamPro), M `pubspec.lock` (do `flutter pub get`).
  - C `assets/fonts/BeVietnamPro-{Regular,Medium,SemiBold,Bold}.ttf` + `assets/fonts/OFL.txt`.
  - C `lib/core/config/env.dart` (`API_BASE_URL`, `USE_MOCK`, `APP_ENV` qua `String/bool.fromEnvironment`; chưa dùng nhưng để sẵn theo DESIGN §1.2).
  - C `lib/core/constants/colors.dart` (`AppColors`, đủ token §4.1), `lib/core/constants/sizes.dart` (`AppSpacing`, `AppRadius`, `AppSizes` §5.2).
  - C `lib/core/theme/app_text_styles.dart`, `lib/core/theme/app_status_colors.dart` (`ThemeExtension`, `copyWith`/`lerp`, nền/viền chip theo tone), `lib/core/theme/app_theme.dart` (`buildLightTheme()` + theme button/input/card/AppBar/NavigationBar/dialog/snackbar/bottom sheet).
  - C `lib/app.dart` (`MaterialApp.router`, `ThemeMode.light`, locale `vi`), M `lib/main.dart`.
  - C `test/core/theme/app_theme_test.dart`.
- Steps: 1. Tải font từ `github.com/google/fonts` (thư mục `ofl/bevietnampro`). 2. Test theme (fail). 3. Token + theme. 4. `flutter pub get`.
- Màu nền/viền chip semantic chưa có mã trong DESIGN §4.1 ⇒ đề xuất mã nhạt cùng tông, ghi PROPOSED trong `colors.dart` và DESIGN §4.1; user xem trên UiKitScreen ở Phase 3.
- Tests: AC-2 → `app_theme_test.dart`.
- Exit: `node scripts/verify.mjs` → `VERIFY PASS full`.
- **Dừng chờ user review.**

### Phase 3 — Widget chung, router, màn mẫu
- Files:
  - C `lib/core/widgets/app_button.dart` (variant primary/secondary/text/danger, `isLoading`, `icon`, `expand`), `app_text_field.dart`, `app_password_field.dart`, `app_card.dart`, `app_status_badge.dart` (`AppStatusTone`), `app_loading.dart` (`AppLoading` + `AppSkeleton`), `app_empty_state.dart`, `app_error_state.dart`, `app_confirmation_dialog.dart`, `brand/app_wordmark.dart` (chữ Care/Nest; chưa có file logo ⇒ hoãn `AppLogo`).
  - C `lib/routing/route_paths.dart`, `lib/routing/app_router.dart` (route `/` và `/ui-kit` chỉ khi `kDebugMode`).
  - C `lib/features/home/presentation/screens/home_screen.dart` (placeholder, không dữ liệu nghiệp vụ), `lib/features/ui_kit/presentation/screens/ui_kit_screen.dart`.
  - D `test/widget_test.dart` (test counter mặc định, không còn đúng); C `test/core/widgets/*_test.dart`, `test/routing/app_router_test.dart`.
  - M `DESIGN.md` — chỉ ghi chú widget/token đã triển khai và mã màu chip PROPOSED; sửa `package:carenest_mobile` thành `package:carenest_app` (§2.2, §9.1).
- Steps: 1. Widget test từng widget (fail). 2. Widget. 3. Router + màn. 4. Chạy app debug trên emulator/Windows để xem UiKitScreen (nếu có thiết bị).
- Tests: AC-3…AC-6 → `test/core/widgets/`; AC-7 → `test/routing/app_router_test.dart`; AC-8 → smoke test render `UiKitScreen` không lỗi overflow ở 360×640 và textScale 1.3.
- Exit: `node scripts/verify.mjs` → `VERIFY PASS full`; chạy tay ghi rõ thiết bị hoặc "chưa chạy".
- **Dừng chờ user review.**

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | harness | `scripts/__tests__/verify.test.mjs` (node unit) | 1 | pass |
| AC-2 | DESIGN §4–5 | `test/core/theme/app_theme_test.dart` (unit) | 2 | pass |
| AC-3 | DESIGN §7 | `test/core/widgets/app_button_test.dart` (widget) | 3 | pass |
| AC-4 | DESIGN §7, §13 | `app_text_field_test.dart` (widget) | 3 | pass |
| AC-5 | DESIGN §6 | `app_status_badge_test.dart` (widget) | 3 | pass |
| AC-6 | DESIGN §14 | `app_states_test.dart` (widget) | 3 | pass |
| AC-7 | DESIGN §7 | `test/routing/app_router_test.dart` (widget) | 3 | pass |
| AC-8 | DESIGN §5.3 | `ui_kit_screen_test.dart` (widget smoke) | 3 | pass |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| `scripts/verify.mjs` là file dùng chung 3 repo (`harness.config.json` → `sharedFiles`) | BE/FE lệch bản ⇒ check cross-repo cảnh báo | Nhánh Flutter chỉ chạy khi có `pubspec.yaml`, không đổi nhánh Maven/npm | Đồng bộ sang BE/FE khi user cho phép; hoặc revert nhánh |
| `go_router` bản mới yêu cầu SDK khác | `pub get` fail | Chọn bản tương thích Dart `^3.12` do `pub add` giải | Gỡ dependency |
| `flutter test` chậm/treo trên Windows | Verify timeout | Log ra `verify.log`, in lệnh fail | Chạy tay 3 lệnh |
| Mã màu chip chưa duyệt | Lệch nhận diện | Ghi PROPOSED, duyệt trên UiKitScreen | Sửa tập trung `colors.dart` |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ không có (không chạm API BE)
- [x] Mỗi AC có test; mỗi phase có Exit = lệnh + kết quả mong đợi
- [x] >8 file hoặc >3 phase ⇒ đã đề xuất tách plan (xem chat: giữ 1 plan 3 phase, dừng review sau mỗi phase)
- [x] Không dùng rule PENDING/OPEN như đã chốt (không làm điều hướng theo role)
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan · không câu mơ hồ

## Progress log
### 2026-10-08 — Phase 1 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 1 fail 0 skip 0 | 7s | log verify.log`; `node --test scripts/__tests__/*.test.mjs .claude/hooks/__tests__/*.test.mjs` → pass 58 fail 0; `node scripts/check-ai-layer.mjs` → 0 lỗi, 2 cảnh báo E7 (glob `lib/**/*log*.dart`, `lib/**/offline/**/*.dart` chưa có file — giữ làm lưới an toàn).
- Khác plan:
  - `runToLog` chỉ quote `exe` khi có khoảng trắng — cmd gọi `"flutter"`/`"dart"` có quote làm `%~dp0` sai (APP-ENV-261008-verify-quoted-bat).
  - Cập nhật thêm `docs/context/REPOSITORY_CONTEXT.md`, `docs/architecture/STATE_MANAGEMENT.md`, `docs/integration/AUTH_FLOW.md`, `docs/integration/BACKEND_INTEGRATION.md:7` (thêm prefix `BE:`, check E2 báo lỗi khi bỏ thư mục src khỏi `planned`), `docs/knowledge/{ISSUE_INDEX,TROUBLESHOOTING}.md`, `.ai/workflows/update-knowledge.md` (ví dụ trigger).
  - `MOBILE_ARCHITECTURE.md` bỏ header SKELETON, chuyển từ `skeleton_only` sang `available.docs` trong CONTEXT_MAP; thêm `DESIGN.md` và `available.source`.
- Chưa làm: đồng bộ `scripts/verify.mjs` sang BE/FE (file dùng chung) — chờ user cho phép.
- Tiếp: Phase 2.
### 2026-10-08 — Phase 2 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 5 fail 0 skip 0 | 13s | log verify.log`
- Đã làm: `go_router ^18.0.2` (`flutter pub add`); `lib/core/config/env.dart`, `lib/core/constants/{colors,sizes}.dart`, `lib/core/theme/{app_text_styles,app_status_colors,app_theme}.dart`, `lib/app.dart`, `lib/main.dart`; test `test/core/theme/app_theme_test.dart` (AC-2).
- Khác plan:
  - Tải font BeVietnamPro bị chặn (quyền tải file ngoài). Theme đã đặt `fontFamily: 'BeVietnamPro'`, Flutter dùng font hệ thống cho tới khi có file; chưa khai báo `fonts:` trong `pubspec.yaml` vì khai báo file thiếu làm build fail. User tải 4 TTF + `OFL.txt` từ `github.com/google/fonts/tree/main/ofl/bevietnampro` vào `assets/fonts/` rồi thêm khối `fonts:` (DESIGN §3).
  - Chưa đặt locale `vi`: cần `flutter_localizations` (thêm vào pubspec) ⇒ hỏi user trước.
  - Router tối thiểu (`lib/routing/{route_paths,app_router}.dart`) + `HomeScreen` làm sớm ở Phase 2 để app chạy được; xóa `test/widget_test.dart` (test counter cũ, không còn `MyApp`).
  - `.claude/rules/navigation.md`: ghi `go_router` CONFIRMED.
- Chưa làm: đồng bộ `scripts/verify.mjs` + test sang BE/FE — bị chặn quyền sửa repo khác; user tự chép.
- Tiếp: Phase 3.
### 2026-10-08 — Phase 3 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 25 fail 0 skip 0 | 9s | log verify.log`; `node scripts/check-ai-layer.mjs` → 0 lỗi, 4 cảnh báo E7 (glob rule cho thư mục chưa có: data, controllers, providers, offline).
- Đã làm: `lib/core/widgets/` (AppButton, AppTextField, AppPasswordField, AppCard, AppStatusBadge, AppLoading + AppSkeleton, AppEmptyState, AppErrorState, AppStateMessage, AppConfirmationDialog, `brand/AppWordmark`); router có `/ui-kit` chỉ khi `enableUiKit` (mặc định `kDebugMode`) + màn "Không tìm thấy trang"; `UiKitScreen`; `HomeScreen` có lối vào UI Kit ở debug; 20 widget test mới (AC-3…AC-8); `DESIGN.md`: package `carenest_app`, danh sách widget đã có, màu chip PROPOSED.
- Khác plan:
  - Thêm `flutter_localizations` (SDK) + locale `vi` — user đồng ý 2026-10-08.
  - Thêm `lib/core/widgets/app_state_message.dart` (bố cục chung empty/error) và `test/helpers/pump_app.dart`.
  - Nút hủy mặc định của dialog là "Quay lại" để không trùng chữ "Hủy" với hành động như "Hủy phiếu".
- Chưa kiểm chứng: chạy app trên thiết bị/emulator — máy chỉ có Chrome/Edge (web), chưa có Android emulator; chưa xem UiKitScreen bằng mắt. Font BeVietnamPro chưa có file (đang dùng font hệ thống).
- Còn lại trước khi `done`: user tải font + thêm khối `fonts:`; user duyệt màu chip trên UiKitScreen; đồng bộ `scripts/verify.mjs` sang BE/FE.
### 2026-10-08 — Font BeVietnamPro (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 26 fail 0 skip 0 | 12s | log verify.log`
- Đã làm: user tải 4 TTF + `OFL.txt` vào `assets/fonts/`; khai báo khối `fonts:` trong `pubspec.yaml`; test `app_theme_test.dart` kiểm tra `FontManifest.json` có BeVietnamPro đủ weight 400/500/600/700.
- Còn lại trước khi `done`: user duyệt màu chip trên UiKitScreen; đồng bộ `scripts/verify.mjs` sang BE/FE.
### 2026-10-08 — Duyệt màu chip (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 27 fail 0 skip 0 | 10s | log verify.log`
- Đã làm: user duyệt màu chip. Kiểm tra tương phản chữ/nền: warning 4.30:1 < 4.5 ⇒ user chọn thêm `AppColors.warningChipText` #A35600 (4.97:1), giữ `warningText` #B25E00 của web. Test mới khóa ≥4.5:1 cho mọi tông. `colors.dart` + DESIGN.md §4.1: PROPOSED ⇒ CONFIRMED.
- Còn lại trước khi `done`: đồng bộ `scripts/verify.mjs` sang BE/FE (user làm tay, repo khác).
