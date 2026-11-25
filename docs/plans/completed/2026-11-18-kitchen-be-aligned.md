---
title: Màn bếp theo BE — Trang chủ, Sổ lưu mẫu, suất theo bữa, lượng thực phẩm; bỏ 3 màn BE đã bỏ
status: done         # user 18/11 "làm tiếp cho xong luôn màn bếp" sau khi xem canvas và 4 câu hỏi ⇒ làm một mạch
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # mã tạm của nhánh (plan 2026-11-16) — đổi sang mã Jira thật trước khi mở PR
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [features, routing]
rules: [AUTH-05, AUTH-21, AUTH-22, NUT-02, NUT-03, NUT-10, NUT-11, NUT-12, NUT-13, NUT-14, NUT-16, NUT-21, NUT-22]
risk: medium         # sửa lib/routing (vùng dùng chung): bỏ 3 route bếp, thêm 1 route; dữ liệu giả, không đổi contract BE
created: 2026-11-18
updated: 2026-11-18
---
# Màn bếp theo BE

## Context
- Canvas "Màn bếp theo nhóm tuổi (B)" (https://claude.ai/artifact/33tCbUk6SJ8gae4QqNqqiZ): bảng "Trang chủ bếp (theo BE)" và "Sổ lưu mẫu (NUT-21)". User 18/11: "2 có hãy vẽ", "3 duyệt", rồi "làm tiếp cho xong luôn màn bếp".
- BE origin/dev: `GET /nutrition/kitchen/day` trả `dayOff`, `menuStatus`, `countStatus` (NONE/PARTIAL/CONFIRMED), `confirmedAt`, thực đơn theo buổi và khối (NURSERY/KINDERGARTEN), suất đã xác nhận theo lớp từng buổi (`normal`, `substitute`), lượng thực phẩm cả ngày theo kho (FRESH/DRY) (`BE:src/main/java/com/carenest/dto/meals/KitchenDayResponse.java`). Lưu mẫu `/nutrition/food-samples` GET/POST/PUT, `/{id}/dispose`; PHT duyệt (`FOOD_SAFETY_APPROVE`) (`BE:src/main/java/com/carenest/controller/meals/KitchenRecordsController.java`). Sửa được khi RECORDED và chưa ghi hủy (`FoodSample.isEditable`); hủy sau ≥ 24 giờ (`disposableFrom`).
- App còn màn K05 Nhận nguyên liệu, K06 Báo thiếu, K07 Trạng thái nấu trái BE (NUT-11/12 PHT trên Web, NUT-22 Zalo, NUT-14 REMOVED); K03 chỉ bữa trưa và có banner "chờ duyệt"; K04 có phiếu xuất kho.

## Quyết định đã chốt
1. Trang chủ bếp theo canvas: số suất đã chốt từng bữa (bữa phụ sáng ghi "Nhà trẻ"), "PHT xác nhận hh:mm", "Xem theo lớp"; Việc hôm nay: Ảnh mẫu, Sổ lưu mẫu, Hủy mẫu; Xem nhanh: Suất ăn theo lớp, Lượng thực phẩm, Thực đơn tuần — user 18/11.
2. Sổ lưu mẫu trên App: mỗi bữa ghi món theo thực đơn đã công bố, khối lượng, dụng cụ chứa, nhiệt độ từng món (Mẫu 5); sửa khi chưa duyệt; ghi hủy mẫu khi đến hạn; PHT duyệt trên Web — user 18/11 (canvas).
3. Bỏ K05, K06, K07 khỏi App bếp — user 18/11. `cooking_status` còn được màn Phó HT/HT chỉ debug dùng ⇒ giữ file, chỉ bỏ route và lối vào của bếp.
4. Hiện đủ nội dung, không nút "Xem thêm" (user 18/11).

## Acceptance criteria
- **AC-1** (`NUT-02`, `NUT-03`, `AUTH-05`): Trang chủ bếp hiện số suất đã xác nhận từng bữa, số thay thế, giờ PHT xác nhận; chưa xác nhận ⇒ câu "Chưa có số suất đã chốt"; ngày nghỉ ⇒ "Hôm nay trường nghỉ"; không tên trẻ.
- **AC-2** (`NUT-16`, `NUT-21`): Việc hôm nay tóm tắt ảnh mẫu, lưu mẫu, hủy mẫu theo dữ liệu của hai màn đó; chạm mở đúng màn.
- **AC-3** (`NUT-21`): Sổ lưu mẫu: bữa chưa ghi có form từng món, "Lưu mẫu bữa …"; đã ghi hiện trạng thái như web (Chờ duyệt / Đã duyệt lưu mẫu), "Sửa" khi chưa duyệt; bữa chưa tới ⇒ "Chưa tới bữa"; mẫu đến hạn ⇒ "Ghi hủy mẫu" có hộp xác nhận ⇒ "Chờ duyệt hủy mẫu"; lưu lỗi giữ dữ liệu đã nhập.
- **AC-4** (`NUT-02`, `NUT-13`): Suất ăn theo lớp chọn bữa (phụ sáng / trưa / chiều), tổng, thường, thay thế, bảng lớp; không banner chờ duyệt.
- **AC-5** (`NUT-10`): Lượng thực phẩm cả ngày theo Hàng tươi / Hàng khô, không phiếu xuất kho.
- **AC-6**: `/kitchen/receipts`, `/kitchen/receipts/shortage`, `/kitchen/cooking` không còn; `/kitchen/samples` mới. Đủ trạng thái tải, lỗi + "Thử lại", rỗng; chữ 2,0 không tràn.

## Bản tác động (vùng dùng chung `lib/routing/**`)
- Đổi: bỏ 3 route bếp + hằng đường dẫn, thêm `/kitchen/samples`. `route_paths.dart` dùng ở 15 file, chỉ `kitchen_home_screen.dart` dùng 3 hằng bị bỏ; `app_router.dart` chỉ `lib/app.dart` dùng.
- Luồng: bếp không còn vào Nhận nguyên liệu, Báo thiếu, Trạng thái nấu; vào Sổ lưu mẫu từ Trang chủ. Vai trò khác không đổi.
- Phương án: (a) bỏ route + xoá `ingredient_receipt`, giữ `cooking_status` cho màn debug Phó HT/HT — chọn; (b) xoá cả `cooking_status` ⇒ phải sửa 5 file management ngoài phạm vi bếp; (c) giữ route, ẩn lối vào ⇒ còn màn trái BE.
- Kiểm: `node scripts/verify.mjs`, test router/màn bếp.

## Khoảng trống BE (ghi ở README bếp)
- `KitchenDayResponse` không có tổng suất từng bữa ⇒ lớp dữ liệu cộng theo lớp khi nối, hoặc BE thêm.
- Không có cờ "bữa đã tới / đến hạn hủy" theo giờ máy chủ ⇒ nguồn dữ liệu tính, App không dùng giờ máy.
- Không có API "việc hôm nay" ⇒ lớp dữ liệu ghép từ ảnh mẫu và lưu mẫu.

## Progress log
- 18/11: tạo plan, bắt đầu code (user cho làm một mạch, không dừng giữa phase).
- 18/11: xong. Trang chủ bếp ghép việc từ nguồn ảnh mẫu và sổ lưu mẫu (nguồn giả dùng chung `shared` để quay lại Trang chủ thấy việc đổi); Sổ lưu mẫu mới (`features/kitchen/food_samples`); Suất ăn theo lớp chọn bữa, bỏ banner chờ duyệt; Lượng thực phẩm theo hàng tươi / hàng khô, bỏ phiếu xuất kho; xoá `features/kitchen/ingredient_receipt`; bỏ 3 route, thêm `/kitchen/samples`. Test mới: `test/features/kitchen/food_samples/food_samples_screen_test.dart`, Trang chủ / K03 / K04 trong `test/features/kitchen/kitchen_meals/kitchen_meals_screen_test.dart`, router "Bếp: Trang chủ mở Sổ lưu mẫu; màn BE đã bỏ không còn route".
- Khác plan: thêm giữ thẻ bữa trong tầm nhìn khi form lưu mẫu thu gọn (test lộ ra màn trôi xuống bữa sau); mẫu đến hạn dùng nhãn "Đến hạn hủy" (xanh) thay "Chưa ghi hủy" của web cho khớp việc "Đến hạn" ở Trang chủ.
- Kiểm: `node scripts/verify.mjs` với Flutter 3.47.6 (kết quả ghi ở báo cáo bàn giao).
