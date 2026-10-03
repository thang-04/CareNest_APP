# CareNest — bối cảnh Mobile

Nguồn: brief CareNest do chủ dự án cung cấp ngày 23/09/2026. CareNest_APP là client Mobile cho Phụ huynh, Giáo viên và Nhà bếp; chức năng BGH trên app chỉ được xét khi có yêu cầu cụ thể. Repo này sở hữu trải nghiệm mobile, điều hướng, trạng thái, tích hợp API và thông báo thiết bị, không sở hữu business rule hoặc hợp đồng API chính thức.

Backend (`CareNest_BE`) là nguồn nghiệp vụ và API dùng chung; Web (`CareNest_FE`) là client khác. Hiện ba repo chưa có source code hoặc bộ `docs/` chính thức. Khi task cần quy tắc, xem BE tương ứng (repo sibling nếu có, hoặc `https://github.com/thang-04/CareNest_BE.git`) và ghi rõ nếu nguồn chưa được tạo.

React Native là phương án dự kiến, chưa chốt. Không giả định navigation library, state/cache, push provider hoặc cách lưu token trước khi có quyết định và source. Với dữ liệu trẻ và sức khỏe, chỉ hiển thị theo quyền/contract BE; thông báo không nên mang nội dung nhạy cảm vượt mức cần thiết.

