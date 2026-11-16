# Auth Flow — Mobile

Nguồn contract: `BE:docs/contracts/AUTH_CONTRACT.md` (BE `dev`). Plan: `docs/plans/active/2026-11-16-app-be-integration.md`. Code: `lib/features/auth/`, `lib/core/network/`, `lib/core/storage/`.

## Cơ chế (CONFIRMED — user 13/11, BE AUTH_CONTRACT)
- OAuth2 Authorization Code + PKCE S256 với Keycloak realm `carenest`, client `carenest-mobile` (public, không password grant). Redirect `carenest://oauth/callback`.
- App mở trang đăng nhập Keycloak bằng trình duyệt hệ thống (`flutter_appauth`); SĐT + mật khẩu nhập ở trang đó, App không giữ mật khẩu.
- Mỗi lần đăng nhập gửi `prompt=login`: máy dùng chung (bếp — AUTH-22) luôn hỏi lại mật khẩu.
- Scope `openid profile`. Phiên thường, không `offline_access` (user 16/11): phiên Keycloak hết sau ~30 phút không refresh, tối đa 10 giờ từ lúc đăng nhập. Đổi sang phiên dài ⇒ thêm `offline_access` vào `kOidcScopes` + task BE cho client.
- Cấu hình: `--dart-define-from-file=env/local.json` (mẫu `env/local.example.json`): `USE_MOCK=false`, `API_BASE_URL` (gồm `/api`), `OIDC_ISSUER`; thiếu biến ⇒ màn lỗi cấu hình.

## Token
- Access token (5 phút): chỉ trong bộ nhớ (`SessionManager`). Refresh token + id token: `flutter_secure_storage`, khóa `carenest.<APP_ENV>.refresh_token` / `.id_token`.
- Bearer chỉ gửi tới host của `API_BASE_URL`; không log header/body (`SafeLogInterceptor`).
- Còn < 30 giây thì refresh trước khi gửi request. 401 ⇒ refresh một lần (dùng chung cho mọi request đang chờ) rồi gửi lại một lần; body `FormData` không gửi lại.
- Refresh bị Keycloak từ chối (`invalid_grant`) ⇒ xóa token, về Đăng nhập với "Phiên đăng nhập đã hết…". Mất mạng/Keycloak lỗi ⇒ `NetworkFailure`, giữ token, cho thử lại.
- Android `allowBackup=false` chặn backup lên cloud/adb; chuyển máy trực tiếp (device-to-device, Android 12+) vẫn có thể mang file theo, nhưng không có khóa Keystore ⇒ đọc lỗi ⇒ xóa khóa hỏng, coi như chưa đăng nhập (plugin cũng tự xóa: `resetOnError`).

## Sau đăng nhập
- `GET /accounts/me` ⇒ `roles`, `permissions`, `assignments`, `childIds`. Gọi lại khi App quay lại foreground (tối đa 1 lần/60 giây); lần gọi lại này lỗi mạng/BE thì giữ nguyên màn đang dùng, lần quay lại sau thử tiếp. Kết quả đến sau khi đã đăng xuất/đăng nhập lại bị bỏ.
- Chế độ (ADR-0022): `TEACHER` ⇒ GV, `KITCHEN_STAFF` ⇒ bếp, `PARENT` + `childIds` không rỗng ⇒ phụ huynh. Nhiều chế độ ⇒ mở chế độ nhân sự, chuyển ở màn Tài khoản, nhớ chế độ cuối theo `userId` (user 14/11). Chế độ không gửi lên BE.
- 403 `1101` ở `/accounts/me` (token App không có role App — BGH, Admin) ⇒ "Tài khoản này dùng trên Web CareNest." BGH chỉ xem trên App: chờ nhánh BE TBD-1 (plan 16/11 quyết định 4).
- 403 `1014` / `1015` ⇒ "Tài khoản chưa dùng được. Vui lòng liên hệ nhà trường." Không tự thử lại.
- 503 `1013` hoặc mất mạng lúc mở App ⇒ màn "Thử lại" (giữ token) kèm "Đăng xuất"; lỗi khác (BE lỗi, Keycloak từ chối vì cấu hình) ⇒ cùng màn với câu "Máy chủ đang gặp lỗi…".

## Kích hoạt tài khoản phụ huynh (AUTH-18, ADR-0026)
- Màn "Kích hoạt tài khoản" (chưa đăng nhập): SĐT, mã SMS 6 số, mật khẩu mới 2 lần ⇒ `POST /parent-activation` (công khai, không Bearer) ⇒ `{ username }` ⇒ mở Keycloak với `login_hint` = username.
- 400 `1006` ⇒ "Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã."; 400 `1009` ⇒ lỗi mật khẩu theo `desc`.

## Đăng xuất
- Hộp xác nhận ⇒ xóa token trên máy, về Đăng nhập ngay (xóa back stack; đăng xuất từ màn Tài khoản còn xóa ngữ cảnh con đang chọn); POST `{issuer}/protocol/openid-connect/logout` với `client_id` + `refresh_token` chạy nền, lỗi mạng bỏ qua. Kiểm 16/11 trên BE local: logout 204, refresh token cũ sau đó bị từ chối (`invalid_grant`).

## Chưa làm
- Quên mật khẩu: chờ API SMS ở nhánh BE `feature/G94-87-BE-FEAT-0-app-rules-sms-reset` (plan 16/11 quyết định 5); bản thật ẩn lối vào.
- Đăng ký/hủy device push token (`PUT|DELETE /me/devices`): Phase 7 (FCM).
- Đổi mật khẩu khi đã đăng nhập (`PUT /me/password`): chưa nối.
