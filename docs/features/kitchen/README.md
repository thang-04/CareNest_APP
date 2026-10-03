# Kitchen Staff — màn hình Mobile

Nhân viên bếp chỉ xem **dữ liệu bếp** (suất đã chốt, thực đơn đã duyệt, định lượng) và **dị ứng ở mức cần cho nấu**; không xem hồ sơ trẻ, không sửa điểm danh (`BE:` AUTH-05). Mọi số liệu do BE tính — APP chỉ hiển thị.

Nguồn chung: card `BE:docs/modules/nutrition.md` · flow `BE:docs/business/flows/meal-management.md` · rủi ro `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` CMR-01, CMR-02.

### Suất ăn hôm nay (đã chốt) theo campus / bữa
- BE: rule NUT-01, NUT-02, NUT-03 (CONFIRMED là snapshot bất biến) · ADR-0005
- Endpoint: chưa có
- PENDING: **P-06** bếp riêng từng campus hay trung tâm ⇒ màn hình phải chịu được cả 1 campus và 2 campus (hiển thị theo dữ liệu BE, không hard-code) · P-05 ai xác nhận.
- Chỉ hiển thị MealCount **CONFIRMED**; DRAFT không phải số để nấu.

### Thực đơn đã duyệt
- BE: rule NUT-08 (chỉ APPROVED), NUT-13 / **P-07** (menu chung hay theo campus/nhóm tuổi)
- Endpoint: chưa có
- AI chỉ tạo Menu DRAFT — bếp không thấy DRAFT.

### Định lượng thực phẩm (Fresh / Stored)
- BE: rule NUT-06, NUT-07 (định lượng = suất CONFIRMED × công thức Menu APPROVED), NUT-10 · P-10 (công thức chi tiết)
- Endpoint: chưa có
- Không tính lại ở client; hiển thị đúng đơn vị BE trả. Kho/tồn kho/NCC ngoài V1 (NUT-11, NUT-12, ADR-0009).

### Dị ứng cần cho nấu
- BE: card `docs/modules/child.md` · rule HLT-06, AUTH-05, NUT-09 · P-17 (ai khai báo/xác nhận)
- Chỉ thông tin BE trả cho role bếp. Dị ứng phải hiển thị bằng chữ/icon, không chỉ bằng màu.

### Điều chỉnh suất (adjustment) — **xử lý PENDING**
- BE: rule ATT-07, NUT-03, NUT-04 · **P-04** (báo bếp thế nào, có thêm suất không)
- APP hiển thị adjustment BE trả; không tự cộng/trừ vào số đã chốt. Push báo có điều chỉnh: chỉ deep link (`docs/integration/PUSH_NOTIFICATION.md`).

## Known pitfalls
- Chưa có. Thêm 1 dòng/bẫy, link incident (`docs/knowledge/incidents/`).
