---
title: Lộ trình hoàn thiện App (phụ huynh, bếp, giáo viên)
status: draft
owner: Giáp
jira: TBD-4 / FE-FEAT-0
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [parent, kitchen, teacher, shared-account, notifications]
rules: [ATT-05b, ATT-12, PCK-04, PAR-01, NUT-16, NUT-23, AUTH-21, AUTH-27, EDU-09]
risk: high
created: 2026-11-26
updated: 2026-11-26
---
# Lộ trình hoàn thiện App

Plan tổng: chia việc còn lại thành các đợt, mỗi đợt có plan con riêng (làn L) hoặc làm thẳng (làn S/M). Không code từ plan này.

## Context — hiện trạng 26/11/2026

| Vai | Đã nối BE | Còn thiếu |
| --- | --- | --- |
| Phụ huynh | Trang chủ, Bé của tôi, điểm danh, đơn nghỉ (gửi, huỷ), đánh giá, khen thưởng, sổ sức khỏe + phiếu khám, ô năm học, nút mở màn từ thông báo | Thực đơn tuần + ảnh suất ăn, hoạt động trong ngày, nút "Gọi giáo viên", tên người đón, phần thêm khen thưởng/đánh giá; **báo nghỉ chiều sau giờ chốt** (mới, từ code Cần) |
| Bếp | Trang chủ, suất ăn theo lớp, lượng thực phẩm, sổ lưu mẫu, ảnh mẫu (1 ảnh/bữa), tab thực đơn ngày | Tên điểm trường, cảnh báo dị ứng theo món, ô năm học (xem năm cũ) |
| Giáo viên | — (0 nguồn live: `lib/features/teacher/*/data` chỉ có dữ liệu giả) | Toàn bộ; plan `2026-11-15-teacher-api-integration.md` (owner Vy Anh, G94-385) |
| Chung | Đăng nhập PKCE, push, thông báo, hồ sơ chỉ xem | Yêu cầu cấp lại mật khẩu, quên mật khẩu SMS (AUTH-27) |

- Kiểm thử: verify 510 pass; **chưa kiểm máy thật** màn bếp, huỷ đơn, nút thông báo.
- PR: App đã push `f633a75`, chưa tạo PR. BE nhánh `fix/G94-180-BE-FIX-10-school-year-scope` local đi trước origin 80 commit (đã gộp G94-236 của Cần), **chưa push**; 6 commit BE của App (phiếu khám, năm học của bé, lọc `schoolYearId`) chưa vào dev ⇒ cần PR BE mới.

## Tác động code Cần vừa gộp (G94-236) lên App

| Thay đổi BE | Ảnh hưởng App | Việc |
| --- | --- | --- |
| ATT-05b (user chốt 25/11): sau giờ chốt phụ huynh vẫn báo nghỉ **buổi chiều hôm nay**; chỉ lưu thông báo, báo GV, không sửa điểm danh/suất; `noticeOnly` mới trong response preview/tạo/danh sách đơn | Form đơn nghỉ hiện đang dựa vào preview; cần hiện đúng "chỉ báo cô" và nhãn ở danh sách | Đợt 1 |
| Huỷ đơn: đơn đã qua hết giờ chốt ⇒ 409 `4024 LEAVE_CANNOT_CANCEL`; đơn `noticeOnly` huỷ được | App đã hiện câu BE; cần test cho 4024 và cho phép huỷ đơn `noticeOnly` | Đợt 1 |
| Đón sớm tính nửa ngày (`EarlyPickupRule`, PCK) | Lịch điểm danh phụ huynh có thể có ngày 0,5 do đón sớm; cần kiểm App hiển thị đúng | Đợt 1 (kiểm) |
| Lịch sinh hoạt / giờ chốt mới (`CutoffResponse`) | Chỉ màn GV (đang giả) | Đợt 4 |
| `EDU_OVERDUE_DIGEST` | Chỉ Hiệu trưởng (Web) | Không |

## Các đợt

### Đợt 0 — Chốt việc đang dở (Giáp, ngay)
1. Kiểm trên Redmi: bếp (`kitchen`), phụ huynh (`0335474254`) — ghi kết quả vào Progress log 2 plan 25/11.
2. Push nhánh BE G94-180, mở PR BE mới vào `dev` (6 commit App + gộp Cần).
3. Tạo PR App (sửa mô tả: phụ thuộc PR BE mới, không phải #113).
- Exit: 2 PR mở, kết quả kiểm máy thật ghi lại.

### Đợt 1 — App-only, BE đã có (Giáp)
1. Báo nghỉ chiều sau giờ chốt (`noticeOnly`): form cho chọn buổi chiều hôm nay khi preview trả `noticeOnly`, câu "Chỉ báo cô giáo, không đổi điểm danh và suất ăn"; danh sách có nhãn; huỷ được.
2. Test lỗi huỷ 4024; kiểm ngày đón sớm 0,5 ở lịch điểm danh.
3. 11 lỗi nhỏ hoãn từ review 25/11 (vd. "Lớp Lớp Nhà trẻ 1", trang chủ trống khi thông báo lỗi, `NOT_RECORDED` bị bỏ…).
4. Sửa tài liệu App còn ghi "món thay thế theo món" ⇒ "cảnh báo dị ứng (chờ Thắng)".
- Làn M (≤8 file) — mini-plan trong chat; Exit: `node scripts/verify.mjs` PASS.

### Đợt 2 — BE phần của Giáp + App (nhánh G94-180)
1. Hồ sơ bé thêm tên điểm trường, cô chủ nhiệm + SĐT ⇒ App nối nút "Gọi giáo viên" (`url_launcher` đã có).
2. Tên người đón cho phụ huynh (PCK-04) — thống nhất với Cần ai thêm vào API điểm danh phụ huynh.
- Làn L (đổi contract BE) ⇒ plan con riêng.

### Đợt 3 — Chờ BE của nhóm, App nối khi có
| Việc | Ai làm BE | App |
| --- | --- | --- |
| `GET /school-years` cho bếp | Cần | Ô năm học bếp, chỉ xem năm cũ |
| Tên điểm trường cho bếp | Thắng (mục 2) | Hiện nhãn điểm trường |
| Cảnh báo dị ứng theo món (NUT-23 sửa) | Thắng (mục 3) | Dòng cảnh báo dưới món ở tab Thực đơn bếp |
| Thực đơn tuần + ảnh suất ăn phụ huynh | Thắng (mục 4) | Bỏ "Sắp có" ở Thực đơn tuần |
| Yêu cầu cấp lại mật khẩu | Thắng (mục 7) | Màn gửi yêu cầu + trạng thái |
| Hoạt động trong ngày (EDU-09) | Tiền | Bỏ "Sắp có" ở Hoạt động |
| Quên mật khẩu SMS (AUTH-27) | gộp nhánh `G94-87` | Nối màn quên mật khẩu |
| Phần thêm khen thưởng / đánh giá | Cần | Ngưỡng, kết quả chủ đề |
- Mỗi mục làn S/M khi BE xong; theo dõi trong bảng này.

### Đợt 4 — App giáo viên nối BE
- Plan sẵn có `2026-11-15-teacher-api-integration.md` (owner Vy Anh). Màn: điểm danh, sức khỏe đầu ngày, đánh giá ngày, đơn nghỉ lớp, đón trẻ, danh sách lớp, cân đo, khen thưởng, năm học.
- Lớn nhất còn lại (≥10 màn). Cần chốt ai làm (câu hỏi 1).

### Đợt 5 — Phát hành
1. Review toàn nhánh (skill review-code), sửa lỗi Critical/Important.
2. Kiểm máy thật đủ 3 vai trên BE dev (VPS) — không chỉ BE local.
3. Build APK release, ghi lại cách cài.
- Exit: verify PASS, checklist máy thật đạt, PR App vào dev được duyệt.

## Câu hỏi mở
- [ ] App giáo viên (đợt 4): Giáp làm, Vy Anh làm, hay chia màn?
- [ ] Đợt 1 mục 1: câu hiển thị cho "báo nghỉ chiều sau giờ chốt" như đề xuất có được không?
- [ ] Mã Jira thật thay cho `TBD-4` trước khi tạo PR?

## Thứ tự đề xuất
Đợt 0 → Đợt 1 (song song gửi đề xuất BE cho Cần, Tiền) → Đợt 2 → Đợt 4 (nếu Giáp làm) → Đợt 3 theo tiến độ nhóm → Đợt 5.

## Validation log
- [x] Hiện trạng có nguồn: `git log`, `ls lib/features/teacher/*/data`, diff BE `21e69a0c..HEAD`
- [x] Mỗi đợt có Exit hoặc dẫn plan con
- [x] >3 phase ⇒ tách plan con theo đợt (đây là plan tổng)
- [x] Không dùng rule PENDING/OPEN; NUT-23 đang chờ Thắng sửa ⇒ đợt 3 chờ

## Progress log
### 2026-11-26 — Đợt 1 (done, chưa commit)
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 520 fail 0 skip 0`
- Đơn nghỉ: `noticeOnly` (form: "Đã qua giờ chốt: đơn chỉ báo cô giáo…", không hỏi ăn, không gửi `eats`; danh sách: "Chỉ báo cô giáo (gửi sau giờ chốt)"), `skippedDates`, `effectiveTo` (huỷ một phần, nút Huỷ theo ngày còn hiệu lực), test 4024.
- Điểm danh: ngày `NOT_RECORDED` có sức khỏe đầu ngày vẫn hiện ("Chưa điểm danh"); bỏ dòng sức khỏe rỗng; nhãn "Nghỉ nửa ngày" (đơn hoặc đón sớm PCK-04); map `pickedUpByName`.
- Trang chủ: số chưa đọc lấy `/me/notifications?limit=1`, lỗi thông báo không làm hỏng trang chủ; ngày hôm nay đọc mỗi lần mở màn.
- Đánh giá: nhãn tuần so theo thứ Hai (tuần bắt đầu sau ngày lễ), tên tuần trống ⇒ "Tuần dd/mm"; kết quả chủ đề ghi lớp lúc học.
- `classLabel` bỏ lỗi "Lớp Lớp …" (seed BE đặt tên lớp có sẵn "Lớp").
- Thông báo bếp: `MENU_CHANGED` icon thực đơn; nút mở Suất ăn theo lớp / tab Thực đơn.
- Script `check-parent-api` không in giới tính / trạng thái thật của bé.
- Không làm: số cờ tuần khi chưa có phiếu (ngoại lệ đã ghi), ngày ghi chú phiếu khám (giữ ngày khám).
- Khác plan: test chủ đề + `classLabel` viết cùng lúc với code (không thấy đỏ trước); đổi ngày của router không có test (cần đồng hồ giả trong router).

### 2026-11-27 — Sau khi gộp G94-385 (Vy Anh, `2568f10`) vào TBD-4 (`bc7a7f3`)
- Trước sửa: analyze sạch, **26 test GV fail** (màn làm lại nhưng test còn tìm chữ cũ: "Đang mở (khóa lúc 08:30)", "Lưu điểm danh", "Chờ PHT xem xét", "Trẻ sau"…), cổng design fail 4 màn GV.
- Design: lỗi ở `scripts/check-design.mjs` — regex `rawNumber` bắt chữ số trong tên hằng (`AppSpacing.space1`). Sửa regex chỉ bắt số đứng riêng + test `check-design.test.mjs` (RED→GREEN); baseline `rawNumber` hạ 55 → 3.
- Test GV viết lại theo giao diện mới, giữ ý định: điểm danh 13, đơn nghỉ lớp 2, danh sách lớp 2, cân đo 5, đón trẻ 2, khen thưởng/`teacher_screens` 4.
- Bỏ test vì hành vi không còn trên màn (cần Vy Anh xác nhận là chủ ý): điểm danh — ô tìm + lọc "Có dấu hiệu cần lưu ý", hỏi "Đổi lớp hoặc ngày?" khi còn thay đổi chưa lưu (giờ đổi ngày là mất thay đổi), hộp xác nhận "Có mặt tất cả", dòng "N trẻ có thay đổi chưa lưu"; danh sách lớp — chip lọc trạng thái; cân đo — lọc Vắng; đón trẻ — tab Chờ đón/Đã đón, nút "Gọi phụ huynh" (`onCall` còn trong constructor nhưng không dùng).
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 617 fail 0 skip 0`; `node --test scripts/__tests__/*.test.mjs` → 62 pass.
- 2026-11-27 Đợt 3 (BE Thắng đã có): **thực đơn tuần phụ huynh** nối `GET /children/{id}/menu` (G94-497, PAR-14) — `LiveWeeklyMenuSource`; domain mới theo contract (bữa theo `MenuSession`, món + `allergens` + `childAllergens`, 1 ảnh/bữa, cờ `published`/`mealsHidden`/`enrolled`/`dayOff`, `unmatchedAllergies`); màn: cảnh báo "Có Cá — bé đã khai dị ứng" (icon + chữ), banner dị ứng chưa khớp, lý do ngày trống theo cờ BE, nút Tuần trước/Tuần sau (`weekStart`), ảnh tải `/meal-photos/{id}/content` (chỉ bộ nhớ), màn xem ảnh 1 ảnh + phóng to. Bỏ giờ ăn, năng lượng, nhóm tuổi, "suất thay thế", lưới nhiều ảnh (`meal_photo_grid.dart` xoá). `MenuMeal` cũ chuyển sang `school_menu` (màn Xem thử BGH/bếp). Ô "Thực đơn" trang chủ phụ huynh: "Đã công bố/Chưa công bố" từ `published` (lỗi ⇒ chưa), hết "Sắp có".
- 2026-11-27 **Tên điểm trường bếp** (G94-496, AUTH-22): `LiveKitchenHomeSource(account:)` lấy `assignments[].campusName` khớp `campusId` của ngày bếp.
- Test mới: `live_weekly_menu_source_test` (RED→GREEN), `live_parent_home_source_test` menu (RED→GREEN), `kitchen_day_sources_test` campus (RED→GREEN), `live_ui_router_test` menu (RED→GREEN); `weekly_menu_photos_test` viết lại sau khi viết màn (không thấy đỏ trước). Verify: `VERIFY PASS full | … | tests 623 fail 0 skip 0`. Chưa thử máy thật (BE 8080 đã tắt lúc kiểm).
