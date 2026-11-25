---
title: Phụ huynh chọn năm học (App)
status: approved
owner: Giáp
jira: TBD-4 / FE-FEAT-0
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [parent]
rules: [AUTH-03, AUTH-04, ATT-15, PAR-01, PAR-03]
risk: medium
created: 2026-11-25
updated: 2026-11-25
---
# Phụ huynh chọn năm học (App)

Phần client. Contract và quyết định: `BE:docs/plans/active/2026-11-25-parent-school-year-picker.md` (nhánh BE `fix/G94-180-BE-FIX-10-school-year-scope`).

## Context
- Ô năm học hiện chỉ có ở GV, dữ liệu giả: `lib/features/teacher/school_year/presentation/selected_school_year.dart:15`.
- Màn phụ huynh tự đoán khoảng ngày vì không biết ngày năm học: `recentStarts`, `loadFromNearestStart` (`lib/core/integration/api_dates.dart:17`, `:34`); dùng ở `live_my_child_source.dart:31`, `live_reward_source.dart:23`, `live_evaluation_source.dart:24`.
- `weekly-comments`, `evaluations`, `health/published` gọi không tham số năm (`live_evaluation_source.dart:32-33`, `live_health_book_source.dart:17`).

## Quyết định đã chốt
1. Ô "Năm học" ở Bé của tôi, Điểm danh, Đơn nghỉ, Đánh giá, Khen thưởng, Sổ sức khỏe; trang chủ giữ hôm nay của năm đang chạy — user, 25/11/2026.
2. Năm đã đóng: nhãn "Chỉ xem", ẩn nút gửi đơn nghỉ — user, 25/11/2026.
3. Chưa làm bếp, chưa nối ô năm học GV — user, 25/11/2026.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:** phụ huynh xem dữ liệu của bé theo năm học bé đã học; BE quyết định năm nào thấy được (AUTH-04, CFG-YR-05).
- **Ảnh hưởng:** chỉ nhóm màn phụ huynh; không đổi route; state năm theo từng bé, xóa khi đăng xuất.

### Câu hỏi mở
(không còn — xem plan BE)

## Acceptance criteria
- **AC-1** (AUTH-03): Given bé có năm ACTIVE và CLOSED When mở Bé của tôi Then ô "Năm học <năm đang chạy>"; chọn năm cũ ⇒ các màn trong danh sách đổi theo, có nhãn "Chỉ xem".
- **AC-2** (ATT-15): Given năm đang chọn When tải Điểm danh / Đánh giá ngày / Khen thưởng Then `from ≥ startDate`, `to ≤ min(hôm nay, endDate)`; không gọi khoảng ngoài năm.
- **AC-3**: Đánh giá gọi `evaluations?schoolYearId=` và `weekly-comments?schoolYearId=`; Sổ sức khỏe gọi `health/published?schoolYearId=`.
- **AC-4** (AUTH-03): Năm đã đóng ⇒ Đơn nghỉ ẩn nút "Xin nghỉ cho bé"; danh sách chỉ đơn có ngày trùng năm đó.
- **AC-5**: Bé không học năm đang chạy ⇒ mặc định năm mới nhất BE trả; không có năm nào ⇒ trạng thái rỗng "Bé chưa có năm học".
- **AC-6**: Đổi bé ⇒ năm về mặc định của bé đó; đăng xuất ⇒ xóa năm đã chọn. Response năm cũ đến muộn không ghi đè năm mới.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| State năm | `ParentSelectedYear` (ValueNotifier theo childId) ở feature parent | Dùng chung `SelectedSchoolYear` của GV | Năm GV là năm phân công lớp; không đụng code GV (Vy Anh) |
| Khoảng ngày | Kẹp theo `startDate/endDate` BE trả, bỏ `loadFromNearestStart` ở 3 nguồn | Giữ đoán + fallback | Đã biết ngày năm học ⇒ không đoán; hết lỗi 4109 mùa hè |
| Đơn nghỉ năm cũ | App lọc theo ngày đơn trùng [start, end] | BE thêm tham số | Chỉ hiển thị; BE plan Key decision |

## Phases
### Phase 3 — Năm học của bé: domain, nguồn, state, ô chọn
- Files: C `lib/features/parent/school_year/domain/child_school_year.dart` · C `.../data/live_child_school_year_source.dart` · C `.../data/fake_child_school_year_source.dart` · C `.../presentation/parent_selected_year.dart` (state + `ParentYearChip`) · M `lib/routing/parent_sources.dart` · M `lib/routing/app_router.dart` (reset khi đăng xuất) · C tests.
- Tests: AC-5, AC-6 → `test/features/parent/school_year/*_test.dart`.
- Exit: `node scripts/verify.mjs` → VERIFY PASS.
- **Dừng chờ user review.**

### Phase 4 — Nối 6 màn theo năm đang chọn
- Files: M 6 nguồn live (`my_child`, `evaluation`, `rewards`, `health_book`, `leave_notice`) + domain source interface nhận năm · M 6 màn (`my_child_screen`, `child_attendance_screen`, `leave_notice_list_screen`, `evaluation_screen`, `rewards_screen`, `health_book_screen`) · M fake sources · M tests.
- Tests: AC-1..4 → test nguồn live (query đúng), widget test ô năm + "Chỉ xem" + ẩn nút đơn nghỉ.
- Exit: `node scripts/verify.mjs` → VERIFY PASS; `node scripts/check-parent-api.mjs --sources` với BE 8081 → PASS.
- **Dừng chờ user review.**

### Phase 5 — Kiểm trên máy thật
- Steps: Redmi, BE 8081 (`carenest_scope6`), phụ huynh `0335474254`: đổi năm ở 6 màn; năm cũ chỉ xem.
- Exit: ghi kết quả vào Progress log.

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | AUTH-03 | widget test ParentYearChip + màn | 4 | |
| AC-2 | ATT-15 | test live sources (query) | 4 | |
| AC-3 | PAR-03 | test live sources (query) | 4 | |
| AC-4 | AUTH-03 | widget test đơn nghỉ | 4 | |
| AC-5 | — | test ParentSelectedYear | 3 | |
| AC-6 | — | test ParentSelectedYear | 3 | |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| BE chưa có endpoint (dev) | Phiên thật lỗi ô năm | Chạy với BE g94-180; lỗi ⇒ trạng thái lỗi có thử lại | Revert commit App |
| Năm cũ thiếu dữ liệu | Màn rỗng | Trạng thái rỗng sẵn có | — |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ phía BE ở plan BE
- [x] Mỗi AC có test; mỗi phase có Exit
- [x] >8 file ⇒ đã tách plan BE / App
- [x] Không dùng rule PENDING/OPEN
- [x] Tự review

## Progress log
### 2026-11-25 — Phase 3 + 4 (done, chờ user kiểm máy thật)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 480 fail 0 skip 0`
- Làm: `features/parent/school_year/` (domain + `recentRange`/`monthRange` kẹp theo năm, nguồn live/fake, `ParentSelectedYear` theo bé, `ParentYearGate`, `ParentYearChip`, `ParentYearPicker`); 5 màn (Điểm danh, Đơn nghỉ, Đánh giá, Khen thưởng, Sổ sức khỏe) dựng trong `ParentYearGate`; Bé của tôi có ô năm (`ParentYearPicker`); đăng xuất xóa năm đã chọn.
- Khác plan: Bé của tôi chỉ có ô chọn năm (hồ sơ không theo năm); `ParentYearGate` widget test viết sau code gate (không đỏ trước); Xem thử dùng `FakeChildSchoolYearSource` nên ô năm cũng hiện; chi tiết đợt khám / chủ đề không theo năm (mở theo id).
- Sửa test cũ: router live test thêm `GET /children/5/school-years`, query `?schoolYearId=3`; hồ sơ Bé của tôi: chữ "Năm học" nay ở ô năm.
- Tiếp: Phase 5 — kiểm trên Redmi với BE 8081 sau khi khởi động lại BE (code mới).
