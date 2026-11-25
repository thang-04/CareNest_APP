---
title: Hồ sơ, yêu cầu cấp lại mật khẩu, huỷ đơn nghỉ, nút mở màn trong thông báo
status: approved
owner: Giáp
jira: TBD-4 / FE-FEAT-0
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [shared-account, parent, notifications]
rules: [AUTH-21, AUTH-22, ATT-04, ATT-05, ATT-12, PAR-07]
risk: medium
created: 2026-11-25
updated: 2026-11-25
---
# Đổi mật khẩu, hồ sơ, huỷ đơn nghỉ, nút mở màn trong thông báo

Plan đi kèm: `2026-11-25-kitchen-api-integration.md`. Chỉ phần BE đã có trên nhánh BE `fix/G94-180-BE-FIX-10-school-year-scope` (giống `origin/dev` ở các API này).

## Context
- Phiên thật: "Thông tin cá nhân", "Đổi mật khẩu" mở "Sắp có" (`lib/routing/app_router.dart:~858-869`). Hồ sơ đã có nguồn `LiveAccountSource` đọc `/accounts/me` lúc đăng nhập (`lib/features/shared/account/data/live_account_source.dart:11`), BE chưa trả số điện thoại ⇒ hiện tên đăng nhập.
- BE `PUT /me/password` (`isAuthenticated()`), body `{currentPassword, newPassword (8–128), confirmPassword}` (`BE:src/main/java/com/carenest/dto/account/AuthRequests.java:45-48`). App đã có màn `NewPasswordScreen(requireCurrent: true)` cho Xem thử.
- Huỷ đơn nghỉ: BE `PATCH /leave-requests/{id}/cancel` (PARENT, không body; BE huỷ phần ngày còn huỷ được — user chốt 14/11: ngày chưa qua giờ chốt huỷ, ngày đã qua giữ "Vắng có phép"). App chưa có nút huỷ (`LeaveNoticeSource` không có `cancel`).
- Chi tiết thông báo: nút hành động chỉ có ở dữ liệu giả; phiên thật không gắn `actionLabel` (`lib/features/shared/notifications/data/live_notification_source.dart:55-95`). BE `NotificationResponse` có `type`, `childId`, `announcementId`.
- **Không làm ở đây — quên mật khẩu:** BE `POST /auth/password/forgot` chỉ nhận email (staff Web); AUTH-21 không cho phụ huynh / bếp quên mật khẩu trên Web. Luồng SMS OTP cho App (AUTH-27) nằm trên nhánh BE `origin/feature/G94-87-BE-FEAT-0-app-rules-sms-reset`, **chưa gộp vào dev**. Cần gộp nhánh đó trước.

## Quyết định đã chốt
- 0. Trên App mọi vai (phụ huynh, GV, bếp) không tự đổi mật khẩu: gửi yêu cầu lên HT / PHT có quyền, họ cấp mật khẩu tạm trên Web; App không dùng `PUT /me/password` — Giáp, 25/11/2026. Rule do BE ghi; API đề xuất ở file gửi Thắng mục 7.
1. Huỷ đơn nghỉ: huỷ phần ngày còn huỷ được, ngày đã qua giờ chốt giữ "Vắng có phép" — user, 14/11/2026 (BE đã làm).
2. Hồ sơ chỉ xem; không có API tự sửa hồ sơ (sửa cần ACCOUNT_MANAGE) — theo BE hiện tại.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** mọi vai App đổi được mật khẩu của mình; phụ huynh huỷ đơn nghỉ đã gửi; bấm thông báo mở đúng màn của bé.
- **Ảnh hưởng:** tab Tài khoản (phụ huynh, GV, bếp), Đơn nghỉ phụ huynh, Chi tiết thông báo. Không đổi contract BE.

### Câu hỏi mở
(không còn)

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Tự đổi mật khẩu hay xin HT/PHT? | Xin HT/PHT, mọi vai App | Giáp | 25/11 | Đề xuất BE gửi Thắng mục 7 |

## Acceptance criteria
- **AC-1** (đề xuất BE mới): Tài khoản › "Đổi mật khẩu" đổi thành "Yêu cầu cấp lại mật khẩu". **Chờ BE (Thắng mục 7)**: tới khi có API, phiên thật giữ "Sắp có"; khi có ⇒ gửi yêu cầu, hiện trạng thái Đang chờ / Đã cấp / Từ chối. Không dùng `PUT /me/password`.
- **AC-2**: Tài khoản › Thông tin cá nhân (phiên thật) mở màn hồ sơ chỉ xem từ `/accounts/me`; không có nút sửa.
- **AC-3** (ATT-05, ATT-12): Đơn nghỉ: đơn đang hiệu lực (chưa huỷ, còn ngày chưa qua) có nút "Huỷ đơn" kèm hộp xác nhận; gửi `PATCH …/cancel`; danh sách tải lại; lỗi BE (đơn đã qua hết giờ chốt…) hiện câu `desc`. Năm học đã đóng (ô năm "Chỉ xem") ⇒ không có nút.
- **AC-4** (PAR-07): Chi tiết thông báo phiên thật có nút mở màn theo `type` + `childId`:
  - `HEALTH_RESULT_PUBLISHED`, `HEALTH_RESULT_UPDATED`, `HEALTH_TREND_APPROVED` ⇒ Sổ sức khỏe của bé.
  - `CHILD_EVALUATION_CONFIRMED`, `THEME_EVALUATION_CONFIRMED`, `WEEKLY_COMMENT_SENT` ⇒ Đánh giá.
  - `REWARD_LIST_UPDATED` ⇒ Khen thưởng.
  - `LEAVE_REQUEST_CHANGED` ⇒ Đơn xin nghỉ.
  - `CHILD_PICKED_UP`, `DAILY_HEALTH_NOTED` ⇒ Điểm danh & bữa ăn.
  - `SCHOOL_ANNOUNCEMENT` ⇒ giữ như hiện tại (nội dung thông báo trường).
  - Loại khác hoặc thiếu `childId` ⇒ không có nút. Vai GV / bếp: không có nút ở plan này.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Bảng loại → màn | Đặt ở lớp router (route theo vai + `childId`) | Trong màn thông báo | Màn trình bày không biết route; một chỗ đổi |
| Nút huỷ đơn | Hiện khi đơn chưa huỷ và `to ≥ hôm nay`; BE quyết định phần huỷ được | App tính giờ chốt | Giờ chốt do HT cấu hình (ATT-06), BE quyết định |

## Phases
### Phase 1 — Tài khoản: hồ sơ (mọi vai); yêu cầu cấp lại mật khẩu để sau khi BE có API
- Files: M `app_router.dart` (phiên thật mở màn hồ sơ chỉ xem; mục mật khẩu đổi tên, vẫn "Sắp có") · M `account_screen.dart` (nhãn) · tests.
- Tests: AC-2 → router test; AC-1 → widget test nhãn mới. Phần gửi yêu cầu làm khi Thắng xong mục 7.
- Exit: `node scripts/verify.mjs` → VERIFY PASS.

### Phase 2 — Huỷ đơn nghỉ
- Files: M `fake_leave_notice_source.dart` (interface thêm `cancel`) · M `live_leave_notice_source.dart` · M `leave_notice_list_screen.dart` · tests.
- Tests: AC-3 → test nguồn (PATCH đúng path), widget test (nút, xác nhận, ẩn ở năm đã đóng).
- Exit: VERIFY PASS.

### Phase 3 — Nút mở màn trong chi tiết thông báo
- Files: M `live_notification_source.dart` (giữ `type`, `childId`) · M domain thông báo · M `notification_detail_screen.dart` (callback mở màn) · M `app_router.dart` (bảng loại → route) · tests.
- Tests: AC-4 → test bảng loại → route; widget test nút.
- Exit: VERIFY PASS.

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | (đề xuất BE) | widget test nhãn; gửi yêu cầu chờ BE | 1 | |
| AC-2 | — | live_ui_router_test | 1 | |
| AC-3 | ATT-05, ATT-12 | live_leave_notice_source_test + widget | 2 | |
| AC-4 | PAR-07 | notification route map test + widget | 3 | |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| BE chưa có API yêu cầu cấp lại mật khẩu | Mục mật khẩu vẫn "Sắp có" | Đề xuất Thắng mục 7 | — |
| Bấm nút thông báo của bé đã bỏ liên kết | Màn 403 | `ParentChildGate` sẵn có hiện "không tìm thấy" | — |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Không đổi contract BE
- [x] Mỗi AC có test; mỗi phase có Exit
- [x] Phạm vi vừa 1 plan (3 phase)
- [x] Không dùng rule PENDING/OPEN; quên mật khẩu tách ra vì BE chưa gộp
- [x] Tự review

## Progress log
### 2026-11-25 — Phase 1–3 (done, chờ kiểm máy thật)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 510 fail 0 skip 0`
- Phase 1: hồ sơ phiên thật chỉ xem (`PersonalInfoScreen(readOnly)`, nhãn "Tên đăng nhập", câu "liên hệ HT/PHT"); mục mật khẩu đổi tên "Yêu cầu cấp lại mật khẩu", mọi chế độ mở "Sắp có" tới khi BE có API (Thắng mục 7).
- Phase 2: `LeaveNoticeSource.cancel` (`PATCH /leave-requests/{id}/cancel`); nút "Huỷ đơn" (đơn chưa huỷ, `to` ≥ hôm nay, năm không chỉ xem) + hộp xác nhận "Huỷ đơn xin nghỉ?"; lỗi BE hiện dưới đơn.
- Phase 3: `routing/notification_targets.dart` (loại + bé ⇒ màn); `AppNotification.childId`; nút ở chi tiết thông báo phụ huynh phiên thật.
- Khác plan: Xem thử cũng không mở màn đổi mật khẩu giả nữa (cùng quyết định 0).
