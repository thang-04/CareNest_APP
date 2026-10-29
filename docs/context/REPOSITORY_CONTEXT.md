# Repository Context — CareNest_APP

Nguồn: brief CareNest do chủ dự án cung cấp ngày 23/09/2026 + docs BE (source of truth). Nghiệp vụ đầy đủ: `BE:docs/context/PROJECT_CONTEXT.md` (`BE:` = `../CareNest_BE/` hoặc https://github.com/thang-04/CareNest_BE.git).

## CareNest là gì
Nền tảng Web + Mobile cho **Trường Mầm non Thượng Hồng (Hải Phòng)** — **1 trường, 2 điểm trường (campus)**. Không phải multi-school/multi-tenant. Hỗ trợ điểm danh, báo ăn, suất ăn cho bếp, dinh dưỡng, sức khỏe định kỳ, quan sát/phát triển trẻ, báo sự cố CSVC, thông báo. AI chỉ là lớp hỗ trợ có người duyệt.

## Ba repo

| Repo | Vai trò |
| --- | --- |
| `CareNest_BE` | **Source of truth**: business rule (ID + status), domain, authz/scope, API contract, DB, engineering memory nghiệp vụ |
| `CareNest_FE` | Web client — BGH, Giáo viên, System Admin |
| `CareNest_APP` (repo này) | Mobile client — Phụ huynh, Giáo viên, Nhân viên bếp |

## APP sở hữu / không sở hữu

| Sở hữu | Không sở hữu |
| --- | --- |
| Màn hình, navigation theo role, client state/cache | Business rule (suất ăn, định lượng, dị ứng, sức khỏe, hiển thị phụ huynh) |
| Tích hợp API (parse envelope, lỗi, retry, offline) | Authorization / access scope (BE kiểm tra thật) |
| Lưu token & dữ liệu trên thiết bị an toàn | API contract (consumer) |
| Nhận push, đăng ký device token, deep link | Quyết định khi nào gửi push (BE event) |
| Engineering memory lỗi UI/thiết bị (`docs/knowledge/`) | Memory lỗi contract/nghiệp vụ (`BE:docs/knowledge/`) |

## Người dùng Mobile

App chỉ cho Phụ huynh, Giáo viên, Bếp; Ban giám hiệu không dùng App (`BE:` AUTH-21, user chốt 27/10).

| Role | Dùng app để | Chi tiết |
| --- | --- | --- |
| Parent | Đăng nhập bằng SĐT (AUTH-18); một tài khoản xem mọi con (PAR-06); xem thông tin **được nhà trường cho phép** của con (default-deny, ADR-0010; danh sách PAR-01, dữ liệu có công bố PAR-03), thực đơn tuần/ngày kèm ảnh suất (PAR-01); nhận thông báo trường, sức khỏe trong ngày, đã đón con (PAR-05, HLT-14, PCK-04); gửi/hủy báo nghỉ cho con, không cần duyệt (ATT-05); sửa thông tin liên lạc của mình (CHD-05) | `docs/features/parent/` |
| Teacher | Điểm danh chủ yếu trên App (ATT-01; có mặt là ăn — ATT-02) + nhiệt độ đầu ngày (HLT-07), đón trẻ = xác nhận trả trẻ (PCK-02, PCK-04, ATT-10), đánh giá hằng ngày (OBS-01, OBS-02), sức khỏe trong ngày, cân đo (HLT-14, HLT-09), xem báo nghỉ của lớp (không tạo thay — ATT-05), (xác nhận nhận xét định kỳ nếu làm trên mobile — OBS-05) | `docs/features/teacher/` |
| Kitchen Staff | Chỉ App, màn tối thiểu (AUTH-21, user chốt 29/10), 1 tài khoản chung mỗi cơ sở (AUTH-22). Xem thực đơn đã công bố, số suất đã xác nhận theo lớp từng bữa, định lượng, số suất dị ứng/thay thế theo món và lớp không tên trẻ (AUTH-05, NUT-17, NUT-23); chụp ảnh mẫu bữa, ghi sổ lưu mẫu (NUT-16, NUT-21) | `docs/features/kitchen/` |
| Principal / Vice Principal | Không dùng App — chỉ Web (AUTH-21). Màn đã dựng giữ làm tham khảo | `docs/features/principal/`, `docs/features/vice-principal/` |

## Ngoài scope
Chat/nhắn tin (Zalo vẫn dùng), kho/NCC và kiểm nhận hàng (PHT làm trên Web — NUT-11, NUT-12), báo thiếu nguyên liệu/suất (Zalo/điện thoại — NUT-22), soạn/duyệt kế hoạch giáo dục (Web — EDU), CSVC (BE FAC REMOVED 29/10), đăng ký trước người đón hộ (PCK-03), chẩn đoán y tế, thanh toán, multi-school.

## Stack

| Hạng mục | Trạng thái |
| --- | --- |
| Framework mobile | Flutter — **CONFIRMED** (user, 2026-10-08); quy chuẩn `DESIGN.md` |
| Navigation | `go_router` — CONFIRMED |
| State/cache, HTTP client, secure storage | Chưa chọn — hỏi trước khi chọn |
| Push provider | Chưa chốt (BE `notification` card) |
| Auth mechanism | Chưa chốt (BE `AUTH_CONTRACT.md` SKELETON; coding guide BE định hướng JWT access + refresh, chưa triển khai) |
| BE | Java 21 + Spring Boot + PostgreSQL — CONFIRMED; response `{code, desc, data}` |
