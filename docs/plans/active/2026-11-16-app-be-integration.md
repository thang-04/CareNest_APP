---
title: App nối BE thật — nền App (đăng nhập PKCE, API client) và lộ trình theo vai trò
status: in-progress  # user duyệt 2026-11-16 (Native); draft → approved → in-progress → done | blocked | cancelled
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # mã tạm (user 16/11, quyết định 11) — đổi sang mã Jira thật trước khi mở PR vào dev
branch: feature/TBD-4-FE-FEAT-0-app-foundation   # tạo từ origin/dev a811d3d ngày 16/11
modules: [integration, architecture, features]
rules: [AUTH-07, AUTH-18, AUTH-21, AUTH-22, ADR-0022, ADR-0026]
risk: high           # đổi auth, API client chung, router (vùng dùng chung), thêm dependency
created: 2026-11-16
updated: 2026-11-16
---
# App nối BE thật — nền App và lộ trình theo vai trò

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App Android đăng nhập thật qua Keycloak (PKCE) và gọi API BE `dev` thay dữ liệu giả cho phụ huynh, GV, bếp; phần còn chặn bởi BE làm sau cùng.

**Architecture:** Feature-based + Clean Architecture theo `docs/architecture/CODING_GUIDE.md` §2–5. Riverpod ghép dependency; một `ApiClient` (Dio) parse envelope và lỗi ở một chỗ; `SessionManager` giữ access token trong bộ nhớ, refresh token trong secure storage; go_router chuyển màn theo `AuthState`. Mỗi feature có repository interface với 2 bản: giả (`USE_MOCK=true`) và gọi BE.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13.5, `go_router`, `flutter_riverpod`, `dio`, `json_serializable` (+ `json_annotation`, `build_runner`), `flutter_appauth`, `flutter_secure_storage`. `firebase_core` + `firebase_messaging` chỉ thêm ở Phase 7.

**Spec:** plan này (Quyết định đã chốt, Làm rõ nghiệp vụ, Acceptance criteria) + contract BE `BE:docs/contracts/AUTH_CONTRACT.md`, `BE:docs/contracts/ERROR_CONTRACT.md`, `docs/integration/BE_API_INDEX.md`.

## Context
- App `dev` (`a811d3d`, 16/11): 33 thư mục feature dùng `Fake*Source`, chưa gọi API (`docs/integration/BACKEND_INTEGRATION.md:13`). `pubspec.yaml` chỉ có `go_router`. `lib/core/config/env.dart:2-8` có `API_BASE_URL`, `USE_MOCK`, `APP_ENV`. `lib/routing/app_router.dart:76-80` mở thẳng màn Đăng nhập giả; màn theo vai trò chỉ có khi `enablePreview` (debug).
- PR #6 (redraw G94-194) vào `dev` rồi bị PR #7 revert ngày 15/11. User 16/11 chọn giữ style Clay của `dev` (`DESIGN.md` Phần B). Plan này làm trên code `dev`.
- BE `dev` (`a5ad6b1e`, 15/11):
  - Keycloak realm `carenest`, client `carenest-mobile` public + PKCE S256, redirect mặc định `carenest://oauth/callback`, `directAccessGrantsEnabled: false` (`BE:docker/keycloak/import/carenest-realm.json`). Access token 5 phút; phiên SSO hết sau 30 phút không dùng, tối đa 10 giờ.
  - `GET /accounts/me`, `POST /parent-activation` (công khai), thông báo `GET /me/notifications`, `PUT|DELETE /me/devices`, API nghiệp vụ điểm danh, sức khỏe, đơn nghỉ, đón trẻ, đánh giá, bếp.
  - Push thật chưa có: chỉ `LoggingPushGateway` ghi log.
  - BGH dùng token App ⇒ mọi API trả 403 `errorCode` 1101 (ADR-0022, ACCEPTED).
- Docs App trên `dev` lệch BE:
  - `docs/integration/AUTH_FLOW.md` ghi "CHƯA CÓ NỘI DUNG".
  - `CODING_GUIDE.md` §5.2 đề xuất `/mobile/auth/login`. BE không có endpoint này; Mobile dùng PKCE (`BE:docs/contracts/AUTH_CONTRACT.md:9`).
  - `BACKEND_INTEGRATION.md` chưa nói tới `errorCode` và coi `desc` là tiếng Anh; BE đã có `errorCode`, `desc` là câu tiếng Việt (`BE:docs/contracts/ERROR_CONTRACT.md`).
  - Phase 1 sửa các docs này (Task 10).

## Quyết định đã chốt
1. Thư viện `flutter_riverpod`, `dio`, `json_serializable`, `flutter_appauth`, `flutter_secure_storage`, `firebase_core` + `firebase_messaging` — user 13/11. Docs `dev` còn ghi PROPOSED vì PR #6 bị revert.
2. Đăng nhập PKCE qua trang Keycloak; theme CareNest cho trang này là task BE — user 13/11, BE `AUTH_CONTRACT.md:9`.
3. Style Clay theo `DESIGN.md` Phần B của `dev`; không làm lại style phẳng — user 16/11.
4. BGH giữ "chỉ xem trên App", làm phase cuối, chặn tới khi nhánh BE `feature/TBD-1-BE-FEAT-0-bgh-mobile-view-only` vào `dev` — user 16/11. Tới lúc đó tài khoản BGH đăng nhập App thấy "dùng trên Web".
5. Quên mật khẩu: chờ BE (API SMS ở nhánh BE `feature/G94-87-BE-FEAT-0-app-rules-sms-reset`), chưa làm; bản release ẩn lối vào — user 16/11.
6. Thông báo: danh sách trong App trước (`GET /me/notifications`); FCM sau, khi BE có bộ gửi FCM và nhóm có project Firebase — user 16/11.
7. Tài khoản nhiều role: mở chế độ nhân sự, chuyển sang phụ huynh ở màn Tài khoản, nhớ chế độ cuối — user 14/11; BE ADR-0022 (có `PARENT` và `childIds` không rỗng mới có chế độ phụ huynh; chế độ không gửi lên BE).
8. Capstone chỉ build Android; không offline — user 14/11.
9. Phiên đăng nhập: phiên thường, không xin `offline_access` (hết sau khoảng 30 phút không có refresh, tối đa 10 giờ từ lúc đăng nhập) — user 16/11. Đổi sang `offline_access` chỉ khi user báo; lúc đó thêm scope vào `kOidcScopes` và làm task BE cho client `carenest-mobile`.
10. Thêm 2 gói đi kèm `json_serializable`: `json_annotation` (runtime) và `build_runner` (dev) — user 16/11.
11. Mã Jira tạm `TBD-4` (mã công việc tạm `FE-FEAT-0`) cho mọi commit của plan; chưa có task Jira thật — user 16/11. Mỗi commit vẫn ứng với đúng 1 task trong plan, ghi bảng commit → task ở Progress log. Trước khi mở PR vào `dev`: user tạo task Jira thật, agent đổi mã từng commit theo bảng (viết lại lịch sử nhánh; đã push thì force push có lease — hỏi user lúc đó). `TBD-1`, `TBD-2`, `TBD-3` đã dùng ở nhánh khác.
12. Chạy thử với BE + Keycloak local (docker) và `adb reverse` — user 16/11.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** actor phụ huynh, GV, tổ bếp (AUTH-21 CONFIRMED) · outcome: đăng nhập thật, thấy dữ liệu BE theo phạm vi · rule AUTH-07 (ACCEPTED), AUTH-18 (CONFIRMED), AUTH-21 (CONFIRMED), AUTH-22 (CONFIRMED), ADR-0022 (ACCEPTED), ADR-0026 (ACCEPTED) · flow `[B]` Keycloak cấp token → `[S]` `GET /accounts/me` trả role, quyền, phân công, `childIds` → App dựng màn theo chế độ.
- **Đối chiếu thiết kế ban đầu:** `CODING_GUIDE.md` §5.2 (form mật khẩu + `/mobile/auth/*`) khác BE (PKCE, không password grant) ⇒ theo BE (quyết định 2). Màn Đăng nhập App thật không còn ô SĐT/mật khẩu; người dùng nhập ở trang Keycloak.
- **Ảnh hưởng:** `APP: Đăng nhập, Kích hoạt tài khoản (mới), Tài khoản (đăng xuất, chuyển chế độ), mọi shell vai trò` · vùng dùng chung `lib/core/**`, `lib/routing/**`, `lib/app.dart` · BE: Phase 1 không đổi contract.

### Câu hỏi mở
- [x] Q1 Phiên đăng nhập: `offline_access` hay phiên thường? — user 16/11: phiên thường; đổi sau thì user báo (quyết định 9).
- [x] Q2 Mã Jira và mã công việc cho Phase 1? — user 16/11: chưa có task Jira, dùng mã tạm gộp chung, tách task sau (quyết định 11).
- [x] Q3 Môi trường chạy thử: BE local hay VPS dev? — user 16/11: BE local (quyết định 12).
- [x] Q4 Duyệt `json_annotation` và `build_runner`? — user 16/11: duyệt (quyết định 10).

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| BGH trên App | Giữ chỉ xem, phase cuối, chờ BE | user | 2026-11-16 | Quyết định 4 |
| Quên mật khẩu khi BE chưa có API SMS | Chờ BE, chưa làm | user | 2026-11-16 | Quyết định 5 |
| Thông báo / push | Danh sách trước, FCM sau | user | 2026-11-16 | Quyết định 6 |
| Style | Clay của `dev` | user | 2026-11-16 | Quyết định 3 |
| Q1 Phiên đăng nhập | Phiên thường; `offline_access` tính sau, user báo khi đổi | user | 2026-11-16 | Quyết định 9 |
| Q2 Mã Jira | Mã tạm `TBD-4` gộp chung, tách task Jira thật trước PR | user | 2026-11-16 | Quyết định 11 |
| Q3 Môi trường chạy thử | BE + Keycloak local | user | 2026-11-16 | Quyết định 12 |
| Q4 Gói đi kèm | Duyệt `json_annotation`, `build_runner` | user | 2026-11-16 | Quyết định 10 |

## Global Constraints
- SDK Flutter 3.47.6 / Dart 3.13.5 theo `pubspec.lock`. Chạy lệnh `flutter` qua PATH tiến trình `D:\Flutter_Setup\stable-3.47.6\flutter\bin`. `flutter pub get --enforce-lockfile` exit 0 trước khi verify.
- Dependency chỉ gồm quyết định 1 và 10. Gói khác (`flutter_local_notifications`, `shared_preferences`) ⇒ hỏi trước. `image_picker` user duyệt 17/11 cho camera ảnh mẫu bữa của bếp.
- Envelope BE `{code, errorCode, desc, data}`; `code` == HTTP status. Phân nhánh lỗi theo status + `errorCode`, không so `desc`. `desc` là câu tiếng Việt, hiển thị được.
- Access token chỉ ở bộ nhớ. Refresh token và id token chỉ ở `flutter_secure_storage`. Không log token, không đưa token vào URL. Bearer chỉ gửi tới host của `API_BASE_URL`.
- Test, fixture, log không chứa dữ liệu trẻ thật hoặc token thật (AGENTS nguyên tắc 4).
- Giao diện dùng token/widget của `lib/core`; `node scripts/check-design.mjs` (chạy trong verify) không tăng vi phạm.
- Commit `<mã-jira>: <English verb…>` ≤72 ký tự; `<mã-jira>` hiện là mã tạm `TBD-4` (quyết định 11). Chỉ commit/push khi user cho phép trong tin nhắn đó.
- Commit nhỏ, đủ ý: mỗi commit 1 thay đổi logic (vd. 1 lớp + test của nó), verify vẫn PASS sau mỗi commit; không gộp cả task thành 1 commit — user 16/11.
- Mỗi phần review: `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0. Sửa docs ⇒ `node scripts/check-ai-layer.mjs` 0 lỗi.

## Review Focus
1. Mở lại App khi refresh token đã hết hạn hoặc bị thu hồi ⇒ về Đăng nhập, không kẹt màn chờ, không vòng lặp refresh — Task 6 `restore_expiredRefresh_signsOut`.
2. Mất mạng hoặc Keycloak/BE trả 503 lúc mở App ⇒ màn "Thử lại", **giữ** token, không đăng xuất — Task 6 `restore_networkError_keepsTokens`, Task 7 `start_meServiceUnavailable_showsRetry`.
3. Nhiều request cùng nhận 401 ⇒ chỉ một lần refresh, mỗi request gửi lại tối đa một lần — Task 3 `on401_refreshesOnceThenRetries`, Task 6 `refresh_concurrentCalls_singleFlight`.
4. Đăng xuất rồi đăng nhập tài khoản khác trên cùng máy (máy bếp dùng chung — AUTH-22) ⇒ Keycloak hỏi lại mật khẩu, không còn dữ liệu hay chế độ của người trước — Task 5 `signIn_requestsPromptLoginAndPkceClient`, Task 7 `signOut_clearsUserAndMode`.
5. Đổi máy hoặc khôi phục backup làm secure storage đọc lỗi ⇒ coi như chưa đăng nhập, xóa khóa hỏng, không crash — Task 4 `read_platformError_returnsNullAndClears`.

---

## Acceptance criteria (Phase 1)
- **AC-1** (AUTH-21, ADR-0022): Given tài khoản GV, bếp hoặc phụ huynh đang ACTIVE, When bấm "Đăng nhập" và nhập SĐT + mật khẩu ở trang Keycloak, Then vào màn chính của chế độ: GV ⇒ `/teacher`, bếp ⇒ `/kitchen`, phụ huynh ⇒ `/parent`.
- **AC-2** (ADR-0022, quyết định 4): Given tài khoản chỉ có role BGH hoặc Admin, When đăng nhập App, Then thấy "Tài khoản này dùng trên Web CareNest." và nút "Đăng xuất"; không vào shell nào.
- **AC-3** (AUTH_CONTRACT 1014, 1015): Given tài khoản bị khóa hoặc chưa có hồ sơ, When đăng nhập hoặc App gọi API, Then thấy "Tài khoản chưa dùng được. Vui lòng liên hệ nhà trường." và nút "Đăng xuất"; không tự thử lại.
- **AC-4:** Given đã đăng nhập, When đóng App rồi mở lại trong thời hạn phiên, Then vào thẳng màn chính, không hỏi mật khẩu.
- **AC-5:** Given access token đã hết hạn (5 phút), When App gọi API, Then App tự refresh; người dùng không thấy lỗi.
- **AC-6:** Given phiên hết hạn hoặc bị thu hồi, When App gọi API hoặc mở App, Then về Đăng nhập, back stack bị xóa, hiện "Phiên đăng nhập đã hết. Vui lòng đăng nhập lại."
- **AC-7** (CODING_GUIDE §5.6): When bấm "Đăng xuất" và xác nhận, Then App thu hồi refresh token ở Keycloak (lỗi mạng vẫn xóa trên máy), xóa token và state, về Đăng nhập. Keycloak không còn phiên `carenest-mobile` của người đó.
- **AC-8** (ADR-0022, quyết định 7): Given tài khoản có `TEACHER` + `PARENT` và `childIds` không rỗng, Then mở chế độ GV; màn Tài khoản có "Chuyển sang chế độ phụ huynh"; mở lại App giữ chế độ cuối.
- **AC-9** (AUTH-18, ADR-0026): Given phụ huynh nhận SMS mã kích hoạt, When nhập SĐT, mã 6 số, mật khẩu mới 2 lần ở "Kích hoạt tài khoản", Then App mở trang Keycloak có sẵn tên đăng nhập BE trả. Mã sai hoặc hết hạn (400 / 1006) ⇒ "Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã."
- **AC-10** (quyết định 5): Màn Đăng nhập thật (`USE_MOCK=false`) không có lối vào "Quên mật khẩu".
- **AC-11:** `USE_MOCK=true` (mặc định) ⇒ App chạy như `dev` hiện tại (Đăng nhập giả + Xem thử theo vai trò), trừ hộp xác nhận đăng xuất thêm ở Task 9. `USE_MOCK=false` mà thiếu `API_BASE_URL` hoặc `OIDC_ISSUER` ⇒ màn lỗi cấu hình nêu tên biến thiếu.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Chọn giả/thật | `USE_MOCK` chọn implementation ở provider; không `if` trong màn | Nhánh riêng cho bản thật | Nối dần từng feature, `dev` luôn chạy được (CODING_GUIDE §4 bước 4) |
| Màn Đăng nhập | Màn mới `SignInScreen` cho bản thật; giữ `LoginScreen` giả cho `USE_MOCK=true` | Sửa `LoginScreen` cho cả hai | Không làm hỏng luồng xem thử (AC-11) |
| Chạy với BE local | `adb reverse tcp:8080 tcp:8080` và `tcp:8180 tcp:8180`; App dùng `http://localhost:...` | `10.0.2.2` | `iss` của token phải trùng issuer BE kiểm (`localhost:8180`); dùng `10.0.2.2` làm lệch `iss` ⇒ mọi API 401 |
| HTTP không mã hóa | Chỉ manifest debug (`usesCleartextTraffic`); release chỉ HTTPS | Mở cho mọi bản | Release không gửi token qua HTTP |
| Làm mới token | Chủ động (token còn < 30 giây thì refresh trước khi gửi) + bị động (401 ⇒ refresh 1 lần, gửi lại 1 lần, trừ body `FormData`) | Chỉ bị động | Token 5 phút; 401 của Resource Server xảy ra trước controller nên gửi lại body JSON an toàn |
| Đăng xuất | POST `{issuer}/protocol/openid-connect/logout` với `client_id` + `refresh_token`, không mở trình duyệt; mỗi lần đăng nhập gửi `prompt=login` | `endSession` qua trình duyệt | Không bật trình duyệt khi đăng xuất; `prompt=login` chặn tự đăng nhập lại bằng cookie Keycloak còn trong Custom Tabs |
| Lưu chế độ cuối | `flutter_secure_storage`, khóa theo `userId`, giữ sau đăng xuất | `shared_preferences` | Không thêm gói ngoài danh sách duyệt; chế độ không nhạy cảm |
| Backup Android | `android:allowBackup="false"` | Giữ mặc định | Khóa Keystore không theo backup ⇒ dữ liệu secure storage khôi phục sang máy mới bị hỏng |
| File `*.g.dart` | Commit; thêm `**/*.g.dart` vào `analyzer.exclude` | Sinh khi CI chạy | `verify.mjs` chạy analyze/test, không chạy build_runner |
| Làm mới `/accounts/me` | Khi App quay lại foreground (tối đa 1 lần/60 giây) | Chỉ lúc mở App | BE đổi quyền/khóa tài khoản có hiệu lực ngay (`AUTH_CONTRACT`: gọi lại `/accounts/me`) |

## Bản tác động (vùng dùng chung — điểm dừng 2)
```text
Thay đổi: thêm lib/core/{errors,network,storage}/, lib/bootstrap.dart; sửa lib/core/config/env.dart,
  lib/app.dart, lib/main.dart, lib/routing/app_router.dart, route_paths.dart (thêm /splash, /activate, /blocked)
Ảnh hưởng (impact.mjs 16/11): app_router.dart — chỉ lib/app.dart dùng, lan 0 file giao diện;
  app.dart — chỉ lib/main.dart; env.dart — chưa file nào dùng. Ownership chưa khai.
Luồng người dùng: USE_MOCK=true không đổi. USE_MOCK=false: mở App ⇒ màn chờ ⇒ Đăng nhập (Keycloak)
  hoặc màn chính theo chế độ; không có "Quên mật khẩu".
Module của: chưa khai ownership; Phase 1 không sửa màn đơn nghỉ (G94-284/G94-331 chờ Cần).
Phương án: A (đề xuất) giữ màn giả sau USE_MOCK, gắn auth ở router · B thay toàn bộ màn giả cùng lúc
  (PR rất lớn, rủi ro cao) · C nhánh bản thật riêng (lệch dev lâu).
Cách kiểm: test redirect (Task 8), test controller (Task 7), chạy emulator theo checklist Task 10.
```

## Lộ trình
Phase 1 có task chi tiết dưới. Mỗi phase sau có plan con riêng ở `docs/plans/active/`, lập khi bắt đầu: đọc controller + DTO BE của từng màn, ghi khoảng trống contract. Phase 2–5 làm lần lượt. Phase bị chặn làm khi phần BE tương ứng đã vào `dev`.

| Phase | Nội dung | API BE `dev` (kiểm quyền + DTO ở plan con) | Phụ thuộc / chặn |
| --- | --- | --- | --- |
| 0 | Chuẩn bị (Task 0) | — | Plan được duyệt |
| 1 | Nền App | Keycloak, `GET /accounts/me`, `POST /parent-activation` | Phase 0 |
| 2 | Thông báo, mọi vai trò | `GET /me/notifications`, `POST /me/notifications/{id}/read`, `POST /me/notifications/read-all` | Phase 1 |
| 3 | Giáo viên | `GET /attendance/classes`, `GET /attendance/day-info`, `GET\|PUT /classes/{classId}/attendance`, `POST /daily-health-entries`, `GET /classes/{classId}/children/{childId}/daily-health`, `GET /leave-requests`, `GET /classes/{classId}/daily-assessment`, `PUT .../general`, `PUT .../skills`, `GET /pickups/classes`, `GET\|POST /pickups`, `GET /children/{childId}/guardian-photos/{guardianId}/url`, `GET /health-checks`, `GET /health-checks/{campaignId}/classes/{classId}/children`, `POST\|PUT /children/{childId}/health/measurements` | Phase 1 |
| 4 | Phụ huynh | `GET /children/{childId}`, `GET /children/{childId}/photo/url`, `POST /leave-requests`, `GET /leave-requests/me`, `PATCH /leave-requests/{id}/cancel`, `GET /children/{childId}/health/published`, `GET /children/{childId}/weekly-comments`, `GET /pickups/children/{childId}`, `GET /children/{childId}/daily-health`, `PUT /accounts/me/photo`. Thực đơn, ảnh bữa, hoạt động: kiểm quyền phụ huynh, thiếu ⇒ đề xuất BE | Phase 1; ảnh tài khoản cần `image_picker` (hỏi) |
| 5 | Bếp | `GET /nutrition/kitchen/day`, `GET /meal-counts`, `GET /nutrition/day-board`, `GET\|POST /nutrition/food-samples`, `GET\|POST /nutrition/meal-photos` (multipart) | Phase 1; chụp ảnh cần `image_picker` (hỏi) |
| 6 | Quên mật khẩu SMS | API SMS ở nhánh BE G94-87 | Chặn: BE G94-87 vào `dev` |
| 7 | Push FCM | `PUT\|DELETE /me/devices` | Chặn: BE gửi FCM thật; project Firebase; `applicationId` thật (hiện `com.example.carenest_app`) |
| 8 | BGH chỉ xem | GET của nhánh BE TBD-1 | Chặn: nhánh BE TBD-1 vào `dev` |
| 9 | Bản release Android | — | `applicationId`, khóa ký (không commit), build release, chạy máy thật |

Phase 3–5: màn theo contract BE `dev`. Phần BE đã làm theo quyết định 14/11 (khóa ngày nghỉ `NOT_SCHOOL_DAY`, hủy phần còn lại của đơn `cancelFrom`, form sức khỏe đầu ngày như Web) đi vào màn khi nối API, vì BE là nguồn (AGENTS nguyên tắc 1).

## Phase 1 — Nền App
3 lần review: **1a** = Task 0–4 (chuẩn bị, cấu hình, lỗi, client, storage) · **1b** = Task 5–6 (Keycloak, phiên) · **1c** = Task 7–10 (tài khoản, router, kích hoạt, docs + chạy thật). Dừng chờ review sau mỗi phần.

### File structure
- C `lib/bootstrap.dart` — kiểm cấu hình, tạo `ProviderScope`.
- M `lib/main.dart`, `lib/app.dart` — chạy qua bootstrap; router lấy từ provider khi `USE_MOCK=false`.
- M `lib/core/config/env.dart` — biến OIDC, kiểm thiếu cấu hình.
- C `lib/core/errors/app_failure.dart` — lỗi chuẩn hóa.
- C `lib/core/network/api_envelope.dart`, `api_error_mapper.dart`, `dio_client.dart`, `auth_interceptor.dart`, `safe_log_interceptor.dart`, `api_client.dart`.
- C `lib/core/storage/secure_store.dart`, `token_storage.dart`.
- C `lib/features/auth/data/datasources/oidc_client.dart`, `app_auth_oidc_client.dart`, `account_remote_data_source.dart`, `activation_remote_data_source.dart`.
- C `lib/features/auth/data/models/me_dto.dart` (+ `me_dto.g.dart`), `lib/features/auth/data/session_manager.dart`.
- C `lib/features/auth/domain/entities/app_user.dart`, `app_mode.dart`.
- C `lib/features/auth/presentation/controllers/auth_state.dart`, `auth_controller.dart`; `presentation/providers/auth_providers.dart`.
- C `lib/features/auth/presentation/screens/sign_in_screen.dart`, `session_loading_screen.dart`, `blocked_screen.dart`, `activation_screen.dart`, `config_error_screen.dart`.
- C `lib/routing/route_access_policy.dart`; M `lib/routing/app_router.dart`, `route_paths.dart`.
- M `lib/features/account/presentation/screens/account_screen.dart` — Đăng xuất, chuyển chế độ.
- M `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore`; C `env/local.example.json`.
- M `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/debug/AndroidManifest.xml`, `ios/Runner/Info.plist`.
- Test: C `test/helpers/fake_http_adapter.dart`, `test/helpers/fake_oidc_client.dart`, `test/core/config/env_test.dart`, `test/core/network/{api_envelope,api_error_mapper,api_client,auth_interceptor,safe_log_interceptor}_test.dart`, `test/core/storage/token_storage_test.dart`, `test/features/auth/**`, `test/routing/route_access_policy_test.dart`, `test/routing/app_router_auth_test.dart`.
- Docs (Task 10): M `AGENTS.md` (mục Stack), `docs/integration/AUTH_FLOW.md`, `BACKEND_INTEGRATION.md`, `docs/architecture/{MOBILE_ARCHITECTURE,STATE_MANAGEMENT,CODING_GUIDE,NAVIGATION}.md`, `.claude/rules/{api-client,state,security-storage}.md` (dòng "chưa chọn"), `docs/context/CURRENT_STATE.md`, `docs/quality/VERIFICATION.md`, `docs/integration/BE_API_INDEX.md` (sinh lại).

### Task 0: Chuẩn bị môi trường (không có test)
- [ ] **Step 1:** Trả `pubspec.lock` về bản commit: chạy `flutter pub get` bằng Flutter 3.47.6. Expected: `git diff --quiet pubspec.lock` exit 0. (16/11 IDE dùng 3.44.0 đã sửa lock; đổi `dart.flutterSdkPath` của IDE sang `D:\Flutter_Setup\stable-3.47.6\flutter` trước.)
- [ ] **Step 2:** User cho phép ⇒ tạo nhánh `feature/TBD-4-FE-FEAT-0-app-foundation` từ `origin/dev` (quyết định 11); sửa `branch:` của plan theo nhánh này.
- [ ] **Step 3:** `node scripts/ai-layer/api-index.mjs`. Expected: `docs/integration/BE_API_INDEX.md` có `GET /accounts/me` và `POST /parent-activation`.
- [ ] **Step 4:** Đưa worktree chạy BE `D:\project_capstone\CareNest_BE-devdb` lên `origin/dev` mới nhất (`git fetch` + `git checkout --detach origin/dev`; worktree chỉ để chạy, không sửa code). User chạy `D:\project_capstone\run-be-dev.ps1` trong terminal của mình (Keycloak 8180 + BE 8080, DB local có seed). Kiểm `curl http://localhost:8180/realms/carenest/.well-known/openid-configuration` ⇒ 200, `issuer` = `http://localhost:8180/realms/carenest`. Kiểm redirect URI của client `carenest-mobile` là `carenest://oauth/callback`.
- [ ] **Step 5:** Emulator `Pixel_8_Pro`: `adb reverse tcp:8080 tcp:8080` và `adb reverse tcp:8180 tcp:8180`.
- [ ] **Step 6:** Chọn tài khoản seed cho checklist Task 10: GV, bếp, phụ huynh, GV kiêm phụ huynh, BGH (từ `BE:docker/keycloak/dev/carenest-users-0.json`). Không ghi mật khẩu vào repo App.

### Task 1: Dependency và cấu hình
**Files:** M `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore`, `lib/core/config/env.dart`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/debug/AndroidManifest.xml`, `ios/Runner/Info.plist` · C `env/local.example.json` · Test `test/core/config/env_test.dart`

**Interfaces:**
- Produces: `Env.oidcIssuer` (`OIDC_ISSUER`, không mặc định), `Env.oidcClientId` (`OIDC_CLIENT_ID`, mặc định `carenest-mobile`), `Env.oidcRedirectUri` (`OIDC_REDIRECT_URI`, mặc định `carenest://oauth/callback`); giữ `Env.apiBaseUrl` (đã gồm `/api`), `Env.useMock`, `Env.appEnv`. `static List<String> Env.missingKeys({required bool useMock, required String apiBaseUrl, required String oidcIssuer})`.

- [ ] **Step 1:** `flutter pub add flutter_riverpod dio json_annotation flutter_appauth flutter_secure_storage` và `flutter pub add --dev json_serializable build_runner`. Expected: `flutter pub get --enforce-lockfile` exit 0. Ghi version vào Progress log.
- [ ] **Step 2:** Viết test:
  ```dart
  test('missingKeys_mock_needsNothing', () => expect(Env.missingKeys(useMock: true, apiBaseUrl: '', oidcIssuer: ''), isEmpty));
  test('missingKeys_real_listsMissing', () => expect(Env.missingKeys(useMock: false, apiBaseUrl: '', oidcIssuer: ''), ['API_BASE_URL', 'OIDC_ISSUER']));
  test('missingKeys_real_complete', () => expect(Env.missingKeys(useMock: false, apiBaseUrl: 'http://localhost:8080/api', oidcIssuer: 'http://localhost:8180/realms/carenest'), isEmpty));
  ```
- [ ] **Step 3:** `flutter test test/core/config/env_test.dart`. Expected: FAIL (chưa có `missingKeys`).
- [ ] **Step 4:** Thêm biến và `missingKeys` vào `env.dart`.
- [ ] **Step 5:** Chạy lại test. Expected: PASS.
- [ ] **Step 6:** Android: `manifestPlaceholders["appAuthRedirectScheme"] = "carenest"` trong `defaultConfig`. Manifest main: `<uses-permission android:name="android.permission.INTERNET"/>`, `android:allowBackup="false"` trên `<application>`. Manifest debug: `<application android:usesCleartextTraffic="true"/>`. iOS `Info.plist`: `CFBundleURLTypes` với scheme `carenest` (chưa kiểm trên iOS — máy Windows không build iOS). Build lỗi vì `minSdk` thấp hơn mức gói yêu cầu ⇒ đặt `minSdk` đúng số gói báo.
- [ ] **Step 7:** `env/local.example.json`: `{"USE_MOCK": false, "APP_ENV": "development", "API_BASE_URL": "http://localhost:8080/api", "OIDC_ISSUER": "http://localhost:8180/realms/carenest"}`. `.gitignore`: `env/*.json`, `!env/*.example.json`. `analysis_options.yaml`: thêm `**/*.g.dart` vào `analyzer.exclude` đang có.
- [ ] **Step 8:** `node scripts/verify.mjs` ⇒ `VERIFY PASS full`; `flutter build apk --debug` ⇒ `√ Built`.
- [ ] **Step 9:** Commit (khi user cho phép): `<mã-jira>: Add networking, auth and storage dependencies`.

### Task 2: Lỗi chuẩn hóa và envelope
**Files:** C `lib/core/errors/app_failure.dart`, `lib/core/network/api_envelope.dart`, `lib/core/network/api_error_mapper.dart` · Test `test/core/network/api_envelope_test.dart`, `api_error_mapper_test.dart`

**Interfaces:**
- Produces:
  ```dart
  sealed class AppFailure implements Exception { int? get status; int? get errorCode; String? get message; } // message = desc của BE
  // 400 ValidationFailure(fieldErrors) · 401 UnauthenticatedFailure · 403 ForbiddenFailure · 404 NotFoundFailure
  // 409 ConflictFailure · 502/503/504 ServiceUnavailableFailure · 4xx/5xx khác ServerFailure
  // NetworkFailure · TimeoutFailure · CancelledFailure · ContractFailure (không phải envelope, hoặc code ≠ status)
  class FieldError { final String field; final String message; }
  abstract final class ApiErrorCodes { // AUTH_CONTRACT, ERROR_CONTRACT
    static const unauthenticated = 1002, otpInvalidOrExpired = 1006, passwordPolicyViolation = 1009,
      authServiceUnavailable = 1013, accountNotProvisioned = 1014, accountInactive = 1015,
      forbidden = 1101, invalidRequestData = 9001, malformedRequest = 9002;
  }
  Object? unwrapEnvelope(Object? body, int httpStatus); // trả data; sai envelope ⇒ throw ContractFailure
  AppFailure mapDioException(DioException e);
  ```
- [ ] **Step 1:** Viết test (thân envelope dùng dữ liệu giả):
  - `unwrapEnvelope_success_returnsData`: `{'code':200,'errorCode':null,'desc':'ok','data':{'a':1}}`, 200 ⇒ `{'a':1}`.
  - `unwrapEnvelope_codeMismatch_throwsContract`: `code` 201, status 200 ⇒ `ContractFailure`.
  - `unwrapEnvelope_notMap_throwsContract`: body `'<html>'` ⇒ `ContractFailure`.
  - `map400_withFieldErrors`: 400, `{'code':400,'errorCode':9001,'desc':'Dữ liệu không hợp lệ','data':[{'field':'phone','message':'Sai'}]}` ⇒ `ValidationFailure`, `fieldErrors.single.field == 'phone'`, `errorCode == 9001`, `message == 'Dữ liệu không hợp lệ'`.
  - `map403_keepsErrorCode`: 403, `errorCode` 1015 ⇒ `ForbiddenFailure`, `errorCode == 1015`.
  - `map503_htmlBody_isServiceUnavailable`: 503, body HTML ⇒ `ServiceUnavailableFailure`, `status == 503`, `errorCode == null`.
  - `map401`, `map404`, `map409`, `map500` ⇒ đúng lớp theo bảng trên.
  - `mapConnectionError_isNetwork`, `mapReceiveTimeout_isTimeout`, `mapCancel_isCancelled`.
- [ ] **Step 2:** Chạy test. Expected: FAIL (chưa có lớp).
- [ ] **Step 3:** Viết 3 file theo Interfaces.
- [ ] **Step 4:** Chạy test. Expected: PASS.
- [ ] **Step 5:** Commit: `<mã-jira>: Add API envelope parsing and error mapping`.

### Task 3: Dio client, interceptor, `ApiClient`
**Files:** C `lib/core/network/dio_client.dart`, `auth_interceptor.dart`, `safe_log_interceptor.dart`, `api_client.dart`, `test/helpers/fake_http_adapter.dart` · Test `test/core/network/api_client_test.dart`, `auth_interceptor_test.dart`, `safe_log_interceptor_test.dart`

**Interfaces:**
- Consumes: `unwrapEnvelope`, `mapDioException`, `AppFailure` (Task 2).
- Produces:
  ```dart
  abstract interface class AccessTokenSource {
    Future<String?> validAccessToken();      // null = chưa đăng nhập
    Future<bool> refreshAfterUnauthorized(); // true = đã có token mới
  }
  Dio createApiDio({required String baseUrl, required AccessTokenSource tokens, HttpClientAdapter? adapter, void Function(String line)? logSink});
  // timeout: connect 10 s, receive 20 s, send 30 s; header Accept: application/json
  class ApiClient {
    ApiClient(Dio dio);
    Future<T> get<T>(String path, {Map<String, Object?>? query, required T Function(Object? data) decode, CancelToken? cancelToken});
    Future<T> post<T>(String path, {Object? body, required T Function(Object? data) decode, CancelToken? cancelToken, bool skipAuth = false});
    Future<T> put<T>(String path, {Object? body, required T Function(Object? data) decode, CancelToken? cancelToken});
    Future<T> patch<T>(String path, {Object? body, required T Function(Object? data) decode, CancelToken? cancelToken});
    Future<T> delete<T>(String path, {required T Function(Object? data) decode, CancelToken? cancelToken});
  } // lỗi ⇒ throw AppFailure
  ```
  `AuthInterceptor`: Bearer chỉ khi host trùng host của `baseUrl` và không có `extra['skipAuth']`. 401 + chưa có `extra['authRetried']` + body không phải `FormData` ⇒ `refreshAfterUnauthorized()`; `true` ⇒ gửi lại 1 lần với `extra['authRetried'] = true`. `SafeLogInterceptor`: chỉ chạy khi `kDebugMode`; mỗi request một dòng `METHOD path status ms`; không header, body, query.
- [ ] **Step 1:** Viết test:
  - `get_addsBearerForApiHost`: header `authorization == 'Bearer t1'`.
  - `request_toOtherHost_hasNoBearer`: URL tuyệt đối `https://other.example/x` ⇒ không có `authorization`.
  - `on401_refreshesOnceThenRetries`: adapter trả 401 rồi 200; `refreshAfterUnauthorized` trả `true`, token thành `t2` ⇒ request 2 mang `Bearer t2`, refresh gọi 1 lần, kết quả decode đúng.
  - `on401_refreshFails_throwsUnauthenticated`: refresh `false` ⇒ `UnauthenticatedFailure`, adapter gọi 1 lần.
  - `on401_twice_noLoop`: 401, refresh `true`, 401 ⇒ `UnauthenticatedFailure`, refresh gọi 1 lần.
  - `on401_formData_notRetried`: body `FormData` ⇒ `UnauthenticatedFailure`, refresh gọi 0 lần.
  - `post_400_throwsValidation`.
  - `log_hasNoTokenOrBody`: dòng log chứa `GET /accounts/me 200`, không chứa `Bearer`, không chứa body.
- [ ] **Step 2:** Chạy test. Expected: FAIL.
- [ ] **Step 3:** Viết 4 file + `FakeHttpAdapter` (xếp sẵn danh sách response, ghi lại request đã nhận).
- [ ] **Step 4:** Chạy test. Expected: PASS.
- [ ] **Step 5:** Commit: `<mã-jira>: Add shared API client with token refresh`.

### Task 4: Secure storage
**Files:** C `lib/core/storage/secure_store.dart`, `token_storage.dart` · Test `test/core/storage/token_storage_test.dart`

**Interfaces:**
- Produces:
  ```dart
  abstract interface class SecureStore { Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key); }
  class FlutterSecureStore implements SecureStore { const FlutterSecureStore(); } // const FlutterSecureStorage(), tùy chọn mặc định của gói
  class MemorySecureStore implements SecureStore {}
  class StoredTokens { final String refreshToken; final String? idToken; }
  class TokenStorage { // khóa carenest.<env>.refresh_token, carenest.<env>.id_token
    TokenStorage(SecureStore store, {required String env});
    Future<StoredTokens?> read(); // đọc lỗi ⇒ xóa 2 khóa, trả null
    Future<void> write(StoredTokens tokens);
    Future<void> clear();
  }
  class LastModeStore { // khóa carenest.<env>.last_mode.<userId>
    LastModeStore(SecureStore store, {required String env});
    Future<String?> read(int userId);
    Future<void> write(int userId, String mode);
  }
  ```
- [ ] **Step 1:** Viết test: `write_thenRead_roundTrip`; `clear_removesBothKeys`; `keys_includeEnv` (env `development` ⇒ có khóa `carenest.development.refresh_token`); `read_platformError_returnsNullAndClears` (store ném `PlatformException` khi đọc ⇒ `null`, `delete` được gọi cho cả 2 khóa); `lastMode_perUser` (user 1 `parent`, user 2 chưa có ⇒ `null`).
- [ ] **Step 2:** Chạy test. Expected: FAIL.
- [ ] **Step 3:** Viết 2 file.
- [ ] **Step 4:** Chạy test. Expected: PASS. `node scripts/verify.mjs` ⇒ `VERIFY PASS full`.
- [ ] **Step 5:** Commit: `<mã-jira>: Add secure token storage`. Ghi Progress log **1a**. **Dừng chờ user review.**

### Task 5: Keycloak PKCE client
**Files:** C `lib/features/auth/data/datasources/oidc_client.dart`, `app_auth_oidc_client.dart`, `test/helpers/fake_oidc_client.dart` · Test `test/features/auth/data/app_auth_oidc_client_test.dart`

**Interfaces:**
- Produces:
  ```dart
  const kOidcScopes = ['openid', 'profile']; // phiên thường (quyết định 9); đổi sang offline_access ⇒ thêm 'offline_access' + task BE
  class OidcTokens { final String accessToken; final DateTime accessTokenExpiresAt; final String refreshToken; final String? idToken; }
  sealed class OidcFailure implements Exception {} // OidcCancelled · OidcInvalidGrant · OidcUnavailable(Object cause)
  abstract interface class OidcClient {
    Future<OidcTokens> signIn({String? loginHint});
    Future<OidcTokens> refresh(String refreshToken);
    Future<void> revoke(String refreshToken);
  }
  class AppAuthOidcClient implements OidcClient {
    AppAuthOidcClient({required FlutterAppAuth appAuth, required Dio plainDio, required String issuer, required String clientId, required String redirectUri});
  }
  OidcFailure mapAppAuthError(Object error);
  // FlutterAppAuthUserCancelledException ⇒ OidcCancelled; FlutterAppAuthPlatformException có 'invalid_grant' ⇒ OidcInvalidGrant; còn lại ⇒ OidcUnavailable
  ```
  `signIn`: `authorizeAndExchangeCode(AuthorizationTokenRequest(clientId, redirectUri, issuer: issuer, scopes: kOidcScopes, promptValues: ['login'], loginHint: loginHint, ...))`; khi issuer là `http://` và `kDebugMode` thì bật tham số cho phép HTTP của gói (tên theo API docs bản đã cài). `refresh`: `appAuth.token(TokenRequest(..., refreshToken: ..., scopes: kOidcScopes))`. `revoke`: `plainDio` POST form `{issuer}/protocol/openid-connect/logout` với `client_id`, `refresh_token`; lỗi ⇒ ném `OidcUnavailable` (bên gọi bỏ qua).
- [ ] **Step 1:** Viết test với `RecordingAppAuth implements FlutterAppAuth` (ghi request, trả kết quả/ném lỗi theo cấu hình):
  - `signIn_requestsPromptLoginAndPkceClient`: `promptValues == ['login']`, `clientId == 'carenest-mobile'`, `redirectUrl == 'carenest://oauth/callback'`, `scopes == kOidcScopes`.
  - `signIn_userCancelled_throwsOidcCancelled`.
  - `refresh_invalidGrant_throwsOidcInvalidGrant` (dựng `FlutterAppAuthPlatformException` theo constructor của bản đã cài).
  - `signIn_missingRefreshToken_throwsUnavailable` (kết quả thiếu refresh token).
  - `revoke_postsFormToLogoutEndpoint`: path `/realms/carenest/protocol/openid-connect/logout`, body có `client_id=carenest-mobile` và `refresh_token=r1`, content-type form.
- [ ] **Step 2:** Chạy test. Expected: FAIL.
- [ ] **Step 3:** Viết 2 file + `FakeOidcClient` (đếm số lần gọi, trả token theo hàng đợi, ném lỗi theo cấu hình).
- [ ] **Step 4:** Chạy test. Expected: PASS.
- [ ] **Step 5:** Commit: `<mã-jira>: Add Keycloak PKCE client`.

### Task 6: `SessionManager`
**Files:** C `lib/features/auth/data/session_manager.dart` · Test `test/features/auth/data/session_manager_test.dart`

**Interfaces:**
- Consumes: `OidcClient`, `OidcTokens`, `OidcFailure` (Task 5); `TokenStorage` (Task 4); `AccessTokenSource` (Task 3).
- Produces:
  ```dart
  enum RestoreResult { restored, noSession, ended } // ended = refresh token bị từ chối
  class SessionManager implements AccessTokenSource {
    SessionManager({required OidcClient oidc, required TokenStorage storage, DateTime Function()? now});
    Future<void> signIn({String? loginHint}); // ném OidcFailure
    Future<RestoreResult> restore();          // mạng/Keycloak lỗi ⇒ ném OidcUnavailable, giữ token
    Future<void> signOut();                   // revoke (bỏ qua lỗi), xóa storage, bỏ access token
    Stream<void> get sessionEnded;            // phát khi refresh gặp OidcInvalidGrant lúc đang dùng
  }
  ```
  Một `Future` refresh dùng chung cho mọi bên gọi (single-flight). Mỗi `signIn`/`signOut` tăng số thế hệ; kết quả refresh thuộc thế hệ cũ bị bỏ (trả `false`, không ghi storage). Token mới sau refresh ghi storage trước khi trả `true`.
- [ ] **Step 1:** Viết test (đồng hồ giả, `FakeOidcClient`, `MemorySecureStore`):
  - `signIn_storesRefreshAndIdToken`.
  - `restore_noStoredTokens_returnsNoSession` (không gọi `oidc.refresh`).
  - `restore_validRefresh_restoredAndRotates` (storage `r1`, refresh trả `r2` ⇒ storage `r2`, `validAccessToken()` trả token mới).
  - `restore_expiredRefresh_signsOut` (`OidcInvalidGrant` ⇒ `ended`, storage rỗng).
  - `restore_networkError_keepsTokens` (`OidcUnavailable` ⇒ ném lại, storage vẫn `r1`).
  - `validAccessToken_nearExpiry_refreshesFirst` (còn 10 giây ⇒ refresh 1 lần).
  - `refresh_concurrentCalls_singleFlight` (3 lời gọi `refreshAfterUnauthorized()` song song ⇒ `oidc.refresh` 1 lần, cả 3 nhận `true`).
  - `refresh_invalidGrant_emitsSessionEnded`.
  - `signOut_duringRefresh_doesNotRestoreSession` (refresh xong sau `signOut` ⇒ storage rỗng, `validAccessToken()` trả `null`).
  - `signOut_revokeFails_stillClears`.
- [ ] **Step 2:** Chạy test. Expected: FAIL.
- [ ] **Step 3:** Viết `session_manager.dart`.
- [ ] **Step 4:** Chạy test. Expected: PASS. `node scripts/verify.mjs` ⇒ `VERIFY PASS full`.
- [ ] **Step 5:** Commit: `<mã-jira>: Add session manager with single refresh`. Ghi Progress log **1b**. **Dừng chờ user review.**

### Task 7: Tài khoản, chế độ, `AuthController`
**Files:** C `lib/features/auth/data/models/me_dto.dart` (+ `.g.dart`), `lib/features/auth/data/datasources/account_remote_data_source.dart`, `lib/features/auth/domain/entities/app_user.dart`, `app_mode.dart`, `lib/features/auth/presentation/controllers/auth_state.dart`, `auth_controller.dart`, `lib/features/auth/presentation/providers/auth_providers.dart`, `lib/bootstrap.dart`, `lib/features/auth/presentation/screens/config_error_screen.dart` · M `lib/main.dart`, `lib/app.dart` · Test `test/features/auth/data/me_dto_test.dart`, `test/features/auth/domain/app_user_test.dart`, `test/features/auth/presentation/auth_controller_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (Task 3), `LastModeStore` (Task 4), `SessionManager` (Task 6).
- Produces:
  ```dart
  @JsonSerializable() class MeDto { userId, username, fullName, email?, roles, permissions, schoolWidePermissions, assignments: List<AssignmentDto>, childIds: List<int>; AppUser toEntity(); }
  @JsonSerializable() class AssignmentDto { staffRole, campusId?, classroomId?, validFrom?, validTo?; }
  class AccountRemoteDataSource { AccountRemoteDataSource(ApiClient api); Future<AppUser> fetchMe(); } // GET /accounts/me
  enum AppMode { teacher, kitchen, parent; AppRole get shellRole; String get homePath; String get pathPrefix; }
  // homePath: /teacher, /kitchen, /parent (RoutePaths.teacherToday, kitchenHome, parentToday)
  class AppUser { userId, username, fullName, roles: Set<String>, permissions: Set<String>, assignments, childIds; List<AppMode> get modes; }
  // modes theo thứ tự: TEACHER ⇒ teacher; KITCHEN_STAFF ⇒ kitchen; PARENT và childIds không rỗng ⇒ parent
  sealed class AuthState {} // AuthChecking · AuthSignedOut({AuthNotice? notice}) · AuthSigningIn · AuthSignedIn(AppUser user, AppMode mode) · AuthBlocked(AuthBlockReason reason) · AuthRetryNeeded(AppFailure failure)
  enum AuthNotice { sessionExpired, signInCancelled, signInFailed }
  enum AuthBlockReason { webOnlyAccount, accountUnavailable }
  // /accounts/me trả 403 1101, hoặc không có role TEACHER/KITCHEN_STAFF/PARENT ⇒ webOnlyAccount
  // 403 1014/1015, hoặc có PARENT nhưng modes rỗng ⇒ accountUnavailable
  class AuthController extends Notifier<AuthState> {
    Future<void> start();                      // restore ⇒ fetchMe ⇒ chọn chế độ
    Future<void> signIn({String? loginHint});
    Future<void> retry();
    Future<void> signOut({AuthNotice? notice});
    Future<void> switchMode(AppMode mode);     // chỉ chế độ có trong user.modes; ghi LastModeStore
    Future<void> onResumed();                  // signed in và đã quá 60 giây từ lần trước ⇒ fetchMe lại
  }
  // providers: secureStoreProvider, tokenStorageProvider, lastModeStoreProvider, oidcClientProvider,
  // sessionManagerProvider, apiClientProvider, accountRemoteDataSourceProvider, authControllerProvider
  Future<Widget> bootstrap(); // thiếu cấu hình ⇒ ConfigErrorApp(missingKeys); còn lại ⇒ ProviderScope(child: CareNestApp())
  ```
  Chế độ ban đầu: chế độ cuối đã lưu nếu còn trong `user.modes`, không thì `user.modes.first`. `sessionEnded` ⇒ `signOut(notice: AuthNotice.sessionExpired)`. Đăng xuất giữ `LastModeStore`, xóa state user.
- [ ] **Step 1:** Viết test:
  - `me_dto_test`: `fromJson_fullPayload` với payload dạng mẫu `AUTH_CONTRACT` (giá trị giả) ⇒ đủ field, `childIds == [7]`.
  - `app_user_test`: `modes_teacherAndParentWithChildren` ⇒ `[teacher, parent]`; `modes_parentWithoutChildren_empty`; `modes_principalOnly_empty`; `modes_kitchen` ⇒ `[kitchen]`.
  - `auth_controller_test` (ProviderContainer + override `FakeOidcClient`, `MemorySecureStore`, `FakeHttpAdapter`):
    - `start_noSession_signedOut`.
    - `start_restoredTeacher_signedInTeacher`.
    - `start_teacherParent_opensTeacher_thenRemembersParent` (switchMode(parent), container mới, `start()` ⇒ parent).
    - `start_principal403_1101_blockedWebOnly`.
    - `start_inactive1015_blockedUnavailable`.
    - `start_parentWithoutChildren_blockedUnavailable`.
    - `start_meServiceUnavailable_showsRetry` (503 ⇒ `AuthRetryNeeded`, storage còn token).
    - `signIn_cancelled_signedOutWithNotice` (⇒ `AuthSignedOut(notice: signInCancelled)`).
    - `signOut_clearsUserAndMode` (⇒ `AuthSignedOut`, storage token rỗng, `LastModeStore` vẫn còn).
    - `sessionEnded_signsOutWithExpiredNotice`.
    - `onResumed_inactiveAccount_blocks` (lần 2 `/accounts/me` trả 403 1015 ⇒ `AuthBlocked(accountUnavailable)`).
- [ ] **Step 2:** Chạy test. Expected: FAIL.
- [ ] **Step 3:** Viết file theo Interfaces; `dart run build_runner build --delete-conflicting-outputs` sinh `me_dto.g.dart`.
- [ ] **Step 4:** Chạy test. Expected: PASS.
- [ ] **Step 5:** Commit: `<mã-jira>: Add account loading and auth state`.

### Task 8: Chuyển màn theo phiên và chế độ
**Files:** C `lib/routing/route_access_policy.dart`, `lib/features/auth/presentation/screens/sign_in_screen.dart`, `session_loading_screen.dart`, `blocked_screen.dart` · M `lib/routing/app_router.dart`, `route_paths.dart` · Test `test/routing/route_access_policy_test.dart`, `test/routing/app_router_auth_test.dart`

**Interfaces:**
- Consumes: `AuthState`, `AppMode`, `authControllerProvider` (Task 7).
- Produces:
  ```dart
  // RoutePaths.splash = '/splash'; RoutePaths.activate = '/activate'; RoutePaths.blocked = '/blocked'
  String? redirectFor(AuthState state, String location);
  // AuthChecking, AuthRetryNeeded ⇒ /splash · AuthSignedOut, AuthSigningIn ⇒ /login (giữ nguyên nếu đang ở /login hoặc /activate)
  // AuthBlocked ⇒ /blocked · AuthSignedIn ⇒ null nếu location == mode.pathPrefix hoặc bắt đầu bằng '${mode.pathPrefix}/', còn lại ⇒ mode.homePath
  GoRouter buildAppRouter({bool enablePreview = kDebugMode, Listenable? refresh, AuthState Function()? readAuth});
  // readAuth == null (USE_MOCK=true) ⇒ hành vi như dev hiện tại; readAuth != null ⇒ initialLocation /splash, /login dùng SignInScreen,
  // chỉ đăng ký shell parent/teacher/kitchen, không đăng ký /preview, BGH, /forgot-password
  ```
  `SignInScreen`: logo, nút "Đăng nhập", dòng "Tên đăng nhập là số điện thoại 10 số, bắt đầu bằng 0.", liên kết "Kích hoạt tài khoản" ⇒ `/activate`, banner theo `AuthNotice` ("Phiên đăng nhập đã hết. Vui lòng đăng nhập lại." · "Bạn đã đóng trang đăng nhập." · "Không đăng nhập được. Thử lại sau."). `SessionLoadingScreen`: vòng tải; ở `AuthRetryNeeded` thêm "Không kết nối được máy chủ." + nút "Thử lại" (`retry()`). `BlockedScreen`: chữ theo AC-2/AC-3 + nút "Đăng xuất".
- [ ] **Step 1:** Viết test:
  - Policy: `checking_goesSplash`; `retryNeeded_goesSplash`; `signedOut_onTeacherRoute_goesLogin`; `signedOut_onActivate_stays`; `blocked_goesBlocked`; `signedInTeacher_onLogin_goesTeacherHome`; `signedInParent_onTeacherRoute_goesParentHome`; `signedInTeacher_onTeacherAttendance_stays` (`/teacher/attendance`).
  - Widget: `signOut_clearsBackStack` (đang ở màn con của `/teacher`, state ⇒ `AuthSignedOut` ⇒ location `/login`, `router.canPop() == false`); `signInScreen_hasNoForgotPassword` (không có chữ "Quên mật khẩu"); `retryScreen_retryButtonCallsRetry`.
- [ ] **Step 2:** Chạy test. Expected: FAIL.
- [ ] **Step 3:** Viết file theo Interfaces; `app.dart` truyền `refresh` (Listenable từ `authControllerProvider`) và `readAuth` khi `USE_MOCK=false`; gọi `start()` lúc khởi động, `onResumed()` khi `AppLifecycleState.resumed`.
- [ ] **Step 4:** Chạy test. Expected: PASS. Test router cũ trong `test/routing/` vẫn PASS (USE_MOCK=true không đổi).
- [ ] **Step 5:** Commit: `<mã-jira>: Gate routes by session and app mode`.

### Task 9: Kích hoạt tài khoản; Đăng xuất và chuyển chế độ ở Tài khoản
**Files:** C `lib/features/auth/data/datasources/activation_remote_data_source.dart`, `lib/features/auth/presentation/screens/activation_screen.dart` · M `lib/features/account/presentation/screens/account_screen.dart` · Test `test/features/auth/presentation/activation_screen_test.dart`, `test/features/account/account_screen_auth_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (`skipAuth: true`), `AuthController.signIn/signOut/switchMode`, `AuthSignedIn.user.modes` (Task 7).
- Produces: `class ActivationRemoteDataSource { ActivationRemoteDataSource(ApiClient api); Future<String> activate({required String phone, required String code, required String newPassword, required String confirmPassword}); }` — POST `/parent-activation`, trả `username`.
  Màn "Kích hoạt tài khoản": ô SĐT, Mã kích hoạt 6 số (`AppOtpField`), Mật khẩu mới, Nhập lại mật khẩu; ghi chú "Nhập mã 6 số trong tin nhắn nhà trường gửi."; nút "Kích hoạt" (khóa trong lúc gửi). Kiểm ở App chỉ để hỗ trợ nhập: SĐT 10 số bắt đầu bằng 0, mã 6 số, mật khẩu 8–128 ký tự, 2 lần nhập khớp — BE kiểm lại. Lỗi: 400/1006 ⇒ chữ AC-9; 400/1009 ⇒ hiện `desc`; 400/9001, 9002 ⇒ lỗi theo ô hoặc `desc`; `NetworkFailure` ⇒ "Không kết nối được. Thử lại." Thành công ⇒ `signIn(loginHint: username)`.
  Màn Tài khoản (khi `USE_MOCK=false`): họ tên + tên đăng nhập lấy từ `AppUser`; "Đăng xuất" ⇒ hộp xác nhận "Đăng xuất khỏi CareNest?" ⇒ `signOut()`; có > 1 chế độ ⇒ dòng "Chuyển sang chế độ phụ huynh" / "Chuyển sang chế độ giáo viên" ⇒ `switchMode`.
- [ ] **Step 1:** Viết test:
  - `activate_success_startsSignInWithUsername` (API giả trả `{'username':'0900000001'}` ⇒ controller giả nhận `loginHint == '0900000001'`).
  - `activate_1006_showsContactSchool`.
  - `activate_passwordMismatch_blocksSubmit` (không gửi request).
  - `activate_doubleTap_sendsOnce`.
  - `account_switchMode_onlyForMultiMode` (1 chế độ ⇒ không có dòng chuyển).
  - `account_logout_confirm_callsSignOut`.
- [ ] **Step 2:** Chạy test. Expected: FAIL.
- [ ] **Step 3:** Viết file theo Interfaces; đăng ký `/activate` trong router bản thật.
- [ ] **Step 4:** Chạy test. Expected: PASS.
- [ ] **Step 5:** Commit: `<mã-jira>: Add parent activation and sign-out`.

### Task 10: Docs, chạy thật, ghi kiểm chứng
**Files:** M `AGENTS.md` (mục Stack: thư viện CONFIRMED theo quyết định 1), `docs/integration/AUTH_FLOW.md` (viết lại theo BE `AUTH_CONTRACT`: PKCE, scope, phiên, 401/403/503, kích hoạt, đăng xuất, chế độ), `docs/integration/BACKEND_INTEGRATION.md` (`errorCode`, `desc` tiếng Việt, `ApiClient`), `docs/architecture/MOBILE_ARCHITECTURE.md`, `STATE_MANAGEMENT.md`, `CODING_GUIDE.md` §1.2 (biến OIDC, `--dart-define-from-file`) và §5 (PKCE thay `/mobile/auth/*`), `NAVIGATION.md` (chuyển màn theo phiên), `.claude/rules/{api-client,state,security-storage}.md` (bỏ dòng "chưa chọn"), `docs/context/CURRENT_STATE.md`, `docs/quality/VERIFICATION.md`, `docs/knowledge/TROUBLESHOOTING.md` (`adb reverse`, lệch `iss`).

- [ ] **Step 1:** Sửa docs. `node scripts/check-ai-layer.mjs` ⇒ 0 lỗi.
- [ ] **Step 2:** Chạy `flutter run --dart-define-from-file=env/local.json` trên emulator (BE local + `adb reverse`) và ghi kết quả từng dòng:
  1. GV ⇒ `/teacher` (AC-1). 2. Bếp ⇒ `/kitchen`. 3. Phụ huynh ⇒ `/parent`.
  4. GV kiêm phụ huynh ⇒ GV; chuyển phụ huynh; tắt hẳn App, mở lại ⇒ phụ huynh (AC-8, AC-4).
  5. BGH ⇒ màn "dùng trên Web" (AC-2).
  6. Khóa tài khoản phụ huynh trên Web ⇒ đưa App về foreground ⇒ màn liên hệ nhà trường (AC-3).
  7. Để App nền > 6 phút ⇒ quay lại ⇒ không lỗi (AC-5).
  8. Đăng xuất ⇒ Keycloak Admin › Users › Sessions không còn phiên `carenest-mobile`; đăng nhập lại ⇒ trang Keycloak hỏi mật khẩu (AC-7).
  9. Kích hoạt: lấy mã bằng "Gửi lại mã" trên Web (cổng SMS giả trả `activationCode`) ⇒ kích hoạt ⇒ trang Keycloak có sẵn tên đăng nhập (AC-9).
  10. Phiên thường (quyết định 9): để App không dùng > 30 phút ⇒ mở lại ⇒ về Đăng nhập với chữ "Phiên đăng nhập đã hết…" (AC-6).
- [ ] **Step 3:** `node scripts/verify.mjs` ⇒ `VERIFY PASS full | … | skip 0`; `flutter build apk --debug` ⇒ `√ Built`. Ghi `docs/quality/VERIFICATION.md` + Progress log **1c**.
- [ ] **Step 4:** Commit: `<mã-jira>: Document PKCE auth flow and API conventions`. **Dừng chờ user review.**

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | AUTH-21 | `start_restoredTeacher_signedInTeacher`, `signedInTeacher_onLogin_goesTeacherHome` (unit) · checklist 1–3 | 1c | — |
| AC-2 | ADR-0022 | `start_principal403_1101_blockedWebOnly`, `blocked_goesBlocked` · checklist 5 | 1c | — |
| AC-3 | AUTH_CONTRACT 1014/1015 | `start_inactive1015_blockedUnavailable`, `onResumed_inactiveAccount_blocks` · checklist 6 | 1c | — |
| AC-4 | — | `restore_validRefresh_restoredAndRotates` · checklist 4 | 1b, 1c | — |
| AC-5 | — | `validAccessToken_nearExpiry_refreshesFirst`, `on401_refreshesOnceThenRetries` · checklist 7 | 1a, 1b | — |
| AC-6 | — | `restore_expiredRefresh_signsOut`, `sessionEnded_signsOutWithExpiredNotice`, `signOut_clearsBackStack` · checklist 10 | 1b, 1c | — |
| AC-7 | CODING_GUIDE §5.6 | `signOut_revokeFails_stillClears`, `revoke_postsFormToLogoutEndpoint`, `account_logout_confirm_callsSignOut` · checklist 8 | 1b, 1c | — |
| AC-8 | ADR-0022 | `modes_teacherAndParentWithChildren`, `start_teacherParent_opensTeacher_thenRemembersParent`, `account_switchMode_onlyForMultiMode` · checklist 4 | 1c | — |
| AC-9 | AUTH-18, ADR-0026 | `activate_success_startsSignInWithUsername`, `activate_1006_showsContactSchool` · checklist 9 | 1c | — |
| AC-10 | Quyết định 5 | `signInScreen_hasNoForgotPassword` | 1c | — |
| AC-11 | — | `missingKeys_*`, test router cũ trong `test/routing/` | 1a, 1c | — |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| `iss` của token khác issuer BE kiểm | Mọi API 401 | `adb reverse`, App dùng `localhost`; ghi TROUBLESHOOTING | Không cần |
| Tên tham số `flutter_appauth`/`flutter_secure_storage` khác giữa các bản | Code không biên dịch | Đọc API docs bản đã cài; test giữ hành vi | Sửa theo bản đã cài |
| IDE dùng Flutter 3.44.0 sửa `pubspec.lock` | Verify không phản ánh lockfile | Đổi SDK của IDE; `--enforce-lockfile` trước verify | Chạy lại `flutter pub get` bằng 3.47.6 |
| Thành viên khác sửa `lib/routing` trên `dev` cùng lúc | Conflict | PR nhỏ theo 1a/1b/1c; merge `dev` trước mỗi PR | Revert commit của phần đó |
| Mã tạm `TBD-4` (quyết định 11) | Đổi mã sau phải viết lại lịch sử nhánh; quên đổi thì PR vào `dev` mang mã giả | Giữ 1 commit = 1 task, bảng commit → task ở Progress log; đổi mã trước khi mở PR | Nhánh chưa vào `dev` nên đổi được |
| Phiên thường (quyết định 9): không có request nào khoảng 30 phút, hoặc quá 10 giờ từ lúc đăng nhập | Phải đăng nhập lại; form đang nhập bị mất | Banner "Phiên đăng nhập đã hết…"; user báo đổi ⇒ thêm `offline_access` (1 hằng số `kOidcScopes` + task BE) | — |
| Sau này đổi sang `offline_access`: thu hồi qua `logout` có thể không xóa phiên offline | Token cũ còn dùng được | Lúc đổi, chạy lại checklist 8 trên Keycloak Admin; sai ⇒ dùng endpoint `revoke` | — |

Rollback chung: `USE_MOCK=true` (mặc định) giữ hành vi `dev` hiện tại; revert commit theo phần 1a/1b/1c.

## Validation log
- [x] Khẳng định về code có `file:line` (Context; BE contract có đường dẫn)
- [x] Đổi contract ⇒ consumer cụ thể: Phase 1 không đổi contract BE (phiên thường, quyết định 9)
- [x] Mỗi AC có test; mỗi phần review có Exit = lệnh + kết quả mong đợi
- [x] >8 file hoặc >3 phase ⇒ đã tách: Phase 1 review 3 lần (1a/1b/1c); Phase 2–9 có plan con riêng
- [x] Không dùng rule PENDING/OPEN như đã chốt (HLT-07 CONFIRMED/PENDING chỉ dùng ở Phase 3, kiểm lại ở plan con)
- [x] Tự review: không placeholder ngoài mã Jira tạm `TBD-4` (quyết định 11) · không mâu thuẫn · không câu mơ hồ

## Progress log
### 2026-11-16 — Plan draft (chờ user duyệt)
- Commit: chưa commit
- Verify: chưa chạy (chỉ thêm file plan); `node scripts/check-ai-layer.mjs` chạy sau khi viết
- Q1–Q4 xong (user 16/11): phiên thường (quyết định 9), mã tạm `TBD-4` (quyết định 11), BE local (quyết định 12), duyệt `json_annotation` + `build_runner` (quyết định 10).
- Bảng commit → task (điền khi commit; dùng để đổi sang mã Jira thật): chưa có commit.
- Tiếp: user duyệt plan và chọn cách làm (Native / Subagent-driven) ⇒ `status: approved`, làm Task 0.

### 2026-11-16 — Plan được duyệt (user), bắt đầu Phase 1a
- User: duyệt plan, chọn Native, cho tạo nhánh `feature/TBD-4-FE-FEAT-0-app-foundation`, commit nhỏ theo từng phần.
- Nhánh tạo từ `origin/dev` `a811d3d` (không track `origin/dev`).
- Task 0 Step 1: `pubspec.lock` trả về bản commit; `flutter pub get --enforce-lockfile` (3.47.6) exit 0. VS Code: workspace `D:\project_capstone\project\web\.vscode\settings.json` đặt `dart.flutterSdkPath` = `D:\Flutter_Setup\stable-3.47.6\flutter` (cài đặt user cũ trỏ tới thư mục không còn, nên extension dùng Flutter 3.44.0 trên PATH).

### 2026-11-16 — Phase 1a: Task 0–4 (chờ review)
- Verify: `node scripts/verify.mjs` (Flutter 3.47.6) → `VERIFY PASS full | format ok | design ok | analyze ok | tests 238 fail 0 skip 0`; `flutter pub get --enforce-lockfile` exit 0; `flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`; `node scripts/check-ai-layer.mjs` → 0 lỗi.
- Gói đã thêm: `flutter_riverpod` 3.5.0, `dio` 5.11.1, `flutter_appauth` 13.0.0, `flutter_secure_storage` 11.2.0, `json_annotation` 4.12.0; dev `json_serializable` 6.15.2, `build_runner` 2.17.1.
- Khác plan:
  - Commit nhỏ hơn 1 commit/task (user 16/11).
  - `AccessTokenSource` được ném `AppFailure` khi refresh không tới được Keycloak ⇒ App báo lỗi mạng, không đăng xuất nhầm (Review Focus 2). Task 6 phải đổi `OidcUnavailable` sang `NetworkFailure`.
  - Mapper giữ nguyên `AppFailure` mà interceptor bọc trong `DioException`.
  - Log che id số trong path thành `{id}`, path có tiền tố `/api`.
  - `LastModeStore` ở file riêng `lib/core/storage/last_mode_store.dart`.
  - Bảng `BE_API_INDEX.md` sinh từ worktree chạy BE `D:\project_capstone\CareNest_BE-devdb` (đưa lên `origin/dev` `f76e9092`); clone BE chính đang ở nhánh G94-329.
  - Task 0 Step 5–6 (`adb reverse`, tài khoản seed) dời tới trước Task 10.
- Bảng commit → task (đổi sang mã Jira thật trước PR):

| Commit | Task plan | Nội dung |
| --- | --- | --- |
| `1ad0f31` | Task 0 | Plan |
| `84b8f69` | Task 0 | Sinh lại `BE_API_INDEX.md` |
| `7d67fa8` | Task 1 | Cấu hình Android/iOS cho redirect PKCE |
| `8a880b5` | Task 1 | Thêm dependency |
| `04a7316` | Task 1 | Biến OIDC + `Env.missingKeys` |
| `35c04f6` | Task 1 | `env/local.example.json`, ignore `*.g.dart` |
| `95eef62` | Task 2 | `AppFailure` + `unwrapEnvelope` |
| `b4908a2` | Task 2 | `mapDioException` |
| `1bac206` | Task 3 | `ApiClient` + `FakeHttpAdapter` |
| `38038dc` | Task 3 | Mapper giữ lỗi của interceptor |
| `57a419f` | Task 3 | `AuthInterceptor` + `createApiDio` |
| `34c17fd` | Task 3 | `SafeLogInterceptor` |
| `2d7457c` | Task 4 | `TokenStorage` |
| `3662941` | Task 4 | `LastModeStore` |

- Tiếp: user review 1a ⇒ Phase 1b (Task 5–6).

### 2026-11-16 — Phase 1b: Task 5–6 (chờ review)
- Verify: `node scripts/verify.mjs` (Flutter 3.47.6) → `VERIFY PASS full | format ok | design ok | analyze ok | tests 264 fail 0 skip 0`.
- `AppAuthOidcClient` theo API `flutter_appauth` 13.0.0: `AuthorizationTokenRequest(... promptValues: ['login'], allowInsecureConnections: debug + issuer http)`, refresh qua `token(TokenRequest(refreshToken: ...))`, đăng xuất POST `{issuer}/protocol/openid-connect/logout`. `invalid_grant` ⇒ `OidcInvalidGrant`; đóng trang ⇒ `OidcCancelled`; lỗi khác ⇒ `OidcUnavailable`.
- `SessionManager`: refresh dùng chung một `Future`; kết quả của phiên cũ bị bỏ sau đăng xuất; lỗi mạng khi refresh lúc đang dùng ⇒ `NetworkFailure`, giữ token.
- Khác plan:
  - Response Keycloak thiếu access token, hạn hoặc refresh token ⇒ `OidcUnavailable`. Refresh không trả refresh token mới ⇒ giữ token cũ.
  - `restore()` gặp `invalid_grant` trả `RestoreResult.ended`, không phát `sessionEnded` (chỉ phát khi đang dùng App).
  - Đăng xuất xóa storage trước, rồi mới thu hồi ở Keycloak.
  - Tên biến cục bộ `access`/`refresh`: hook pre-commit coi `accessToken = …` là secret.
- Commit → task:

| Commit | Task plan | Nội dung |
| --- | --- | --- |
| `421eb0b` | Task 5 | `OidcClient` + `AppAuthOidcClient` |
| `cdf6c27` | Task 6 | `SessionManager` + `FakeOidcClient` |

- Tiếp: user review 1b ⇒ Phase 1c (Task 7–10).

### 2026-11-16 — Phase 1c: Task 7–9 + docs Task 10 (chờ chạy thật)
- Verify: `node scripts/verify.mjs` (Flutter 3.47.6) → `VERIFY PASS full | format ok | design ok | analyze ok | tests 338 fail 0 skip 0`; `node scripts/check-ai-layer.mjs` → 0 lỗi (1 cảnh báo E7 có sẵn).
- Chưa chạy: Task 10 Step 2 (emulator + BE local) — cần user bật Docker, `run-be-dev.ps1`, emulator. Seed BE local không có tài khoản GV kiêm phụ huynh ⇒ checklist 4 cần liên kết phụ huynh trên Web hoặc bỏ qua.
- Khác plan:
  - `AppMode` là enum thuần; ánh xạ màn chính/shell ở `lib/routing/route_access_policy.dart`.
  - `lib/core/network/api_providers.dart` giữ provider của API client; `authOverrides` ghép nguồn token với `SessionManager` (core không import feature).
  - Đã đăng nhập mà vào route ngoài chế độ (Xem thử, BGH) ⇒ về màn chính, không ra 404.
  - Hộp xác nhận đăng xuất áp cả bản giả; 2 test cũ sửa theo.
  - Kích hoạt xong ⇒ màn "Tài khoản đã kích hoạt" có nút Đăng nhập riêng (mã SMS dùng một lần).
  - Cổng thiết kế bắt tên token có chữ số (`AppSpacing.space6`) trong `EdgeInsets` ⇒ màn mới dùng `pagePadding`; logo bo góc bằng `ClipRRect`. Không sửa script cổng (harness).
  - Hook secret bắt tên field API `newPassword`/`confirmPassword` và mật khẩu giả trong test ⇒ đổi tên biến cục bộ, đánh dấu `carenest:allow-secret` ở dòng tên field và giá trị giả.
- Commit → task:

| Commit | Task plan | Nội dung |
| --- | --- | --- |
| `ec1babd` | Task 7 | `AppUser`, `AppMode`, `MeDto` |
| `cf7d85b` | Task 7 | `AccountRemoteDataSource` |
| `ccd5c67` | Task 7 | `AuthController`, provider |
| `ac770d5` | Task 7 | `bootstrap`, màn thiếu cấu hình |
| `4fa2255` | Task 8 | Luật chuyển màn |
| `892440b` | Task 8 | Màn Đăng nhập, Đang tải, Bị chặn |
| `71fdddb` | Task 8 | Router theo phiên |
| `6843ec6` | Task 8 | `app.dart`: `start()`, `onResumed()` |
| `48cda79` | Task 9 | API kích hoạt |
| `170490c` | Task 9 | Màn Kích hoạt tài khoản |
| `2f077be` | Task 9 | Tài khoản: xác nhận đăng xuất, chuyển chế độ |
| `fb03dba` | Task 9 | Router: kích hoạt, hồ sơ, chuyển chế độ |
| `3c0bf50` | Task 10 | `AUTH_FLOW.md` |
| `c935ef2` | Task 10 | `BACKEND_INTEGRATION.md`, rule api-client |
| `f3c50dc` | Task 10 | Stack CONFIRMED ở docs |
| `bb565e7` | Task 10 | `NAVIGATION.md`, `CURRENT_STATE.md` |

- Tiếp: user bật BE local + emulator ⇒ Task 10 Step 2 (checklist), ghi `docs/quality/VERIFICATION.md`.

### 2026-11-16 — Task 10 + review toàn nhánh (chờ user review)
- Task 10 Step 2 theo cách B (user chọn — máy không chạy nổi emulator): script kiểm contract BE `f76e9092` + Keycloak local trên PC, 30/30 PASS; `flutter build apk --debug --dart-define-from-file=env/local.example.json` → `√ Built`. Chi tiết: `docs/quality/VERIFICATION.md` mục 2026-11-16. Chạy trên điện thoại Android thật: chưa, cần trước khi merge.
- Review toàn nhánh (reviewer mới): "with fixes" — 0 Critical, 3 Important, 10 Minor. Đã sửa 3 Important + 4 Minor nâng mức theo tác động: lỗi khi quay lại App không còn đẩy về màn chờ; kết quả đến muộn sau đăng xuất bị bỏ; màn Thử lại nói đúng loại lỗi và có "Đăng xuất"; đăng xuất không chờ Keycloak; lỗi lạ không kẹt màn chờ; refresh chen lúc đăng xuất không làm token sống lại; "Thông tin cá nhân" hiện người đang đăng nhập.
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 353 fail 0 skip 0`.
- Để sau (Minor, user quyết): bấm Đăng nhập 2 lần sau kích hoạt; xóa con đang chọn ở mọi kiểu đăng xuất (cần khi Phase 4 có dữ liệu thật); 401 đến sau lần refresh vừa xong gây refresh thêm; `dataExtractionRules` cho chuyển máy; tách interface domain cho auth trước Phase 2; đưa script kiểm contract vào repo.
- Commit → task: `a2e5b48`, `003a393`, `7ff6366`, `9074e47`, `0cde30e` (sửa sau review, Task 5–9); `a25db3c` (Task 10, kiểm chứng).

### 2026-11-16 — Sửa Minor 1, 2, 6 (user chọn)
- Đăng nhập khi trang Keycloak đang mở ⇒ bỏ lượt mới (AppAuth Android từ chối 2 lượt cùng lúc); nút "Đăng nhập" ở thẻ "Tài khoản đã kích hoạt" hiện đang xử lý như màn Đăng nhập.
- Mọi đường về Đăng nhập (đăng xuất ở Tài khoản/màn chặn/màn Thử lại, hết phiên, 401) xóa con đang chọn, làm một chỗ ở `lib/app.dart`; router bỏ lần reset riêng của tab Tài khoản. `app.dart`, `app_router.dart` là vùng dùng chung: `impact.mjs` → dùng bởi `bootstrap.dart` / `app.dart`, 0 màn hình bị lan.
- Script kiểm contract vào repo: `scripts/check-auth-contract.mjs`, mật khẩu seed qua `CARENEST_SEED_PASSWORD`, cách chạy ở `docs/integration/AUTH_FLOW.md`.
- Verify: `tests 356 fail 0 skip 0`; chi tiết `docs/quality/VERIFICATION.md`.
- Còn để sau: 401 đến sau lần refresh vừa xong gây refresh thêm; `dataExtractionRules` cho chuyển máy; tách interface domain cho auth (làm đầu Phase 2).
- Commit → task: `f24ae1b` (Minor 1, Task 7), `5f0d71a` (Minor 1, Task 9); `78a4c89` (Minor 2, Task 8); `aa95fa6` (Minor 6, Task 10).
