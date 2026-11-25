# CareNest Mobile — Coding Guide (Flutter)

| Thông tin | Giá trị |
| --- | --- |
| Phạm vi | Chạy dự án, thư mục, kiến trúc, auth/token, code style, nối Spring Boot, upload, push, checklist code |
| Giao diện | **Không ở đây** — xem `DESIGN.md` (Phần A: Design System chung web + app; Phần B: riêng App) |
| Nguồn | Tách nguyên văn từ `DESIGN.md` guide mobile 2.0 (mục 1–2, 10–12, 15–16, phần code của 17, 18) ngày 2026-11-15; số mục đổi theo bảng `DESIGN.md` §B10 |
| Trạng thái | Lựa chọn kỹ thuật/API là **PROPOSED** tới khi team và BE xác nhận; **OPEN** là điểm cần chốt |
| Nền đã chốt (25/11) | Phiên/API/push = code PR #8 của Tiền (`lib/core/integration/`: `MobileSession`, `MobileApi`, `PushCoordinator`); state `ChangeNotifier` + constructor. Chỗ guide còn nói `dio`, Riverpod, `AppFailure`, `TokenStorage`, `USE_MOCK` là đề xuất cũ — theo `docs/architecture/MOBILE_ARCHITECTURE.md` |

Nghiệp vụ, quyền, field, endpoint thuộc `CareNest_BE`. Tham chiếu `[Sx]` ở mục "Tài liệu tham chiếu" cuối file.

## Mục lục

1. [Chạy dự án và cấu hình](#section-1)
2. [Cấu trúc thư mục](#section-2)
3. [Kiến trúc và luồng dữ liệu](#section-3)
4. [Quy trình thêm feature](#section-4)
5. [Đăng nhập, phiên và lưu token](#section-5)
6. [Code style và kiểm tra](#section-6)
7. [Nối Spring Boot và tích hợp nền tảng](#section-7)
8. [Checklist code trước PR](#section-8)
9. [Nguồn nghiệp vụ chung và các điểm cần chốt](#section-9)

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
flutter run
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
flutter run --dart-define-from-file=env/local.json
```

Build cho nền tảng được hỗ trợ với **cùng cấu hình môi trường** đã xác nhận:

```bash
flutter build apk --release --dart-define=CARENEST_API_BASE_URL=https://api.example.com/api --dart-define=CARENEST_OIDC_ISSUER=https://sso.example.com/realms/carenest
flutter build appbundle --release --dart-define=CARENEST_API_BASE_URL=https://api.example.com/api --dart-define=CARENEST_OIDC_ISSUER=https://sso.example.com/realms/carenest
```

Các URL trên chỉ là ví dụ. Không chạy release với mock hoặc thiếu URL thật. Quy trình ký/phân phối bản iOS do pipeline dự án quy định.

### 1.2 Cấu hình

| Biến | Vai trò | Nơi đọc |
|---|---|---|
| `CARENEST_API_BASE_URL` | Base URL của API (đã gồm `/api`) | `core/integration/mobile_config.dart` |
| `CARENEST_OIDC_ISSUER` | Issuer Keycloak, vd. `http://localhost:8180/realms/carenest` | `core/integration/mobile_config.dart` |
| `APP_ENV` | `development`, `staging`, `production` (khóa lưu chế độ cuối) | `core/config/env.dart` |

Client id `carenest-mobile` và redirect `carenest://oauth/callback` cố định trong `MobileConfig`.

Chạy với BE thật: `flutter run --dart-define-from-file=env/local.json` (chép từ `env/local.example.json`; `env/*.json` khác mẫu không commit). Bản debug thiếu 2 biến trên ⇒ Đăng nhập giả + Xem thử theo vai trò; bản release thiếu ⇒ bấm Đăng nhập báo "Chưa cấu hình địa chỉ API và Keycloak cho App."

Dùng `String.fromEnvironment` / `bool.fromEnvironment` tập trung trong `env.dart`. Thiếu cấu hình bắt buộc phải được phát hiện khi bootstrap. `--dart-define` không phải nơi cất bí mật; không nhúng mật khẩu, signing key hoặc token cố định vào app.

### 1.3 Package đề xuất

| Nhu cầu | Package/cơ chế | Quy tắc |
|---|---|---|
| HTTP | `MobileApi` (`dart:io` `HttpClient`, PR #8) | Một client dùng chung: `json`, `publicJson`, `multipart`, `binary` |
| State và dependency injection | `ChangeNotifier` + constructor | Dùng nhất quán; không thêm Bloc/Provider/Riverpod nếu chưa thống nhất |
| Điều hướng | `go_router` | Cấu hình ở `routing/`; xử lý phiên qua redirect |
| Token lưu bền | `flutter_secure_storage` | Chỉ lớp storage/auth được truy cập |
| Ngày, số, tiền | `intl` | Tập trung helper, thống nhất locale |
| Thiết lập không nhạy cảm | `shared_preferences` nếu cần | Không lưu token hoặc mật khẩu |
| Chọn ảnh | `image_picker` khi feature cần ảnh | Camera/thư viện, xử lý hủy và phục hồi kết quả trên Android; xem mục 7.1 |
| Nén ảnh | Package phù hợp do nhóm chọn | Nén trước upload theo giới hạn backend, không mặc định image_picker tự nén mọi định dạng |
| Push notification | `firebase_core` + `firebase_messaging` nếu chốt FCM | OPEN: backend, Firebase/APNs và vòng đời device token; xem mục 7.2 |
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
    Logo.jpg                        # Logo đầy đủ hiện có (DESIGN.md §B3)
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
    navigation_destinations.dart    # Cấu hình đích theo vai trò/quyền đã chốt ở DESIGN.md §B5.2
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
## 3. Kiến trúc và luồng dữ liệu

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
- Mobile native không dùng localStorage. Mock nên ở bộ nhớ hoặc fixture JSON; chỉ lưu qua lớp local khi có nhu cầu rõ. Preferences chỉ cho thiết lập không nhạy cảm; token theo mục 5.
- Không mở rộng feature mobile bằng cách sao chép mọi module của web. Phạm vi được xác định ở tài liệu yêu cầu riêng.

---

<a id="section-4"></a>
## 4. Quy trình thêm feature

Ví dụ đường dẫn `features/feature_name/` chỉ minh họa tổ chức, không định nghĩa nghiệp vụ mới.

1. Chốt màn hình, dữ liệu đầu vào/đầu ra và API với tài liệu yêu cầu.
2. Tạo entity và hợp đồng repository thuần Dart trong `domain/`.
3. Tạo DTO, remote datasource và repository implementation trong `data/`.
4. Nếu cần mock, tạo implementation cùng interface và fixture; chọn implementation ở bootstrap/provider, không if mock trong screen.
5. Tạo controller/state; bổ sung use case nếu có phối hợp hoặc logic tái sử dụng đáng kể.
6. Tạo screen/widgets theo mẫu DESIGN.md §8 (chung) và §B5–B6 (riêng App), dùng theme/token/component chung; thiếu thì bổ sung DESIGN.md §B4 và widget test, không dựng style tạm.
7. Đăng ký route tại `routing/app_router.dart`; route chờ xác thực và kiểm tra vai trò/quyền qua policy, kể cả deep link.
8. Chỉ thêm đích điều hướng cấp cao khi phù hợp; màn chi tiết không mặc định thêm tab.
9. Thử loading/rỗng/lỗi/mạng yếu/bàn phím/chữ lớn/Back; giữ nội dung form khi request thất bại.
10. Kiểm tra analyzer/format; chạy unit/widget/integration test phù hợp với phần thay đổi.
11. Cập nhật Design System chung, token hai repo và widget test khi tạo component/token chung; ghi ngoại lệ UI trong PR và đồng bộ phiên bản.

---

<a id="section-5"></a>
## 5. Đăng nhập, phiên và lưu token

Mục này mô tả xác thực. Khung vai trò/điều hướng ở DESIGN.md §B5.2; quy tắc kế thừa nghiệp vụ ở mục 9.

**Đã chốt (user 2026-11-13, BE `AUTH_CONTRACT`):** App dùng OAuth2 Authorization Code + PKCE qua trang Keycloak (client `carenest-mobile`, không password grant), không dùng form mật khẩu của App hay endpoint `/mobile/auth/*` ở §5.2. Chi tiết đang chạy: `docs/integration/AUTH_FLOW.md`; code `lib/features/auth/` (`AppAuthOidcClient`, `SessionManager`, `AuthController`). Các mục 5.2 và 5.7 dưới đây giữ làm tham khảo, không áp dụng; 5.3–5.6 vẫn đúng, với thay đổi: refresh token luôn lưu secure storage (không có tùy chọn "ghi nhớ"), tài khoản lấy từ `GET /accounts/me`.

### 5.1 Chọn cơ chế cho native

| Kênh | Cơ chế trong guide | Nơi giữ thông tin xác thực |
|---|---|---|
| CareNest Web | Cookie HttpOnly | Trình duyệt, backend đặt cookie |
| Flutter Android/iOS | Bearer token | Access token trong bộ nhớ; thông tin khôi phục phiên trong secure storage nếu ghi nhớ |
| Flutter chạy web, nếu phát sinh | Hợp đồng web riêng | Không áp dụng máy móc secure-storage/Bearer của bản native |

Native gọi API bằng Bearer không có cơ chế trình duyệt tự gửi cookie gây CSRF, nên guide không bổ sung CSRF token cho luồng Bearer native. Web giữ bảo vệ cookie/CSRF; nếu native dùng hợp đồng cookie có CSRF thì phải tuân thủ yêu cầu backend ở mục 5.7.

`HttpOnly` là hạn chế JavaScript trong môi trường trình duyệt, không phải một chế độ lưu token của `flutter_secure_storage`. Code native cần đọc token để gắn Bearer; điều này không mâu thuẫn với quy chuẩn web không đọc cookie. `flutter_secure_storage` sử dụng cơ chế lưu bảo mật theo nền tảng, gồm Keychain trên iOS và encrypted storage trên Android. [S7]

**Hợp đồng mobile dưới đây là đề xuất mới cần thống nhất với backend**, không phải endpoint đã tồn tại. Nếu backend chỉ hỗ trợ cookie, chọn phương án 12.7 trước khi viết client.

### 5.2 API mobile đề xuất

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

### 5.3 Nơi lưu token và trách nhiệm

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

### 5.4 Khởi động và khôi phục phiên

1. Bootstrap khởi tạo storage, client, repository và auth controller.
2. Auth state bắt đầu `checking`; router hiển thị màn tải phiên.
3. Nếu không có phiên trong bộ nhớ/refresh token hợp lệ để thử: chuyển `unauthenticated` và mở LoginScreen.
4. Nếu có refresh token đã lưu: gọi refresh, cập nhật token đã rotate rồi gọi `/mobile/auth/me`.
5. Chỉ sau khi backend chấp nhận phiên mới chuyển `authenticated` và mở trang nội bộ được phép.
6. Refresh token bị từ chối/hết hạn: xóa token và yêu cầu đăng nhập. Lỗi mạng/5xx: hiển thị lỗi/thử lại, không xóa token chỉ vì không kết nối được.

Các trạng thái đề xuất: `checking`, `unauthenticated`, `authenticating`, `otpRequired` nếu có, `authenticated`, `error`. Không coi sự tồn tại một chuỗi token hoặc decode JWT ở app là bằng chứng phiên còn hợp lệ.

### 5.5 Dio interceptor và làm mới token

- Gắn `Authorization: Bearer <accessToken>` **chỉ với backend CareNest**; không đưa header này tới URL tải ảnh/file bên ngoài hoặc host khác. Kiểm soát redirect để không chuyển tiếp credential ra host ngoài.
- Không gắn access token vào login/OTP/refresh nếu hợp đồng không yêu cầu. Refresh dùng client riêng hoặc cờ bỏ qua auth-refresh interceptor để tránh vòng lặp.
- `401` từ login là lỗi đăng nhập; không tự refresh. `403` là lỗi quyền/chính sách, không tự logout.
- `401` của request cần xác thực có thể kích hoạt **một lần refresh đang chạy chung**; các request còn lại chờ cùng kết quả. Không tạo nhiều refresh song song dùng cùng refresh token.
- Lưu refresh token mới sau rotation trước khi coi refresh thành công. Nếu logout/đổi tài khoản trong khi refresh chạy, kết quả cũ không được khôi phục phiên; session manager kiểm tra phiên/generation hiện tại.
- Retry tối đa một lần sau refresh cho request đủ điều kiện. Không tự replay upload/stream hoặc thao tác ghi nếu không bảo đảm body có thể gửi lại và backend chưa thực hiện thao tác; dùng cơ chế idempotency khi API hỗ trợ.
- Refresh trả `401`: kết thúc phiên, xóa token, báo một lần. Refresh lỗi mạng/5xx: giữ thông tin khôi phục và cho thử lại; không gọi refresh đệ quy.
- Che/redact Authorization, password, OTP và refresh token trong log. Không bật log body xác thực trong release. [S4]

### 5.6 Đăng xuất và phiên demo

- Logout gọi backend để thu hồi phiên, sau đó dọn token bộ nhớ/secure storage, auth state và cache riêng tài khoản. Hủy request đang chạy và thay route stack để Back không mở lại màn bảo vệ.
- Nếu không liên lạc được backend: vẫn có thể đăng xuất cục bộ bằng cách xóa token trên máy; thông báo thu hồi phiên trên server chưa được xác nhận. Không nói mọi thiết bị đã đăng xuất.
- Nếu xóa secure storage thất bại, không báo đã xóa phiên lưu bền thành công; xử lý lỗi/thử lại để tránh tự khôi phục tài khoản cũ.
- Backend xác minh thông tin đăng nhập và trả user cùng role/quyền; app không tự chọn vai trò. Ánh xạ nhóm mobile theo DESIGN.md §B5.2 sau khi đối chiếu mã backend; guide không thay thế ma trận quyền trong SRS.
- Mock auth dùng fixture và phiên giả ở bộ nhớ, không lưu mật khẩu thật/token backend. Tài khoản demo chỉ hiện khi debug + USE_MOCK; release không có đường đăng nhập demo.
- Không lưu mật khẩu để thực hiện “Ghi nhớ đăng nhập”; chỉ giữ thông tin khôi phục phiên theo chính sách trên.

### 5.7 Nếu backend hiện chỉ hỗ trợ cookie HttpOnly

Đây là phương án thay thế, **không bật đồng thời Bearer và cookie cho cùng một hợp đồng mà chưa thống nhất**.

- Native Dio không tự hoạt động giống trình duyệt: cần cookie manager/jar để nhận Set-Cookie và gửi Cookie, ví dụ `dio_cookie_manager` + `cookie_jar`. [S8]
- Cookie jar ở bộ nhớ mất khi process kết thúc. Nếu ghi nhớ phiên bằng cookie, phải có cơ chế lưu bảo mật qua adapter đã kiểm tra; không coi PersistCookieJar ghi file mặc định là secure storage.
- Không đặt `ignoreExpires: true` cho xác thực. Cookie hết hạn và xóa khi logout phải được xử lý đúng.
- Native Dart có thể tiếp cận dữ liệu cookie; thuộc tính HttpOnly không tạo ranh giới “app không thể đọc token” như JavaScript trình duyệt. Không trộn cookie jar native với WebView mà không có thiết kế riêng.
- Giữ hợp đồng `/auth/login`, `/auth/me`, `/auth/logout`, `/auth/csrf` của web; app gửi header CSRF nếu backend yêu cầu. Không tự tắt CSRF của toàn backend chỉ để native gọi được.
- CORS và `withCredentials` của trình duyệt không áp dụng theo cùng cách cho native Dio. Nếu chạy Flutter Web phải có client/cấu hình riêng theo hợp đồng web.
- Khi chọn phương án này, thay thế hướng dẫn Bearer/refresh/storage tương ứng ở 12.2–12.6 và checklist; không tự gọi các endpoint `/mobile/auth` đề xuất.

---

<a id="section-6"></a>
## 6. Code style và kiểm tra

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

<a id="section-7"></a>
## 7. Nối Spring Boot và tích hợp nền tảng

1. Xác nhận hợp đồng xác thực **native Bearer** hay **cookie**, không tự mặc định dùng endpoint web để lấy token JSON.
2. Thiết lập `API_BASE_URL`, `USE_MOCK=false`; production HTTPS. Điện thoại/emulator có môi trường mạng riêng; `localhost` trên thiết bị không mặc định là máy chạy Spring Boot. Xác nhận địa chỉ truy cập phù hợp với môi trường chạy.
3. Datasource gọi endpoint thật, repository map dữ liệu/lỗi; screen không cần đổi theo việc chuyển mock → API.
4. Thống nhất schema, pagination/cursor, timezone, error code, upload limits và response lỗi từng trường. Giá trị page/pageSize không hardcode khác nhau ở các feature.
5. Với native Bearer: backend hỗ trợ login/me/refresh/logout, rotation và thu hồi phiên theo mục 5. Với cookie: cấu hình cookie manager và CSRF tương ứng; không vô hiệu hóa bảo vệ web vì yêu cầu native.
6. Cấu hình quyền/network/storage Android/iOS đúng package đang dùng. Chỉ cho phép HTTP dev bằng cấu hình phạm vi dev khi cần; release dùng HTTPS, không bỏ kiểm tra certificate.
7. Refresh token lưu qua secure storage; đọc/write/delete có xử lý lỗi. Kiểm tra restore khi app bị đóng, không chỉ hot reload.
8. Nếu có upload, dùng multipart theo hợp đồng; không mặc định lưu mọi file lớn dạng base64. File trả về URL phải có cơ chế xác thực đúng; không rò Bearer qua URL/query hoặc host bên ngoài.
9. Camera/ảnh/file/share chỉ thêm khi scope cần, có mô tả quyền phù hợp và xử lý người dùng từ chối. Push notification là hạng mục tích hợp riêng nếu có, không tự coi chuông trong app là push đã hoạt động.
10. Kiểm tra trên nền tảng được dự án hỗ trợ và ít nhất một thiết bị thật trước phát hành; build iOS/Android theo pipeline và signing của dự án.

### 7.1 Chọn và upload ảnh (PROPOSED)

- Dùng `image_picker` để chọn từ camera/thư viện khi feature cần; thêm mô tả quyền/cấu hình Android/iOS đúng phiên bản package và API nền tảng. Chỉ xin quyền cần thiết tại thời điểm thao tác; xử lý hủy chọn/từ chối quyền. [S12]
- Widget hiển thị preview, xóa ảnh đã chọn, tiến độ và thử lại. DESIGN.md §6.3 nêu **tối đa 3 ảnh** cho ImageUploader web; dùng làm giới hạn đề xuất cho màn mobile tương ứng, không áp mặc định cho mọi feature. Backend chốt số ảnh, dung lượng, kích thước và MIME type cho từng endpoint.
- Nén/resize ảnh trước gửi bằng lớp xử lý ảnh được nhóm chọn; kiểm tra lại kích thước/định dạng sau xử lý. Không coi chọn ảnh bằng image_picker là đã hoàn thành mọi yêu cầu nén. Upload multipart theo hợp đồng API.
- Android có thể hủy Activity lúc mở trình chọn: xử lý kết quả qua `retrieveLostData` theo package, gắn lại đúng form/phiên hiện tại. File camera ở cache có thể là tạm; draft cần giữ qua việc đóng app phải có cơ chế lưu riêng. [S12]
- Giữ form và danh sách ảnh khi lỗi mạng; chỉ báo gửi thành công sau khi API xác nhận. Không tự replay upload sau refresh nếu body/endpoint chưa bảo đảm gửi lại an toàn.

### 7.2 Thông báo đẩy và deep link (OPEN)

Chuông trong app và danh sách thông báo không chứng minh backend đã hỗ trợ push. **FCM là phương án đề xuất**, cần xác nhận backend gửi push, dự án Firebase, APNs cho iOS và hợp đồng đăng ký/hủy device token trước khi tích hợp. [S13]

- `core/notifications` chứa adapter nhận push; `features/notifications` chứa dữ liệu/domain/UI danh sách. Ghép callback điều hướng qua routing/bootstrap, không để core import màn hình feature.
- Khi bật FCM, cấu hình platform và quyền thông báo theo tài liệu Firebase; xử lý từ chối quyền, token thay đổi và việc liên kết device token với user. Logout/đổi tài khoản cập nhật liên kết để thiết bị không tiếp tục nhận thông báo riêng của người cũ. [S13]
- Phân biệt thông báo khi app đang mở, app ở background và mở từ trạng thái đóng; handler nền không điều hướng trực tiếp. Sự kiện mở thông báo đi qua router, chờ phiên và kiểm tra quyền theo DESIGN.md §B5.2.
- Payload chỉ mang loại thông báo/ID tối thiểu; tải dữ liệu chi tiết qua API có xác thực. Tránh hiển thị nội dung nhạy cảm của trẻ trên màn khóa; nội dung thông báo cần nhóm chốt.
- Khi chưa có push backend, chỉ triển khai danh sách/chuông theo API được xác nhận; không báo thông báo đẩy đã hoạt động.

---

<a id="section-8"></a>
## 8. Checklist code trước PR

Checklist giao diện: `DESIGN.md` §13.3 (chung) và §B8 (riêng App).

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

---

<a id="section-9"></a>
## 9. Nguồn nghiệp vụ chung và các điểm cần chốt

### 9.1 Kế thừa web/mobile

| Nội dung | Cách dùng cho mobile |
| --- | --- |
| Logo/tranh/màu/font/spacing/radius/motion/icon | Theo DESIGN.md Phần A §3–6 và Phần B §B1–B4; không có bộ token UI độc lập cho app |
| Tông trạng thái và thuật ngữ | Cùng ý nghĩa; nhãn theo phụ huynh/nhân viên ở DESIGN.md §3.2, §10.2 và §B4.2; legacy purple web = approval app |
| Vòng đời chứng từ | Theo SRS/Use Case và mã BE; không suy chuyển trạng thái từ màu/vị trí nút |
| Chữ ký/lịch sử | Chỉ field/thao tác thuộc phạm vi đã duyệt; nếu ký chỉ ở web thì mobile chỉ xem |
| Khác biệt thiết bị | Chỉ các khác biệt được DESIGN.md §1.3 và §B1 cho phép; bổ sung dòng trước khi tạo khác biệt mới |
| In A4/PDF/CSV | Không tự chuyển PrintToolbar/font Tinos/layout A4 sang mobile; chức năng mới cần yêu cầu riêng |

Các mã ATT-05, NUT-08, HLT-02/05, OBS-03/05, P-13/P-13b được **dẫn từ Design System nguồn**; hai file đầu vào không chứa đầy đủ SRS/Use Case/DTO. Chưa xác minh độc lập nghiệp vụ hoặc endpoint. Không thêm role, trạng thái BE, chữ ký hay bước duyệt chỉ từ ví dụ UI.

### 9.2 Điểm OPEN / NEEDS VERIFICATION

| Điểm | Quy ước tạm | Cần chốt với |
| --- | --- | --- |
| Design System 3.4 | `DESIGN.md` Phần A chép theo bản PROPOSED, không ghi đã duyệt | Team |
| Field phụ huynh P-13b | Dựng khung, field không có thì bỏ dòng | BGH + BE |
| Tab/màn giáo viên/bếp | Hôm nay/Lớp hoặc Bếp/Thông báo/Tài khoản; bếp chỉ bật khi phạm vi duyệt | SRS/Screen Flow + team |
| Tổ trưởng | Không mặc định TEAM_LEADER riêng | SRS + schema user/permissions |
| Tạo tài khoản phụ huynh/SMS mời | Giữ ghi nhận bản mobile trước, không tự đăng ký | Luồng quản lý tài khoản + BE |
| Gói Tabler Flutter | AppIcons tạm Material rounded; giữ tên giống web | Team APP |
| Appearance | T0 Sân chơi, không tự gọi GET /school/appearance | BE |
| Sức khỏe P-13 | Không tự màu/nhãn đánh giá; AI chỉ dữ liệu đã duyệt | BGH + BE |
| Riverpod/go_router | Lựa chọn PROPOSED của guide, không khẳng định đã cài | Team |
| Form auth hay Keycloak | Giữ tranh + logo, form theo phương án chốt | BE + team |
| Bearer/cookie/refresh/CSRF | Giữ đề xuất mục 5; chốt hợp đồng trước tích hợp | BE |
| OTP | Mẫu challenge/verify/resend; không giả định endpoint tồn tại | SRS + BE |
| Push | FCM đề xuất, không coi chuông = push đã hoạt động | BE + Firebase/APNs |
| Upload | Giới hạn theo endpoint; 3 ảnh là mẫu tương ứng web | BE + giải pháp nén |
| Chứng từ/chữ ký/quyền | Hiển thị theo đặc tả/DTO; không sinh luồng | SRS/Use Case + BE |
| Bóng lớp nổi --shadow-xl | Nguồn chưa ghi số; lấy từ tokens.css khi nối code | Team FE/APP |
| Token tự sinh chung | Chưa có; hai file đối chiếu cùng bảng | Team |
| Nối repo APP | Đã nối 2026-11-15: `DESIGN.md` hai phần + guide này | — |

UI/mock có thể triển khai theo nguồn chung; tích hợp phụ thuộc hợp đồng OPEN chỉ chuyển sang API thật sau xác nhận. Không gắn CONFIRMED từ dữ liệu mock hoặc một dòng mô tả widget đã có.

---
<a id="references"></a>
## Tài liệu tham chiếu

**Nguồn bản 10/10/2026:** hai file người dùng cung cấp: “CareNest Mobile – Design & Coding Guide (Flutter)” và “CareNest Design System — web + app” phiên bản 3.1 (09/10/2026). Design System là nguồn quyết định UI. Các tham chiếu DESIGN/review cũ chỉ giữ ở nội dung cần đối chiếu, không coi là tài liệu đã đọc thêm trong lần này.

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

Ngày cập nhật guide: **10/10/2026**; tách khỏi DESIGN.md ngày 15/11/2026, nội dung code giữ nguyên; chưa kiểm tra mã nguồn/build/luồng auth của dự án. Khóa Flutter/package trong repository và dùng tài liệu tương ứng khi triển khai.