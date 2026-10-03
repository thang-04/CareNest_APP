# Workflow tích hợp API Mobile

1. Xác định màn hình/caller và contract BE đang tồn tại; nếu chưa có contract chính thức, ghi rõ điểm cần thống nhất.
2. Kiểm tra request, response, lỗi, auth/refresh, mất kết nối và dữ liệu nhạy cảm theo endpoint thực tế.
3. Cập nhật client và test, không sao chép validation nghiệp vụ từ BE trừ phần hỗ trợ nhập liệu được yêu cầu.
4. Nếu contract phải đổi, phối hợp thay đổi ở BE và xét tác động FE; nêu phần chưa được kiểm thử liên repo.

