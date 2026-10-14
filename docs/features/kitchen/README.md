# Kitchen Staff — màn hình Mobile

Nhân viên bếp chỉ xem **dữ liệu bếp** (suất đã chốt, thực đơn đã duyệt, định lượng) và **dị ứng ở mức cần cho nấu**; không xem hồ sơ trẻ, không sửa điểm danh (`BE:` AUTH-05). Mọi số liệu do BE tính — APP chỉ hiển thị.

Nguồn chung: card `BE:docs/modules/nutrition.md` · flow `BE:docs/business/flows/meal-management.md` · rủi ro `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` CMR-01, CMR-02.

### Suất ăn hôm nay (đã chốt) theo campus / bữa
- BE: rule NUT-01, NUT-02, NUT-03 (CONFIRMED là snapshot bất biến) · ADR-0005
- Endpoint: chưa có
- PENDING: **P-06** bếp riêng từng campus hay trung tâm ⇒ màn hình phải chịu được cả 1 campus và 2 campus (hiển thị theo dữ liệu BE, không hard-code) · P-05 ai xác nhận.
- Chỉ hiển thị MealCount **CONFIRMED**; DRAFT không phải số để nấu.
- Mockup K01 / K03 (user 2026-10-13): Trang chủ bếp có số suất đã chốt + giờ chốt; màn "Suất ăn đã chốt" theo lớp (thường / thay thế, ghi chú dị ứng ở mức nấu, không tên trẻ). Điều chỉnh sau giờ chốt hiện **banner chờ duyệt**, bếp vẫn nấu theo số đã xác nhận (NUT-03).
- Trang chủ bố cục D (user 2026-10-14, `docs/design/mobile-redesign-clay.md`): số suất đã chốt chữ rất lớn để đọc từ xa, badge Thường / Thay thế, thẻ tiến độ nấu theo bốn bước `CookingStage` + nút cập nhật, rồi danh sách việc. Wireframe tách thay thế theo chế độ ăn (hải sản, chay…) nhưng dữ liệu hiện chỉ có tổng thay thế ⇒ chưa tách; cần BE trả nếu muốn hiện.

### Thực đơn đã duyệt
- BE: rule NUT-08 (chỉ APPROVED), NUT-13 / **P-07** (thực đơn chung hay theo campus/nhóm tuổi)
- Endpoint: chưa có
- AI chỉ tạo MealPlan (thực đơn) DRAFT — bếp không thấy DRAFT.
- Mockup K02 (tab Thực đơn): dải ngày, nhóm tuổi Nhà trẻ / Mầm / Chồi / Lá, định lượng theo nhóm, thực đơn thay thế (số bé + đổi món, không tên trẻ). Dùng chung màn `SchoolMenuScreen` với Phó HT (V06). Thực đơn theo nhóm tuổi phụ thuộc P-07.

### Định lượng thực phẩm (Fresh / Stored)
- BE: rule NUT-06, NUT-07 (công thức: `BE:docs/business/BUSINESS_RULES.md`), NUT-10 · P-10 (công thức chi tiết)
- Endpoint: chưa có
- Không tính lại ở client; hiển thị đúng đơn vị BE trả. Kho/tồn kho/NCC: OPEN, chưa làm (NUT-11, NUT-12, ADR-0009).
- Mockup K04: bảng thực phẩm cần dùng cho bữa (182 suất) + banner phiếu xuất kho đã duyệt (phiếu thuộc nghiệp vụ nhận nguyên liệu mới, PROPOSED — Q2).

### Trạng thái chuẩn bị + bàn giao suất — **PROPOSED**
- BE: rule NUT-14 (chờ nấu → đang nấu → sẵn sàng bàn giao), NUT-15 (số suất từng lớp, GV xác nhận nhận), NUT-16 (ảnh món) · flow `BE:docs/business/flows/meal-management.md`
- Ảnh bữa ăn — **PROPOSED** (user 2026-10-13): (1) bếp chụp ảnh món khi nấu xong; (2) giáo viên chụp khay khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món ăn trong thực đơn/lịch của con. BE NUT-16 hiện chỉ ghi bếp chụp ⇒ đề xuất cập nhật BE. Mockup K07 chưa có bước chụp ảnh ⇒ đợt này không dựng bước đó.
- Endpoint: chưa có. Màn "Trạng thái nấu" dựng với dữ liệu giả, chỉ có ở bản debug, cho tới khi team chốt (user 2026-10-13, plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`).
- Mockup K07 ghi "Giáo viên không cần thao tác nhận suất" — **lệch NUT-15** (PROPOSED: GV xác nhận số nhận). APP giữ câu theo mockup ở bản giả; cần team chốt một bên.

### Nhận nguyên liệu + báo thiếu thực phẩm — **nghiệp vụ mới, BE chưa ghi**
- Nguồn: user 2026-10-13 ("nghiệp vụ mới"), mockup `docs/design/figma/kitchen-05-06-receive-ingredients-shortage.png`. Mức **PROPOSED** (user 2026-10-13, Q3 plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md`). Phiếu xuất kho (PXK) thuộc nghiệp vụ này (Q2).
- Mockup: bếp nhập số thực nhận theo lô, so với số trên phiếu xuất kho; có chênh lệch ⇒ báo Phó HT; báo thiếu gồm thực phẩm, số lượng, cần trước giờ nào, ảnh hưởng, ghi chú.
- BE gần nhất: NUT-10 (Fresh/Stored, CONFIRMED); NUT-11/12 kho–NCC (OPEN, ADR-0009). Lệch `AGENTS.md` nguyên tắc 8 ⇒ cần BE ghi rule trước khi nối API.
- Endpoint: chưa có. Chênh lệch, "tự báo Phó HT" là hành vi BE; APP chỉ hiển thị.
- APP so số nhập với số phiếu chỉ để nhắc khi nhập (viền đỏ + "Thiếu x kg"); chênh lệch chính thức do BE ghi khi xác nhận. Màn báo thiếu điền sẵn món đang thiếu, gửi cho Phó HT.

### Dị ứng cần cho nấu
- BE: card `BE:docs/modules/child.md` · rule HLT-06, AUTH-05, NUT-09 · P-17 (ai khai báo/xác nhận)
- Chỉ thông tin BE trả cho role bếp. Dị ứng phải hiển thị bằng chữ/icon, không chỉ bằng màu.

### Điều chỉnh suất (adjustment) — **xử lý PENDING**
- BE: rule ATT-07, NUT-03, NUT-04 · **P-04** (báo bếp thế nào, có thêm suất không)
- APP hiển thị adjustment BE trả; không tự cộng/trừ vào số đã chốt. Push báo có điều chỉnh: chỉ deep link (`docs/integration/PUSH_NOTIFICATION.md`).

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
