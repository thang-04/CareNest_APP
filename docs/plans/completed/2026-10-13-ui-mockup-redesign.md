---
title: Dựng lại UI CareNest Mobile theo mockup 5 vai trò
status: done
owner: ATPX48-69
jira: none
branch: dev
modules: []
rules: [AUTH-03, AUTH-04, AUTH-05, AUTH-07, ATT-01, ATT-02, ATT-03, ATT-04, ATT-05, NUT-01, NUT-02, NUT-03, NUT-06, NUT-07, NUT-08, NUT-10, NUT-11, NUT-12, NUT-14, NUT-16, HLT-02, HLT-03, HLT-04, OBS-01, OBS-08, OBS-10, PAR-01, PAR-02]
risk: high
created: 2026-10-13
updated: 2026-10-13
---
# Dựng lại UI CareNest Mobile theo mockup 5 vai trò

## Context
User gửi mockup Figma "CareNest App (Moqups)". Figma MCP hết lượt gọi (gói Starter, 20 lượt/tháng), nên user chụp ảnh vào Google Doc "MockUp Mobile App". 30 ảnh đã lưu ở `docs/design/figma/`, tên file theo vai trò và số màn. Đây là nguồn bố cục duy nhất của plan.

Mockup có 5 vai trò: Phụ huynh (18 màn), Giáo viên (13 màn), Nhân viên bếp (7 màn), Phó Hiệu trưởng (9 màn), Hiệu trưởng (7 màn).

Hiện trạng code (plan cũ `docs/plans/completed/2026-10-10-ui-redesign-mobile.md`, đã đóng 2026-10-13):
- Token, theme và 17 widget chung theo `DESIGN.md` ở `lib/core/`. Màu ở `lib/core/constants/colors.dart`.
- 6 màn dữ liệu giả: Đăng nhập, Phụ huynh Hôm nay, Báo nghỉ, Giáo viên Hôm nay, Điểm danh, Bếp Suất ăn.
- Router `lib/routing/app_router.dart:23-76`: màn theo vai trò chỉ đăng ký khi `enablePreview` (mặc định `kDebugMode`). Khung tab từng vai trò ở `_roleShell` (`app_router.dart:79-100`).
- Thanh đáy chỉ có 3 vai trò (`lib/routing/navigation_destinations.dart:17-36`). Màn chọn vai trò xem thử ở `lib/features/dev_preview/presentation/screens/role_preview_screen.dart`.
- Plan nền `docs/plans/active/2026-10-08-flutter-ui-foundation.md` vẫn `in-progress` (branch `main`). Plan này không đụng plan đó.

Mockup lệch `DESIGN.md`: màu xanh đậm bão hòa, header xanh đặc, chữ giống Roboto. `DESIGN.md` §4.1 chốt brand `#4FB0F5`, primary `#0B72BC`; §3 chốt font Be Vietnam Pro.

## Quyết định đã chốt
1. Bố cục theo mockup; màu, font, khoảng cách, bo góc theo `DESIGN.md` và token hiện có. Không sửa `DESIGN.md` §4 — user, 2026-10-13.
2. Màn có nghiệp vụ chưa chốt bên BE: Claude tự phân tích, dựng UI với dữ liệu giả — user, 2026-10-13. Kết quả phân tích ở mục Key decisions.
3. BGH có trên app, tách 2 vai trò: Hiệu trưởng và Phó Hiệu trưởng — user, 2026-10-13.
4. Đóng plan `2026-10-10-ui-redesign-mobile` — user, 2026-10-13. Đã chuyển sang `docs/plans/completed/`.
5. Không làm Giáo viên 08 và 11–14: nghiệp vụ chưa xác định — user, 2026-10-13.
6. Giữ từ plan cũ: dữ liệu giả tĩnh, không nối API, không thêm thư viện (Riverpod/Dio/chart/camera…); màn theo vai trò chỉ có ở bản debug — user, 2026-10-10.
7. Dựng Bếp 05–06 (nhận nguyên liệu, báo thiếu thực phẩm): đây là nghiệp vụ mới — user, 2026-10-13. Đè lên phân tích K2 ban đầu. BE chưa ghi rule; mức PROPOSED (Q3).
8. Ảnh bữa ăn: bếp chụp món khi nấu xong; giáo viên chụp khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món trong thực đơn/lịch của con. Mức PROPOSED — user, 2026-10-13. Bước bếp chụp không có trong mockup K07 ⇒ không dựng đợt này.

## Làm rõ nghiệp vụ
- **Hiểu nghiệp vụ:**
  - Actor: Phụ huynh, Giáo viên, Nhân viên bếp, Phó Hiệu trưởng, Hiệu trưởng.
  - Outcome: xem và thao tác giao diện mới với dữ liệu giả. Không đổi nghiệp vụ, không gọi BE.
  - Rule CONFIRMED/ACCEPTED dùng: AUTH-03/04/05/07, ATT-01..05, NUT-01/02/03/06/07/08, HLT-02/04, OBS-01/08, PAR-01/02 — nguồn `BE:docs/business/BUSINESS_RULES.md:13-100`.
  - Rule chưa chốt mà mockup đụng tới: NUT-02 người xác nhận (P-05), NUT-04 (P-04), NUT-11/12 kho–NCC (OPEN ADR-0009, P-08/P-09), HLT-03 ngưỡng (P-13), OBS-07 lịch hoạt động (OPEN ADR-0006), OBS-10 khen thưởng (PROPOSED, P-11), PAR-03 field phụ huynh xem (P-13b), AUTH-02 phạm vi Phó HT (P-14), P-06 bếp theo campus.
  - Flow: [S] mở app → Đăng nhập (nút không gọi API) → bản debug: chọn vai trò → khung tab của vai trò.
- **Đối chiếu thiết kế ban đầu:**
  - `docs/architecture/NAVIGATION.md:9-15` chỉ có 3 nhánh Parent/Teacher/Kitchen; mockup thêm Phó HT và Hiệu trưởng ⇒ quyết định 3.
  - `AGENTS.md` nguyên tắc 8 và `BE:docs/business/BUSINESS_RULES.md:50-51` để kho/NCC ngoài phạm vi; mockup Bếp 04–06 và Phó HT 05 có phiếu xuất kho, nhận nguyên liệu, báo thiếu ⇒ Key decisions K2.
  - `BE:docs/business/BUSINESS_RULES.md:79` (OBS-08) cấm soạn/duyệt giáo án; mockup Giáo viên 04.1 và 10 ghi "Giáo án đã duyệt", "Tổ trưởng & Phó HT đã ký duyệt" ⇒ K3.
  - Bếp 05–06 là nghiệp vụ mới (quyết định 7), chưa có trong `BE:docs/business/BUSINESS_RULES.md`; gần nhất là NUT-10 (Fresh/Stored, CONFIRMED) và NUT-11/12 (OPEN, ADR-0009). Lệch `AGENTS.md` nguyên tắc 8 ("kho/NCC chưa làm") ⇒ không sửa `AGENTS.md` (khối dùng chung 3 repo); đề xuất cập nhật BE (Q3: chưa sửa repo BE).
  - Trạng thái nấu (K07, V05) có NUT-14 PROPOSED; ảnh bữa ăn có NUT-16 PROPOSED nhưng ghi "bếp chụp", mockup T15–T16 để giáo viên chụp ⇒ ghi lệch vào docs feature, không coi là đã chốt.
  - Không tìm thấy rule BE cho: đón trẻ và xác minh người đón, đơn nghỉ phép nhân sự, đăng nhập bằng số điện thoại và OTP SMS (`BE:docs/contracts/AUTH_CONTRACT.md` là SKELETON) ⇒ K4, K5.
  - `docs/architecture/NAVIGATION.md:58` để "Xác nhận số suất" ở nhóm chưa gán vai trò (P-05); mockup giao cho Phó HT ⇒ K6.
- **Ảnh hưởng:**
  - APP: `lib/core/{constants,widgets,layouts}`, `lib/routing/*`, `features/dev_preview`, 6 feature hiện có, khoảng 20 feature mới, test, docs điều hướng và feature theo vai trò.
  - BE: không đổi contract trong plan này. Các khoảng trống contract (K4, K5) ghi đề xuất vào `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` khi user cho phép sửa repo BE.
  - FE: không ảnh hưởng, token trùng mã web.
  - Không có dữ liệu cũ.

### Câu hỏi mở
- [x] Q1. Plan có 7 phase và hơn 60 file. Giữ 1 plan, dừng review sau mỗi phase? Hay tách thành 3 plan: (A) nền + xác thực + tài khoản, (B) Phụ huynh + Giáo viên, (C) Bếp + BGH?
- [x] Q2. Bếp 05 nhận theo "phiếu PXK-1012". Phiếu xuất kho có thuộc nghiệp vụ mới không? Nếu có: giữ "phiếu xuất kho" ở K01, K04 (banner + nút), K05, và "Phiếu xuất kho", "Báo thiếu từ bếp" ở V05.
- [x] Q3. Nghiệp vụ nhận nguyên liệu / báo thiếu: team đã chốt (CONFIRMED) hay mới đề xuất (PROPOSED)? Cho phép ghi đề xuất vào repo BE (`BUSINESS_RULES.md` nhóm NUT, `ADR-0009`) không?

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Màu/font | Bố cục mockup, màu/font `DESIGN.md` | user | 2026-10-13 | Quyết định 1 |
| Màn chưa có rule BE | Claude tự phân tích, dựng UI dữ liệu giả | user | 2026-10-13 | Key decisions K1–K7 |
| BGH | Tách Hiệu trưởng và Phó Hiệu trưởng | user | 2026-10-13 | `docs/architecture/NAVIGATION.md` (Phase 1) |
| Plan cũ | Đóng | user | 2026-10-13 | `docs/plans/completed/2026-10-10-ui-redesign-mobile.md` |
| Bếp 05–06 | Vẫn dựng, là nghiệp vụ mới | user | 2026-10-13 | Quyết định 7; `docs/features/kitchen/README.md` |
| Q1 | 1 plan 7 phase, dừng review sau mỗi phase | user | 2026-10-13 | Plan này |
| Q2 | Phiếu xuất kho thuộc nghiệp vụ mới, giữ như mockup | user | 2026-10-13 | `docs/features/kitchen/README.md` |
| Q3 | PROPOSED; chưa sửa repo BE, Claude soạn đề xuất | user | 2026-10-13 | `docs/features/kitchen/README.md` |
| Ai chụp ảnh bữa ăn | Bếp chụp món khi nấu xong; GV chụp khi nhận suất rồi đăng; phụ huynh xem trong thực đơn/lịch | user | 2026-10-13 | Quyết định 8; `docs/features/{parent,teacher,kitchen}/README.md` |
| Giáo viên 08, 11–14 | Không làm, nghiệp vụ chưa xác định | user | 2026-10-13 | Quyết định 5 |

## Danh sách màn
Ký hiệu cột "Xử lý": **Đ** = dựng theo mockup · **Đ−** = dựng nhưng bỏ phần ghi trong ngoặc · **B** = bỏ khỏi đợt này.
Ảnh: tên file trong `docs/design/figma/`.

### Phụ huynh (ảnh `parent-*`)
| Mã | Màn | Rule | Xử lý |
| --- | --- | --- | --- |
| P01 | Đăng nhập (số điện thoại + mật khẩu) | AUTH_CONTRACT SKELETON | Đ — dùng chung mọi vai trò |
| P02 | Trang chủ: lời chào, thẻ bé, Hôm nay, Tiện ích | PAR-01, AUTH-04 | Đ |
| P03 | Xin nghỉ cho bé | ATT-04, ATT-05 | Đ |
| P04 | Đơn xin nghỉ đã gửi | ATT-05 | Đ — trạng thái chỉ "GV chưa xem / GV đã xem", không có "duyệt" |
| P05 | Thực đơn tuần | NUT-08, PAR-02 | Đ (ảnh bữa ăn là khối giữ chỗ) |
| P06 | Thông báo | — | Đ — dùng chung mọi vai trò |
| P07 | Chi tiết thông báo | — | Đ (ảnh là khối giữ chỗ) |
| P08 | Bé của tôi – Hôm nay | PAR-01, OBS-07 [P] | Đ |
| P09 | Hoạt động & đánh giá | OBS-01, OBS-07 [P] | Đ (ảnh hoạt động là khối giữ chỗ) |
| P10 | Điểm danh & bữa ăn (lịch tháng) | ATT-01, ATT-04 | Đ |
| P11 | Bé của tôi – Sức khỏe | HLT-02, HLT-03 [P], HLT-04 | Đ — nhãn "Bình thường" là giá trị BE trả (giả), APP không tự xếp loại |
| P12 | Bé của tôi – Phát triển & khen thưởng | OBS-05, OBS-10 [PROPOSED] | Đ |
| P13 | Hồ sơ của bé | AUTH-04, HLT-06 | Đ |
| P14 | Tài khoản | — | Đ — dùng chung mọi vai trò |
| P15–P17 | Quên mật khẩu → OTP → Đặt mật khẩu mới | AUTH_CONTRACT SKELETON | Đ |
| P18 | Thông tin cá nhân | — | Đ — dùng chung mọi vai trò |

### Giáo viên (ảnh `teacher-*`)
| Mã | Màn | Rule | Xử lý |
| --- | --- | --- | --- |
| T01 | Trang chủ: thẻ lớp, hạn điểm danh, Việc cần làm | AUTH-03, ATT-06 [P] | Đ− (bỏ việc "Cơ sở vật chất": màn CSVC không có trong mockup) |
| T02 | Điểm danh & báo ăn | ATT-01..04, NUT-01 | Đ — hàng đếm không gọi là "suất" |
| T03 | Đơn xin nghỉ của lớp | ATT-05 | Đ |
| T04 | Đánh giá hằng ngày – danh sách bé | OBS-01 | Đ |
| T04.1 | Đánh giá hằng ngày – chi tiết bé | OBS-01, OBS-02, OBS-08, OBS-10 | Đ− (bỏ thẻ "Giáo án đã duyệt"; giữ "Gắn cờ" dạng PROPOSED) |
| T05–T06 | Đón trẻ, xác minh người đón | không có rule BE | Đ (ảnh người đón là icon giữ chỗ) |
| T07–T07.1 | Đo sức khỏe – danh sách, chi tiết | HLT-01..04, NAVIGATION [P] người nhập | Đ — "Kết quả" là giá trị BE trả (giả) |
| T09 | Lớp học (danh sách bé) | AUTH-03, HLT-06 | Đ |
| T10 | Lịch hoạt động | OBS-07 [OPEN], OBS-08 | Đ− (bỏ "Giáo án tuần… đã duyệt", "Tổ trưởng & Phó HT đã ký duyệt", "Xem file") |
| T15–T16 | Chụp ảnh bữa ăn, gửi phụ huynh | NUT-16 [PROPOSED], quyết định 8 | Đ (không camera thật: khung ngắm là khối tĩnh) |
| T08, T11–T14 | — | — | B (quyết định 5) |

### Nhân viên bếp (ảnh `kitchen-*`)
| Mã | Màn | Rule | Xử lý |
| --- | --- | --- | --- |
| K01 | Trang chủ bếp | AUTH-05, NUT-03 | Đ |
| K02 | Thực đơn đã công bố | NUT-08 | Đ |
| K03 | Suất ăn đã chốt theo lớp | NUT-01, NUT-03, AUTH-05 | Đ |
| K04 | Định lượng thực phẩm | NUT-06, NUT-07 | Đ |
| K05–K06 | Nhận nguyên liệu, báo thiếu thực phẩm | nghiệp vụ mới (quyết định 7), BE chưa ghi; NUT-10 | Đ (K2) |
| K07 | Trạng thái nấu | NUT-14 [PROPOSED] | Đ |

### Phó Hiệu trưởng (ảnh `vice-principal-*`)
| Mã | Màn | Rule | Xử lý |
| --- | --- | --- | --- |
| V01 | Trang chủ cơ sở | AUTH-02, AUTH-08 | Đ |
| V02 | Yêu cầu chờ duyệt | NUT-03, OBS-10 | Đ |
| V03 | Duyệt điều chỉnh suất | NUT-03, NUT-04 [P] | Đ |
| V04 | Chốt suất ăn trong ngày | NUT-02, P-05 [P] | Đ (K6) |
| V05 | Theo dõi trạng thái bếp | NUT-14 [PROPOSED] | Đ (giữ "Phiếu xuất kho" và banner "Báo thiếu từ bếp", Q2) |
| V06 | Thực đơn tuần theo nhóm tuổi | NUT-08 | Đ |
| V07 | Cân đối dinh dưỡng ngày | NUT-06 | Đ — mọi "Đạt/Thiếu" là giá trị BE trả (giả) |
| V10 | Trẻ của cơ sở | AUTH-02 | Đ |
| V12 | Duyệt đề xuất khen thưởng | OBS-10 [PROPOSED] | Đ |

### Hiệu trưởng (ảnh `principal-*`)
| Mã | Màn | Rule | Xử lý |
| --- | --- | --- | --- |
| H01 | Tổng quan toàn trường | AUTH-01, AUTH-08 | Đ− (bỏ ô "Nghỉ phép nhân sự") |
| H02 | Chờ Hiệu trưởng duyệt | OBS-10 | Đ− (bỏ tab và mục "Nghỉ phép") |
| H04 | Duyệt khen thưởng cuối năm | OBS-10 [PROPOSED] | Đ |
| H05 | Duyệt đơn nghỉ của nhân sự | không có trong phạm vi CareNest | B (K5) |
| H06 | Danh sách trẻ toàn trường | AUTH-01 | Đ |
| H07 | Thực đơn tuần (chỉ xem) | NUT-08 | Đ |
| H08 | Cơ sở & Phó HT phụ trách | AUTH-02 | Đ |

## Acceptance criteria
- **AC-1** (`DESIGN.md` §4–5): Given mọi màn mới, When render, Then màu lấy từ `AppColors`/`AppStatusColors`, chữ từ `AppTextStyles`; không có mã màu hex trong `lib/features/`.
- **AC-2** (`AUTH-07`, NAVIGATION): Given bản release (`enablePreview: false`), When mở app, Then chỉ có Đăng nhập, Quên mật khẩu, OTP, Đặt mật khẩu mới; mọi route theo vai trò trả 404.
- **AC-3** (NAVIGATION, quyết định 3): Given bản debug, When mở "Xem thử theo vai trò", Then có 5 vai trò, mỗi vai trò vào đúng khung 4 tab theo mockup.
- **AC-4** (`ATT-05`): Given P04 và T03, When hiển thị đơn nghỉ, Then không có chữ "duyệt"/"từ chối"; trạng thái chỉ là đã xem / chưa xem.
- **AC-5** (`NUT-01`): Given T02, When hiển thị hàng đếm, Then không có chữ "suất".
- **AC-6** (`AUTH-05`): Given màn Bếp, When hiển thị suất ăn và thực đơn thay thế, Then không có tên trẻ.
- **AC-7** (`OBS-08`, K3): Given mọi màn, When render, Then không có chữ "giáo án".
- **AC-8** (`HLT-04`): Given P11 và T07.1, When hiển thị số đo, Then có câu "không thay thế chẩn đoán y tế" và không có lời khuyên điều trị.
- **AC-9** (nguyên tắc 4 `AGENTS.md`): Given ảnh trẻ, ảnh người đón, ảnh bữa ăn, When render, Then là khối giữ chỗ hoặc icon, không có ảnh thật.
- **AC-10** (`R` 375 px, chữ phóng 2.0): Given mỗi màn mới, When test với chữ 2.0 ở 375 px, Then không tràn.

## Key decisions
| Mã | Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- | --- |
| K1 | Màn có rule PENDING/PROPOSED (P-05, P-13, P-13b, OBS-07, OBS-10) | Dựng đủ, dữ liệu giả, chỉ ở bản debug | Bỏ màn | User cho dựng giả (quyết định 2). Rule vẫn PENDING; giao diện không coi là đã chốt |
| K2 | Nhận nguyên liệu, báo thiếu (K05, K06) | Dựng, dữ liệu giả, bản debug | Bỏ (phân tích ban đầu theo NUT-11/12 OPEN) | User xác nhận là nghiệp vụ mới (quyết định 7). Chênh lệch "tự báo Phó HT" là hành vi BE; APP chỉ hiển thị |
| K3 | Giáo án (T04.1, T10) | Giữ lịch hoạt động, bỏ mọi chữ duyệt/ký giáo án | Bỏ T10 | OBS-08 CONFIRMED: CareNest không duyệt giáo án; lịch hoạt động là ngữ cảnh (ADR-0006) |
| K4 | Đón trẻ, ảnh bữa ăn, trạng thái nấu, đăng nhập SĐT + OTP | Dựng giả, ghi khoảng trống contract | Bỏ | Không thuộc nhóm ngoài phạm vi; BE chưa có rule/contract ⇒ đề xuất ghi `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` |
| K5 | Đơn nghỉ phép nhân sự (H05, ô ở H01/H02) | Bỏ | Dựng giả | Quản lý nhân sự không có trong phạm vi CareNest (`BE:docs/context/PROJECT_CONTEXT.md:66`), không có module BE |
| K6 | Chốt suất ăn (V04) giao cho Phó HT | Dựng ở nhánh Phó HT, ghi chú P-05 PENDING trong docs | Để ngoài nhánh | Mockup đặt ở Phó HT; chỉ ở bản debug, chưa chốt P-05 |
| K7 | Biểu đồ cân nặng (P11), lịch tháng (P10) | Tự vẽ bằng `CustomPainter`/`GridView` | Thêm thư viện chart/calendar | Quyết định 6: không thêm thư viện |
| K8 | Đặt widget mới | `lib/core/widgets/` khi ≥2 màn dùng; còn lại trong `features/<x>/presentation/widgets/` | Tất cả vào core | `DESIGN.md` cấu trúc Feature-based |

## Phases
### Phase 1 — Nền: widget mới, điều hướng 5 vai trò, docs
- Files: M `lib/routing/{app_router,route_paths,navigation_destinations}.dart` · M `lib/features/dev_preview/.../role_preview_screen.dart` · M `lib/core/constants/app_icons.dart` · C `lib/core/widgets/{app_hero_header,app_stat_tile,app_task_row,app_day_strip,app_timeline,app_otp_field,app_month_calendar}.dart` · M `docs/architecture/NAVIGATION.md` · C `docs/features/{principal,vice-principal}/README.md` · M `docs/features/README.md` · M `docs/context/CURRENT_STATE.md` · M `test/routing/app_router_test.dart` · M `test/core/widgets/app_widgets_test.dart`
- Steps: 1. Widget chung mới, token `DESIGN.md`. 2. Đích thanh đáy 5 vai trò theo mockup (Phụ huynh: Trang chủ · Bé của tôi · Thông báo · Tài khoản; Giáo viên: Trang chủ · Lớp học · Thông báo · Tài khoản; Bếp: Trang chủ · Thực đơn · Thông báo · Tài khoản; Phó HT: Trang chủ · Duyệt · Thông báo · Tài khoản; Hiệu trưởng: Tổng quan · Duyệt · Thông báo · Tài khoản). 3. Màn xem thử 5 vai trò. 4. Docs điều hướng, feature 2 vai trò mới.
- Tests: AC-2, AC-3 → `app_router_test.dart`; widget mới → `app_widgets_test.dart` (gồm chữ 2.0).
- Exit: `node scripts/verify.mjs` → `VERIFY PASS full`, skip 0; `node scripts/check-ai-layer.mjs` 0 lỗi.
- **Dừng chờ user review.**

### Phase 2 — Xác thực và tài khoản dùng chung (P01, P14–P18, P06–P07)
- Files: M `features/auth/.../login_screen.dart` · C `features/auth/.../{forgot_password,otp_verify,new_password}_screen.dart` · C `features/account/` (Tài khoản, Thông tin cá nhân) · C `features/notifications/` (danh sách, chi tiết) · M `lib/routing/*` · test tương ứng
- Tests: AC-2 (route xác thực có ở release), AC-9 (P07), AC-10.
- Exit: như Phase 1. **Dừng chờ user review.**

### Phase 3 — Phụ huynh (P02–P05, P08–P13)
- Files: M `features/parent_home/*`, M `features/leave_notice/*` · C `features/parent_menu/`, `features/child_today/`, `features/child_activities/`, `features/child_attendance/`, `features/child_health/`, `features/child_development/`, `features/child_profile/` · test tương ứng
- Tests: AC-4 (P04), AC-8 (P11), AC-9 (P05, P09), AC-10.
- Exit: như Phase 1. **Dừng chờ user review.**

### Phase 4 — Giáo viên (T01–T07.1, T09, T10, T15–T16)
- Files: M `features/teacher_home/*`, M `features/attendance/*` · C `features/class_leave_notices/`, `features/daily_review/`, `features/pickup/`, `features/health_measure/`, `features/class_roster/`, `features/activity_schedule/`, `features/meal_photos/` · test tương ứng
- Tests: AC-4 (T03), AC-5 (T02), AC-7 (T04.1, T10), AC-8 (T07.1), AC-9 (T06, T15–T16), AC-10.
- Exit: như Phase 1. **Dừng chờ user review.**

### Phase 5 — Nhân viên bếp (K01–K07)
- Files: M `features/kitchen_meals/*` · C `features/kitchen_home/`, `features/kitchen_menu/`, `features/food_quantities/`, `features/ingredient_receipt/` (K05–K06), `features/cooking_status/` · test tương ứng
- Tests: AC-6, AC-10; K05–K06: ô số thực nhận lệch phiếu có nhãn chữ, không chỉ màu.
- Exit: như Phase 1. **Dừng chờ user review.**

### Phase 6 — Phó Hiệu trưởng (V01–V07, V10, V12)
- Files: C `features/vp_home/`, `features/approvals/`, `features/meal_count_confirm/`, `features/nutrition_balance/`, `features/campus_children/`, `features/reward_proposals/`; dùng lại thực đơn và trạng thái nấu của Phase 5 ở chế độ chỉ xem · test tương ứng
- Tests: AC-10.
- Exit: như Phase 1. **Dừng chờ user review.**

### Phase 7 — Hiệu trưởng (H01, H02, H04, H06–H08)
- Files: C `features/principal_overview/`, `features/school_children/`, `features/campuses/`; dùng lại `approvals/`, `reward_proposals/`, thực đơn · test tương ứng
- Tests: AC-7 và không có "nghỉ phép" (K5), AC-10.
- Exit: như Phase 1. Cập nhật `docs/context/CURRENT_STATE.md`. **Dừng chờ user review.**

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | DESIGN §4–5 | grep hex trong `lib/features/` (verify) + review | 1–7 | ✓ grep `Color(0x` trong `lib/features/`: 0 |
| AC-2 | AUTH-07 | `app_router_test.dart` (widget) | 1, 2 | ✓ verify 168 pass |
| AC-3 | NAVIGATION | `app_router_test.dart` (widget) | 1 | ✓ verify 168 pass |
| AC-4 | ATT-05 | test màn P04, T03 (widget) | 3, 4 | ✓ verify 168 pass |
| AC-5 | NUT-01 | `attendance_screen_test.dart` (widget) | 4 | ✓ verify 168 pass |
| AC-6 | AUTH-05 | test màn bếp (widget) | 5 | ✓ verify 168 pass |
| AC-7 | OBS-08 | test màn T04.1, T10 (widget) | 4 | ✓ verify 168 pass |
| AC-8 | HLT-04 | test màn P11, T07.1 (widget) | 3, 4 | ✓ verify 168 pass |
| AC-9 | AGENTS nguyên tắc 4 | test màn có ảnh (widget: không có `Image.network`) | 2–4 | ✓ verify 168 pass |
| AC-10 | R 375 px | test chữ 2.0 mỗi màn (widget) | 1–7 | ✓ verify 168 pass |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Dựng UI cho rule PENDING bị hiểu là đã chốt | Team code BE theo UI | Màn chỉ ở bản debug; docs feature ghi rõ [P]; báo lúc giao | Gỡ route khỏi `app_router.dart` |
| Khối lượng lớn (khoảng 55 màn) | Review khó, dễ lệch mockup | Dừng sau mỗi phase, chụp màn 375 px so với ảnh `docs/design/figma/` | Phase trước giữ nguyên; `git restore` file của phase (hỏi user trước) |
| Đổi bố cục 6 màn cũ làm vỡ test cũ | Verify fail | Sửa test cùng phase | `git restore` file của phase (hỏi user trước) |
| Màu `DESIGN.md` nhạt hơn mockup, header brand `#4FB0F5` | Chữ trắng trên brand thiếu tương phản | Chữ trên brand dùng `onBrand` (`DESIGN.md:382`, 4,64:1) | Chỉnh token header, không sửa mockup |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ không đổi contract trong plan; khoảng trống contract liệt kê ở K4
- [x] Mỗi AC có test; mỗi phase có Exit = lệnh + kết quả mong đợi
- [x] >8 file hoặc >3 phase ⇒ đã đề xuất tách plan (Q1)
- [x] Không dùng rule PENDING/OPEN như đã chốt (K1, K6)
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan · không câu mơ hồ

## Progress log
### 2026-10-13 — Phase 1 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 63 fail 0 skip 0 | 12s | log verify.log`; `check-ai-layer` 0 lỗi (3 cảnh báo glob có từ trước)
- Đã làm:
  - Widget chung mới ở `lib/core/widgets/`: `AppHeroHeader` + `AppHeroBell`, `AppStatTile` + `AppStatRow`, `AppTaskCard`, `AppDayStrip`, `AppTimeline`, `AppOtpField`, `AppMonthCalendar`. `DateLabels` thêm `weekdayShort`, `weekdayHeaders`.
  - Điều hướng 5 vai trò: `route_paths.dart`, `navigation_destinations.dart` (nhãn tab theo mockup), `app_router.dart` (shell Phó HT, Hiệu trưởng); `AppIcons` thêm `childFace`, `classGroup`, `approval`, `shieldPerson`. Màn xem thử có 5 vai trò.
  - Test: AC-3 (5 vai trò × 4 tab), AC-2 mở rộng cho route mới; widget mới không tràn ở 360 px chữ 1.0 và 2.0; lịch đọc trạng thái bằng chữ; OTP chỉ nhận số.
  - Docs: `NAVIGATION.md` (2 nhánh BGH, bảng route), `DESIGN.md` §7.1 (7 widget mới) và §8.4 (tab theo mockup, 2 vai trò BGH), `docs/features/{vice-principal,principal}/README.md`, `docs/features/README.md`, `CURRENT_STATE.md`, `docs/features/kitchen/README.md`.
- Khác plan:
  - `RoutePaths.kitchenToday` / `kitchenMeals` đổi thành `kitchenHome` (`/kitchen`) / `kitchenMenu` (`/kitchen/menu`) theo tab mockup; tab Trang chủ bếp tạm hiện màn Suất ăn cũ tới Phase 5.
  - Phát hiện `BE:docs/business/USER_ROLES.md:20-21` ghi Principal / Vice Principal chỉ dùng Web ⇒ ghi lệch vào `DESIGN.md` §8.4 và 2 feature doc; cần đề xuất cập nhật BE.
  - `DESIGN.md` §8.4 trước đó ghi "Không thêm Phó hiệu trưởng" ⇒ sửa theo quyết định 3.
- Chưa kiểm chứng: chưa xem bằng mắt, vì Phase 1 chưa có màn dùng widget mới; sẽ chụp 375 px ở Phase 2.
- Tiếp: Phase 2 (xác thực, tài khoản, thông báo dùng chung).
### 2026-10-13 — Phase 2 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 84 fail 0 skip 0 | 15s | log verify.log`; `check-ai-layer` 0 lỗi (3 cảnh báo glob có từ trước)
- Đã làm:
  - Xác thực: Đăng nhập theo P01 (số điện thoại + icon, mật khẩu + icon, banner "cấp qua SMS", phiên bản); `ForgotPasswordScreen` (P15), `OtpVerifyScreen` (P16, đếm ngược gửi lại), `NewPasswordScreen` (P17, gợi ý định dạng; `requireCurrent` khi đổi từ Tài khoản). Route `/forgot-password/*` có cả ở release; release để callback null ⇒ báo "chưa kết nối", debug đi hết luồng.
  - `features/account`: `AccountScreen` (P14) và `PersonalInfoScreen` (P18) dùng chung 5 vai trò, dữ liệu giả `FakeAccountSource`; `AppRole` enum.
  - `features/notifications`: `NotificationsScreen` (P06: lọc Tất cả / Chưa đọc, đánh dấu đã đọc trên màn) và `NotificationDetailScreen` (P07: ảnh là khối giữ chỗ), dữ liệu giả theo vai trò.
  - Router: `NavTab` cho đích thanh đáy; tab Thông báo và Tài khoản của mọi vai trò dùng màn chung; màn con mở trên navigator gốc (ẩn thanh đáy).
  - `AppTextField` thêm `leadingIcon`, dạng khoá; `AppInfo` (phiên bản, tên trường).
  - Test: AC-2 (release vẫn có Quên mật khẩu, báo chưa kết nối), luồng debug quên mật khẩu → OTP → đặt mật khẩu → Đăng nhập, chi tiết thông báo ẩn thanh đáy, Đăng xuất về Đăng nhập, AC-9 (P07 không có `Image`), AC-10 chữ 2.0 cho mọi màn mới.
- Xem bằng mắt (375×812, golden test tạm có nạp font Be Vietnam Pro + Material Icons, đã xoá sau khi chụp): Đăng nhập, Quên mật khẩu, OTP, Đặt mật khẩu mới, Thông báo, Chi tiết thông báo, Tài khoản, Thông tin cá nhân, Xem thử — khớp bố cục mockup; màu và bo góc theo `DESIGN.md`.
- Lỗi bắt được và đã sửa:
  - `AccountScreen` không tải lại hồ sơ khi đổi vai trò ⇒ thêm `didUpdateWidget`.
  - Chữ 2.0: tiêu đề "Thông báo" + "Đánh dấu đã đọc" tràn 112 px ⇒ `Wrap`; `AppFilterChip` cao cứng 36 tràn 41 px ⇒ `minHeight` + `Flexible`. Lần sửa đầu thêm `alignment` làm chip giãn hết chiều ngang, ảnh chụp bắt được ⇒ bỏ `alignment`.
- Khác plan:
  - Chụp màn bằng `flutter run -d web-server` + Chrome headless không ổn định (server debug chỉ nhận một client; route ra 404 sau khi tải) ⇒ chuyển sang golden test tạm.
  - Nút Đăng xuất dùng dạng danger của `DESIGN.md` (nền `dangerSoft`) thay viền đỏ của mockup.
  - Logo `assets/image/Logo.jpg` có nền gần trắng, thấy viền mờ trên nền trắng; chưa sửa (cần file logo nền trong).
- Tiếp: Phase 3 (Phụ huynh).
### 2026-10-13 — Phase 3 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 102 fail 0 skip 0 | 16s | log verify.log`; `check-ai-layer` 0 lỗi (3 cảnh báo glob có từ trước)
- Đã làm (10 màn Phụ huynh, dữ liệu giả theo mockup: bé Nguyễn Minh Anh, Mầm 3A, mẹ Thu Lan, cô Hà — khớp nhau giữa các màn):
  - P02 Trang chủ: `AppHeroHeader` + thẻ bé (Xem hồ sơ, Đổi bé) · Hôm nay (điểm danh có badge, thực đơn, hoạt động) · Tiện ích 2×2.
  - P03 Xin nghỉ (màn riêng, buổi nghỉ, lý do ≤500 ký tự, banner huỷ suất chỉ khi nghỉ cả ngày) · P04 Đơn đã gửi (GV đã xem / chưa xem / đã huỷ).
  - P05 Thực đơn tuần (dải ngày, năng lượng và ghi chú dị ứng là chữ BE trả, ảnh bữa ăn GV đăng là khối giữ chỗ).
  - P08/P11/P12 tab Bé của tôi (Hôm nay · Sức khỏe với biểu đồ cân nặng tự vẽ · Phát triển với phiếu bé ngoan) · P09 Hoạt động & đánh giá · P10 Điểm danh tháng (lịch, chú giải, chi tiết ngày) · P13 Hồ sơ bé.
  - `SelectedChild` (ValueNotifier) dùng chung Trang chủ và Bé của tôi; Đăng xuất reset. Route màn con chỉ mang `?child=<id>`.
  - Widget chung mới `AppPhotoPlaceholder`; `AppTextField.maxLength`; `DateLabels.weekdayDayMonth`, `time24`.
  - Test: AC-4 (P04 không có duyệt/từ chối), AC-8 (P11 có câu không thay chẩn đoán, không có "điều trị"), AC-9 (P05, P09 không có `Image`), AC-10 chữ 2.0 cho 9 màn; đổi bé, đổi ngày thực đơn, chọn ngày nghỉ có phép.
- Xem bằng mắt (375×812, golden test tạm, đã xoá): 9 màn khớp bố cục mockup.
- Lỗi bắt được và đã sửa:
  - Gửi đơn thành công mà màn không rời đi ⇒ nút "Đang gửi" quay mãi; nay tắt trạng thái gửi trước `onSubmitted`.
  - Chữ 2.0 tràn ở `AppListRow` có badge (64 px), thẻ đơn nghỉ (26 px), chú giải lịch (34 px) ⇒ `AppListRow` đưa badge xuống dưới tiêu đề khi chữ > 1,3; thẻ đơn dùng `Wrap`; chú giải `Flexible`.
  - Nhãn đọc màn hình của ô số liệu / lịch / biểu đồ bị gộp vào node cha ⇒ thêm `container: true` cho các `Semantics` có `excludeSemantics`.
  - Ký tự ✓ không có trong font Be Vietnam Pro ⇒ dòng bữa ăn dùng chữ.
- Khác plan:
  - Gộp 7 feature dự kiến thành `my_child` (P08–P13) + `parent_menu` (P05); `leave_notice` thay form sheet bằng màn `LeaveNoticeFormScreen` (xoá `leave_notice_form_sheet.dart`).
  - Thẻ tuần ở Thực đơn và ngày ở Hoạt động bỏ mũi tên "‹" chuyển tuần/ngày trước (dữ liệu giả chỉ có một tuần/ngày) — sẽ thêm khi có API.
  - Gọi giáo viên ở Hồ sơ bé mở "Sắp có" (cần plugin quay số, chưa thêm thư viện).
  - Thẻ "Khen thưởng cuối năm" viền liền thay viền đứt của mockup.
  - Domain `LeaveNotice` đổi lý do từ enum sang chữ, thêm `session`, `seenByTeacher` theo mockup ⇒ BE chưa có field, đã ghi đề xuất ở `docs/features/parent/README.md`.
- Tiếp: Phase 4 (Giáo viên).
### 2026-10-13 — Phase 4 (chờ review)
- Commit: chưa commit
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 120 fail 0 skip 0 | 16s | log verify.log`; `check-ai-layer` 0 lỗi (3 cảnh báo glob có từ trước)
- Đã làm (13 màn Giáo viên, dữ liệu giả lớp Mầm 3A 28 bé dùng chung `class_roster`, khớp nhau: 3 bé vắng — Khánh Linh, Minh Châu có đơn, Đức Huy không đơn — ở Điểm danh, Đánh giá, Đón trẻ, Đo sức khỏe):
  - T01 Trang chủ (hero, thẻ lớp + Lịch hoạt động, hạn điểm danh, 6 việc), T02 Điểm danh & báo ăn (ô đếm, đánh dấu tất cả có mặt, Có mặt / Vắng, bấm tên báo ăn), T03 Đơn nghỉ của lớp, T04/T04.1 Đánh giá hằng ngày, T05/T06 Đón trẻ + xác minh, T07/T07.1 Đo sức khỏe, T09 Lớp học (tab), T10 Lịch hoạt động, T15/T16 Ảnh bữa ăn.
  - Widget chung mới `AppSearchField` (+ `matchesSearch` không dấu); `AppTextField.inputFormatters`.
  - Dữ liệu Phụ huynh chỉnh cho khớp số đo GV: lần đo gần nhất 12/10, tháng 9 là 16,8 kg.
  - Test: AC-4 (T03 không duyệt), AC-5 (T02 không chữ "suất"), AC-7 (T01, T04.1, T10 không "giáo án"), AC-8 (T07.1), AC-9 (T06, T15 không `Image`), AC-10 chữ 2.0 cho 12 màn; luồng đánh giá, giao bé, đo, chụp → gửi.
- Xem bằng mắt (375×812, golden test tạm, đã xoá): 13 màn khớp bố cục mockup.
- Lỗi bắt được và đã sửa:
  - `SwitchListTile` trong card có nền ⇒ assert "ink splashes may be invisible"; bọc `Material` trong suốt.
  - Trang chủ GV khi lỗi tải vẫn để khung chờ ở thẻ lớp (animation chạy mãi) ⇒ bỏ khung chờ khi lỗi.
  - Tràn: Lớp học (nhãn + mũi tên ở khổ 360, 7 px) ⇒ nhãn xuống dưới tên; Lịch hoạt động (chữ tuần trên AppBar ở chữ 2.0, 23 px) ⇒ đưa vào thẻ kế hoạch; thẻ lớp T01 xuống dòng nút ở chữ thường ⇒ Row / Column theo cỡ chữ.
  - Nhãn semantics "Báo ăn" gộp vào node khác ⇒ `container: true`.
- Khác plan / mockup:
  - Thêm việc "Ảnh bữa ăn" ở Trang chủ GV: mockup T15 không có lối vào khác.
  - T02 chỉ có Có mặt / Vắng như mockup; bé có đơn hiển thị có phép theo đơn (ATT-04). "Ăn 1 bữa · Trưa" là ghi chú BE trả; báo ăn theo từng bữa chưa có trong BE ⇒ đề xuất.
  - Số trên mockup lệch nhau (T01 12/28 vs T07 13/28, T04 8/26) ⇒ dùng số khớp dữ liệu giả: 13/28 đã đo, 8/25 đã đánh giá (25 bé có mặt).
  - T07.1 bỏ "Đổi bé ▾" (quay về danh sách để chọn bé khác); T06 nút "Đúng – giao bé" dùng nút chính `DESIGN.md` thay nút xanh lá của mockup.
  - Gom feature theo nghiệp vụ: `class_roster`, `class_leave_notices`, `daily_review`, `pickup`, `health_measure`, `activity_schedule`, `meal_photos`; xoá `attendance_status.dart` không còn dùng.
- Tiếp: Phase 5 (Nhân viên bếp).
### 2026-10-13 — Phase 5 (chờ review)
- Commit: chưa commit
- Đã làm (7 màn Bếp, dữ liệu giả bữa trưa 12/10 cơ sở chính 182 suất = 175 thường + 7 thay thế; Mầm 3A 24 + 1 khớp 25 bé có mặt ở màn Giáo viên):
  - K01 Trang chủ bếp (thẻ bếp + trạng thái nấu lấy cùng nguồn K07, suất đã chốt, 5 việc), K02 Thực đơn theo nhóm tuổi (tab, `school_menu` dùng lại cho Phó HT), K03 Suất ăn đã chốt theo lớp (viết lại `kitchen_meals`), K04 Định lượng + phiếu xuất kho, K05 Nhận nguyên liệu (so số nhập với phiếu để nhắc), K06 Báo thiếu thực phẩm, K07 Trạng thái nấu (`readOnly` cho Phó HT).
  - Widget chung `AppSelectField`; `MealSlot` chuyển sang `school_menu/domain/meal_slot.dart` (thực đơn, ảnh bữa ăn, trạng thái nấu cùng dùng).
  - Thông báo giả của bếp sửa thành "Mầm 3A xin +1 suất · chờ Phó HT duyệt" (bếp chỉ thấy số đã xác nhận, NUT-03).
  - Test: AC-6 (K02, K03 không tên trẻ), NUT-02 (chưa xác nhận ⇒ không có số), K05 chênh lệch hiện / hết khi sửa đủ, K06 gửi báo thiếu, K07 chuyển bước + chỉ xem, AC-10 chữ 2.0 cho 7 màn.
- Xem bằng mắt (375×812, golden test tạm, đã xoá): 7 màn khớp bố cục mockup.
- Lỗi bắt được và đã sửa:
  - Font Be Vietnam Pro không có ký tự "→" ⇒ dòng đổi món mất mũi tên; đổi dữ liệu thành cặp (món gốc, món thay), vẽ mũi tên bằng icon.
  - Trang chủ bếp tràn 163 px ở chữ 2.0 (hàng "182 suất") ⇒ `Wrap` + `Flexible`; lỗi tải không để khung chờ chạy mãi.
  - Tiêu đề cột K04 dính chữ ⇒ thêm khoảng cách.
- Khác plan / mockup:
  - Số "+1 suất" ở K01/K03 hiện là **chờ Phó HT duyệt**, không cộng vào 182 (mockup để "+1 suất" như đã có).
  - Thực đơn thay thế theo nhóm khớp K03 (Mầm: 1 dị ứng hải sản), không theo số mockup K02 (2 + 1).
  - K07 giữ câu "Giáo viên không cần thao tác nhận suất" theo mockup — lệch NUT-15 PROPOSED, đã ghi ở `docs/features/kitchen/README.md`.
  - Bước bếp chụp ảnh món khi nấu xong (quyết định 8) chưa dựng: mockup K07 không có.
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 130 fail 0 skip 0 | 18s | log verify.log`; `check-ai-layer` 0 lỗi (3 cảnh báo glob có từ trước)
- Tiếp: Phase 6 (Phó Hiệu trưởng).
### 2026-10-13 — Phase 6 (chờ review)
- Commit: chưa commit
- Đã làm (9 màn Phó HT, dữ liệu giả cơ sở chính 12/10: 196 trẻ = 182 có mặt + 9 có phép + 5 vắng; số suất khớp K03):
  - V01 Trang chủ cơ sở (thẻ cơ sở, 4 ô số, 5 việc; số chờ duyệt và việc "Chốt suất" đổi theo khi xử lý), V02 tab Duyệt (lọc Tất cả / Suất ăn / Khen thưởng), V03 Duyệt điều chỉnh suất (từ chối bắt buộc lý do), V04 Chốt suất ăn (P-05), V05 Trạng thái bếp (K07 chỉ xem + phiếu xuất kho + báo thiếu), V06 Thực đơn tuần (K02 + đã công bố + nút cân đối), V07 Cân đối dinh dưỡng, V10 Trẻ của cơ sở (tìm, lọc lớp, dị ứng / ăn kiêng), V12 Đề xuất khen thưởng (gửi HT / trả lại).
  - Feature mới: `vice_principal_home`, `approvals`, `meal_count_confirm`, `nutrition_balance`, `campus_children`, `reward_proposals` (plan ghi `vp_home` ⇒ đặt tên đủ). Bảng suất theo lớp tách thành `MealCountTable` (K03 + V04); `SchoolMenuScreen.bottom` nhận thêm nhóm tuổi + ngày; `CookingStatusScreen` thêm ô `notice`.
  - Test: V01–V12 hành vi chính, V03 thiếu lý do / ID không có, V04 xác nhận xong ẩn nút, V07 nhóm không có thực đơn, V10 lọc + tìm, V12 chuyển tab; router: màn con Phó HT ẩn thanh đáy, ngữ cảnh V07 từ query; AC-10 chữ 2.0 cho 9 màn.
- Xem bằng mắt (375×812, golden test tạm, đã xoá cùng `test/failures/` còn sót từ Phase 4): 9 màn khớp bố cục mockup.
- Lỗi bắt được và đã sửa:
  - V03: báo "nhập lý do" nằm ngoài màn hình (ô lý do cuối danh sách) ⇒ cuộn tới ô lý do; nút giữ trạng thái đang gửi sau khi duyệt ⇒ reset trước khi rời màn.
  - V10: ô tìm nằm trong danh sách ảo sẽ mất chữ khi cuộn xa ⇒ đưa ô tìm và bộ lọc ra ngoài danh sách.
  - `Wrap` spaceBetween trong Column căn trái không dàn hai đầu (V01 badge "Hôm nay", V12 badge hợp lệ) ⇒ Row + Expanded; V07 tràn ở chữ 2.0 ⇒ Wrap trong Column stretch.
  - Tên trẻ giả ở V03 / V12 trùng trẻ Mầm 3A của Giáo viên nhưng ghi lớp khác ⇒ đổi tên / lớp cho khớp.
- Khác plan / mockup:
  - V04 giờ tổng hợp 08:15, giờ chốt 08:30 (khớp K03 "chốt lúc 08:30", V03 "sau giờ chốt 08:30"); bỏ banner điều chỉnh 09:05 ở V04 vì điều chỉnh chỉ có sau khi chốt.
  - Nút "Duyệt" (V03) dùng nút chính `DESIGN.md` thay nút xanh lá của mockup; "Từ chối" / "Trả lại" dùng nút danger nền nhạt.
  - V10 số dị ứng / ăn kiêng 4 / 4 theo dữ liệu giả khớp K03 (mockup 6 / 1); lớp của một số bé theo danh sách Mầm 3A đã có.
  - V10 chạm bé ⇒ "Sắp có" (hồ sơ cho Phó HT chưa có mockup).
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 152 fail 0 skip 0 | 19s | log verify.log`
- Tiếp: Phase 7 (Hiệu trưởng).
### 2026-10-13 — Phase 7 (chờ review)
- Commit: chưa commit
- Đã làm (6 màn Hiệu trưởng, dữ liệu giả 12/10 toàn trường: 334 trẻ = 196 cơ sở chính + 138 cơ sở 2, 312 có mặt, 306 suất đã chốt):
  - H01 Tổng quan (4 ô: Trẻ có mặt · Suất ăn đã chốt · Thực đơn tuần · Cơ sở; đánh giá theo khối; mục chờ duyệt), H02 tab Duyệt (đợt chờ duyệt + đã xử lý gần đây), H04 Khen thưởng cuối năm (chọn từng đề xuất, ghi chú khi trả về), H06 Danh sách trẻ (lọc cơ sở, lớp + sĩ số, tìm tên bé; chạm lớp mở danh sách trẻ của lớp), H07 Thực đơn tuần theo cơ sở + ngày (năng lượng ngày theo nhóm, tóm tắt BE), H08 Cơ sở & Phó HT phụ trách (mở từ Tài khoản hoặc ô Cơ sở).
  - Feature mới: `principal_overview`, `school_children`, `campuses`; thêm vào `approvals` (H02), `reward_proposals` (đợt gửi Hiệu trưởng, H04), `school_menu` (H07). Đợt H04 gồm đúng 7 đề xuất hợp lệ Phó HT gửi ở V12.
  - Dữ liệu giả mở rộng: cơ sở 2 (5 lớp, có nhà trẻ) cho danh sách trẻ, thực đơn, dinh dưỡng; canxi chỉ thiếu ở nhóm Mầm. `CampusChildrenScreen` thêm `title`, `initialClassId` (ID lớp sai ⇒ coi như chưa chọn); `AccountScreen` thêm `onOpenCampuses` (chỉ Hiệu trưởng).
  - Test: H01 không có "Nghỉ phép", H02 đợt chờ / đã xử lý, H04 bỏ chọn cần ghi chú + duyệt đúng số đã chọn + trả về bắt buộc ghi chú, H06 lọc cơ sở + tìm, màn lớp mở sẵn / ID sai, H07 đổi cơ sở, H08; router: màn con ẩn thanh đáy, Tài khoản Hiệu trưởng có "Cơ sở của trường", Phó HT không có; AC-10 chữ 2.0 cho 6 màn.
- Xem bằng mắt (375×812, golden test tạm, đã xoá): 6 màn khớp bố cục mockup (trừ phần bỏ theo K5).
- Lỗi bắt được và đã sửa:
  - H04 nút "Duyệt 7 đề xuất" bị cắt chữ ở nửa bề ngang ⇒ "Duyệt (7)".
  - Tên trẻ giả sinh tự động lặp tên đệm liên tiếp và trùng một bé Mầm 3A ("Đỗ Tuấn Kiệt") ⇒ đổi cách ghép họ + tên, kiểm tra không trùng trong mỗi cơ sở.
  - Màn trẻ của lớp hiện sĩ số cả cơ sở ⇒ hiện sĩ số lớp.
- Khác plan / mockup:
  - Bỏ theo K5: ô "Nghỉ phép nhân sự" (H01, thay bằng ô Cơ sở), tab và mục "Nghỉ phép" (H02), màn H05; H02 vì vậy không còn bộ lọc.
  - H04 duyệt từng phần (bỏ chọn ⇒ trả về Phó HT kèm ghi chú) là cách APP hiểu ô chọn của mockup — OBS-10 PROPOSED, cần BE xác nhận.
  - H07 thêm dải ngày (mockup chỉ Thứ Hai); thẻ hiện năng lượng ngày của thực đơn; tóm tắt dinh dưỡng là banner thông tin (không suy màu từ chữ BE trả).
  - H08 bỏ mảng "CSVC" (ngoài phạm vi CareNest). Cơ sở chính không có lớp nhà trẻ (giữ như K02); "Nhà trẻ 1" của mockup đặt ở cơ sở 2.
- Verify: `node scripts/verify.mjs` → `VERIFY PASS full | format ok | analyze ok | tests 168 fail 0 skip 0 | 27s | log verify.log`
- Tiếp: user review Phase 7 ⇒ đóng plan (`status: done`, chuyển `docs/plans/completed/`).
### 2026-10-13 — Đóng plan
- User duyệt Phase 7 ("duyệt") ⇒ `status: done`, chuyển `docs/plans/completed/`.
- Commit: chưa commit (chờ user cho phép).
- Còn mở cho BE / team (đã ghi trong docs feature): contract cho mọi màn mới (dữ liệu giả, chỉ bản debug); P-05 người chốt suất; OBS-10 luồng khen thưởng + đợt gửi Hiệu trưởng; NUT-14 / NUT-15 lệch mockup K07; NUT-16 ai chụp ảnh bữa ăn; nghiệp vụ nhận nguyên liệu / phiếu xuất kho (PROPOSED); `BE:docs/business/USER_ROLES.md` còn ghi BGH chỉ dùng Web.
