# Push Notification — Mobile

> **Status: CHƯA CÓ NỘI DUNG — không dùng làm nguồn.** Push provider (vd. FCM/APNs trực tiếp hoặc dịch vụ trung gian) chưa chốt; endpoint đăng ký device token chưa có. Agent không tự chọn provider/SDK — hỏi.

## Nguyên tắc (dùng được)
- BE quyết định **khi nào** gửi (domain event after-commit → module `notification`, `BE:docs/modules/notification.md`). APP nhận, hiển thị, đăng ký token.
- **Không dữ liệu nhạy cảm trong push**: không tên trẻ kèm dữ liệu sức khỏe/dị ứng/quan sát, không số đo, không nội dung đánh giá. Nội dung chung: "Có cập nhật mới về con", "Số suất hôm nay đã được xác nhận".
- Payload chỉ gồm loại sự kiện + ID cần cho deep link. APP mở màn hình rồi **tải dữ liệu qua API có auth**; BE kiểm tra scope.
- Deep link: kiểm tra đăng nhập + role trước khi mở; ID ngoài scope ⇒ 403/404 ⇒ màn hình lỗi, không crash (`.claude/rules/navigation.md`, `docs/architecture/NAVIGATION.md` mục Deep link).
- Không chat, không nhắn tin 2 chiều (CareNest không thay Zalo).
- Gửi thất bại không ảnh hưởng nghiệp vụ (BE); APP không dựa vào push để đồng bộ dữ liệu — luôn refetch khi mở màn hình.
- Logout ⇒ hủy đăng ký device token (khi BE có endpoint).

## Điền khi chốt
- [ ] Provider + SDK; cấu hình Android/iOS (quyền thông báo, channel)
- [ ] Endpoint đăng ký/hủy device token; gắn token với user/phiên
- [ ] Danh mục loại sự kiện → role nhận → màn hình đích (thống nhất với BE)
- [ ] Hành vi foreground / background / app đã đóng
- [ ] Danh sách thông báo in-app (có lưu ở BE không)
