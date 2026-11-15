---
paths:
  - "lib/features/**/presentation/**/*.dart"
  - "lib/core/widgets/**/*.dart"
  - "lib/core/layouts/**/*.dart"
  - "lib/core/theme/**/*.dart"
  - "lib/core/constants/**/*.dart"
---

# UI style — đồng bộ với web

> Nguồn: `DESIGN.md`. Phần A = Design System chung web + app (chép nguyên từ `CareNest_FE`, **không sửa tay**); Phần B = riêng App. App khác web **chỉ** ở các dòng bảng §B1 (Clay, bo góc, thanh đáy nổi, nhãn tab, bố cục trang chủ/đăng nhập, không UiKitScreen).

- Màu chỉ trong `core/constants/colors.dart`; bóng chỉ `AppShadows`. Widget đọc `Theme.of(context).colorScheme`, `AppStatusColors.of(context)`, `textTheme`. Link dùng `AppStatusColors.primary`, không `colorScheme.primary` (= nền nút `brand`) — §B2.1.
- Số trong `EdgeInsets`, `SizedBox`, `BorderRadius` chỉ là `0` hoặc hằng `AppSpacing` / `AppRadius` / `AppSizes` (§2.3 quy tắc 20, §B2.2). Không `fontSize:`/`fontWeight:` ở feature; không đậm 800.
- Dùng widget `lib/core/widgets/` (§B4.1). Không `ElevatedButton`, `AlertDialog`, `SnackBar`, `ListTile`, `CircleAvatar` trực tiếp ở feature. Thiếu widget ⇒ thêm vào `core/widgets` + widget test, không dựng tạm.
- Icon chỉ qua `AppIcons` (§B4.3); không `Icons.*` ở feature; không emoji.
- Badge: 7 tông `gray/orange/blue/approval/red/green/teal`; nhãn/tông theo bảng map §3.2 — cùng mã BE ⇒ cùng nhãn, tông với web. `approval` chỉ "chờ duyệt". Map ở `features/<f>/presentation/<f>_status.dart`.
- Màu không đứng một mình; không tô đánh giá sức khỏe khi BE không trả nhãn (§2.1 quy tắc 8).
- Một nút chính mỗi vùng, không FAB; nút là động từ (§6.4). Thuật ngữ theo người đọc §10.2.
- Đủ trạng thái §9 / §B7; hành động không hoàn tác có hộp xác nhận.
- Không `BackdropFilter` trong list; không khóa `textScaler`; vùng chạm ≥48.
- Muốn khác web ở điểm mới ⇒ thêm dòng §B1 + đề xuất §B9 trước khi code. Đổi token dùng chung ⇒ sửa Design System web trước (§12).
- Tự kiểm: lệnh §13.2 + checklist §13.3, §B8, rồi `node scripts/verify.mjs`.
