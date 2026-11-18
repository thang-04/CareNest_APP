---
title: Bé của tôi — hồ sơ của bé (gộp trang Hồ sơ, thêm tiền sử)
status: done         # user 18/11 "duyệt canva … hãy sửa luôn app"; draft → approved → in-progress → done | blocked | cancelled
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # mã tạm của nhánh (plan 2026-11-16) — đổi sang mã Jira thật trước khi mở PR
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [features]
rules: [AUTH-04, CHD-02, CHD-05, CHD-06, HLT-06, PAR-01, PAR-02]
risk: medium         # bỏ route /parent/child-profile trong lib/routing (vùng dùng chung); dữ liệu giả, không đổi contract BE
created: 2026-11-18
updated: 2026-11-18
---
# Bé của tôi — hồ sơ của bé (gộp trang Hồ sơ, thêm tiền sử)

## Context
- Thay plan `docs/plans/completed/2026-11-18-parent-my-child-journey.md` (bản "hành trình năm học" làm sáng 18/11). User hỏi vì sao Hành trình năm học là số đo sức khỏe, rồi duyệt canvas "Bé của tôi gộp Hồ sơ" (https://claude.ai/artifact/9auLezc8PN6y71Be6E8EEr) kèm yêu cầu thêm tiền sử bản thân, tiền sử gia đình.
- Hiện tại: Bé của tôi có thanh chọn bé + hành trình năm học (`lib/features/parent/my_child/presentation/screens/my_child_screen.dart`); hồ sơ là màn con `/parent/child-profile` (`child_profile_screen.dart`, mở từ nút "Hồ sơ của bé" và link "Xem hồ sơ của <bé> ›" trên thẻ bé ở Trang chủ — `parent_home_screen.dart:253`).
- BE có khai báo sức khỏe khi tiếp nhận: `child_health_declarations` (`BE:docs/database/DATA_DICTIONARY.md`), tiền sử bản thân / gia đình `REPORTED` + tên bệnh hoặc `NONE_REPORTED` (HLT-06, CHD-06). Web hiển thị "Có — <tên bệnh>" / "Không" / "Chưa cung cấp" (`CareNest_FE/src/models/children/childProfile.js`). Chưa có API phụ huynh ⇒ dữ liệu giả.

## Quyết định đã chốt
1. Gộp Hồ sơ của bé vào tab Bé của tôi; bỏ thanh chọn bé, tab theo bé đang chọn ở Trang chủ — user 18/11.
2. Giữ thẻ đầu (ảnh chữ cái lớn, tên, lớp · tuổi), bỏ nút Gọi cô và Hồ sơ của bé; dòng thứ ba "Năm học …" — user duyệt canvas 18/11.
3. Bên dưới chỉ thông tin của trang Hồ sơ; bỏ Hành trình năm học, Phát triển, Danh hiệu — user 18/11.
4. Sức khỏe đã khai báo thêm Tiền sử bản thân, Tiền sử gia đình — user 18/11.
5. Bỏ route `/parent/child-profile`; link "Xem hồ sơ của <bé> ›" ở Trang chủ chuyển sang tab Bé của tôi — user duyệt canvas 18/11.

## Làm rõ nghiệp vụ
Theo `.ai/workflows/clarify-business.md`.
- **Hiểu nghiệp vụ:** phụ huynh chỉ xem hồ sơ con mình (AUTH-04), không sửa (CHD-05). Khai báo sức khỏe theo trạng thái BE (CHD-06); tiền sử là dữ liệu nhạy cảm (CHD-02).
- **Ảnh hưởng:** APP: tab Bé của tôi, Trang chủ (đích của link "Xem hồ sơ"), router bỏ một route con. BE: cần API phụ huynh cho hồ sơ + khai báo sức khỏe (PAR-01 chưa liệt kê, PAR-02 mặc định không hiện) — ghi lệch BE, không đổi BE.

### Câu hỏi mở
Còn `- [ ]` ⇒ không được `approved` (check-ai-layer E5).
- [x] Gộp Hồ sơ vào Bé của tôi
- [x] Thêm tiền sử

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Gộp Hồ sơ, bỏ thanh chọn bé, bỏ hành trình | Có, theo canvas | User | 18/11 | `docs/features/parent/README.md` |
| Tiền sử bản thân, gia đình | Thêm vào Sức khỏe đã khai báo | User | 18/11 | `docs/features/parent/README.md` |

## Acceptance criteria
- **AC-1** (`AUTH-04`): Given tab Bé của tôi, Then thấy thẻ đầu (tên, lớp · tuổi, năm học), Thông tin chung, Giáo viên chủ nhiệm (nút gọi), Sức khỏe đã khai báo, Người đưa đón, ghi chú; không có thanh chọn bé, nút Gọi cô, Hồ sơ của bé, Hành trình năm học.
- **AC-2** (`AUTH-04`): Given đổi bé ở Trang chủ, Then Bé của tôi hiện hồ sơ bé đó.
- **AC-3** (`CHD-06`, `HLT-06`): Sức khỏe đã khai báo hiện dị ứng (chip đỏ có icon từng chất / "Không" / "Chưa cung cấp"), chế độ ăn, tiền sử bản thân, tiền sử gia đình ("Có — tên bệnh" / "Không" / "Chưa cung cấp").
- **AC-4**: Link "Xem hồ sơ của <bé> ›" ở Trang chủ chuyển sang tab Bé của tôi; link cũ `/parent/child?tab=…` vẫn mở tab.
- **AC-5**: Lỗi tải ⇒ báo lỗi, "Thử lại" tải lại; chữ 1,3 và 2,0 không tràn.

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Model khai báo | `DeclaredHealth` + `DeclaredItem` theo trạng thái BE | Chuỗi gộp sẵn (`healthLine` cũ) | Nhãn "Không" / "Chưa cung cấp" do App đổi từ trạng thái BE, khớp web; dễ nối API |
| Đích link "Xem hồ sơ" | `context.go(RoutePaths.parentChild)` | Giữ màn con riêng | Hồ sơ chỉ còn ở một chỗ |

## Phases
### Phase 1 — Màn và dữ liệu giả
- Files: M `lib/features/parent/my_child/domain/my_child.dart` · M `lib/features/parent/my_child/data/fake_my_child_source.dart` · M `lib/features/parent/my_child/presentation/screens/my_child_screen.dart` · D `lib/features/parent/my_child/presentation/screens/child_profile_screen.dart` · M `test/features/parent/my_child/my_child_screens_test.dart`
- Tests: AC-1, AC-2, AC-3, AC-5
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 2 — Route (vùng dùng chung) và Trang chủ
- Files: M `lib/routing/app_router.dart` · M `lib/routing/route_paths.dart` · M `lib/features/parent/parent_home/presentation/screens/parent_home_screen.dart` · M `test/routing/app_router_test.dart`
- Tests: AC-4
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 3 — Tài liệu
- Files: M `docs/features/parent/README.md` · M `docs/architecture/NAVIGATION.md` · M `docs/context/CURRENT_STATE.md` · A `docs/knowledge/incidents/APP-BUG-261118-setstate-future-retry.md` · M `docs/knowledge/ISSUE_INDEX.md`
- Exit: `node scripts/check-ai-layer.mjs` + `node scripts/verify.mjs` → PASS

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | AUTH-04 | `my_child_screens_test.dart` (widget) | 1 | pass |
| AC-2 | AUTH-04 | `my_child_screens_test.dart` (widget) | 1 | pass |
| AC-3 | CHD-06, HLT-06 | `my_child_screens_test.dart` (widget) | 1 | pass |
| AC-4 | — | `app_router_test.dart` (widget) | 2 | pass |
| AC-5 | — | `my_child_screens_test.dart` (lỗi + Thử lại, chữ 1,3 / 2,0) | 1 | pass |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Bỏ route trong vùng dùng chung | Link cũ `/parent/child-profile` ⇒ "Không tìm thấy trang" | Không push hay màn nào còn dùng route này (grep) | Trả route và `ChildProfileScreen` từ git |
| Mất số liệu năm học ở Bé của tôi | Phụ huynh tìm số đo, phiếu | Sổ sức khỏe, Đánh giá, Khen thưởng ở Việc nhanh | Trả bản hành trình từ git |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ không đổi contract BE
- [x] Mỗi AC có test; mỗi phase có Exit = lệnh + kết quả mong đợi
- [x] >8 file: không tách plan — 3 phase nối tiếp của cùng một màn
- [x] Không dùng rule PENDING/OPEN như đã chốt
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan · không câu mơ hồ

## Progress log
### 2026-11-18 — Phase 1 (done)
- `ChildProfile` mới: lớp, tuổi, năm học tách riêng; `DeclaredHealth` (dị ứng + chế độ ăn + tiền sử bản thân, gia đình) theo trạng thái BE qua `DeclaredItem`. Bỏ `ChildJourney`, `loadJourney` và màn `ChildProfileScreen`.
- `MyChildScreen`: không thanh chọn bé, theo `SelectedChild`; thẻ đầu không nút; 4 phần thông tin + ghi chú. Dữ liệu giả: Minh Anh tiền sử gia đình "Có — Tăng huyết áp"; Bảo Ngọc dị ứng hải sản, tiền sử bản thân "Có — Hen phế quản".
- Test "Thử lại" lộ lỗi `setState() callback argument returned a Future.` (closure mũi tên trả Future) ⇒ sửa ở Bé của tôi; 12 màn khác còn mẫu cũ, ghi `APP-BUG-261118-setstate-future-retry`.

### 2026-11-18 — Phase 2 (done)
- Bỏ route `/parent/child-profile` và `RoutePaths.parentChildProfile`; link "Xem hồ sơ của <bé> ›" ở Trang chủ gọi `context.go(RoutePaths.parentChild)`. Giao diện Trang chủ không đổi.

### 2026-11-18 — Phase 3 (done)
- `docs/features/parent/README.md` (mục Bé của tôi, lệch BE), `docs/architecture/NAVIGATION.md`, `docs/context/CURRENT_STATE.md`, incident + `ISSUE_INDEX.md`.
- `node scripts/verify.mjs` (Flutter 3.47.6) → `VERIFY PASS full | format ok | design ok | analyze ok | tests 443 fail 0 skip 0`.
- Chưa commit, chưa push: chờ user cho phép.
