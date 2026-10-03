# CareNest Mobile — hướng dẫn cho coding agent

Bạn đang làm việc trong repository Mobile của CareNest. Đọc `.ai/ROUTER.md` để chọn profile và workflow liên quan; không nạp toàn bộ `.ai/` theo mặc định. `.ai/REPO_CONTEXT.md` nêu trách nhiệm ứng dụng, còn `.ai/CONTEXT_MAP.yaml` phân biệt file hiện có và dự kiến.

- APP sở hữu màn hình, điều hướng, trạng thái client, tích hợp API và thông báo thiết bị cho Phụ huynh, Giáo viên, Nhà bếp; một số chức năng BGH có thể đến sau.
- BE sở hữu business rule, authorization, dữ liệu và API contract. Không sao chép quy tắc tính suất ăn, dị ứng, dinh dưỡng hoặc sức khỏe vào APP.
- Bảo vệ dữ liệu trẻ em, sức khỏe, token và ảnh: không đưa dữ liệu thật hoặc secret vào prompt, log, fixture hay commit; UI không thay thế kiểm tra quyền ở BE.
- Với thay đổi auth/API dùng chung, kiểm tra tác động BE/FE. Nếu thiếu contract hoặc tài liệu, ghi rõ khoảng trống; nếu tài liệu và implementation mâu thuẫn, xác minh intended behavior.
- React Native chỉ là phương án dự kiến. Đọc source thực tế trước khi áp rule framework hoặc chọn cơ chế thông báo/lưu token.

## Git, commit và comment (bắt buộc)

- Không tự ý commit, push, tạo/merge pull request khi user chưa cho phép rõ trong tin nhắn hiện tại; không commit thẳng `main`.
- Không chạy lệnh git phá hủy (`reset --hard`, `push --force`, `rebase`, `branch -D`, `clean -fd`...) khi chưa hỏi; không `--no-verify`.
- Commit theo Conventional Commits tiếng Anh, subject ≤ 72 ký tự, body ngắn nói lý do; không ghi tên model/công cụ AI hay `Co-Authored-By` của AI.
- Comment code chỉ ngắn gọn ở flow có logic chính; không comment code hiển nhiên, không để code comment-out.
- Hỏi trước khi đổi dependency, contract hoặc thứ ảnh hưởng cả nhóm; không sửa ngoài phạm vi task hoặc repo CareNest khác. Trả lời user bằng tiếng Việt.
- Chi tiết: mục "Quy tắc chung CareNest" trong `CLAUDE.md`.
