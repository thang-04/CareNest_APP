# Router — chọn context cho task Mobile

Làn S (`AGENTS.md`) không cần đọc file này.

1. Xác định **loại task** → bảng 1 (profile, workflow, skill, mức khởi đầu).
2. Xác định **màn hình/domain** → grep từ khóa trong `.ai/CONTEXT_MAP.yaml` mục `keywords` → đọc `app_docs` + `be_module_card`.
3. Đọc thêm chỉ khi `.ai/ESCALATION.md` yêu cầu.

## Bảng 1 — Loại task

| Task | Profile | Workflow | Skill | Mức đầu |
| --- | --- | --- | --- | --- |
| Bug màn hình, crash, hiển thị sai, API lỗi, test fail | `profiles/code.md` | `workflows/fix-bug.md` | fix-bug | L1 |
| Refactor nhỏ, validation nhập liệu, sửa UI cục bộ | `profiles/code.md` | `workflows/implement-feature.md` (rút gọn) | implement-feature | L1 |
| Màn hình / chức năng mới cho Parent, Teacher, Kitchen | `profiles/feature.md` | `workflows/implement-feature.md` | implement-feature | L2 |
| Review code / PR | `profiles/code.md` | `workflows/review-code.md` | review-code | L1→L2 |
| Tích hợp endpoint, DTO, error code, auth/token/refresh | `profiles/feature.md` | `workflows/integrate-api.md` | integrate-api | L2; L3 nếu cần BE đổi contract |
| Push notification, deep link, device token | `profiles/architecture.md` | `workflows/integrate-api.md` | integrate-api | L3 |
| Thay đổi cần BE/FE đổi theo, lỗi contract/nghiệp vụ | `profiles/cross-repo.md` | theo loại thay đổi | — | L3 |
| Kiến trúc client, chọn thư viện nền, secure storage, build/release | `profiles/architecture.md` | theo loại thay đổi | — | L4 |
| Onboarding toàn bộ, audit lớn, thiết kế lại app | `profiles/full.md` | — | — | FULL |
| Đổi nghiệp vụ / thứ người dùng thấy, yêu cầu chưa rõ hoặc lệch tài liệu | `profiles/feature.md` | `workflows/clarify-business.md` → workflow theo loại | implement-feature | L2 |
| Làn L: thư viện nền, auth/token, API client chung, điều hướng theo role, dependency, ≥2 nhóm màn hình, đổi contract BE, >8 file | `profiles/architecture.md` | `workflows/clarify-business.md` → `workflows/plan-change.md` | plan-change | L3 |

## Bảng 2 — Tín hiệu nâng mức ngay

Chạm bất kỳ mục nào ⇒ ít nhất L3: dữ liệu sức khỏe / dị ứng · hiển thị cho phụ huynh (PAR-*, ADR-0010) · token / phiên đăng nhập / lưu trữ trên thiết bị · ảnh trẻ · nội dung push · số suất ăn / thực đơn cho bếp · offline queue / retry ghi dữ liệu · mã lỗi hoặc DTO BE mới.

## Bảng 3 — Ngoài scope

Chat/nhắn tin (CareNest không thay Zalo) · multi-school/multi-tenant · kho/NCC/tồn kho (OPEN — BE ADR-0009) · soạn/duyệt giáo án · chẩn đoán y tế/tâm lý · thanh toán/học phí · hiển thị AI draft như kết quả chính thức ⇒ **dừng**, đối chiếu `BE:docs/context/PROJECT_CONTEXT.md` (Exclusions) và hỏi người dùng.

`BE:<path>` = `../CareNest_BE/<path>` (xem `AGENTS.md`).

## Cập nhật tri thức (song song với mọi task)

User đưa thông tin nghiệp vụ mới / chốt PENDING, gặp **bug mới** hoặc edge case ⇒ chạy `workflows/update-knowledge.md` (skill `update-knowledge`) **ngay trong lượt**, rồi tiếp tục task chính. Claude có Stop hook nhắc khi session có dấu hiệu bug khó (verify fail rồi pass) mà chưa ghi memory (BE ADR-0012).
