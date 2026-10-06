# Workflow — Implement feature (Mobile)

Làn S (`AGENTS.md`): bước 0, 5, 6, 8 — rule 1 dòng. Làn L: bước 0 rồi `plan-change.md`, làm theo phase.

0. **Làn + nghiệp vụ:** xác định làn S/M/L (`AGENTS.md`); đổi nghiệp vụ/thứ người dùng thấy ⇒ `clarify-business.md` (hỏi tới khi rõ, đối chiếu tài liệu, ảnh hưởng) trước khi code; làn L ⇒ `plan-change.md`.
1. **Requirement:** actor (Parent / Teacher / Kitchen Staff), outcome, điều kiện hoàn thành. Map sang mục màn hình trong `docs/features/<role>/README.md` → BE flow, module card, rule ID. Rule PENDING/OPEN ⇒ nêu khoảng trống, hỏi hoặc thiết kế UI theo dữ liệu/permission BE trả về — không tự quyết.
2. **Memory:** grep `docs/knowledge/ISSUE_INDEX.md` + "Known pitfalls" của feature doc + `PATTERNS.md` cho màn hình/domain tương tự.
3. **Navigation:** vị trí màn hình trong `docs/architecture/NAVIGATION.md`; deep link nếu nhận từ push. Màn hình mới ⇒ cập nhật NAVIGATION.md.
4. **Contract:** endpoint có trong OpenAPI BE / module card chưa? Chưa ⇒ dừng phần gọi API, ghi đề xuất contract (endpoint, request, response `data`, status lỗi) để thống nhất với BE. Theo `workflows/integrate-api.md`.
5. **Impact analysis:** role khác dùng chung component/state? dữ liệu nhạy cảm (sức khỏe, dị ứng, ảnh) — hiển thị/cache/log thế nào? offline? push? Chạm Bảng 2 của `ROUTER.md` ⇒ L3.
6. **Code:** theo `.claude/rules/` + pattern đang có trong source. Không chọn thư viện nền mới khi chưa hỏi. Không tính lại số liệu nghiệp vụ (suất ăn, định lượng, trend) ở client — hiển thị giá trị BE trả.
7. **Test & kiểm tra:** thao tác chính; trạng thái loading / empty / error / offline / 401 / 403; double-submit; chữ tiếng Việt dài; màn hình nhỏ. Phân biệt test tự động với kiểm tra tay trên emulator/máy thật.
8. **Docs & memory:** cập nhật feature doc (màn hình mới, PENDING còn lại, Known pitfalls nếu gặp edge case), `CURRENT_STATE.md` khi feature bắt đầu/xong. Edge case đáng nhớ ⇒ `update-knowledge.md` T3.
9. **Verify + báo cáo** theo `docs/quality/VERIFICATION.md` (mẫu theo làn). Báo: đã chạy gì, chưa kiểm chứng gì (thiết bị, API thật, push), thay đổi BE còn chờ. Đối chiếu DoD.
