---
title: Quyết định nghiệp vụ App 14/11 — đề xuất BE và việc sửa App
status: in-progress
owner: Giáp
jira: G94-332, G94-232, G94-194, G94-334 / FE-FEAT-49   # user chọn 14/11; BE dùng G94-87
branch: feature/G94-194-FE-FEAT-49-app-ui-redraw   # UI redraw chưa vào dev, user chọn làm tiếp nhánh này
modules: [attendance, health, identity-access, notification, nutrition]
rules: [ATT-04, ATT-06, ATT-08, AUTH-21, AUTH-22, AUTH-27, HLT-07, HLT-14, HLT-18, NUT-02, OBS-06, OBS-29, PAR-04, PAR-05, PAR-07, PCK-04]
risk: medium
created: 2026-11-14
updated: 2026-11-14
---
# Quyết định nghiệp vụ App 14/11 — đề xuất BE và việc sửa App

## Context
Ngày 14/11 user chốt các điểm App còn mở. Phần lớn là PENDING trong `BE:docs/business/BUSINESS_RULES.md` (Pending register) hoặc chưa có rule BE. Theo `.ai/workflows/update-knowledge.md` T1, APP không ghi rule: file này giữ đề xuất cho BE và danh sách việc sửa App. Docs App đã cập nhật cùng ngày (`docs/context/CURRENT_STATE.md`, `docs/features/{parent,teacher,kitchen}/README.md`, `docs/architecture/*`, `docs/integration/AUTH_FLOW.md`, `docs/integration/PUSH_NOTIFICATION.md`).

## Quyết định đã chốt
Tất cả do user chốt trong phiên làm việc APP ngày 2026-11-14. Không đảo khi chưa hỏi user.

| # | Chủ đề | Quyết định | Rule BE liên quan |
| --- | --- | --- | --- |
| 1 | P-21 triệu chứng đầu ngày | Giữ danh sách hiện có của BE/Web (`HealthSymptom`): Sốt, Ho, Sổ mũi, Cảm cúm, Mệt mỏi, Khác | HLT-07 |
| 2 | P-22 trẻ bất thường lúc nhận | Như Web: trẻ luôn được nhận (Có mặt, có suất); ghi "Có dấu hiệu cần lưu ý" + xử trí "Báo phụ huynh đón về sớm"; không có "Không nhận" | HLT-07, PCK-04 |
| 3 | P-23 ưu tiên | Must trong Capstone | HLT-07 |
| 4 | Thân nhiệt | Tùy chọn như Web (20,0–45,0 °C); bắt buộc chọn quan sát `NO_CONCERN` / `NOTED` | HLT-07 |
| 5 | P-19 ngày nghỉ theo lịch trường | Khóa điểm danh; App hiện "Hôm nay trường nghỉ". BE đã có code (`NOT_SCHOOL_DAY`, `DayInfoResponse.schoolDay`) | ATT-06, SCH-05 |
| 6 | P-40 mức BMI | Không chỉnh tay; chỉ sửa phiếu cân đo khi kỳ còn mở | HLT-13, HLT-18 |
| 7 | Trẻ vắng không đơn | Như Web: chỉ trạng thái `UNEXCUSED`, không ghi chú; T03 chỉ hiện đơn nghỉ | ATT-09 |
| 8 | Nhãn "Ăn chay" | Bỏ; chỉ hiện dị ứng nhẹ/nặng | HLT-06 |
| 9 | Hủy đơn nghỉ nhiều ngày | Hủy phần còn lại (ngày chưa qua giờ chốt); ngày đã qua giữ Vắng có phép. BE đã có code (`cancelFrom`; không còn ngày hủy được ⇒ `LEAVE_CANNOT_CANCEL`) | ATT-04 |
| 10 | P-32 ý kiến phụ huynh | Không làm trên App | PAR-04 |
| 11 | P-31 phiếu bé ngoan / khen | Phụ huynh chỉ xem khi BE đã công bố (phạm vi làm cả hai vẫn mở) | OBS-10, OBS-14 |
| 12 | Tài khoản nhiều role | Mở chế độ GV; chuyển chế độ phụ huynh ở màn Tài khoản; nhớ chế độ lần cuối | AUTH-21 |
| 13 | Quên mật khẩu | SMS OTP cho phụ huynh, GV, bếp; màn nằm trong App (P-41). Tài khoản bếp: SĐT đăng nhập là SĐT tổ trưởng bếp do HT/PHT nhập, không cần field riêng | AUTH-27, AUTH-22 |
| 14 | Push | Mọi thông báo BE tạo đều push, App không lọc (thay bảng 7 sự kiện); nhận xét định kỳ không push, chỉ nhận xét tuần; thông báo trường (PAR-05) hoãn — `docs/integration/PUSH_NOTIFICATION.md` | PAR-07, OBS-29, PAR-05 |
| 15 | Nền tảng | Sản phẩm Android + iOS; Capstone chỉ build Android | — |
| 16 | Offline | Không | — |

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** actor GV, phụ huynh, bếp trên App · outcome: rule App khớp Web/BE · rule ở bảng trên.
- **Đối chiếu thiết kế ban đầu:** P-21 nháp (ARR-03) có tiêu chảy, phát ban, đau bụng, đau mắt — user bỏ, giữ enum Web. HLT-07 ghi "đo nhiệt độ mọi trẻ" nhưng Web/BE để thân nhiệt tùy chọn — user chọn theo Web. AUTH-19 chỉ nói phụ huynh — user mở rộng cho GV, bếp.
- **Ảnh hưởng:** BE rule + register (đề xuất dưới) · `APP: Điểm danh, Đơn nghỉ lớp (T03), Lớp học, Báo nghỉ, Tài khoản, Quên mật khẩu` · FE Web không đổi.

### Câu hỏi mở
- [x] Màn quên mật khẩu nằm trong App, gọi API BE (P-41, user 2026-11-14).
- [x] Tài khoản GV có SĐT: nhân sự đăng nhập bằng SĐT, `phone` bắt buộc khi tạo (`BE:src/main/java/com/carenest/dto/account/CreateAccountRequest.java:17`).
- [x] Mã Jira Phase 1 phía App: G94-332, G94-232, G94-194, G94-334 (user 2026-11-14); BE dùng G94-87.

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| P-22, vắng không đơn, P-21, thân nhiệt | Như Web (riêng P-21 thay câu trả lời đầu "danh sách nháp") | user | 2026-11-14 | docs App, mục trên |
| SĐT OTP bếp; push khi xác nhận lại suất | SĐT tổ trưởng bếp; có push | user | 2026-11-14 | `docs/features/kitchen/README.md` |

## Đề xuất cập nhật BE — đã làm 2026-11-14
User cho phép; BE nhánh `feature/G94-87-BE-FEAT-0-app-rules-sms-reset` (chưa push): `a8487aed` rule 1–4 + plan `BE:docs/plans/active/2026-11-14-app-sms-password-reset.md` · `0b722d0d` API quên mật khẩu SMS OTP · `b3438ad9` danh mục push (PAR-07). Khác đề xuất: (3) không thêm cờ `canCancel` — App dựa vào `LEAVE_CANNOT_CANCEL`; (4) không thêm field SĐT bếp, rule mới là AUTH-27 thay vì sửa AUTH-19/22; (5) theo BE: mọi thông báo đều push. Đề xuất gốc:
1. `BE:docs/business/BUSINESS_RULES.md` Pending register ⇒ "Đã đóng", ngày 2026-11-14, nguồn "User chốt trong phiên làm việc APP":
   - P-19: ngày nghỉ theo lịch trường khóa điểm danh (sửa ATT-06 hoặc SCH-05).
   - P-21: danh sách triệu chứng = `HealthSymptom` hiện có (Sốt, Ho, Sổ mũi, Cảm cúm, Mệt mỏi, Khác).
   - P-22: trường luôn nhận trẻ; bất thường ⇒ ghi dấu hiệu + xử trí "Báo phụ huynh đón về sớm", đón sớm theo PCK-04.
   - P-23: Must.
   - P-32: không làm kênh ý kiến trên App (PAR-04 thành CONFIRMED).
   - P-40: không chỉnh tay mức BMI; sửa phiếu cân đo chỉ khi kỳ còn mở (HLT-13, HLT-18).
2. HLT-07: đổi "đo nhiệt độ mọi trẻ" thành "thân nhiệt nhập khi đo, không bắt buộc; bắt buộc chọn quan sát" cho khớp code (`DailyHealthRequest.temperature` tùy chọn).
3. ATT-04: phụ huynh hủy đơn nhiều ngày ⇒ hủy các ngày chưa qua giờ chốt; ngày đã qua giữ `EXCUSED`. API danh sách đơn trả cờ còn hủy được (`canCancel`) và ngày áp dụng.
4. AUTH-19 / AUTH-21 / AUTH-22: quên mật khẩu trên App bằng SMS OTP cho phụ huynh, GV, bếp; tài khoản bếp có field SĐT tổ trưởng bếp, HT/PHT nhập. Phản hồi không lộ tài khoản có tồn tại.
5. `BE:docs/modules/notification.md`: danh mục sự kiện push theo bảng ở `docs/integration/PUSH_NOTIFICATION.md`.

## Acceptance criteria
- **AC-1** (HLT-07): Given GV ở màn điểm danh, When trẻ Có mặt, Then nhập được quan sát (bắt buộc), triệu chứng, xử trí, thân nhiệt (tùy chọn); trẻ vắng không có ô sức khỏe.
- **AC-2** (P-19): Given ngày nghỉ BE trả, When GV mở điểm danh, Then thấy "Hôm nay trường nghỉ", không có nút điểm danh.
- **AC-3** (ATT-04): Given đơn 3 ngày đã qua 1 ngày, When phụ huynh hủy, Then hai ngày còn lại bị hủy, ngày đã qua vẫn Vắng có phép.
- **AC-4** (HLT-06): Lớp học, suất ăn, thực đơn không còn nhãn "Ăn chay".
- **AC-5** (ATT-09): T03 chỉ liệt kê đơn nghỉ, không có trẻ vắng không đơn.
- **AC-6** (AUTH-21): Given tài khoản GV kiêm phụ huynh, When đăng nhập, Then mở chế độ GV; chuyển chế độ ở Tài khoản; mở lại App thì giữ chế độ cuối.

## Phases
### Phase 1 — Sửa code giả theo quyết định (user duyệt 14/11; Jira: AC-1/2/5 G94-332, AC-3 G94-232, AC-4/6 G94-194, Thông báo G94-334)
- Files (dự kiến): M `lib/features/class_roster/data/fake_class_roster_source.dart` · M `lib/features/campus_children/data/fake_campus_children_source.dart` · M `lib/features/kitchen_meals/data/fake_kitchen_meals_source.dart` · M `lib/features/school_menu/data/fake_school_menu_source.dart` · M `lib/features/class_leave_notices/**` · M `lib/features/leave_notice/**` · M `lib/features/attendance/**` · M `lib/features/account/**`
- Steps: AC-1..AC-6 theo thứ tự; tách plan nếu >8 file.
- Exit: `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0
- **Dừng chờ user review.**

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| BE không nhận đề xuất | App lệch rule BE | Chỉ sửa code giả sau khi user duyệt đề xuất BE | Revert commit App |

## Validation log
- [ ] Khẳng định về code có `file:line`
- [ ] Không dùng rule PENDING/OPEN như đã chốt

## Progress log
### 2026-11-14 — docs App (xong, chưa commit)
- Commit: chưa commit
- Verify: `node scripts/check-ai-layer.mjs` (xem báo cáo phiên)
- Tiếp: user duyệt đề xuất BE, tạo mã Jira, rồi làm Phase 1.

### 2026-11-14 — BE đã ghi đề xuất 1–5 (nhánh G94-87, chưa vào `dev`)
- Docs App đồng bộ theo BE: `docs/integration/AUTH_FLOW.md` (luồng API quên mật khẩu), `docs/integration/PUSH_NOTIFICATION.md` (PAR-07, bảng loại theo role), `docs/context/CURRENT_STATE.md`, `docs/features/{parent,teacher,kitchen}/README.md`, `docs/architecture/NAVIGATION.md`.
- Commit App: chưa commit.
- Tiếp: mã Jira App ⇒ Phase 1 (sửa code giả).

### 2026-11-14 — Phase 1 (xong, chờ user review)
- Commit (nhánh `feature/G94-194-FE-FEAT-49-app-ui-redraw`, chưa push): `75aa7e7` G94-332 · `c38a9bc` G94-232 · `b04d113` G94-194 (bỏ "Ăn chay") · `c35dd5b` G94-194 (chuyển chế độ) · `47a0651` G94-334. Trước đó tách 3 commit cho thay đổi có sẵn: `196a147` TBD-3, `83fbe9d` G94-194, `d10195f` G94-87.
- AC-1..AC-6 có test `Plan 14/11 AC-n`; thêm test PAR-07 cho Thông báo.
- Khác plan: (AC-6) chế độ cuối chỉ nhớ trong phiên — lưu bền chờ plan nền App thêm storage (`TODO(Giáp)` trong `app_modes.dart`); không sửa vùng dùng chung `lib/core`, `lib/routing`. (AC-3) không có cờ `canCancel` từ BE: App hiện nút khi đơn còn ngày từ hôm nay, BE trả `LEAVE_CANNOT_CANCEL` thì báo. Thông báo bỏ ảnh đính kèm và người gửi (BE `NotificationResponse` không có).
- Sửa kèm: hàng nút Có mặt / Vắng tràn ngang khi chữ 2.0 và nút đang chọn in đậm (đổi `Row` ⇒ `Wrap`).
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 219 fail 0 skip 0`.
