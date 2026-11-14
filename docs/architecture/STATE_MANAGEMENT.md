# State Management

> **Status: CHƯA CÓ NỘI DUNG — không dùng làm nguồn.** Thư viện state đã duyệt: `flutter_riverpod` (user 2026-11-13, chưa thêm vào `pubspec.yaml`); chính sách cache/refetch chưa chốt. Không offline (user 2026-11-14). Nguyên tắc dưới đây dùng được; rule chi tiết khi code: `.claude/rules/state.md`.

## Nguyên tắc (dùng được)

| Loại state | Ví dụ | Nguồn sự thật | Ghi chú |
| --- | --- | --- | --- |
| Server state | Điểm danh, thực đơn, số suất, sức khỏe | BE | Cache có key theo user + role + ngữ cảnh + ngày; refetch sau ghi |
| Session | User, role, token | BE (auth) | Policy PROPOSED: token chỉ trong OS secure storage (Keychain/Keystore), không SharedPreferences; thư viện chưa chọn (DESIGN đề xuất flutter_secure_storage — PROPOSED). Xóa hết khi logout |
| Ngữ cảnh chọn | Con đang xem, lớp, campus, ngày | Client | Đổi ngữ cảnh ⇒ hủy request cũ |
| Form / nháp | Batch điểm danh đang nhập | Client | Giữ trên màn khi lỗi mạng để gửi lại; không lưu xuống máy, không hàng đợi offline (user 2026-11-14) |

- Không tính số liệu dẫn xuất ở client (MealCount, FoodQuantityPlan, trend) — BE tính (`BE:docs/modules/nutrition.md`, `BE:docs/modules/health.md`).
- Không optimistic update cho xác nhận/duyệt.

## Điền khi chốt
- [ ] Chính sách stale/refetch với `flutter_riverpod`
- [x] Offline: không hỗ trợ (user 2026-11-14)
- [ ] Persist cache giữa phiên: có/không (mặc định không cho dữ liệu nhạy cảm)
