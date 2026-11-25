# Rà soát App phụ huynh — 18/11/2026

> Tham khảo cho người phụ trách App phụ huynh — Vy Anh không làm phần này (18/11). Các sửa code phụ huynh nêu bên dưới **đã hoàn tác**, chưa áp dụng.

Nhánh `feature/G94-385-APP-FEAT-54-teacher-app` (chưa commit). Đối chiếu BE `dev` 696051b0 (pull 18/11): `docs/business/BUSINESS_RULES.md`, controller có `PARENT`, DTO; Web `CareNest_FE` dev b76c575b — **không có màn phụ huynh** (AUTH-21: phụ huynh chỉ dùng App). Figma `docs/design/figma/parent-*.png`.

Kết quả: **OK** · **LỆCH** · **THIẾU** · **THIẾU API** (BE chưa có endpoint cho phụ huynh).

## API BE phụ huynh gọi được (hiện tại)
| Endpoint | DTO | Dùng cho |
| --- | --- | --- |
| `POST /leave-requests`, `GET /leave-requests/me`, `PATCH /leave-requests/{id}/cancel` | `CreateLeaveRequest(childId, fromDate, toDate, reason ≤500)`, `LeaveRequestResponse(… status ACTIVE/CANCELLED, effectiveTo, appliedDates, skippedDates)` | Đơn xin nghỉ |
| `GET /children/{childId}/health/published` | `PublishedHealthResponse` (kết quả cân đo, biểu đồ, nhận định đã duyệt) | Tab Sức khỏe |
| `GET /children/{childId}/weekly-comments` | `ParentWeeklyCommentResponse(weekLabel, content, sentAt, teacherName…)` | Nhận xét tuần |
| `GET /children/{childId}/photo`, `/guardian-photos/{gid}`, `/accounts/me/photo` | ảnh / `FileUrlResponse` | Ảnh bé, ảnh phụ huynh (PCK-02) |
| `GET /accounts/me` | `MyAccountResponse(childIds…)` | Danh sách con |
| `GET /me/notifications`, `/read`, `/read-all`, `/me/devices` | `NotificationResponse(type, typeLabel, announcementId…)` | Thông báo, push |
| `GET /me/announcements/{id}` (mới 18/11) | `MyAnnouncementResponse(title, body, sentAt, senderName, attachments)` | Thông báo của trường (PAR-07) |

Không có API phụ huynh cho: hôm nay của bé, thông tin bé (lớp, cơ sở, GV), lịch điểm danh, thực đơn tuần, ảnh mẫu bữa, đánh giá ngày, sức khỏe đầu ngày, hoạt động, khen thưởng, người đón, hồ sơ bé (endpoint hiện chỉ cho nhân sự). PAR-01 nói phụ huynh xem các mục này ⇒ **cần BE bổ sung** (ghi ở cuối).

## Từng màn
| Màn | Rule / BE | App trước | Kết quả | Sửa |
| --- | --- | --- | --- | --- |
| Tạo đơn nghỉ | ATT-05: chỉ ngày bắt đầu–kết thúc + lý do; tối đa 30 ngày; không ngày quá khứ | Có chọn "Buổi nghỉ" (cả ngày/sáng/chiều); chọn tới 180 ngày | LỆCH | Bỏ chọn buổi; Đến ngày tối đa 30 ngày kể từ Từ ngày |
| Tạo đơn — câu suất ăn | ATT-04/05b: ngày nghỉ không suất; ngày đã qua giờ chốt giữ nguyên | "Suất ăn … sẽ được huỷ tự động" | LỆCH | "Ngày nghỉ không có suất ăn. Ngày đã qua giờ chốt điểm danh giữ nguyên." |
| Danh sách đơn nghỉ | `status` ACTIVE/CANCELLED; `effectiveTo`; `skippedDates` | "GV đã xem / chưa xem" (BE không có) | LỆCH | Nhãn như Web GV: Đang hiệu lực / Đã hủy; "Đã hủy từ dd/MM" khi hủy một phần; "Không áp dụng dd/MM (đã qua giờ chốt)" |
| Hủy đơn | `PATCH /leave-requests/{id}/cancel`: hủy từ ngày đầu chưa khóa | Không có | THIẾU | Nút "Hủy đơn" (đơn còn ngày sau hôm nay) ⇒ sheet xác nhận ⇒ gửi; lỗi báo dưới thẻ |
| Hôm nay của bé — thẻ đơn nghỉ | như trên | Badge "GV chưa xem" | LỆCH | Badge "Đang hiệu lực" |
| Thực đơn tuần — ảnh mẫu | NUT-16: 1 ảnh mỗi điểm trường + ngày + bữa (`MealPhotoResponse`, UNIQUE campus/date/session) | "Ảnh mẫu nhóm …", nhiều ảnh mỗi bữa | LỆCH | 1 ảnh mỗi bữa, "Ảnh mẫu bữa ăn · Bếp đăng HH:mm"; xem ảnh toàn màn 1 ảnh |
| Thực đơn tuần — bữa theo nhóm tuổi | NUT-17 (`AgeGroupDetailResponse.mealSessions`) | Bé lớp Lá không có bữa sáng | OK | — (THIẾU API thực đơn cho phụ huynh) |
| Lịch điểm danh — "Bữa: đã ăn sáng · trưa · chiều" | ATT-02a: tham gia ăn cả ngày, không theo bữa | Liệt kê từng bữa | LỆCH | "Tham gia ăn: Có" |
| Hồ sơ bé — "Người đưa đón đã đăng ký" | PCK-03: phụ huynh không đăng ký trước người đón hộ | Tiêu đề gợi đăng ký người đón | LỆCH | Đổi "Phụ huynh" (phụ huynh trên hồ sơ, ảnh đối chiếu PCK-02) |
| Phát triển — nhận xét tuần "Đã xác nhận" | `ParentWeeklyCommentResponse` không có cờ xác nhận; phụ huynh chỉ thấy tin đã gửi (OBS-29) | Badge "Đã xác nhận" | LỆCH | Bỏ badge |
| Sức khỏe | `PublishedHealthResponse`: số đo, `bmiStatus`, điểm biểu đồ, nhận định đã duyệt (HLT-05) | Chuỗi đã định dạng, xu hướng theo tháng, dòng chế độ ăn | LỆCH (TB) | Khi nối API map theo DTO; dị ứng/chế độ ăn: CHỜ API BE (user 18/11 giữ bằng dữ liệu giả; đề xuất BE mục 10) |
| Phát triển — cờ, khen thưởng cuối năm, nhận xét tháng | OBS-10/14 | Có màn | THIẾU API | Giữ dữ liệu giả, chờ BE |
| Hoạt động — "Ảnh hoạt động" | BE không có ảnh hoạt động | Có | CHỜ API BE | User 18/11: giữ màn bằng dữ liệu giả; đề xuất BE mục 6 |
| Thông báo | `typeLabel`, `announcementId` ⇒ `/me/announcements/{id}` (PAR-07) | Loại tự đặt | LỆCH (thấp) | Khi nối API hiện `typeLabel`, mở chi tiết thông báo trường |

## Đã sửa (18/11, chưa commit)
- Đơn nghỉ: domain theo `LeaveRequestResponse` (ACTIVE/CANCELLED, `effectiveTo`, `skippedDates`), bỏ buổi nghỉ và "GV đã xem"; thêm hủy đơn; giới hạn 30 ngày; câu suất ăn theo ATT-05b.
- Thực đơn tuần + xem ảnh: 1 ảnh mỗi bữa, "Ảnh mẫu bữa ăn".
- Lịch điểm danh: "Tham gia ăn: Có".
- Hồ sơ bé: "Phụ huynh" thay "Người đưa đón đã đăng ký".
- Nhận xét tuần: bỏ badge "Đã xác nhận".
- Test: `flutter test test/features/parent` 47 pass; verify toàn repo ở báo cáo bàn giao.

## Đã chốt (18/11)
- "Ảnh hoạt động" và dị ứng / chế độ ăn: giữ trên App bằng dữ liệu giả, **chờ API BE**.

## Cần BE (đề xuất, chưa sửa BE)
PAR-01 cho phụ huynh xem nhưng chưa có endpoint phụ huynh: hôm nay của bé (điểm danh, giờ đến, tham gia ăn, người đón — PCK-04), thông tin bé + lớp + GV, lịch điểm danh tháng, thực đơn tuần đã công bố + ảnh mẫu bữa theo điểm trường, đánh giá ngày (OBS-13), sức khỏe đầu ngày (HLT-14), hoạt động trong ngày (EDU-09), khen thưởng/cờ (OBS-10/14), hồ sơ bé. Chi tiết từng API: `docs/plans/parent-be-requests.md`.

## App khác Figma (để sửa Figma)
- PH03 Tạo đơn: bỏ hàng "Buổi nghỉ"; câu suất ăn mới.
- PH04 Danh sách đơn: badge Đang hiệu lực / Đã hủy; nút "Hủy đơn"; dòng "Không áp dụng … (đã qua giờ chốt)".
- PH05 Thực đơn tuần: mỗi bữa 1 ảnh; "Ảnh mẫu bữa ăn · Bếp đăng HH:mm".
- PH10 Lịch điểm danh: "Tham gia ăn: Có" thay danh sách bữa.
- PH13 Hồ sơ bé: tiêu đề "Phụ huynh".
- PH12 Phát triển: bỏ badge "Đã xác nhận" ở nhận xét tuần.
