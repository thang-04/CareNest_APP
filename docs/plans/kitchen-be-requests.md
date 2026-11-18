# Đề xuất BE cho App bếp — 18/11/2026

Gửi người phụ trách BE. Nguồn: rà soát `docs/plans/kitchen-app-review.md` (mục "Nhóm tuổi và ảnh mẫu"). App bếp hiện chạy dữ liệu giả theo đúng dạng dưới đây; chưa sửa repo BE. Trạng thái: **PROPOSED** — cần BE/user chốt.

Còn thiếu thật sự: **mục 1** (bếp chưa đọc được nguyên liệu + gam/trẻ). Mục 2 tùy chọn.

Bối cảnh: user (18/11) muốn bếp xem "nhóm tuổi này, bữa này có món gì, nguyên liệu gì" và suất ăn gom theo nhóm tuổi. BE đã có dữ liệu nhưng chưa trả cho role `KITCHEN_STAFF` qua App.

## Đã có sẵn ở BE (kiểm lại `origin/dev` 696051b0, 18/11) — không đề xuất
- **Nhóm tuổi ăn bữa nào:** `GET /age-groups` trả `AgeGroupDetailResponse(id, code, name, shortName, sortOrder, ageFromMonths, ageToMonths, mealSessions, mealsPerDay, maxClassSize, nutritionNote)`; cho `KITCHEN_STAFF` (`controller/organization/AgeGroupController.java:37-39`, DTO `dto/organization/AgeGroupDetailResponse.java:14`). App dùng `mealSessions`; khối món suy như `MenuBlock.ofAgeGroup` (`ageToMonths ≤ 36` ⇒ Nhà trẻ).
- **Lớp thuộc nhóm tuổi nào:** `GET /meal-counts` (`MealCountController.java:35-36`, cho `KITCHEN_STAFF`) trả `MealCountResponse.Line.ageGroupId`. App ghép với `/kitchen/day` theo `classroomId` + `session` được, không bắt buộc BE đổi.

## 1. Bếp đọc nguyên liệu + gam/trẻ theo nhóm tuổi
- Rule: NUT-13 (một thực đơn, nhà trẻ khác mẫu giáo, các lứa mẫu giáo cùng món khác định lượng), NUT-18 (món = công thức nguyên liệu + gam/trẻ theo nhóm tuổi), AUTH-05 (bếp chỉ xem dữ liệu bếp, không tên trẻ).
- Hiện tại: `DishDetailResponse.ingredients[]` = `Ingredient(foodId, foodCode, foodName, unit, ageGroupId, gramsPerChild)` có đủ, nhưng `GET /nutrition/dishes`, `GET /nutrition/dishes/{id}` chỉ `PRINCIPAL`, `VICE_PRINCIPAL` (`NutritionDishController`).
- Phương án (chọn 1):
  1. **Đề xuất:** `/nutrition/kitchen/day` trả nguyên liệu trong món: `KitchenDayResponse.MenuDish(id, code, name, List<DishIngredient> ingredients)` với `DishIngredient(foodId, foodName, unit, ageGroupId, gramsPerChild)`. Một lần gọi đủ cho màn Thực đơn bếp; chỉ món đã công bố trong ngày.
  2. Mở `GET /nutrition/dishes/{id}` cho `KITCHEN_STAFF` (chỉ đọc). App phải gọi từng món ⇒ nhiều request; trả cả dinh dưỡng/giá (`nutritionByAgeGroup.cost`) bếp không cần.
- App dùng: thẻ món liệt kê nguyên liệu và "50 g" cho 1 trẻ của nhóm đang chọn. App không nhân ra tổng (NUT-06/07 — tổng do BE tính ở `foods`).

## 2. (Tùy chọn) `/kitchen/day` trả `ageGroupId` cho từng lớp
- Không bắt buộc: App lấy được qua `/meal-counts` (mục trên). Chỉ để App gọi 1 API thay vì 2.
- Đề xuất DTO: `ClassServings(session, classroomId, classroomName, ageGroupId, normal, substitute)`.

## Không đề xuất (giữ như BE)
- Ảnh mẫu bữa ăn: 1 ảnh mỗi cơ sở + ngày + bữa (user chốt 18/11 theo BE).
- Thực phẩm cần (`foods`): tổng ngày theo Hàng tươi/Hàng khô.
- Sổ lưu mẫu: theo cơ sở + ngày + bữa; App không nhập `dishDetails` (khối lượng, dụng cụ, nhiệt độ — Mẫu 5) để giữ gọn, Web/PHT bổ sung nếu cần.

## Ảnh hưởng nếu BE đổi
- BE: `KitchenDayResponse` (+ mapper `KitchenDayServiceImpl`), OpenAPI, test controller/service. Web `KitchenTodayPage.jsx` không bắt buộc đổi (field thêm, không đổi field cũ).
- App: thay nguồn giả `FakeKitchenDaySource` bằng nguồn API; domain `kitchen_day.dart` đã có sẵn field tương ứng.
