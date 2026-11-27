---
title: Bếp theo NUT-23 mới (cảnh báo dị ứng) và luồng báo nghỉ chiều sau giờ chốt
status: approved
owner: Giáp
jira: TBD-4 / FE-FEAT-0
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [kitchen, parent]
rules: [NUT-23, AUTH-05, ATT-05b, ATT-12, PCK-04]
risk: medium
created: 2026-11-26
updated: 2026-11-26
---
# Bếp theo NUT-23 mới và luồng báo nghỉ chiều sau giờ chốt

Đối chiếu BE nhánh `fix/G94-180-BE-FIX-10-school-year-scope` sau khi gộp dev + Cần (`1ce2ee9f`, 26/11/2026).

## Context

### A. Việc của Thắng cho App — hiện trạng
| Mục | Trạng thái | Nguồn |
| --- | --- | --- |
| NUT-23 chỉ cảnh báo, bỏ suất thay thế | **Đã có** (G94-483): `substitute` luôn 0 | `BE:docs/business/BUSINESS_RULES.md` NUT-23 |
| Cảnh báo dị ứng cho bếp | **Đã có** (G94-494): `/nutrition/kitchen/day` → `menu[].dishes[].allergens`, `allergyWarnings[{allergen, byClass[{classroomId, classroomName, count}]}]`, `unmatchedAllergies[{name, byClass}]`; đếm trẻ báo ăn đang học theo khai báo, **không theo điểm danh**; không tên trẻ | `BE:dto/meals/KitchenDayResponse.java`, `service/meals/impl/KitchenAllergyWarnings.java` |
| Tên điểm trường cho bếp | Chưa | — |
| Thực đơn tuần + ảnh cho phụ huynh | Chưa (`/meal-photos/week` chỉ HT/PHT) | `KitchenRecordsController.java:192` |
| Yêu cầu cấp lại mật khẩu | Chưa | — |
| Ghi huỷ mẫu năm đã đóng | Chưa | — |

### B. Bé học buổi sáng, 11h phụ huynh gửi đơn nghỉ chiều — BE đang làm gì (ATT-05b, PCK-04)
1. Giờ chốt điểm danh đã qua ⇒ ngày hôm nay **khóa**. Đơn **nghỉ chiều hôm nay** vẫn nhận, BE ghi `noticeOnly = true` (`LeaveRequestServiceImpl` khoảng dòng 226–231): **không** sửa điểm danh, **không** huỷ suất xế (đã chốt), chỉ lưu đơn + báo GV lớp (`LEAVE_REQUEST_CREATED`).
2. Nếu chọn Cả ngày / Buổi sáng / ngày khác đã qua giờ chốt ⇒ 400 `4021` "Không còn ngày học nào trước giờ chốt…".
3. GV vẫn điểm danh bình thường; đơn `noticeOnly` không khóa, không tự đặt nửa buổi (`AttendanceServiceImpl` khoảng dòng 339, 389).
4. Khi GV trả trẻ (`POST /pickups`) **trước mốc tính đủ ngày** (mặc định 15:00, HT cấu hình) ⇒ BE tự ghi bé nghỉ chiều (`absentPart = AFTERNOON`, chuyên cần 0,5) (`PickupServiceImpl.markHalfDayWhenPickedUpBeforeFullDayThreshold`). Trả sau mốc ⇒ đủ ngày.
5. Phụ huynh huỷ đơn `noticeOnly` được (chỉ huỷ thông báo); suất xế vẫn tính.

### C. App hiện tại
- Phụ huynh: form đã hiện "Đã qua giờ chốt: đơn chỉ báo cô giáo…" khi preview trả `noticeOnly`, danh sách có nhãn, huỷ được (`b739a1a`). Thiếu: form mặc định ngày mai (`leave_notice_form_screen.dart:50`), chọn hôm nay + Cả ngày sau giờ chốt chỉ biết lỗi sau khi bấm gửi (preview chỉ chạy cho nửa buổi); trang chủ không cho biết đã báo nghỉ chiều.
- GV: App GV toàn dữ liệu giả ⇒ GV chỉ thấy đơn trên Web. Trả trẻ App (`pickup_verify_screen.dart`) chưa gọi BE.
- Bếp: còn hiện "0 thay thế" (3 màn); chưa hiện cảnh báo dị ứng.

## Quyết định đã chốt
1. NUT-23 chỉ cảnh báo, bỏ suất thay thế — user, 25/11/2026 (BE G94-483).
2. Sau giờ chốt chỉ nhận báo nghỉ chiều của chính hôm nay, không sửa điểm danh/suất — user, 25/11/2026 (ATT-05b).

### Câu hỏi mở
(không còn)

| Câu hỏi | Trả lời | Ai | Ngày |
| --- | --- | --- | --- |
| B1 form sau giờ chốt | Chọn hôm nay ⇒ App xem trước Cả ngày; BE 4021 ⇒ khóa Cả ngày + Buổi sáng, tự chọn Buổi chiều, câu giải thích; hôm nay không học ⇒ khóa cả 3; lỗi mạng ⇒ không khóa | Giáp | 26/11 |
| B2 trang chủ báo nghỉ chiều | Có | Giáp | 26/11 |
| A1 cảnh báo dị ứng | Tab Thực đơn dưới món + 1 dòng nhắc Trang chủ bếp | Giáp | 26/11 |

## Acceptance criteria
- **AC-1** (NUT-23): Bếp không còn chữ "thay thế" ở Trang chủ, Suất ăn theo lớp, tab Thực đơn; tổng suất = `normal`.
- **AC-2** (NUT-23, AUTH-05): tab Thực đơn: món có `allergyWarnings` hiện dòng cảnh báo (biểu tượng + chữ) "Có tôm · Mầm 1: 2 trẻ" theo từng lớp; không tên trẻ; `unmatchedAllergies` hiện cuối ngày "Khai báo chưa khớp danh mục: … (lớp: số trẻ)"; câu "Số trẻ theo khai báo dị ứng, không theo điểm danh; không có cảnh báo không có nghĩa là món an toàn".
- **AC-3** (ATT-05b): form chọn hôm nay sau giờ chốt: Buổi chiều ⇒ câu chỉ báo cô (đã có); Cả ngày/Buổi sáng ⇒ hiện câu BE `4021` ngay, không đợi bấm gửi (nếu B1 = có).
- **AC-4** (ATT-05b): trang chủ phụ huynh có đơn `noticeOnly` hôm nay ⇒ dòng "Đã báo cô nghỉ buổi chiều" (nếu B2 = có).
- **AC-5** (PCK-04): lịch điểm danh hiện nửa ngày sau khi cô trả sớm (đã có nhãn "Nghỉ nửa ngày") — kiểm máy thật.

## Phases
### Phase 1 — Bếp bỏ suất thay thế (AC-1)
- Files: M `kitchen_home` (domain bỏ `substitute`, live, fake, màn), M `kitchen_meals` (cột/dòng thay thế), M `kitchen_menu_screen.dart` (câu chú thích), M `meal_count_table.dart` (dùng chung với màn Phó HT xem thử — giữ cờ ẩn cột) · tests.
- Exit: `node scripts/verify.mjs` PASS.

### Phase 2 — Bếp cảnh báo dị ứng (AC-2)
- Files: M `kitchen_menu` (domain `MenuDish{name, allergens, warnings}`, live map, màn), M `kitchen_meals` (tuỳ A1) · tests nguồn + widget.
- Exit: verify PASS.

### Phase 3 — Phụ huynh báo nghỉ chiều sau giờ chốt (AC-3, AC-4)
- Files: M `leave_notice_form_screen.dart`, `live_leave_notice_source.dart` (preview cả ngày khi chọn hôm nay), M `parent_home` (dòng báo nghỉ) · tests.
- Exit: verify PASS.

### Phase 4 — Kiểm máy thật (AC-5)
- BE 8081 khởi động lại (code đã gộp). Kịch bản: đặt giờ hiện tại sau giờ chốt; phụ huynh `0335474254` gửi nghỉ chiều hôm nay ⇒ GV (Web) thấy đơn ⇒ GV trả trẻ trước 15:00 ⇒ phụ huynh thấy "Nghỉ nửa ngày", suất xế không đổi; bếp `kitchen` thấy cảnh báo dị ứng ở tab Thực đơn.

## Ngoài phạm vi (ghi lại)
- App GV thấy đơn `noticeOnly`, trả trẻ qua BE: thuộc plan GV (`2026-11-15-teacher-api-integration.md`, owner Vy Anh).
- Mục Thắng còn nợ (điểm trường, thực đơn phụ huynh, cấp lại mật khẩu, ghi huỷ mẫu): cập nhật file `D:\project_capstone\project\web\DE-XUAT-BE-Thang-dinh-duong-bep-2026-11-25.md`.

## Validation log
- [x] Khẳng định code có `file:line` (BE sau gộp `1ce2ee9f`)
- [x] Không đổi contract BE
- [x] Mỗi AC có phase + test
- [x] Câu hỏi mở đã trả lời 26/11 ⇒ approved

## Progress log
- 2026-11-26 Phase 1 xong: bếp bỏ "thay thế" (trang chủ, Suất theo lớp một cột SUẤT, footer Thực đơn); tổng = `normal`. Bảng `MealCountTable` có `showAlternative` (màn Phó HT xem thử giữ 2 cột).
- 2026-11-26 Phase 2 xong: tab Thực đơn hiện "Có <chất> · <lớp>: N trẻ" dưới món (icon + chữ), thẻ "Dị ứng đã khai chưa khớp danh mục chất", ghi chú khai báo ≠ điểm danh; Trang chủ bếp 1 dòng "N món hôm nay có trẻ dị ứng · xem ở Thực đơn" mở tab Thực đơn.
- 2026-11-26 Phase 3 xong: `AppSegmented.disabled`; form chọn hôm nay ⇒ preview Cả ngày, 4021 ⇒ preview chiều: được ⇒ khoá Cả ngày + Buổi sáng, tự chọn chiều + câu đã chốt; chiều cũng 4021 ⇒ khoá cả 3 + "Hôm nay không có buổi học", nút gửi tắt; lỗi mạng ⇒ không khoá. Trang chủ PH "Đã báo cô nghỉ buổi chiều" từ `/leave-requests/me` (noticeOnly, chưa huỷ, fromDate = hôm nay).
- 2026-11-26 Verify: `node scripts/verify.mjs` PASS, 531 test.
- 2026-11-26 Phase 4 CHƯA chạy: điện thoại chưa cắm (adb trống); BE 8081 lên nhưng `/auth/login` trả 1013 (gateway Keycloak), không lấy được token để gọi thử. Cần user khởi động lại BE 8081 bằng script rồi thử trên máy thật.
- 2026-11-26 Phase 4 đang chạy: App cài trên máy thật. BE 8081 cũ trả 500 cho `/children/{id}/attendance/today` (BE chạy lẫn code cũ/mới sau merge `1ce2ee9f` đổi số migration) ⇒ user chạy lại BE 8080 trên DB mới `carenest_scope8`, hết 500.
- 2026-11-26 BE mới có luật ATT-05b: từ giờ bắt đầu buổi chiều (`attendance_cutoffs.afternoon_start`, mặc định 13:30) preview/gửi/huỷ nghỉ chiều hôm nay trả 409 `4032`. Form: chiều 4032 ⇒ khoá cả 3 buổi, hiện câu BE, nút gửi tắt (test RED→GREEN). Verify PASS 532 test. Kịch bản test thủ công `../TEST-app-di-ung-nghi-chieu-2026-11-26.md` (SQL lật giờ, đã thử với API thật).
