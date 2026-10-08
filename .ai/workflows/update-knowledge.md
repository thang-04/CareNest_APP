# Workflow — Cập nhật tri thức (nghiệp vụ mới, PENDING được chốt, bug mới)

Chạy **ngay trong lượt** khi gặp trigger, không đợi cuối task. Đây là nguồn duy nhất cho "khi nào / ghi gì / ghi ở đâu"; các workflow khác chỉ trỏ về đây. `BE:<path>` = `../CareNest_BE/<path>`.

| Trigger | Ví dụ |
| --- | --- |
| T1. Thông tin nghiệp vụ mới / chốt PENDING / đổi quyết định | "phụ huynh được xem chiều cao cân nặng", "chọn Riverpod" |
| T2. Bug mới chưa có trong `ISSUE_INDEX` APP lẫn BE (kể cả chưa fix xong) | Crash, sai navigation theo role, push không mở đúng màn hình, lệch contract API |
| T3. Edge case UI/nghiệp vụ đáng nhớ | Mất mạng khi giáo viên lưu điểm danh cả lớp |

## T1 — Nghiệp vụ mới / PENDING được chốt

1. **Nguồn:** ghi người nói, ngày, mức (CONFIRMED nếu từ trường/khảo sát/team chốt; PROPOSED nếu là đề xuất). Không tự nâng mức. Mơ hồ ⇒ hỏi lại 1 câu.
2. **Nghiệp vụ, quyền, contract thuộc BE** ⇒ APP **không** ghi rule. Soạn đề xuất cập nhật cho BE (file + rule ID + nội dung) theo `BE:.ai/workflows/update-knowledge.md` và đưa cho user; chỉ sửa repo BE khi user cho phép.
3. **Grep mọi chỗ tham chiếu trong APP**, sửa từng hit (PENDING đã đóng ⇒ bỏ khỏi danh sách PENDING, mở khóa màn hình nếu có):
   `grep -rn "P-04\b" docs .ai .claude .agents AGENTS.md`
4. Quyết định riêng Mobile (framework, navigation, state, push, lưu token, UX) ⇒ `docs/architecture/*`, `docs/features/<role>/`; file SKELETON có nội dung thật ⇒ bỏ header skeleton và cập nhật `.ai/CONTEXT_MAP.yaml`.
5. Mâu thuẫn với nguồn CONFIRMED ⇒ **không ghi đè**; nêu mâu thuẫn, hỏi user.
6. Trạng thái dự án / PENDING ảnh hưởng APP đổi ⇒ `docs/context/CURRENT_STATE.md`.

## T2 — Bug mới

**Ghi khi** ít nhất một điều đúng: không hiển nhiên · phải thử >1 cách · chỉ xảy ra trên 1 nền tảng/thiết bị/build · có thể lặp lại · lỗi môi trường/build tốn >15 phút. Không ghi lỗi gõ nhầm.

1. Grep `docs/knowledge/ISSUE_INDEX.md` (chuỗi lỗi, màn hình, HTTP status, `Android|iOS`, từ khóa) + `BE:docs/knowledge/ISSUE_INDEX.md` nếu lỗi dữ liệu/contract. Đã có ⇒ mở incident, bổ sung Attempts.
2. Chưa có ⇒ tạo ngay `docs/knowledge/incidents/<ID>.md` từ `_TEMPLATE.md` với `status: open` + 1 dòng `ISSUE_INDEX.md` (root cause `?`). ID: `APP-BUG|APP-CASE|APP-ENV|APP-CTR-YYMMDD-slug`. Ghi nền tảng + version OS, thiết bị/emulator, build.
3. Trong lúc điều tra: mỗi cách thử + kết quả ghi vào **Attempts** của incident, không chỉ trong câu trả lời, để phiên sau không mất.
4. Chứng minh root cause + fix ⇒ điền Root cause / Fix / Regression test, đổi status ở cả incident và index.
5. Bẫy của màn hình ⇒ 1 dòng Known pitfalls trong `docs/features/<role>/README.md`. Lỗi môi trường ⇒ mục `TROUBLESHOOTING.md`. Bài học tổng quát ⇒ `PATTERNS.md` (ID `AP-<SLUG>`).
6. Root cause ở contract/nghiệp vụ BE ⇒ incident `APP-CTR-…` ở APP + soạn mục cho `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` đưa cho user (không tự sửa BE); không che bằng workaround ở APP.

## T3 — Edge case

Incident `APP-CASE-YYMMDD-slug` (`type: edge-case`) + 1 dòng ISSUE_INDEX + Known pitfalls. Cần rule nghiệp vụ mới ⇒ T1 bước 2 (PROPOSED cho tới khi được xác nhận).

## Quy tắc

- 1 dòng ở index, chi tiết ở file chi tiết. Link thay vì chép.
- Không ghi dữ liệu trẻ thật, ảnh trẻ, token, secret, log dài.
- Không tạo incident cho chuyện chưa xảy ra. Giới hạn cố ý/chưa làm (không phải bug) ⇒ `KNOWN_ISSUES.md` (`APP-KI-xxx`).
- Báo user danh sách file tri thức đã cập nhật. Không commit khi user chưa yêu cầu.
