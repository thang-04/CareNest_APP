# Workflow — Fix bug (Mobile)

1. **Triệu chứng:** ghi lại nguyên văn lỗi (message, stack dòng quyết định, HTTP status + `desc` từ BE), role, màn hình, nền tảng + version OS, thiết bị/emulator, trạng thái mạng, build (debug/release). Hành vi mong đợi lấy từ `docs/features/<role>/README.md` → rule ID / flow BE. Tái hiện bằng **dữ liệu giả, tối thiểu**.
2. **Tra memory trước khi điều tra:** grep `docs/knowledge/ISSUE_INDEX.md` (chuỗi lỗi, màn hình, status code, `Android|iOS`, từ khóa VN/EN). Lỗi build/thiết bị ⇒ `TROUBLESHOOTING.md`. Lỗi có vẻ từ dữ liệu/contract ⇒ grep thêm `BE:docs/knowledge/ISSUE_INDEX.md` + `BE:docs/knowledge/CROSS_MODULE_ISSUES.md`. Có match ⇒ đọc incident, **đặc biệt mục Attempts** để không lặp cách đã thất bại.
3. **Phân loại & kiểm chứng với code hiện tại:** APP (UI/state/navigation) · contract (response khác `BE:docs/backend-coding-guide.md` §8 / OpenAPI) · thiết bị/môi trường · nghiệp vụ BE. Incident cũ là manh mối, không phải kết luận.
4. **Chứng minh root cause** bằng bằng chứng (test fail, log đã che dữ liệu nhạy cảm, network trace, file:line). Ghi lại từng cách thử + kết quả ngay khi điều tra — dùng cho bước 7.
5. **Đánh giá tác động** trước khi sửa: role khác dùng chung component? dữ liệu cache/offline đã sai cần xóa? token/push? Lỗi thuộc BE ⇒ **không** che bằng workaround ở APP; theo `profiles/cross-repo.md`.
6. **Sửa hẹp + regression test** fail-trước/pass-sau (unit/component test khi có test runner). Kiểm tra loading/empty/error/offline/401/403. Báo đúng: đã chạy gì, trên nền tảng nào, chưa kiểm chứng trên máy thật/API thật nào.
7. **Cập nhật engineering memory** (bắt buộc nếu lỗi không hiển nhiên / thử >1 cách / chỉ xảy ra trên 1 nền tảng-thiết bị / có thể lặp / lỗi môi trường >15 phút):
   - `docs/knowledge/incidents/<ID>-<slug>.md` theo `_TEMPLATE.md` (gồm Attempts thất bại).
   - 1 dòng trong `ISSUE_INDEX.md` với từ khóa + chuỗi lỗi để grep được.
   - Lỗi môi trường/build ⇒ thêm mục `TROUBLESHOOTING.md`.
   - Bẫy của màn hình/role ⇒ 1 dòng "Known pitfalls" trong `docs/features/<role>/README.md`.
   - `PATTERNS.md` nếu tổng quát hóa được. Chưa rõ root cause ⇒ `KNOWN_ISSUES.md`, không tạo incident.
   - Lỗi contract/nghiệp vụ ⇒ đề xuất mục cho `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` (không tự sửa BE).
8. Đối chiếu `docs/quality/DEFINITION_OF_DONE.md`.
