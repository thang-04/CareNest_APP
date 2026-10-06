# Workflow — Fix bug (Mobile)

Làn S (1–2 file, nguyên nhân rõ): triệu chứng, grep memory, sửa, regression test fail-trước/pass-sau. Làn M/L: đủ các bước; root cause đủ 6 mục (triệu chứng nguyên văn · tái hiện · mong đợi vs thực tế · `file:line` + bằng chứng · vì sao giờ mới lộ · phạm vi ảnh hưởng) trước khi sửa. Không có nguồn cho "hành vi đúng" ⇒ `clarify-business.md`. **3 lần sửa thất bại ⇒ dừng**, ghi Attempts, hỏi user.

1. **Triệu chứng:** ghi lại nguyên văn lỗi (message, stack dòng quyết định, HTTP status + `desc` từ BE), role, màn hình, nền tảng + version OS, thiết bị/emulator, trạng thái mạng, build (debug/release). Hành vi mong đợi lấy từ `docs/features/<role>/README.md` → rule ID / flow BE. Tái hiện bằng **dữ liệu giả, tối thiểu**.
2. **Tra memory trước khi điều tra:** grep `docs/knowledge/ISSUE_INDEX.md` (chuỗi lỗi, màn hình, status code, `Android|iOS`, từ khóa VN/EN). Lỗi build/thiết bị ⇒ `TROUBLESHOOTING.md`. Lỗi có vẻ từ dữ liệu/contract ⇒ grep thêm `BE:docs/knowledge/ISSUE_INDEX.md` + `BE:docs/knowledge/CROSS_MODULE_ISSUES.md`. Có match (kể cả status `open`) ⇒ đọc incident, **đặc biệt mục Attempts** để không lặp cách đã thất bại.
3. **Phân loại & kiểm chứng với code hiện tại:** APP (UI/state/navigation) · contract (response khác `BE:docs/backend-coding-guide.md` §8 / OpenAPI) · thiết bị/môi trường · nghiệp vụ BE. Incident cũ là manh mối, không phải kết luận.
4. **Chứng minh root cause** bằng bằng chứng (test fail, log đã che dữ liệu nhạy cảm, network trace, file:line). Ghi lại từng cách thử + kết quả ngay khi điều tra — dùng cho bước 7.
5. **Đánh giá tác động** trước khi sửa: role khác dùng chung component? dữ liệu cache/offline đã sai cần xóa? token/push? Lỗi thuộc BE ⇒ **không** che bằng workaround ở APP; theo `profiles/cross-repo.md`.
6. **Sửa hẹp + regression test** fail-trước/pass-sau (unit/component test khi có test runner). Kiểm tra loading/empty/error/offline/401/403. Báo đúng: đã chạy gì, trên nền tảng nào, chưa kiểm chứng trên máy thật/API thật nào.
7. **Cập nhật engineering memory:** theo `update-knowledge.md` T2 (incident `status: open` mở ngay từ bước 4 nếu lỗi không hiển nhiên; Attempts ghi vào incident).
8. Đối chiếu `docs/quality/DEFINITION_OF_DONE.md`.
