---
title: Thiết kế tối giản và nối API thật cho App giáo viên
status: approved     # user duyệt phạm vi UI 16/11/2026
owner: Nguyễn Vy Anh
jira: G94-385 / APP-FEAT-54
branch: feature/teacher-app-screens
modules: [attendance, health, observation, identity-access]
rules: [AUTH-03, AUTH-21, ATT-02, ATT-04, ATT-09, HLT-07, HLT-14, PCK-02, PCK-03, PCK-04]
risk: high           # thêm thư viện nền, auth, API client dùng chung
created: 2026-11-15
updated: 2026-11-16
---
# Thiết kế tối giản và nối API thật cho App giáo viên

## Context
UI giáo viên đã có bằng dữ liệu giả sau interface nguồn dữ liệu (`docs/plans/teacher-app-changes.md`). Yêu cầu mới ngày 16/11/2026 thu gọn App theo hướng **xem là chính, ít chữ, ít thao tác**: giáo viên chỉ nhập trong hai nhóm **Điểm danh** và **Sức khỏe** (sức khỏe đầu ngày, cân nặng, chiều cao); đánh giá trẻ và các nội dung còn lại chỉ xem. App chưa có HTTP client, đăng nhập, lưu token (`pubspec.yaml`: chỉ `go_router`, `url_launcher`).

## Làm rõ nghiệp vụ

- Actor/role: `TEACHER` · Outcome: mở App là thấy ngay lớp và ba việc thao tác nhanh; dữ liệu còn lại đọc nhanh theo từng bé.
- Rule khớp: ATT-01/02/04/09 (điểm danh), HLT-07/09/13/14 (nhiệt độ, sức khỏe trong ngày, cân nặng, chiều cao), OBS-01..13 (App chỉ xem kết quả đánh giá theo yêu cầu mới).
- Flow đã chốt: Hôm nay → Điểm danh → Sức khỏe hoặc Trả trẻ; tab Lớp → chọn bé → xem đánh giá/sức khỏe/lịch sử.
- Figma hiện tại chưa phải nguồn cuối: nhóm “Bản sửa theo rule – 13/11” vẫn ghi GV nhập đánh giá và đón trẻ; UI mới theo ưu tiên `yêu cầu 16/11 → DESIGN.md → BE contract`.
- Trả trẻ được giữ là thao tác trên App theo PCK-02/PCK-04 (user xác nhận 16/11/2026).
- Báo ăn trên APP dùng màn phụ: trẻ Có mặt mặc định có ăn, GV có thể bỏ chọn nếu trẻ vẫn đi học nhưng không ăn (user xác nhận 16/11/2026). Quyết định này lệch ATT-02 hiện tại; UI/dữ liệu giả làm trước, phase API chờ BE ngừng bỏ qua `meals`.

## Nguyên tắc UX

- Trang Hôm nay có ba hành động chính: `Điểm danh`, `Sức khỏe`, `Trả trẻ`; một hàng tiến độ ngắn, không dùng đoạn giải thích dài.
- Điểm danh: mỗi bé một hàng, hai lựa chọn Có mặt/Vắng; thao tác hàng loạt một chạm; lưu xong sang sức khỏe.
- Sức khỏe: một màn danh sách, hai lối vào ngắn `Hôm nay` (nhiệt độ/biểu hiện) và `Cân đo` (chiều cao/cân nặng); chỉ hiện field phụ khi có bất thường.
- Chi tiết bé gom nội dung chỉ xem: đánh giá hằng ngày, nhận xét định kỳ, lịch sử sức khỏe/cân đo; dùng thẻ tóm tắt và mở rộng khi cần.
- Không tự tính/chẩn đoán; phân loại, cảnh báo, trạng thái công bố và quyền đều lấy từ BE.

## Quyết định cần team duyệt (Key decisions)
| Hạng mục | Đề xuất | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Đăng nhập | `flutter_appauth` — Keycloak OAuth2 Authorization Code + PKCE, client `carenest-mobile`, redirect `carenest://oauth/callback` (`BE:docs/contracts/AUTH_CONTRACT.md`) | WebView tự viết | Thư viện chuẩn AppAuth, dùng trình duyệt hệ thống; BE không cho App dùng `/auth/login` (403 1101) |
| HTTP | `dio` | `package:http` | Interceptor (Bearer, refresh, envelope) — đã đề xuất trong `DESIGN.md` §1.3 |
| Lưu token | `flutter_secure_storage` | — | Keychain/Keystore (`.claude/rules/security-storage.md`) |
| State | Giữ `StatefulWidget` + interface nguồn dữ liệu như hiện tại | `flutter_riverpod` | Ít thư viện mới; đổi sau khi team chốt state |
| Phạm vi thao tác | Điểm danh + Sức khỏe (gồm cân đo) + Trả trẻ; các màn khác chỉ xem | — | User xác nhận 16/11/2026; khớp ATT, HLT, PCK của BE |

## Luồng đăng nhập và token
1. Màn Đăng nhập: nút "Đăng nhập" mở trang Keycloak (realm `carenest`) qua `flutter_appauth`; nhận access token (JWT 5 phút) + refresh token.
2. Refresh token và id token lưu `flutter_secure_storage`; access token giữ trong bộ nhớ.
3. Gọi `GET /accounts/me` ⇒ role; TEACHER mở nhánh `/teacher`, role không dùng App ⇒ báo lỗi (AUTH-21).
4. Interceptor: 401 (code 1002) ⇒ refresh một lần (gộp request đồng thời) rồi gửi lại; thất bại ⇒ xóa token, về Đăng nhập. 503 (1013) ⇒ thử lại, không đăng xuất.
5. Đăng xuất: logout Keycloak (end session) + xóa token, cache, state.

## API client
- `lib/core/network/api_client.dart`: base URL + prefix `/api` từ `Env` (`--dart-define=API_BASE_URL`), timeout, parse envelope `{code, errorCode, desc, data}` một chỗ, map lỗi thành `AppFailure(status, errorCode, desc, fieldErrors)`.
- Không log body, header Authorization, token.
- Base URL theo môi trường:
  - Giả lập Android + BE máy dev: `adb reverse tcp:8080 tcp:8080` và `adb reverse tcp:8180 tcp:8180`, App dùng `http://localhost:8080`. Lý do: token Keycloak có issuer `http://localhost:8180` (`KC_HOSTNAME`), gọi qua `10.0.2.2` sẽ lệch issuer.
  - Staging/VPS: URL HTTPS của team.
- Android cho phép HTTP cleartext chỉ ở bản debug (network security config).

## Thứ tự nối endpoint
| Bước | Màn | Endpoint |
| --- | --- | --- |
| 1 | Chọn lớp GV | `GET /attendance/classes` |
| 2 | Điểm danh | `GET /classes/{classId}/attendance?date=`, `PUT /classes/{classId}/attendance` |
| 3 | Sức khỏe đầu ngày | tóm tắt từ bước 2 (`health`), `POST /daily-health-entries` |
| 4 | Cân nặng, chiều cao | `GET /children/{id}/health`, `POST /children/{id}/health/measurements`, `PUT /children/{id}/health/measurements/{measurementId}` |
| 5 | Chỉ xem | `GET /leave-requests?classId=`, `GET /classes/{classId}/daily-assessment`, `GET /children/{id}/health`, `GET /children?classId=` |
| 6 | Chung | `GET /me/notifications`, `GET /accounts/me` |
| 7 | Trả trẻ | `GET /classes/{classId}/pickups?date=`, `GET /pickups/children/{childId}`, `POST /pickups` |
Mỗi màn: thêm `Api<Xxx>Source` cạnh `Fake<Xxx>Source`; chọn theo `USE_MOCK` ở điểm ghép (router). Bước 5 cần map lại model chỉ xem theo DTO thật.

## Lỗi, mạng, trạng thái
- 400 (9001) ⇒ lỗi theo field; 403 (1101, 3001) ⇒ màn "không có quyền" (HT tắt quyền RECORD của GV); 409 ⇒ tải lại + báo trạng thái đã đổi; 5xx ⇒ "thử lại".
- Điểm danh: PUT idempotent ⇒ cho phép thử lại; giữ lựa chọn khi lỗi mạng (đã có).
- Sức khỏe: `requestId` sinh một lần cho mỗi lần nhập ⇒ gửi lại an toàn (đã có).
- Cân đo: POST không tự thử lại; PUT chỉ gửi lại khi người dùng xác nhận vì sửa số đo cần lý do theo HLT-13.
- Trả trẻ: không tự thử lại POST.
- Không offline queue ở giai đoạn này.

## Kiểm thử
- Unit: parse envelope, map lỗi, interceptor refresh (dio mock adapter, không gọi mạng).
- Widget: giữ test hiện có với Fake source; thêm test Api source với JSON mẫu đúng DTO BE (dữ liệu giả).
- Thủ công: BE local + tài khoản GV dev (`BE:docs/TAI_KHOAN_DEV.md`, ví dụ `teacher1`) trên giả lập Pixel 8 Pro: điểm danh → sức khỏe đầu ngày → cân đo → xem đánh giá; kiểm tra dữ liệu trên Web.
- Exit mỗi phase: `node scripts/verify.mjs` → `VERIFY PASS full`.

## Chạy BE local
1. Trong `CareNest_BE`: `docker compose up --build` (PostgreSQL, Keycloak `:8180`, API `:8080`, profile `dev` nạp dữ liệu mẫu).
2. Kiểm tra `http://localhost:8180/realms/carenest/.well-known/openid-configuration`, Swagger `http://localhost:8080/swagger-ui/index.html`.
3. `adb reverse` như trên, chạy App với `--dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:8080/api`.

## Phases
1. Thêm 3 thư viện + API client + đăng nhập PKCE + `/accounts/me` ⇒ dừng review.
2. Điểm danh + Sức khỏe đầu ngày ⇒ dừng review.
3. Cân đo + chi tiết bé chỉ xem ⇒ dừng review.
4. Các màn chỉ xem + thông báo ⇒ dừng review.
5. Trả trẻ + rà tổng thể UI giáo viên ⇒ dừng review.

## Câu hỏi mở
- [x] Thêm `flutter_appauth`, `dio`, `flutter_secure_storage`; giữ `StatefulWidget`, chưa thêm Riverpod — user không đổi đề xuất kỹ thuật và yêu cầu tiếp tục 16/11/2026.
- [x] Trả trẻ giữ thao tác trên App theo PCK-02/PCK-04 — user xác nhận 16/11/2026.
- [x] Mã Jira chưa cần ở giai đoạn sửa/kiểm thử; bắt buộc hỏi trước khi commit/PR.
- [x] `offline_access` không chặn phase UI; kiểm tra realm trước phase auth và không tự yêu cầu scope chưa cấu hình.

## Progress log
- 2026-11-16: Đã rà Figma, `DESIGN.md`, code APP và controller/DTO BE. Chưa sửa code vì plan còn câu hỏi nghiệp vụ PCK và quyết định dependency.
- 2026-11-16: User chốt giữ Trả trẻ trên App và yêu cầu tối ưu theo `DESIGN.md` để đồng bộ FE. Plan được duyệt; bắt đầu phase UI trước, chưa commit/push.
- 2026-11-16: Phase UI hoàn tất: Trang Hôm nay tách `Cần làm`/`Xem nhanh`; Sức khỏe gom lối cân đo; cân đo nhập/sửa đúng `HealthMeasurementRequest`; giữ Trả trẻ. `dart format` sạch, `flutter analyze` sạch, toàn bộ 191 test pass. `node scripts/verify.mjs` chưa chạy được do sandbox chặn Node `lstat C:\Users\ASUS`; các bước Flutter của verify đã chạy trực tiếp và pass.
