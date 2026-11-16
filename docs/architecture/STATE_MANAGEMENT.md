# State Management

> Thư viện: `flutter_riverpod` 3.x (CONFIRMED — user 2026-11-13). Rule chi tiết khi code: `.claude/rules/state.md`. Plan: `docs/plans/active/2026-11-16-app-be-integration.md`.

## Nguyên tắc

| Loại state | Ví dụ | Nguồn sự thật | Ghi chú |
| --- | --- | --- | --- |
| Server state | Điểm danh, thực đơn, số suất, sức khỏe | BE | Cache có key theo user + role + ngữ cảnh + ngày; refetch sau ghi |
| Session | User, role, chế độ | BE (auth) | `authControllerProvider` (`AuthState`); token không nằm trong state: access token ở bộ nhớ `SessionManager`, refresh token ở `flutter_secure_storage`. Xóa hết khi đăng xuất |
| Ngữ cảnh chọn | Con đang xem, lớp, campus, ngày | Client | Đổi ngữ cảnh ⇒ hủy request cũ |
| Form / nháp | Batch điểm danh đang nhập | Client | Giữ khi lỗi mạng; không offline (user 14/11) |

- Không tính số liệu dẫn xuất ở client (MealCount, FoodQuantityPlan, trend) — BE tính (`BE:docs/modules/nutrition.md`, `BE:docs/modules/health.md`).
- Không optimistic update cho xác nhận/duyệt.
- Ghép dependency: provider dữ liệu ở `features/<f>/presentation/providers/`; chọn bản giả/thật theo `USE_MOCK` ở provider, không `if` trong màn. Test ghi đè provider (`ProviderContainer(overrides: ...)`).

## Đã chốt
- [x] Thư viện state/DI: `flutter_riverpod` (user 2026-11-13)
- [x] Offline: không (user 2026-11-14)
- [x] Persist cache giữa phiên: không; chỉ refresh token và chế độ cuối (`LastModeStore`) trong secure storage
