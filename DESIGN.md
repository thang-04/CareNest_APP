# CareNest Mobile – Design & Coding Guide (Flutter)

Tài liệu dùng chung cho nhóm phát triển **CareNest Mobile trên Android/iOS bằng Flutter**. Được chuyển từ quy chuẩn CareNest Web, tổ chức theo **Feature-based + Clean Architecture**, và cập nhật theo `DESIGN_review_Flutter.md` ngày 08/10/2026. Đây là **quy chuẩn triển khai đề xuất**, chưa phải mô tả một dự án Flutter đã được kiểm tra mã nguồn.

Trước khi làm màn hình mới: đọc tài liệu và xem **UiKitScreen** trong bản debug để chọn widget, màu và kiểu chữ. Nguyên tắc: dùng lại thành phần chung; thiếu thì bổ sung vào `core/widgets` hoặc hệ thống theme để cả nhóm cùng dùng.

**Phạm vi:** thiết kế, kiến trúc, API, trạng thái giao diện, xác thực và chất lượng mã nguồn cho app native. Mục 8.4 bổ sung khung điều hướng theo nhóm người dùng; mục 18 quy định cách kế thừa trạng thái chứng từ/chữ ký từ tài liệu nghiệp vụ. Ma trận quyền, chuyển trạng thái và thao tác nghiệp vụ cụ thể vẫn phải đối chiếu SRS/Use Case/Screen Flow; không tự suy ra từ giao diện web.

**Quy ước mức độ xác nhận:**

- **PROPOSED:** đề xuất triển khai trong guide, chưa chứng minh dự án đã có mã nguồn/API tương ứng.
- **OPEN:** cần nhóm hoặc backend chốt trước khi triển khai phần phụ thuộc.
- **NEEDS VERIFICATION:** thông tin được nhắc trong review nhưng cần đối chiếu tài liệu gốc.

Các lựa chọn kỹ thuật mặc định trong guide là **PROPOSED**. Review đánh giá một bản DESIGN dành cho web; file đang sửa đã là bản Flutter, nên giữ các phần phù hợp và bổ sung những điểm còn thiếu. Những nhận định `CONFIRMED` về vai trò/tài khoản trong review được ghi nhận là thông tin từ review, chưa được xác minh độc lập với SRS trong lần cập nhật này.

**Điểm khác với web:** tài liệu mặc định đề xuất **Bearer token + secure storage cho app native**; web tiếp tục dùng cookie HttpOnly. Backend phải hỗ trợ hợp đồng mobile tương ứng. Nếu backend chỉ hỗ trợ cookie hiện tại, xem mục 12.7 trước khi triển khai; không tự giả định endpoint web trả token JSON.

## Mục lục

1. [Chạy dự án và cấu hình](#section-1)
2. [Cấu trúc thư mục](#section-2)
3. [Thương hiệu và tài nguyên](#section-3)
4. [Màu sắc và design tokens](#section-4)
5. [Chữ, khoảng cách và bố cục thích ứng](#section-5)
6. [Badge và màu thông tin](#section-6)
7. [Widget dùng chung](#section-7)
8. [Khung ứng dụng và mẫu màn hình](#section-8)
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
  brand/
    logo_mark.png
    logo_full.png
  images/
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
    theme/
      app_theme.dart
      app_text_styles.dart
      app_status_colors.dart        # ThemeExtension cho success/warning/purple/teal và chip
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
      app_loading.dart
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

    ui_kit/
      presentation/
        screens/
          ui_kit_screen.dart        # Chỉ đăng ký route trong debug

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
## 3. Thương hiệu và tài nguyên

Giữ nhận diện của CareNest Web.

| Tài nguyên | Dùng ở đâu | Widget đề xuất |
|---|---|---|
| `assets/brand/logo_mark.png` | Biểu tượng trong app và splash | `AppLogo` dạng mark |
| `assets/brand/logo_full.png` | Màn đăng nhập, màn giới thiệu nếu có | `AppLogo` dạng full |
| Chữ CareNest | Cạnh biểu tượng nếu dùng chữ render | `AppWordmark`: Care xanh đậm, Nest xanh trời |
| App launcher icon | Icon ngoài màn hình điện thoại | Cấu hình riêng Android/iOS |

Không kéo méo, đổi màu hoặc thêm bóng vào logo. Giữ tỷ lệ ảnh bằng `BoxFit.contain`. Không lấy ảnh có khoảng trắng quá lớn làm launcher icon. Splash/launcher icon phải cấu hình qua tài nguyên nền tảng hoặc công cụ tương ứng; không sao chép `favicon.png` làm giải pháp mặc định.

Tập trung đường dẫn ở `AppAssets`. Ảnh/font đóng gói phải khai báo trong `pubspec.yaml`; không hardcode đường dẫn rải rác. Ưu tiên font đóng gói để giao diện có chữ Việt ổn định khi mạng yếu.

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/brand/
    - assets/images/
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

Chỉ giữ các mục asset thực sự tồn tại. `assets/icons/` cần khai báo thêm nếu được sử dụng. Giữ thông tin tên app/phiên bản trong cấu hình và màn tài khoản/giới thiệu; không cần footer ở mọi màn mobile.

---

<a id="section-4"></a>
## 4. Màu sắc và design tokens

Chỉ định nghĩa màu gốc bằng các hằng số của `AppColors` trong `core/constants/colors.dart`. Theme ánh xạ màu qua `ColorScheme` và `ThemeExtension`; widget dùng theme thay vì tự viết `Color(0x...)`.

### 4.1 Bảng màu giữ từ web

| Nhóm | Token Dart đề xuất | Mã | Sử dụng |
|---|---|---|---|
| Brand | `brandBlue700` | `#0269C5` | Chữ Care, điểm nhấn |
| Brand | `brandBlue600` | `#1675CF` | Màu thương hiệu phụ |
| Brand | `brandSky400` | `#4FB0F5` | Chữ Nest |
| Brand | `brandSky300` | `#71C6FD` | Minh họa nhẹ |
| Brand | `brandMint300` | `#94DEBD` | Điểm nhấn minh họa |
| Primary | `primary` | `#1565E0` | Nút chính, link, mục đang chọn |
| Primary | `primaryPressed` | `#0F55C4` | Trạng thái nhấn |
| Primary | `primaryContainer` | `#EAF2FE` | Nền chọn nhẹ |
| Primary | `focusRing` | `#D6E6FD` | Viền focus |
| Success | `success` / `successText` | `#12A150` / `#0B7A3B` | Thành công / chữ trên nền nhạt |
| Warning | `warning` / `warningText` | `#E8890C` / `#B25E00` | Cảnh báo / chữ trên nền nhạt |
| Danger | `danger` / `dangerText` | `#E03131` / `#C92A2A` | Lỗi / chữ trên nền nhạt |
| Purple | `purple` / `purpleText` | `#7048E8` / `#4D2DB7` | Nhãn cần phân biệt |
| Teal | `teal` | `#0C8599` | Thông tin phụ |
| Text | `textPrimary` | `#1B2433` | Nội dung chính |
| Text | `textSecondary` | `#4A5568` | Nội dung phụ |
| Text | `textMuted` | `#8592A6` | Placeholder/ghi chú, cần kiểm tra độ tương phản |
| Text | `textInverse` | `#FFFFFF` | Chữ trên nền phù hợp |
| Border | `border` / `borderStrong` | `#E3E9F2` / `#CDD6E3` | Viền thông thường/input |
| Surface | `background` | `#F5F8FC` | Nền màn hình |
| Surface | `surface` / `surfaceSoft` | `#FFFFFF` / `#F8FAFC` | Card và khối phụ |
| Disabled | `disabled` / `disabledContainer` | `#ADB5BD` / `#F1F3F6` | Phần tử vô hiệu |
| Loading | `skeleton` | `#EEF1F5` | Placeholder khi tải |

**Màu chip theo tông (CONFIRMED — user duyệt 2026-10-08):** chữ chip dùng `…Text` của tông, riêng teal dùng `tealText` #0A6B7B và warning dùng `warningChipText` #A35600 (`warningText` #B25E00 trên nền warning chỉ 4.30:1). Nền/viền: success #E7F6EE/#B5E3C8, warning #FFF4E5/#FFD8A8, danger #FDECEC/#F8C4C4, purple #F1EDFD/#D5CBF9, teal #E3F4F6/#B2DFE5; info dùng `primaryContainer`/`focusRing`, neutral dùng `disabledContainer`/`border`. Chữ/nền mỗi tông ≥4.5:1 (WCAG AA), có test khóa trong `test/core/theme/app_theme_test.dart`. Khai báo ở `AppColors`, ánh xạ trong `AppStatusColors`.

Các màu nền/viền semantic chưa liệt kê mã phải được bổ sung tập trung và kiểm tra trên UiKitScreen trước khi dùng; không tự tạo khác nhau ở từng feature. Cặp màu thương hiệu không đồng nghĩa mọi cặp chữ/nền đều đọc tốt.

### 4.2 Ánh xạ token sang Flutter

| Token/nhóm | Vị trí trong theme |
|---|---|
| `primary`, `textInverse` | `ColorScheme.primary`, `onPrimary` |
| `primaryContainer`, `brandBlue700` | `primaryContainer`, `onPrimaryContainer` |
| `danger`, `textInverse` | `error`, `onError` |
| `surface`, `textPrimary`, `textSecondary` | `surface`, `onSurface`, `onSurfaceVariant` |
| `borderStrong`, `border` | `outline`, `outlineVariant` |
| `background` | `ThemeData.scaffoldBackgroundColor` |
| Success, warning, purple, teal; nền/viền chip | `ThemeExtension<AppStatusColors>` trong `app_status_colors.dart` |
| Pressed, focus, disabled, skeleton | Component theme/widget chung, dùng token đã có |

`ColorScheme.fromSeed` sinh bảng màu từ seed; **không bảo đảm `primary` bằng đúng `#1565E0`**. Ghi đè các role đã được duyệt bằng `copyWith` hoặc khai báo `ColorScheme` đầy đủ; không chỉ truyền seed rồi coi là giữ nguyên nhận diện. Khi ghi đè phải kiểm tra lại các cặp `on…` và màu container. Các role được sinh nhưng chưa duyệt vẫn là PROPOSED. Xem ví dụ mục 9.1. [S10, S11]

`background` vẫn là token của CareNest, nhưng ánh xạ qua Scaffold; không dùng thuộc tính `ColorScheme.background` đã deprecated trong SDK hiện hành.

### 4.3 Nguyên tắc

- Dùng token theo ý nghĩa: `primary`, `surface`, `error`, `onSurface`; không đặt token mới theo tên một màn hình.
- Không dùng riêng màu để truyền đạt thông tin; badge có chữ hoặc icon.
- Ngoại lệ màu từ dữ liệu: ảnh thật, avatar màu do dữ liệu cung cấp; vẫn cần fallback và bảo đảm chữ dễ đọc.
- Màu pressed, disabled, focus, selection được cấu hình trong theme/widget chung.
- Bản đầu dùng **Light Theme** đồng nhất với web và đặt `themeMode: ThemeMode.light` trong `MaterialApp.router`. Chỉ bật Dark Theme/System Theme sau khi có đầy đủ token tối và kiểm tra màn hình; không mặc định chuyển bằng `ThemeData.dark()` rồi coi là đã hoàn thành.

---

<a id="section-5"></a>
## 5. Chữ, khoảng cách và bố cục thích ứng

Đơn vị kích thước bố cục Flutter là **logical pixel**. Không chuyển các kích thước desktop sang mobile theo tỷ lệ cố định.

### 5.1 Typography

Font `BeVietnamPro`; khai báo `TextTheme` trong `app_theme.dart` / `app_text_styles.dart`.

| Vai trò | TextTheme | Cỡ đề xuất | Độ đậm |
|---|---|---|---|
| Tiêu đề lớn trong nội dung | `headlineSmall` | 24 | 700 |
| Tiêu đề AppBar | `titleLarge` | 20 | 600 |
| Tiêu đề khối/card | `titleMedium` | 16 | 600 |
| Nội dung chính/form | `bodyLarge` | 16 | 400 |
| Nội dung phụ/list | `bodyMedium` | 14 | 400 |
| Label/nút | `labelLarge` | 14 | 600 |
| Chú thích | `labelSmall` | 12 | 400 |

Nội dung chính ưu tiên 16 để phụ huynh dễ đọc trên điện thoại; chú thích 12 chỉ dành cho thông tin phụ. Không chuyển mặc định body 13–14 của web thành toàn bộ nội dung mobile.

Độ đậm dùng 400/500/600/700. Widget lấy style từ theme; không tạo cỡ chữ tùy ý. Tôn trọng text scaling của hệ điều hành; không ép hệ số chữ bằng 1 toàn app. Kiểm tra text lớn, nhãn dài, tiếng Việt có dấu và lỗi nhiều dòng. [S2]

### 5.2 Khoảng cách, bo góc và bóng

| Token | Giá trị đề xuất | Dùng cho |
|---|---|---|
| `AppSpacing.space1`…`space7` | 4, 8, 12, 16, 20, 24, 32 | Gap/padding theo lưới 4 |
| `pagePadding` | 16 | Lề ngang điện thoại |
| `cardPadding` | 16 | Nội dung card |
| `radiusSmall` | 8 | Input/nút |
| `radiusMedium` | 12 | Card/dialog |
| `radiusLarge` | 20 | Sheet nếu dùng bo góc |
| `radiusPill` | 999 | Chip/badge dạng viên; không áp cho mọi card |
| `minimumTapTarget` | 48 | Vùng chạm tối thiểu theo quy chuẩn nhóm |
| `buttonMinHeight` | 48 | Nút chuẩn; cho phép tăng khi chữ lớn |

`sizes.dart` khai báo `AppSpacing`, `AppRadius`, `AppSizes`; giá trị đều là logical pixel. Quy chuẩn nhóm dùng vùng chạm tối thiểu **48×48 logical pixels** trên cả Android/iOS, đáp ứng mức 48 của Android và cao hơn mức 44 của iOS. Chỉ dùng các mức bóng/elevation đã định nghĩa trong theme. Badge có thể nhỏ hơn 48 nếu không tương tác; nếu bấm được phải mở rộng vùng chạm. [S2]

### 5.3 Responsive và bàn phím

- Theo **chiều rộng cửa sổ hiện có**, không theo tên thiết bị. Dùng `LayoutBuilder` cho vùng nội dung và `MediaQuery` cho thông tin cửa sổ/inset.
- Quy ước đề xuất: dưới 600 logical pixels dùng bố cục một cột và NavigationBar; từ 600 có thể dùng NavigationRail/hai cột khi phù hợp. Đây là mốc dự án, có thể điều chỉnh sau kiểm tra. [S3]
- Form dùng cuộn, xử lý bàn phím, focus và nút tiếp theo. Không đặt chiều cao card/text cố định gây cắt chữ.
- `SafeArea` dùng ở nơi cần tránh status bar, notch, vùng home indicator; không cộng inset trùng với Scaffold/AppBar.
- Vùng nút dưới cùng không bị bàn phím hoặc thanh điều hướng hệ thống che. Kiểm tra `viewInsets` và cơ chế resize của Scaffold.
- Kiểm tra màn nhỏ khoảng 320 logical pixels, màn phổ biến, tablet, xoay ngang và chữ lớn. Không bắt mọi màn dùng đúng một kích thước thiết kế.

---

<a id="section-6"></a>
## 6. Badge và màu thông tin

Phần này chỉ chuẩn hóa cách hiển thị, không định nghĩa trạng thái nghiệp vụ hoặc bước chuyển trạng thái.

| Tông | Ý nghĩa hiển thị chung |
|---|---|
| Gray | Trung tính, không hoạt động |
| Blue | Thông tin hoặc đang thực hiện |
| Orange | Chờ/nhắc chú ý |
| Purple | Nhóm trạng thái cần phân biệt riêng theo đặc tả feature |
| Red | Lỗi hoặc cần xử lý |
| Green | Thành công hoặc hoàn thành |
| Teal | Nhãn thông tin phụ |

`AppStatusBadge(label, tone, icon)` là widget chung. Feature ánh xạ mã trạng thái sang nhãn/tông dựa trên đặc tả đã chốt; không khai báo một vòng đời mặc định cho mọi feature. Khi hai trạng thái cùng tông vẫn phải phân biệt bằng chữ/icon. Không để badge bấm được mà chỉ thể hiện bằng màu.

---

<a id="section-7"></a>
## 7. Widget dùng chung

**Đã triển khai (2026-10-08)** trong `lib/core/widgets/`: `AppButton`, `AppTextField`, `AppPasswordField`, `AppCard`, `AppStatusBadge`, `AppLoading`, `AppSkeleton`, `AppEmptyState`, `AppErrorState` (bố cục chung `AppStateMessage`), `AppConfirmationDialog`, `brand/AppWordmark`. Các tên còn lại trong bảng là API đề xuất, chưa có. Xem và thử các biến thể trên UiKitScreen trước khi dùng.

| Nhu cầu | Widget/cơ chế | Quy tắc |
|---|---|---|
| Nút | `AppButton` bọc `FilledButton` / `OutlinedButton` / `TextButton` | Primary/secondary/text/danger; loading/disabled; vùng chạm tối thiểu 48×48 |
| Ô nhập | `AppTextField` dựa trên `TextFormField` | Label, hint, error, keyboardType, input action |
| Mật khẩu | `AppPasswordField` | Ẩn/hiện; không lưu mật khẩu; không chặn password manager tùy tiện |
| Card | `AppCard` | Padding, bo góc, màu từ theme |
| Danh sách | `ListView.builder` / sliver | Dữ liệu dài dựng theo nhu cầu, không bọc mọi thứ trong Column |
| Badge | `AppStatusBadge` | Chữ + tông; thêm icon khi hữu ích |
| Avatar | `AppAvatar` khi cần | Placeholder khi thiếu ảnh/lỗi ảnh |
| Loading | `AppLoading`, `AppSkeleton` khi cần | Không chặn toàn màn cho thao tác nhỏ |
| Rỗng/lỗi | `AppEmptyState`, `AppErrorState` | Lời giải thích và hành động phù hợp |
| View bất đồng bộ | `AppAsyncView` | Tải/rỗng/lỗi; phân biệt lần đầu và refresh |
| Xác nhận | `AppConfirmationDialog` dùng `AlertDialog` | Nút ghi đúng tên hành động, ví dụ “Hủy phiếu”; không “OK” |
| Chọn/lọc | `showModalBottomSheet` | Form dài mở màn riêng; tránh modal desktop lớn |
| Tab/chuyển nhóm/lọc nhanh | `TabBar`, `SegmentedButton`, `FilterChip` | Chọn theo ý nghĩa; không coi mọi bộ lọc là tab điều hướng |
| Làm mới danh sách | `RefreshIndicator` | Giữ dữ liệu/bộ lọc, danh sách ngắn hoặc rỗng vẫn có thể kéo nếu phù hợp |
| Chọn/tìm kiếm | Sheet dùng chung khi có nhiều nơi sử dụng | Search, chọn, hủy; hỗ trợ danh sách dài |
| Bộ lọc | `AppFilterSheet` nếu dùng lặp lại | Áp dụng/đặt lại, số bộ lọc đang bật |
| Thông báo ngắn | `ScaffoldMessenger`/SnackBar qua helper | Hành động và lỗi form không chỉ dựa vào SnackBar |
| Tiến độ | `LinearProgressIndicator` hoặc wrapper | Chỉ biểu diễn dữ liệu có thật |
| Chọn ảnh/file | Widget riêng khi có nhu cầu | Permission đúng lúc, preview, nén ảnh theo hợp đồng, tiến độ và hủy upload; mục 16.1 |
| Chuông/danh sách thông báo | Widget/màn thuộc feature `notifications` | Badge theo dữ liệu; push là tích hợp riêng theo mục 16.2 |

Dùng một bộ icon chính, mặc định Material Icons. Không trộn bộ icon ở mỗi feature. Icon đơn có tooltip/semantics label. Ưu tiên widget Material chuẩn đã cấu hình theme thay vì viết lại toàn bộ hành vi focus, semantics và hiệu ứng nhấn.

UiKitScreen là danh mục thử component, không chứa dữ liệu thật và chỉ có route trong debug; release không chỉ ẩn nút truy cập mà còn không đăng ký route.

---

<a id="section-8"></a>
## 8. Khung ứng dụng và mẫu màn hình

### 8.1 Khung ứng dụng

| Web | Mobile tương ứng |
|---|---|
| Sidebar cố định | NavigationBar cho các đích cấp cao; NavigationRail khi rộng |
| Header chung | AppBar gọn; màn con có Back |
| Breadcrumb | Stack điều hướng, tiêu đề màn và nút Back |
| Footer | Phiên bản/hỗ trợ trong màn tài khoản/giới thiệu |
| Bảng nhiều cột | List/card, chỉ hiện thông tin chính; chạm để xem chi tiết |
| Modal lớn | Bottom sheet cho thao tác ngắn; màn riêng cho form dài |
| Bộ lọc ngang | Search và nút mở filter sheet |
| Phân trang số | Tải thêm/cursor hoặc phân trang backend theo hợp đồng |
| Hover | Pressed/selected/focus; không phụ thuộc hover |

Các đích điều hướng cấp cao do `navigation_destinations.dart` khai báo một lần và chọn theo vai trò/quyền backend trả về. **NavigationBar có 3–5 đích chính** khi phạm vi phù hợp; chức năng còn lại nằm trong màn nội dung. Tên đích theo phạm vi đã chốt, không đưa mọi màn thành tab. Bảng ở mục 8.4 là gợi ý bố cục, chưa phải danh sách use case được duyệt.

`AppShell` giữ trạng thái tab/scroll khi cần. Màn chi tiết/form thường dùng route con; tránh lồng nhiều Scaffold hoặc hiện hai AppBar. Android Back và thao tác Back trên iOS phải cho kết quả nhất quán. Deep link chờ kiểm tra phiên trước khi mở màn; sau đăng nhập chỉ điều hướng tới đường dẫn nội bộ đã kiểm tra.

### 8.2 Mẫu màn hình

| Loại | Bố cục đề xuất |
|---|---|
| Trang chủ | AppBar → tóm tắt phù hợp → lối vào các tính năng trong phạm vi |
| Danh sách | Tiêu đề → search/filter → list/card → tải thêm; giữ bộ lọc/scroll khi quay lại |
| Chi tiết | AppBar + Back → thông tin theo section/card → vùng thao tác nếu có |
| Tạo/sửa | AppBar + Back → form cuộn → lỗi từng trường → nút gửi/lưu |
| Form nhiều bước | Progress/step label → nội dung bước → Back/Next; chỉ dùng khi cần |
| Đăng nhập | Logo gọn → form → thông báo lỗi → CTA; không chia cột thương hiệu như desktop |
| Xác thực OTP | Đích nhận mã được che bớt → nhập/dán mã → gửi lại theo thời hạn backend |
| Tải/lỗi phiên | Loading hoặc lỗi có thử lại; không chớp màn đăng nhập rồi nhảy vào app |

Mỗi vùng thao tác chỉ có một CTA chính. Không dùng đồng thời FAB và nút primary cho cùng một thao tác. Dùng nút đủ rộng trong form; không mặc định mọi màn đều có FAB.

### 8.3 Hành vi mobile

- Kéo để refresh chỉ khi phù hợp; không ghi đè form đang nhập.
- Back khi có thay đổi chưa lưu cần xử lý theo thiết kế; dùng cơ chế Back hiện hành của Flutter như `PopScope`, không chặn mọi thao tác Back.
- Đi vào background không tương đương logout. Resume có thể tải lại thông tin phiên/data khi cần; không tự mất nội dung form.
- Quyền camera/ảnh/file hỏi khi người dùng thực hiện thao tác; có cách tiếp tục hoặc mở cài đặt khi bị từ chối.
- Mạng yếu/mất mạng phải có trạng thái rõ. Không coi việc có kết nối Wi-Fi là bằng chứng API truy cập được.
- Chưa có cơ chế đồng bộ thì không báo thao tác offline đã gửi thành công. Giữ dữ liệu form trong state khi request lỗi, gồm điểm danh/đánh giá cuối ngày nếu các màn này thuộc phạm vi đã chốt; lưu draft bền qua việc đóng app chỉ khi có thiết kế riêng.

### 8.4 Nhóm người dùng và khung điều hướng (PROPOSED / NEEDS VERIFICATION)

Review nêu mobile phục vụ **Giáo viên (gồm Tổ trưởng), Phụ huynh, Nhân viên bếp** và ghi thông tin này là CONFIRMED theo Screen Flow mobile v3. Lần sửa này chỉ có hai file DESIGN/review, nên phạm vi ba nhóm cần đối chiếu SRS/Screen Flow gốc trước khi bật đầy đủ. Nếu phạm vi được duyệt chỉ có Teacher và Parent thì chỉ đăng ký hai cấu hình đó; chưa bật Kitchen Staff.

| Nhóm | Mã backend cần đối chiếu | Đích NavigationBar gợi ý | Trạng thái |
|---|---|---|---|
| Giáo viên | `TEACHER` | Trang chủ · Lớp học · Thông báo · Tài khoản | PROPOSED; màn con theo SRS |
| Phụ huynh | `PARENT` | Trang chủ · Bé của tôi · Thông báo · Tài khoản | Bổ sung nhóm còn thiếu; mã/quyền cần đối chiếu backend |
| Nhân viên bếp | `KITCHEN_STAFF` | Trang chủ · Công việc bếp · Thông báo · Tài khoản | NEEDS VERIFICATION về phạm vi mobile |
| Tổ trưởng | `TEAM_LEADER` hoặc quyền/cờ của `TEACHER` | Dùng khung giáo viên; hiện thêm chức năng được phép | OPEN; không mặc định tạo một role riêng |

- Vai trò/quyền lấy từ user do backend trả; người dùng không tự chọn role trong form đăng nhập. Mã không hỗ trợ thì hiển thị trạng thái rõ, không mặc định thành Teacher.
- `route_access_policy.dart` kiểm tra quyền cho cả route trực tiếp và deep link. Ẩn tab/nút chỉ là UX; backend vẫn xác minh quyền và phạm vi dữ liệu cho từng API.
- Deep link từ thông báo chờ xác thực, kiểm tra quyền và dữ liệu đích còn tồn tại; không mở màn cấm chỉ vì payload có ID. Không hiển thị dữ liệu của tài khoản trước sau khi đổi tài khoản.
- Không đưa các role web như Phó hiệu trưởng/nhân viên văn phòng vào mobile chỉ vì cùng dùng backend. Đối chiếu ma trận quyền trong SRS trước khi thêm route.
- Review nêu tài khoản phụ huynh do Phó hiệu trưởng tạo trên web và gửi SMS mời cài app. Ghi nhận là NEEDS VERIFICATION; chưa tự thêm “Đăng ký tài khoản” trên mobile. Hợp đồng kích hoạt/đặt mật khẩu ban đầu cần backend chốt, tách khỏi OTP đăng nhập.

---

<a id="section-9"></a>
## 9. Theme và tổ chức style

Flutter không dùng CSS, BEM, `className`, `var(--token)` hoặc CSS riêng cho feature.

| Nơi | Nội dung |
|---|---|
| `core/constants/colors.dart` | Giá trị màu gốc |
| `core/constants/sizes.dart` | Khoảng cách, bo góc, kích thước dùng chung |
| `core/theme/app_theme.dart` | ThemeData, ColorScheme, theme của input/nút/card/navigation |
| `core/theme/app_text_styles.dart` | TextTheme/typography |
| `core/theme/app_status_colors.dart` | ThemeExtension cho màu semantic ngoài ColorScheme |
| `core/widgets/` | Widget chung có hành vi và style đồng nhất |
| `<feature>/presentation/widgets/` | Widget riêng feature |

Quy tắc:

1. Lấy màu/chữ qua `Theme.of(context)` hoặc ThemeExtension; không tạo màu/cỡ chữ mới trong từng screen.
2. Dùng token khoảng cách và BorderRadius chung; không tạo theme khác cho cùng loại nút ở từng feature.
3. `build()` không gọi API, đọc storage hoặc thay đổi state.
4. Tách widget theo trách nhiệm khi màn hình khó đọc; không tạo widget mới cho mọi SizedBox.
5. Chỉ chuyển widget lên core khi có cùng ngữ nghĩa/hành vi và được tái sử dụng, không chỉ vì hình thức giống nhau.
6. Nếu cần style đặc thù, giữ ở widget riêng feature; token mới dùng chung phải cập nhật guide và UiKitScreen.
7. Dữ liệu động như ảnh/avatar/progress là tham số widget, không phải lý do để bỏ qua theme.

### 9.1 Mẫu cấu hình theme (PROPOSED)

Ví dụ dưới đây đặt trong `core/theme/app_theme.dart`; import `AppColors` từ `core/constants/colors.dart`. Các token lấy đúng mã ở mục 4.1. Đây là **mẫu nền**, chưa bao gồm mọi component theme/ThemeExtension và chưa được chạy trong dự án của nhóm.

```dart
import 'package:flutter/material.dart';
import 'package:carenest_app/core/constants/colors.dart';

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.textInverse,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.brandBlue700,
    error: AppColors.danger,
    onError: AppColors.textInverse,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    ).apply(
      fontFamily: 'BeVietnamPro',
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
```

Trong `app.dart`, truyền `theme: buildLightTheme()` và `themeMode: ThemeMode.light` cho `MaterialApp.router`. Không khóa `textScaler` để ép bố cục.

Hoàn thiện `ThemeExtension<AppStatusColors>` cho success/warning/purple/teal, gồm màu chữ/nền/viền theo tông; triển khai `copyWith` và `lerp`, đăng ký trong `ThemeData.extensions`. `AppStatusBadge` đọc extension để mọi feature dùng cùng màu. Chốt thêm theme cho button/input/card/AppBar/NavigationBar/sheet/dialog và trạng thái pressed/disabled/focus trên UiKitScreen; không coi mẫu trên là toàn bộ theme đã hoàn chỉnh. [S10, S11]


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
- Controller không nhận `BuildContext` chỉ để gọi API; UI xử lý SnackBar/dialog/điều hướng theo kết quả.
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
6. Tạo screen/widgets theo mẫu mục 8, dùng theme và widget chung.
7. Đăng ký route tại `routing/app_router.dart`; route chờ xác thực và kiểm tra vai trò/quyền qua policy, kể cả deep link.
8. Chỉ thêm đích điều hướng cấp cao khi phù hợp; màn chi tiết không mặc định thêm tab.
9. Thử loading/rỗng/lỗi/mạng yếu/bàn phím/chữ lớn/Back; giữ nội dung form khi request thất bại.
10. Kiểm tra analyzer/format; chạy unit/widget/integration test phù hợp với phần thay đổi.
11. Cập nhật UiKitScreen/guide khi tạo component hoặc token chung mới.

---

<a id="section-12"></a>
## 12. Đăng nhập, phiên và lưu token

Mục này mô tả xác thực. Khung vai trò/điều hướng ở mục 8.4; quy tắc kế thừa nghiệp vụ ở mục 18. API và OTP dưới đây là PROPOSED/OPEN cho tới khi backend và SRS chốt.

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

- Tiếng Việt có dấu, câu ngắn, xưng hô trung tính. Code/identifier dùng tiếng Anh.
- Nút bắt đầu bằng động từ: Đăng nhập, Gửi mã, Thử lại, Áp dụng, Lưu thay đổi. Không dùng “OK/Submit” khi có thể ghi rõ hành động.
- Lỗi nêu vấn đề và cách sửa; không đưa exception kỹ thuật lên UI.
- Label không thay bằng placeholder. Trường bắt buộc có dấu và semantics phù hợp.
- Ngày `dd/MM/yyyy` (hiển thị ngày/tháng/năm; `MM` là tháng trong mẫu `intl`), giờ hiển thị theo múi giờ đã thống nhất; không lấy múi giờ máy làm quy tắc nghiệp vụ mặc định. Tập trung `DateFormat`/định dạng số, tiền trong helper; không format khác nhau ở từng screen.
- Nhãn chờ ghi rõ **chờ ai** khi có dữ liệu, ví dụ “Chờ giáo viên xác nhận”; không chỉ hiện “Đang chờ”. Không tự suy đoán người xử lý tiếp theo khi backend chưa trả thông tin.
- Mã máy/enum không hiển thị nguyên văn; nhãn tiếng Việt map ở presentation hoặc mapper phù hợp.
- Nhãn dài được xuống dòng/truncation có chủ đích; không cắt mất thông tin quan trọng chỉ để giữ card thấp.
- Không yêu cầu người dùng hiểu “JWT, refresh token, Dio, HTTP 401”; dùng “Phiên đăng nhập đã hết hạn”, “Không thể kết nối. Hãy thử lại”.

---

<a id="section-14"></a>
## 14. Tải, lỗi, rỗng và xác nhận

| Tình huống | Cách xử lý |
|---|---|
| Tải lần đầu | Loading/skeleton tại vùng nội dung |
| Refresh | Giữ dữ liệu hiện tại, hiển thị tiến độ nhỏ |
| Tải thêm | Spinner cuối list, chặn request trùng, retry tại cuối list |
| Nút đang gửi | Loading + disabled, không gửi lặp |
| Không có dữ liệu | Empty state có giải thích; CTA chỉ khi phù hợp |
| Bộ lọc không có kết quả | Giữ filter, có “Đặt lại bộ lọc” |
| Lỗi form | Lỗi ngay dưới trường; giữ dữ liệu đã nhập |
| Lỗi tải | Error state + “Thử lại” |
| Mất mạng/timeout | Thông báo kết nối; không coi là đăng xuất |
| Thiếu quyền | Màn/thông báo phù hợp; không biến thành dữ liệu rỗng |
| Tác vụ ảnh hưởng lớn | Dialog/sheet xác nhận đúng tên hành động |
| Upload bị hủy/từ chối quyền | Có phản hồi, không tạo bản ghi giả thành công |

Không dùng một boolean `isLoading` cho mọi hoạt động nếu cần giữ list hoặc form độc lập. Không hiện thành công trước khi API xác nhận; optimistic update chỉ dùng khi có chiến lược khôi phục rõ.

Test TalkBack/VoiceOver, nhãn nút icon, thứ tự focus và chữ lớn. Vùng chạm của control tương tác đạt tối thiểu theo mục 5; thông tin quan trọng không chỉ thể hiện qua màu. [S2]

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
- Widget hiển thị preview, xóa ảnh đã chọn, tiến độ và thử lại. Review nêu **tối đa 3 ảnh** cho ImageUploader web; dùng làm giới hạn đề xuất cho màn mobile tương ứng, không áp mặc định cho mọi feature. Backend chốt số ảnh, dung lượng, kích thước và MIME type cho từng endpoint.
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

- [ ] Dùng màu/chữ/khoảng cách từ theme và token chung; primary đúng `#1565E0`, không chỉ dựa vào seed.
- [ ] Material 3, TextTheme, ThemeExtension và Light Theme được cấu hình nhất quán.
- [ ] Dùng widget chung đúng biến thể; widget mới được bổ sung vào UiKitScreen nếu dùng chung.
- [ ] Không sao chép sidebar, breadcrumb, bảng rộng hoặc CSS web sang màn điện thoại.
- [ ] SafeArea, bàn phím, Back và vùng nút dưới cùng hoạt động đúng.
- [ ] Không tràn/cắt chữ với màn nhỏ, chữ lớn và nhãn tiếng Việt dài.
- [ ] Có loading/rỗng/lỗi/retry/disabled phù hợp; giữ form khi request lỗi.
- [ ] Icon tương tác có nhãn; màu trạng thái có chữ/icon; vùng chạm đủ lớn.

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
- [ ] Bản release không có mock login/UiKit route/log nhạy cảm, dùng URL môi trường đúng.
- [ ] Package/platform config và pubspec.lock được cập nhật đồng bộ.
- [ ] Quyền thiết bị và xử lý từ chối quyền đã kiểm tra nếu thay đổi liên quan.
- [ ] Nếu upload ảnh: giới hạn backend, nén, hủy/khôi phục chọn ảnh và lỗi mạng được xử lý.
- [ ] Nếu có push: FCM/APNs, device token, đổi tài khoản và mở deep link đã kiểm tra; không mặc định chuông là push.

---

<a id="section-18"></a>
## 18. Nguồn nghiệp vụ chung và các điểm cần chốt

### 18.1 Kế thừa web/mobile mà không làm lệch đặc tả

| Nội dung chung | Cách dùng cho mobile |
|---|---|
| Thương hiệu, mã màu, font, lưới 4, bo góc | Dùng token Flutter ở mục 3–5; thay đổi token dùng chung cần cập nhật cả guide web/mobile |
| Tông trạng thái và UX copy | Cùng ý nghĩa/nhãn nghiệp vụ; widget Flutter ở mục 6–7, copy ở mục 13 |
| Vòng đời chứng từ | Giữ quy tắc đã được SRS/Use Case duyệt; mobile ánh xạ mã backend sang nhãn/chip, không suy chuyển trạng thái từ màu hoặc vị trí nút |
| Chữ ký và lịch sử xử lý | Giữ ý nghĩa dữ liệu người ký/thời điểm/trạng thái; hiển thị nếu màn mobile được yêu cầu. Nếu ký chỉ có trên web, mobile chỉ xem, không tự thêm nút/khối ký |
| In A4, PrintToolbar, PDF/CSV | Không đưa vào mobile theo phạm vi trong review; nếu yêu cầu thay đổi phải bổ sung thiết kế riêng |

Review dẫn nguồn chung là DESIGN web mục 4, 6, 12, 13; đó là số mục của **bản web được review**, không phải số mục của file mobile này. Bản mobile giữ guideline triển khai riêng; không dùng để ghi đè bản DESIGN dành cho web. Hai file đầu vào không chứa đầy đủ quy tắc vòng đời/chữ ký gốc, nên không tự tạo enum trạng thái, danh sách người ký hoặc bước phê duyệt trong lần sửa này.

### 18.2 Danh sách OPEN / NEEDS VERIFICATION

| Điểm cần chốt | Quy ước tạm trong guide | Cần xác nhận với |
|---|---|---|
| Phạm vi vai trò mobile | Khung Teacher/Parent; Kitchen Staff theo review nhưng chỉ bật sau đối chiếu | SRS/Screen Flow và nhóm nghiệp vụ |
| Tổ trưởng | Không mặc định `TEAM_LEADER` là role riêng | SRS + schema user/permissions backend |
| Tạo tài khoản phụ huynh/SMS mời | Ghi nhận mô tả của review; chưa thêm tự đăng ký | Luồng quản lý tài khoản web/mobile và backend |
| State/DI và routing | Riverpod + go_router là lựa chọn PROPOSED trong guide | Nhóm phát triển trước khi cài package |
| Xác thực native | Bearer + secure storage; fallback cookie ở 12.7 | Backend: endpoint, refresh/rotation/thu hồi và hợp đồng CSRF nếu dùng cookie |
| OTP | Có mẫu challenge/verify/resend; chưa giả định endpoint tồn tại | SRS + backend: khi nào yêu cầu OTP, kênh gửi, thời hạn, giới hạn thử |
| Push notification | FCM là phương án PROPOSED, chưa coi là đã tích hợp | Backend + cấu hình Firebase/APNs |
| Ảnh upload | 3 ảnh chỉ là giới hạn đề xuất cho màn tương ứng trong review | Hợp đồng từng endpoint + nhóm chọn giải pháp nén |
| Chứng từ/chữ ký/quyền dữ liệu | Đọc/hiển thị theo đặc tả đã duyệt; không tự sinh luồng | SRS/Use Case và DTO/API backend |

Phần UI/theme và mock có thể triển khai theo các đề xuất trên. Những tích hợp phụ thuộc một hợp đồng còn OPEN chỉ chuyển sang API thật sau khi hợp đồng được xác nhận và guide được cập nhật; không gắn nhãn CONFIRMED từ mock.

---

## Tài liệu tham chiếu

**Nguồn chỉnh sửa:** `DESIGN (2).md` và `DESIGN_review_Flutter.md` do người dùng cung cấp.

Các lựa chọn cấu trúc, token thiết kế và hợp đồng API trong guide là đề xuất cho CareNest; nguồn dưới đây hỗ trợ nguyên tắc nền tảng/package, không phải xác nhận backend hoặc widget của dự án đã tồn tại.

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

Ngày cập nhật guide: **08/10/2026**. S10–S13 được đối chiếu trong lần sửa này; S1–S9 là liên kết tham khảo giữ từ bản đầu vào. Chưa kiểm tra mã nguồn dự án, build hoặc luồng xác thực thực tế. Khóa phiên bản Flutter/package trong repository và dùng tài liệu tương ứng trước khi triển khai.
