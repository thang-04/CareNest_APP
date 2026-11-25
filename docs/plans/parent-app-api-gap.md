# Parent app — đối chiếu màn hình với API BE

Ngày: 2026-11-15 · Nguồn: `BE:docs/api/API_INDEX.md`, controller BE (nhánh `dev` 613b0274), `BE:docs/contracts/AUTH_CONTRACT.md`, `BE:docs/contracts/ERROR_CONTRACT.md`, `docs/features/parent/README.md`, Use Case List v3.3 (team).

Status: **EXISTS** = có endpoint phụ huynh gọi được · **PARTIAL** = có nhưng thiếu field/quyền · **MISSING** = chưa có endpoint cho phụ huynh.

## Lưu ý nền

- **Đăng nhập App không dùng `/auth/*`.** `/auth/login` là cổng cho Web, phụ huynh nhận 403 1101. App đăng nhập Keycloak bằng OAuth2 Authorization Code + PKCE, client `carenest-mobile`, redirect `carenest://oauth/callback` (`BE:docs/contracts/AUTH_CONTRACT.md:9,18`). Gọi API kèm `Authorization: Bearer <JWT>`. Access token sống 5 phút; refresh với Keycloak.
- Quyền mặc định của PARENT chỉ có `CHILD_PROFILE_VIEW` (`BE:src/main/java/com/carenest/utils/enums/Permission.java:17-22`), cộng các endpoint ghi rõ `hasRole('PARENT')`.
- Envelope `{code, errorCode?, desc, data}`; xử lý lỗi theo `errorCode`, không theo `desc`. 401 code 1002 ⇒ refresh một lần rồi về đăng nhập; 503 code 1013 ⇒ thử lại, không đăng xuất.
- Base URL dev: `http://<host>:8080/api`.

## Bảng đối chiếu

| Màn (mockup) | UC v3.3 | Dữ liệu / thao tác | Endpoint BE | Status |
| --- | --- | --- | --- | --- |
| P01 Đăng nhập | UC01 | Đăng nhập | Keycloak PKCE (không qua BE) | EXISTS (cần thư viện OAuth, chưa chọn) |
| P01 Kích hoạt lần đầu | UC01 | SĐT + mã + mật khẩu mới | `POST /parent-activation` (public) | EXISTS |
| P15–P17 Quên mật khẩu / OTP / Đặt mật khẩu | UC02 | OTP qua SMS | `/auth/password/*` không gửi OTP cho phụ huynh; BGH cấp mật khẩu tạm (`AUTH_CONTRACT:37`) | **MISSING** cho phụ huynh — màn OTP lệch BE |
| P02 Trang chủ — danh sách con | UC68 | Danh sách con của tài khoản | Không có endpoint riêng; dùng `childIds` trong `GET /accounts/me` rồi gọi `GET /children/{id}` từng bé | PARTIAL (N+1 lần gọi) |
| P02 Trang chủ — tóm tắt hôm nay | UC68 | Điểm danh hôm nay, thực đơn đã công bố, tên hoạt động | — | **MISSING** |
| P13 Hồ sơ bé | UC70 | Hồ sơ, lớp, ảnh | `GET /children/{id}/profile`, `GET /children/{id}/photo/url` | EXISTS |
| P10 Điểm danh tháng | UC68 | Lịch sử Có mặt / Vắng theo bé | Mọi route `/attendance/*` chỉ cho staff | **MISSING** |
| P10 Báo ăn theo ngày | UC68 | Trạng thái ăn (suy từ điểm danh, ATT-02) | — | **MISSING** |
| P05 Thực đơn tuần + ảnh suất | ngoài UC v3.3, cần xác nhận (PAR-01 có) | Thực đơn đã công bố, ảnh mẫu bữa | `/nutrition/meal-plans`, `/nutrition/day-board`: chỉ HT/PHT; ảnh bữa: HT/PHT/bếp | **MISSING** |
| P11 Sức khỏe — cân đo, biểu đồ | UC70 | Kết quả đã công bố, tăng trưởng, diễn giải | `GET /children/{id}/health/published` | EXISTS |
| P08 Sức khỏe trong ngày (HLT-14) | UC70 | Triệu chứng, xử trí | `GET /children/{id}/daily-health` cần `ATTENDANCE_VIEW` (staff) | **MISSING** cho phụ huynh |
| P08 Đánh giá ngày | UC71 | Đánh giá ngày đã lưu (OBS-13) | — | **MISSING** |
| P09 Hoạt động hôm nay | UC71 | Tên hoạt động từ kế hoạch ngày (EDU-09) | — | **MISSING** |
| P12 Phát triển — nhận xét tuần | UC70 | Nhận xét đã gửi | `GET /children/{id}/weekly-comments` (`hasRole('PARENT')`) | EXISTS |
| P12 Phát triển — phiếu bé ngoan, khen thưởng | UC72 | Phiếu tuần/tháng, khen cuối năm đã duyệt | — | **MISSING** |
| P03–P04 Xin nghỉ, đơn đã gửi, huỷ | UC69 | Tạo, xem của tôi, huỷ | `POST /leave-requests`, `GET /leave-requests/me`, `PATCH /leave-requests/{id}/cancel` | EXISTS — APP lệch: bỏ field buổi nghỉ, "GV đã xem" |
| Đón con (PCK-04) | ngoài UC v3.3, cần xác nhận | Ai đón, giờ đón | `GET /pickups/children/{id}` cần `PICKUP_RECORD` (GV) | **MISSING** cho phụ huynh |
| P06–P07 Thông báo | UC05 | Danh sách, đánh dấu đọc | `GET /me/notifications`, `POST .../read`, `POST /me/notifications/read-all` | EXISTS |
| Đăng ký thiết bị push | UC05 | Token FCM/APNs | `PUT/DELETE /me/devices` | EXISTS (push provider chưa chọn) |
| P14, P18 Tài khoản, thông tin cá nhân | UC06 | Xem hồ sơ | `GET /accounts/me` | EXISTS |
| P18 Sửa liên lạc (CHD-05) | UC06 | Sửa thông tin liên lạc của mình | Chỉ có `/parent-accounts/phone-change-requests` (đổi SĐT qua yêu cầu) | PARTIAL |
| Đổi mật khẩu | UC07 | Mật khẩu cũ/mới | `PUT /me/password` | EXISTS |

## UC chưa có màn / màn chưa có UC

- **UC72 Xem khen thưởng cuối năm:** chưa có màn riêng (tab Phát triển có chỗ, BE chưa có API).
- **Màn ngoài UC v3.3:** Thực đơn tuần (P05), Đón con. Rule PAR-01, PCK-04 có, nhưng Use Case List chưa có ⇒ cần team xác nhận.

## API cần đề xuất BE (cho phụ huynh, scope GuardianLink, chỉ dữ liệu đã công bố)

1. `GET /me/children` — danh sách con + tóm tắt hôm nay.
2. Điểm danh + trạng thái ăn theo bé, theo tháng.
3. Thực đơn tuần/ngày đã công bố + ảnh mẫu bữa của cơ sở con học.
4. Sức khỏe trong ngày (HLT-14) cho phụ huynh.
5. Đánh giá ngày đã lưu (OBS-13) và tên hoạt động hôm nay (EDU-09).
6. Phiếu bé ngoan và khen thưởng cuối năm đã duyệt (OBS-10, OBS-14).
7. Lịch sử đón con (PCK-04).
8. Quên mật khẩu phụ huynh: chốt luồng trên App (BE hiện để BGH cấp mật khẩu tạm).
