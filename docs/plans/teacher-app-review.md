# Rà soát App giáo viên — 17/11/2026

Nhánh `feature/G94-385-APP-FEAT-54-teacher-app` (commit `45cddf1` + thay đổi chưa commit). Đối chiếu: BE `docs/business/BUSINESS_RULES.md`, service/DTO BE (nhánh `dev`), màn Web giáo viên `CareNest_FE` (`AttendancePage.jsx`, `DailyHealthPanel.jsx`, `PickupVerifyFlow.jsx`, `TeacherDashboard.jsx`), chạy thử trên giả lập Pixel 8 Pro.

Kết quả: **OK** · **LỆCH** (khác BE/FE) · **THIẾU** (chưa làm) · **CHỜ** (cần user chốt).

## Điểm danh
| Nghiệp vụ | BE / FE | App | Kết quả | Sửa |
| --- | --- | --- | --- | --- |
| ATT-04/09 — lưu | BE từ chối khi gửi trẻ có đơn nghỉ hoặc EXCUSED do GV gửi (`AttendanceServiceImpl.java:261-272`); FE chỉ gửi dòng đã đổi, bỏ trẻ có đơn (`AttendancePage.jsx:160,280`) | Gửi cả lớp, gồm trẻ có đơn (EXCUSED) và trẻ chưa điểm danh | LỆCH (cao) | Chỉ gửi trẻ không có đơn, đã có Có mặt/Vắng |
| ATT-06/07/08 — khóa | BE trả `canRecord`, `day.locked/schoolDay/unlock`; FE: sửa được khi `canRecord && schoolDay && !locked` | Chỉ hiện nhãn "Khóa lúc"; vẫn sửa sau giờ khóa | THIẾU (cao) | Thêm `locked`, `schoolDay`, `canRecord`; khóa ⇒ chỉ xem + dải "Đã khóa" |
| ATT-02a — tham gia ăn | BE dev 696051b0 (18/11): có mặt mặc định ăn đủ bữa nhóm tuổi; GV gạt tắt "Tham gia ăn" cho cả ngày; `meals` được lưu. Web cột "Tham gia ăn" | Nút "Tham gia ăn (N/M)" mở danh sách công tắc từng trẻ, mặc định bật | OK | Đổi nhãn "Chọn trẻ ăn" ⇒ "Tham gia ăn" như Web |
| ATT-09 — nhãn | FE: Có mặt / Có phép / Không phép / Chưa điểm danh | Có mặt / Có phép / Vắng / Chưa ĐD | LỆCH (thấp) | Đổi "Vắng" ⇒ "Không phép" |
| ATT-04 — trẻ có đơn | FE: tag "Phụ huynh báo nghỉ", không sửa | Đúng | OK | — |
| Dễ dùng | — | 1 nút chính, "Có mặt tất cả", vùng chạm lớn | OK | — |

## Sức khỏe đầu ngày
| Nghiệp vụ | BE / FE | App | Kết quả | Sửa |
| --- | --- | --- | --- | --- |
| HLT-07 — thân nhiệt, enum, ghi chú | 20,0–45,0, 1 số lẻ; ghi chú ≤500 | Đúng | OK | — |
| HLT-14 — Cần lưu ý cần biểu hiện/ghi chú | `DailyHealthServiceImpl.java:160-165`, FE `dailyHealthValidation.js:65-67` | Đúng | OK | — |
| Chuyển cơ sở y tế | Bắt buộc nơi chuyển + giờ (`:166-169`) | Không bắt buộc | LỆCH (TB) | Bắt buộc `place`, `time` |
| HLT-15 — trẻ đã trả | Không ghi thêm khi trẻ đã được trả | Chưa khóa theo từng trẻ | THIẾU (TB) | Khóa trẻ đã trả |
| Cân đo | User 16/11 gom vào Sức khỏe | Lối "Nhập nhanh trong đợt cân đo" | CHỜ | Theo quyết định 16/11 |

## Trả trẻ
| Nghiệp vụ | BE / FE | App | Kết quả | Sửa |
| --- | --- | --- | --- | --- |
| PCK-02 — ảnh phụ huynh | Đối chiếu bằng ảnh (`PickupChildResponse.photoUrl`, FE `PortraitImage`) | Luôn hiện icon, bỏ qua `photoUrl` | LỆCH (cao) | Hiện ảnh từ `photoUrl`; lỗi/không có ảnh ⇒ icon + phải gọi |
| PCK-04 — giờ trả | Bắt buộc, không sau giờ hiện tại; FE cho sửa | Tự lấy giờ hiện tại | THIẾU (TB) | Cho sửa giờ, mặc định giờ hiện tại |
| PCK-01 — chỉ trẻ có mặt | Board có ABSENT/UNMARKED | Màn coi mọi trẻ chưa đón là "Chờ đón" | LỆCH (TB) | Hiện "Vắng hôm nay"/"Chưa điểm danh", tắt nút |
| Ghi chú khi gọi | Bắt buộc ≤500 | Đúng | OK | — |
| Tên màn | FE "Đón trẻ" | "Trả trẻ" | LỆCH (thấp) | Giữ "Trả trẻ" theo user |

## Màn chỉ xem
| Màn | Nghiệp vụ | App | Kết quả | Sửa |
| --- | --- | --- | --- | --- |
| Đánh giá trẻ | OBS-02/15: mỗi mặt có thang riêng (`DailySheetResponse.Row`), KTKN Đạt/Chưa đạt theo mục tiêu; OBS-12 `locked`, `attendanceTaken` | Một thang chung 3 mức cho 7 mặt; "Có mặt 07:42" BE không có | LỆCH (TB) | Map đúng `Row`; bỏ giờ đến |
| Đơn nghỉ lớp | ATT-05: `status` ACTIVE/CANCELLED, `appliedDates`, `skippedDates` | "Mới/Đã xem" tự đặt, không có Đã hủy | LỆCH (TB) | Map theo `status` |
| Khen thưởng | OBS-14: danh hiệu cố định, trạng thái theo danh sách lớp | Có danh hiệu không tồn tại | LỆCH (TB) | Dùng danh hiệu BE |
| Cân đo | HLT-01: kỳ do HT/PHT mở, không theo tháng | Tiêu đề "tháng 10" | LỆCH (thấp) | "Kỳ cân đo" |
| Lịch hoạt động | OBS-07/EDU-09: giáo án ngày đã duyệt | Ghi chú dẫn OBS-08 (đã bỏ) | LỆCH (thấp) | Sửa nguồn |
| Thông báo | `NotificationType` BE | Loại tự đặt, có "Nhắc đo sức khỏe" | LỆCH (thấp) | Map theo BE |
| Lớp học | AUTH-03/OBS-32: nhiều lớp, dạy thay | Một lớp cố định | THIẾU (thấp) | Chọn lớp |
| Trang chủ | PCK-04 không có giờ đón cố định | "Từ 16:30" | LỆCH (thấp) | Bỏ mốc giờ |

## Ưu tiên
- **Cao (làm ngay):** payload điểm danh; khóa điểm danh theo BE; ảnh phụ huynh khi trả trẻ.
- **Chờ user:** giữ hay bỏ "Chọn trẻ ăn"; giữ nhập cân đo trên App.
- **Trung bình:** bắt buộc nơi/giờ chuyển y tế; tắt trả trẻ cho trẻ vắng/chưa điểm danh; sửa giờ trả; model Đánh giá, Đơn nghỉ, Khen thưởng theo DTO BE; khóa sức khỏe khi đã trả trẻ.
- **Thấp:** nhãn "Không phép"; tên kỳ cân đo; loại thông báo; chọn lớp; bỏ "Từ 16:30".

## Đã sửa (17/11, chưa commit)
- Điểm danh: chỉ gửi trẻ không có đơn nghỉ và đã chọn Có mặt/Vắng (ATT-04/09); thêm `canRecord`, `locked`, `schoolDay` ⇒ khóa thì chỉ xem, badge "Đã khóa", ẩn nút lưu (ATT-06/08); thẻ đếm "Không phép" như Web.
- Trả trẻ: hiện ảnh phụ huynh từ `photoUrl` (lỗi/không có ⇒ icon); danh sách hiện "Vắng hôm nay" / "Chưa điểm danh" và không có nút Trả trẻ cho trẻ đó (PCK-01).
- Sức khỏe: chọn "Chuyển cơ sở y tế / cấp cứu" ⇒ bắt buộc nơi chuyển và giờ.
- Kiểm tra: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 195 fail 0 skip 0`.

## Đã sửa — mức trung bình (17/11, chưa commit)
- Đơn nghỉ lớp: model theo `LeaveRequestResponse` (ACTIVE "Đang hiệu lực" / CANCELLED "Đã hủy", `skippedDates` "Không áp dụng"); bỏ "Mới/Đã xem" tự đặt.
- Khen thưởng: model theo `RewardClassDetail` — trạng thái của cả danh sách lớp (nhãn như Web), danh hiệu theo OBS-14, số ngày có mặt, danh hiệu gợi ý ghi "(gợi ý)"; bỏ "Bé tiến bộ", "Bé ngoan toàn diện".
- Trả trẻ: dòng "Giờ trả" sửa được, mặc định giờ hiện tại, không cho sau giờ hiện tại (PCK-04).
- Sức khỏe đầu ngày: bé đã trả (`handedOverAt`) hiện "Đã trả trẻ lúc HH:mm", không mở màn nhập (HLT-15).
- Cân đo (user chốt 17/11 giữ nhập trên App): ràng buộc đã khớp `HealthMeasurementRequest` (40–150 cm, 3–60 kg, ghi chú ≤500, lý do sửa ≤300 bắt buộc); đổi tên kỳ "tháng 10" ⇒ "Kỳ cân đo quý IV" (HLT-01).
- Còn lại: model Đánh giá ngày theo `DailySheetResponse.Row` (mỗi mặt thang riêng); loại thông báo theo `NotificationType`; chọn lớp; "Chọn trẻ ăn" chờ chốt.
- Verify: `VERIFY PASS full | format ok | design ok | analyze ok | tests 197 fail 0 skip 0`.

## Đã sửa — mục còn lại (17/11, chưa commit)
- Đánh giá ngày: dữ liệu theo `DailySheetResponse.Row` — mỗi mặt thang riêng, nhãn như Web: Ăn theo bữa (Ăn hết/Ăn ít/Không ăn), Ngủ trưa (Ngủ tốt/Ngủ ít/Không ngủ), Cảm xúc (Vui vẻ/Bình thường/Buồn/Quấy khóc), Tham gia hoạt động (Tích cực/Bình thường/Chưa tích cực), Sức khỏe; hành vi theo `ObservedBehavior`; bỏ "Có mặt 07:42" và thang "Cần cố gắng" chung. Kiến thức kỹ năng theo MT (Đạt/Chưa đạt) ở tab định kỳ.
- Thông báo GV: chỉ các loại BE `NotificationType` (LEAVE_REQUEST_CHANGED, ATTENDANCE_REMINDER, HEALTH_CHECK_OPENED, ATTENDANCE_DAY_UNLOCKED, REWARD_LIST_UPDATED); thêm field `type`. Bỏ "Bếp đã giao bữa trưa", "Nhắc đo sức khỏe tháng 10".
- Chọn lớp: `SelectedClass` (state, không trong route) + "Đổi lớp ›" trên thẻ lớp khi GV có >1 lớp (chủ nhiệm, dạy thay — OBS-32), như ô "Lớp" trên Web; Điểm danh, Sức khỏe dùng lớp đang chọn; đăng xuất reset. Dữ liệu giả các màn khác vẫn của Mầm 3A.
- Còn chờ user: "Chọn trẻ ăn" (ATT-02).
- Verify: `VERIFY PASS full | format ok | design ok | analyze ok | tests 198 fail 0 skip 0`.

- 17/11 (user chốt): mỗi GV chỉ một lớp ⇒ bỏ "Đổi lớp" và `SelectedClass`; lớp lấy từ lớp được phân công.

## Cập nhật theo BE/FE dev mới (18/11, pull BE 696051b0, FE b76c575b)
- ATT-02a CONFIRMED (BE `a19fa882`, FE `727f10d8`): GV tắt tham gia ăn cho trẻ có mặt, cả ngày một nút ⇒ màn "Tham gia ăn" của App khớp; hết mục chờ "Chọn trẻ ăn". Đổi nhãn nút theo Web.
- Thông báo: `NotificationResponse` thêm `announcementId`, `typeLabel`; thông báo của trường mở `GET /me/announcements/{id}` (`MyAnnouncementResponse`: title, body, sentAt, senderName, attachments) — PAR-07..13. App thông báo dùng chung GV/phụ huynh/bếp: khi nối API hiện `typeLabel` của BE, mở chi tiết theo `announcementId`.
