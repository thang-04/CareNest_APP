# Teacher app — thay đổi màn hình (15/11/2026)

Nhánh `feature/teacher-app-screens` (từ `dev`). Vẫn dữ liệu giả sau interface nguồn dữ liệu; chưa gọi API. Đối chiếu API: `docs/plans/teacher-app-gap.md`.

## Màn thao tác (3 nhóm)

| Màn | Trước | Sau |
| --- | --- | --- |
| Trang chủ GV (T01) — sửa lần 2 theo Figma | Bố cục D (thẻ lớn + vòng tiến độ + việc trượt ngang) | Theo Figma T01: dải xanh lời chào, thẻ lớp "Lớp Mầm 3A · 28 bé" + ô "Lịch hoạt động ›", dải cam hạn điểm danh, danh sách dọc "Việc cần làm hôm nay" (việc đầu viền xanh) |
| Trang chủ GV (T01) — nội dung | Việc: Điểm danh & báo ăn, Đơn nghỉ, Đánh giá, Ảnh bữa ăn, Đón trẻ, Đo sức khỏe | `Cần làm`: ① Điểm danh → ② Sức khỏe (đầu ngày + cân đo) → ③ Trả trẻ. `Xem nhanh`: Đơn nghỉ, Đánh giá. Bỏ Ảnh bữa ăn |
| Điểm danh (T02) — sửa lần 2 | — | Nút "Tất cả có mặt" (bé có đơn nghỉ giữ Vắng); không nhập bữa ăn (ATT-02: có mặt = ăn), chỉ hiện "Suất ăn: N"; bỏ chữ giải thích dài trên 4 màn thao tác |
| Điểm danh (T02) | Tiêu đề "Điểm danh & báo ăn"; mặc định chưa điểm danh; nút "Đánh dấu tất cả có mặt"; chạm tên để báo ăn; ô "Chưa ĐD" | Tiêu đề "Điểm danh"; mặc định **Có mặt**; bé có đơn nghỉ mặc định Vắng (có phép) + nhãn "Có đơn nghỉ", GV vẫn đổi sang Có mặt; chỉ hai nút Có mặt / Vắng; bỏ báo ăn (ATT-02); nút "Lưu và sang Sức khỏe đầu ngày" ⇒ lưu xong mở màn Sức khỏe |
| Sức khỏe đầu ngày | Chưa có | **Mới.** Danh sách bé có mặt, ô đếm Có mặt / Đã kiểm tra / Cần lưu ý; bé chưa ghi hiện "Chưa kiểm tra". Chạm bé ⇒ form theo `DailyHealthRequest`: thân nhiệt (tùy chọn, 20,0–45,0 °C), Bình thường / Cần lưu ý, biểu hiện, đã xử trí, chuyển cơ sở y tế (nơi, giờ, người đi kèm), ghi chú ≤500. BE không cho ghi ⇒ chỉ xem |
| Trả trẻ (T05) | "Đón trẻ"; dòng "Đăng ký: Mẹ …, Bố …"; nút "Giao bé" | "Trả trẻ"; bảng Chờ đón / Đã đón theo `PickupBoardResponse`; dòng đã đón ghi giờ + người đón; nút "Trả trẻ" |
| Trả trẻ một bé (T06) | "Người đón đã đăng ký" (PCK-03 không có); chọn thẻ rồi "Đúng – giao bé"; "Không khớp – gọi phụ huynh" (Sắp có) | Thẻ bé + thẻ lớn từng phụ huynh trên hồ sơ (quan hệ, tên, SĐT, ảnh); mỗi phụ huynh có "Gọi" (mở trình quay số qua `url_launcher`, lỗi thì báo số để gọi tay) và "Trả trẻ" (PHOTO_MATCH, tự ghi giờ). Phụ huynh chưa có ảnh ⇒ "Trả trẻ" tắt, phải gọi. "Ghi kết quả gọi phụ huynh" ⇒ ghi chú bắt buộc, chọn "Phụ huynh đồng ý – trả trẻ" (PHONE_CONFIRMED) hoặc "Không trả trẻ" (PHONE_DECLINED) |

## Màn chỉ xem

| Màn | Bỏ | Thêm / giữ |
| --- | --- | --- |
| Đánh giá hằng ngày — danh sách (T04) | Nút "Đánh giá" | Nhãn Chưa đánh giá / Đã xong / Vắng; chạm xem chi tiết |
| Đánh giá hằng ngày — một bé (T04.1) | Chip chọn mức, ô ghi chú, cờ, nút "Lưu & về danh sách" | Banner "Chỉ xem. Đánh giá thực hiện trên web."; 7 mặt (OBS-02) với mức Đạt / Cần cố gắng / Chưa đạt; nhận xét; cờ nếu có |
| Cân đo — danh sách (T07) | Nút "Đo" | Nhãn Chưa đo / Đã đo / Vắng; chạm bé để nhập hoặc sửa |
| Cân đo — một bé (T07.1) | Ô chiều cao/cân nặng, công tắc công bố | Nhập chiều cao/cân nặng theo giới hạn BE; ghi chú tùy chọn; sửa bắt buộc lý do; lưu là công bố, không có công tắc; kết quả BE tính, không chẩn đoán |
| Đơn nghỉ của lớp (T03) | Nút "Đánh dấu đã xem" | Danh sách đơn (badge Mới / Đã xem vẫn là dữ liệu giả — BE chưa có field) |
| Lịch hoạt động (T10) | Nút "Đánh giá hoạt động hôm nay" | Lịch theo ngày |
| Lớp học (T09) | — | Không đổi (vốn chỉ xem) |

## Màn ẩn

- Ảnh bữa ăn của GV (T15/T16): bỏ route và việc trên Trang chủ (NUT-16: chỉ bếp chụp). Ngày 17/11 user chốt bỏ hẳn màn này: đã xoá code feature `teacher/meal_photos` và test.

## Còn mở

- Mã Jira cho commit (repo bắt buộc `G94-xxx: …`).
- `flutter upgrade`: máy có Flutter 3.41.9 / Dart 3.11.5, repo cần Dart ^3.12.0 ⇒ chưa chạy được `flutter analyze` / `flutter test` / ảnh chụp màn hình.
- `url_launcher` đã thêm vào `pubspec.yaml` (user đồng ý 15/11) nhưng **`pubspec.lock` chưa cập nhật** vì `flutter pub get` không chạy được với Flutter cũ.
- Thư viện HTTP / state / lưu token / OAuth PKCE để nối API: chưa chọn.
- API thiếu và lệch: xem `docs/plans/teacher-app-gap.md` mục cuối.

## Sửa lần 3 — khớp màn Web giáo viên (CareNest_FE, 15/11)
- Điểm danh: bé chưa ghi là "Chưa ĐD" như Web; nút "Có mặt tất cả" chỉ áp bé chưa điểm danh; bé có đơn nghỉ hiện "Phụ huynh báo nghỉ", Vắng có phép, không sửa; "Khóa lúc HH:mm"; không nhập bữa, chỉ "Suất ăn: N" (ATT-02).
- Sức khỏe: nhãn biểu hiện/xử trí như Web ("Cảm cúm", "Mệt mỏi", "Theo dõi tại lớp", "Đã gọi điện cho phụ huynh", "Báo phụ huynh đón về sớm", "Chuyển cơ sở y tế / cấp cứu"); Cần lưu ý phải có biểu hiện hoặc ghi chú.
- Trả trẻ: sheet gọi phụ huynh "Nội dung cuộc gọi" bắt buộc, nút "Trả trẻ" / "Không trả", lỗi "Ghi nội dung cuộc gọi với phụ huynh."
- Giữ khác Web: lưu điểm danh xong tự sang Sức khỏe đầu ngày (Web để chung một trang).
