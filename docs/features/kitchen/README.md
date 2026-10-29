# Kitchen Staff — màn hình Mobile

Nhân viên bếp chỉ xem **dữ liệu bếp của cơ sở mình** (thực đơn đã công bố, số suất đã xác nhận theo lớp từng bữa, định lượng) và **số suất dị ứng/thay thế theo món và lớp, không tên trẻ**; không xem hồ sơ trẻ, không sửa điểm danh (`BE:` AUTH-05, NUT-17, NUT-23). Bếp chỉ dùng App (AUTH-21); mỗi cơ sở bếp riêng, cả tổ bếp dùng chung một tài khoản, lịch sử ghi theo tài khoản (AUTH-22). Việc bếp ghi trên App: ảnh mẫu bữa (NUT-16), sổ lưu mẫu (NUT-21). Mọi số liệu do BE tính — APP chỉ hiển thị. Từ 29/10 bếp giữ màn tối thiểu (AUTH-21, user chốt): số suất theo lớp, thực đơn, ảnh mẫu, sổ lưu mẫu. Màn Định lượng và Dị ứng giữ vì BE USER_ROLES vẫn cho bếp xem; hỏi trước khi thêm màn khác.

Nguồn chung: card `BE:docs/modules/nutrition.md` · flow `BE:docs/business/flows/meal-management.md` · rủi ro `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` CMR-01, CMR-02.

### Suất ăn hôm nay (đã xác nhận) theo lớp / bữa
- BE: rule NUT-01, NUT-02, NUT-03 (CONFIRMED là snapshot bất biến), NUT-17 (số bữa theo nhóm tuổi; bếp xem theo lớp từng bữa) · ADR-0005
- Endpoint: chưa có
- Đã chốt 28/10: mỗi cơ sở bếp riêng, tài khoản bếp gắn một cơ sở (AUTH-05, AUTH-22; đóng P-06) · PHT cơ sở xác nhận số suất, HT thay khi vắng (NUT-02; đóng P-05). Vẫn hiển thị theo dữ liệu BE, không hard-code cơ sở.
- Chỉ hiển thị MealCount **CONFIRMED**; DRAFT không phải số để nấu.
- Mockup K01 / K03 (user 2026-10-13): Trang chủ bếp có số suất đã chốt + giờ chốt; màn "Suất ăn đã chốt" theo lớp (thường / thay thế, ghi chú dị ứng ở mức nấu, không tên trẻ). Điều chỉnh sau giờ chốt hiện **banner chờ duyệt**, bếp vẫn nấu theo số đã xác nhận (NUT-03).
- Lệch BE (28/10): không có điều chỉnh chờ duyệt hay thêm suất cho trẻ muộn (ATT-03, NUT-04); thay đổi chỉ qua PHT mở lại điểm danh rồi xác nhận lại, bếp thấy số mới khi đã xác nhận lại (ATT-08, NUT-03). Dị ứng là số suất theo **món** và lớp (NUT-23), bảng giả chỉ có thường / thay thế theo lớp — cần sửa khi tích hợp.
- Trang chủ bố cục D (user 2026-10-14, `docs/design/mobile-redesign-clay.md`): số suất đã chốt chữ rất lớn để đọc từ xa, badge Thường / Thay thế, thẻ tiến độ nấu theo bốn bước `CookingStage` + nút cập nhật, rồi danh sách việc. Wireframe tách thay thế theo chế độ ăn (hải sản, chay…) nhưng dữ liệu hiện chỉ có tổng thay thế ⇒ chưa tách; cần BE trả nếu muốn hiện.
- Lệch BE (28/10): thẻ tiến độ nấu (NUT-14 REMOVED) và việc "Nhận nguyên liệu" (NUT-11, NUT-12 — PHT ghi trên Web) — cần sửa khi tích hợp.

### Thực đơn đã công bố
- BE: rule NUT-08 (PHT dinh dưỡng công bố; đã công bố không sửa), NUT-13 (một thực đơn chung hai cơ sở; nhà trẻ khác mẫu giáo, các lứa mẫu giáo cùng món khác định lượng; bộ 4 tuần xoay vòng — đóng P-07)
- Endpoint: chưa có
- AI chỉ tạo MealPlan (thực đơn) DRAFT — bếp không thấy DRAFT.
- Mockup K02 (tab Thực đơn): dải ngày, nhóm tuổi Nhà trẻ / Mầm / Chồi / Lá, định lượng theo nhóm, thực đơn thay thế (số bé + đổi món, không tên trẻ). Dùng chung màn `SchoolMenuScreen` với Phó HT (V06). Nhóm tuổi theo NUT-13.

### Định lượng thực phẩm (Fresh / Stored)
- BE: rule NUT-06, NUT-07 (công thức: `BE:docs/business/BUSINESS_RULES.md`), NUT-10, NUT-18 (gam/trẻ theo nhóm tuổi — đóng P-10)
- Endpoint: chưa có
- Không tính lại ở client; hiển thị đúng đơn vị BE trả. Kho khô, kiểm nhận hàng tươi, NCC: PHT ghi trên Web (NUT-11, NUT-12, ADR-0009) — không có trên App bếp.
- Mockup K04: bảng thực phẩm cần dùng cho bữa (182 suất) + banner phiếu xuất kho đã duyệt (phiếu thuộc nghiệp vụ nhận nguyên liệu mới, PROPOSED — Q2).
- Lệch BE (28/10): không còn phiếu xuất kho theo ngày (NUT-11: trừ dự kiến khi công bố + điều chỉnh theo suất chốt) — bỏ banner phiếu khi tích hợp.

### Trạng thái chuẩn bị + bàn giao suất — **REMOVED ở BE (28/10)**
- BE: rule NUT-14 (chờ nấu → đang nấu → sẵn sàng bàn giao), NUT-15 (số suất từng lớp, GV xác nhận nhận), NUT-16 (ảnh món) · flow `BE:docs/business/flows/meal-management.md`
- Ảnh bữa ăn — **PROPOSED** (user 2026-10-13): (1) bếp chụp ảnh món khi nấu xong; (2) giáo viên chụp khay khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món ăn trong thực đơn/lịch của con. BE NUT-16 hiện chỉ ghi bếp chụp ⇒ đề xuất cập nhật BE. Mockup K07 chưa có bước chụp ảnh ⇒ đợt này không dựng bước đó.
- Endpoint: chưa có. Màn "Trạng thái nấu" dựng với dữ liệu giả, chỉ có ở bản debug, cho tới khi team chốt (user 2026-10-13, plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`).
- Mockup K07 ghi "Giáo viên không cần thao tác nhận suất" — **lệch NUT-15** (PROPOSED: GV xác nhận số nhận). APP giữ câu theo mockup ở bản giả; cần team chốt một bên.
- Lệch BE (28/10): NUT-14 và NUT-15 **REMOVED** — không theo dõi trạng thái nấu, không ghi bàn giao; bếp chia suất theo danh sách lớp. NUT-16 CONFIRMED: chỉ bếp chụp ảnh mẫu (mục dưới). Màn K07 (`/kitchen/cooking`) cần bỏ khi tích hợp.

### Nhận nguyên liệu + báo thiếu thực phẩm — **nghiệp vụ mới, BE chưa ghi**
- Nguồn: user 2026-10-13 ("nghiệp vụ mới"), mockup `docs/design/figma/kitchen-05-06-receive-ingredients-shortage.png`. Mức **PROPOSED** (user 2026-10-13, Q3 plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`). Phiếu xuất kho (PXK) thuộc nghiệp vụ này (Q2).
- Mockup: bếp nhập số thực nhận theo lô, so với số trên phiếu xuất kho; có chênh lệch ⇒ báo Phó HT; báo thiếu gồm thực phẩm, số lượng, cần trước giờ nào, ảnh hưởng, ghi chú.
- BE gần nhất: NUT-10 (Fresh/Stored, CONFIRMED); NUT-11/12 kho–NCC (CONFIRMED 28/10, ADR-0009 ACCEPTED).
- Endpoint: chưa có. Chênh lệch, "tự báo Phó HT" là hành vi BE; APP chỉ hiển thị.
- APP so số nhập với số phiếu chỉ để nhắc khi nhập (viền đỏ + "Thiếu x kg"); chênh lệch chính thức do BE ghi khi xác nhận. Màn báo thiếu điền sẵn món đang thiếu, gửi cho Phó HT.
- Lệch BE (28/10): bếp không ghi nhận hàng — PHT nhập kho khô và ghi kiểm nhận hàng tươi trên Web (NUT-11, NUT-12); thiếu nguyên liệu hoặc thiếu/thừa suất báo PHT qua Zalo/điện thoại, hệ thống không ghi (NUT-22). Màn K05/K06 cần bỏ khi tích hợp.

### Ảnh mẫu bữa + sổ lưu mẫu — **chưa có màn**
- BE: rule NUT-16 (bếp chụp ảnh mẫu mỗi bữa trên App, dùng chung toàn trường, phụ huynh xem trong thực đơn ngày — PAR-01), NUT-21 (ghi sổ lưu mẫu thức ăn mỗi bữa) · PENDING P-26 (mẫu sổ) · ADR-0009
- Endpoint: chưa có. Ảnh tải lên theo giới hạn upload BE; chỉ chụp suất ăn, không chụp trẻ.

### Dị ứng cần cho nấu
- BE: card `BE:docs/modules/child.md` · rule HLT-06 (phụ huynh khai khi nhập học, mức nhẹ/nặng — đóng P-17), AUTH-05, NUT-09, NUT-23 (nhẹ ⇒ bỏ món, tăng món khác; nặng ⇒ PHT chọn món thay thế)
- Bếp chỉ thấy số suất dị ứng/thay thế theo món và lớp, không tên trẻ. Chỉ thông tin BE trả cho role bếp. Dị ứng phải hiển thị bằng chữ/icon, không chỉ bằng màu.

### Thay đổi số suất sau xác nhận — **đã chốt (đóng P-04)**
- BE: rule ATT-03, ATT-07, ATT-08, NUT-03, NUT-04, NUT-22. Không bổ sung suất cho trẻ muộn; thay đổi chỉ qua PHT mở lại điểm danh rồi xác nhận lại; bếp làm theo số đã xác nhận lại. Thiếu/thừa thực tế báo qua Zalo, hệ thống không ghi.
- APP hiển thị số BE trả; không tự cộng/trừ vào số đã chốt. Push báo số đã xác nhận lại: chỉ deep link (`docs/integration/PUSH_NOTIFICATION.md`).

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
