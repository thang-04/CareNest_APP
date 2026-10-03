# Known Issues & Limitations — CareNest_APP

Lỗi/giới hạn **đang tồn tại** hoặc chưa xử lý triệt để, kể cả chưa rõ root cause. Khi fix xong ⇒ chuyển thành incident + dòng `ISSUE_INDEX.md`, xóa khỏi đây.

| ID | Role / màn hình | Mô tả | Workaround | Trạng thái | Ngày |
| --- | --- | --- | --- | --- | --- |
| KI-001 | toàn app | Chưa có source; framework + thư viện nền chưa chốt | Không áp convention framework khi chưa có source | Mở | 2026-10-03 |
| KI-002 | toàn app | Auth BE và push provider chưa chốt (`AUTH_FLOW.md`, `PUSH_NOTIFICATION.md` SKELETON) | Không tự chọn cơ chế; hỏi | Mở | 2026-10-03 |
| KI-003 | Parent, Teacher, Kitchen | Nhiều màn hình phụ thuộc PENDING (P-03, P-04, P-06, P-07, P-13b, P-15) — xem `docs/context/CURRENT_STATE.md` | UI theo dữ liệu BE trả; không hard-code | Mở | 2026-10-03 |
