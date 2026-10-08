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

| Role | Dùng app để | Chi tiết |
| --- | --- | --- |
| Parent | Xem thông tin **được nhà trường cho phép** của con (default-deny, ADR-0010); gửi/hủy báo nghỉ cho con, không cần duyệt (ATT-05) | `docs/features/parent/` |
| Teacher | Nhập điểm danh + báo ăn, quan sát hằng ngày, báo sự cố CSVC, xem báo nghỉ của lớp, (duyệt summary nếu làm trên mobile) | `docs/features/teacher/` |
| Kitchen Staff | Xem suất đã chốt, thực đơn đã duyệt, định lượng, dị ứng cần cho nấu | `docs/features/kitchen/` |
| Principal / Vice Principal | Chủ yếu Web; mobile chỉ khi có yêu cầu sau | — |

## Ngoài scope
Chat/nhắn tin (Zalo vẫn dùng), kho/NCC (OPEN — BE ADR-0009, chưa làm), giáo án (GoKids giữ), chẩn đoán y tế, thanh toán, multi-school.

## Stack

| Hạng mục | Trạng thái |
| --- | --- |
| Framework mobile | Flutter — **CONFIRMED** (user, 2026-10-08); quy chuẩn `DESIGN.md` |
| Navigation | `go_router` — CONFIRMED |
| State/cache, HTTP client, secure storage | Chưa chọn — hỏi trước khi chọn |
| Push provider | Chưa chốt (BE `notification` card) |
| Auth mechanism | Chưa chốt (BE `AUTH_CONTRACT.md` SKELETON; coding guide BE định hướng JWT access + refresh, chưa triển khai) |
| BE | Java 21 + Spring Boot + PostgreSQL — CONFIRMED; response `{code, desc, data}` |
