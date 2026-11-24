---
title: App nối BE thật — nền đăng nhập/API/push của Tiền (PR #8), UI của Giáp, và lộ trình theo vai trò
status: in-progress  # user duyệt lại 2026-11-25 (Q9, Q10 = có; Native)
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # mã tạm (user 16/11, quyết định 11) — đổi sang mã Jira thật trước khi mở PR vào dev
branch: feature/TBD-4-FE-FEAT-0-app-foundation   # tạo từ origin/dev a811d3d ngày 16/11; đang merge dev 244fbf3 (24/11)
modules: [integration, architecture, features]
rules: [AUTH-07, AUTH-18, AUTH-21, AUTH-22, ADR-0022, ADR-0026, PCK-02]
risk: high           # đổi auth, API client chung, router (vùng dùng chung), sửa code của thành viên khác, gỡ dependency
created: 2026-11-16
updated: 2026-11-24
---
# App nối BE thật — nền của Tiền, UI của Giáp, lộ trình theo vai trò

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App Android chạy thật trên nền đăng nhập, gọi API và push của Tiền (PR #8, đã ở `dev`), giữ toàn bộ màn hình của Giáp, rồi nối API BE cho GV, phụ huynh, bếp.

**Architecture:** `MobileSession` (ChangeNotifier; `flutter_appauth` + `flutter_secure_storage`) giữ phiên. `MobileApi` (`dart:io` `HttpClient`) gọi BE, đọc envelope, ném `ApiFailure`. Mỗi feature có interface `XSource` với bản `FakeXSource` (đã có) và `LiveXSource` (gọi `MobileApi`). Router chế độ thật truyền bản `Live` vào màn. Không dùng Riverpod, Dio.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13.5, `go_router`, `flutter_appauth` 13.0.0, `flutter_secure_storage` 11.2.0, `firebase_core` ^4.15.2 + `firebase_messaging` ^16.7.1 (Tiền), `image_picker` ^1.2.4, `url_launcher` ^6.3.2.

**Spec:** plan này (Đổi hướng 24/11, Quyết định đã chốt, AC) + code PR #8 (`dev` `244fbf3`: `lib/core/integration/`, `push_coordinator.dart`, `live_*_source.dart`) + contract BE `BE:docs/contracts/AUTH_CONTRACT.md`, `BE:docs/contracts/ERROR_CONTRACT.md`, `docs/integration/BE_API_INDEX.md`.

## Đổi hướng 24/11/2026 (đọc trước)
- 17/11 PR #8 của Tiền (G94-288, `nqtienvn`) vào `dev`: đăng nhập PKCE (`MobileSession`, `LiveLoginScreen`), `MobileApi`, thông báo thật, push FCM. Lớp này làm song song với Phase 1 của plan này (Riverpod/Dio, `SessionManager`), chưa vào `dev`.
- 24/11 user merge `dev` vào nhánh, lấy bản Tiền ở cả 22 file conflict. Merge **chưa commit**: `flutter analyze` 488 lỗi (nguyên nhân ở Context).
- User 24/11: giữ phần Tiền đã code, giữ UI của Giáp, nối hoàn chỉnh BE cho App trên nền đó. Phase 1 cũ được thay bằng **Phase R** dưới đây; code Phase 1 cũ gỡ ở Task R6; lịch sử ở Progress log và git (`ac60703`).

## Context
- **Nền của Tiền** (bản merge hiện tại = `dev`):
  - `lib/core/integration/mobile_session.dart:39` `signIn()`: scope `openid profile` (`:49`), không `prompt=login`, không `loginHint`. `profileUpdateRequired` ⇒ ném lỗi và xóa phiên (`:66`, `:74`); `restore()` cũng xóa (`:122-123`).
  - `lib/core/integration/mobile_api.dart:21` `json()`, `:27` `binary()`; `:32` cần `userId` (không gọi được API công khai); `:59` 401 ⇒ refresh 1 lần rồi gửi lại; chỉ có body JSON, không multipart; `:83` `registerDevice`.
  - `lib/app.dart:63-64` đăng nhập xong `go('/live/notifications')`; `:32` bấm push ⇒ `go('/live/notifications/$id')`; `:75` đăng xuất ⇒ `go('/login')`. Không xóa con đang chọn (`SelectedChild`).
  - Router `dev` (`lib/routing/app_router.dart:490` `_liveRoutes`): chế độ thật dưới `/live/...`, mỗi vai trò chỉ có tab Thông báo + Tài khoản (trang khác `const {}`). Vai trò lấy từ `liveRoleOf()` (`live_account_source.dart`): role đầu tiên trong `roles` (BE sắp TEACHER → KITCHEN_STAFF → PARENT), không chuyển chế độ.
  - Không có: kích hoạt tài khoản (AUTH-18), chuyển chế độ GV ↔ phụ huynh (ADR-0022), màn ảnh chân dung (PCK-02), tải ảnh multipart.
- **UI của Giáp** (`HEAD` `718198e`): màn theo vai trò ở `lib/features/{parent,teacher,kitchen,shared,management}/`; shell + màn con ở `_staffAndParentRoutes` (`HEAD:lib/routing/app_router.dart:241`), `_roleShell` (`:597`); `lib/routing/route_access_policy.dart:7` `homePathFor`. Màn dùng `FakeXSource` và nhận `source` qua constructor. Màn điều hướng bằng đường tuyệt đối (`RoutePaths.parentLeaveNotices = '/parent/leave-notices'`) ⇒ chế độ thật phải dùng đường thường, không tiền tố `/live`.
- **488 lỗi của bản merge:**
  - `pubspec.yaml` bản Tiền thiếu `image_picker`, `url_launcher` (UI cần) và `flutter_riverpod`, `dio`, `json_*` (Phase 1 cũ).
  - `app_router.dart` bản Tiền trỏ đường thư mục cũ (167 lỗi).
  - 8 file của Tiền import `features/notifications|account/...`; nhánh đã chuyển 2 thư mục vào `features/shared/`.
  - Manifest bản Tiền mất `allowBackup="false"` và quyền mở trình quay số.
  - 5 file plugin desktop được khôi phục, trong khi nhánh đã bỏ linux/macos/windows (`45cddf1`).
- BE `dev`: nền tảng lấy từ claim `azp` của token (không cần header). `GET /accounts/me` trả `roles` (đã sắp xếp), `childIds`, `profileUpdateRequired`. `PUT /accounts/me/photo` multipart, part `file`; lỗi 1131 "Chọn ảnh chân dung JPG, PNG hoặc WEBP". `POST /parent-activation` công khai, trả `username`; mã sai hoặc hết hạn 400/1006.

## Quyết định đã chốt
1. ~~Riverpod, Dio, json_serializable~~ — thay 24/11 (quyết định 13). Giữ `flutter_appauth`, `flutter_secure_storage`, `firebase_*` (user 13/11).
2. Đăng nhập PKCE qua trang Keycloak — user 13/11, BE `AUTH_CONTRACT.md:9`.
3. Style Clay theo `DESIGN.md` Phần B — user 16/11.
4. BGH chỉ xem, làm phase cuối, chờ BE `TBD-1` — user 16/11. Tới lúc đó BGH/Admin thấy màn "dùng trên Web" (`UnsupportedRoleScreen` của Tiền).
5. Quên mật khẩu: chờ BE G94-87; bản thật không có lối vào — user 16/11.
6. Thông báo trong App + push FCM: dùng code của Tiền (PR #8) — user 24/11 (thay quyết định 6 cũ).
7. Tài khoản nhiều role: mở chế độ nhân sự trước, chuyển sang phụ huynh ở Tài khoản, nhớ chế độ cuối — user 14/11; BE ADR-0022 (phụ huynh cần `childIds` không rỗng).
8. Chỉ build Android; không offline — user 14/11.
9. Phiên thường, không `offline_access` — user 16/11. Code Tiền đúng như vậy (`mobile_session.dart:49`).
10. ~~`json_annotation`, `build_runner`~~ — gỡ ở Task R6 (quyết định 13).
11. Mã Jira `TBD-4` — user 16/11; user 25/11: giữ `TBD-4` khi mở PR, không đổi sang mã thật.
12. Chạy thử với BE + Keycloak local và `adb reverse` — user 16/11.
13. **Nền = code PR #8 của Tiền**; Phase 1 cũ (Riverpod/Dio, `SessionManager`, `ApiClient`, `AuthController`) gỡ hết — user 24/11.
14. **Giữ toàn bộ màn hình của Giáp**; chế độ thật dùng shell và màn của Giáp — user 24/11.
15. **File của Tiền: chỉ thêm** (hàm, tham số tùy chọn mới; không đổi hành vi đang chạy), ghi vào mô tả PR để Tiền biết — user 24/11. Ngoại lệ: quyết định 18.
16. Màn Đăng nhập thật = `LiveLoginScreen` của Tiền + link "Kích hoạt tài khoản"; bỏ `SignInScreen` của Giáp — user 24/11.
17. Hai màn Thông báo = bản của Tiền — user 24/11.
18. ~~Phụ huynh chưa có ảnh: bắt tải ảnh~~ — **đổi 25/11 (user):** App **không buộc** cập nhật ảnh chân dung khi đăng nhập (đúng quyết định user 13/11; Q8 ngày 24/11 hỏi sai). Vẫn đổi hành vi `signIn`/`restore` của Tiền: `profileUpdateRequired` không chặn phiên.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** actor phụ huynh, GV, tổ bếp (AUTH-21 CONFIRMED) · outcome: đăng nhập thật, dùng màn của Giáp, dữ liệu BE theo phạm vi · rule AUTH-18 (CONFIRMED), AUTH-21 (CONFIRMED), AUTH-22 (CONFIRMED), PCK-02 (CONFIRMED, ảnh chân dung bắt buộc), ADR-0022 (ACCEPTED), ADR-0026 (ACCEPTED) · flow `[B]` Keycloak cấp token → `[S]` `GET /accounts/me` → App chọn chế độ → shell của chế độ.
- **Đối chiếu:** code Tiền chặn đăng nhập khi `profileUpdateRequired` (`mobile_session.dart:66`); PCK-02 và BE `MyAccountResponse` ghi "App bắt cập nhật hồ sơ trước khi dùng" ⇒ đổi theo quyết định 18.
- **Ảnh hưởng:** `APP: Đăng nhập, Kích hoạt (mới trên nền Tiền), Ảnh chân dung (mới), Tài khoản (chuyển chế độ), mọi shell vai trò` · vùng dùng chung `lib/core/**`, `lib/routing/**`, `lib/app.dart` · code của Tiền: `mobile_session.dart`, `mobile_api.dart`, `live_login_screen.dart`, `app.dart` (chỉ thêm, trừ quyết định 18) · BE: không đổi contract.

### Câu hỏi mở
- [x] Q5 Sửa file của Tiền tới mức nào? — user 24/11: chỉ thêm (quyết định 15).
- [x] Q6 Màn Đăng nhập? — user 24/11: của Tiền + link kích hoạt (quyết định 16).
- [x] Q7 Màn Thông báo? — user 24/11: của Tiền (quyết định 17).
- [x] Q8 Phụ huynh chưa có ảnh? — user 24/11: bắt tải ảnh; **user 25/11 sửa: không buộc** (quyết định 18).
- [x] Q9 Mỗi lần đăng nhập gửi `prompt=login` để Keycloak luôn hỏi mật khẩu? Lý do: máy bếp dùng chung (AUTH-22); đăng xuất lúc mất mạng thì Keycloak còn phiên, người sau bấm Đăng nhập sẽ vào thẳng tài khoản người trước. Việc này đổi hành vi `signIn` của Tiền. Đề xuất: **có** (Task R3 Step 6).
- [x] Q10 Đang dùng mà Keycloak từ chối làm mới token (hết phiên 30 phút / 10 giờ) ⇒ xóa phiên, về Đăng nhập với chữ "Phiên đăng nhập đã hết. Vui lòng đăng nhập lại."? Hiện code Tiền chỉ báo lỗi ở từng màn, người dùng phải tự mở lại App. Việc này đổi hành vi `_renew` của Tiền. Đề xuất: **có** (Task R5).

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Q5 File của Tiền | Chỉ thêm | user | 2026-11-24 | Quyết định 15 |
| Q6 Màn Đăng nhập | `LiveLoginScreen` + link kích hoạt | user | 2026-11-24 | Quyết định 16 |
| Q7 Màn Thông báo | Bản Tiền | user | 2026-11-24 | Quyết định 17 |
| Q8 Ảnh chân dung | Không buộc cập nhật khi đăng nhập (sửa 25/11; 24/11 đã chọn bắt tải ảnh) | user | 2026-11-25 | Quyết định 18 |
| Q9 `prompt=login` | Có | user | 2026-11-25 | Task R3 Step 6 |
| Q10 Hết phiên khi đang dùng | Có, về Đăng nhập kèm câu báo | user | 2026-11-25 | Task R5 |

## Global Constraints
- Flutter 3.47.6 qua PATH `D:\Flutter_Setup\stable-3.47.6\flutter\bin`; `flutter pub get --enforce-lockfile` exit 0 trước verify.
- Dependency sau Task R6: `go_router`, `flutter_appauth`, `flutter_secure_storage`, `firebase_core`, `firebase_messaging`, `image_picker`, `url_launcher` (+ có sẵn của `dev`). Gói khác ⇒ hỏi trước.
- File của Tiền chỉ thêm (quyết định 15). Mỗi chỗ thêm ghi ở Progress log, mục "Thêm vào code Tiền", để đưa vào mô tả PR.
- Envelope `{code, errorCode, desc, data}`; phân nhánh lỗi theo `ApiFailure.status` + `errorCode`, không so `desc`; `desc` là câu tiếng Việt, hiển thị được.
- Không log token; Bearer chỉ gửi tới host của `CARENEST_API_BASE_URL`; refresh token chỉ ở secure storage (code Tiền đã đúng).
- Test, fixture không chứa dữ liệu trẻ thật, token thật (AGENTS nguyên tắc 4).
- Giao diện mới dùng token/widget `lib/core`; `node scripts/check-design.mjs` (trong verify) không tăng vi phạm.
- Commit `TBD-4: <English verb…>` ≤72 ký tự, commit nhỏ, verify PASS sau mỗi commit; chỉ commit/push khi user cho phép.
- Exit mỗi task: `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0. Sửa docs ⇒ `node scripts/check-ai-layer.mjs` 0 lỗi.

## Review Focus
1. Phụ huynh A đăng xuất, phụ huynh B đăng nhập trên cùng máy ⇒ không thấy con, chế độ hay dữ liệu của A — Task R2 `signOut_clearsModeAndSelectedChild`, Task R1 `live_signOut_resetsSelectedChild`.
2. Đang ở chế độ thật mà màn đẩy tới đường của vai trò khác hoặc đường Xem thử ⇒ về màn chính của chế độ hiện tại, không 404, không lộ màn dữ liệu giả — Task R1 `signedIn_otherRolePath_goesModeHome`.
3. Bấm push khi App đang tắt ⇒ mở đúng chi tiết thông báo trong shell của chế độ hiện tại — Task R1 `live_pushDeepLink_opensDetail`.
4. ~~Phụ huynh chưa có ảnh bị chặn~~ — bỏ 25/11 (quyết định 18): phụ huynh chưa có ảnh vào App bình thường — Task R4 `live_parentWithoutPortrait_opensApp`.
5. Tài khoản GV kiêm phụ huynh nhưng chưa có con đang học ⇒ không có nút chuyển sang phụ huynh — Task R2 `fromAccount_parentNoChild_noParentMode`.

---

## Acceptance criteria (Phase R)
- **AC-R1:** Given bản merge, When `node scripts/verify.mjs`, Then `VERIFY PASS full`, skip 0; test của Tiền (`live_router_test`, `mobile_session_test`, `mobile_api_test`, `push_coordinator_test`, `live_notification_detail_test`) pass không sửa `expect`.
- **AC-R2** (AUTH-21): Given cấu hình thật, When GV, bếp hoặc phụ huynh đăng nhập, Then vào tab Thông báo trong shell của vai trò (code Tiền, `app.dart:64`); các tab khác là màn của Giáp; tab Thông báo dùng dữ liệu BE.
- **AC-R3** (AUTH-21, ADR-0022): Given chỉ có role BGH/Admin, When đăng nhập, Then thấy "Tài khoản này dùng trên Web" và nút Đăng xuất; không vào shell.
- **AC-R4** (ADR-0022, quyết định 7): Given `TEACHER` + `PARENT` và `childIds` không rỗng, Then mở chế độ GV; Tài khoản có "Chuyển sang chế độ phụ huynh"; mở lại App giữ chế độ cuối.
- **AC-R5** (AUTH-18, ADR-0026): Given màn Đăng nhập, When bấm "Kích hoạt tài khoản", nhập SĐT, mã 6 số, mật khẩu mới 2 lần, Then thấy "Tài khoản đã kích hoạt" và nút Đăng nhập; bấm ⇒ trang Keycloak có sẵn tên đăng nhập. 400/1006 ⇒ "Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã."
- **AC-R6** (quyết định 18, sửa 25/11): Given phụ huynh `profileUpdateRequired`, When đăng nhập, Then vào App bình thường, không có màn bắt cập nhật ảnh.
- **AC-R7** (AUTH-22): When đăng xuất, Then con đang chọn và chế độ trong bộ nhớ bị xóa (chế độ cuối đã lưu theo `userId` vẫn giữ).
- **AC-R8:** Given đã đăng nhập, When mở đường con của vai trò (vd. `/parent/leave-notices`), Then mở được; đường của vai trò khác ⇒ màn chính của chế độ hiện tại.
- **AC-R9** (Q9 = có): mỗi lần đăng nhập, Keycloak hỏi lại mật khẩu dù còn phiên trình duyệt.
- **AC-R10** (Q10 = có): refresh bị Keycloak từ chối ⇒ về Đăng nhập, hiện "Phiên đăng nhập đã hết. Vui lòng đăng nhập lại."
- **AC-R11** (quyết định 13): `lib/` và `test/` không còn `flutter_riverpod`, `package:dio`; `AGENTS.md` mục Stack ghi đúng nền mới.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Đường của chế độ thật | Đường thường (`/parent/...`); giữ `/live/notifications`, `/live/notifications/:id`, `/live/unsupported` làm lối vào | Giữ tiền tố `/live` cho mọi màn | Màn của Giáp đẩy đường tuyệt đối; `app.dart` và push của Tiền vẫn chạy không sửa |
| Khi nào dùng router thật | Có `session`, `api`, `signIn`, `signOut` **và** (`enablePreview` = false **hoặc** session có `apiBaseUrl` + `issuer`) | Luôn dùng khi có `session` (như Tiền) | Debug chưa cấu hình vẫn có Xem thử; test của Tiền (`enablePreview: false`) vẫn vào router thật |
| Xem thử khi đã cấu hình thật | Không có | Cùng router | Hai bộ shell trùng đường; giống AC-11 cũ (bản thật không Xem thử) |
| Màn sau đăng nhập | Giữ tab Thông báo (`app.dart:64`) | Về Hôm nay | Quyết định 15 (không đổi hành vi Tiền); đổi sau nếu Tiền đồng ý |
| Chuyển màn theo phiên | Hàm thuần `liveRedirect(...)` ở `lib/routing/live_access.dart` | `redirect` rải ở từng shell | Test được không cần widget; một chỗ cho Review Focus 2, 4 |
| Chế độ | `LiveModeController` (ChangeNotifier) nghe `MobileSession`; lưu bằng `LastModeStore` có sẵn | Sửa `liveRoleOf` của Tiền | Quyết định 15; dùng lại `AppUser.modes` (ADR-0022) |
| Xóa con đang chọn | `LiveModeController` reset `SelectedChild` khi phiên kết thúc | Sửa `app.dart` | Mọi đường đăng xuất/hết phiên đi qua `MobileSession.clear()` ⇒ một chỗ |
| API công khai, multipart | Thêm `MobileApi.publicJson`, `MobileApi.multipart` (+ tham số tùy chọn cho `_request`) | Lớp HTTP riêng | Không lặp lại xử lý envelope/401; chỉ thêm (quyết định 15) |
| Hồ sơ, Đổi mật khẩu ở chế độ thật | Giữ "sẽ có trong bản sau" như Tiền | Nối ngay `PUT /me/password` | Ngoài phạm vi Phase R; đưa vào phase Tài khoản sau |
| Cấu hình | `--dart-define-from-file`, khóa `CARENEST_API_BASE_URL`, `CARENEST_OIDC_ISSUER` (`MobileConfig` của Tiền) + `APP_ENV` | Khóa cũ `API_BASE_URL`, `OIDC_ISSUER`, `USE_MOCK` | Một bộ khóa; `USE_MOCK` thay bằng "đã cấu hình hay chưa" |

## Bản tác động (vùng dùng chung — điểm dừng 2, 3)
```text
Thay đổi: hoàn tất merge dev (PR #8); router chế độ thật dùng shell của Giáp; thêm vào code Tiền
  (MobileApi.publicJson/multipart, MobileSession.signIn(loginHint), reloadAccount, LiveLoginScreen.onActivate);
  đổi hành vi signIn/restore khi profileUpdateRequired (quyết định 18); gỡ Phase 1 cũ + Riverpod/Dio.
impact.mjs 24/11: app_router.dart — dùng bởi lib/app.dart, lan 0 file giao diện;
  mobile_session.dart — dùng bởi app.dart, mobile_api.dart, live_account_source.dart, push_coordinator.dart,
  app_router.dart; lan 0 file giao diện. Ownership chưa khai; lib/core/integration/** do Tiền viết (PR #8).
Luồng người dùng: chưa cấu hình ⇒ như dev (Đăng nhập + Xem thử). Đã cấu hình ⇒ Đăng nhập Keycloak ⇒
  shell của chế độ với màn của Giáp; phụ huynh thiếu ảnh ⇒ màn ảnh trước; GV kiêm PH chuyển được chế độ.
Phương án: A (chọn) nền Tiền + UI Giáp · B nền Phase 1 của Giáp, đổi code Tiền sang ApiClient ·
  C hủy merge, bàn với Tiền trước.
Cách kiểm: test của Tiền pass không sửa expect (AC-R1); test live_access, live_mode_controller,
  widget router thật; chạy BE local theo checklist Task R7.
```

## Lộ trình
| Phase | Nội dung | Trạng thái / chặn |
| --- | --- | --- |
| 1 (cũ) | Nền Riverpod/Dio | Thay bằng Phase R (24/11); code gỡ ở Task R6 |
| 2 | Thông báo + push FCM | Code App xong (Tiền, PR #8). Push thật cần project Firebase + `google-services.json` (không commit) + BE gửi FCM |
| **R** | Hoàn tất merge, chế độ thật dùng UI của Giáp, chế độ GV ↔ PH, kích hoạt, ảnh chân dung, gỡ nền cũ | Task R0–R7 dưới đây |
| 3 | GV nối API | Sau R. Plan con khi bắt đầu (cập nhật `2026-11-15-teacher-api-integration.md` theo `MobileApi`) |
| 4 | Phụ huynh nối API | Sau R. API có: hồ sơ, sức khỏe, nhận xét tuần, đơn nghỉ; thiếu: file `API-phu-huynh-con-thieu-2026-11-24.md` (ngoài repo, thư mục `web` của Giáp, đã gửi Cần) |
| 5 | Bếp nối API | Sau R |
| 6 | Quên mật khẩu SMS | Chặn: BE G94-87 |
| 8 | BGH chỉ xem | Chặn: BE TBD-1 |
| 9 | Release Android | `applicationId` thật, khóa ký, build release, máy thật |

### Mẫu nối một màn (Phase 3–5)
1. Đọc controller + DTO BE của màn; ghi field dùng; field BE không có ⇒ ghi khoảng trống, không bịa.
2. Thêm `Live<X>Source implements <X>Source` cạnh `fake_<x>_source.dart`, gọi `MobileApi.json(...)`, map DTO → domain có sẵn.
3. Router chế độ thật truyền `Live<X>Source(api)` vào màn (màn đã nhận `source`).
4. Test bằng `HttpServer` loopback như `test/features/shared/notifications/mobile_api_test.dart` (Tiền): map đúng; 403/404/409 hiện đúng trạng thái.

| Phase | API BE `dev` (đã kiểm có trong controller 24/11) |
| --- | --- |
| 3 GV | `GET /attendance/classes`, `GET /attendance/day-info`, `GET\|PUT /classes/{classId}/attendance`, `POST /daily-health-entries`, `GET /classes/{classId}/children/{childId}/daily-health`, `GET /leave-requests`, `GET\|PUT /classes/{classId}/daily-assessment/...`, `GET /pickups/classes`, `GET\|POST /pickups`, `GET /children/{childId}/guardian-photos/{guardianId}/url`, `GET /health-checks`, `POST\|PUT /children/{childId}/health/measurements` |
| 4 PH | `GET /children/{childId}/profile`, `GET /children/{childId}/photo/url`, `POST /leave-requests`, `GET /leave-requests/me`, `PATCH /leave-requests/{id}/cancel`, `GET /children/{childId}/health/published`, `GET /children/{childId}/weekly-comments` |
| 5 Bếp | `GET /nutrition/kitchen/day`, `GET /meal-counts`, `GET /nutrition/day-board`, `GET\|POST\|PUT /nutrition/food-samples`, ảnh bữa `/nutrition/meal-photos` (multipart — dùng `MobileApi.multipart` của Task R4) |

## Phase R — Nền của Tiền + UI của Giáp
Review sau mỗi task R0, R1–R2, R3–R5, R6–R7. Dừng chờ user review ở mỗi mốc.

### File structure
- C `lib/routing/live_access.dart` — `liveRedirect(...)`.
- C `lib/features/auth/data/live_mode_controller.dart` — chế độ GV/bếp/PH của phiên thật.
- C `lib/features/auth/data/activation_api.dart` (thay `datasources/activation_remote_data_source.dart`).
- C `lib/core/media/photo_picker.dart` — chọn/chụp ảnh qua `image_picker`.
- C `lib/features/shared/account/data/profile_photo_api.dart`, `presentation/screens/profile_photo_required_screen.dart`.
- M (Tiền, chỉ thêm) `lib/core/integration/mobile_api.dart`, `mobile_session.dart`, `lib/app.dart`, `lib/features/auth/presentation/screens/live_login_screen.dart`.
- M `lib/routing/app_router.dart`, `route_paths.dart`, `route_access_policy.dart`; `lib/features/auth/domain/entities/app_user.dart`; `activation_screen.dart`.
- D Phase 1 cũ (Task R6).

### Task R0: Hoàn tất merge `dev` — build và test xanh, giữ hành vi hai bên
**Files:**
- M `pubspec.yaml`, `pubspec.lock`.
- M (chỉ dòng import) `lib/app.dart`, `lib/features/shared/account/data/live_account_source.dart`, `lib/features/shared/notifications/data/{live_notification_source,push_coordinator}.dart`, `lib/features/shared/notifications/presentation/screens/{notifications_screen,notification_detail_screen}.dart`, `test/features/shared/notifications/{live_notification_detail_test,mobile_api_test,push_coordinator_test}.dart`.
- M `lib/routing/app_router.dart`.
- M `android/app/src/main/AndroidManifest.xml`.
- D `linux/flutter/generated_plugin_registrant.cc`, `linux/flutter/generated_plugins.cmake`, `macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake`.
- D `test/app_test.dart` (kiểm `CareNestApp.start/onResumed` của `app.dart` cũ, đã thay bằng bản Tiền).

**Interfaces:**
- Produces (tạm, R6 bỏ 4 tham số đầu sau `enablePreview`): `GoRouter buildAppRouter({bool enablePreview = kDebugMode, Listenable? refresh, AuthState Function()? readAuth, Future<void> Function()? onSignOut, Future<void> Function(AppMode mode)? onSwitchMode, MobileSession? session, MobileApi? api, Future<void> Function()? signIn, Future<void> Function()? signOut})`.
- `StatefulShellRoute _roleShell(GlobalKey<NavigatorState> rootKey, AppRole role, List<NavDestination> destinations, Map<String, GoRouterWidgetBuilder> screens, {_AccountTab account = const _AccountTab(), NotificationSource notifications = const FakeNotificationSource(), String? Function()? redirect})`.
- `_AccountTab` thêm `final bool live` (true ⇒ "Thông tin cá nhân", "Đổi mật khẩu" gọi `openComingSoon` như `dev`).

- [ ] **Step 1:** `git status` → "All conflicts fixed but you are still merging." (MERGE_HEAD = `244fbf3`).
- [ ] **Step 2:** `pubspec.yaml` = bản Tiền + `image_picker: ^1.2.4`, `url_launcher: ^6.3.2`, `flutter_riverpod: ^3.5.0`, `dio: ^5.11.1`, `json_annotation: ^4.12.0`; dev: `json_serializable: ^6.15.2`, `build_runner: ^2.17.1`. `flutter pub get` → exit 0.
- [ ] **Step 3:** Sửa import `features/notifications/` → `features/shared/notifications/`, `features/account/` → `features/shared/account/`. `grep -rn "carenest_app/features/notifications/\|carenest_app/features/account/" lib test` → 0 dòng.
- [ ] **Step 4:** `app_router.dart` = bản `HEAD` + các phần của `dev`: tham số `session/api/signIn/signOut`; route Đăng nhập dùng `LiveLoginScreen` khi có `session` và `signIn` (như `dev:lib/routing/app_router.dart` khoảng dòng 96–110); `..._liveRoutes(...)` của Tiền, gọi `_roleShell(..., account: _AccountTab(live: true, source: LiveAccountSource(session), onLogout: signOut), notifications: notifications, redirect: ...)`.
- [ ] **Step 5:** Manifest main = bản Tiền (giữ việc bỏ `taskAffinity`, sửa redirect đăng nhập `268c81d`) + `android:allowBackup="false"` + `<queries>` intent `android.intent.action.DIAL` / `tel` của `HEAD`.
- [ ] **Step 6:** Xóa 5 file desktop và `test/app_test.dart`.
- [ ] **Step 6b:** Plan của Tiền `docs/plans/active/2026-11-16-notification-integration.md` thiếu frontmatter ⇒ `check-ai-layer` lỗi E5 (có sẵn từ `dev`). Chỉ thêm frontmatter theo `docs/plans/_TEMPLATE.md`: `status: done`, `owner: Tiền`, `jira: G94-288 / APP-FEAT-55`, `branch: feature/G94-288-APP-FEAT-55-notification-client`, `created: 2026-11-16`. `node scripts/check-ai-layer.mjs` → 0 lỗi.
- [ ] **Step 7:** `flutter analyze` → "No issues found!". `flutter test test/routing/live_router_test.dart test/features/auth/mobile_session_test.dart test/features/shared/notifications` → All tests passed (AC-R1, không sửa `expect` của Tiền).
- [ ] **Step 8:** `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0.
- [ ] **Step 9:** Commit merge (hook cho message bắt đầu bằng `Merge `):
  ```text
  Merge branch 'dev' into feature/TBD-4-FE-FEAT-0-app-foundation

  - Conflicts take dev (PR #8 live sign-in, notifications, push)
  - Fix imports for features moved to shared/, merge router params
  - Keep allowBackup=false and DIAL query, drop desktop plugin files
  ```
  **Dừng chờ review.**

### Task R1: Chế độ thật dùng shell và màn của Giáp
**Files:** C `lib/routing/live_access.dart` · M `lib/routing/app_router.dart` · Test C `test/routing/live_access_test.dart`, C `test/routing/live_ui_router_test.dart`

**Interfaces:**
- Consumes: `homePathFor(AppMode)`, `shellRoleFor(AppMode)` (`route_access_policy.dart`).
- Produces: `String? liveRedirect({required bool signedIn, required AppMode? mode, required bool photoRequired, required String location})` — thứ tự: chưa đăng nhập ⇒ `RoutePaths.login` (trừ khi đang ở `login`, `activate`); không có chế độ ⇒ `/live/unsupported` (trừ khi đang ở đó); `photoRequired` ⇒ `RoutePaths.profilePhoto` (trừ khi đang ở đó); đang ở `login`/`activate` ⇒ `homePathFor(mode)`; đường bắt đầu `/live/` ⇒ `null`; đường ngoài `homePathFor(mode)` ⇒ `homePathFor(mode)`; còn lại `null`.
- Produces: router thật `GoRouter _buildLiveRouter(GlobalKey<NavigatorState> rootKey, {required MobileSession session, required MobileApi api, required Future<void> Function() signIn, required Future<void> Function() signOut})` — dùng khi điều kiện ở Key decisions đúng; `List<RouteBase> _staffAndParentRoutes(rootKey, {_AccountTab account, NotificationSource notifications})`.
- `RoutePaths.profilePhoto = '/profile-photo'` (thêm ngay để `liveRedirect` biên dịch; màn ở R4).

- [ ] **Step 1:** Test `live_access_test.dart`:
  ```dart
  test('signedOut_anyPath_goesLogin', () => expect(liveRedirect(signedIn: false, mode: null, photoRequired: false, location: '/parent'), RoutePaths.login));
  test('signedOut_activate_stays', () => expect(liveRedirect(signedIn: false, mode: null, photoRequired: false, location: RoutePaths.activate), isNull));
  test('signedIn_noAppMode_goesUnsupported', () => expect(liveRedirect(signedIn: true, mode: null, photoRequired: false, location: '/teacher'), '/live/unsupported'));
  test('signedIn_login_goesModeHome', () => expect(liveRedirect(signedIn: true, mode: AppMode.teacher, photoRequired: false, location: RoutePaths.login), RoutePaths.teacherToday));
  test('signedIn_otherRolePath_goesModeHome', () => expect(liveRedirect(signedIn: true, mode: AppMode.parent, photoRequired: false, location: RoutePaths.teacherAttendance), RoutePaths.parentToday));
  test('signedIn_previewPath_goesModeHome', () => expect(liveRedirect(signedIn: true, mode: AppMode.kitchen, photoRequired: false, location: RoutePaths.preview), RoutePaths.kitchenHome));
  test('signedIn_ownChildPath_stays', () => expect(liveRedirect(signedIn: true, mode: AppMode.parent, photoRequired: false, location: RoutePaths.parentLeaveNew), isNull));
  test('signedIn_liveEntry_passesThrough', () => expect(liveRedirect(signedIn: true, mode: AppMode.teacher, photoRequired: false, location: '/live/notifications/12'), isNull));
  ```
- [ ] **Step 2:** `flutter test test/routing/live_access_test.dart` → FAIL (chưa có `liveRedirect`).
- [ ] **Step 3:** Viết `liveRedirect`. Chạy lại → PASS.
- [ ] **Step 4:** Test `live_ui_router_test.dart`, dùng `FakeSession`/`FeedApi` cùng kiểu `test/routing/live_router_test.dart` (chép vào `test/helpers/live_fakes.dart`, không sửa file của Tiền):
  - `live_teacher_landsOnNotifications_thenHomeTabShowsTeacherHome`: `go('/live/notifications')` ⇒ `NavigationBar`; bấm tab "Hôm nay" ⇒ `find.byType(TeacherHomeScreen)` 1.
  - `live_parentChildRoute_opens`: vai trò `['PARENT']` + `childIds: [1]`, `go(RoutePaths.parentLeaveNotices)` ⇒ `LeaveNoticeListScreen`.
  - `live_pushDeepLink_opensDetail`: `go('/live/notifications/7')` ⇒ `NotificationDetailScreen`.
  - `live_signOut_resetsSelectedChild`: đặt `SelectedChild.notifier.value = 'child-2'`, bấm Đăng xuất + xác nhận ⇒ `signOut` được gọi, `SelectedChild.notifier.value == FakeParentHomeSource.children.first.id`.
- [ ] **Step 5:** Router: thêm `_buildLiveRouter`; `redirect` gọi `liveRedirect(signedIn: session.signedIn, mode: <vai trò từ liveRoleOf → AppMode>, photoRequired: false, location: state.matchedLocation)`; `refreshListenable: session`; giữ 3 lối vào `/live/...` của Tiền (đổi đích sang đường thường); bỏ shell `/live/<vai trò>` của `_liveRoutes`. Đăng xuất: `SelectedChild.reset()` rồi `signOut()`.
- [ ] **Step 6:** `flutter test test/routing` → PASS, gồm `live_router_test.dart` của Tiền không sửa `expect`.
- [ ] **Step 7:** Verify → PASS. Commit: `TBD-4: Route live sessions to the role screens` (live_access + test riêng 1 commit, router + widget test 1 commit).

### Task R2: Chế độ GV ↔ phụ huynh (ADR-0022, quyết định 7)
**Files:** M `lib/features/auth/domain/entities/app_user.dart` · C `lib/features/auth/data/live_mode_controller.dart` · M `lib/routing/app_router.dart` · Test M `test/features/auth/domain/app_user_test.dart`, C `test/features/auth/data/live_mode_controller_test.dart`, M `test/routing/live_ui_router_test.dart`

**Interfaces:**
- Produces: `factory AppUser.fromAccount(Map<String, dynamic> account)` — khóa `userId`, `username`, `fullName`, `roles`, `permissions`, `assignments` (`staffRole`, `campusId`, `classroomId`), `childIds`; khóa thiếu ⇒ rỗng.
- Produces: `class LiveModeController extends ChangeNotifier { LiveModeController(MobileSession session, LastModeStore store); AppMode? get mode; List<AppMode> get modes; Future<void> switchTo(AppMode mode); }` — phiên mới (`userId` đổi) ⇒ `modes = AppUser.fromAccount(account).modes`, `mode` = chế độ đã lưu nếu còn trong `modes`, không thì `modes.first`, rỗng ⇒ `null`; phiên kết thúc ⇒ `mode = null`, `modes = []`, `SelectedChild.reset()`; `switchTo` ngoài `modes` ⇒ bỏ qua.
- Router: `refreshListenable: Listenable.merge([session, modeController])`; `liveRedirect(mode: modeController.mode)`; tab Tài khoản `modeSwitches` = mỗi chế độ khác `mode`: `AccountModeSwitch(label: 'Chuyển sang chế độ phụ huynh' | 'giáo viên' | 'bếp', onTap: () => modeController.switchTo(m))`.

- [ ] **Step 1:** Test `app_user_test.dart`:
  ```dart
  test('fromAccount_teacherParentWithChild_modesTeacherThenParent', () => expect(AppUser.fromAccount({'userId': 3, 'roles': ['TEACHER', 'PARENT'], 'childIds': [9]}).modes, [AppMode.teacher, AppMode.parent]));
  test('fromAccount_parentNoChild_noParentMode', () => expect(AppUser.fromAccount({'userId': 3, 'roles': ['TEACHER', 'PARENT'], 'childIds': []}).modes, [AppMode.teacher]));
  ```
- [ ] **Step 2:** Test `live_mode_controller_test.dart` (session giả + `LastModeStore` trên `FlutterSecureStorage.setMockInitialValues({})`):
  - `signIn_teacherParent_noStored_opensTeacher` → `mode == AppMode.teacher`.
  - `signIn_storedParent_opensParent` → lưu sẵn `parent` cho `userId` 3 ⇒ `mode == AppMode.parent`.
  - `switchTo_parent_persistsAndNotifies` → listener gọi 1 lần; controller mới đọc lại ⇒ `parent`.
  - `signOut_clearsModeAndSelectedChild` → `mode == null`, `SelectedChild` về con đầu.
  - `signIn_principalOnly_modeNull` → `mode == null`.
- [ ] **Step 3:** Chạy → FAIL. Viết code. Chạy lại → PASS.
- [ ] **Step 4:** Router dùng controller. Widget test `live_teacherParent_switchToParent_opensParentShell`: tab Tài khoản có "Chuyển sang chế độ phụ huynh"; bấm ⇒ `find.byType(ParentHomeScreen)` sau khi về màn chính.
- [ ] **Step 5:** Verify → PASS. Commit: `TBD-4: Add GV-parent mode switching to live sessions` (tách: `AppUser.fromAccount`; controller; router).
  **Dừng chờ review R1–R2.**

### Task R3: Kích hoạt tài khoản, đăng nhập có sẵn tên (AUTH-18, ADR-0026)
**Files:** M (Tiền, chỉ thêm) `mobile_api.dart`, `mobile_session.dart`, `lib/app.dart`, `live_login_screen.dart` · C `lib/features/auth/data/activation_api.dart` · D `lib/features/auth/data/datasources/activation_remote_data_source.dart` · M `activation_screen.dart`, `app_router.dart` · Test C `test/core/integration/mobile_api_public_test.dart`, C `test/core/integration/mobile_session_sign_in_test.dart`, C `test/features/auth/data/activation_api_test.dart` (thay `activation_remote_data_source_test.dart`), M `test/features/auth/presentation/activation_screen_test.dart`

**Interfaces:**
- `Future<Object?> MobileApi.publicJson(String method, String path, {Object? body})` — không gửi `Authorization`, không cần phiên; đọc envelope và ném `ApiFailure(status, desc, errorCode)` như `json`.
- `Future<void> MobileSession.signIn({String? loginHint})` — truyền `loginHint` vào `AuthorizationTokenRequest`.
- `lib/app.dart`: `Future<void> _signIn({String? loginHint})`. Tham số `signIn` của `buildAppRouter` và `_buildLiveRouter` đổi kiểu thành `Future<void> Function({String? loginHint})`; `LiveLoginScreen` nhận `() => signIn()`.
- `LiveLoginScreen({super.key, required this.signIn, this.onPreview, this.onActivate})` — `onActivate != null` ⇒ nút chữ "Kích hoạt tài khoản" dưới nút Đăng nhập.
- `class ActivationApi { ActivationApi(MobileApi api); Future<String> activate({required String phone, required String code, required String newPassword, required String confirmPassword}); }` — `POST /parent-activation`, body đúng 4 field đó, trả `data.username`.
- `ActivationScreen({super.key, required ActivationApi api, required Future<void> Function({String? loginHint}) signIn})` — StatefulWidget, bỏ Riverpod, giữ giao diện; lỗi: `ApiFailure` 400 + `errorCode` 1006 ⇒ "Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã."; 400 khác ⇒ `desc`; lỗi mạng ⇒ "Không kết nối được. Kiểm tra mạng rồi thử lại."

- [ ] **Step 1:** Test `mobile_api_public_test.dart` (server loopback như test của Tiền): `publicJson_sendsNoAuthorization` (header `authorization` null; trả `data`), `publicJson_400_throwsApiFailureWithErrorCode` (body `{code:400,errorCode:1006,desc:'x'}` ⇒ `ApiFailure.status == 400`, `errorCode == 1006`).
- [ ] **Step 2:** Test `mobile_session_sign_in_test.dart` (dùng lại `FakeAppAuth` kiểu `test/features/auth/mobile_session_test.dart`): `signIn_loginHint_passedToKeycloak` ⇒ `authorization.loginHint == '0912345678'`.
- [ ] **Step 3:** Test `activation_api_test.dart`: `activate_success_returnsUsername`, `activate_postsFourFieldsWithoutAuth`. Test `activation_screen_test.dart`: `activate_success_signInWithUsername` (bấm Đăng nhập ⇒ `signIn(loginHint: '0912345678')`), `activate_1006_showsContactSchool`. Widget router: `liveLogin_activateLink_opensActivation`.
- [ ] **Step 4:** Chạy → FAIL. Viết code theo Interfaces. Chạy lại → PASS.
- [ ] **Step 5:** Ghi Progress log mục "Thêm vào code Tiền": `publicJson`, `signIn({loginHint})`, `_signIn({loginHint})`, `onActivate`.
- [ ] **Step 6 (chỉ khi Q9 = có):** test `signIn_promptLogin_everyTime` ⇒ `authorization.promptValues == ['login']`; thêm `promptValues: const ['login']` vào `signIn`. Ghi Progress log là đổi hành vi (Q9).
- [ ] **Step 7:** Verify → PASS. Commit tách: `TBD-4: Add public JSON calls to MobileApi`, `TBD-4: Pass login hint through live sign-in`, `TBD-4: Rewire account activation to the live session`.

### Task R4: Ảnh chân dung (quyết định 18 — đổi 25/11: không buộc; màn ảnh, `PhotoPicker`, `ProfilePhotoApi`, `reloadAccount` đã gỡ, giữ `MobileApi.multipart` cho bếp)
**Files:** M (Tiền) `mobile_session.dart` (đổi hành vi theo quyết định 18 + thêm), `mobile_api.dart` (thêm) · C `lib/core/media/photo_picker.dart`, `lib/features/shared/account/data/profile_photo_api.dart`, `lib/features/shared/account/presentation/screens/profile_photo_required_screen.dart` · M `app_router.dart` · Test C `test/core/integration/mobile_session_profile_test.dart`, `test/core/integration/mobile_api_multipart_test.dart`, `test/features/shared/account/profile_photo_required_screen_test.dart`, M `test/routing/live_access_test.dart`

**Interfaces:**
- `MobileSession`: `signIn` và `restore` giữ phiên khi `profileUpdateRequired` (bỏ ném lỗi `:66-69`, bỏ `clear()` `:122-124`); thêm `bool get profileUpdateRequired` (= `account?['profileUpdateRequired'] == true`), `Future<void> reloadAccount()` (gọi `/accounts/me` bằng `accessToken()`, gán `account`, `notifyListeners()`).
- `Future<Object?> MobileApi.multipart(String method, String path, {required String field, required Uint8List bytes, required String filename, required String contentType})` — Bearer + refresh-gửi-lại như `json`; `_request` thêm tham số tùy chọn cho phần multipart, nhánh JSON giữ nguyên.
- `abstract interface class PhotoPicker { Future<PickedPhoto?> pick(PhotoSource source); }`, `enum PhotoSource { camera, gallery }`, `class PickedPhoto { final Uint8List bytes; final String filename; final String contentType; }`, `class ImagePickerPhotoPicker implements PhotoPicker` (`maxWidth: 1080`, `imageQuality: 85`).
- `class ProfilePhotoApi { ProfilePhotoApi(MobileApi api); Future<void> upload(PickedPhoto photo); }` — `PUT /accounts/me/photo`, part `file`.
- `ProfilePhotoRequiredScreen({super.key, required ProfilePhotoApi api, required PhotoPicker picker, required Future<void> Function() onSaved, required Future<void> Function() onSignOut})` — chữ: tiêu đề "Cập nhật ảnh chân dung"; mô tả "Nhà trường cần ảnh chân dung của phụ huynh để cô giáo nhận đúng người khi đón bé."; nút "Chụp ảnh", "Chọn ảnh có sẵn", nút chính "Lưu ảnh" (tắt khi chưa có ảnh), nút chữ "Đăng xuất". Lỗi 400/1131 ⇒ `desc` BE; khác ⇒ "Chưa lưu được ảnh. Kiểm tra mạng rồi thử lại."
- Router: `liveRedirect(photoRequired: session.profileUpdateRequired)`; route `RoutePaths.profilePhoto` → màn trên với `onSaved: session.reloadAccount`.

- [ ] **Step 1:** Test: `signIn_profileUpdateRequired_keepsSession` (`signedIn` true, `profileUpdateRequired` true), `restore_profileUpdateRequired_keepsSession`, `reloadAccount_updatesFlag`, `multipart_sendsFilePartWithBearer` (server đọc `content-type: multipart/form-data`, part `name="file"`, header `Bearer`), `liveRedirect_photoRequired_blocksEveryPath` (`/live/notifications/3`, `/parent`, `/teacher` ⇒ `RoutePaths.profilePhoto`; ở `RoutePaths.profilePhoto` ⇒ `null`), màn: `noPhoto_saveDisabled`, `save_success_callsOnSaved`, `save_1131_showsBeMessage`.
- [ ] **Step 2:** Chạy → FAIL. Viết code. Chạy lại → PASS; `flutter test test/features/auth/mobile_session_test.dart` (Tiền) vẫn PASS.
- [ ] **Step 3:** Ghi Progress log: đổi hành vi `signIn`/`restore` (quyết định 18); thêm `profileUpdateRequired`, `reloadAccount`, `multipart`.
- [ ] **Step 4:** Verify → PASS. Commit tách: `TBD-4: Keep live sessions that need a parent photo`, `TBD-4: Add multipart upload to MobileApi`, `TBD-4: Ask parents for a portrait before using the app`.

### Task R5: Hết phiên khi đang dùng (chỉ khi Q10 = có)
**Files:** M (Tiền) `mobile_session.dart`, `live_login_screen.dart` · M `app_router.dart` · Test C `test/core/integration/mobile_session_expiry_test.dart`, M `test/routing/live_ui_router_test.dart`

**Interfaces:**
- `_renew()`: lỗi `invalid_grant` của Keycloak (`FlutterAppAuthPlatformException`, `platformErrorDetails.error == 'invalid_grant'`) ⇒ `clear()`, đặt `expired = true`, ném lại; lỗi mạng ⇒ giữ phiên như cũ. Thêm `bool expired` (về `false` khi `signIn` thành công).
- `LiveLoginScreen` thêm `this.notice` (String?) hiện phía trên nút Đăng nhập. Router truyền `session.expired ? 'Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.' : null`.

- [ ] **Step 1:** Test `renew_invalidGrant_clearsAndMarksExpired`, `renew_networkError_keepsSession`, widget `liveLogin_expired_showsNotice`.
- [ ] **Step 2:** FAIL → viết → PASS. Ghi Progress log (đổi hành vi, Q10).
- [ ] **Step 3:** Verify → PASS. Commit: `TBD-4: Send expired live sessions back to sign-in`.
  **Dừng chờ review R3–R5.**

### Task R6: Gỡ nền Phase 1 cũ, đổi stack và docs (quyết định 13)
**Files:**
- D `lib/core/network/` (7 file), `lib/core/errors/app_failure.dart`, `lib/core/storage/token_storage.dart`, `lib/features/auth/data/session_manager.dart`, `lib/features/auth/data/datasources/{oidc_client,app_auth_oidc_client,account_remote_data_source}.dart`, `lib/features/auth/data/models/me_dto.dart` + `.g.dart`, `lib/features/auth/presentation/controllers/{auth_controller,auth_state}.dart`, `lib/features/auth/presentation/providers/auth_providers.dart`, `lib/features/auth/presentation/screens/{sign_in_screen,session_loading_screen,blocked_screen,config_error_screen}.dart`, `lib/bootstrap.dart`.
- D test: `test/bootstrap_test.dart`, `test/core/network/*` (5), `test/core/storage/token_storage_test.dart`, `test/core/config/env_test.dart`, `test/features/auth/data/{account_remote_data_source_test,app_auth_oidc_client_test,me_dto_test,session_manager_test}.dart`, `test/features/auth/presentation/{auth_controller_test,auth_screens_test}.dart`, `test/helpers/{fake_auth_controller,fake_http_adapter}.dart`, `test/routing/app_router_auth_test.dart`.
- M `lib/main.dart` (= `dev`: `runApp(const CareNestApp())`), `lib/core/config/env.dart` (chỉ còn `appEnv`), `lib/routing/app_router.dart` (bỏ `refresh/readAuth/onSignOut/onSwitchMode`, `_buildSessionRouter`, `_SessionAccountSource`), `lib/routing/route_access_policy.dart` (bỏ `redirectFor`), `test/routing/route_access_policy_test.dart` (bỏ test `redirectFor`), `pubspec.yaml`/`.lock` (bỏ `flutter_riverpod`, `dio`, `json_annotation`, `json_serializable`, `build_runner`), `analysis_options.yaml` (bỏ exclude `*.g.dart`), `env/local.example.json` → `{"APP_ENV": "development", "CARENEST_API_BASE_URL": "http://localhost:8080/api", "CARENEST_OIDC_ISSUER": "http://localhost:8180/realms/carenest"}`, `scripts/check-auth-contract.mjs` (đọc khóa mới nếu đang đọc khóa cũ).
- Docs: `AGENTS.md` (đoạn Stack: thay Riverpod/Dio/json_serializable bằng nền `MobileSession`/`MobileApi` — user 24/11), `docs/architecture/{CODING_GUIDE,STATE_MANAGEMENT,MOBILE_ARCHITECTURE,NAVIGATION}.md`, `.claude/rules/{api-client,state}.md` (+ bản `.agents/` nếu có), `docs/integration/{AUTH_FLOW,BACKEND_INTEGRATION}.md`, `docs/context/CURRENT_STATE.md`.

- [ ] **Step 1:** Xóa/sửa theo danh sách. `grep -rn "flutter_riverpod\|package:dio\|json_annotation" lib test` → 0 dòng.
- [ ] **Step 2:** `flutter pub get` → exit 0; `flutter analyze` → "No issues found!".
- [ ] **Step 3:** Sửa docs; `node scripts/check-ai-layer.mjs` → 0 lỗi.
- [ ] **Step 4:** Verify → PASS. Commit tách: `TBD-4: Remove the superseded Riverpod and Dio auth stack`, `TBD-4: Drop unused Riverpod, Dio and codegen packages`, `TBD-4: Document the live session stack from PR #8`.

### Task R7: Chạy thật, ghi kiểm chứng, PR
- [ ] **Step 1:** BE + Keycloak local (`D:\project_capstone\run-be-dev.ps1`, user chạy); `adb reverse tcp:8080 tcp:8080`, `adb reverse tcp:8180 tcp:8180`; `flutter run --dart-define-from-file=env/local.example.json`.
- [ ] **Step 2:** Checklist (tài khoản seed từ `BE:docker/keycloak/dev/carenest-users-0.json`, không ghi mật khẩu vào repo):
  1. GV ⇒ tab Thông báo; tab Hôm nay là màn của Giáp (AC-R2).
  2. Bếp ⇒ như trên (AC-R2).
  3. Phụ huynh có ảnh ⇒ shell phụ huynh; mở Xin nghỉ (AC-R8).
  4. Phụ huynh chưa có ảnh ⇒ vào App bình thường (AC-R6).
  5. GV kiêm phụ huynh ⇒ chế độ GV; chuyển phụ huynh; đóng mở lại giữ chế độ (AC-R4).
  6. BGH ⇒ "dùng trên Web" (AC-R3).
  7. Kích hoạt bằng mã từ log BE (cổng SMS giả) ⇒ Keycloak có sẵn tên (AC-R5).
  8. Đăng xuất rồi đăng nhập người khác (AC-R7; AC-R9 nếu Q9 = có).
  9. Thông báo: đọc, "Đọc tất cả". Push: chỉ khi có `google-services.json`, không thì ghi "chưa kiểm".
- [ ] **Step 3:** Ghi `docs/quality/VERIFICATION.md` + Progress log.
- [ ] **Step 4:** User cho phép ⇒ push nhánh. PR vào `dev`: cần mã Jira thật (quyết định 11) ⇒ hỏi user; mô tả PR liệt kê mục "Thêm vào code Tiền" và 2 chỗ đổi hành vi (quyết định 18, Q9/Q10 nếu có), nhắn Tiền review.

## Test matrix
| AC | Rule | Test (tầng) | Task | Kết quả |
| --- | --- | --- | --- | --- |
| AC-R1 | — | test của Tiền chạy lại, `verify.mjs` | R0 | — |
| AC-R2 | AUTH-21 | `live_teacher_landsOnNotifications_thenHomeTabShowsTeacherHome` · checklist 1–2 | R1 | — |
| AC-R3 | AUTH-21, ADR-0022 | `signedIn_noAppMode_goesUnsupported`, `live_router_test` (Tiền) · checklist 6 | R1 | — |
| AC-R4 | ADR-0022 | `fromAccount_*`, `live_mode_controller_test`, `live_teacherParent_switchToParent_opensParentShell` · checklist 5 | R2 | — |
| AC-R5 | AUTH-18, ADR-0026 | `publicJson_*`, `signIn_loginHint_passedToKeycloak`, `activate_*`, `liveLogin_activateLink_opensActivation` · checklist 7 | R3 | — |
| AC-R6 | Quyết định 18 | `signIn_profileUpdateRequired_keepsSession`, `restore_profileUpdateRequired_keepsSession`, `live_parentWithoutPortrait_opensApp` · checklist 4 | R4 | — |
| AC-R7 | AUTH-22 | `signOut_clearsModeAndSelectedChild`, `live_signOut_resetsSelectedChild` · checklist 8 | R1, R2 | — |
| AC-R8 | — | `signedIn_otherRolePath_goesModeHome`, `live_parentChildRoute_opens` · checklist 3 | R1 | — |
| AC-R9 | AUTH-22 | `signIn_promptLogin_everyTime` · checklist 8 | R3 (Q9) | — |
| AC-R10 | — | `renew_invalidGrant_clearsAndMarksExpired`, `liveLogin_expired_showsNotice` | R5 (Q10) | — |
| AC-R11 | Quyết định 13 | grep R6 Step 1, `check-ai-layer` | R6 | — |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Tiền tiếp tục sửa `lib/core/integration`, router trên `dev` | Conflict lần nữa | Báo Tiền trước khi làm R3–R5; PR sớm sau R7 | Merge `dev` lại, giữ quyết định 15 |
| Đổi hành vi `signIn`/`restore` (quyết định 18), Q9, Q10 | Tiền không biết, sửa ngược | Ghi rõ ở mô tả PR, nhờ Tiền review | Revert commit tương ứng |
| Gỡ Riverpod/Dio trái docs cũ | Agent sau làm theo docs cũ | Task R6 sửa `AGENTS.md`, rules, docs kiến trúc | — |
| Push thật cần `google-services.json` (không có trong repo) | Không kiểm được push | Checklist ghi "chưa kiểm"; plugin chỉ bật khi có file (`android/app/build.gradle.kts:8`) | — |
| Merge commit lớn (R0) | Khó review | Commit merge chỉ gồm sửa để biên dịch; việc mới ở R1+ | Trước khi commit merge: `git merge --abort` (hỏi user); sau: revert merge |
| Mã tạm `TBD-4` | PR mang mã giả | Đổi trước PR (quyết định 11) | — |

## Validation log
- [x] Khẳng định về code có `file:line` (Context, Interfaces)
- [x] Đổi contract ⇒ consumer cụ thể: BE không đổi; `buildAppRouter` chỉ `lib/app.dart` dùng (impact 24/11); `MobileSession` 5 file dùng, liệt kê ở Bản tác động
- [x] Mỗi AC có test; mỗi task có Exit = lệnh + kết quả mong đợi
- [x] >8 file hoặc >3 phase ⇒ Phase R review 4 mốc; Phase 3–5 có plan con riêng
- [x] Không dùng rule PENDING/OPEN như đã chốt (AUTH-18, AUTH-21, AUTH-22, PCK-02 CONFIRMED; ADR-0022, ADR-0026 ACCEPTED)
- [x] Q9, Q10 user trả lời 25/11: có

## Progress log
### 2026-11-16 → 2026-11-23 — Phase 1 cũ và các màn (tóm tắt)
- Phase 1 (Riverpod/Dio, `SessionManager`, `ApiClient`, `AuthController`, kích hoạt, chuyển chế độ) làm và review 16/11 (verify `tests 356`), chi tiết commit ở git log nhánh (`1ad0f31`..`aa95fa6`). Thay bằng Phase R (24/11).
- 17/11–23/11: các màn phụ huynh, GV, bếp vẽ lại theo Figma và BE (dữ liệu giả), đến `718198e` (xin nghỉ nửa buổi chọn ăn, 24/11).

### 2026-11-24 — Đổi hướng: merge `dev` (PR #8), plan cập nhật (chờ duyệt)
- `dev` local fast-forward `a811d3d..244fbf3`; `git merge --no-commit --no-ff dev`; 22 conflict lấy bản `dev` (user). Chưa commit merge. `flutter analyze` → 488 lỗi (Context).
- `node scripts/check-ai-layer.mjs` sau khi sửa plan: 1 lỗi E5 ở plan của Tiền (thiếu frontmatter, có sẵn từ `dev`) ⇒ Task R0 Step 6b; plan này không có lỗi.
- User chốt Q5–Q8 (quyết định 15–18). Còn Q9, Q10.
- Thêm vào code Tiền: chưa có.
- Tiếp: user trả lời Q9, Q10, duyệt plan, chọn cách làm ⇒ `status: approved`, làm Task R0.

### 2026-11-25 — Task R0: hoàn tất merge `dev` (chờ review)
- User 25/11: Q9 = có, Q10 = có, cách làm Native.
- Commit merge `d9b330b` (2 cha: `718198e`, `244fbf3`).
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 473 fail 0 skip 0`; `flutter analyze` → "No issues found!"; test của Tiền (`live_router_test`, `mobile_session_test`, `test/features/shared/notifications/`) → All tests passed, không sửa `expect`; `node scripts/check-ai-layer.mjs` → 0 lỗi.
- Khác plan:
  - `test/features/shared/notifications/live_notification_detail_test.dart`: đường `../../helpers/` → `../../../helpers/` (file nằm sâu thêm 1 cấp sau khi chuyển vào `shared/`).
  - `scripts/design-baseline.json`: trả dòng `textStyle` = 1 cho `notifications_screen.dart` (nợ có sẵn ở baseline `dev`, đường cũ); không sửa màn của Tiền.
  - Plan của Tiền: `status: in-progress` (không phải `done`): `check-ai-layer` không nhận `done` trong `active/`; plan của Tiền còn bước chạy Android thật + Firebase.
  - Hook secret bắt dòng `onChangePassword` gán `account.live` ⇒ dùng biến cục bộ `live` trong `_roleShell`.
  - Thư mục `linux/`, `macos/`, `windows/` (chỉ còn file sinh tự động, không theo dõi) xóa khỏi ổ đĩa.
- Thêm vào code Tiền: chưa (R0 chỉ sửa import).
- Tiếp: Task R1.

### 2026-11-25 — Task R1–R7 (user: "làm hoàn thành luôn", không dừng ở mốc)
- Verify cuối: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 385 fail 0 skip 0`; `node scripts/check-ai-layer.mjs` → 0 lỗi; `flutter build apk --debug --dart-define-from-file=env/local.example.json` → `√ Built`. Số test giảm 502 → 363 khi gỡ test của nền Riverpod/Dio cũ (R3/R6), rồi tăng lại 385.
- Commit: R1 `db27231`, `fb7a7a4` · R2 `5394168`, `dcc71e7`, `c09733f` · R3 `d76c34c`, `2d8e65e`, `14eda67` · gỡ nền cũ `6310b74`, `4b87b38` · R4 `dce9773`, `a77d126`, `81d6743`, `7beb88e` · R5 `0de3291`, `9c8db6d` · docs `0e2d473`.
- Thêm vào code Tiền (đưa vào mô tả PR):
  - `MobileApi`: `publicJson` (không Bearer), `multipart` (một tệp, refresh như `json`); `_request` thêm tham số tùy chọn `auth`, `form`.
  - `MobileSession`: `signIn({loginHint})`, `profileUpdateRequired`, `reloadAccount()`, `expired`.
  - `LiveLoginScreen`: `onActivate`, `notice`.
  - `app.dart`: `_signIn({loginHint})`, truyền `signInAs` cho router.
- Đổi hành vi code Tiền (user duyệt): `signIn`/`restore` giữ phiên khi `profileUpdateRequired` (quyết định 18); `signIn` luôn gửi `prompt=login` (Q9); refresh bị `invalid_grant` ⇒ xóa phiên, `expired` (Q10); router: tab khác Thông báo/Tài khoản là màn của Giáp (quyết định 14) — sửa 1 `expect` trong `test/routing/live_router_test.dart` của Tiền.
- Khác plan:
  - Router giữ `signIn: Future<void> Function()` (test của Tiền truyền `() async {}`), thêm `signInAs(String username)`.
  - `ActivationScreen` dùng interface `ActivationGateway`; lỗi trường của BE (`data`) không map từng ô vì `ApiFailure` không có danh sách trường — banner hiện `desc`, 1009 vẫn dưới ô mật khẩu.
  - Gỡ nền cũ (R6 Step 1–2) làm trong R3 vì router phiên cũ chặn chữ ký mới của `ActivationScreen`; commit `14eda67` đứng riêng không biên dịch, `6310b74` biên dịch lại.
  - `buildAppRouter` thêm `modeStore` (test truyền kho bộ nhớ); `LiveModeController` bỏ qua mọi lỗi đọc/ghi kho chế độ.
  - Debug chưa cấu hình BE ⇒ Đăng nhập giả + Xem thử (trước đây `LiveLoginScreen` báo lỗi).
- Task R7 Step 1–2 (chạy BE local + điện thoại, checklist 9 mục): **chưa chạy** — BE/Keycloak local không bật (8080, 8180 không trả lời 25/11). Cần user chạy.
- Tiếp: review toàn nhánh; user chạy checklist R7; mã Jira thật trước PR.

### 2026-11-25 — Review toàn nhánh Phase R + lượt sửa (chờ user chạy R7)
- Reviewer mới (đọc code, không chạy máy): 0 Critical, 1 Important, 11 Minor; "ready with fixes".
- Đã sửa (mỗi lỗi có test đỏ trước): I1 router chọn màn trước khi đọc chế độ cuối (`ce202df`, thêm giới hạn 3 giây khi đọc kho); tên tệp ảnh cố định `photo.<đuôi>` (`bbf9d98`); lỗi mở camera và lỗi tải lại tài khoản sau khi đã lưu ảnh (`178ec76`); lỗi đăng nhập sau kích hoạt (`e444695`). Test của Tiền `live_router_test` thêm `setUp` giả lập secure storage.
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 394 fail 0 skip 0`.
- Để sau (Minor): màn Đăng nhập không hiện "phiên đã hết" khi hết phiên lúc mở App; danh sách chuyển chế độ không tự cập nhật sau khi tải lại tài khoản; `LiveModeController` không dispose; tệp ảnh tạm còn trong cache App; HEIC gửi nhãn JPEG; commit `14eda67` không biên dịch riêng (sửa phải viết lại lịch sử — hỏi user); route `splash`/`blocked` thừa; vài dòng docs còn `API_BASE_URL`/`USE_MOCK`; `liveRoleOf` của Tiền không còn dùng; push mở lúc đang ở màn ảnh bị bỏ sau khi lưu.
- Cần BE/user quyết: tài khoản có role PARENT nhưng không còn con đang học vẫn bị BE đòi ảnh (`profileUpdateRequired` không xét `childIds`); phụ huynh không còn con thấy "dùng trên Web".
- Chỉ điện thoại thật xác nhận được: AppAuth Android trả `invalid_grant` ở `platformErrorDetails.error`; Keycloak nhận `prompt=login`, `login_hint`; Spring nhận multipart ảnh.

### 2026-11-25 — Không buộc ảnh chân dung; mã Jira giữ TBD-4
- User 25/11: App không buộc cập nhật ảnh chân dung khi đăng nhập (quyết định 18 sửa, đúng quyết định 13/11). Gỡ màn `ProfilePhotoRequiredScreen`, `ProfilePhotoApi`, `PhotoPicker`, `MobileSession.reloadAccount`/`profileUpdateRequired`, tham số `photoRequired` của `liveRedirect`, route `/profile-photo`. Giữ `MobileApi.multipart` (bếp dùng ở Phase 5) và việc `signIn`/`restore` không huỷ phiên khi `profileUpdateRequired`. Test `live_parentWithoutPortrait_opensApp` đỏ trước, xanh sau.
- Đề xuất BE (Cần/thangnd): `MyAccountResponse` ghi "App bắt cập nhật hồ sơ trước khi dùng (PCK-02, user chốt 2026-10-31)" — lệch quyết định 13/11; nhánh BE `feature/TBD-1-BE-FEAT-0-bgh-mobile-view-only` (TBD-2) đặt `profileUpdateRequired` luôn `false`, chưa vào `dev`.
- User 25/11: giữ mã `TBD-4` cho PR, không cần mã Jira thật (thay quyết định 11).
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 379 fail 0 skip 0`.
