---
title: Nối màn bếp với BE (phần BE đã có)
status: approved
owner: Giáp
jira: TBD-4 / FE-FEAT-0
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [kitchen]
rules: [AUTH-05, AUTH-21, AUTH-22, NUT-01, NUT-02, NUT-03, NUT-08, NUT-13, NUT-16, NUT-17, NUT-21, NUT-23, CFG-YR-01]
risk: high
created: 2026-11-25
updated: 2026-11-25
---
# Nối màn bếp với BE (phần BE đã có)

Plan đi kèm: `2026-11-25-account-leave-notification.md` (đổi mật khẩu, hồ sơ, huỷ đơn nghỉ, nút thông báo). Phần BE còn thiếu gửi Thắng: `D:\project_capstone\project\web\DE-XUAT-BE-Thang-dinh-duong-bep-2026-11-25.md`.

## Context
- Mọi màn bếp chạy dữ liệu giả: shell bếp dựng `const KitchenHomeScreen()` và `SchoolMenuScreen` với `FakeParentHomeSource.today` (`lib/routing/app_router.dart:~285-301`); `_kitchenRoutes()` không nhận nguồn (`app_router.dart:574`).
- BE đã có (KITCHEN_STAFF, điểm trường của tài khoản — `KitchenAccess.java:77`):
  - `GET /nutrition/kitchen/day?date` → `dayOff, menuStatus, countStatus, confirmedAt, menu[session, menuBlock, dishes{id,code,name}], servings[session, classroomId, classroomName, normal, substitute]` (chỉ dòng đã xác nhận, NUT-03), `foods[food{name,unit,purchaseUnit…}, storage, quantity]`.
  - `GET /meal-counts?date` → `today` (ngày máy chủ), `schoolDay`, `counts[session, status, needsReconfirmation, confirmedAt, totals{normal, substitute}, classes[ageGroupId…]]`.
  - `/nutrition/food-samples` GET (from, to ≤ 93 ngày) / POST / PUT / `{id}/dispose` (KITCHEN_RECORD); response có `editable`, `disposableFrom`, `disposalStatus`, `status`.
  - `/nutrition/meal-photos` GET `?date`, POST multipart `file` + `session`, `{id}/content`; `/nutrition/meal-photo-windows` (giờ bắt đầu, kết thúc từng bữa); BE giữ **1 ảnh / điểm trường × ngày × bữa**, đăng lại là ghi đè (`MealPhotoServiceImpl.java:122-131`).
  - `GET /age-groups` (bữa của nhóm tuổi).

## Quyết định đã chốt
1. Ảnh suất ăn theo BE: 1 ảnh mỗi điểm trường × ngày × bữa; bỏ thiết kế chụp theo nhóm tuổi — Giáp, 25/11/2026.
2. Tab Thực đơn bếp = phương án B: thực đơn từng ngày theo buổi × khối từ `/nutrition/kitchen/day`; món thay thế theo món chờ Thắng (NUT-23) — Giáp, 25/11/2026.
3. Phần này chỉ nối phần BE đã có; ô năm học bếp chờ Cần mở `GET /school-years` cho bếp — Giáp, 25/11/2026.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** bếp xem số suất đã chốt theo lớp từng bữa, thực đơn đã công bố, lượng thực phẩm; ghi ảnh mẫu (NUT-16) và sổ lưu mẫu (NUT-21); không thấy tên trẻ (AUTH-05). Mọi số do BE tính (NUT-01).
- **Đối chiếu thiết kế ban đầu:** `docs/features/kitchen/README.md` ghi ảnh theo nhóm tuổi, nhiều ảnh (17–18/11) ⇒ đổi theo quyết định 1; tab Thực đơn dùng chung `SchoolMenuScreen` (tuần × nhóm tuổi, định lượng) ⇒ bếp đổi sang màn thực đơn ngày riêng, `SchoolMenuScreen` giữ cho màn Phó HT xem thử.
- **Ảnh hưởng:** chỉ nhóm màn bếp; BGH debug screens không đổi. Không đổi contract BE.

### Câu hỏi mở
(không còn)

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Ảnh theo nhóm tuổi hay theo điểm trường? | Theo BE, 1 ảnh/điểm trường/bữa | Giáp | 25/11 | README bếp (Phase 3) |
| Tab Thực đơn bếp? | B: ngày theo khối, thay thế chờ Thắng | Giáp | 25/11 | README bếp (Phase 4) |
| Giờ "chưa tới bữa / còn N phút"? | Giờ điện thoại chỉ để hiển thị, BE chặn ngoài khung | Giáp | 25/11 | — |
| "Việc hôm nay" trang chủ? | App ghép từ ảnh + sổ lưu mẫu BE trả, chỉ đếm | Giáp | 25/11 | — |

## Acceptance criteria
- **AC-1** (NUT-02, NUT-03): Trang chủ hiện từng bữa đã xác nhận với tổng và số thay thế lấy từ `/meal-counts.totals` khi bữa `CONFIRMED` và không `needsReconfirmation`; bữa đang chờ xác nhận lại ⇒ không hiện số, ghi "Đang chờ PHT xác nhận lại"; chưa bữa nào ⇒ "Chưa có số suất đã chốt hôm nay". `dayOff` ⇒ "Hôm nay trường nghỉ".
- **AC-2** (NUT-17, AUTH-05): Suất ăn theo lớp = `kitchen/day.servings` nhóm theo bữa; không tên trẻ.
- **AC-3** (NUT-01): Lượng thực phẩm = `kitchen/day.foods`, tươi / khô theo `storage`, số + đơn vị BE (App chỉ định dạng); rỗng ⇒ câu trạng thái hiện có.
- **AC-4** (NUT-21): Sổ lưu mẫu: món của bữa từ `kitchen/day.menu`; mẫu hôm nay và mẫu các ngày trước chưa xong huỷ từ `GET /food-samples` (30 ngày gần nhất); nút Sửa theo `editable` BE; Ghi hủy khi `disposalStatus == NONE`; lỗi BE (6047, 6053, 6061, 6062, 6063, 6071) hiện câu `desc`.
- **AC-5** (NUT-16): Ảnh mẫu: mỗi bữa 1 ảnh của điểm trường; chụp ⇒ `POST /meal-photos` (multipart, JPEG ≤ 5 MB); bữa đã có ảnh ⇒ "Chụp lại" có hộp xác nhận (ảnh cũ bị thay); ảnh tải qua `/content` có auth, không lưu vào thư viện máy.
- **AC-6** (NUT-08, NUT-13): Tab Thực đơn: ngày đang chọn (mặc định hôm nay, đổi ngày trong tuần), món theo bữa × khối Nhà trẻ / Mẫu giáo; chưa công bố ⇒ "Thực đơn tuần này chưa công bố".
- **AC-7**: 401 / 403 / 6063 (không có phân công) ⇒ trạng thái lỗi có thử lại, không crash; Xem thử vẫn dùng dữ liệu giả.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Tổng suất từng bữa | `/meal-counts.totals` khi bữa đã chốt và không chờ xác nhận lại | App cộng các lớp | NUT-01: App không cộng; totals là số hiện tại nên chỉ khớp khi không chờ xác nhận lại |
| Nguồn dữ liệu | Mỗi màn 1 `Live…Source` gọi `kitchen/day` / `meal-counts` / `food-samples` / `meal-photos` | 1 nguồn chung có cache | Giống mẫu phụ huynh; mỗi màn tải lại khi mở, đơn giản |
| Ngày "hôm nay" | `meal-counts.today` (ngày máy chủ) | Giờ điện thoại | Tránh lệch ngày khi máy sai giờ |
| Tên điểm trường | Ẩn tới khi BE trả `campusName` (Thắng mục 2) | Hiện `campusId` | Không hiện mã khó hiểu |
| Tab Thực đơn | Màn mới `features/kitchen/kitchen_menu` | Sửa `SchoolMenuScreen` dùng chung | Dữ liệu BE khác hẳn (ngày × khối); không ảnh hưởng màn Phó HT |

## Phases
### Phase 1 — Trang chủ, Suất ăn theo lớp, Lượng thực phẩm
- Files: C `lib/features/kitchen/kitchen_home/data/live_kitchen_home_source.dart` · C `.../kitchen_meals/data/live_kitchen_meals_source.dart` · C `.../food_quantities/data/live_food_quantity_source.dart` · C `lib/routing/kitchen_sources.dart` · M `lib/routing/app_router.dart` · M 3 màn (nhận nguồn) · C tests.
- Tests: AC-1 → `live_kitchen_home_source_test` (đã chốt / chờ xác nhận lại / chưa có / nghỉ); AC-2, AC-3 → test nguồn; AC-7 → `live_ui_router_test` bếp.
- Exit: `node scripts/verify.mjs` → VERIFY PASS.

### Phase 2 — Sổ lưu mẫu
- Files: C `.../food_samples/data/live_food_sample_source.dart` · M `food_samples.dart` (bỏ tự tính `editable`, dùng cờ BE; `disposableNow` = BE `disposalStatus` + `disposableFrom` so ngày máy chủ chỉ để hiển thị) · M màn + tests.
- Tests: AC-4 → test nguồn (GET, POST, PUT, dispose, map lỗi).
- Exit: VERIFY PASS.

### Phase 3 — Ảnh mẫu 1 ảnh mỗi bữa
- Files: M `kitchen_meal_photos.dart` (bỏ nhóm tuổi; `MealPhotoSlot{session, window, photo?}`) · C `live_kitchen_photo_source.dart` · M `fake_kitchen_photo_source.dart`, `meal_sample_photos_screen.dart`, `meal_photo_widgets.dart`, `meal_photos_status.dart` · M `docs/features/kitchen/README.md` · tests.
- Tests: AC-5 → test nguồn (multipart, ghi đè), widget test "Chụp lại" có xác nhận.
- Exit: VERIFY PASS.

### Phase 4 — Tab Thực đơn theo ngày
- Files: C `lib/features/kitchen/kitchen_menu/{domain,data,presentation}` · M `app_router.dart` (tab bếp dùng màn mới) · M README bếp · tests.
- Tests: AC-6 → test nguồn + widget test.
- Exit: VERIFY PASS; `node scripts/check-ai-layer.mjs` (sửa docs).

### Phase 5 — Kiểm trên máy thật
- Tài khoản bếp seed (`kitchen` / `demo123`), BE 8081 (`carenest_scope6`): mở 5 màn, ghi 1 mẫu, chụp 1 ảnh trong khung giờ. Ghi kết quả vào Progress log.

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | NUT-02, NUT-03 | live_kitchen_home_source_test | 1 | |
| AC-2 | NUT-17, AUTH-05 | live_kitchen_meals_source_test | 1 | |
| AC-3 | NUT-01 | live_food_quantity_source_test | 1 | |
| AC-4 | NUT-21 | live_food_sample_source_test | 2 | |
| AC-5 | NUT-16 | live_kitchen_photo_source_test + widget | 3 | |
| AC-6 | NUT-08, NUT-13 | kitchen_menu tests | 4 | |
| AC-7 | — | live_ui_router_test | 1 | |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Seed bếp không có phân công điểm trường ở DB đang dùng | Mọi màn 6063 | Kiểm `staff_assignments` trước Phase 5 | — |
| Ảnh lớn vượt 5 MB | Đăng lỗi | `image_picker` giảm kích thước / chất lượng | — |
| Ghi đè ảnh nhầm | Mất ảnh cũ | Hộp xác nhận "Chụp lại" | — |
| Màn Phó HT xem thử dùng nguồn giả bếp | Hỏng màn debug | Giữ fake source, chỉ đổi domain ảnh tương thích | Revert commit |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Không đổi contract BE; phần thiếu ở file đề xuất Thắng
- [x] Mỗi AC có test; mỗi phase có Exit
- [x] Đã tách plan (bếp / tài khoản + đơn nghỉ + thông báo)
- [x] Không dùng rule PENDING/OPEN
- [x] Tự review

## Progress log
### 2026-11-25 — Phase 1–4 (done, chờ kiểm máy thật)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 503 fail 0 skip 0`
- Kiểm API thật (BE 8081, `carenest_scope6`, tài khoản `kitchen`, chỉ GET): `/nutrition/kitchen/day`, `/meal-counts`, `/nutrition/food-samples`, `/nutrition/meal-photo-windows`, `/nutrition/meal-photos`, `kitchen/day?date` đều 200, tên trường khớp nguồn App.
- Làm: `features/kitchen/shared/kitchen_day_api.dart`; nguồn live Trang chủ, Suất ăn theo lớp, Lượng thực phẩm, Sổ lưu mẫu, Ảnh mẫu, Thực đơn; `kitchen_home/domain/kitchen_tasks.dart` (Việc hôm nay dùng chung bản giả + thật); `routing/kitchen_sources.dart`; màn lỗi hiện câu BE.
- Khác plan: tổng suất từng bữa = `totals.normal + totals.substitute` (BE `nutrition.md`: tổng = normal + substitute), không cộng các lớp; bữa chờ xác nhận lại ẩn khỏi tổng (AC-1, không hiện câu riêng — dùng nhắc "xác nhận một phần" sẵn có); `FoodSample.editable` lấy cờ BE, bản giả vẫn suy; Ảnh mẫu bỏ nhóm tuổi (domain `KitchenPhotoDay.meals`), thêm `KitchenPhotoSource.loadPhoto`; test màn Ảnh mẫu viết lại theo 1 ảnh/bữa.
- Tiếp: Phase 5 — kiểm trên Redmi (tài khoản `kitchen` / `demo123`).
