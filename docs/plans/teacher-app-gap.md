# Teacher app — đối chiếu UC, màn hình và API BE

Ngày: 2026-11-15 · Nguồn: `BE:docs/api/API_INDEX.md`, controller/DTO BE (nhánh `dev` 613b0274), `BE:src/main/java/com/carenest/utils/enums/Permission.java`, `docs/features/teacher/README.md`, Use Case List v3.3 (team).

Phạm vi App cho GV (user chốt 15/11): **3 luồng thao tác** — Điểm danh → Sức khỏe đầu ngày → Trả trẻ. Mọi màn khác **chỉ xem**; nhập/duyệt làm trên Web.

Quyền mặc định TEACHER: CHILD_PROFILE_VIEW, ATTENDANCE_VIEW, ATTENDANCE_RECORD, DAILY_HEALTH_RECORD, PICKUP_RECORD, ASSESSMENT_VIEW, ASSESSMENT_RECORD, ASSESSMENT_CONFIRM (`Permission.java`). HT tắt được các quyền RECORD ⇒ App phải xử lý 403. Phạm vi "lớp mình" kiểm ở service BE.

| UC | Màn App | Loại | Endpoint BE | Status |
| --- | --- | --- | --- | --- |
| UC49 Điểm danh | Điểm danh (T02) | Thao tác | `GET /classes/{classId}/attendance?date=` → `ClassAttendanceResponse`; `PUT /classes/{classId}/attendance` ← `SaveAttendanceRequest{date, entries[{childId, status}]}` | EXISTS |
| UC50 Báo ăn | Điểm danh (chỉ hiển thị "Suất ăn: N") | Dẫn xuất | Có mặt = ăn mọi bữa của lớp: `AttendanceServiceImpl.mealsFor(status, classSessions)` bỏ qua `meals` gửi lên (ATT-02 CONFIRMED, user xác nhận 15/11) | EXISTS — không cần nhập |
| HLT-07/14 Sức khỏe đầu ngày, trong ngày | Sức khỏe đầu ngày (mới) | Thao tác | `POST /daily-health-entries` ← `DailyHealthRequest`; tóm tắt từ `ClassAttendanceResponse.ChildRow.health`; `GET /classes/{classId}/children/{childId}/daily-health` | EXISTS (P-21/22/23 còn PENDING) |
| UC60/61 Trả trẻ | Trả trẻ (T05/T06) | Thao tác | `GET /classes/{classId}/pickups` → `PickupBoardResponse`; `GET /pickups/children/{childId}` → `PickupChildResponse`; `POST /pickups` ← `PickupRequest` | EXISTS |
| UC54 Đánh giá ngày | Đánh giá hằng ngày (T04/T04.1) | Chỉ xem | `GET /classes/{classId}/daily-assessment` → `DailySheetResponse` | EXISTS (App chưa map DTO thật) |
| UC51/52/53 Cân đo, xu hướng | Cân đo (T07/T07.1) | Chỉ xem | `GET /children/{childId}/health`, `GET .../health/trend-analysis` | EXISTS |
| UC55 Hồ sơ phát triển | — | Chỉ xem | `GET /assessment/children/{childId}/development` | EXISTS — App **chưa có màn** |
| UC56/57/58 Nhận xét tuần/tháng/năm, AI nháp | — | Web | `/assessment/weekly-comments`, `/assessment/evaluations/*` | Làm trên Web |
| UC59 Đề xuất khen thưởng | — | Web | `/assessment/reward-lists/classes/{classId}` | Làm trên Web |
| UC47/48 Mục tiêu năm, kế hoạch | Lịch hoạt động (T10) | Chỉ xem | `/education-plans/class-docs` (payload JSON chung) | PARTIAL — App chưa map |
| Danh sách lớp | Lớp học (T09) | Chỉ xem | `GET /children?classId=`, `GET /attendance/classes` | EXISTS |
| Đơn nghỉ của lớp (ATT-05) | Đơn nghỉ lớp (T03) | Chỉ xem | `GET /leave-requests?classId=&from=&to=` | EXISTS — BE không có "GV đã xem" |
| UC62 Báo sự cố CSVC | — | — | FAC-01..04 REMOVED | Không làm |
| Ảnh bữa ăn (NUT-16) | Ảnh bữa ăn (T15/T16) | Ẩn | Upload cần KITCHEN_RECORD (bếp) | Ẩn khỏi App GV |
| UC01/02/05/06/07 | Đăng nhập, thông báo, tài khoản | — | Keycloak PKCE; `/me/notifications`; `/accounts/me`; `/me/password` | EXISTS |

## Trường BE dùng ở 3 màn thao tác

- **Điểm danh & báo ăn:** `children[].child{id, fullName}`, `record.status` (PRESENT / EXCUSED / UNEXCUSED, null = chưa ghi), `record.meals` (Map MealSession → Boolean), `mealSessions` của lớp (MORNING / LUNCH / AFTERNOON), `leave{requestId, fromDate, toDate, reason}`, `day.cutoff`, `day.locked`, `canRecord`. Ghi: `entries[{childId, status, meals}]`. BE tự đặt `meals` theo trạng thái (ATT-02) nên App không nhập bữa.
  - App mặc định Có mặt khi `record` null (user chốt 15/11). GV chỉ có Có mặt / Vắng; Vắng gửi EXCUSED nếu bé có `leave`, còn lại UNEXCUSED (ATT-09).
- **Sức khỏe đầu ngày:** `requestId` (App sinh, idempotent), `classId`, `childId`, `date`, `temperature` (tùy chọn, 20,0–45,0, 1 số lẻ), `observation` (NO_CONCERN / NOTED), `symptoms[]`, `actions[]`, `note` ≤500, `referral{place ≤150, time HH:mm, escort ≤100}`.
- **Trả trẻ:** bảng `rows[{child, attendanceStatus, status, pickup}]`; phụ huynh `guardians[{position, fullName, relationship, phone, photoUrl}]`; ghi `PickupRequest{childId, verification, guardianPosition, handoverTime, note}`:
  - PHOTO_MATCH: bắt buộc `guardianPosition` + `handoverTime`.
  - PHONE_CONFIRMED: bắt buộc `handoverTime` + `note`.
  - PHONE_DECLINED: bắt buộc `note`.

## Nhu cầu UI BE chưa hỗ trợ / cần chốt


1. Trang chủ GV: số bé đã điểm danh, đã kiểm tra sức khỏe, đã đón trong một lần gọi — chưa có endpoint tổng hợp (App phải gọi nhiều API).
2. Đơn nghỉ lớp: badge "Mới / Đã xem" không có trong `LeaveRequestResponse`.
3. Nút "Gọi" phụ huynh dùng `url_launcher` (đã thêm 15/11, lockfile chờ `flutter pub get`).
4. Đánh giá ngày, lịch hoạt động: App vẫn dùng mô hình giả, chưa map `DailySheetResponse` và class-docs.
5. UC55 Hồ sơ phát triển: chưa có màn chỉ xem trên App.
6. Đăng nhập: cần thư viện OAuth2 PKCE (Keycloak) — chưa chọn.
