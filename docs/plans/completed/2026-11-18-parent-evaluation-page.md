---
title: Trang Đánh giá của phụ huynh — 5 mục Ngày · Tuần · Chủ đề · Học kỳ · Cuối năm
status: in-progress  # user duyệt 18/11, làm liền 3 phase; draft → approved → in-progress → done | blocked | cancelled
owner: Giáp
jira: TBD-4 / FE-FEAT-0   # mã tạm của nhánh (plan 2026-11-16) — đổi sang mã Jira thật trước khi mở PR
branch: feature/TBD-4-FE-FEAT-0-app-foundation
modules: [features]
rules: [OBS-01, OBS-02, OBS-05, OBS-06, OBS-12, OBS-13, OBS-27, OBS-28, OBS-29, PAR-03]
risk: medium         # thêm route vào lib/routing (vùng dùng chung); dữ liệu giả, không đổi contract BE
created: 2026-11-18
updated: 2026-11-18
---
# Trang Đánh giá của phụ huynh

## Context
- User 18/11 duyệt canvas "Đánh giá của bé" (https://claude.ai/artifact/TbHzuHafe14n6zoqhKZ23a): một trang Đánh giá riêng, thanh 5 mục giống segmented Hôm nay | Phát triển.
- Hiện ô "Đánh giá" ở Việc nhanh mở tab Phát triển của Bé của tôi (`lib/features/parent/parent_home/presentation/screens/parent_home_screen.dart:216-221`). Tab này có nhận xét tuần, dòng nhận xét tháng, phiếu bé ngoan, khen cuối năm (`lib/features/parent/my_child/presentation/screens/my_child_screen.dart:287-441`).
- BE: phụ huynh mới có `GET /children/{childId}/weekly-comments` (OBS-29). Đánh giá ngày, cuối chủ đề, học kỳ, cuối năm chưa có API cho phụ huynh ⇒ dữ liệu giả như Sổ sức khỏe (`lib/features/parent/health_book/data/fake_health_book_source.dart`).

## Quyết định đã chốt
1. Trang Đánh giá riêng, 5 mục: Ngày · Tuần · Chủ đề · Học kỳ · Cuối năm — user 18/11.
2. Phụ huynh vào từ ô "Đánh giá" ở Trang chủ, mở thẳng trang Đánh giá — user 18/11.
3. Bé của tôi giữ nguyên: tab Phát triển, ô "Khen thưởng", ô "Hoạt động & đánh giá" không đổi — user 18/11.
4. Dữ liệu giả, chưa nối BE; nhãn và field theo DTO BE hiện có (`BE:src/main/java/com/carenest/dto/observation/`) — cùng cách làm Sổ sức khỏe 17/11.

## Làm rõ nghiệp vụ
Theo `.ai/workflows/clarify-business.md`.
- **Hiểu nghiệp vụ:** Phụ huynh xem đánh giá của con đã lưu, đã gửi hoặc đã xác nhận. OBS-13 (ngày, sau khi GV lưu), OBS-29 (tuần, bản đã gửi), OBS-05 + OBS-06 (định kỳ, đã xác nhận), OBS-27 (chủ đề, đạt từ 70% số MT), OBS-28 (phiếu cuối năm), PAR-03 (chỉ hiện sau công bố/xác nhận) — đều CONFIRMED.
- **Đối chiếu thiết kế ban đầu:** DESIGN.md §B6.2 ghi "Cập nhật phát triển: dòng thời gian theo tháng" ⇒ đổi thành trang 5 mục (user 18/11). Không có kỳ Tháng vì màn Đánh giá tháng đã bỏ (OBS-26).
- **Ảnh hưởng:** APP: Trang chủ (ô Đánh giá), route mới `/parent/evaluation` và `/parent/evaluation/themes/<themeId>`. Bé của tôi không đổi. BE không đổi.

### Câu hỏi mở
Còn `- [ ]` ⇒ không được `approved` (check-ai-layer E5).
- [x] Phiếu cuối năm: phụ huynh chỉ xem "Lưu ý cho cha mẹ" (đề xuất) hay cả 4 lưu ý?
- [x] "Chưa đạt": tông đỏ như web (đề xuất, DESIGN.md §3.2) hay xám dịu hơn?
- [x] Ghi chú chung cả lớp của bảng cuối chủ đề: ẩn với phụ huynh (đề xuất)?
- [x] Chủ đề đang học: hiện dòng "Đang học · Chưa có kết quả" (đề xuất) hay ẩn tới khi có kết quả?

| Câu hỏi | Trả lời | Ai | Ngày | Rule/doc đã cập nhật |
| --- | --- | --- | --- | --- |
| Lưu ý cuối năm phụ huynh xem | Chỉ "Lưu ý cho cha mẹ" | User | 18/11 | `docs/features/parent/README.md` |
| Tông "Chưa đạt" | Đỏ như web | User | 18/11 | `docs/features/parent/README.md` |
| Ghi chú chung lớp ở bảng chủ đề | Ẩn với phụ huynh | User | 18/11 | `docs/features/parent/README.md` |
| Chủ đề đang học | Hiện "Đang học · Chưa có kết quả", không mở được | User | 18/11 | `docs/features/parent/README.md` |

## Acceptance criteria
- **AC-1** (`OBS-13`, `OBS-01`): Given trang Đánh giá mục Ngày, When đổi tuần bằng ‹ › và chọn ngày, Then thấy Sinh hoạt lưới 2 cột (sức khỏe, cảm xúc, 3 bữa, ngủ trưa, hành vi), mặt khác thường tô cam kèm icon; Học tập (tham gia, nhóm Chưa đạt trước, nhóm Đạt sau, kèm tên hoạt động); Lời cô nhắn; cờ ngày. Ngày bé vắng ⇒ "Bé nghỉ học"; ngày cô chưa lưu ⇒ "Chưa có đánh giá".
- **AC-2** (`OBS-29`): Given mục Tuần, Then thấy nhận xét đã gửi, mới nhất mở sẵn, tuần cũ có "Đọc tiếp".
- **AC-3** (`OBS-27`): Given mục Chủ đề, Then chủ đề nhóm theo học kỳ, mỗi dòng có số MT đạt / tổng và Đạt / Chưa đạt; When chạm một chủ đề, Then mở chi tiết: số đạt + thanh, nhóm Chưa đạt, nhóm Đạt thu gọn, câu "đạt từ 70%", người xác nhận.
- **AC-4** (`OBS-06`): Given mục Học kỳ, When đổi học kỳ bằng ‹ ›, Then thấy số lĩnh vực đạt + thanh; 5 lĩnh vực mở/đóng; lĩnh vực mở hiện MT chưa đạt kèm "Đạt ở x/y chủ đề".
- **AC-5** (`OBS-28`): Given mục Cuối năm, Then thấy số MT đạt + thanh, nhãn Hoàn thành chương trình (lớp 5–6 tuổi), nhận xét của cô, lưu ý cho gia đình, lĩnh vực (nhận xét của cô + MT chưa đạt), cân đo cuối năm.
- **AC-6**: Given Trang chủ, When chạm "Đánh giá", Then mở trang Đánh giá mục Ngày; con lạ ⇒ màn không tìm thấy.
- **AC-7**: Đủ trạng thái tải, lỗi + "Thử lại", rỗng; chữ 1,3 và 2,0 không tràn (nhãn thanh 5 mục xuống dòng, không cắt).

## Key decisions
| Quyết định | Chọn | Phương án khác | Vì sao |
| --- | --- | --- | --- |
| Thanh 5 mục | `AppSegmented` có sẵn, chữ 14 | Sửa core để cuộn ngang | Không đụng `lib/core`; chữ lớn thì nhãn xuống dòng, không cắt (DESIGN.md §2.3 quy tắc 22). Lệch canvas (cuộn ngang) ghi ở README |
| Đổi kỳ | Ngày, Học kỳ: nút ‹ ›; Tuần, Chủ đề: danh sách | Chip chọn kỳ | Như canvas user duyệt |
| Thanh tỉ lệ đạt | `LinearProgressIndicator` bo pill như màn Cân đối dinh dưỡng | Widget core mới | Đã có tiền lệ trong feature (`nutrition_balance_screen.dart:139-148`) |
| Nguồn dữ liệu | `EvaluationSource` + `FakeEvaluationSource` | Gọi API weekly-comments thật | Các mục khác chưa có API; nối BE theo plan 2026-11-16 |

## Phases
### Phase 1 — Màn và dữ liệu giả
- Files: C `lib/features/parent/evaluation/domain/evaluation.dart` · C `lib/features/parent/evaluation/data/fake_evaluation_source.dart` · C `lib/features/parent/evaluation/presentation/evaluation_labels.dart` · C `lib/features/parent/evaluation/presentation/screens/evaluation_screen.dart` · C `lib/features/parent/evaluation/presentation/screens/theme_result_screen.dart` · C `lib/features/parent/evaluation/presentation/widgets/` (mục Ngày, Tuần, Chủ đề, Học kỳ, Cuối năm, khối dùng chung) · C `test/features/parent/evaluation/evaluation_screen_test.dart` · C `test/features/parent/evaluation/theme_result_screen_test.dart`
- Tests: AC-1 → AC-5, AC-7
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 2 — Route và ô Đánh giá ở Trang chủ (vùng dùng chung)
- Files: M `lib/routing/route_paths.dart` · M `lib/routing/app_router.dart` · M `lib/features/parent/parent_home/presentation/screens/parent_home_screen.dart` · M `test/routing/app_router_test.dart`
- Tests: AC-6
- Exit: `node scripts/verify.mjs` → VERIFY PASS
### Phase 3 — Tài liệu
- Files: M `docs/features/parent/README.md` · M `docs/architecture/NAVIGATION.md` · M `docs/context/CURRENT_STATE.md`
- Exit: `node scripts/check-ai-layer.mjs` + `node scripts/verify.mjs` → PASS

## Test matrix
| AC | Rule | Test (tầng) | Phase | Kết quả |
| --- | --- | --- | --- | --- |
| AC-1 | OBS-13, OBS-01 | `evaluation_screen_test.dart` (widget) | 1 | |
| AC-2 | OBS-29 | `evaluation_screen_test.dart` (widget) | 1 | |
| AC-3 | OBS-27 | `evaluation_screen_test.dart`, `theme_result_screen_test.dart` (widget) | 1 | |
| AC-4 | OBS-06 | `evaluation_screen_test.dart` (widget) | 1 | |
| AC-5 | OBS-28 | `evaluation_screen_test.dart` (widget) | 1 | |
| AC-6 | — | `app_router_test.dart` (widget) | 2 | |
| AC-7 | — | `evaluation_screen_test.dart` (chữ 1,3 / 2,0, lỗi, rỗng) | 1 | |

## Rủi ro & rollback
| Rủi ro | Tác động | Giảm thiểu | Rollback |
| --- | --- | --- | --- |
| Thêm route vào vùng dùng chung | Router của mọi vai trò | Chỉ thêm 2 route con phụ huynh theo mẫu Sổ sức khỏe; test router | Gỡ 2 route, trả ô Đánh giá về `RoutePaths.parentChildAt('development')` |
| Dữ liệu giả lệch DTO khi nối BE | Sửa domain khi có API | Field theo DTO BE hiện có; ghi khoảng trống BE ở README | Sửa `domain/evaluation.dart` + nguồn dữ liệu |

## Validation log
- [x] Khẳng định về code có `file:line`
- [x] Đổi contract ⇒ không đổi contract BE
- [x] Mỗi AC có test; mỗi phase có Exit = lệnh + kết quả mong đợi
- [x] >8 file: không tách plan — 3 phase nối tiếp của cùng một màn
- [x] Không dùng rule PENDING/OPEN như đã chốt (4 câu hỏi mở chờ user)
- [x] Tự review: không placeholder · không mâu thuẫn · scope vừa 1 plan · không câu mơ hồ

## Progress log
### 2026-11-18 — Phase 1 (done)
- Màn Đánh giá 5 mục + màn kết quả một chủ đề, dữ liệu giả `FakeEvaluationSource` (Minh Anh Mầm 3A, Bảo Ngọc Lá 1; mốc cuối năm học 28/05/2027).
- Khác plan: Học tập của ngày bỏ dòng đếm "Đạt x/y" ở tiêu đề (nhóm Chưa đạt / Đạt đã ghi số); tên bé hiện dưới AppBar như Sổ sức khỏe thay vì phụ đề AppBar trên canvas.
- Máy có 2 Flutter: PATH là 3.44.0, lockfile cần ≥ 3.47 ⇒ chạy bằng `D:\Flutter_Setup\stable-3.47.6\flutter` (SDK của VS Code).
- `node scripts/verify.mjs` → `VERIFY PASS full | format ok | design ok | analyze ok | tests 433 fail 0 skip 0`.
- Commit: xem `git log` nhánh, chưa push.
