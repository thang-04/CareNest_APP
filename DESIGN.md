# CareNest Mobile — Design & Coding Guide (Flutter)

| Thông tin | Giá trị |
| --- | --- |
| Bản cập nhật mobile | 2.0 — 10/10/2026 |
| UI đồng bộ theo | **CareNest Design System — web + app, phiên bản 3.1 — 09/10/2026** |
| Trạng thái Design System nguồn | **PROPOSED — chờ team duyệt**; bản này đồng bộ theo nguồn đó, không xác nhận team đã duyệt |
| Nền tảng | Flutter Android/iOS, repository `CareNest_APP` |
| Kiến trúc | Feature-based + Clean Architecture |
| Phạm vi lần sửa | Quy chuẩn UI, token, component, khung màn, câu chữ, checklist và tham chiếu liên quan |
| Nguồn UI chính | `CareNest_FE/DESIGN.md`; khi nối repo, chép nguyên bản Design System chung thành `CareNest_APP/DESIGN.md` |
| Vai trò tài liệu này | Guide triển khai mobile đã đồng bộ; **không tạo một Design System riêng cho app** |

Trước khi làm màn hình mới, đọc Design System chung và danh mục widget ở §7.1. Dùng component chung; thiếu thì bổ sung vào `core/widgets` và token, kèm widget test (§7.4), trước khi dùng ở màn hình.

**Ưu tiên UI:** yêu cầu rõ của người dùng trong lượt hiện tại → Design System chung → phần UI của guide này → mặc định Material/AI. Khi cần thay đổi lâu dài, cập nhật nguồn chung và hai nền tảng trong cùng đợt; ngoại lệ ghi rõ “lệch design system ở …” trong PR.

**PHẢI / KHÔNG** là bắt buộc theo Design System đang áp dụng. **NÊN** là mặc định, lệch thì ghi lý do. Các lựa chọn kỹ thuật/API là **PROPOSED** cho tới khi nhóm và backend xác nhận. **OPEN** là điểm cần chốt; **NEEDS VERIFICATION** là thông tin cần đối chiếu SRS/Use Case/Screen Flow hoặc mã nguồn.

Guide giữ hướng dẫn chạy dự án, kiến trúc, API, xác thực, upload và push của bản mobile. Quyền, mã role, field, endpoint và vòng đời nghiệp vụ vẫn do SRS/Use Case/Screen Flow cùng `CareNest_BE` quyết định. Mẫu UI không tự xác nhận một chức năng hoặc endpoint đã tồn tại.

**Xác thực native:** giữ đề xuất Bearer token + secure storage; web dùng cookie HttpOnly. Design System 3.1 còn mở lựa chọn form đăng nhập hay Keycloak. Chốt với backend trước khi tích hợp; hợp đồng ở mục 12 vẫn là đề xuất, phương án cookie ở mục 12.7.

**Khi nối vào repo:** theo Phụ lục A, tách phần code sang `docs/architecture/CODING_GUIDE.md` và dùng bản Design System chung làm `DESIGN.md`. Lần sửa này cập nhật tài liệu; chưa sửa repository, cài package, tạo widget hoặc chạy build.

## Mục lục

1. [Chạy dự án và cấu hình](#section-1)
2. [Cấu trúc thư mục](#section-2)
3. [Thương hiệu, tranh và tài nguyên](#section-3)
4. [Màu sắc và design tokens](#section-4)
5. [Chữ, kích thước, khoảng cách và chuyển động](#section-5)
6. [Badge và ánh xạ trạng thái](#section-6)
7. [Widget dùng chung và icon](#section-7)
8. [Khung ứng dụng và công thức màn hình](#section-8)
9. [Theme và tổ chức style](#section-9)
10. [Kiến trúc và luồng dữ liệu](#section-10)
11. [Quy trình thêm feature](#section-11)
12. [Đăng nhập, phiên và lưu token](#section-12)
13. [Chữ trên giao diện](#section-13)
14. [Tải, lỗi, rỗng và xác nhận](#section-14)
15. [Code style và kiểm tra](#section-15)
16. [Nối Spring Boot và tích hợp nền tảng](#section-16)
17. [Checklist trước PR](#section-17)
18. [Nguồn nghiệp vụ chung và các điểm cần chốt](#section-18)

- [Phụ lục A — Nối tài liệu vào repository](#appendix-a)
- [Phụ lục B — Bảng thay đổi UI](#appendix-b)
- [Tài liệu tham chiếu](#references)

---

<a id="section-1"></a>
## 1. Chạy dự án và cấu hình

Flutter/Dart SDK, Android/iOS SDK và phiên bản package được nhóm thống nhất trong repository. Không sao chép số phiên bản từ tài liệu mà chưa kiểm tra tương thích; commit `pubspec.lock` của ứng dụng. Build iOS cần môi trường macOS/Xcode phù hợp.

### 1.1 Lệnh phát triển

Chạy trong thư mục dự án Flutter đã khởi tạo:

```bash
flutter doctor
flutter pub get
flutter devices
flutter run --dart-define=USE_MOCK=true
flutter analyze
dart format lib test
flutter test
```

Trước PR, kiểm tra định dạng mà không sửa file:

```bash
dart format --output=none --set-exit-if-changed lib test
```

Chạy API thật, thay URL mẫu bằng backend thực tế:

```bash
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.example.com/api
```

Build cho nền tảng được hỗ trợ với **cùng cấu hình môi trường** đã xác nhận:

```bash
flutter build apk --release --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.example.com/api
flutter build appbundle --release --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.example.com/api
```

Các URL trên chỉ là ví dụ. Không chạy release với mock hoặc thiếu URL thật. Quy trình ký/phân phối bản iOS do pipeline dự án quy định.

### 1.2 Cấu hình

| Biến | Vai trò | Nơi đọc |
|---|---|---|
| `API_BASE_URL` | Base URL của API | `core/config/env.dart` |
| `USE_MOCK` | Chọn repository mock hay thật | Điểm ghép dependency |
| `APP_ENV` | `development`, `staging`, `production` nếu dự án cần | `core/config/env.dart` |

Dùng `String.fromEnvironment` / `bool.fromEnvironment` tập trung trong `env.dart`. Thiếu cấu hình bắt buộc phải được phát hiện khi bootstrap. `--dart-define` không phải nơi cất bí mật; không nhúng mật khẩu, signing key hoặc token cố định vào app.

### 1.3 Package đề xuất

| Nhu cầu | Package/cơ chế | Quy tắc |
|---|---|---|
| HTTP | `dio` | Một cấu hình client dùng chung, phân biệt client upload/refresh khi cần |
| State và dependency injection | `flutter_riverpod` | Dùng nhất quán; không thêm Bloc/Provider cho cùng trách nhiệm nếu chưa thống nhất |
| Điều hướng | `go_router` | Cấu hình ở `routing/`; xử lý phiên qua redirect |
| Token lưu bền | `flutter_secure_storage` | Chỉ lớp storage/auth được truy cập |
| Ngày, số, tiền | `intl` | Tập trung helper, thống nhất locale |
| Thiết lập không nhạy cảm | `shared_preferences` nếu cần | Không lưu token hoặc mật khẩu |
| Chọn ảnh | `image_picker` khi feature cần ảnh | Camera/thư viện, xử lý hủy và phục hồi kết quả trên Android; xem mục 16.1 |
| Nén ảnh | Package phù hợp do nhóm chọn | Nén trước upload theo giới hạn backend, không mặc định image_picker tự nén mọi định dạng |
| Push notification | `firebase_core` + `firebase_messaging` nếu chốt FCM | OPEN: backend, Firebase/APNs và vòng đời device token; xem mục 16.2 |
| File, chia sẻ, cache ảnh | Package phù hợp khi có nhu cầu thực tế | Không thêm dependency chỉ để có sẵn |
| Lint | `flutter_lints` | Khai báo trong `analysis_options.yaml` |

Riverpod và go_router là **lựa chọn đề xuất của bản guide**, không khẳng định dự án đã cài. Nếu nhóm đã chọn thư viện tương đương, cập nhật đồng bộ guide, state và DI; giữ nguyên ranh giới các tầng. [S1, S4, S5, S6]

---

<a id="section-2"></a>
## 2. Cấu trúc thư mục

Giữ `main.dart`, `app.dart`, `core/`, `features/` theo đề xuất. Bổ sung cấu hình, lưu trữ, lỗi, routing và bootstrap. `assets/` nằm ở **gốc dự án** và được khai báo trong `pubspec.yaml`.

```text
assets/
  image/
    Logo.jpg                        # Logo đầy đủ hiện có (§3.1)
  brand/                            # Khi có bản PNG nền trong: logo-mark.png, logo-full.png
  images/
  illustrations/                    # Cùng bộ tranh sáp màu của web
  icons/
  fonts/

lib/
  main.dart                         # Khởi tạo Flutter binding, gọi bootstrap và runApp
  app.dart                          # MaterialApp.router, theme, locale
  bootstrap.dart                    # Ghép repository/client/storage/provider theo môi trường

  routing/
    app_router.dart                 # Route và redirect; được phép ghép nhiều feature
    route_paths.dart
    navigation_destinations.dart    # Cấu hình đích theo vai trò/quyền đã chốt ở mục 8.4
    route_access_policy.dart        # Kiểm tra quyền cho route/deep link, không thay backend

  core/
    config/
      env.dart
      app_config.dart
    constants/
      colors.dart
      sizes.dart
      asset_paths.dart
      motion.dart                    # AppMotion theo Design System
      app_icons.dart                 # Một điểm import icon, tên giống web
    theme/
      app_theme.dart
      app_text_styles.dart
      app_status_colors.dart        # ThemeExtension: semantic, phản hồi, 7 tông bản ghi
    utils/
      date_formatters.dart
      number_formatters.dart
      search_utils.dart
    network/
      dio_client.dart
      auth_interceptor.dart
      api_error_mapper.dart
    storage/
      token_storage.dart            # Interface lưu phiên/token
      secure_token_storage.dart     # Triển khai qua flutter_secure_storage
      memory_token_storage.dart     # Phiên không ghi nhớ và fake test
      preferences_storage.dart      # Cấu hình không nhạy cảm, nếu có
    notifications/                 # Chỉ khi có push; adapter nền tảng, không chứa màn hình
      push_notification_service.dart
    errors/
      app_failure.dart
    widgets/
      app_button.dart
      app_text_field.dart
      app_password_field.dart
      app_card.dart
      app_status_badge.dart
      app_filter_chip.dart
      app_stat_card.dart
      app_segmented.dart
      app_banner.dart
      app_toast.dart
      app_bottom_sheet.dart
      app_submit_overlay.dart
      app_progress_bar.dart
      app_avatar.dart
      app_info_list.dart
      app_list_row.dart
      app_stepper.dart
      app_loading.dart
      app_skeleton.dart
      app_empty_state.dart
      app_error_state.dart
      app_confirmation_dialog.dart
      app_async_view.dart
      brand/
        app_logo.dart
        app_wordmark.dart
    layouts/
      app_shell.dart
      auth_scaffold.dart
      app_hero_scene.dart            # Nơi duy nhất dùng kính/blur trên hero

  features/
    auth/
      data/
        datasources/
          auth_remote_data_source.dart
          auth_local_data_source.dart
        models/
          user_dto.dart
          auth_response_dto.dart
        repositories/
          auth_repository_impl.dart
          mock_auth_repository.dart
      domain/
        entities/
          app_user.dart
          auth_session.dart
          user_role.dart            # Mã role map từ backend; không tự đoán TEAM_LEADER
        repositories/
          auth_repository.dart
        validators/
          login_validator.dart
        usecases/                   # Chỉ tạo khi cần điều phối đáng kể
      presentation/
        screens/
          login_screen.dart
          session_loading_screen.dart
          otp_screen.dart           # Chỉ khi hợp đồng đăng nhập có OTP
        widgets/
          login_form.dart
        controllers/
          auth_controller.dart
          auth_state.dart
        providers/
          auth_providers.dart

    home/
      presentation/
        screens/
          home_screen.dart

    notifications/                 # Chỉ khi danh sách thông báo thuộc phạm vi đã chốt
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
      presentation/
        screens/
        widgets/
        controllers/
        providers/

    feature_name/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
      presentation/
        screens/
        widgets/
        controllers/
        providers/

test/
  core/
  features/
integration_test/                   # Khi đã có kiểm thử tích hợp
```

**Thư mục trong cây là mẫu, không bắt buộc tạo thư mục rỗng.** Tên feature dùng `snake_case`, ví dụ `child_profile`, không dùng `child-profile` như web.

### 2.1 Trách nhiệm các tầng

| Tầng | Chứa | Không chứa |
|---|---|---|
| `presentation` | Screen, widget, controller, state, điều phối tương tác | Gọi Dio trực tiếp, đọc secure storage, chuyển JSON thủ công |
| `domain` | Entity, hợp đồng repository, validation thuần Dart | Flutter widget, Dio, plugin storage |
| `data` | DTO, datasource API/local, triển khai repository, mock | Điều hướng, BuildContext, UI thông báo |
| `core` | Hạ tầng và widget nhiều feature cùng dùng | Quy trình nghiệp vụ riêng, import screen của feature |
| `routing` / `bootstrap` | Ghép các feature, dependency và route | Logic xử lý nghiệp vụ trong route builder |

Entity `AppUser` không chứa access/refresh token. `AuthSession` thuộc domain có thể biểu diễn thông tin phiên nhưng không được đưa thông tin token ra state màn hình. Việc kiểm tra định dạng email/mật khẩu chỉ phục vụ form; xác thực mật khẩu thật thuộc backend.

### 2.2 Import và dùng chung

- Thống nhất `package:carenest_app/...` cho code trong `lib/` (package name trong `pubspec.yaml`).
- Không import implementation `data` của feature khác vào màn hình. Cross-feature giao tiếp qua interface/provider được ghép ở bootstrap hoặc hợp đồng chung thực sự cần thiết.
- `routing`, `bootstrap`, `app.dart` là điểm ghép được phép tham chiếu nhiều feature. `core/network` không import trực tiếp `AuthController`; nhận callback/interface phiên qua DI.
- Không đẩy mọi entity lên `core`; chỉ chuyển phần có cùng ý nghĩa và được nhiều feature sử dụng.
- Theo lựa chọn **Feature-based + Clean Architecture**, DTO thuộc `data`, entity và repository interface thuộc `domain`; không để domain/presentation import DTO hoặc implementation. Mapper chuyển DTO sang entity trong data. Use case chỉ thêm khi có logic/điều phối đáng kể; không cần lớp chuyển tiếp cho mọi lời gọi. [S1]

---

<a id="section-3"></a>
## 3. Thương hiệu, tranh và tài nguyên

Theo Design System §4. Logo, tranh và font cùng nguồn với web; cách bố trí theo nền tảng.

### 3.1 Logo và font

| Tài nguyên app | Dùng | Quy tắc |
| --- | --- | --- |
| `assets/image/Logo.jpg` | `AppLogo` đầy đủ; đăng nhập | Bản hiện có (user, 2026-10-10): biểu tượng + chữ, **nền trắng** ⇒ chỉ đặt trên nền sáng |
| `assets/brand/logo-mark.png`, `logo-full.png` | Dạng mark/full nền trong | Chưa có file; khi có thì đổi một dòng ở `AppAssets` |
| Chữ render `AppWordmark` | Cạnh biểu tượng khi cần | **Care** dùng token `wordmarkCare` (`#0269C5`); **Nest** dùng `brand` (`#4FB0F5`) |
| App launcher icon | Màn hình Android/iOS | Cấu hình tài nguyên riêng nền tảng từ logo, không lấy favicon làm mặc định |
| `assets/fonts/` | Be Vietnam Pro | Đóng gói 400/500/600/700, family `BeVietnamPro` |

`wordmarkCare` là tên token adapter Flutter cho màu logo tại Design System §4.1, không phải màu primary tương tác. Đường dẫn logo dùng tên gạch nối như nguồn chung; nếu asset hiện có dùng `logo_mark.png`/`logo_full.png`, đổi tên hoặc ánh xạ tại `AppAssets` và cập nhật `pubspec.yaml` cùng đợt, không để hai bản logo khác nhau.

Không kéo méo, đổi màu hoặc thêm bóng logo. Nền sau logo luôn sáng; giữ tỷ lệ bằng `BoxFit.contain`. `mockups/brand/logo.jpg` là nguồn để cắt, không dùng trực tiếp. Tập trung đường dẫn ở `AppAssets` trong `core/constants/asset_paths.dart`.

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/brand/
    - assets/images/
    - assets/illustrations/
  fonts:
    - family: BeVietnamPro
      fonts:
        - asset: assets/fonts/BeVietnamPro-Regular.ttf
          weight: 400
        - asset: assets/fonts/BeVietnamPro-Medium.ttf
          weight: 500
        - asset: assets/fonts/BeVietnamPro-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/BeVietnamPro-Bold.ttf
          weight: 700
```

Chỉ khai báo thư mục/file thật sự tồn tại. `assets/icons/` khai báo khi dùng asset icon; không thay bộ icon chung bằng các ảnh riêng từng feature. Tên app/phiên bản nằm ở cấu hình và màn Tài khoản/Giới thiệu; không thêm footer vào mọi màn.

### 3.2 Tranh và bề mặt

Dùng **cùng bộ 20 tranh sáp màu** của web (`src/assets/illustrations/scenes/`, `login-scene.webp`, `hero-scene.webp`). App đóng gói bản rộng 1080 px, WebP ≤150 KB vào `assets/illustrations/`; danh mục đường dẫn tập trung ở `AppAssets`. Đây là yêu cầu asset, chưa xác nhận các file đã có trong app.

| Vị trí | App |
| --- | --- |
| Nền toàn app | Nền `background` trơn; không phủ tranh toàn bộ app |
| Màn Hôm nay | Hero cao 224 logical pixels, đáy mờ về nền; khối chào kính |
| Đăng nhập | Tranh khoảng 42% phía trên; sheet form trắng bo 32 phía dưới |
| Card/list/sheet thông thường | Trắng đặc `surface`, không kính |
| Màn trống | Tranh 168×124, bo 20; tiêu đề + giải thích + hành động phù hợp |
| Màn lỗi | Icon, không tranh |

Kính chỉ dùng cho khối chào trong hero: trắng 72%, blur 20, viền trắng 85%. Khai báo token tập trung; chỉ `app_hero_scene.dart` xử lý blur. **KHÔNG `BackdropFilter` trong item danh sách cuộn.**

App tạm dùng tranh **T0 Sân chơi** tới khi backend có hợp đồng appearance. `GET /school/appearance` trong Design System là đề xuất, không tự gọi như API đã có. Tranh đăng nhập chỉ giữ tỷ lệ 42% khi đủ không gian; cho form cuộn và xử lý bàn phím theo mục 5.6.

---

<a id="section-4"></a>
## 4. Màu sắc và design tokens

Theo Design System §3.1–3.3. Mã màu chỉ định nghĩa trong `core/constants/colors.dart`; màu bóng trong `AppShadows`. Widget đọc `ColorScheme` / `AppStatusColors`, không viết `Color(0x...)` hoặc `Colors.*` riêng tại screen.

### 4.1 Màu nền tảng — cùng mã với web

| Vai trò | Mã | Web | App `AppColors` |
| --- | --- | --- | --- |
| Nền thương hiệu: nút chính, mục chọn đậm | `#4FB0F5` | `--color-brand` | `brand` |
| Thương hiệu khi rê chuột | `#71C6FD` | `--color-brand-hover` | — |
| Thương hiệu khi nhấn | `#95CFF9` | `--color-brand-active` | `brandPressed` |
| Chữ/icon trên nền thương hiệu (4,64:1) | `#0E3F63` | `--color-on-brand` | `onBrand` |
| Link, chữ màu, icon nhấn, focus (5,06:1) | `#0B72BC` | `--color-primary` | `primary` |
| Link khi rê/nhấn | `#0A6AAE` | `--color-primary-hover` | `primaryPressed` |
| Nền nhạt: mục chọn, ô icon | `#E2F2FD` | `--color-primary-soft` | `primarySoft` |
| Viền nhạt chọn | `#95CFF9` | `--color-primary-border` | `primaryBorder` |
| Vòng focus | `#C5E5FC` | `--color-focus-ring` | `focusRing` |
| Mint của logo | `#94DEBD` | `--color-accent` | `accent` |
| Nền mint | `#EEFAF4` | `--color-accent-soft` | `accentSoft` |
| Chữ trên nền mint (4,92:1) | `#1F7A59` | `--color-accent-fg` | `accentText` |
| Nền màn | `#F1F9FE` | `--color-bg` | `background` |
| Bề mặt: card, sheet, modal, ô nhập | `#FFFFFF` | `--color-surface` | `surface` |
| Bề mặt phụ trong card | `#F8FAFC` | `--color-surface-muted` | `surfaceMuted` |
| Chữ chính (15,6:1) | `#1B2433` | `--color-text` | `textPrimary` |
| Chữ phụ (7,5:1) | `#4A5568` | `--color-text-secondary` | `textSecondary` |
| Chữ mờ, placeholder (4,84:1) | `#66728A` | `--color-text-muted` | `textMuted` |
| Chữ vô hiệu | `#A3AEBD` | `--color-text-disabled` | `textDisabled` |
| Viền nhạt, kẻ phân cách | `#E3E9F2` | `--color-border` | `border` |
| Viền ô nhập, nút phụ | `#CDD6E3` | `--color-border-strong` | `borderStrong` |
| Viền vùng kéo-thả | `#B9C6D8` | `--color-border-dashed` | — |
| Rãnh segmented, khung chờ | `#EEF1F5` | `--skeleton` | `track` |
| Nền sau hộp thoại (không blur) | `#0E3F63` 32% | `--color-overlay` | `overlay` |

`brand` là **nền nút chính**, `onBrand` là **chữ/icon trên nút chính**. `primary` là **link, icon nhấn, focus**, không còn là màu nền nút như guide cũ. Không dùng chữ trắng trên `brand`.

### 4.2 Màu phản hồi — tách khỏi trạng thái bản ghi

| Nghĩa | Màu | Chữ | Nền | Viền | Web | App |
| --- | --- | --- | --- | --- | --- | --- |
| Thành công | `#12A150` | `#0B7A3B` | `#E7F7EE` | `#B5E5C8` | `--color-success*` | `success*` |
| Cảnh báo | `#E8890C` | `#9A5100` | `#FFF4E3` | `#F7D49C` | `--color-warning*` | `warning*` |
| Lỗi, nguy hiểm | `#E03131` | `#C92A2A` | `#FDECEC` | `#F6B9B9` | `--color-danger*` | `danger*` |
| Thông tin | `#0B72BC` | `#0E3F63` | `#E2F2FD` | `#95CFF9` | `--color-info*` | `info*` |

Dùng 3.3 cho **thông điệp** (có chuyện gì vừa xảy ra); dùng 3.2 cho **trạng thái của một bản ghi**. Chữ màu trên nền nhạt dùng bậc đậm (`-fg`, `-700`, `-800`), không dùng màu chính.

Token Flutter cho mỗi nhóm phản hồi: `success/successText/successSoft/successBorder`, tương tự `warning`, `danger`, `info`. Bảng trên là giá trị chuẩn. `AppButton` danger dùng `dangerSoft` + `dangerText`, không nền đỏ đặc chữ trắng.

### 4.3 Ánh xạ Flutter

Để các widget Material mặc định dùng đúng nền CTA, **`ColorScheme.primary` ánh xạ tới `AppColors.brand`**, không tới token Dart `AppColors.primary`. Đây là khác nhau giữa tên role Material và tên token CareNest; cấu hình một lần, không đảo qua lại giữa feature.

| Flutter | Token CareNest | Dùng |
| --- | --- | --- |
| `ColorScheme.primary` / `onPrimary` | `brand` / `onBrand` | Nút chính |
| `primaryContainer` / `onPrimaryContainer` | `primarySoft` / `onBrand` | Container chọn; component có thể dùng chữ `primary` theo mục 8 |
| `secondary` / `onSecondary` | `primary` / `surface` | Role phụ; link đọc `AppStatusColors.primary` |
| `secondaryContainer` / `onSecondaryContainer` | `primarySoft` / `onBrand` | Vùng phụ được chọn |
| `error` / `onError` | `danger` / `surface` | Role lỗi Material; nút danger vẫn dùng container nhạt |
| `errorContainer` / `onErrorContainer` | `dangerSoft` / `dangerText` | Container lỗi |
| `surface` / `onSurface` / `onSurfaceVariant` | `surface` / `textPrimary` / `textSecondary` | Bề mặt và chữ |
| `outline` / `outlineVariant` | `borderStrong` / `border` | Viền |
| `scrim` | `overlay` | Nền sau dialog/sheet, không blur |
| `ThemeData.scaffoldBackgroundColor` | `background` | Nền màn |
| `ThemeExtension<AppStatusColors>` | `brandPressed`, `primary`, `primaryPressed`, `focusRing`, `textMuted`, `textDisabled`, `track`, màu phản hồi và các tông mục 6 | Widget chung đọc extension |

`ColorScheme.fromSeed` không bảo đảm màu sinh ra giống token nguồn. Ghi đè role cần dùng và kiểm tra các cặp `on…`. Không để màu tự sinh hoặc mặc định Material đi vào component CareNest. Token `background` dùng qua Scaffold, không dùng `ColorScheme.background` đã deprecated. [S10, S11]

### 4.4 Luật dùng màu

- Dùng lớp semantic theo ý nghĩa; không đặt màu theo tên màn và không hardcode màu trong feature.
- Không dùng riêng màu để truyền đạt thông tin; luôn có nhãn, thêm icon/chú giải khi cần.
- Không tự tô đánh giá sức khỏe nếu backend không trả nhãn đã được chốt (HLT-02, P-13).
- Màu từ dữ liệu như ảnh/avatarColor là ngoại lệ; có fallback và kiểm tra chữ dễ đọc. Mock/fixture/test/demo không dùng dữ liệu hoặc ảnh trẻ thật.
- Chỉ **Light Theme**, `themeMode: ThemeMode.light`. Chưa bật Dark/System Theme khi nguồn chung chưa có bộ token tối.
- Thiếu token/variant: cập nhật Design System, token cả hai repo và widget test (§7.4). Không tự thêm màu tại màn hình.

---

<a id="section-5"></a>
## 5. Chữ, kích thước, khoảng cách và chuyển động

Theo Design System §3.4–3.9. Kích thước Flutter dùng **logical pixel**; số trong bảng là giá trị nền trước text scaling. Không chuyển số desktop theo một tỷ lệ cố định.

### 5.1 Typography

Font đóng gói `BeVietnamPro`; định nghĩa tập trung trong `app_text_styles.dart` và `TextTheme`.

| Vai trò | TextTheme | Cỡ app | Độ đậm |
| --- | --- | --- | --- |
| Tiêu đề màn/tab | `headlineSmall` | 22 | 700 |
| Lời chào trên tranh | `displaySmall` | 26 | 700 |
| Số lớn/KPI/số đo | `headlineMedium` | 28 | 700 |
| AppBar/hộp thoại | `titleLarge` | 18 | 600 |
| Tiêu đề card | `titleMedium` | 17 | 700 |
| Tiêu đề dòng/nhãn ô nhập | `titleSmall` | 16 | 600 |
| Nội dung chính | `bodyLarge` | 16, dòng 1,5 | 400 |
| Nội dung phụ/meta | `bodyMedium` | 14 | 400 |
| Chữ nút | `labelLarge` | 16 | 700 |
| Badge/chip/ngày giờ phụ | `labelMedium` | 13 | 600 |
| Nhãn nhóm in hoa | `labelSmall` | 12, giãn 0,06em | 600 |

Giãn 0,06em của labelSmall tương đương letterSpacing 0,72 logical pixel ở cỡ nền 12, khai báo tại app_text_styles.dart.

400 cho nội dung, 500 cho menu/tab, 600 cho nhãn/chữ nhấn/mã chứng từ, 700 cho tiêu đề/card/nút/số lớn. **Không 800.** Chữ 12 chỉ dành cho nhãn/giờ phụ. Số căn cột dùng `FontFeature.tabularFigures()` trong style chung.

Không khóa `textScaler`. Kiểm tại 1,0 / 1,3 / 2,0. Nội dung xuống dòng, không ellipsis; ngoại lệ tiêu đề AppBar và dòng danh sách tối đa 2 dòng. Không cắt thông tin quan trọng để giữ chiều cao card. [S2]

### 5.2 Khoảng cách

| AppSpacing | Giá trị |
| --- | --- |
| `space1` | 4 |
| `space2` | 8 |
| `space3` | 12 |
| `space4` | 16 |
| `space5` | 20 |
| `space6` | 24 |
| `space8` | 32 |
| `space10` | 40 |

Không dùng `space7 = 32`; đổi mọi tham chiếu sang `space8`.

| Áp dụng | Giá trị app |
| --- | --- |
| Lề màn | 16; 20 khi chiều rộng cửa sổ ≥400 |
| Padding card chuẩn / dày | 20 / 16 |
| Giữa card | 12 |
| Giữa section | 24 |

### 5.3 Bo góc

| AppRadius | Giá trị | Áp dụng |
| --- | --- | --- |
| `xs` | 6 | Chi tiết nhỏ theo component |
| `sm` | 12 | Ảnh thu nhỏ, ô lịch |
| `md` | 14 | Theo component chung |
| `lg` | 16 | Banner, toast |
| `xl` | 20 | Ô nhập nhiều dòng, tranh màn trống |
| `xxl` | 24 | Card, thẻ số liệu |
| `xxxl` | 32 | Dialog, sheet mép trên |
| `pill` | 9999 | Nút, badge, chip, segmented, ô nhập một dòng |

Ô icon 40 và avatar dùng hình tròn. Bo lồng nhau: bo trong = bo ngoài − khoảng cách hai mép; phép tính nằm trong component/token, không tự viết số ở feature.

### 5.4 Kích thước

| AppSizes / vai trò | Giá trị nền |
| --- | --- |
| `buttonHeight` / `buttonSmallHeight` | 52 / 44 |
| `inputHeight` | 52 |
| `minimumTapTarget` | 48×48 |
| `badgeHeight` | 28 |
| `filterChipHeight` | 36 |
| `listRowMinHeight` | 64 |
| `iconTileSize` | 40 |
| `iconInline` / `iconTile` / `iconNavigation` | 20 / 22 / 24 |
| `iconBadge` | 14 theo component badge ở Design System §6.1 |
| `appBarHeight` | 56 |
| `bottomNavigationHeight` | 72 + safe area |
| `navigationIndicatorWidth` / `navigationIndicatorHeight` | 64 / 32 |
| `heroHeight` | 224 |
| `emptyIllustrationWidth` / `emptyIllustrationHeight` | 168 / 124 |

Tên AppSizes là adapter đề xuất cho các kích thước đã có trong Design System; dùng thống nhất trong `sizes.dart`. 52 là chiều cao nền, không ép form/nút cắt chữ tại text scaling lớn. Nút nhỏ 44 và chip tương tác 36 vẫn phải có **vùng chạm ≥48×48**. Badge không tương tác có thể cao 28.

### 5.5 Bóng và chuyển động

`AppShadows.card` có đúng hai lớp theo Design System §3.8:

```dart
// Chỉ khai báo trong AppShadows, không đặt tại feature.
BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
BoxShadow(color: Color(0x400B72BC), blurRadius: 40,
  spreadRadius: -20, offset: Offset(0, 16)),
```

Lớp nổi dùng `AppShadows.overlay` tương đương `--shadow-xl` của web. Design System nguồn không ghi số đầy đủ của `--shadow-xl`; khi nối repo lấy từ `tokens.css`, không tự chọn bóng Material để coi là đã đồng bộ. Nút không bóng. Focus dùng vòng 3 với `focusRing` qua theme.

| AppMotion | Giá trị | Dùng |
| --- | --- | --- |
| `curve` | cubic-bezier(0.4, 0, 0.2, 1) | Đường cong chung, không nảy |
| `fast` | 150 ms | Nhấn/tab/chip |
| `overlay` | 180 ms | Mở lớp nổi |
| `base` | 300 ms | Chuyển màn/mở rộng |
| `toast` / `toastError` | 3,5 s / 6 s | Toast thường/lỗi |
| `skeletonPulse` | 1,2 s | Khung chờ |

Giá trị chuyển động phụ cũng đặt trong `motion.dart`: nhấn nút scale 0,98; lớp nổi mờ 0→1 + scale 0,95→1 + dịch 4; skeleton độ mờ 0,6↔1; toast có thanh đếm ngược 3; segmented trượt nền ô chọn. Loading dùng ba chấm `primary`, `brand`, `accent` nhảy lần lượt; progress đang chạy có sọc.

Tôn trọng `MediaQuery.disableAnimations`: tắt hiệu ứng, **giữ thanh đếm ngược toast** theo Design System. Không dựng thời lượng/curve riêng ở feature.

### 5.6 Responsive, bàn phím và SafeArea

- Bố cục app chuẩn **một cột**, thanh điều hướng đáy + AppBar màn con. Không tự chuyển sang NavigationRail/hai cột tại mốc 600 như guide cũ; nếu cần kiểu tablet mới, bổ sung ngoại lệ vào Design System §1.3 trước.
- Đo chiều rộng cửa sổ bằng `LayoutBuilder`/`MediaQuery`; dùng mốc 400 cho lề màn. Không suy theo tên thiết bị. [S3]
- Form cuộn, có focus và input action phù hợp; thanh nút dính đáy ở trên bàn phím. Không cố định chiều cao khối text/card.
- `SafeArea` tránh notch/home indicator; không cộng inset hai lần vào AppBar/Scaffold/thanh đáy.
- Kiểm ở 360–430 logical pixels, thêm màn hẹp khoảng 320, cửa sổ rộng và xoay ngang; chữ lớn 2,0 không mất nội dung hoặc thao tác.

---

<a id="section-6"></a>
## 6. Badge và ánh xạ trạng thái

Theo Design System §3.2. Chuẩn hóa **cách hiển thị**; không tự định nghĩa vòng đời hoặc mã enum backend.

### 6.1 Tông thống nhất

```dart
enum AppStatusTone { gray, orange, blue, approval, red, green, teal }
```

| Tông | Màu | Chữ | Nền | Nghĩa |
| --- | --- | --- | --- | --- |
| `gray` | `#7B8AA0` | `#556377` | `#EAECF0` | Nháp, đã hủy, ngừng, chưa có |
| `orange` | `#F5820B` | `#944F06` | `#FDEBD8` | Chờ người khác làm, cần để ý |
| `blue` | `#2BA0F3` | `#0E3F63` | `#DDF0FD` | Đang thực hiện, đã gửi |
| `approval` | `#F5B400` | `#835C00` | `#FDF3D6` | Chờ người duyệt/phê duyệt |
| `red` | `#F0475A` | `#A63749` | `#FDE2E5` | Cần xử lý, bị trả lại |
| `green` | `#22B573` | `#176F51` | `#DCF3E9` | Hoàn tất |
| `teal` | `#13B5B1` | `#0F6C71` | `#D9F3F3` | Nhãn thông tin |

Dùng đúng mã nền đã liệt kê trong nguồn chung; viền pha màu tông 34% trên trắng, tính một lần trong token. Không dùng màu feedback mục 4.2 thay cho tông bản ghi. Chữ luôn lấy màu đậm của tông; không dùng màu tông chính làm chữ trên nền nhạt.

Web giữ tên legacy `purple` nhưng nó là **vàng chờ duyệt** (`--tone-approval`), không còn màu tím. App dùng `approval`. Đổi enum cũ `{ neutral, info, warning, purple, danger, success, teal }` sang tên mới và rà từng bảng mapping; không đổi bằng thay chuỗi toàn cục vì `warning/danger/success/info` vẫn là tên phản hồi.

`approval` chỉ cho chờ người duyệt. “Chờ xử lý chênh lệch” dùng tông này khi thật sự chờ duyệt; nếu chỉ chờ xử lý công việc thì dùng `orange` theo ý nghĩa. Không dùng vàng chờ duyệt để trang trí.

### 6.2 Widget và mapping theo feature

`AppStatusBadge(label, tone, icon)` dạng viên thuốc, cao nền 28, chữ 13/600, icon 14 khi có. Cùng mã backend và cùng nhóm người đọc ở web/app phải có cùng nhãn, tông và icon. Feature có một bảng map tại `features/<feature>/presentation/<feature>_status.dart`; domain không phụ thuộc màu/icon Flutter.

| Feature/trạng thái từ backend | Phụ huynh | Nhân viên | Tông |
| --- | --- | --- | --- |
| Điểm danh: có mặt | Đã đến lớp | Có mặt | `green` |
| Điểm danh: vắng có phép/có thông báo nghỉ | Nghỉ có báo | Có phép | `orange` |
| Điểm danh: vắng không phép | Nghỉ không báo | Không phép | `red` |
| Thông báo nghỉ: `SUBMITTED` | Đã gửi | Đã gửi | `blue` |
| Thông báo nghỉ: `CANCELLED` | Đã hủy | Đã hủy | `gray` |
| Chứng từ: chờ duyệt | Theo quyền xem | Chờ duyệt | `approval` |
| Tài sản: Tốt / Bình thường / Cần sửa / Hỏng | Theo phạm vi | Giữ nhãn tương ứng | `green` / `blue` / `orange` / `red` |

Các mô tả điểm danh/chứng từ trong bảng không phải tên enum BE; dùng mã thật từ hợp đồng. Thông báo nghỉ **không thêm trạng thái chờ duyệt** (ATT-05).

- Tông `blue` không có icon thì có chấm phát sáng; hiệu ứng tắt khi giảm chuyển động.
- Chờ ghi rõ **chờ ai** khi BE trả dữ liệu; không tự đoán người xử lý.
- Nhãn vai trò của tôi/người liên quan (“Người nhận”, “Người bàn giao”, “Tôi”) dùng `teal`; thiếu/hư hỏng/dị ứng dùng `red`; thừa/lệch sổ sách dùng `orange`.
- Banner cảnh báo dị ứng trong màn Thực đơn dùng feedback warning, khác với chip phân loại dị ứng `red`.
- Màu không đứng một mình: badge có chữ, lịch có chú giải. Badge bấm được phải đủ vùng chạm và semantics.

---

<a id="section-7"></a>
## 7. Widget dùng chung và icon

Theo Design System §5–6. App dùng `lib/core/widgets/`; feature không gọi trực tiếp widget Material để tạo style riêng cho cùng loại control. Widget Material có thể là phần triển khai bên trong wrapper chung.

### 7.1 Danh mục đích

“Cần bổ sung” theo Design System 3.1 là trạng thái được nguồn ghi nhận, **chưa kiểm chứng mã nguồn repo**. Các widget có tên trong guide cũ cũng phải rà lại style trước khi coi là đạt bản mới.

| Thành phần | Widget app | Hình và hành vi chung |
| --- | --- | --- |
| Nút | `AppButton` | Primary/secondary/text/danger; viên thuốc, chữ 16/700, cao 52; primary `brand/onBrand`; secondary trắng + `borderStrong`; danger `dangerSoft/dangerText`; không bóng |
| Ô nhập | `AppTextField`, `AppPasswordField` | Một dòng viên thuốc, cao nền 52; nhiều dòng bo 20; nhãn trên, hint/error dưới; focus viền `primary` + vòng `focusRing`; mật khẩu ẩn/hiện; icon trái tuỳ chọn (`leadingIcon`, khi mockup có); khoá (`enabled: false`) nền `surfaceMuted` |
| Card | `AppCard` | Trắng đặc, bo 24, padding 20 (dày 16), bóng card; đầu card ô icon + tiêu đề + link |
| Badge | `AppStatusBadge` | Viên thuốc, nền/viền/chữ đúng tông mục 6; cao 28 |
| Chip lọc | `AppFilterChip` | Viên thuốc viền; chọn nền `primarySoft`, chữ `onBrand`; vùng chạm ≥48 |
| Thẻ số liệu | `AppStatCard` — cần bổ sung | Nhãn trên, số lớn màu đậm theo tông, icon mờ ở góc, nền chuyển nhẹ; có mũi tên khi bấm được |
| Ô số liệu gọn | `AppStatTile`, `AppStatRow` | Số lớn + nhãn dưới, nền/viền/chữ theo tông mục 6; hàng chia đều, chữ phóng >1,3 xuống lưới 2 cột (mockup 2026-10-13) |
| Đầu trang chủ | `AppHeroHeader`, `AppHeroBell` | Dải nền `brand`, chữ `onBrand`, lời chào + tên, chuông có số chưa đọc; card ngữ cảnh đè mép dưới dải. Thay hero tranh khi chưa có bộ tranh (§3.2) |
| Việc cần làm | `AppTaskCard` | Card trắng + `AppListRow`: ô icon, tên, mô tả, badge; việc cần làm ngay viền `primary` |
| Dải ngày | `AppDayStrip` | Ô T2…CN + ngày/tháng; ô chọn nền `brand`; vùng chạm ≥48 |
| Lịch tháng | `AppMonthCalendar` | Thứ Hai đầu tuần; chấm theo tông + nhãn semantics; cuối tuần chữ mờ; ngày chọn tròn `primary` |
| Dòng thời gian | `AppTimeline` | Cột giờ tuỳ chọn · chấm + đường nối · nội dung; mốc đang diễn ra chấm đặc, nền `primarySoft` |
| Tìm kiếm | `AppSearchField` | Viên thuốc, icon kính lúp, không nhãn trên ⇒ có nhãn semantics; `matchesSearch` lọc không phân biệt dấu |
| Ảnh giữ chỗ | `AppPhotoPlaceholder` | Khối `primarySoft` + icon ảnh, chữ dưới, "+N" ở ô cuối; dùng khi chưa có ảnh qua URL có auth, không dùng ảnh trẻ thật |
| Ô chọn | `AppSelectField` | Cùng khung ô nhập, mũi tên xuống; màn mở `AppBottomSheet` để chọn |
| Mã OTP | `AppOtpField` | Ô số rời, một `TextField` ẩn nhận phím/dán/autofill; ô đang nhập viền `primary` |
| Segmented | `AppSegmented` | Rãnh `track`, ô chọn trắng trượt; count lấy BE; tab/menu đậm 500 |
| Banner | `AppBanner` | Màu nhạt theo nghĩa phản hồi, không viền, icon trơn, bo 16 |
| Toast | `AppToast` — cần bổ sung | Nền màu theo loại, icon tròn, thanh đếm ngược 3; mép trên dưới status bar; 3,5 s / lỗi 6 s |
| Xác nhận | `AppConfirmationDialog` | Icon lớn giữa trong vòng tròn tông, tiêu đề + mô tả; nút lặp đúng hành động, phụ “Quay lại”; bo 32 |
| Sheet | `AppBottomSheet` | Trắng, bo trên 32, bóng lớp nổi, scrim `overlay` không blur; focus/Back/semantics phù hợp |
| Gửi form | `AppSubmitOverlay` | Phủ trắng, ba chấm “Đang gửi…” → “Đã gửi” hoặc lỗi + “Thử lại”; giữ form |
| Loading | `AppLoading` | Ba chấm `primary/brand/accent`; không spinner quay |
| Skeleton | `AppSkeleton` | Đúng hình nội dung, nhịp thở theo `AppMotion` |
| Rỗng/lỗi | `AppEmptyState`, `AppErrorState` | Rỗng có tranh nhỏ; lỗi có icon + câu cụ thể + “Thử lại” |
| View bất đồng bộ | `AppAsyncView` — adapter của guide | Điều phối lần đầu/refresh/rỗng/lỗi bằng widget chuẩn; không thêm style/variant riêng |
| Tiến trình | `AppProgressBar` — cần bổ sung | Chuyển sắc cùng họ + sọc; xong xanh lá “Hoàn thành”; tổng 0 hiển thị “—”; dữ liệu BE |
| Avatar | `AppAvatar` | Tròn, chữ đầu tên, pastel theo công thức mục 7.3 |
| Nhãn–giá trị | `AppInfoList` — cần bổ sung | Một cột; nhãn muted + giá trị chính; thiếu theo nhóm người đọc |
| Dòng danh sách | `AppListRow` | Trong card, sọc/kẻ nhạt, cả dòng bấm được nếu có đích; cao ≥64; tải thêm |
| Bước | `AppStepper` — cần bổ sung | Wizard/tiến trình chứng từ theo dữ liệu được chốt; bước hiện tại `primary` |
| Logo | `AppLogo`, `AppWordmark` | Theo mục 3.1, không thêm style logo ở feature |

Cơ chế danh sách dài: `ListView.builder`/sliver; refresh dùng `RefreshIndicator`. Chọn/tìm kiếm/bộ lọc ngắn dùng wrapper `AppBottomSheet`; form dài mở màn riêng. `AppFilterSheet` có thể là composition của sheet + control chung, không tạo design variant mới. Chuông/danh sách thông báo thuộc `features/notifications`, không chứng minh push đã tích hợp.

Kết quả thao tác dùng `AppToast`; controller trả kết quả và UI gọi helper. Không dùng SnackBar Material mặc định trong feature. Khi chưa có component cần thiết, bổ sung wrapper + widget test; không dựng tạm một kiểu khác ở màn.

### 7.2 Icon

- Đích chung **Tabler outline**, nét app 1,75. Chỉ `lib/core/constants/app_icons.dart` import bộ icon.
- Tên ánh xạ giống web `src/components/ui/icons.js`, đổi lowerCamel: `Save` → `save`. Cùng chức năng cùng tên/icon; icon mới thêm tên ở web và app cùng đợt.
- Gói Tabler Flutter còn **OPEN**. Trước khi chốt dependency, `AppIcons` tạm ánh xạ `Icons.*_rounded` theo ngoại lệ đã có trong Design System §15. **Không `Icons.*`/`TablerIcons.*` trực tiếp trong feature.**
- Icon một màu theo chữ cạnh nó, đứng trước chữ trong nút. Ô icon dùng `primarySoft/primary` hoặc nền/chữ theo tông.
- Icon đơn có tooltip hoặc `Semantics`; không emoji làm biểu tượng. Giữ kích thước theo mục 5.4.

### 7.3 Avatar

Cùng người cùng màu ở hai nền tảng: tổng mã ký tự của tên mod 5, giống hàm `avatarTone` trong web `src/utils/format.js`. Khi nối code phải đối chiếu cách web duyệt tên/chuỗi để giữ đúng kết quả, không dùng hash khác ở Dart.

| Tông | Nền | Chữ |
| --- | --- | --- |
| 0 | `#E2F2FD` | `#0B72BC` |
| 1 | `#FCE7F3` | `#BE185D` |
| 2 | `#DCFCE7` | `#15803D` |
| 3 | `#FEF3C7` | `#B45309` |
| 4 | Tông teal pha 14% trên trắng | `#0F6C71` |

Màu avatar khai báo trong token. Mặc định chữ đầu tên; ảnh thật chỉ khi BE trả URL có quyền. Không ảnh trẻ thật trong mock/fixture/test/demo.

### 7.4 Kiểm component và đổi component

App **không có UiKitScreen** (user bỏ, 2026-10-10). Đây là chỗ lệch Design System chung, cần đồng bộ bên web. Thay vào đó, mỗi widget chung có widget test ở `test/core/widgets/` phủ các trạng thái chính (selected/disabled/loading/error) và badge đủ 7 tông. Mỗi màn kiểm text scaling 2,0 bằng widget test.

Component/variant mới phải cập nhật Design System §6 và widget test; component chưa có ở repo kia ghi rõ. Mẫu cùng nghĩa dùng từ hai chỗ chuyển lên dùng chung. Đổi token cần cập nhật cả `tokens.css`, `colors.dart` và tài liệu chung, kèm ảnh trước–sau.

---

<a id="section-8"></a>
## 8. Khung ứng dụng và công thức màn hình

Theo Design System §7.2–8.2. Đây là chuẩn bố cục; quyền và field thật vẫn theo backend/SRS.

### 8.1 Khung ứng dụng

| Phần | Quy chuẩn app |
| --- | --- |
| AppShell | Nội dung một cột + thanh điều hướng 3–5 đích; giữ tab/scroll khi cần |
| Màn tab | Tiêu đề lớn trong nội dung; Hôm nay có hero |
| Màn con | AppBar trắng cao 56, nút Back, tiêu đề căn trái |
| Thanh đáy | Cao 72 + safe area; nhãn luôn hiện; icon 24 |
| Đích đang chọn | Viên 64×32 `primarySoft` sau icon; icon/nhãn `primary` |
| Số chưa đọc | Viên nền `danger`, chữ `surface` trắng; có semantics |
| Ngữ cảnh con/lớp/điểm trường | Chip avatar/tên + mũi tên, mở `AppBottomSheet` chọn |
| Vùng hành động form/chi tiết | Nút dính đáy, nền đặc, tránh bàn phím/home indicator |
| Điều hướng chi tiết | Route con hoặc bottom sheet cho chi tiết ngắn; không breadcrumb desktop |
| Phiên bản/hỗ trợ | Màn Tài khoản/Giới thiệu; không footer toàn app |

Mỗi vùng thao tác **một nút chính**. **App không dùng FAB.** Không tạo số liệu/lối tắt ngoài phạm vi hoặc số đếm suy từ một trang dữ liệu.

Các đích khai báo một lần ở `navigation_destinations.dart`, chọn theo quyền backend. `AppShell` không lồng hai AppBar/Scaffold. Back Android/iOS nhất quán; deep link chờ kiểm tra phiên và quyền; chỉ chuyển sau đăng nhập tới đường dẫn nội bộ đã kiểm tra.

### 8.2 Công thức màn

| Loại | Bố cục app |
| --- | --- |
| Hôm nay/tổng quan | Hero + card theo mức quan trọng (tối đa 3) + 1–2 lối tắt trong phạm vi |
| Danh sách | AppBar/tiêu đề tab + segmented/dải ngày + card chứa dòng nhóm theo ngày + tải thêm; giữ scroll/filter |
| Việc của tôi | Segmented trạng thái → dòng danh sách; count chỉ khi BE trả |
| Chi tiết ngắn | Bottom sheet; có lối mở màn con khi cần |
| Chi tiết chứng từ | Màn con, card thông tin xếp dọc → lịch sử → chữ ký nếu thuộc phạm vi → nút dính đáy |
| Tạo/sửa | Một cột, form cuộn theo section/card → lỗi dưới trường → nút dính đáy |
| Form nhiều bước | AppStepper + nội dung bước + Back/Next; không thêm bước nghiệp vụ |
| Thao tác được giao | Banner hướng dẫn → thông tin → vùng nhập → chữ ký được phép → nút |
| Hồ sơ | Avatar/thông tin đầu hồ sơ → danh sách lối vào |
| Đăng nhập | Tranh trên → logo/lời chào → sheet trắng chứa form dưới |
| OTP, khi có trong hợp đồng | Giữ nhận diện auth; đích nhận mã che bớt → nhập/dán mã → gửi lại theo hạn BE |
| Tải/lỗi phiên | AppLoading hoặc lỗi + Thử lại, không chớp login rồi nhảy vào app |

Không thêm khối gợi ý, số liệu bịa, chức năng in A4 hoặc form desktop nhiều cột.

### 8.3 Hành vi mobile

- Kéo refresh khi phù hợp; giữ dữ liệu/bộ lọc, không ghi đè form đang nhập.
- Back có thay đổi chưa lưu xử lý theo thiết kế, dùng cơ chế như `PopScope`; không chặn mọi thao tác Back.
- Background không tương đương logout; resume có thể kiểm tra/tải lại phiên, không tự mất form.
- Xin quyền camera/ảnh/file khi thao tác, có đường tiếp tục/mở cài đặt nếu bị từ chối.
- Mất mạng có trạng thái rõ; Wi-Fi không chứng minh API truy cập được. Chưa có đồng bộ thì không báo đã gửi offline.
- Giữ form khi request lỗi; draft bền qua đóng app chỉ khi có thiết kế riêng.
- Đổi tài khoản/đăng xuất dọn dữ liệu riêng tài khoản; không thoáng hiện dữ liệu người trước. Push/màn khóa không mang dữ liệu sức khỏe.

### 8.4 Nhóm người dùng và tab

Design System nguồn nêu Phụ huynh, Giáo viên, Bếp; tab giáo viên là PROPOSED, bếp cần đối chiếu phạm vi. Giữ kiểm tra SRS/Screen Flow và mã backend của bản mobile; **không bật thêm role chỉ do có mẫu UI**.

| Nhóm | Mã backend cần đối chiếu | Tab theo Design System | Trạng thái |
| --- | --- | --- | --- |
| Phụ huynh | `PARENT` | **Trang chủ · Bé của tôi · Thông báo · Tài khoản** | Theo mockup (user 2026-10-13); quyền/field cần backend chốt |
| Giáo viên | `TEACHER` | **Trang chủ · Lớp học · Thông báo · Tài khoản** | Theo mockup (user 2026-10-13); màn con theo SRS |
| Nhân viên bếp | `KITCHEN_STAFF` | **Trang chủ · Thực đơn · Thông báo · Tài khoản** | Theo mockup (user 2026-10-13); quyền theo AUTH-05 |
| Phó Hiệu trưởng | Vice Principal (mã BE chưa có) | **Trang chủ · Duyệt · Thông báo · Tài khoản** | User chốt có trên app 2026-10-13; BE `USER_ROLES.md:21` còn ghi chỉ Web; scope campus AUTH-02 |
| Hiệu trưởng | Principal (mã BE chưa có) | **Tổng quan · Duyệt · Thông báo · Tài khoản** | User chốt có trên app 2026-10-13; BE `USER_ROLES.md:20` còn ghi chỉ Web; scope toàn trường AUTH-01 |
| Tổ trưởng | `TEAM_LEADER` hoặc quyền/cờ của `TEACHER` | Khung giáo viên + chức năng được phép | OPEN; không mặc định tạo role riêng |

Chỉ đăng ký cấu hình của nhóm đã được duyệt. Phó Hiệu trưởng và Hiệu trưởng được user chốt đưa lên app (2026-10-13, plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`); nhân viên văn phòng vẫn không có. User không chọn role ở login; role không hỗ trợ có thông báo rõ, không mặc định Teacher.

`route_access_policy.dart` kiểm tra cả route trực tiếp/deep link và dữ liệu đích còn tồn tại; ẩn tab/nút chỉ là UX, BE vẫn kiểm quyền từng API. Bản mobile trước ghi tài khoản phụ huynh do Phó hiệu trưởng tạo và SMS mời: giữ là NEEDS VERIFICATION; không thêm tự đăng ký. Kích hoạt/đặt mật khẩu ban đầu tách khỏi OTP login.

### 8.5 Công thức màn phụ huynh

Theo Design System §8.2. Chỉ hiển thị field mà DTO có và quyền cho phép; P-13b còn OPEN. Mã rule dưới đây là dẫn chiếu của nguồn, chưa thay thế việc đọc SRS/BE.

| Màn | Thành phần theo thứ tự |
| --- | --- |
| Đăng nhập | Tranh · logo · “Chào mừng phụ huynh” · tài khoản · mật khẩu · “Quên mật khẩu” · “Đăng nhập”; không đăng ký; form/Keycloak theo backend |
| Hôm nay | Hero + lời chào + chip chọn con · Điểm danh (badge + giờ) · Bữa ăn hôm nay · Cập nhật mới; trường nghỉ thì banner xám thay card Điểm danh |
| Bé | Avatar + chip chọn con + lớp/điểm trường · lối vào Điểm danh/Thực đơn/Sức khỏe/Cập nhật phát triển/Thông báo nghỉ · Thông tin của bé |
| Điểm danh | Segmented Tuần/Tháng · lịch chấm đúng tông + chú giải · tổng chỉ khi BE trả |
| Thực đơn | Dải ngày · banner warning dị ứng nếu BE trả · mỗi bữa một card, món một dòng; chỉ thực đơn đã công bố (NUT-08) |
| Sức khỏe | Lần đo gần nhất/số lớn · biểu đồ một màu `primary` · lần khám; không tự tô đánh giá (HLT-02, P-13); AI chỉ khi đã duyệt (HLT-05) |
| Cập nhật phát triển | Dòng thời gian theo tháng, phần xem trước 3 dòng theo công thức nguồn, mở chi tiết để đọc đủ; chỉ mục đã duyệt (OBS-03/05) |
| Thông báo nghỉ | Danh sách Đã gửi/Đã hủy, không chờ duyệt (ATT-05) · form Từ–Đến ngày/lý do chip/ghi chú · AppSubmitOverlay · chi tiết/toast/banner BE · danger “Hủy thông báo nghỉ” |
| Thông báo | Nhóm Hôm nay/Hôm qua/Trước đó, chấm chưa đọc có semantics |
| Tài khoản | Avatar + tên + SĐT · Con của tôi · cài đặt · danger “Đăng xuất” |

Màn giáo viên/bếp chưa có công thức chi tiết trong nguồn chung: dùng token/component/mẫu §8.2 của guide, chỉ thêm field và thao tác sau khi yêu cầu được chốt.

---

<a id="section-9"></a>
## 9. Theme và tổ chức style

Flutter không dùng CSS/BEM; **hành vi và hình thức** vẫn phải khớp Design System. Không để mặc định Material thay thế token/component CareNest.

| Nơi | Nội dung |
| --- | --- |
| `core/constants/colors.dart` | Màu nền, tông bản ghi, phản hồi, avatar, logo, kính |
| `core/constants/sizes.dart` | AppSpacing, AppRadius, AppSizes, AppShadows |
| `core/constants/motion.dart` | AppMotion và tham số hiệu ứng |
| `core/constants/app_icons.dart` | Một điểm import bộ icon, ánh xạ giống web |
| `core/constants/asset_paths.dart` | AppAssets, logo, font, tranh |
| `core/theme/app_theme.dart` | ThemeData/ColorScheme, component theme, Light Theme |
| `core/theme/app_text_styles.dart` | TextTheme đúng mục 5.1; không cỡ chữ ở feature |
| `core/theme/app_status_colors.dart` | ThemeExtension; tông và màu semantic ngoài ColorScheme |
| `core/widgets/` | Wrapper/component chung, đúng mục 7 |
| `<feature>/presentation/widgets/` | Composition và nội dung riêng feature |

Số trong `EdgeInsets`, `SizedBox`, `BorderRadius` tại feature chỉ là 0 hoặc hằng AppSpacing/AppRadius/AppSizes. Giá trị động từ dữ liệu/layout phải qua API component phù hợp. `build()` không gọi API/storage/thay state. Chuyển widget chung khi cùng nghĩa/hành vi, không vì chỉ trông giống nhau.

### 9.1 Mẫu ColorScheme nền (PROPOSED)

Mẫu dưới đây đặt trong `core/theme/app_theme.dart`, giả định `AppColors` đã khai báo đủ theo mục 4. Đây là mẫu cấu hình, chưa phải code đã chạy trong repo.

```dart
import 'package:flutter/material.dart';
import 'package:carenest_app/core/constants/colors.dart';

ColorScheme buildLightColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.brand,
    onPrimary: AppColors.onBrand,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.onBrand,
    secondary: AppColors.primary,
    onSecondary: AppColors.surface,
    secondaryContainer: AppColors.primarySoft,
    onSecondaryContainer: AppColors.onBrand,
    error: AppColors.danger,
    onError: AppColors.surface,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.dangerText,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    scrim: AppColors.overlay,
  );
}
```

`ThemeData` dùng `useMaterial3: true`, scheme trên, `fontFamily: 'BeVietnamPro'`, `scaffoldBackgroundColor: AppColors.background`, TextTheme mục 5.1 và `ThemeExtension<AppStatusColors>`. `MaterialApp.router` dùng `ThemeMode.light`, không khóa textScaler. Role chưa ghi đè trong mẫu không được tự dùng làm màu mới cho UI. [S10, S11]

### 9.2 Hợp đồng theme/component

- `AppStatusColors` cung cấp link `primary`, pressed/focus, muted/disabled/track, phản hồi và 7 bộ tông gồm màu/chữ/nền/viền; triển khai copyWith/lerp và đăng ký ThemeData.extensions.
- AppButton: primary `brand/onBrand`, pressed `brandPressed`; danger nhạt `dangerSoft/dangerText`; bo pill, không bóng; loading ba chấm.
- Input: viền borderStrong, focus primary + vòng focusRing; màu lỗi theo feedback; label/hint/error có style chung.
- AppBar trắng, căn trái; NavigationBar cao 72 + safe area, nhãn luôn hiện, indicator 64×32; không để primary role Material làm icon chọn thành nền brand sai mục 8.1.
- Card trắng đặc bo 24 + AppShadows.card; banner/toast bo 16; dialog/sheet bo 32 + overlay không blur.
- Link đọc token `primary` qua extension; không lấy `colorScheme.primary` vì role đó là nền brand của nút.
- Theme input/button/card/navigation/sheet/dialog định nghĩa một lần, kiểm bằng widget test. Không tạo một theme khác ở mỗi feature.

Thiếu màu/token/variant → cập nhật Design System và hai repo trước khi dùng. Mẫu trên không thay thế toàn bộ theme/widget và kiểm thử dự án.

---

<a id="section-10"></a>
## 10. Kiến trúc và luồng dữ liệu

Dùng **Feature-based + Clean Architecture** với ba tầng `presentation`, `domain`, `data`. Repository là điểm chọn nguồn dữ liệu. Luồng chuẩn:

1. Screen/widget nhận thao tác người dùng.
2. Controller/Notifier quản lý state và gọi hợp đồng repository hoặc use case cần thiết.
3. Repository implementation phối hợp datasource và chuyển DTO thành entity.
4. Datasource gọi Dio hoặc lớp lưu cục bộ; mock repository trả dữ liệu demo qua cùng hợp đồng.
5. Kết quả trở về controller rồi UI; thông báo/điều hướng do presentation xử lý.

| Thành phần | Phụ thuộc được phép |
|---|---|
| Presentation | Domain, core UI, state library |
| Domain | Dart thuần và hợp đồng domain chung |
| Data | Domain, core network/storage, DTO, package hạ tầng |
| Core | Không import implementation của feature |
| Bootstrap/routing | Ghép các implementation và feature |

**Quy tắc:**

- Không gọi Dio hoặc secure storage trong screen/widget. `auth_local_data_source` dùng TokenStorage được inject.
- Controller không nhận `BuildContext` chỉ để gọi API; UI xử lý AppToast/AppConfirmationDialog/điều hướng theo kết quả.
- DTO map JSON ở tầng data, kiểm tra trường thiếu/không hợp lệ; không ép JSON trực tiếp vào widget.
- State bất biến; có trạng thái tải lần đầu, tải thêm, refresh và gửi form riêng khi cần.
- Phân biệt lỗi xác thực, thiếu quyền, validation, timeout, mạng, server và hủy request. Chuẩn hóa thành `AppFailure` thay vì hiển thị raw DioException/stack trace.
- Form có state riêng; kết quả tải lại không tự ghi đè các trường đã sửa. Thao tác async xử lý widget đã dispose/cancel đúng lifecycle.
- Request tìm kiếm có debounce nếu cần, bỏ kết quả cũ trả chậm; tải thêm chặn gọi lặp, giữ thứ tự và tránh trùng bản ghi.
- Mock là phục vụ demo/test. Không suy luận dữ liệu mock đã thể hiện đầy đủ hoặc bảo đảm quy tắc backend thật.
- Mobile native không dùng localStorage. Mock nên ở bộ nhớ hoặc fixture JSON; chỉ lưu qua lớp local khi có nhu cầu rõ. Preferences chỉ cho thiết lập không nhạy cảm; token theo mục 12.
- Không mở rộng feature mobile bằng cách sao chép mọi module của web. Phạm vi được xác định ở tài liệu yêu cầu riêng.

---

<a id="section-11"></a>
## 11. Quy trình thêm feature

Ví dụ đường dẫn `features/feature_name/` chỉ minh họa tổ chức, không định nghĩa nghiệp vụ mới.

1. Chốt màn hình, dữ liệu đầu vào/đầu ra và API với tài liệu yêu cầu.
2. Tạo entity và hợp đồng repository thuần Dart trong `domain/`.
3. Tạo DTO, remote datasource và repository implementation trong `data/`.
4. Nếu cần mock, tạo implementation cùng interface và fixture; chọn implementation ở bootstrap/provider, không if mock trong screen.
5. Tạo controller/state; bổ sung use case nếu có phối hợp hoặc logic tái sử dụng đáng kể.
6. Tạo screen/widgets theo mẫu mục 8 và Design System §8, dùng theme/token/component chung; thiếu thì bổ sung mục 7 và widget test, không dựng style tạm.
7. Đăng ký route tại `routing/app_router.dart`; route chờ xác thực và kiểm tra vai trò/quyền qua policy, kể cả deep link.
8. Chỉ thêm đích điều hướng cấp cao khi phù hợp; màn chi tiết không mặc định thêm tab.
9. Thử loading/rỗng/lỗi/mạng yếu/bàn phím/chữ lớn/Back; giữ nội dung form khi request thất bại.
10. Kiểm tra analyzer/format; chạy unit/widget/integration test phù hợp với phần thay đổi.
11. Cập nhật Design System chung, token hai repo và widget test khi tạo component/token chung; ghi ngoại lệ UI trong PR và đồng bộ phiên bản.

---

<a id="section-12"></a>
## 12. Đăng nhập, phiên và lưu token

Mục này mô tả xác thực. Khung vai trò/điều hướng ở mục 8.4; quy tắc kế thừa nghiệp vụ ở mục 18. API và OTP dưới đây là PROPOSED/OPEN cho tới khi backend và SRS chốt. Design System §15 còn mở form app/web hay Keycloak: chốt phương án trước khi tích hợp. Mẫu UI đăng nhập ở mục 8 không tự xác nhận cơ chế auth.

### 12.1 Chọn cơ chế cho native

| Kênh | Cơ chế trong guide | Nơi giữ thông tin xác thực |
|---|---|---|
| CareNest Web | Cookie HttpOnly | Trình duyệt, backend đặt cookie |
| Flutter Android/iOS | Bearer token | Access token trong bộ nhớ; thông tin khôi phục phiên trong secure storage nếu ghi nhớ |
| Flutter chạy web, nếu phát sinh | Hợp đồng web riêng | Không áp dụng máy móc secure-storage/Bearer của bản native |

Native gọi API bằng Bearer không có cơ chế trình duyệt tự gửi cookie gây CSRF, nên guide không bổ sung CSRF token cho luồng Bearer native. Web giữ bảo vệ cookie/CSRF; nếu native dùng hợp đồng cookie có CSRF thì phải tuân thủ yêu cầu backend ở mục 12.7.

`HttpOnly` là hạn chế JavaScript trong môi trường trình duyệt, không phải một chế độ lưu token của `flutter_secure_storage`. Code native cần đọc token để gắn Bearer; điều này không mâu thuẫn với quy chuẩn web không đọc cookie. `flutter_secure_storage` sử dụng cơ chế lưu bảo mật theo nền tảng, gồm Keychain trên iOS và encrypted storage trên Android. [S7]

**Hợp đồng mobile dưới đây là đề xuất mới cần thống nhất với backend**, không phải endpoint đã tồn tại. Nếu backend chỉ hỗ trợ cookie, chọn phương án 12.7 trước khi viết client.

### 12.2 API mobile đề xuất

Ví dụ base URL là `/api`, endpoint dưới đây tương đối với base URL:

| Endpoint | Gửi | Trả về |
|---|---|---|
| `POST /mobile/auth/login` | `{ email, password, remember }` | Không có OTP: `200 { accessToken, refreshToken, expiresAt, user }`; sai: `401 { message, code? }` |
| `POST /mobile/auth/refresh` | `{ refreshToken }` | `200 { accessToken, refreshToken, expiresAt }`; refresh token hết hạn/thu hồi: `401` |
| `GET /mobile/auth/me` | `Authorization: Bearer <accessToken>` | `200 user`; phiên không hợp lệ: `401` |
| `POST /mobile/auth/logout` | Access token nếu còn hợp lệ và thông tin thu hồi theo hợp đồng, ví dụ `{ refreshToken }` | `204`, backend thu hồi phiên; cần hỗ trợ refresh token để thu hồi ngay cả khi access token hết hạn |

Response có token chỉ gửi qua HTTPS, không cache và không log. Access token ngắn hạn; refresh token có thời hạn/rotation/thu hồi do backend quyết định. Không hardcode thời hạn vào UI.

Nếu đăng nhập yêu cầu OTP, thêm hợp đồng challenge:

| Endpoint | Gửi | Trả về |
|---|---|---|
| `POST /mobile/auth/login` | Thông tin đăng nhập | `{ requiresOtp: true, challengeId, maskedDestination, resendAt, expiresAt }`; chưa có phiên đăng nhập hoàn chỉnh |
| `POST /mobile/auth/otp/verify` | `{ challengeId, code }` | Bộ token và user sau xác minh thành công |
| `POST /mobile/auth/otp/resend` | `{ challengeId }` | Thông tin challenge/thời hạn mới theo backend |

OTP là phần tùy chọn của **luồng đăng nhập**; chỉ triển khai khi yêu cầu thực tế có OTP. Countdown ở app phục vụ hiển thị; backend quyết định mã hết hạn, số lần thử và gửi lại. Không cấp quyền truy cập màn bảo vệ trước khi xác minh xong.

### 12.3 Nơi lưu token và trách nhiệm

| Dữ liệu | Nơi giữ | Quy tắc |
|---|---|---|
| Access token | Bộ nhớ trong session manager | Dio interceptor đọc qua interface; không đưa vào widget state |
| Refresh token, khi ghi nhớ | `flutter_secure_storage` qua TokenStorage | Dùng để khôi phục phiên sau khi app bị đóng |
| Refresh token, không ghi nhớ | Bộ nhớ | Không ghi xuống thiết bị; app process kết thúc thì cần đăng nhập lại |
| User hiện tại | Auth state nhận từ backend | Không dùng user cache để kết luận đã xác thực |
| Mật khẩu/OTP | Form trong bộ nhớ | Không lưu, không log; dọn khi kết thúc form |
| Thiết lập không nhạy cảm | Preferences nếu cần | Không dùng cho token |

`auth_local_data_source.dart` gọi `core/storage/token_storage.dart`; `secure_token_storage.dart` là implementation plugin. Screen/controller không gọi plugin trực tiếp. Key đề xuất: `carenest.mobile.<environment>.refresh_token`, tránh dùng chung token giữa staging/production.

Khi chọn không ghi nhớ hoặc đổi tài khoản, xóa refresh token cũ của phiên trước. Không giữ token của tài khoản cũ rồi tự khôi phục lại. Nếu secure storage lỗi, báo rõ việc ghi nhớ thất bại; không tự hạ xuống file/preferences không bảo mật. Cấu hình platform/backup/accessibility theo package và kiểm tra trên thiết bị. [S7]

Backend không có refresh token thì cần điều chỉnh hợp đồng: có thể lưu access token trong secure storage khi ghi nhớ, nhưng không tự gia hạn được; token hết hạn phải đăng nhập lại. Không tự tạo refresh token ở client.

### 12.4 Khởi động và khôi phục phiên

1. Bootstrap khởi tạo storage, client, repository và auth controller.
2. Auth state bắt đầu `checking`; router hiển thị màn tải phiên.
3. Nếu không có phiên trong bộ nhớ/refresh token hợp lệ để thử: chuyển `unauthenticated` và mở LoginScreen.
4. Nếu có refresh token đã lưu: gọi refresh, cập nhật token đã rotate rồi gọi `/mobile/auth/me`.
5. Chỉ sau khi backend chấp nhận phiên mới chuyển `authenticated` và mở trang nội bộ được phép.
6. Refresh token bị từ chối/hết hạn: xóa token và yêu cầu đăng nhập. Lỗi mạng/5xx: hiển thị lỗi/thử lại, không xóa token chỉ vì không kết nối được.

Các trạng thái đề xuất: `checking`, `unauthenticated`, `authenticating`, `otpRequired` nếu có, `authenticated`, `error`. Không coi sự tồn tại một chuỗi token hoặc decode JWT ở app là bằng chứng phiên còn hợp lệ.

### 12.5 Dio interceptor và làm mới token

- Gắn `Authorization: Bearer <accessToken>` **chỉ với backend CareNest**; không đưa header này tới URL tải ảnh/file bên ngoài hoặc host khác. Kiểm soát redirect để không chuyển tiếp credential ra host ngoài.
- Không gắn access token vào login/OTP/refresh nếu hợp đồng không yêu cầu. Refresh dùng client riêng hoặc cờ bỏ qua auth-refresh interceptor để tránh vòng lặp.
- `401` từ login là lỗi đăng nhập; không tự refresh. `403` là lỗi quyền/chính sách, không tự logout.
- `401` của request cần xác thực có thể kích hoạt **một lần refresh đang chạy chung**; các request còn lại chờ cùng kết quả. Không tạo nhiều refresh song song dùng cùng refresh token.
- Lưu refresh token mới sau rotation trước khi coi refresh thành công. Nếu logout/đổi tài khoản trong khi refresh chạy, kết quả cũ không được khôi phục phiên; session manager kiểm tra phiên/generation hiện tại.
- Retry tối đa một lần sau refresh cho request đủ điều kiện. Không tự replay upload/stream hoặc thao tác ghi nếu không bảo đảm body có thể gửi lại và backend chưa thực hiện thao tác; dùng cơ chế idempotency khi API hỗ trợ.
- Refresh trả `401`: kết thúc phiên, xóa token, báo một lần. Refresh lỗi mạng/5xx: giữ thông tin khôi phục và cho thử lại; không gọi refresh đệ quy.
- Che/redact Authorization, password, OTP và refresh token trong log. Không bật log body xác thực trong release. [S4]

### 12.6 Đăng xuất và phiên demo

- Logout gọi backend để thu hồi phiên, sau đó dọn token bộ nhớ/secure storage, auth state và cache riêng tài khoản. Hủy request đang chạy và thay route stack để Back không mở lại màn bảo vệ.
- Nếu không liên lạc được backend: vẫn có thể đăng xuất cục bộ bằng cách xóa token trên máy; thông báo thu hồi phiên trên server chưa được xác nhận. Không nói mọi thiết bị đã đăng xuất.
- Nếu xóa secure storage thất bại, không báo đã xóa phiên lưu bền thành công; xử lý lỗi/thử lại để tránh tự khôi phục tài khoản cũ.
- Backend xác minh thông tin đăng nhập và trả user cùng role/quyền; app không tự chọn vai trò. Ánh xạ nhóm mobile theo mục 8.4 sau khi đối chiếu mã backend; guide không thay thế ma trận quyền trong SRS.
- Mock auth dùng fixture và phiên giả ở bộ nhớ, không lưu mật khẩu thật/token backend. Tài khoản demo chỉ hiện khi debug + USE_MOCK; release không có đường đăng nhập demo.
- Không lưu mật khẩu để thực hiện “Ghi nhớ đăng nhập”; chỉ giữ thông tin khôi phục phiên theo chính sách trên.

### 12.7 Nếu backend hiện chỉ hỗ trợ cookie HttpOnly

Đây là phương án thay thế, **không bật đồng thời Bearer và cookie cho cùng một hợp đồng mà chưa thống nhất**.

- Native Dio không tự hoạt động giống trình duyệt: cần cookie manager/jar để nhận Set-Cookie và gửi Cookie, ví dụ `dio_cookie_manager` + `cookie_jar`. [S8]
- Cookie jar ở bộ nhớ mất khi process kết thúc. Nếu ghi nhớ phiên bằng cookie, phải có cơ chế lưu bảo mật qua adapter đã kiểm tra; không coi PersistCookieJar ghi file mặc định là secure storage.
- Không đặt `ignoreExpires: true` cho xác thực. Cookie hết hạn và xóa khi logout phải được xử lý đúng.
- Native Dart có thể tiếp cận dữ liệu cookie; thuộc tính HttpOnly không tạo ranh giới “app không thể đọc token” như JavaScript trình duyệt. Không trộn cookie jar native với WebView mà không có thiết kế riêng.
- Giữ hợp đồng `/auth/login`, `/auth/me`, `/auth/logout`, `/auth/csrf` của web; app gửi header CSRF nếu backend yêu cầu. Không tự tắt CSRF của toàn backend chỉ để native gọi được.
- CORS và `withCredentials` của trình duyệt không áp dụng theo cùng cách cho native Dio. Nếu chạy Flutter Web phải có client/cấu hình riêng theo hợp đồng web.
- Khi chọn phương án này, thay thế hướng dẫn Bearer/refresh/storage tương ứng ở 12.2–12.6 và checklist; không tự gọi các endpoint `/mobile/auth` đề xuất.

---

<a id="section-13"></a>
## 13. Chữ trên giao diện

Theo Design System §10. UI tiếng Việt có dấu, câu ngắn, chủ động, xưng hô trung tính “bạn”; code/identifier dùng tiếng Anh. Không emoji, mã kỹ thuật, null/ID nội bộ hoặc exception trên UI.

### 13.1 Quy tắc

- Nút ghi đúng động từ: “Đăng nhập”, “Gửi phiếu”, “Lưu nháp”, “Duyệt”, “Hủy thông báo nghỉ”. Không “OK”, “Đồng ý”, “Có”, “Submit”, “Xác nhận” chung chung.
- Hộp xác nhận lặp đúng hành động; nút phụ “Quay lại”. Xóa/hủy dùng danger và icon đỏ.
- Lỗi nói điều sai + cách sửa: “Chưa chọn ngày bắt đầu nghỉ”, thay vì “Dữ liệu không hợp lệ”. Lỗi trường dưới ô, giữ dữ liệu form.
- Label không thay bằng placeholder; trường bắt buộc có `*` và semantics. Mã chứng từ hiển thị đậm màu `primary`.
- Ngày `dd/MM/yyyy`, ngày giờ `dd/MM/yyyy HH:mm`, giờ 24h. Trong `intl`, **MM là tháng**, `mm` là phút. Ngày gần có thể “Thứ Sáu, 9/10”; số thập phân dấu phẩy “104,5 cm”. Helper tập trung, thống nhất múi giờ nghiệp vụ với backend.
- Chờ ghi rõ chờ ai khi backend trả thông tin. Không tự suy người xử lý tiếp theo.
- Không khóa textScaler; xuống dòng theo mục 5.1. Ngoại lệ phần xem trước Cập nhật phát triển theo §8.5 phải mở được nội dung đầy đủ.
- Không yêu cầu người dùng hiểu “JWT, refresh token, Dio, HTTP 401”; dùng “Phiên đăng nhập đã hết hạn” hoặc “Không thể kết nối. Hãy thử lại”.

### 13.2 Thuật ngữ theo người đọc

| Nhân viên (giáo viên/bếp) | Phụ huynh | Không dùng |
| --- | --- | --- |
| trẻ | bé, con | học sinh |
| giáo viên | cô giáo | GVCN trong câu |
| Ban giám hiệu, Hiệu trưởng, Phó hiệu trưởng | nhà trường | admin, BGH trong câu |
| điểm trường | điểm trường | campus, cơ sở |
| thông báo nghỉ | thông báo nghỉ, báo nghỉ | đơn nghỉ, đơn xin phép |
| thực đơn, suất ăn | thực đơn, bữa sáng/trưa/chiều | MealPlan |
| chờ duyệt, đã duyệt, trả lại | Theo quyền và nội dung được xem | pending, approved |
| Chưa cập nhật | Nhà trường chưa cập nhật | null, Không có dữ liệu |

Nhãn tab dùng đúng Hôm nay/Bé/Lớp/Bếp/Thông báo/Tài khoản ở mục 8.4. Cùng feature, cùng người đọc phải cùng nhãn với web.

---

<a id="section-14"></a>
## 14. Tải, lỗi, rỗng và xác nhận

Theo Design System §9, §11; mọi màn tải dữ liệu đủ các trạng thái liên quan.

| Tình huống | Hiển thị và hành vi |
| --- | --- |
| Tải lần đầu | AppSkeleton đúng hình vùng nội dung; **không spinner giữa màn** |
| Tải lại/refresh | Giữ dữ liệu/filter, kéo xuống + thanh tiến độ mảnh dưới AppBar |
| Tải thêm | Ba chấm AppLoading cuối list, chặn request trùng, retry cuối list |
| Rỗng | AppEmptyState: tranh 168×124 bo 20 + câu khi nào có dữ liệu/làm gì tiếp; CTA nếu có việc làm được |
| Lọc không có kết quả | Giữ filter + AppEmptyState + “Đặt lại bộ lọc” |
| Mất mạng/lỗi tải | AppErrorState có icon, câu cụ thể + “Thử lại”; không tranh, không coi là logout |
| Không có quyền | “Bạn không có quyền xem nội dung này” + nút về Hôm nay; không biến thành rỗng |
| Nội dung không còn | “Nội dung không còn” + nút về Hôm nay |
| Lỗi trường | Dưới ô, màu danger + icon, map lỗi backend đúng field, giữ form |
| Đang gửi form | AppSubmitOverlay, khóa gửi lặp; ba chấm “Đang gửi…”; lỗi giữ dữ liệu + “Thử lại” |
| Thao tác nhỏ đang chạy | AppButton loading/disabled, ba chấm nhỏ; không phủ toàn màn |
| Kết quả thao tác | AppToast nền màu đúng loại, thanh đếm ngược; 3,5 s / lỗi 6 s; phía trên dưới status bar |
| Hành động không hoàn tác | AppConfirmationDialog icon lớn giữa; danger cho hủy/xóa; CTA lặp đúng tên hành động |
| Field thiếu | Ẩn dòng hoặc “Chưa cập nhật”; phụ huynh “Nhà trường chưa cập nhật”; không dựng giá trị 0 thay dữ liệu thiếu |
| Upload hủy/từ chối quyền | Phản hồi rõ, không tạo bản ghi giả thành công |

Không dùng một boolean isLoading cho mọi hoạt động khi cần giữ list/form độc lập. Không hiện thành công trước API xác nhận; optimistic update chỉ khi có chiến lược khôi phục rõ. Mẫu form phải giữ dữ liệu sau lỗi.

Test TalkBack/VoiceOver, semantics icon/chấm chưa đọc, thứ tự focus, chữ 2,0 và vùng chạm ≥48. Màu luôn có chữ/icon/chú giải. Mục 3–6 là nguồn kích thước/theme, không tự dựng lại trạng thái tại feature. [S2]

Dữ liệu sức khỏe không đi vào push/màn khóa. Đăng xuất/đổi tài khoản không thoáng hiện dữ liệu phiên trước. Mock/fixture/test/ảnh chụp/demo không dùng dữ liệu hoặc ảnh trẻ thật.

---

<a id="section-15"></a>
## 15. Code style và kiểm tra

| Loại | Quy ước | Ví dụ |
|---|---|---|
| File/thư mục | snake_case | `login_screen.dart`, `child_profile` |
| Class/enum/type | UpperCamelCase | `LoginScreen`, `AuthRepository` |
| Biến/hàm/constant | lowerCamelCase | `accessToken`, `restoreSession`, `pagePadding` |
| Private trong library | `_` theo Dart | `_storage` |
| Screen | `...Screen` | `HomeScreen` |
| Controller | `...Controller` | `AuthController` |
| DTO | `...Dto` | `UserDto` |
| Repository interface/implementation | Tên rõ vai trò | `AuthRepository`, `AuthRepositoryImpl` |

Dùng `dart format`, analyzer và lints của dự án; không giữ quy tắc Prettier/ESLint hoặc UPPER_SNAKE_CASE cho mọi constant như web. Code, comment và identifier dùng tiếng Anh; chữ hiển thị dùng tiếng Việt. Comment giải thích vì sao. [S9]

- Ưu tiên null safety rõ ràng; không dùng `!` hoặc `dynamic` hàng loạt để bỏ qua dữ liệu chưa xác định.
- `const` khi phù hợp; dispose controller/focus/listener hoặc để framework quản lý theo lifecycle đúng.
- Không bỏ qua Future quan trọng; sau await, thao tác UI chỉ khi context còn hợp lệ.
- Không log token, password, OTP, dữ liệu cá nhân hoặc raw response xác thực.
- Không có credential demo/endpoint dev cố định trong release.
- Không thêm package trùng chức năng; thay version phải kiểm tra platform config và lockfile.

### Kiểm thử phù hợp

Unit test cho mapping/validation/refresh/storage failure; widget test cho trạng thái form, routing phiên và lỗi UI; integration test cho login–restore–logout trên môi trường kiểm thử. Kiểm tra refresh đồng thời, logout trong lúc refresh, lỗi mạng, token hết hạn và đổi tài khoản. Không coi analyzer/build thành công là bằng chứng luồng xác thực chạy đúng.

---

<a id="section-16"></a>
## 16. Nối Spring Boot và tích hợp nền tảng

1. Xác nhận hợp đồng xác thực **native Bearer** hay **cookie**, không tự mặc định dùng endpoint web để lấy token JSON.
2. Thiết lập `API_BASE_URL`, `USE_MOCK=false`; production HTTPS. Điện thoại/emulator có môi trường mạng riêng; `localhost` trên thiết bị không mặc định là máy chạy Spring Boot. Xác nhận địa chỉ truy cập phù hợp với môi trường chạy.
3. Datasource gọi endpoint thật, repository map dữ liệu/lỗi; screen không cần đổi theo việc chuyển mock → API.
4. Thống nhất schema, pagination/cursor, timezone, error code, upload limits và response lỗi từng trường. Giá trị page/pageSize không hardcode khác nhau ở các feature.
5. Với native Bearer: backend hỗ trợ login/me/refresh/logout, rotation và thu hồi phiên theo mục 12. Với cookie: cấu hình cookie manager và CSRF tương ứng; không vô hiệu hóa bảo vệ web vì yêu cầu native.
6. Cấu hình quyền/network/storage Android/iOS đúng package đang dùng. Chỉ cho phép HTTP dev bằng cấu hình phạm vi dev khi cần; release dùng HTTPS, không bỏ kiểm tra certificate.
7. Refresh token lưu qua secure storage; đọc/write/delete có xử lý lỗi. Kiểm tra restore khi app bị đóng, không chỉ hot reload.
8. Nếu có upload, dùng multipart theo hợp đồng; không mặc định lưu mọi file lớn dạng base64. File trả về URL phải có cơ chế xác thực đúng; không rò Bearer qua URL/query hoặc host bên ngoài.
9. Camera/ảnh/file/share chỉ thêm khi scope cần, có mô tả quyền phù hợp và xử lý người dùng từ chối. Push notification là hạng mục tích hợp riêng nếu có, không tự coi chuông trong app là push đã hoạt động.
10. Kiểm tra trên nền tảng được dự án hỗ trợ và ít nhất một thiết bị thật trước phát hành; build iOS/Android theo pipeline và signing của dự án.

### 16.1 Chọn và upload ảnh (PROPOSED)

- Dùng `image_picker` để chọn từ camera/thư viện khi feature cần; thêm mô tả quyền/cấu hình Android/iOS đúng phiên bản package và API nền tảng. Chỉ xin quyền cần thiết tại thời điểm thao tác; xử lý hủy chọn/từ chối quyền. [S12]
- Widget hiển thị preview, xóa ảnh đã chọn, tiến độ và thử lại. Design System §6.3 nêu **tối đa 3 ảnh** cho ImageUploader web; dùng làm giới hạn đề xuất cho màn mobile tương ứng, không áp mặc định cho mọi feature. Backend chốt số ảnh, dung lượng, kích thước và MIME type cho từng endpoint.
- Nén/resize ảnh trước gửi bằng lớp xử lý ảnh được nhóm chọn; kiểm tra lại kích thước/định dạng sau xử lý. Không coi chọn ảnh bằng image_picker là đã hoàn thành mọi yêu cầu nén. Upload multipart theo hợp đồng API.
- Android có thể hủy Activity lúc mở trình chọn: xử lý kết quả qua `retrieveLostData` theo package, gắn lại đúng form/phiên hiện tại. File camera ở cache có thể là tạm; draft cần giữ qua việc đóng app phải có cơ chế lưu riêng. [S12]
- Giữ form và danh sách ảnh khi lỗi mạng; chỉ báo gửi thành công sau khi API xác nhận. Không tự replay upload sau refresh nếu body/endpoint chưa bảo đảm gửi lại an toàn.

### 16.2 Thông báo đẩy và deep link (OPEN)

Chuông trong app và danh sách thông báo không chứng minh backend đã hỗ trợ push. **FCM là phương án đề xuất**, cần xác nhận backend gửi push, dự án Firebase, APNs cho iOS và hợp đồng đăng ký/hủy device token trước khi tích hợp. [S13]

- `core/notifications` chứa adapter nhận push; `features/notifications` chứa dữ liệu/domain/UI danh sách. Ghép callback điều hướng qua routing/bootstrap, không để core import màn hình feature.
- Khi bật FCM, cấu hình platform và quyền thông báo theo tài liệu Firebase; xử lý từ chối quyền, token thay đổi và việc liên kết device token với user. Logout/đổi tài khoản cập nhật liên kết để thiết bị không tiếp tục nhận thông báo riêng của người cũ. [S13]
- Phân biệt thông báo khi app đang mở, app ở background và mở từ trạng thái đóng; handler nền không điều hướng trực tiếp. Sự kiện mở thông báo đi qua router, chờ phiên và kiểm tra quyền theo mục 8.4.
- Payload chỉ mang loại thông báo/ID tối thiểu; tải dữ liệu chi tiết qua API có xác thực. Tránh hiển thị nội dung nhạy cảm của trẻ trên màn khóa; nội dung thông báo cần nhóm chốt.
- Khi chưa có push backend, chỉ triển khai danh sách/chuông theo API được xác nhận; không báo thông báo đẩy đã hoạt động.

---

<a id="section-17"></a>
## 17. Checklist trước PR

### Thiết kế và tương tác

- [ ] UI theo Design System chung 3.1; ngoại lệ ghi rõ, không ghi PROPOSED thành đã duyệt.
- [ ] Nút chính `brand #4FB0F5` / `onBrand #0E3F63`; link `primary #0B72BC`; nền `#F1F9FE`, muted `#66728A`.
- [ ] Light Theme, TextTheme đúng 22/26/28/18/17/16/14/13/12 theo vai trò; nút 16/700; không 800, không khóa textScaler.
- [ ] Nút/input một dòng pill cao nền 52; card bo 24 padding 20, dialog/sheet bo 32; `space8 = 32`, không space7.
- [ ] Vùng chạm ≥48 kể cả nút nhỏ/chip; list row ≥64; NavigationBar 72 + safe area, nhãn luôn hiện.
- [ ] Một nút chính mỗi vùng; không FAB; câu nút là động từ; danger đỏ nhạt chữ đỏ, không bóng nút.
- [ ] Badge dùng 7 tông gray/orange/blue/approval/red/green/teal; cùng nhãn/tông với web theo người đọc; approval vàng chỉ chờ người duyệt.
- [ ] Icon qua AppIcons; Tabler outline hoặc fallback Material rounded đúng ngoại lệ; không import trực tiếp/emoji tại feature.
- [ ] Card trắng đặc; kính chỉ hero, không BackdropFilter trong list; logo/tranh cùng nguồn, không méo/đổi màu logo.
- [ ] Tải đầu skeleton, loading ba chấm, form AppSubmitOverlay, kết quả AppToast; rỗng có tranh/lỗi có icon; đủ retry/permission/not-found.
- [ ] Hành động không hoàn tác có AppConfirmationDialog; giữ form khi lỗi; SafeArea/bàn phím/Back đúng.
- [ ] 360–430 và màn hẹp/chữ 1,0/1,3/2,0 không mất nội dung; semantics/TalkBack/VoiceOver đúng.
- [ ] Không tự đánh giá sức khỏe, tính tổng/trạng thái hoặc thêm field thay BE; không dữ liệu/ảnh trẻ thật trong mock/test/demo.
- [ ] Widget/variant/token mới có trong Design System và widget test; đổi token cập nhật cả hai repo + ảnh trước–sau.
- [ ] Giảm chuyển động tắt hiệu ứng theo AppMotion, giữ thanh đếm ngược toast.

### Kiến trúc và dữ liệu

- [ ] Screen/widget không gọi Dio, đọc token/storage hoặc map JSON trực tiếp.
- [ ] Domain không phụ thuộc Flutter/Dio/storage plugin; DTO map trong data.
- [ ] DI chọn repository mock/thật; không if USE_MOCK rải trong screen.
- [ ] Xử lý cancel/dispose, request tìm kiếm cũ, tải thêm trùng và refresh mà không ghi đè form.
- [ ] Phạm vi role được đối chiếu SRS/Screen Flow; có `PARENT`, chỉ bật Kitchen Staff khi được duyệt, không tự đoán mã/quyền Tổ trưởng.
- [ ] NavigationBar 3–5 đích phù hợp; route/deep link kiểm tra phiên và quyền; backend vẫn kiểm tra quyền dữ liệu.
- [ ] Trạng thái chứng từ/chữ ký dùng mã và dữ liệu đã chốt; không tự dựng quy trình, nghiệp vụ in hoặc chức năng web trên mobile.

### Xác thực native theo phương án mặc định

- [ ] Backend đã thống nhất endpoint native; không mặc định endpoint web trả token JSON.
- [ ] Token không lưu trong preferences/file thường và không xuất hiện trong log/UI.
- [ ] Access token ở bộ nhớ; refresh token chỉ lưu secure storage khi ghi nhớ.
- [ ] Khôi phục phiên qua refresh + /me; phân biệt hết phiên với lỗi mạng.
- [ ] Interceptor chỉ gắn Bearer cho backend được phép; tránh refresh đệ quy/song song.
- [ ] Retry có giới hạn và an toàn; logout/đổi tài khoản không bị refresh cũ khôi phục lại.
- [ ] Logout dọn phiên cục bộ; thu hồi server được xác nhận hoặc thông báo rõ nếu thất bại.
- [ ] Nếu dùng OTP, chưa vào app trước khi xác minh thành công.
- [ ] Nếu chọn cookie thay thế, đã cập nhật checklist tương ứng và kiểm tra cookie/CSRF/secure persistence; không bật hai luồng tùy tiện.

### Kiểm tra và release

- [ ] Analyzer và kiểm tra format thành công.
- [ ] Kiểm thử phù hợp với thay đổi đã chạy; luồng xác thực có kiểm tra restore/expiry/logout.
- [ ] Bản release không có mock login/route xem thử theo vai trò/log nhạy cảm, dùng URL môi trường đúng.
- [ ] Package/platform config và pubspec.lock được cập nhật đồng bộ.
- [ ] Quyền thiết bị và xử lý từ chối quyền đã kiểm tra nếu thay đổi liên quan.
- [ ] Nếu upload ảnh: giới hạn backend, nén, hủy/khôi phục chọn ảnh và lỗi mạng được xử lý.
- [ ] Nếu có push: FCM/APNs, device token, đổi tài khoản và mở deep link đã kiểm tra; không mặc định chuông là push.

### Tự rà UI tại repository app

Chạy tại gốc `CareNest_APP`; các lệnh dưới chỉ rà khi đã có repo, chưa chạy trong lần sửa Markdown này:

```bash
# Màu ngoài token/bóng: kết quả cần rà ngoại lệ màu từ dữ liệu.
rg -n 'Color\(0x|Colors\.' lib -g '*.dart' -g '!core/constants/colors.dart' -g '!core/constants/sizes.dart'
# Chữ, kích thước và icon tự đặt ở feature: dòng mới cần xử lý.
rg -n 'fontSize:|fontWeight:|BorderRadius\.circular\([1-9]|EdgeInsets\.[A-Za-z]+\([^)]*[1-9]|SizedBox\((width|height): *[1-9]|Icons\.|TablerIcons\.' lib/features -g '*.dart'
# Blur chỉ ở hero, widget mặc định cần dùng qua wrapper.
rg -n 'BackdropFilter' lib -g '*.dart' -g '!app_hero_scene.dart'
rg -n '\b(ElevatedButton|AlertDialog|SnackBar|ListTile|CircleAvatar)\(' lib/features -g '*.dart'
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
```

Đọc kết quả trong ngữ cảnh; comment/mẫu không tự đồng nghĩa lỗi. Dòng mới của thay đổi phải tuân thủ luật token/component. Khi các script dự án có sẵn, chạy thêm `node scripts/check-ai-layer.mjs` và `node scripts/verify.mjs` theo Design System Phụ lục A. Không tự xác nhận script/package/repo đã tồn tại từ tài liệu.

---

<a id="section-18"></a>
## 18. Nguồn nghiệp vụ chung và các điểm cần chốt

### 18.1 Kế thừa web/mobile

| Nội dung | Cách dùng cho mobile |
| --- | --- |
| Logo/tranh/màu/font/spacing/radius/motion/icon | Theo Design System chung §3–5 và guide mục 3–7; không có bộ token UI độc lập cho app |
| Tông trạng thái và thuật ngữ | Cùng ý nghĩa; nhãn theo phụ huynh/nhân viên ở mục 6, 13; legacy purple web = approval app |
| Vòng đời chứng từ | Theo SRS/Use Case và mã BE; không suy chuyển trạng thái từ màu/vị trí nút |
| Chữ ký/lịch sử | Chỉ field/thao tác thuộc phạm vi đã duyệt; nếu ký chỉ ở web thì mobile chỉ xem |
| Khác biệt thiết bị | Chỉ các khác biệt được Design System §1.3 cho phép; bổ sung dòng trước khi tạo khác biệt mới |
| In A4/PDF/CSV | Không tự chuyển PrintToolbar/font Tinos/layout A4 sang mobile; chức năng mới cần yêu cầu riêng |

Các mã ATT-05, NUT-08, HLT-02/05, OBS-03/05, P-13/P-13b được **dẫn từ Design System nguồn**; hai file đầu vào không chứa đầy đủ SRS/Use Case/DTO. Chưa xác minh độc lập nghiệp vụ hoặc endpoint. Không thêm role, trạng thái BE, chữ ký hay bước duyệt chỉ từ ví dụ UI.

### 18.2 Điểm OPEN / NEEDS VERIFICATION

| Điểm | Quy ước tạm | Cần chốt với |
| --- | --- | --- |
| Design System 3.1 | Đồng bộ tài liệu theo bản PROPOSED, không ghi đã duyệt | Team |
| Field phụ huynh P-13b | Dựng khung, field không có thì bỏ dòng | BGH + BE |
| Tab/màn giáo viên/bếp | Hôm nay/Lớp hoặc Bếp/Thông báo/Tài khoản; bếp chỉ bật khi phạm vi duyệt | SRS/Screen Flow + team |
| Tổ trưởng | Không mặc định TEAM_LEADER riêng | SRS + schema user/permissions |
| Tạo tài khoản phụ huynh/SMS mời | Giữ ghi nhận bản mobile trước, không tự đăng ký | Luồng quản lý tài khoản + BE |
| Gói Tabler Flutter | AppIcons tạm Material rounded; giữ tên giống web | Team APP |
| Appearance | T0 Sân chơi, không tự gọi GET /school/appearance | BE |
| Sức khỏe P-13 | Không tự màu/nhãn đánh giá; AI chỉ dữ liệu đã duyệt | BGH + BE |
| Riverpod/go_router | Lựa chọn PROPOSED của guide, không khẳng định đã cài | Team |
| Form auth hay Keycloak | Giữ tranh + logo, form theo phương án chốt | BE + team |
| Bearer/cookie/refresh/CSRF | Giữ đề xuất mục 12; chốt hợp đồng trước tích hợp | BE |
| OTP | Mẫu challenge/verify/resend; không giả định endpoint tồn tại | SRS + BE |
| Push | FCM đề xuất, không coi chuông = push đã hoạt động | BE + Firebase/APNs |
| Upload | Giới hạn theo endpoint; 3 ảnh là mẫu tương ứng web | BE + giải pháp nén |
| Chứng từ/chữ ký/quyền | Hiển thị theo đặc tả/DTO; không sinh luồng | SRS/Use Case + BE |
| Bóng lớp nổi --shadow-xl | Nguồn chưa ghi số; lấy từ tokens.css khi nối code | Team FE/APP |
| Token tự sinh chung | Chưa có; hai file đối chiếu cùng bảng | Team |
| Nối repo APP | Dùng quy trình Phụ lục A; lần này chỉ sửa Markdown | Team APP |

UI/mock có thể triển khai theo nguồn chung; tích hợp phụ thuộc hợp đồng OPEN chỉ chuyển sang API thật sau xác nhận. Không gắn CONFIRMED từ dữ liệu mock hoặc một dòng mô tả widget đã có.

---

<a id="appendix-a"></a>
## Phụ lục A — Nối tài liệu vào repository

Theo Phụ lục A của **CareNest Design System — web + app**. Bản Markdown này là guide đồng bộ để đọc và bàn giao; khi nối repo, dùng cấu trúc dưới đây để tránh hai nguồn UI khác nhau.

| Đích trong `CareNest_APP` | Nội dung |
| --- | --- |
| `DESIGN.md` | **Chép nguyên bản Design System chung 3.1** từ web; không thay bằng một bản chỉ dành cho mobile |
| `docs/architecture/CODING_GUIDE.md` | Tách phần code của guide: mục 1–2, 10–12, 15–16; phần kiến trúc/auth/release ở 17; quy định nghiệp vụ và điểm cần chốt ở 18; giữ tham chiếu rõ sang DESIGN.md |
| `AGENTS.md` | Stack: “Giao diện: theo DESIGN.md (chung với web). Luật cứng mục 2, tự kiểm mục 13.2.”; thêm đường dẫn coding guide cho phần code |
| `.claude/rules/ui-style.md` | Paths cho presentation/widget/theme/constants; tóm Design System §2.1, 2.3, 3.2, 9, 10, 13.2 |
| Comment `DESIGN.md §…` trong `lib/` | Rà lại số mục theo Design System chung, không theo số mục guide này |

Số mục không phải giao diện “10–18” trong Phụ lục A nguồn là số của bản DESIGN cũ; sau đồng bộ, mục 13–14 và phần đầu 17 của guide này là UI, do Design System chung sở hữu. Khi tách coding guide, chuyển logic code và tham chiếu UI về nguồn chung, không chép lại một bảng màu cũ.

Thứ tự triển khai tài liệu và code:

1. Tách phần code, chép Design System chung, cập nhật hướng dẫn AI và tham chiếu.
2. Làm PR theme chung: màu/tông, typography, spacing/radius/sizes/motion/icon và asset trước khi dựng màn mới; rà mọi tham chiếu đổi tên.
3. Nâng wrapper AppButton/Input/Card/Badge/Loading/Dialog, bổ sung widget còn thiếu; phủ đủ trạng thái bằng widget test.
4. Áp công thức màn, kiểm kích thước/chữ lớn/trạng thái, chạy kiểm tra dự án ở mục 17.
5. Đổi token lâu dài: cập nhật token web + app, tăng phiên bản và ghi lịch sử nguồn chung, chép DESIGN.md sang repo kia cùng đợt.

Đây là hướng dẫn bàn giao; **chưa thực hiện thay đổi repository** trong lần chỉnh Markdown.

---

<a id="appendix-b"></a>
## Phụ lục B — Bảng thay đổi UI

Các giá trị cũ dưới đây chỉ để tra cứu migration, **không phải token được phép dùng mới**.

| Hạng mục | Bản mobile trước | Bản đồng bộ 3.1 |
| --- | --- | --- |
| Nút chính | Primary #1565E0, chữ trắng | Brand #4FB0F5, chữ #0E3F63 |
| Link | Dùng chung primary nút | Primary #0B72BC, pressed #0A6AAE |
| Nền / muted | #F5F8FC / #8592A6 | #F1F9FE / #66728A |
| Tông bản ghi | neutral/info/warning/purple/danger/success/teal | gray/orange/blue/approval/red/green/teal |
| Chờ duyệt | Tím #7048E8 | Vàng approval #F5B400; legacy purple chỉ giữ ở web |
| Bo nút/input | 8 | Pill 9999; multiline 20 |
| Card / dialog / sheet | 12 / 12 / 20 | 24 / 32 / 32 |
| Nút/input / padding card | 48 / 16 | 52 / 20; card dày 16 |
| Khoảng cách 32 | space7 | space8; thêm space10 = 40 |
| AppBar/card/nút/badge | 20/600, 16/600, 14/600, 12 | 18/600, 17/700, 16/700, 13/600 |
| Icon | Material tùy feature | AppIcons chung, đích Tabler outline, fallback rounded qua mapping |
| Loading/toast | Spinner, SnackBar mặc định | Ba chấm, AppToast có thanh đếm ngược |
| Danger button | Đỏ đặc chữ trắng | Đỏ nhạt chữ đỏ |
| Bề mặt/tranh | Chưa quy định đủ | Card trắng đặc; hero kính; cùng bộ tranh; lỗi dùng icon |
| Navigation | Trang chủ/Lớp học/Bé của tôi/Công việc bếp | Hôm nay/Lớp/Bé/Bếp; nhãn luôn hiện |
| Tablet/FAB | Có thể NavigationRail tại 600; FAB khi phù hợp | Một cột/thanh đáy theo nguồn; không FAB; khác thêm cần cập nhật nguồn chung |
| Quyền/nghiệp vụ/auth | Đề xuất kỹ thuật + xác minh SRS | Giữ ranh giới cũ; nguồn UI không xác nhận role/API/ma trận quyền |

---

<a id="references"></a>
## Tài liệu tham chiếu

**Nguồn lần sửa:** hai file người dùng cung cấp: “CareNest Mobile – Design & Coding Guide (Flutter)” và “CareNest Design System — web + app” phiên bản 3.1 (09/10/2026). Design System là nguồn quyết định UI. Các tham chiếu DESIGN/review cũ chỉ giữ ở nội dung cần đối chiếu, không coi là tài liệu đã đọc thêm trong lần này.

Liên kết kỹ thuật dưới đây được giữ từ guide mobile; S10–S11 được kiểm tra lại cho mẫu theme. Các nguồn package không xác nhận repo CareNest đã cài thư viện hoặc backend đã có hợp đồng.

- **S1:** [Flutter – Architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations): phân tách UI/data, repository và domain layer theo nhu cầu.
- **S2:** [Flutter – Accessibility](https://docs.flutter.dev/ui/accessibility): text scaling, vùng chạm, screen reader và contrast.
- **S3:** [Flutter – Adaptive apps](https://docs.flutter.dev/ui/adaptive-responsive/general): đo không gian cửa sổ, LayoutBuilder và điều hướng thích ứng.
- **S4:** [Dio – Package documentation](https://pub.dev/packages/dio): client, interceptor, cancellation và request.
- **S5:** [go_router – Package documentation](https://pub.dev/packages/go_router): routing/redirect.
- **S6:** [Riverpod – Getting started](https://riverpod.dev/docs/introduction/getting_started): state và khởi tạo dependency.
- **S7:** [flutter_secure_storage – Package documentation](https://pub.dev/packages/flutter_secure_storage): lưu bảo mật và cấu hình nền tảng.
- **S8:** [dio_cookie_manager – Package documentation](https://pub.dev/packages/dio_cookie_manager): quản lý cookie cho Dio native.
- **S9:** [Effective Dart – Style](https://dart.dev/effective-dart/style): tên file/class/identifier và formatter.
- **S10:** [Flutter API – ColorScheme.fromSeed](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html): màu từ seed và ghi đè các role.
- **S11:** [Flutter API – ThemeData](https://api.flutter.dev/flutter/material/ThemeData/ThemeData.html): Material 3, ColorScheme, TextTheme và component theme.
- **S12:** [image_picker – Package documentation](https://pub.dev/packages/image_picker): cấu hình nền tảng, xử lý lost data và file tạm.
- **S13:** [Firebase – Get started with FCM in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started): cấu hình push, quyền và device token.

Ngày cập nhật guide: **10/10/2026**. Đồng bộ UI theo Design System 3.1; chưa kiểm tra mã nguồn/build/luồng auth của dự án. Khóa Flutter/package trong repository và dùng tài liệu tương ứng khi triển khai.
