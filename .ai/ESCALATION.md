# Escalation — mở rộng context theo mức

Không mức nào đọc toàn bộ `docs/` (APP hoặc BE) trừ FULL. Đọc theo thứ tự; dừng khi đủ bằng chứng.

BE docs: sibling `../CareNest_BE/<path>` (ký hiệu `BE:<path>`). Không có checkout ⇒ đọc từ https://github.com/thang-04/CareNest_BE.git và nêu rõ giới hạn kiểm chứng.

| Mức | Khi nào | Đọc (cộng dồn) | Ngân sách gợi ý |
| --- | --- | --- | --- |
| L1 cục bộ | Bug/sửa trong 1 màn hình/component/hook | Source + test gần nhất · `docs/knowledge/ISSUE_INDEX.md` (dòng liên quan) · `docs/features/<role>/README.md` (mục màn hình) · BE module card nếu lỗi phụ thuộc dữ liệu/contract | 1 feature doc + 1 card |
| L2 feature | Màn hình/luồng mới, tích hợp endpoint | + `docs/architecture/NAVIGATION.md` (nhóm màn hình) · `docs/integration/BACKEND_INTEGRATION.md` · flow BE trong card · rule ID trong `BE:docs/business/BUSINESS_RULES.md` (chỉ nhóm liên quan) · `BE:docs/contracts/API_CONVENTIONS.md` + `ERROR_CONTRACT.md` | 1 card + 1 flow |
| L3 liên repo / nhạy cảm | Cần BE đổi contract; push; token; dữ liệu sức khỏe/dị ứng/phụ huynh; offline ghi dữ liệu | + `BE:docs/system/CROSS_REPO_MAP.md` · `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` · `docs/integration/AUTH_FLOW.md` / `PUSH_NOTIFICATION.md` · ADR BE được card trỏ (vd. ADR-0010) · `BE:docs/business/USER_ROLES.md` | vài card + map |
| L4 hệ thống client | Kiến trúc app, thư viện nền, secure storage, release | + `docs/architecture/*` · `docs/context/REPOSITORY_CONTEXT.md` · `BE:docs/architecture/SECURITY.md` · `BE:docs/system/SYSTEM_ARCHITECTURE.md` | đầy đủ phần liên quan |
| FULL | Onboarding, audit, thiết kế lại | `docs/INDEX.md` → toàn bộ docs APP; `BE:docs/INDEX.md` theo nhu cầu | không tối ưu token |

## Quy tắc

- Phát hiện dependency ngoài phạm vi đang đọc ⇒ nâng 1 mức, nói rõ lý do.
- Rule PENDING/OPEN ⇒ không suy đoán: nêu khoảng trống, đề xuất cấu hình được, hoặc hỏi.
- File có header `Status: CHƯA CÓ NỘI DUNG` ⇒ không dùng làm nguồn.
- Code APP, docs, contract BE mâu thuẫn ⇒ nêu xung đột, xác minh intended behavior với BE trước khi sửa.
- Đường dẫn trong `CONTEXT_MAP.yaml > planned` chưa tồn tại — không viện dẫn.
