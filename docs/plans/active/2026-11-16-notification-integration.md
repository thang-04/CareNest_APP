---
title: Tích hợp thông báo App — spec 902
status: in-progress
owner: Tiền
jira: G94-288 / APP-FEAT-55
branch: feature/G94-288-APP-FEAT-55-notification-client
modules: []
rules: [PAR-03, PAR-05, PAR-07, PAR-11, PAR-12, EDU-73, EDU-74]
risk: high
created: 2026-11-16
updated: 2026-11-18
---
# Tích hợp thông báo App — spec 902

## Phạm vi và quyết định

Ngày 16/11/2026, Tiền yêu cầu implement spec 902, duyệt Firebase Core/Messaging và sau khi đối chiếu AUTH_CONTRACT tiếp tục duyệt `flutter_appauth` cho Keycloak PKCE và `flutter_secure_storage` cho phiên. Không dùng gateway đăng nhập Web cho App. App dùng `carenest-mobile`, redirect `carenest://oauth/callback`, bearer API và quyền do BE quyết định. PAR-03/05/07/11/12 và EDU-73/74 áp dụng; không suy quyền từ payload.

Ảnh hưởng: login/session và router, danh sách/chi tiết thông báo, đăng ký/hủy thiết bị và nhận FCM, cấu hình Android. Dữ liệu cũ của các màn preview phải tiếp tục hoạt động; không đổi API BE. Kiểm thử unit/widget và build Android khi có Flutter SDK; Android thật và Firebase phụ thuộc cấu hình do Tiền cung cấp. Không chạy e2e.

## Các bước

1. Thiết lập SDK được duyệt, đăng nhập PKCE và refresh bảo mật theo AUTH_CONTRACT; API client theo envelope.
2. Đăng ký/refresh/unregister token theo phiên, xử lý mất mạng và đổi tài khoản; không log token.
3. Giữ notificationId qua đăng nhập, tải A20 → A07/A08 qua bearer, chống xử lý trùng theo userId + notificationId.
4. Kiểm thử, đối chiếu 902 và ghi rõ cấu hình Firebase/điện thoại còn thiếu.

## Progress log

- 2026-11-16: Tiền duyệt bốn dependency. SDK Flutter đã xóa; chuẩn bị khôi phục cùng phiên bản 3.47.6 từng dùng, không sửa version công cụ build của repo. Firebase chưa được tạo. Source App trước đó chỉ là preview giả và chưa có phiên thật.
