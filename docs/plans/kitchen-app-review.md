# Rà soát App bếp — 18/11/2026

Nhánh làm việc: `feature/G94-385-APP-FEAT-54-teacher-app` (chưa commit; tạo nhánh riêng cho bếp bị chặn trên máy, chờ user). Đối chiếu: BE `docs/business/BUSINESS_RULES.md` (NUT-*, AUTH-05/21/22), `KitchenRecordsController` + DTO (`KitchenDayResponse`, `FoodSampleRequest/Response`, `MealPhotoResponse`, `MealPhotoWindowResponse`) nhánh `dev`; Web `CareNest_FE` (`KitchenTodayPage.jsx`, `FoodSampleQueuePage.jsx`, `MealPhotosPage.jsx`, `kitchenRecordConstants.js`) — Web là màn của BGH, bếp không dùng Web (AUTH-21); Figma `docs/design/figma/kitchen-*.png`.

Kết quả: **OK** · **LỆCH** · **THIẾU** · **CHỜ** (cần user chốt).

## Trước khi sửa
| Màn App | BE / Web | Kết quả |
| --- | --- | --- |
| Trang chủ: thẻ tiến độ nấu, việc "Cập nhật trạng thái nấu" | NUT-14 REMOVED | LỆCH |
| Nhận nguyên liệu, Báo thiếu thực phẩm | NUT-11/12: PHT nhập trên Web; NUT-22: báo qua Zalo/điện thoại | LỆCH |
| Suất ăn: một bữa, ghi chú dị ứng theo lớp, banner "xin +1 chờ duyệt" | `KitchenDayResponse.servings`: theo bữa × lớp, `normal`/`substitute`; không có điều chỉnh chờ duyệt (NUT-03/04) | LỆCH |
| Định lượng + phiếu xuất kho | `foods`: thực phẩm, Hàng tươi/Hàng khô, số lượng; không có phiếu xuất kho | LỆCH |
| Sổ lưu mẫu | NUT-21, `/nutrition/food-samples` (ghi, sửa, ghi hủy sau 24 giờ) | THIẾU |
| Ảnh mẫu theo nhóm tuổi | BE: 1 ảnh mỗi cơ sở × ngày × bữa | CHỜ (user chốt 17/11 theo nhóm tuổi, cần BE đổi) |
| Thực đơn (tab) | `menu` theo bữa × khối | OK (màn dùng chung `SchoolMenuScreen`) |

## Đã sửa (18/11, chưa commit)
- Bỏ màn và route: Nhận nguyên liệu, Báo thiếu thực phẩm, Trạng thái nấu (`/kitchen/receipts`, `/kitchen/receipts/shortage`, `/kitchen/cooking`); xoá feature `ingredient_receipt`, `food_quantities`, màn `KitchenMealsScreen`. Giữ `cooking_status` domain vì màn Phó HT/HT cũ còn dùng (BGH không dùng App — chưa dọn).
- Trang chủ bếp: bỏ thẻ tiến độ nấu. Việc: Thực đơn hôm nay · Suất ăn theo lớp · Thực phẩm cần · Ảnh mẫu bữa ăn · Sổ lưu mẫu.
- Dữ liệu mới `kitchen_day` theo `KitchenDayResponse` (bữa `MORNING/LUNCH/AFTERNOON`, nhãn như Web "Bữa phụ sáng / Bữa trưa / Bữa chiều"; `countStatus` NONE/PARTIAL/CONFIRMED).
- Suất ăn theo lớp: chọn bữa Sáng/Trưa/Chiều; bảng lớp – Thường – Thay thế; "Đã xác nhận lúc HH:mm"; chưa xác nhận ⇒ không hiện số; PARTIAL ⇒ banner "Mới xác nhận một số bữa".
- Thực phẩm cần: nhóm Hàng tươi / Hàng khô, số lượng + đơn vị BE trả.
- Sổ lưu mẫu (mới, `/kitchen/samples`): mỗi bữa hôm nay "Chưa lưu mẫu" ⇒ nút "Lưu mẫu" (chọn món, mặc định đủ món; giờ lấy mẫu mặc định giờ hiện tại, không sau hiện tại; ghi chú ≤500); "Chờ duyệt" ⇒ nút "Sửa"; "Đã duyệt" ⇒ chỉ xem. Mục "Hủy mẫu": mẫu ngày trước — "Chưa đủ 24 giờ" / "Cần hủy" (nút "Ghi hủy", giờ hủy không trước mốc 24 giờ, không sau hiện tại) / "Chờ duyệt hủy". Lỗi mạng giữ sheet và báo lỗi.
- Kiểm tra: `node scripts/verify.mjs` (kết quả ở báo cáo bàn giao); ảnh giả lập `docs/design/screenshots/kitchen/`.

## Lệch còn lại / cần chốt
- **Tổng suất trên App**: App cộng số các lớp để hiện "Tổng suất" (Web không hiện tổng). Chỉ cộng để hiển thị, không tính lại số suất.
- **Dị ứng theo món** (NUT-23): `KitchenDayResponse` chỉ có `substitute` theo lớp, chưa có món thay thế cụ thể — App hiện số suất thay thế; món thay thế xem trong thực đơn.
- **Ghi chú từng món Mẫu 5** (`dishDetails`: khối lượng, dụng cụ, nhiệt độ): BE có; App không nhập để giữ gọn (chốt 18/11) — làm trên Web, có thể bổ sung sau.
- Màn Phó HT/HT cũ trong App (AUTH-21: BGH chỉ dùng Web) vẫn còn code — chờ quyết định PHT/HT.

## App khác Figma (để sửa Figma)
- K01 Trang chủ: bỏ thẻ tiến độ nấu và việc "Nhận nguyên liệu"; thêm "Thực phẩm cần", "Sổ lưu mẫu".
- K03 Suất ăn: thêm chọn bữa Sáng/Trưa/Chiều; bỏ banner điều chỉnh chờ duyệt và ghi chú dị ứng theo lớp.
- K04 Định lượng ⇒ "Thực phẩm cần": bỏ banner phiếu xuất kho, nhóm Hàng tươi / Hàng khô, bỏ cột "dùng cho món".
- K05/K06 Nhận nguyên liệu, Báo thiếu; K07 Trạng thái nấu: bỏ.
- Thêm khung mới: Sổ lưu mẫu + sheet Lưu mẫu + sheet Ghi hủy.
- Ảnh mẫu bữa ăn: bỏ chip nhóm tuổi; mỗi bữa một thẻ, một ảnh khung 4:3, nút "Chụp ảnh" / "Chụp lại".
- Tab Thực đơn bếp: chip nhóm tuổi + chọn bữa; mỗi món một thẻ liệt kê nguyên liệu và gam/trẻ.
- Suất ăn theo lớp: nhóm theo nhóm tuổi, mỗi nhóm có tổng suất.

## Nhóm tuổi và ảnh mẫu (18/11, chưa commit)

User chốt 18/11: ảnh mẫu theo bữa như BE; bếp xem thực đơn theo nhóm tuổi + bữa (món, nguyên liệu); các màn khác chia nhóm tuổi nếu BE có.

| Dữ liệu | BE có chia nhóm tuổi? | Nguồn | App |
| --- | --- | --- | --- |
| Nhóm tuổi ăn bữa nào | Có — `AgeGroup.mealSessions` (NUT-17) | `GET /age-groups` → `AgeGroupDetailResponse.mealSessions`, bếp đọc được (`AgeGroupController.java:37-39`, BE `origin/dev`) | Dùng; khi nối API lấy từ endpoint này |
| Món theo bữa | Theo **khối** Nhà trẻ / Mẫu giáo (`MenuBlock`, NUT-13), không theo từng nhóm Mầm/Chồi/Lá | `/nutrition/kitchen/day` → `menu[].menuBlock` | Chọn nhóm ⇒ hiện món của khối nhóm đó |
| Nguyên liệu + gam/trẻ của món | Có, theo nhóm tuổi (`DishDetailResponse.Ingredient.ageGroupId`, `gramsPerChild` — NUT-18) | `GET /nutrition/dishes/{id}` — **chỉ HT/PHT**, bếp chưa đọc được | Màn Thực đơn hiện nguyên liệu gam/trẻ (dữ liệu giả theo DTO này); cần BE cho bếp đọc hoặc thêm vào `/kitchen/day` |
| Suất ăn theo lớp | Lớp có nhóm tuổi trong `/meal-counts` (`Line.ageGroupId`, bếp đọc được); `/kitchen/day` `ClassServings` **chưa có `ageGroupId`** | `MealCountResponse.Line` | Suất ăn gom theo nhóm tuổi, mỗi nhóm có tổng |
| Thực phẩm cần | Không — tổng ngày theo Hàng tươi/Hàng khô (BE đã tính theo gam từng nhóm tuổi) | `/kitchen/day` → `foods` | Giữ tổng ngày |
| Sổ lưu mẫu | Không — theo cơ sở + ngày + bữa | `FoodSampleResponse` | Giữ theo bữa |
| Ảnh mẫu | Không — 1 ảnh mỗi cơ sở + ngày + bữa, đăng lại thì thay | `MealPhotoResponse`, `POST /meal-photos` | Đã đổi: mỗi bữa 1 ảnh, "Chụp lại" thay ảnh |

Đã sửa:
- Ảnh mẫu bữa ăn: bỏ chip nhóm tuổi; 3 thẻ Bữa phụ sáng / Bữa trưa / Bữa chiều; trạng thái Đã có ảnh / Cần chụp / Chưa tới giờ / Quá giờ, chưa có ảnh; "Đăng HH:mm · Giờ đăng …"; nút "Chụp ảnh", có ảnh thì "Chụp lại" (thay ảnh). Giữ xử lý lỗi camera, đăng lại khi lỗi mạng.
- Tab Thực đơn bếp (mới, thay `SchoolMenuScreen`): chip nhóm tuổi (Nhà trẻ, Mầm, Chồi, Lá), chọn bữa (chỉ các bữa nhóm đó ăn — Lá không có bữa sáng), dòng "Mầm · Bữa trưa · 51 suất", mỗi món một thẻ với nguyên liệu và gam/trẻ của nhóm đó.
- Suất ăn theo lớp: gom theo nhóm tuổi, mỗi nhóm "Mầm · 51 suất".
- Dữ liệu giả thêm lớp Nhà trẻ 1 (18 suất) và món khối Nhà trẻ; nhóm Lá không ăn bữa phụ sáng.

Cần BE (đề xuất, chưa sửa BE — chi tiết `docs/plans/kitchen-be-requests.md`):
1. Cho `KITCHEN_STAFF` đọc nguyên liệu món, hoặc `/kitchen/day` trả `ingredients` (foodName, ageGroupId, gramsPerChild) trong `MenuDish`.
2. (Tùy chọn) `/kitchen/day` `ClassServings` thêm `ageGroupId` — App vẫn ghép được với `/meal-counts`.
- Nhóm tuổi ăn bữa nào: **đã có** ở `GET /age-groups` (`AgeGroupDetailResponse.mealSessions`) — đề xuất cũ bỏ (user nhắc 18/11).

Phụ huynh: màn Thực đơn tuần của phụ huynh vẫn ghi "Ảnh mẫu nhóm …" (dữ liệu giả cũ) — BE không có ảnh theo nhóm tuổi, cần sửa khi làm App phụ huynh.
