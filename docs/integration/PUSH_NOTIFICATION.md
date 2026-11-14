# Push Notification — Mobile

> **Status: MỘT PHẦN.** Đã chốt provider, phạm vi push và danh mục loại thông báo theo role (BE PAR-07). Field payload, cấu hình Android chưa chốt. Phần còn trống: không tự chọn — hỏi.

## Đã chốt
- **Provider:** FCM qua `firebase_core` + `firebase_messaging` (user 2026-11-13). Capstone chỉ build Android (user 2026-11-14); iOS/APNs làm sau.
- **Phạm vi (BE PAR-07, user 2026-11-14):** mọi thông báo BE tạo cho người dùng đều push tới App và hiện trong danh sách thông báo; App không lọc loại, không có loại chỉ trong App. Thay bảng 7 sự kiện "ngoài bảng không push" cùng ngày. Nguồn danh mục: `BE:docs/modules/notification.md` mục "Danh mục thông báo trên App theo role"; lệch thì BE đúng.
- Nội dung push do BE soạn, chung, không dữ liệu nhạy cảm (loại sức khỏe: "Thông tin sức khỏe").
- Không có: push khi công bố nhận xét tháng/học kỳ/cuối năm (OBS-06; chỉ nhận xét tuần OBS-29) · thông báo của trường do BGH gửi (PAR-05, hoãn — task riêng) · phụ huynh gửi ý kiến (P-32).

Bảng tra màn đích. Cột "BE": `dev` = đã có; `G94-236` = nhánh daily-attendance của BE, chưa vào `dev`. Màn đích ghi "Thông báo" = mở danh sách thông báo; màn đích chi tiết cho loại mới là **đề xuất**, chốt khi làm deep link.

| Role nhận | Loại (`NotificationType`) | Rule | Màn đích | BE |
| --- | --- | --- | --- | --- |
| Phụ huynh | `CHILD_PICKED_UP` | PCK-04 | Bé của tôi › Hôm nay | dev |
| Phụ huynh | `HEALTH_RESULT_PUBLISHED`, `HEALTH_RESULT_UPDATED` | HLT-11, PAR-03 | Bé của tôi (sức khỏe) — đề xuất | dev |
| Phụ huynh | `DAILY_HEALTH_NOTED` (sức khỏe "cần lưu ý") | HLT-14, OBS-31 | Bé của tôi › Hôm nay | G94-236 |
| Phụ huynh | `WEEKLY_COMMENT_SENT` (nhận xét tuần) | OBS-29 | Bé của tôi › Phát triển | G94-236 |
| Phụ huynh | `CHILD_PLACED` (con lên lớp/ở lại khi sang năm học) | OBS-31 | Bé của tôi — đề xuất | G94-236 |
| GV | `LEAVE_REQUEST_CHANGED` (phụ huynh gửi/hủy đơn nghỉ) | ATT-05, OBS-31 | Đơn nghỉ của lớp | G94-236 |
| GV | `CHILD_PLACED` (trẻ vào lớp) | CHD-10 | Lớp học | dev |
| GV | `ATTENDANCE_DAY_UNLOCKED`, `ATTENDANCE_REMINDER` | ATT-08, OBS-30 | Điểm danh — đề xuất | dev, G94-236 |
| GV | `CHILD_WITHDRAWN`, `CHILD_TB_CONTACT`, `HEALTH_CHECK_OPENED`, `EDU_*` | CHD-03, CHD-07, HLT-08, EDU | Thông báo | dev |
| GV | `ASSESSMENT_REMINDER`, `ASSESSMENT_REOPENED`, `STAFF_ASSIGNED`, `CUTOFF_CHANGED`, `REWARD_LIST_UPDATED`, `SCHOOL_YEAR_ACTIVATED` | OBS-30, OBS-31, CFG-YR-02 | Thông báo | G94-236 |
| Bếp | `MEAL_COUNT_CONFIRMED` (xác nhận / xác nhận lại số suất) | NUT-02, ATT-08, OBS-31 | Suất ăn hôm nay | G94-236 |
| Bếp | `CUTOFF_CHANGED`, `SCHOOL_YEAR_ACTIVATED` | OBS-31, CFG-YR-02 | Thông báo | G94-236 |

- BGH (chỉ xem trên App, `docs/plans/active/2026-11-13-bgh-view-only.md`) nhận các loại của BGH khi dùng App: mở danh sách Thông báo.
- Loại lạ (BE thêm sau): hiện trong danh sách Thông báo, không crash.

## Nguyên tắc
- BE quyết định **khi nào** gửi (domain event after-commit → module `notification`, `BE:docs/modules/notification.md`). APP nhận, hiển thị, đăng ký token.
- **Không dữ liệu nhạy cảm trong push**: không tên trẻ kèm dữ liệu sức khỏe/dị ứng/quan sát, không số đo, không nội dung đánh giá.
- Payload chỉ gồm loại sự kiện + ID cần cho deep link. APP mở màn hình rồi **tải dữ liệu qua API có auth**; BE kiểm tra scope.
- Deep link: kiểm tra đăng nhập + role (và chế độ GV/phụ huynh của tài khoản nhiều role) trước khi mở; ID ngoài scope ⇒ 403/404 ⇒ màn hình lỗi, không crash (`.claude/rules/navigation.md`, `docs/architecture/NAVIGATION.md` mục Deep link).
- Không chat, không nhắn tin 2 chiều (CareNest không thay Zalo).
- Gửi thất bại không ảnh hưởng nghiệp vụ (BE); APP không dựa vào push để đồng bộ dữ liệu — luôn refetch khi mở màn hình.
- Logout ⇒ hủy đăng ký device token (`DELETE /me/devices`).

## Điền khi BE chốt
- [x] Endpoint đăng ký/hủy device token: `PUT /me/devices`, `DELETE /me/devices` (`BE:docs/modules/notification.md`, có ở `dev`)
- [x] Tên loại sự kiện: `NotificationType` (bảng trên)
- [ ] Field payload `data` của push (BE `PushDispatchListener`) — đọc khi làm deep link
- [ ] Cấu hình Android: quyền thông báo (Android 13+), channel
- [ ] Hành vi foreground / background / app đã đóng
- [x] Danh sách thông báo in-app lưu ở BE: `GET /me/notifications?limit`, `POST /me/notifications/{id}/read`, `POST /me/notifications/read-all`; `read_at` chỉ để App hiện badge (PAR-05)
