# CareNest Mobile — thiết kế lại theo style Clay nổi

Kết quả Phase 0 của plan `docs/plans/active/2026-10-13-fe-aligned-mobile-ui.md`. User chọn trên wireframe ngày 2026-10-14. Tài liệu này là đặc tả để dựng Flutter; quyết định bổ sung Q1–Q5 ở cuối.

## Nguồn

- Wireframe đã chọn: `docs/design/wireframes/carenest-mobile-wireframe.html` (mở bằng trình duyệt; tham số `?man=<màn>&v=<bố cục>&st=clay&xem=mot&mau=mau`). Ảnh trong `docs/design/wireframes/img/` là tranh minh hoạ và logo của FE, không có ảnh hay dữ liệu trẻ thật.
- Token màu: `lib/core/constants/colors.dart` (cùng mã với FE `src/styles/tokens.css`). Style Clay không thêm màu thương hiệu mới.
- FE đã có token clay: `--shadow-clay`, `--shadow-clay-hover`, `--shadow-clay-btn` (FE `src/styles/tokens.css`, khối Elevation).

## Lựa chọn của user

| Màn | Bố cục | Nguồn quyết định |
| --- | --- | --- |
| Phụ huynh — Trang chủ | **H · Thẻ ví xếp chồng các bé** | user chọn |
| Hiệu trưởng — Tổng quan | **D · Hai cơ sở cạnh nhau** | user chọn |
| Đăng nhập | A · Logo giữa, form trong card | khuyên dùng — user xác nhận (Q1) |
| Phụ huynh — Xin nghỉ | D · Lịch tháng chọn khoảng ngày | khuyên dùng — user xác nhận (Q1) |
| Giáo viên — Trang chủ | D · Thẻ lớp + vòng điểm danh | khuyên dùng — user xác nhận (Q1) |
| Giáo viên — Điểm danh | A · Tổng số + danh sách hai nút | khuyên dùng — user xác nhận (Q1) |
| Bếp — Trang chủ | D · Chữ lớn đọc từ xa | khuyên dùng — user xác nhận (Q1) |
| Phó HT — Trang chủ | F · Mốc giờ buổi sáng | khuyên dùng — user xác nhận (Q1) |

Style: **Clay nổi cho toàn app**, và cho cả 13 thành phần ở trang "Từng mục" — user chọn. Màn chưa có wireframe giữ bố cục hiện tại, đổi sang thành phần Clay.

## Thành phần Clay → Flutter

Số trong bảng lấy nguyên từ wireframe (`[data-st="clay"]`). Flutter `BoxShadow` không có bóng trong (inset), nên cột cuối ghi cách dựng thay thế.

| Thành phần | Clay trên wireframe | Dựng trong Flutter |
| --- | --- | --- |
| Nền màn | Giữ `#F1F9FE` (Q2: không dùng `#E6F2FC` của wireframe) | `AppColors.background`, không đổi |
| Card (`AppCard`) | Bo 28; viền sáng trên `inset 0 2 0 rgba(255,255,255,.95)`; tối nhẹ dưới `inset 0 -3 0 rgba(11,114,188,.07)`; bóng `0 16 30 -14 rgba(79,176,245,.55)` + `0 3 8 -3 rgba(16,24,40,.08)` | Hai lớp ngoài là `AppShadows.card`; mép sáng là `Border.all` trắng 85% (Flutter không cho viền khác màu từng cạnh khi đã bo góc); bỏ lớp tối nhẹ dưới |
| Nút chính (`AppButton`, `AppButtonVariant.primary`) | Nền `brand`, chữ `onBrand`; gờ đáy `inset 0 -3 0 rgba(0,0,0,.14)`; quầng `0 8 16 -8 rgba(79,176,245,.75)` | `AppShadows.buttonPrimary`: gờ đáy là bóng cứng lệch xuống 3px màu `brand` tối hơn + quầng; chỉ khi bấm được. Q3: user cho phép, đã sửa `DESIGN.md` §5.5 |
| Nút phụ / nhạt | Gờ đáy `inset 0 -2 0 rgba(16,24,40,.06)` | Như nút chính, không quầng |
| Ô icon 40 (`AppIconTile`) | Gradient 150° tông 26% → 9% trên nền trắng; viền sáng trên; quầng màu tông | `LinearGradient` + `BoxShadow` màu tông 45% |
| Badge (`AppStatusBadge`) | Không viền; nền tông 16%; bóng màu tông nhẹ | Bỏ viền, thêm `BoxShadow` nhỏ |
| Ô nhập (`AppTextField`) | Không viền; lõm vào `inset 0 2 4 rgba(16,24,40,.07)` + vòng 1px `border`; focus vòng 2px `primary` + 5px `focusRing` | Lõm vào bằng gradient nền trên → dưới; giữ viền 1px; focus như hiện tại nhưng 2px |
| Segmented (`AppSegmented`) | Rãnh lõm vào; mục đang chọn nổi bóng card | Rãnh gradient `border` → `track`; mục chọn `AppShadows.buttonSecondary` |
| Thanh dưới (`AppShell`) | Nổi, cách mép 12, bo 28, cao 68, bóng card | `Padding` + `ClipRRect` + `DecoratedBox` quanh `NavigationBar`; giữ nhãn luôn hiện, viên chỉ báo `primarySoft` |
| Vùng nút đáy (`AppBottomDock`) | Nổi, cách mép 12, bo 28 | Như thanh dưới; vẫn tránh home indicator bằng `SafeArea` |
| Thẻ số / ô số nhỏ (`AppStatTile`) | Gradient tông 12% → trắng; ô số nhỏ có quầng màu tông | Giữ gradient hiện có, thêm bóng |
| Banner (`AppBanner`) | Không viền; viền sáng trên + bóng mềm | Bỏ viền, thêm bóng |
| Chip lọc, nút chọn | Không viền; gờ đáy + bóng nhẹ | Như nút phụ |
| Thanh tiêu đề màn con | Nền trong suốt, không kẻ dưới | `AppBarTheme` nền `transparent`, bỏ `shape` |

Giữ nguyên: bảng màu `DESIGN.md` §4, font Be Vietnam Pro, thang chữ §5.1, khoảng cách §5.2, vùng chạm ≥48, độ tương phản AA.

## Bố cục đã chọn — điểm cần giữ khi dựng

- **PH Trang chủ H:** lời chào nhỏ + tên phụ huynh; thẻ bé đang chọn (avatar 56, tên, lớp, badge điểm danh, dải 3 ô Đến lớp / Bữa trưa / Hoạt động, link "Xem hôm nay"); thẻ bé kia ló ra dưới, chạm để đổi. Từ 3 bé: phần ló ghi "+N bé" và mở `AppBottomSheet` chọn bé hiện có. Một bé: không có phần ló. Dưới là lưới 2×2 "Việc nhanh". Thay mục "chip chọn con" của `DESIGN.md` §8.5 (Q5: user đồng ý).
- **HT Tổng quan D:** lời chào; hai thẻ cơ sở cạnh nhau (vòng tỉ lệ có mặt, có mặt/sĩ số, suất đã chốt, trạng thái bếp); mục "Chờ Hiệu trưởng duyệt". Không có "Nghỉ phép nhân sự" (`docs/features/principal/README.md`, H05 không làm). Tỉ lệ, số suất, trạng thái bếp là số BE trả.
- Các màn khuyên dùng còn lại: xem wireframe đúng tham số ở bảng trên; chi tiết chốt sau khi user xác nhận Q1.

## Trạng thái bắt buộc mỗi màn

Có dữ liệu, đang tải (khung chờ đúng hình dòng thật), rỗng (câu + hành động nếu có), lỗi (một khối lỗi cho cả màn, nút "Thử lại", dữ liệu cũ giữ nguyên). Đã vẽ trên wireframe, nút Trạng thái.

## Quyết định bổ sung

Q1–Q5 user trả lời 2026-10-14, ghi ở mục "Câu hỏi mở" của plan: bố cục khuyên dùng cho 6 màn; giữ nền `#F1F9FE`; nút có bóng clay; card bo 28, thanh dưới và vùng nút đáy nổi; `DESIGN.md` §8.5 đổi theo bố cục mới.
