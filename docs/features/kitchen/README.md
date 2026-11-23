# Kitchen Staff — màn hình Mobile

Nhân viên bếp chỉ xem **dữ liệu bếp của cơ sở mình** (thực đơn đã công bố, số suất đã xác nhận theo lớp từng bữa, định lượng) và **số suất dị ứng/thay thế theo món và lớp, không tên trẻ**; không xem hồ sơ trẻ, không sửa điểm danh (`BE:` AUTH-05, NUT-17, NUT-23). Bếp chỉ dùng App (AUTH-21); mỗi cơ sở bếp riêng, cả tổ bếp dùng chung một tài khoản, lịch sử ghi theo tài khoản (AUTH-22). Việc bếp ghi trên App: ảnh mẫu bữa (NUT-16), sổ lưu mẫu (NUT-21). Mọi số liệu do BE tính — APP chỉ hiển thị. Từ 29/10 bếp giữ màn tối thiểu (AUTH-21, user chốt): số suất theo lớp, thực đơn, ảnh mẫu, sổ lưu mẫu. Màn Lượng thực phẩm và Dị ứng giữ vì BE USER_ROLES vẫn cho bếp xem; hỏi trước khi thêm màn khác. 18/11: các màn bếp làm lại theo BE (plan `docs/plans/completed/2026-11-18-kitchen-be-aligned.md`), bỏ Nhận nguyên liệu, Báo thiếu, Trạng thái nấu.

Nguồn chung: card `BE:docs/modules/nutrition.md` · flow `BE:docs/business/flows/meal-management.md` · rủi ro `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` CMR-01, CMR-02.

### Trang chủ bếp + suất ăn đã xác nhận theo lớp từng bữa — **màn dữ liệu giả theo BE (18/11)**
- BE: rule NUT-01, NUT-02, NUT-03 (CONFIRMED là snapshot bất biến), NUT-17 (số bữa theo nhóm tuổi; bếp xem theo lớp từng bữa) · ADR-0005
- Endpoint BE đã có, App chưa nối: `GET /nutrition/kitchen/day` (KITCHEN_STAFF, điểm trường của tài khoản) trả `dayOff`, `menuStatus` (NONE / DRAFT / PUBLISHED), `countStatus` (NONE / PARTIAL / CONFIRMED), `confirmedAt`, thực đơn theo buổi và khối (NURSERY / KINDERGARTEN), suất đã xác nhận theo lớp từng buổi (`normal`, `substitute`), lượng thực phẩm cả ngày (`BE:src/main/java/com/carenest/dto/meals/KitchenDayResponse.java`).
- Đã chốt 28/10: mỗi cơ sở bếp riêng, tài khoản bếp gắn một cơ sở (AUTH-05, AUTH-22; đóng P-06) · PHT cơ sở xác nhận số suất, HT thay khi vắng (NUT-02; đóng P-05). Vẫn hiển thị theo dữ liệu BE, không hard-code cơ sở.
- Chỉ hiển thị MealCount **CONFIRMED**; DRAFT và số đang chờ xác nhận lại không phải số để nấu. Thay đổi chỉ qua PHT mở lại điểm danh rồi xác nhận lại (ATT-08, NUT-03, NUT-04) ⇒ không có banner "chờ duyệt" (bỏ 18/11).
- Trang chủ bếp (canvas "Trang chủ bếp (theo BE)", user duyệt 18/11): "Bếp hôm nay" + ngày · điểm trường; thẻ "Số suất đã chốt": mỗi bữa một dòng số lớn (bữa phụ sáng ghi "Nhà trẻ"), số thay thế, nhãn "PHT xác nhận hh:mm", "Xem theo lớp"; chưa xác nhận ⇒ "Chưa có số suất đã chốt hôm nay"; xác nhận một phần ⇒ chỉ bữa đã xác nhận kèm câu nhắc. "Việc hôm nay": Ảnh mẫu bữa ăn (vd. "3/9 phần có ảnh · bữa trưa còn 2 nhóm", Cần chụp), Sổ lưu mẫu (vd. "Bữa trưa chưa ghi · bữa phụ sáng chờ PHT duyệt", Cần ghi), Hủy mẫu (vd. "Mẫu bữa trưa 11/10 hủy được từ 10:40", Đến hạn). "Xem nhanh": Suất ăn theo lớp, Lượng thực phẩm, Thực đơn tuần. Ngày nghỉ ⇒ "Hôm nay trường nghỉ".
- Màn "Suất ăn theo lớp" (`/kitchen/meals`): chọn bữa Phụ sáng / Trưa / Chiều, thẻ Tổng suất · Thường · Thay thế, bảng lớp; bữa phụ sáng ghi chỉ lớp Nhà trẻ ăn. Không tên trẻ, chỉ xem.
- Khoảng trống BE: `KitchenDayResponse` không có tổng suất từng bữa ⇒ khi nối, lớp dữ liệu cộng theo lớp hoặc đề xuất BE trả tổng. Không có API "việc hôm nay" ⇒ lớp dữ liệu ghép từ ảnh mẫu và lưu mẫu (dữ liệu giả đã ghép như vậy: chụp ảnh, ghi mẫu xong quay lại Trang chủ thì việc đổi theo). Dị ứng là số suất theo **món** và lớp (NUT-23), `ClassServings` chỉ có thường / thay thế ⇒ chưa hiện ghi chú dị ứng theo lớp.

### Thực đơn đã công bố
- BE: rule NUT-08 (PHT dinh dưỡng công bố; đã công bố không sửa), NUT-13 (một thực đơn chung hai cơ sở; nhà trẻ khác mẫu giáo, các lứa mẫu giáo cùng món khác định lượng; bộ 4 tuần xoay vòng — đóng P-07)
- Endpoint: chưa có
- AI chỉ tạo MealPlan (thực đơn) DRAFT — bếp không thấy DRAFT.
- Mockup K02 (tab Thực đơn): dải ngày, nhóm tuổi Nhà trẻ / Mầm / Chồi / Lá, định lượng theo nhóm, thực đơn thay thế (số bé + đổi món, không tên trẻ). Dùng chung màn `SchoolMenuScreen` với Phó HT (V06). Nhóm tuổi theo NUT-13.

### Lượng thực phẩm cần trong ngày (hàng tươi / hàng khô) — **màn dữ liệu giả theo BE (18/11)**
- BE: rule NUT-06, NUT-07 (công thức: `BE:docs/business/BUSINESS_RULES.md`), NUT-10, NUT-18 (gam/trẻ theo nhóm tuổi — đóng P-10)
- Endpoint BE đã có, App chưa nối: `foods` trong `GET /nutrition/kitchen/day` = thực phẩm, kho (FRESH / DRY), số lượng cả ngày theo đơn vị gốc, đã cộng thải bỏ; rỗng khi ngày nghỉ, thực đơn chưa công bố hoặc chưa có suất đã xác nhận. Đơn vị mua (`purchaseUnit`) để lớp dữ liệu quy đổi khi hiển thị.
- Màn "Lượng thực phẩm" (`/kitchen/quantities`): thẻ "Hàng tươi" và "Hàng khô" (nhãn như web), mỗi dòng thực phẩm — số lượng; không tính lại ở client. Kho khô, kiểm nhận hàng tươi, NCC: PHT ghi trên Web (NUT-11, NUT-12, ADR-0009) — không có trên App bếp, đã bỏ banner và nút phiếu xuất kho (18/11).

### Trạng thái nấu + bàn giao suất — **REMOVED ở BE (28/10), đã bỏ khỏi App bếp (18/11)**
- BE: rule NUT-14, NUT-15 REMOVED — không theo dõi trạng thái nấu, không ghi bàn giao; bếp chia suất theo danh sách lớp. NUT-16 CONFIRMED: chỉ bếp chụp ảnh mẫu (mục dưới).
- 18/11 (user "làm tiếp cho xong luôn màn bếp"): bỏ route `/kitchen/cooking` và thẻ tiến độ nấu trên Trang chủ bếp. Code `features/kitchen/cooking_status` còn giữ vì màn Phó HT / HT chỉ có ở bản debug (V05, tổng quan HT) còn dùng; bỏ cùng các màn đó.

### Nhận nguyên liệu + báo thiếu thực phẩm — **đã bỏ khỏi App (18/11)**
- BE (28/10): bếp không ghi nhận hàng — PHT nhập kho khô và ghi kiểm nhận hàng tươi trên Web (NUT-11, NUT-12, ADR-0009); thiếu nguyên liệu hoặc thiếu/thừa suất báo PHT qua Zalo/điện thoại, hệ thống không ghi (NUT-22).
- 18/11: xoá màn K05 Nhận nguyên liệu, K06 Báo thiếu (`features/kitchen/ingredient_receipt`) và route `/kitchen/receipts`, `/kitchen/receipts/shortage` (user "làm tiếp cho xong luôn màn bếp").

### Ảnh mẫu bữa theo nhóm tuổi — **màn dữ liệu giả (17/11, bố cục B 18/11)**
- BE: rule NUT-16 (bếp chụp ảnh mẫu mỗi bữa trên App, dùng chung toàn trường, phụ huynh xem trong thực đơn ngày — PAR-01; khung giờ đăng do HT cấu hình, ngoài khung thì chặn), NUT-17 (số bữa theo nhóm tuổi), NUT-21 (ghi sổ lưu mẫu thức ăn mỗi bữa) · PENDING P-26 (mẫu sổ) · ADR-0009
- User 17/11: bếp đăng ảnh **theo nhóm tuổi**. Số ảnh không giới hạn (bếp chụp bao nhiêu cũng được), nhưng **mỗi bữa nhóm đó ăn phải có ít nhất 1 ảnh**. Bữa của từng nhóm theo **cấu hình nhóm tuổi của Hiệu trưởng** (BE `age_groups.meal_sessions`, `/age-groups` chỉ HT sửa; user chốt 18/11, thay ghi chú 17/11 "Phó HT dinh dưỡng"). Seed BE: Nhà trẻ (24–36 tháng) ăn bữa phụ sáng, trưa, chiều; Mẫu giáo bé, nhỡ, lớn ăn trưa, chiều. Lệch tài liệu BE: NUT-17 còn ghi PHT dinh dưỡng cấu hình, code cho HT ⇒ đề xuất sửa NUT-17. Tên buổi như web: "Bữa phụ sáng", "Bữa trưa", "Bữa chiều".
- Màn "Ảnh mẫu bữa ăn" (`/kitchen/photos`, mở từ việc "Ảnh mẫu bữa ăn" trên Trang chủ bếp), bố cục B user duyệt 18/11 (canvas "Màn bếp theo nhóm tuổi (B)"): chọn nhóm tuổi trước. Trên cùng chip điểm trường và thẻ tiến độ ngày ("3/9 phần đã có ảnh mẫu" = số cặp nhóm–bữa có ảnh / tổng số cặp). Ô nhóm tuổi 2 cột: tên, độ tuổi, "đã có ảnh / số bữa nhóm ăn", một vạch mỗi bữa (xanh lá có ảnh, cam đang trong giờ chưa có, xám chưa tới giờ hoặc chưa có giờ, đỏ hết giờ chưa có). Mở màn ⇒ chọn sẵn nhóm đầu tiên còn bữa cần chụp; đang chụp nhóm nào thì giữ nhóm đó. Dưới là tên nhóm, "… · ăn bữa trưa và bữa chiều", rồi dòng thời gian các bữa: thẻ bữa có nhãn chữ (Có N ảnh / Cần chụp / Chưa tới giờ / Quá giờ, chưa có ảnh / Chưa có giờ đăng), giờ đăng ("còn N phút" khi đang mở), vùng chụp lớn viền nét đứt "Chụp ảnh mẫu bữa …" khi chưa có ảnh, lưới ảnh 2 cột kèm giờ đăng và ô "Chụp thêm" khi còn trong giờ. Chưa tới giờ: "Nút chụp mở lúc …". Đang đăng thì vùng chụp chờ, không đăng trùng.
- Hết giờ mà nhóm chưa có ảnh: **chỉ báo đỏ**, không đăng bù (user chốt 18/11; BE chặn ngoài giờ — NUT-16). HT chưa đặt giờ đăng cho bữa: thẻ chìm "Chưa có giờ đăng", nhắc báo Hiệu trưởng đặt trong Cấu hình thời gian. Ngày nghỉ: "Hôm nay trường nghỉ".
- Giờ đăng (chưa đặt / chưa tới / đang mở / đã hết) và số phút còn lại do nguồn dữ liệu trả theo giờ máy chủ, App không tự tính theo giờ máy.
- Phụ huynh xem ảnh theo từng bữa trong Thực đơn tuần, ghi "Ảnh mẫu nhóm …" (`docs/features/parent/README.md`). Dữ liệu giả bếp (18/11) theo tên nhóm tuổi BE (Nhà trẻ, Mẫu giáo bé/nhỡ/lớn); dữ liệu giả phụ huynh còn ghi "Ảnh mẫu nhóm Mầm", có bữa sáng cho mẫu giáo ⇒ chưa khớp, sửa khi làm lại thực đơn phụ huynh.
- Lệch BE: `MealPhoto` hiện theo cơ sở + ngày + buổi (MORNING / LUNCH / AFTERNOON), **1 ảnh mỗi bữa** (đăng lại thì thay file), không theo nhóm tuổi ⇒ cần BE thêm nhóm tuổi và nhiều ảnh mỗi bữa trước khi tích hợp. Mã bữa trên App dùng đúng tên buổi của BE.
- Camera (user duyệt `image_picker` 17/11): nút mở app camera của máy, camera sau, ảnh thu nhỏ cạnh dài 1600 px, JPEG chất lượng 80 (`data/image_picker_camera.dart`). Ảnh vừa chụp hiện ngay trong lưới ảnh của bữa; huỷ chụp thì không đăng; không mở được camera thì báo kiểm tra quyền camera; đăng lỗi thì giữ ảnh (ô viền đỏ "Chưa đăng") và có nút "Đăng lại ảnh" gửi lại đúng ảnh đó (CODING_GUIDE §7.1). Nguồn giả giữ ảnh trong bộ nhớ, mất khi đóng app.
- Chưa làm: phục hồi ảnh khi Android huỷ Activity lúc mở camera (`retrieveLostData`) — máy yếu có thể mất ảnh vừa chụp, bếp chụp lại; nén theo giới hạn upload của BE (chưa chọn gói nén); xoá ảnh chụp nhầm.
- Ý cũ 13/10 (PROPOSED, chưa chốt): giáo viên chụp khay khi bếp giao tới lớp; BE NUT-16 chỉ ghi bếp chụp.
- Endpoint BE đã có (`/nutrition/meal-photos`, `/nutrition/meal-photo-windows`) nhưng theo cơ sở + buổi, chưa theo nhóm tuổi ⇒ chưa nối. Ảnh tải lên theo giới hạn upload BE; chỉ chụp suất ăn, không chụp trẻ.

### Sổ lưu mẫu thức ăn — **màn dữ liệu giả theo BE (18/11)**
- BE: rule NUT-21 (bếp ghi lưu mẫu mỗi bữa, giữ ít nhất 24 giờ rồi ghi hủy; PHT duyệt cả lưu mẫu và hủy mẫu — quyền `FOOD_SAFETY_APPROVE`) · PENDING P-26 (mẫu sổ của trường) — App chỉ ghi các cột BE có.
- Endpoint BE đã có, App chưa nối: `GET /nutrition/food-samples?from&to`, `POST` (ghi), `PUT /{id}` (sửa khi RECORDED và chưa ghi hủy — `FoodSample.isEditable`), `POST /{id}/dispose` (ghi hủy, không trước `disposableFrom` = lấy mẫu + 24 giờ). Mỗi món ghi khối lượng / thể tích, dụng cụ chứa, nhiệt độ bảo quản (Mẫu 5, tối đa 50 / 100 / 50 ký tự); giờ lấy mẫu bỏ trống ⇒ BE lấy lúc ghi.
- Màn "Sổ lưu mẫu" (`/kitchen/samples`, mở từ việc "Sổ lưu mẫu" hoặc "Hủy mẫu" trên Trang chủ bếp; canvas "Sổ lưu mẫu (NUT-21)"): mỗi bữa một thẻ. Chưa ghi ⇒ ô nhập 3 trường cho từng món của thực đơn đã công bố (hiện hết, không thu gọn), dụng cụ chứa và nhiệt độ điền sẵn theo mẫu gần nhất, khối lượng để trống; "Lưu mẫu bữa …", giờ lấy mẫu = lúc bấm lưu. Đã ghi ⇒ nhãn như web "Chờ duyệt lưu mẫu" / "Đã duyệt lưu mẫu", "Lấy mẫu hh:mm · N món", ghi chú từng món; "Sửa lưu mẫu bữa …" khi chưa duyệt (giữ giờ lấy mẫu, có "Hủy sửa"). Bữa chưa tới ⇒ thẻ chìm "Chưa tới bữa". Thực đơn chưa công bố ⇒ báo chưa có món.
- "Mẫu cần hủy": mẫu ngày trước chưa xong hủy. Đến hạn ⇒ "Đến hạn hủy" + "Ghi hủy mẫu" có hộp xác nhận (ghi rồi không sửa được) ⇒ "Chờ duyệt hủy mẫu"; chưa đủ 24 giờ ⇒ "Chưa tới giờ hủy", không có nút. PHT duyệt hủy xong thì mẫu rời danh sách. Nhãn mẫu, sổ lưu và hủy mẫu (Mẫu 4, Mẫu 5) PHT in trên Web.
- Lưu lỗi ⇒ giữ chữ đã nhập, báo dưới nút, bấm lưu lại; lưu / hủy sửa xong form thu gọn và màn giữ thẻ bữa đó trong tầm nhìn.
- Khoảng trống BE: không có cờ "bữa đã tới" và "đã đến hạn hủy" theo giờ máy chủ ⇒ nguồn dữ liệu trả, App không so giờ máy (lớp dữ liệu có thể suy từ giờ đăng ảnh và `disposableFrom` theo giờ máy chủ, hoặc BE thêm cờ).

### Dị ứng cần cho nấu
- BE: card `BE:docs/modules/child.md` · rule HLT-06 (phụ huynh khai khi nhập học, mức nhẹ/nặng — đóng P-17), AUTH-05, NUT-09, NUT-23 (nhẹ ⇒ bỏ món, tăng món khác; nặng ⇒ PHT chọn món thay thế)
- Bếp chỉ thấy số suất dị ứng/thay thế theo món và lớp, không tên trẻ. Chỉ thông tin BE trả cho role bếp. Dị ứng phải hiển thị bằng chữ/icon, không chỉ bằng màu.

### Thay đổi số suất sau xác nhận — **đã chốt (đóng P-04)**
- BE: rule ATT-03, ATT-07, ATT-08, NUT-03, NUT-04, NUT-22. Không bổ sung suất cho trẻ muộn; thay đổi chỉ qua PHT mở lại điểm danh rồi xác nhận lại; bếp làm theo số đã xác nhận lại. Thiếu/thừa thực tế báo qua Zalo, hệ thống không ghi.
- APP hiển thị số BE trả; không tự cộng/trừ vào số đã chốt. Push báo số đã xác nhận lại: chỉ deep link (`docs/integration/PUSH_NOTIFICATION.md`).

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
