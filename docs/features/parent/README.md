# Parent — màn hình Mobile

Phụ huynh chỉ xem **con có GuardianLink** và **chỉ dữ liệu nhà trường cho phép** (default-deny). Rule: `BE:docs/business/BUSINESS_RULES.md` nhóm PAR + AUTH-04; quyết định: `BE:docs/decisions/ADR-0010-parent-visibility-policy.md`. API phụ huynh là endpoint/DTO riêng — APP hiển thị đúng field DTO có, **không tự lọc/ẩn field thay BE**.

Không có chat (PAR-04) — trao đổi tức thời vẫn qua Zalo.

### Chọn con / Tổng quan con
- Mục đích: chọn con (nếu nhiều), xem tóm tắt hôm nay.
- BE: card `BE:docs/modules/child.md`, `BE:docs/modules/identity-access.md` · rule AUTH-04, PAR-01, PAR-02
- Endpoint: chưa có
- Field: PAR-01 (chốt 29/10, đóng P-13b) — tóm tắt chỉ gồm các mục trong danh sách; một tài khoản xem mọi con (PAR-06).
- Giao diện (bố cục H, user 2026-10-14, `docs/design/mobile-redesign-clay.md`): thẻ bé đang chọn là thẻ lớn; bé khác ló ra dưới thẻ, chạm để đổi; từ 3 bé thì phần ló ghi "+N bé khác" mở sheet chọn bé. Ba ô hôm nay chỉ hiện field đang có (điểm danh, thực đơn đã công bố hay chưa, tên hoạt động); trạng thái của bé đang ló không hiện vì cần thêm một lần gọi dữ liệu.

### Lịch sử điểm danh
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/attendance.md` · rule PAR-01, ATT-09 (Có mặt / Vắng; vắng có phép khi có đơn nghỉ), ATT-03 (sau giờ chốt không nhận trẻ muộn), ATT-08 (PHT mở lại ⇒ dữ liệu có thể đổi sau lần nhập đầu)
- Endpoint: chưa có

### Bữa ăn
- BE: card `BE:docs/modules/nutrition.md` · flow `BE:docs/business/flows/meal-management.md` · rule PAR-01 (thực đơn tuần + thực đơn ngày, ngày có ảnh suất ăn hôm đó), NUT-08 (chỉ thực đơn đã công bố), NUT-13 (một thực đơn chung hai cơ sở — đóng P-07), NUT-16
- Endpoint: chưa có
- Field: PAR-01 (thực đơn tuần/ngày, ảnh suất ăn — chốt 29/10, đóng P-13b).
- Ảnh bữa ăn — **PROPOSED** (user 2026-10-13): (1) bếp chụp ảnh món khi nấu xong; (2) giáo viên chụp khay khi bếp giao tới lớp rồi đăng; phụ huynh xem ảnh món ăn trong thực đơn/lịch của con. BE NUT-16 hiện chỉ ghi bếp chụp ⇒ đề xuất cập nhật BE. Ảnh chỉ tải qua URL có auth; ảnh chụp khay suất ăn, không chụp mặt trẻ.
- Lệch BE (28/10): NUT-16 CONFIRMED chỉ bếp chụp ảnh mẫu mỗi bữa, dùng chung toàn trường; dữ liệu giả `MealPhotoSet` ghi ảnh "GV đăng khi nhận suất" — cần sửa khi tích hợp. **Đã sửa 17/11**: bỏ `MealPhotoSet`, dữ liệu giả ghi "Bếp đăng".
- Ảnh mẫu theo nhóm tuổi — **đề xuất A, user 2026-11-17** (canvas "Ảnh bữa ăn theo nhóm tuổi"): mỗi nhóm tuổi có suất khác nhau nên bếp chụp ảnh mẫu theo nhóm tuổi, một bữa có thể nhiều ảnh (vd. bữa sáng 2–3 ảnh). Phụ huynh chỉ thấy ảnh nhóm tuổi của con, nằm ngay trong thẻ của bữa đó: 1 ảnh một ô rộng, 2 ảnh hai ô, 3 ảnh ba ô vuông, từ 4 ảnh ô thứ ba ghi "+n"; dưới ảnh "Ảnh mẫu nhóm <nhóm> · Bếp đăng <giờ>"; chạm ảnh mở xem toàn màn, vuốt qua các ảnh cùng bữa. Bữa đã qua giờ mà chưa có ảnh ⇒ "Bếp chưa đăng ảnh <bữa>"; chưa tới giờ ⇒ "Có ảnh sau <giờ ăn>". Trạng thái (`MealPhotos` posted / missing / upcoming) do nguồn dữ liệu trả, App không suy theo giờ máy.
- User 17/11 chốt thêm: số ảnh không giới hạn (bếp chụp bao nhiêu cũng được), mỗi bữa nhóm tuổi đó ăn cần ít nhất 1 ảnh; **số bữa** từng nhóm tuổi do Phó HT phụ trách dinh dưỡng cấu hình (NUT-17), vd. mẫu giáo 3 bữa, mẫu giáo lớn 2 bữa. Bé lớp Lá (dữ liệu giả: nhóm Lá ăn 2 bữa) chỉ thấy bữa trưa và bữa chiều; bữa trưa hôm nay "Bếp chưa đăng ảnh bữa trưa", khớp màn "Ảnh mẫu bữa ăn" của bếp (`docs/features/kitchen/README.md`).
- Lệch BE (17/11, **chưa làm BE theo user**): `MealPhoto` hiện theo điểm trường + ngày + bữa, mỗi bữa 1 ảnh (đăng lại là thay). Để nối cần BE thêm nhóm tuổi, nhiều ảnh mỗi bữa, số bữa theo nhóm tuổi (PHT dinh dưỡng cấu hình theo NUT-17, user chốt 17/11) và trạng thái ảnh theo bữa. Đến lúc đó App dùng dữ liệu giả.

### Sổ sức khỏe (đã công bố)
- BE: card `BE:docs/modules/health.md` · flow `BE:docs/business/flows/health-check.md` · rule HLT-02 (trend do BE tính), HLT-04, HLT-05, HLT-21 (diễn giải AI chỉ hiện khi đã duyệt), PAR-02
- Endpoint: chưa có
- User 17/11 (canvas "Sổ sức khỏe"): màn riêng mở từ ô "Sổ sức khỏe" ở Trang chủ, thay tab Sức khỏe cũ của Bé của tôi (từ 18/11 Bé của tôi là một trang, không còn tab — xem mục Bé của tôi). Ba phần: **Kỳ cân đo** (accordion, kỳ mới nhất mở sẵn: chiều cao, cân nặng, BMI, mức BMI theo tuổi, ghi chú của cô) · **Đợt khám** (mỗi đợt một thẻ; chạm mở màn Chi tiết đợt khám với đủ phiếu: kết luận + lời dặn, tiền sử, dấu hiệu sinh tồn, dinh dưỡng, phát triển, tiêm chủng, 24 mục khám lâm sàng; bỏ phần hành chính của phiếu) · **Xu hướng** (biểu đồ chiều cao, cân nặng theo thời gian thật, lọc 6 tháng | 12 tháng | Toàn bộ; chấm rỗng là số đo khi khám; nhận định AI đã được GV chủ nhiệm duyệt). Dữ liệu giả `FakeHealthBookSource`, route ở `docs/architecture/NAVIGATION.md`.
- Phân loại theo WHO do BE trả (HLT-03, HLT-10; đóng P-13) — APP không tự tô màu "bất thường". Cân đo chỉ hiện sau khi GV/PHT công bố (HLT-11, PAR-03).
- Lệch BE (17/11, cần thống nhất khi tích hợp): `GET /children/{childId}/health/published` (`PublishedHealthResponse`) chỉ trả số đo + kết luận ngắn của phiếu khám ⇒ màn Chi tiết đợt khám cần BE trả đủ các mục phiếu (trừ phần hành chính), tên bác sĩ, đơn vị khám. Nhận định đã duyệt chỉ có `summary` + `warnings` ⇒ phần Tổng quan / Cần chú ý / Điểm tích cực / Lưu ý về dữ liệu, tên khoảng phân tích và cờ "đã có số đo mới sau lần duyệt" (`stale`) cần BE trả theo phần, hoặc App gộp lại khi nối.
- Từ 29/10 PAR-01 có thêm sức khỏe trong ngày và xử trí (HLT-14, báo ngay, không chờ công bố) — đối chiếu màn Hôm nay khi tích hợp.
- Biểu đồ tự vẽ (chưa chọn thư viện chart), không tô vùng chuẩn.
- Dị ứng của con: card `BE:docs/modules/child.md` · HLT-06 (phụ huynh khai khi nhập học, mức nhẹ/nặng — đóng P-17), NUT-23. Hiện ở Bé của tôi (Sức khỏe đã khai báo) và Thực đơn tuần.

### Cập nhật phát triển (đã duyệt) & Hoạt động hằng ngày
- BE: card `BE:docs/modules/learning-observation.md` · flow `BE:docs/business/flows/child-observation.md` · rule OBS-03, OBS-05, OBS-06, OBS-10, OBS-13, OBS-14, EDU-09, PAR-01, PAR-03
- Endpoint: chưa có
- Đã chốt 29/10: phụ huynh nhận mọi kỳ nhận xét (OBS-06, đóng P-12); đánh giá ngày hiện sau khi GV lưu (OBS-13); dữ liệu có công bố chỉ hiện sau khi công bố (PAR-03, đóng P-13b).
- "Hoạt động hằng ngày": phụ huynh thấy tên các hoạt động trong ngày của lớp (EDU-09), lấy từ kế hoạch ngày (OBS-07, ADR-0019). UI dữ liệu giả `/parent/activities` chỉ có ở bản debug (user cho dựng giả 2026-10-13, plan `docs/plans/completed/2026-10-13-ui-mockup-redesign.md` K1); bật ở release khi BE có API kế hoạch ngày.
- Phiếu bé ngoan / khen thưởng cuối năm (tab Phát triển, khối cũ): OBS-10 (phiếu tuần, phụ huynh thấy ngay khi GV xác nhận), OBS-14 (khen cuối năm); làm cả hai: P-31 — số phiếu và ngưỡng là BE trả. Từ 18/11 có trang Khen thưởng riêng (xem mục dưới); khối cũ bỏ cùng tab Phát triển khi Bé của tôi thành một trang (18/11).
- Lối tắt ở Trang chủ (user 17/11, sửa 18/11): mục "Việc nhanh" hàng thứ ba gồm "Đánh giá" và "Khen thưởng", từ 18/11 mở hai trang riêng (xem các mục dưới). Ô "Hoạt động & đánh giá" (đánh giá ngày) giữ nguyên. Bé của tôi thành một trang (xem mục dưới); link cũ `/parent/child?tab=development&section=rewards` vẫn mở Bé của tôi, bỏ qua tham số.

### Trang Đánh giá (đã lưu / đã gửi / đã xác nhận)
- BE: card `BE:docs/modules/learning-observation.md` · rule OBS-01, OBS-02, OBS-05, OBS-06, OBS-12, OBS-13, OBS-27, OBS-28, OBS-29, PAR-03 · plan `docs/plans/completed/2026-11-18-parent-evaluation-page.md`
- Endpoint: chỉ có `GET /children/{childId}/weekly-comments` (nhận xét tuần đã gửi, OBS-29). Đánh giá ngày, cuối chủ đề, học kỳ, cuối năm chưa có API cho phụ huynh ⇒ dữ liệu giả `FakeEvaluationSource` (mốc cuối năm học 2026–2027; Minh Anh Mầm 3A, Bảo Ngọc Lá 1).
- User 18/11 (canvas "Đánh giá của bé"): trang riêng mở từ ô "Đánh giá" ở Trang chủ, thanh 5 mục kiểu segmented: **Ngày** (‹ › đổi tuần, dải ngày; Sinh hoạt lưới 2 cột, mặt khác thường tô cam kèm icon; Học tập: tham gia, nhóm Chưa đạt trước, nhóm Đạt sau, kèm tên hoạt động; Lời cô nhắn; cờ ngày; ngày vắng / cô chưa lưu báo riêng) · **Tuần** (nhận xét đã gửi, mới nhất mở sẵn, tuần cũ trích 3 dòng + "Đọc tiếp") · **Chủ đề** (nhóm theo học kỳ, mỗi dòng số MT đạt / tổng + Đạt / Chưa đạt; chạm mở màn kết quả chủ đề: MT chưa đạt trước, MT đạt sau, hiện đủ) · **Học kỳ** (‹ › đổi học kỳ; số lĩnh vực đạt; lĩnh vực chưa đạt mở sẵn, MT chưa đạt kèm "Đạt ở x/y chủ đề") · **Cuối năm** (phiếu sự phát triển: số MT đạt, nhãn Hoàn thành chương trình mầm non cho lớp 5–6 tuổi, nhận xét của cô, lưu ý cho gia đình, lĩnh vực có nhận xét của cô).
- User 18/11 (sau khi xem App): lĩnh vực ở Học kỳ, Cuối năm mở ra là thấy đủ MT (chưa đạt trước, đạt sau), bỏ nút "Xem N mục tiêu đạt"; màn kết quả chủ đề bỏ "Xem thêm N mục tiêu" (không thu gọn). Lĩnh vực vẫn chạm tên để mở/đóng; lĩnh vực có MT chưa đạt mở sẵn. Cuối năm bỏ thẻ "Cân đo cuối năm" — số đo xem ở Sổ sức khỏe; cân đo của phiếu (BE `SheetMeasurement`) không hiện cho phụ huynh ở trang này.
- User 18/11 chốt: phiếu cuối năm chỉ hiện "Lưu ý cho cha mẹ" (3 lưu ý còn lại không hiện); "Chưa đạt" tông đỏ như web; ghi chú chung cả lớp của bảng cuối chủ đề không hiện cho phụ huynh; chủ đề đang học hiện "Đang học · Chưa có kết quả", không mở được. Không có mục Tháng (màn Đánh giá tháng đã bỏ — OBS-26). Mục tiêu chỉ Đạt / Chưa đạt.
- Khác canvas: tên bé hiện dưới AppBar như Sổ sức khỏe (canvas để ở phụ đề AppBar); chữ phóng lớn thì nhãn thanh 5 mục xuống dòng (`AppSegmented` sẵn có) thay vì cuộn ngang; mục Ngày bỏ dòng đếm "Đạt x/y" ở tiêu đề Học tập vì hai nhóm đã ghi số.
- Lệch BE (18/11, cần thống nhất khi tích hợp): cần API phụ huynh cho đánh giá ngày (OBS-13) và kết quả cuối chủ đề, học kỳ, cuối năm theo trẻ, chỉ bản đã xác nhận (OBS-05, PAR-03); cần field đếm sẵn "số lĩnh vực đạt" của trẻ trong học kỳ và "số MT đạt" theo lĩnh vực ở phiếu cuối năm (App không tự đếm — DESIGN.md §2.1 quy tắc 12); đánh giá ngày cần tên hoạt động kèm từng MT (BE `EvaluationDay` chỉ có danh sách MT đạt / chưa đạt).

### Trang Khen thưởng (đã phát / đã duyệt)
- BE: card `BE:docs/modules/learning-observation.md` · rule OBS-10, OBS-14, OBS-23, PAR-03, PAR-09 · plan `docs/plans/completed/2026-11-18-parent-rewards-page.md`
- Endpoint: chưa có cho phụ huynh — API phiếu `/assessment/behaviour-tickets/*` cần quyền ASSESSMENT_VIEW (GV, BGH), danh sách khen thưởng chỉ cho GV, PHT, HT ⇒ dữ liệu giả `FakeRewardSource` (cùng mốc trang Đánh giá: thứ Sáu 28/05/2027; Minh Anh Mầm 3A, Bảo Ngọc Lá 1).
- User 18/11 (canvas "Khen thưởng của bé", https://claude.ai/artifact/2WM74tr1wVBDiCd4ecdYRA): trang riêng mở từ ô "Khen thưởng" ở Trang chủ, thanh 3 mục: **Tuần** (tuần mới nhất: số cờ, cờ từng ngày T2–T6 — có cờ, không cờ, nghỉ, chưa có; câu "Từ N cờ trong tuần, cô xét phiếu Bé ngoan khi hết tuần" hoặc phiếu đã phát + người phát, ngày phát; nút "Xem đánh giá từng ngày" mở trang Đánh giá. Các tuần trước nhóm theo tháng, tuần có phiếu mang nhãn "Bé ngoan", "Xem các tuần trước" mở thêm 2 tháng) · **Tháng** (tháng mới nhất: số phiếu Bé ngoan, ô từng tuần, câu ngưỡng hoặc phiếu Bé ngoan toàn diện đã phát; các tháng trước có số phiếu tuần và nhãn "Bé ngoan toàn diện") · **Cuối năm** (danh hiệu, Lời cô, "Hiệu trưởng duyệt ngày …"; thẻ Cả năm học: cờ, phiếu tuần, phiếu tháng). Nút "?" mở sheet "Cách bé nhận khen thưởng" (cờ → phiếu tuần → phiếu tháng → danh hiệu).
- User 18/11 chốt: phụ huynh xem ghi chú của cô trong danh sách khen thưởng (mục Lời cô); phiếu tháng giữ tên "Bé ngoan toàn diện", không thêm nhãn "xuất sắc" (OBS-10); danh sách đã duyệt mà bé không có danh hiệu ⇒ "Năm học này bé chưa có danh hiệu"; chưa duyệt (chờ PHT/HT hay bị trả lại) ⇒ chỉ "Chưa có danh hiệu cuối năm"; có báo đẩy khi bé nhận phiếu tuần, phiếu tháng, danh hiệu.
- Chỉ ghi "cô xét", không ghi "đủ điều kiện": GV chọn trẻ nhận phiếu, hệ thống không gợi ý (OBS-10). Ngưỡng 3 cờ / 3 phiếu lấy từ `rules` BE trả (`WEEK_MIN_FLAGS`, `MONTH_MIN_WEEKLY_TICKETS`), App không ghi cứng.
- Khác canvas: danh hiệu tông xanh lá (canvas cũ vàng; tông `approval` chỉ dành cho "chờ duyệt" — `.claude/rules/ui-style.md`); icon theo `AppIcons` (thêm `ticket`, `medal`, `star`, `help`); nhãn "Bé ngoan toàn diện" ở các tháng trước nằm dưới số phiếu để chữ lớn không tràn; tên bé hiện dưới AppBar như trang Đánh giá.
- Lệch BE (18/11, cần thống nhất khi tích hợp): cần API phụ huynh theo trẻ trả cờ từng ngày của tuần (ngày có mặt), phiếu tuần và tháng đã phát (kỳ, số cờ, người phát, ngày phát), số phiếu tuần theo tháng, danh hiệu + ghi chú của cô khi danh sách APPROVED kèm ngày HT duyệt, tổng cả năm, ngưỡng; PAR-09 cần loại báo đẩy "khen thưởng mới" (phiếu tuần, phiếu tháng, danh hiệu) — chỉ câu chung + deep link `/parent/rewards`; màn lập danh sách khen thưởng trên web nên báo GV rằng phụ huynh xem được ghi chú.

### Bé của tôi (hồ sơ của bé)
- BE: card `BE:docs/modules/child.md` · rule AUTH-04, CHD-02, CHD-05, CHD-06, HLT-06, PAR-02 · plan `docs/plans/completed/2026-11-18-parent-my-child-profile.md`
- Endpoint: chưa có API phụ huynh cho hồ sơ trẻ ⇒ dữ liệu giả `FakeMyChildSource.loadProfile` (Minh Anh Mầm 3A, Bảo Ngọc Lá 1).
- User 18/11 (canvas "Bé của tôi gộp Hồ sơ", https://claude.ai/artifact/9auLezc8PN6y71Be6E8EEr; thay bản "hành trình" làm cùng ngày): tab Bé của tôi là hồ sơ của bé, gộp trang Hồ sơ của bé cũ (P13; route `/parent/child-profile` đã bỏ). Không có thanh chọn bé: tab theo bé đang chọn ở Trang chủ (`SelectedChild`); phụ huynh có 2 bé đổi bé ở Trang chủ. Thứ tự: thẻ đầu (ảnh chữ cái lớn, tên, lớp · tuổi, năm học; không có nút) · Thông tin chung (ngày sinh, giới tính, cơ sở) · Giáo viên chủ nhiệm (nút gọi mở "Sắp có" — chưa có plugin quay số) · Sức khỏe đã khai báo (dị ứng, chế độ ăn, tiền sử bản thân, tiền sử gia đình) · Người đưa đón đã đăng ký · ghi chú "Thông tin do nhà trường quản lý…". Bỏ Hành trình năm học, Phát triển, Danh hiệu: số đo xem ở Sổ sức khỏe, nhận xét ở Đánh giá, phiếu và danh hiệu ở Khen thưởng (đều ở Việc nhanh, Trang chủ). Link "Xem hồ sơ của <bé> ›" trên thẻ bé ở Trang chủ chuyển sang tab này.
- Sức khỏe đã khai báo theo bảng BE `child_health_declarations` (CHD-06), mỗi mục `REPORTED` / `NONE_REPORTED` / `NOT_PROVIDED`. Tiền sử bản thân, gia đình (user 18/11 thêm) ghi như web: "Có — <tên bệnh>" / "Không" / "Chưa cung cấp", không tô màu. Dị ứng: mỗi chất một chip tông đỏ có icon (DESIGN.md: chip phân loại dị ứng `red`), hoặc "Không" / "Chưa cung cấp". Chế độ ăn: chữ BE trả / "Bình thường" / "Chưa cung cấp".
- Khác canvas: chip dị ứng tông đỏ (canvas cam) theo DESIGN.md.
- Lệch BE (18/11, cần thống nhất khi tích hợp): PAR-01 chưa liệt kê hồ sơ trẻ và khai báo sức khỏe, PAR-02 mặc định không hiện ⇒ cần BE cho phép và thêm API phụ huynh theo trẻ trả hồ sơ (ngày sinh, giới tính, cơ sở, lớp, năm học, GV chủ nhiệm, người đưa đón) và khai báo sức khỏe (dị ứng, chế độ ăn, tiền sử bản thân, gia đình). Tiền sử là dữ liệu nhạy cảm (CHD-02): chỉ con của phụ huynh (AUTH-04), không đưa vào push hay log.

### Báo nghỉ (đơn nghỉ)
- BE: card `BE:docs/modules/attendance.md` · flow `BE:docs/business/flows/leave-request.md` · rule ATT-05 (CONFIRMED), ATT-04, ATT-09, ATT-05b (PROPOSED) · permission `leave:create`
- Mục đích: phụ huynh gửi **thông báo nghỉ** cho con (từ ngày, đến ngày, lý do), xem danh sách đã gửi, hủy thông báo. **Không có bước duyệt** — không hiển thị trạng thái chờ duyệt/duyệt/từ chối. Chỉ phụ huynh tạo; GV không tạo thay (ATT-05).
- Trạng thái: `SUBMITTED → CANCELLED` (phụ huynh hủy). Ngày có đơn ⇒ trẻ Vắng có phép tự động, không có suất (ATT-04, ATT-09); ngày đã qua giờ chốt/đã xác nhận suất (ATT-05b) do BE xử lý — APP hiển thị kết quả/lỗi BE trả, không tự tính.
- Endpoint: chưa có. Giờ chốt: một giờ chung toàn trường, HT cấu hình (ATT-06, đóng P-03) — BE quyết định, APP không khóa theo giờ máy. PENDING: P-20 (con có đơn nghỉ vẫn đến lớp).
- Mockup P03–P04 (user 2026-10-13) thêm **buổi nghỉ** (cả ngày / sáng / chiều), **lý do tự nhập** (≤500 ký tự) và trạng thái **GV đã xem / GV chưa xem** — BE chưa có field `session`, `seenByTeacher` ⇒ đề xuất BE. Nghỉ nửa buổi xử lý suất ăn ra sao chưa có rule ⇒ form chỉ báo huỷ suất khi nghỉ cả ngày (ATT-04). Mockup chưa có thao tác huỷ đơn; danh sách vẫn hiển thị "Đã huỷ" nếu BE trả.
- Lệch BE (28/10): ATT-05 chỉ có ngày bắt đầu–kết thúc + lý do, không có buổi nghỉ; suất tính theo điểm danh cả ngày (ATT-02) — field `session` (`LeaveSession`) cần bỏ hoặc đề xuất BE khi tích hợp. **User 17/11: giữ buổi nghỉ và câu "Suất ăn … sẽ được huỷ tự động" theo Figma; BE sửa sau rồi nối** (thêm `session` vào API tạo đơn, luật suất ăn khi nghỉ nửa buổi, xử lý ngày gửi sau giờ chốt — ATT-05b — cho khớp câu huỷ suất).
- Giao diện form (Figma PH03, user 2026-11-17, thay bố cục D của 14/10; style Clay theo DESIGN.md): thẻ bé hai dòng "Bé <họ tên>" / "Lớp <lớp>"; hai ô "Từ ngày *" và "Đến ngày *", bấm ô mở lịch tháng trong sheet, chạm một ngày là chọn; ngày đã qua và quá 180 ngày không chọn được, ô Đến ngày không chọn ngày trước Từ ngày (hỗ trợ nhập, BE vẫn kiểm tra cut-off); ngày đã có đơn nghỉ có chấm + nhãn "Đã báo nghỉ" lấy từ danh sách đơn BE trả; chữ hệ thống lớn thì hai ô xếp dọc. Hộp cam: dòng đậm báo huỷ suất (chỉ khi nghỉ cả ngày) + dòng báo cô giáo lớp.

### Tài khoản phụ huynh
- BE: card `BE:docs/modules/identity-access.md` · rule AUTH-18 (tên đăng nhập = SĐT; tài khoản + mật khẩu tạm gửi qua SMS, in phiếu dự phòng — code BE hiện chỉ có in phiếu), CHD-05 (chỉ sửa thông tin liên lạc của mình; thông tin trẻ do trường sửa), CHD-04 (trẻ thôi học ⇒ mất quyền xem trẻ đó ngay; tài khoản vẫn dùng cho trẻ khác) · PENDING P-28 (số tài khoản mỗi trẻ)
- Endpoint: chưa có. Danh sách con và field được sửa là BE trả; APP không tự lọc trẻ thôi học. Màn "Thông tin cá nhân" dùng chung đang cho sửa họ tên, SĐT, email — field nào phụ huynh được sửa và đổi SĐT (là tên đăng nhập) theo contract BE.

### Đón con
- BE: card `BE:docs/modules/attendance.md` · rule PCK-04 (ai đã đón, giờ đón; thông báo khi con được đón), PCK-03 (không đăng ký trước người đón hộ trên App — báo GV qua gọi/nhắn).
- Endpoint: chưa có.

### Nhận thông báo
- `docs/integration/PUSH_NOTIFICATION.md` — nội dung chung + deep link, không dữ liệu sức khỏe.
- Thông báo của trường do BGH gửi, push + trong App, không có trạng thái đã đọc (PAR-05). Phụ huynh gửi ý kiến cho trường: P-32 (chưa làm).

## Known pitfalls
- Lời chào đặt cạnh nút chuông (không còn hero): `Semantics` phải có `container: true`, không thì gộp thành một câu đọc — `docs/knowledge/incidents/APP-BUG-261014-greeting-bell-semantics-merge.md`.
