---
title: Nối API BE cho các màn phụ huynh (Phase 4 của plan App nối BE)
status: in-progress  # user duyệt 2026-11-25 (Native, commit nhỏ)
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # user 25/11: giữ TBD-4, không cần mã Jira thật
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [features, integration]
rules: [AUTH-04, ATT-12, ATT-14, ATT-15, OBS-36, HLT-11, PAR-01, PAR-03]
risk: high           # >8 file, 7 màn, route phụ huynh (vùng dùng chung)
created: 2026-11-25
updated: 2026-11-25
---
# Nối API BE cho các màn phụ huynh

Plan cha: `docs/plans/active/2026-11-16-app-be-integration.md` (Phase 4). Nền phiên/API: `MobileSession`, `MobileApi` (PR #8), router phiên thật `_buildLiveRouter`.

## Context
- BE `origin/dev` `a58857f2` (24/11) có API phụ huynh, kiểm quyền `isGuardianOf` + trẻ chưa nghỉ học (`ChildAccessPolicy`); lỗi chung: 403/4108 "Bạn chỉ xem được thông tin của con mình", 400/4109 "Chọn khoảng ngày trong một năm học, tối đa 62 ngày" (`from`, `to` bắt buộc).
  - `ParentAttendanceController`: `GET /children/{id}/attendance/today` (`ParentTodayResponse`), `GET /children/{id}/attendance?from&to` (`ParentAttendanceResponse`: `days`, `totals` nửa buổi 0,5), `GET /children/{id}/daily-health/parent?from&to`.
  - `ParentAssessmentController`: `GET /children/{id}/daily-assessments?from&to`, `GET /children/{id}/evaluations?schoolYearId` (themes, semesters, yearEnd — không có tháng), `GET /children/{id}/rewards?from&to` (flags, tickets WEEKLY/MONTHLY, yearEndTitles).
  - `GET /children/{id}/weekly-comments`, `GET /children/{id}/health/published`, `GET /children/{id}/profile` (`ChildPhotoProfileResponse`), `GET /children/{id}/photo/url`.
  - Đơn nghỉ: `POST /leave-requests`, `POST /leave-requests/preview` (`LeavePreviewResponse`), `GET /leave-requests/me`, `PATCH /leave-requests/{id}/cancel`.
  - Trạng thái ngày `ParentAttendanceStatus`: `PRESENT`, `ABSENT_EXCUSED`, `ABSENT`, `NOT_RECORDED`, `NO_SCHOOL`, `NOT_ENROLLED`.
- App: mọi màn phụ huynh nhận `source` qua constructor (`ParentHomeScreen.source`, `MyChildScreen.source`, `EvaluationScreen.source`, `RewardsScreen.source`, `HealthBookScreen.source`, `LeaveNoticeListScreen.source`…), router đang truyền bản giả. Route con kiểm ID theo `FakeParentHomeSource.children` (`lib/routing/app_router.dart`, `_parentChildRoutes`). `SelectedChild` mặc định con giả đầu tiên. `ParentAttendanceStatus` của App thiếu 2 trạng thái mới.
- BE chưa có (giữ dữ liệu giả hoặc "Sắp có"): thực đơn tuần, ảnh bữa, hoạt động theo giờ, người đón (`pickedUpByName` luôn null), chi tiết phiếu khám (chỉ có kết luận ngắn), tên điểm trường, tên GV chủ nhiệm, nhãn tuổi, quy tắc khen thưởng (số cờ tối thiểu).

## Quyết định đã chốt
1. Thứ tự: nền phụ huynh → Xin nghỉ → Trang chủ hôm nay → Bé của tôi → Đánh giá → Khen thưởng → Sổ sức khỏe — user 25/11.
2. Tên điểm trường, tên GV chủ nhiệm, nhãn tuổi: **tạm ẩn** ở chế độ thật tới khi BE bổ sung vào `/children/{id}/profile`; App không tự tính tuổi — user 25/11.
3. Màn chưa có API (Thực đơn, Hoạt động trong ngày, ảnh bữa): chế độ thật hiện "Sắp có", không hiện dữ liệu giả — user 25/11 (Q1).
6. Khen thưởng: ẩn dòng quy tắc "đủ N cờ" ở chế độ thật (BE parent API không trả ngưỡng) — user 25/11 (Q2).
4. Bản giả giữ nguyên cho chế độ Xem thử (debug chưa cấu hình).
5. Mã `TBD-4`, cùng nhánh hiện tại — user 25/11.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** actor phụ huynh (AUTH-04: chỉ con mình) · outcome: các màn phụ huynh hiện dữ liệu BE đã chốt/công bố · rule ATT-12/14/15, OBS-36, HLT-11, PAR-01/03 · flow `[S]` BE lọc theo `isGuardianOf` → App chỉ hiển thị.
- **Ảnh hưởng:** `APP: Trang chủ, Bé của tôi (hồ sơ, điểm danh tháng, theo dõi đầu ngày), Xin nghỉ, Đánh giá, Khen thưởng, Sổ sức khỏe` · vùng dùng chung `lib/routing/app_router.dart` · BE không đổi contract.

### Câu hỏi mở
- [x] Q1 Màn chưa có API (Thực đơn tuần, Hoạt động trong ngày) ở chế độ thật: hiện "Sắp có" (đề xuất) hay giữ dữ liệu giả? — user 25/11: "Sắp có".
- [x] Q2 Khen thưởng cần ngưỡng "đủ N cờ thì được phiếu tuần" (App đang hiện `RewardRules`), BE parent API không trả: ẩn dòng quy tắc (đề xuất) hay ghi cứng? — user 25/11: ẩn.

## Acceptance criteria
- **AC-1** (AUTH-04): phụ huynh có 2 con ⇒ thẻ chọn con là 2 con thật từ `childIds`; chọn con nào thì mọi màn tải theo ID đó; mở route con với ID không phải con mình ⇒ 404 / màn "không có quyền" (403/4108), không crash.
- **AC-2** (ATT-12): Xin nghỉ nửa buổi ⇒ bữa bị huỷ / bữa còn học lấy từ `POST /leave-requests/preview`; gửi đơn ⇒ `POST /leave-requests` kèm `part`, `eats`; danh sách = `GET /leave-requests/me`; huỷ = `PATCH …/cancel`; lỗi 4017/4019–4028/4031 hiện câu BE.
- **AC-3** (ATT-15): Trang chủ hiện trạng thái hôm nay (gồm "Hôm nay không phải ngày học", "Bé chưa vào lớp"), giờ đến, nghỉ sáng/chiều, số thông báo chưa đọc.
- **AC-4** (ATT-14): Điểm danh tháng: từng ngày + tổng có mặt/vắng có phép/vắng (nửa buổi 0,5), bữa đã ăn, bữa huỷ; không hiện người đón.
- **AC-5**: Theo dõi đầu ngày: nhiệt độ, triệu chứng, ghi chú của cô theo ngày.
- **AC-6** (OBS-36): Đánh giá 5 tab đọc dữ liệu BE đã chốt; tab không có dữ liệu ⇒ trạng thái rỗng.
- **AC-7**: Khen thưởng Tuần/Tháng/Cuối năm từ `/rewards`.
- **AC-8** (HLT-11): Sổ sức khỏe: kỳ cân đo, biểu đồ, xu hướng đã duyệt; phiếu khám chỉ hiện kết luận BE trả, không vẽ mục BE không có.
- **AC-9** (quyết định 2): Thẻ bé / hồ sơ chế độ thật không hiện điểm trường, GV chủ nhiệm, nhãn tuổi.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| ID con | Giữ `String` trong domain, bản thật = `childId.toString()` | Đổi toàn bộ domain sang `int` | Ít file đổi; route đã mang ID dạng chuỗi |
| Danh sách con cho route | `LiveParentHomeSource` nhớ `Future<List<ChildSummary>>` theo phiên; route con chờ future (màn tải) rồi kiểm ID | Tải lại mỗi route | Một lần gọi `/children/{id}/profile` mỗi con mỗi phiên |
| Con đang chọn ngoài danh sách | Màn chính chọn con đầu tiên của danh sách thật | Đổi `SelectedChild.reset()` | `reset()` đang dùng ở test bản giả; ID giả không có trong danh sách thật |
| Khoảng ngày | Màn tháng: từ ngày 1 tới cuối tháng (≤ 31 ngày); tab ngày/khen thưởng: 8 tuần gần nhất (56 ngày, < 62) | Cả năm học | BE giới hạn 62 ngày, 1 năm học (4109) |
| Ẩn trường thiếu | Field domain đổi sang nullable (`String?`), màn ẩn khi null | Chuỗi rỗng | Ẩn có chủ đích, test kiểm được |
| Lỗi | `ApiFailure` 403 ⇒ "Bạn chỉ xem được thông tin của con mình."; 400/4109 ⇒ câu BE; khác ⇒ màn lỗi + Thử lại có sẵn | Một câu chung | Theo `.claude/rules/api-client.md` |
| Map DTO | Map tay trong `Live<X>Source`, mỗi source một file test với JSON mẫu đúng DTO BE | Model sinh mã | Không còn `json_serializable` (gỡ 25/11) |

## Bản tác động (vùng dùng chung)
```text
Thay đổi: thêm Live<X>Source cho 6 feature phụ huynh; router phiên thật truyền bản Live vào màn phụ huynh,
  route con kiểm ID theo danh sách con thật; ChildSummary/ChildProfile cho phép thiếu điểm trường, GV, tuổi.
impact.mjs: app_router.dart — chỉ lib/app.dart dùng, lan 0 file giao diện. Ownership chưa khai.
Luồng người dùng: Xem thử không đổi. Phiên thật phụ huynh: thấy con thật và dữ liệu BE; màn chưa có API theo Q1.
Phương án: A (chọn) bản Live cạnh bản giả, router chọn · B sửa thẳng bản giả thành gọi API (mất Xem thử).
Cách kiểm: test map từng source (HttpServer loopback), widget test router phiên thật cho route con, verify.mjs;
  chạy BE local (run-be-app-dev.ps1) + script gọi API bằng token phụ huynh seed để so dữ liệu.
```

## Phases
Mỗi task: test map đỏ trước → code → `node scripts/verify.mjs` → commit nhỏ. Review toàn bộ ở cuối (Native).

### Task P0: Nền phụ huynh — danh sách con thật
- Files: C `lib/features/parent/parent_home/data/live_parent_home_source.dart` · M `parent_home/domain/parent_today.dart` (`ChildSummary.campusName`, `ageLabel`, `homeroomTeacher` → `String?`; enum thêm `noSchool`, `notEnrolled`), các widget dùng 3 field (ẩn khi null), `parent_home_screen.dart` (con đang chọn ngoài danh sách ⇒ con đầu), `lib/routing/app_router.dart` (`_parentChildRoutes` nhận `ParentHomeSource`; chế độ thật dùng Live) · Test C `test/features/parent/parent_home/live_parent_home_source_test.dart`, M `test/routing/live_ui_router_test.dart`.
- Interfaces: `class LiveParentHomeSource implements ParentHomeSource { LiveParentHomeSource(MobileApi api, MobileSession session); }` — `loadChildren()`: `session.account['childIds']` → mỗi ID `GET /children/{id}/profile` → `ChildSummary(id: '$id', fullName, shortName: từ cuối của họ tên, className: child.className ?? cls.name, campusName: null, ageLabel: null, homeroomTeacher: null)`; nhớ future theo phiên. `loadToday(childId)`: `GET /children/{id}/attendance/today` + `GET /me/notifications` (`unreadCount`) → `ParentToday(greetingName: account.fullName, …, menuPublished: false, activityTitle: null)`.
- Tests: `loadChildren_mapsProfilesInAccountOrder`, `loadChildren_cachedPerSession`, `loadToday_mapsAllSixStatuses`, `loadToday_403_throwsOwnChildMessage`; router `live_parentChildRoute_unknownChild_notFound`, `live_parentHome_showsRealChildren`.

### Task P1: Xin nghỉ
- Files: C `parent/leave_notice/data/live_leave_notice_source.dart` · M router (truyền Live) · Test C `…/live_leave_notice_source_test.dart`.
- Interfaces: `LiveLeaveNoticeSource implements LeaveNoticeSource` — `loadNotices` = `GET /leave-requests/me` lọc `childId`; `submit` = `POST /leave-requests` (`part`: FULL_DAY/MORNING/AFTERNOON, `eats`); `loadMealPlan` = `POST /leave-requests/preview` → `LeaveMealPlan(offMeals, keptMeals)` (`eatsApplies` false ⇒ `keptMeals` rỗng); `today` = ngày máy. Thêm `cancel(id)` nếu màn danh sách có nút huỷ (kiểm màn; không có thì không thêm).
- Tests: `submit_postsPartAndEats`, `loadMealPlan_mapsPreview`, `loadNotices_mapsStatusAndEatsMeals`, `submit_4031_throwsBeMessage`.

### Task P2: Trang chủ hôm nay
- Màn trang chủ dùng `LiveParentHomeSource.loadToday` (P0). Thêm nhãn cho `noSchool` ("Hôm nay không phải ngày học"), `notEnrolled` ("Bé chưa vào lớp") ở `*_status.dart` theo bảng badge DESIGN.md §3.2. Lối vào Thực đơn / Hoạt động theo Q1.
- Tests: widget `parentHome_noSchool_showsLabel`, `parentHome_live_hidesCampusAndAge`.

### Task P3: Bé của tôi
- Files: C `parent/my_child/data/live_my_child_source.dart` · M `my_child/domain/my_child.dart` (`ChildProfile.campus`, `teachers`, `ageLabel` → `String?`) và màn hồ sơ (ẩn khi null) · Test C `…/live_my_child_source_test.dart`.
- Interfaces: `loadProfile` = `/children/{id}/profile` (họ tên, lớp, năm học, ngày sinh, giới tính, khai báo sức khỏe, người giám hộ: quan hệ, tên, SĐT nếu BE trả); `loadAttendance` = `/attendance?from=ngày 1&to=cuối tháng` → `AttendanceMonth` (đếm từ `totals`, `mealsLine` từ `mealsEaten`, `mealCancelled` = `cancelledMeals` không rỗng, `pickupLine` null); `loadActivities` theo Q1. Theo dõi đầu ngày: thêm vào chỗ màn đang hiện sức khỏe đầu ngày, nguồn `/daily-health/parent` (kiểm màn khi làm; ghi Khác plan nếu cần màn mới).
- Tests: `loadProfile_mapsDeclarationAndGuardians`, `loadAttendance_countsHalfDays`, `loadAttendance_requestsCalendarMonth`.

### Task P4: Đánh giá (5 tab)
- Files: C `parent/evaluation/data/live_evaluation_source.dart` · Test C `…/live_evaluation_source_test.dart`.
- Interfaces: `load(childId)` = song song `/daily-assessments?from&to` (8 tuần gần nhất) + `/weekly-comments` + `/evaluations` → `EvaluationBook(weeks, weeklyComments, themes, semesters, yearEnd)`; status `ASSESSED/ABSENT/NOT_RECORDED` → `DayStatus`; `meals` map `MealSession` → `EatingLevel`; hoạt động → `GoalResult` (đạt / cố gắng / chưa đạt).
- Tests: `load_groupsDaysIntoWeeks`, `load_mapsThemeSemesterYearEnd`, `load_noYearEnd_null`.

### Task P5: Khen thưởng
- Files: C `parent/rewards/data/live_reward_source.dart` · M domain/màn theo Q2 · Test C `…/live_reward_source_test.dart`.
- Interfaces: `load(childId)` = `/rewards?from&to` (8 tuần gần nhất) → tuần: cờ từng ngày + phiếu WEEKLY; tháng: phiếu MONTHLY; cuối năm: `yearEndTitles` (danh hiệu, lời cô).
- Tests: `load_weeklyFlagsAndTickets`, `load_monthlyTicket`, `load_yearEndTitles`.

### Task P6: Sổ sức khỏe
- Files: C `parent/health_book/data/live_health_book_source.dart` · M màn chi tiết khám (chỉ hiện mục có dữ liệu) · Test C `…/live_health_book_source_test.dart`.
- Interfaces: `load` = `/health/published` → `rounds` từ `results` có số đo; `exams` từ kết quả khám có `conclusion` (chỉ kết luận, phân loại, mức theo dõi); biểu đồ từ `growth`; xu hướng từ `interpretation`.
- Tests: `load_mapsRoundsAndGrowth`, `load_examOnlyConclusion`.

### Task P7: Kiểm với BE local, docs
- BE `origin/dev` qua `D:\project_capstone\run-be-app-dev.ps1`; script `scripts/check-parent-api.mjs` (mới): đăng nhập PKCE tài khoản phụ huynh seed, gọi từng API ở trên, in shape/status (không in dữ liệu trẻ). Ghi `docs/quality/VERIFICATION.md`, `docs/integration/BE_API_INDEX.md` (sinh lại từ `../be-app-dev`), Progress log.
- Exit: `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0.

## Test matrix
| AC | Rule | Test | Task |
| --- | --- | --- | --- |
| AC-1 | AUTH-04 | `loadChildren_*`, `live_parentChildRoute_unknownChild_notFound`, `live_parentHome_showsRealChildren` | P0 |
| AC-2 | ATT-12 | `submit_postsPartAndEats`, `loadMealPlan_mapsPreview`, `loadNotices_*`, `submit_4031_*` | P1 |
| AC-3 | ATT-15 | `loadToday_mapsAllSixStatuses`, `parentHome_noSchool_showsLabel` | P0, P2 |
| AC-4 | ATT-14 | `loadAttendance_*` | P3 |
| AC-5 | — | test map daily-health (P3) | P3 |
| AC-6 | OBS-36 | `load_groupsDaysIntoWeeks`, `load_mapsThemeSemesterYearEnd` | P4 |
| AC-7 | — | `load_weeklyFlagsAndTickets`, `load_monthlyTicket`, `load_yearEndTitles` | P5 |
| AC-8 | HLT-11 | `load_mapsRoundsAndGrowth`, `load_examOnlyConclusion` | P6 |
| AC-9 | Quyết định 2 | `parentHome_live_hidesCampusAndAge`, test hồ sơ P3 | P2, P3 |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| BE đổi DTO phụ huynh (mới, 24/11) | Map sai, màn lỗi | Test map theo DTO `a58857f2`; P7 gọi thật | Sửa map |
| Phụ huynh nhiều con, mạng chậm | Trang chủ chậm (N lời gọi profile) | Gọi song song, nhớ theo phiên | — |
| Đổi field sang nullable | Màn bản giả lỗi hiển thị | Bản giả vẫn điền đủ; test widget cũ chạy lại | Revert task |
| Dữ liệu thật của trẻ trong log/test | Lộ dữ liệu | Fixture giả; script P7 không in nội dung | — |

## Validation log
- [x] Khẳng định về BE có đường dẫn controller/DTO (`origin/dev` `a58857f2`)
- [x] Không đổi contract BE
- [x] Mỗi AC có test; mỗi task có Exit = `verify.mjs`
- [x] >8 file: chia 8 task, commit nhỏ
- [x] Q1, Q2 user trả lời 25/11

## Progress log
### 2026-11-25 — Plan draft (chờ duyệt)
- User 25/11: đồng ý thứ tự; 3 field thiếu của thẻ bé tạm ẩn; giữ `TBD-4`.
- Tiếp: user trả lời Q1, Q2 và duyệt ⇒ làm P0.

### 2026-11-25 — Plan được duyệt
- User: Q1 "Sắp có", Q2 ẩn quy tắc, duyệt plan, commit nhỏ từng phần, chạy Native tới khi xong.
