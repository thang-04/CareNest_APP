# State Management

> **Status: CHƯA CÓ NỘI DUNG — không dùng làm nguồn.** Thư viện state/cache chưa chọn. Nguyên tắc dưới đây dùng được; rule chi tiết khi code: `.claude/rules/state.md`.

## Nguyên tắc (dùng được)

| Loại state | Ví dụ | Nguồn sự thật | Ghi chú |
| --- | --- | --- | --- |
| Server state | Điểm danh, thực đơn, số suất, sức khỏe | BE | Cache có key theo user + role + ngữ cảnh + ngày; refetch sau ghi |
| Session | User, role, token | BE (auth) | Token trong secure storage; xóa hết khi logout |
| Ngữ cảnh chọn | Con đang xem, lớp, campus, ngày | Client | Đổi ngữ cảnh ⇒ hủy request cũ |
| Form / nháp | Batch điểm danh đang nhập | Client | Giữ khi lỗi mạng; offline queue chỉ khi đã chốt (xem dưới) |

- Không tính số liệu dẫn xuất ở client (MealCount, FoodQuantityPlan, trend) — BE tính (`BE:docs/modules/nutrition.md`, `health.md`).
- Không optimistic update cho xác nhận/duyệt.

## Điền khi chốt
- [ ] Thư viện server-state/cache + chính sách stale/refetch
- [ ] Thư viện client state (nếu cần)
- [ ] Offline: có hỗ trợ không, cho màn hình nào (PROPOSED: chỉ batch điểm danh/báo ăn của giáo viên), lưu ở đâu, mã hóa
- [ ] Persist cache giữa phiên: có/không (mặc định không cho dữ liệu nhạy cảm)
