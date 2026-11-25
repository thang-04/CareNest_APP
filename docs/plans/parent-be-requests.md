# Đề xuất API phụ huynh cho BE — 18/11/2026

> Tham khảo cho người phụ trách App phụ huynh — Vy Anh không làm phần này (18/11). Các sửa code phụ huynh nêu bên dưới **đã hoàn tác**, chưa áp dụng.

Gửi người phụ trách BE. Nguồn: `docs/plans/parent-app-review.md`; BE `dev` 696051b0. Trạng thái: **PROPOSED** — cần BE/user chốt; chưa sửa repo BE. App đang chạy dữ liệu giả theo dạng dưới đây.

## Nguyên tắc chung (áp mọi mục)
- Quyền: `hasRole('PARENT')`, token client App (`ClientPlatform.MOBILE`, AUTH-21). Phạm vi con qua `ChildAccessPolicy.canAccessChild` (liên kết GuardianChildLink, trẻ chưa thôi học — AUTH-04, PAR-02 mặc định từ chối).
- Chỉ dữ liệu đã công bố/xác nhận (PAR-03); sức khỏe trong ngày hiện ngay (HLT-14).
- Không trả dữ liệu trẻ khác (tên bạn cùng lớp, số liệu lớp), không trả nội bộ nhân sự.
- Đường dẫn đề xuất theo kiểu đã có: `/children/{childId}/...` (như `/children/{childId}/health/published`, `/weekly-comments`).
- Ảnh: trả `photoId`, tải qua endpoint `content`/`url` có auth như ảnh trẻ hiện có.

Đã có, không đề xuất: đơn nghỉ (`/leave-requests/me`, tạo, hủy), kết quả cân đo (`/health/published`), nhận xét tuần (`/weekly-comments`), ảnh trẻ/phụ huynh, thông báo + thông báo trường (`/me/notifications`, `/me/announcements/{id}`).

## 1. Thông tin bé (dùng cho Trang chủ, đổi bé)
- Rule: PAR-01, PAR-06 (một tài khoản xem mọi con), AUTH-04.
- Hiện tại: `/accounts/me` chỉ có `childIds`; `ChildController` cần `CHILD_PROFILE_VIEW`.
- Đề xuất: `GET /me/children` → `List<ParentChildSummary(childId, fullName, shortName, dateOfBirth, className, campusName, ageGroupId, ageGroupName, mainTeacherNames, photoUploaded)>`.

## 2. Hôm nay của bé
- Rule: PAR-01, ATT-02a (tham gia ăn cả ngày), ATT-09, PCK-04 (báo khi đã đón), HLT-14, EDU-09 (tên hoạt động).
- Đề xuất: `GET /children/{childId}/today?date=` → `ChildTodayResponse(date, attendanceStatus PRESENT/EXCUSED/UNEXCUSED/null, mealParticipation boolean|null, leaveRequestId, dailyHealth (mục 5), pickup (mục 8), activities (mục 6, chỉ tên), dailyReviewAvailable)`.
- Không có giờ đến nếu BE không ghi giờ điểm danh (App hiện ghi "07:42" — bỏ nếu BE không có).

## 3. Lịch điểm danh tháng
- Rule: PAR-01, ATT-04/05b, ATT-09, ATT-02a.
- Đề xuất: `GET /children/{childId}/attendance?month=YYYY-MM` → `ChildAttendanceMonthResponse(month, days: List<Day(date, schoolDay, status, mealParticipation, leaveRequestId)>, totals(present, excused, unexcused, noMealDays))`.
- Tổng do BE tính; App không tự đếm.

## 4. Thực đơn tuần + ảnh mẫu bữa
- Rule: PAR-01, NUT-08 (đã công bố), NUT-13 (khối Nhà trẻ/Mẫu giáo), NUT-16 (1 ảnh mỗi điểm trường + ngày + bữa), NUT-17 (bữa theo nhóm tuổi), NUT-23 (suất thay thế của bé).
- Hiện tại: `MealPlanController` chỉ HT/PHT; `KitchenRecordsController` ảnh chỉ HT/PHT/bếp.
- Đề xuất: `GET /children/{childId}/menu?weekStart=` → `ChildWeeklyMenuResponse(weekStart, published, days: List<Day(date, meals: List<Meal(session, dishes: List<Dish(id, name, substitute boolean)>, photo: MealPhotoRef(photoId, uploadedAt)|null)>, energyNote)>)`; chỉ bữa của nhóm tuổi bé, món của khối bé, điểm trường của bé.
- Ảnh: `GET /children/{childId}/meal-photos/{photoId}/content` (kiểm ảnh thuộc điểm trường của bé).

## 5. Sức khỏe đầu ngày
- Rule: HLT-07, HLT-14 (báo phụ huynh ngay), HLT-15, PAR-03.
- Đề xuất: `GET /children/{childId}/daily-health?from=&to=` → `List<ParentDailyHealth(date, temperature, status NORMAL/ATTENTION, symptoms, handling, referral(place, time)|null, note, recordedAt)>`. Không tên GV ghi nếu không cần.

## 6. Hoạt động trong ngày + ảnh hoạt động
- Rule: EDU-09 (App chỉ hiện tên hoạt động cho phụ huynh), PAR-01.
- Đề xuất: `GET /children/{childId}/activities?date=` → `List<ActivityItem(time, title)>` từ giáo án ngày đã duyệt.
- **Ảnh hoạt động:** BE chưa có nghiệp vụ (chưa rule). App giữ màn bằng dữ liệu giả (user 18/11). Cần chốt: ai chụp (GV), giới hạn, có ảnh trẻ khác trong ảnh lớp không (riêng tư), lưu bao lâu. Nếu làm: `GET /children/{childId}/activity-photos?date=` → `List<ActivityPhoto(photoId, takenAt, caption)>`.

## 7. Đánh giá ngày, cờ, khen thưởng
- Rule: OBS-13 (thấy sau khi GV lưu), OBS-02/15 (mặt và thang), OBS-10 (cờ tuần/tháng), OBS-14 (danh hiệu cuối năm HT duyệt), PAR-03.
- Đề xuất:
  - `GET /children/{childId}/daily-reviews?date=` → `ParentDailyReview(date, rows: List<Row(criterion, label, value)>, behaviors, comment)` — chỉ bé, đúng nhãn như `DailySheetResponse.Row`.
  - `GET /children/{childId}/rewards?schoolYearId=` → `ParentRewards(weeklyFlags, monthlyTickets, yearEndTitle|null)` — chỉ khi đã duyệt.

## 8. Người đón
- Rule: PCK-02 (đối chiếu ảnh phụ huynh), PCK-03 (không đăng ký trước người đón hộ), PCK-04 (báo phụ huynh khi đã đón).
- Đề xuất: trong `ChildTodayResponse.pickup` → `PickupInfo(pickedUpAt, method PHOTO_MATCH/PHONE_CONFIRMED, pickedUpByRelation)`; lịch sử theo ngày ở mục 3 nếu cần.

## 9. Hồ sơ bé
- Rule: PAR-01, AUTH-04, PCK-02, AUTH-27 (phụ huynh không xóa ảnh).
- Đề xuất: `GET /children/{childId}/profile` → `ParentChildProfile(fullName, dateOfBirth, gender, className, campusName, mainTeacherNames, guardians: List<Guardian(relation, fullName, phone, photoUploaded)>)`. Không có "người đưa đón đã đăng ký".

## 10. Dị ứng / chế độ ăn
- Rule: HLT-06 (phụ huynh khai khi nhập học, mức nhẹ/nặng), NUT-23 (nhẹ ⇒ bỏ món; nặng ⇒ món thay thế).
- Hiện tại: `PublishedHealthResponse` không có dị ứng.
- Đề xuất: `GET /children/{childId}/allergies` → `List<ChildAllergy(allergenName, level MILD/SEVERE, note)>`; thực đơn (mục 4) đánh dấu món thay thế cho bé. App giữ dòng dị ứng/chế độ ăn bằng dữ liệu giả (user 18/11), chờ API.

## Ưu tiên gợi ý
1. Mục 1, 2, 4 (Trang chủ + thực đơn, phụ huynh dùng nhiều nhất).
2. Mục 3, 5, 8.
3. Mục 7, 9, 10.
4. Mục 6 ảnh hoạt động — cần chốt nghiệp vụ trước.

## Ảnh hưởng
- BE: controller/DTO mới cho PARENT, service đọc lại dữ liệu đã có (điểm danh, thực đơn, ảnh mẫu, sức khỏe đầu ngày, đánh giá, đón trẻ), OpenAPI, test quyền (phụ huynh không đọc được con người khác).
- Web: không đổi.
- App: thay nguồn giả trong `lib/features/parent/**/data` bằng nguồn API; domain hiện tại gần với các DTO trên.
