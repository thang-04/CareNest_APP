# Navigation — cây màn hình theo role

Mức chi tiết: role → nhóm màn hình. Thư viện navigation chưa chọn; tên route chốt khi có code. Rule nghiệp vụ của từng màn hình: `docs/features/<role>/README.md` (map sang BE). Rule code: `.claude/rules/navigation.md`.

Ký hiệu: **[P]** = PENDING, chưa đăng ký route cho tới khi chốt (hoặc bật bằng cờ) · **[?]** = chỉ làm nếu được yêu cầu.

## Gốc

```text
App
├─ Auth (chưa đăng nhập)      Login · (quên mật khẩu/đổi mật khẩu — chờ AUTH_CONTRACT BE)
└─ Main (đã đăng nhập) → chọn nhánh theo role BE trả về
   ├─ Parent
   ├─ Teacher
   └─ Kitchen
```

Dùng chung mọi role: Thông báo (danh sách in-app, nếu BE có) · Tài khoản/Đăng xuất · Màn hình lỗi: không có quyền (403) / không tìm thấy (404) / mất mạng.

## Parent

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Chọn con / Tổng quan con | Danh sách con có GuardianLink; tóm tắt hôm nay | Chỉ con của mình (AUTH-04) |
| Lịch sử điểm danh | Có mặt/vắng theo ngày | |
| Bữa ăn | Thực đơn/bữa ăn của con | Chỉ field được phép (PAR-02) |
| Sức khỏe | Số đo + trend đã **công bố**; diễn giải chỉ khi đã APPROVED | Không hiển thị AI DRAFT |
| Hoạt động & phát triển | Hoạt động hằng ngày, cập nhật phát triển **đã duyệt** | Field cụ thể [P] P-13b |
| Đơn nghỉ | Tạo/xem đơn | **[P] P-15** — phụ huynh gửi qua app hay GV nhập |

Không có: chat, xem trẻ khác, dữ liệu chưa công bố.

## Teacher

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Chọn lớp / ngày | Lớp được phân công (AUTH-03) | |
| Điểm danh + báo ăn | Nhập hàng loạt cả lớp/ngày; cập nhật trẻ đến muộn | Cut-off [P] P-03 — BE quyết định |
| Quan sát hằng ngày | Nhập hàng loạt theo tiêu chí có cấu trúc + ghi chú | Tiêu chí là data từ BE (P-11) |
| Báo sự cố CSVC | Tạo báo cáo hỏng/thiếu/không đủ + vị trí; xem trạng thái | |
| Đơn nghỉ của lớp | Xem/nhập/duyệt | **[P] P-15** |
| Duyệt summary | Xem/sửa/duyệt summary DRAFT của lớp | **[?]** nếu làm trên mobile |
| Nhập số đo sức khỏe | Chiều cao, cân nặng | **[P]** người nhập chưa chốt (USER_ROLES) |

## Kitchen

| Nhóm màn hình | Nội dung | Ghi chú |
| --- | --- | --- |
| Suất ăn hôm nay | Số suất **đã chốt** theo campus / bữa | Bếp theo campus hay trung tâm [P] P-06 |
| Thực đơn | Thực đơn **đã duyệt** | Menu chung/riêng [P] P-07 |
| Định lượng thực phẩm | Kế hoạch định lượng, tách Fresh / Stored | Chỉ hiển thị BE tính |
| Dị ứng cần cho nấu | Danh sách dị ứng ở mức cần để nấu | Không xem hồ sơ trẻ (AUTH-05) |
| Điều chỉnh suất | Adjustment sau khi chốt | Cách xử lý/báo bếp [P] P-04 |

## Deep link (từ push)

Đích PROPOSED: tổng quan con (Parent) · chi tiết cập nhật mới (Parent) · suất ăn/điều chỉnh (Kitchen) · trạng thái sự cố (Teacher). Payload chỉ có loại + ID; mở màn hình rồi tải qua API (`docs/integration/PUSH_NOTIFICATION.md`).

Thêm/đổi màn hình ⇒ cập nhật file này + feature doc của role.
