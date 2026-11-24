# State Management

> State: `ChangeNotifier` + `StatefulWidget`, dependency qua constructor (CONFIRMED — user 2026-11-24, nền PR #8; Riverpod gỡ 2026-11-25). Rule chi tiết khi code: `.claude/rules/state.md`. Plan: `docs/plans/active/2026-11-16-app-be-integration.md`.

## Nguyên tắc

| Loại state | Ví dụ | Nguồn sự thật | Ghi chú |
| --- | --- | --- | --- |
| Server state | Điểm danh, thực đơn, số suất, sức khỏe | BE | Cache có key theo user + role + ngữ cảnh + ngày; refetch sau ghi |
| Session | User, role, chế độ | BE (auth) | `MobileSession` (`account` = `/accounts/me`) + `LiveModeController` (chế độ); access token chỉ ở bộ nhớ `MobileSession`, refresh token ở `flutter_secure_storage`. Đăng xuất / hết phiên ⇒ xóa phiên và con đang chọn |
| Ngữ cảnh chọn | Con đang xem, lớp, campus, ngày | Client | Đổi ngữ cảnh ⇒ hủy request cũ |
| Form / nháp | Batch điểm danh đang nhập | Client | Giữ khi lỗi mạng; không offline (user 14/11) |

- Không tính số liệu dẫn xuất ở client (MealCount, FoodQuantityPlan, trend) — BE tính (`BE:docs/modules/nutrition.md`, `BE:docs/modules/health.md`).
- Không optimistic update cho xác nhận/duyệt.
- Ghép dependency: màn nhận `source` qua constructor; router chế độ thật (`_buildLiveRouter`) truyền bản `Live<X>Source(api)`, router xem thử dùng `Fake<X>Source`; không `if` trong màn. Test truyền nguồn giả qua constructor.

## Đã chốt
- [x] State/DI: `ChangeNotifier` + constructor (user 2026-11-24; thay `flutter_riverpod` của 13/11)
- [x] Offline: không (user 2026-11-14)
- [x] Persist cache giữa phiên: không; chỉ refresh token và chế độ cuối (`LastModeStore`) trong secure storage
