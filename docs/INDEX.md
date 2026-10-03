# Docs Index — CareNest_APP

Không đọc hết. Task thường: `.ai/ROUTER.md` → `.ai/CONTEXT_MAP.yaml` keywords → feature doc + BE module card. Status: **FULL** = dùng làm nguồn · **SKELETON** = chưa có nội dung, không dùng làm nguồn.

Nghiệp vụ, rule, contract nằm ở BE: `BE:docs/INDEX.md` (`BE:` = `../CareNest_BE/` hoặc https://github.com/thang-04/CareNest_BE.git).

| Nhóm | File | Nội dung | Status |
| --- | --- | --- | --- |
| context | `context/REPOSITORY_CONTEXT.md` | CareNest, 3 repo, APP sở hữu gì, role mobile, stack | FULL |
| | `context/CURRENT_STATE.md` | Đã làm / chờ chốt / PENDING ảnh hưởng APP | FULL |
| architecture | `architecture/NAVIGATION.md` | Cây màn hình theo role, deep link | FULL |
| | `architecture/MOBILE_ARCHITECTURE.md` | Ràng buộc + mục cần chốt | SKELETON |
| | `architecture/STATE_MANAGEMENT.md` | Nguyên tắc state/cache | SKELETON |
| features | `features/README.md` | Cách map màn hình → BE; AI trong APP | FULL |
| | `features/parent/README.md` | Màn hình Parent → BE flow/card/rule | FULL |
| | `features/teacher/README.md` | Màn hình Teacher → BE | FULL |
| | `features/kitchen/README.md` | Màn hình Kitchen → BE | FULL |
| integration | `integration/BACKEND_INTEGRATION.md` | Nguồn contract, envelope, status, retry/offline | FULL |
| | `integration/AUTH_FLOW.md` | Auth mobile | SKELETON |
| | `integration/PUSH_NOTIFICATION.md` | Nguyên tắc push + mục cần chốt | SKELETON |
| knowledge | `knowledge/ISSUE_INDEX.md` | **Search đầu tiên khi debug** | FULL (chưa có issue) |
| | `knowledge/incidents/_TEMPLATE.md` | Mẫu incident (có Attempts) | FULL |
| | `knowledge/KNOWN_ISSUES.md`, `TROUBLESHOOTING.md`, `PATTERNS.md` | Giới hạn, lỗi build/thiết bị, bài học | FULL |
| quality | `quality/DEFINITION_OF_DONE.md` | Tiêu chí hoàn thành + memory checklist | FULL |

Coding rules: `.claude/rules/` (component, navigation, state, api-client, security-storage). Quy trình: `.ai/workflows/`.
