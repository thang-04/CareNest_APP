# Profile CODE — sửa cục bộ, bug, review nhỏ

Mức: L1. Mục tiêu: tốn ít context nhất mà vẫn đúng.

Đọc:
1. Source + test gần vị trí lỗi: screen/component, hook, API client call, navigation route; thay đổi gần đây (git log file).
2. `docs/knowledge/ISSUE_INDEX.md`: grep chuỗi lỗi, mã lỗi BE (`code`), tên màn hình, nền tảng (Android/iOS).
3. `docs/features/<role>/README.md` — mục màn hình liên quan (BE flow/card/rule ID nào áp dụng).
4. BE module card chỉ khi lỗi phụ thuộc dữ liệu/contract.

Phân loại lỗi trước khi sửa: **APP** (UI/state/navigation) · **contract** (response khác `BE:docs/contracts/`) · **thiết bị/môi trường** (`docs/knowledge/TROUBLESHOOTING.md`) · **nghiệp vụ BE** (không sửa bằng workaround ở APP).

Không đọc: architecture docs, ADR BE (trừ khi card trỏ tới). Framework: Flutter — theo `DESIGN.md` và source thực tế.

Nâng lên L2/L3 khi sửa chạm: auth/token, push, dữ liệu sức khỏe/dị ứng/phụ huynh, offline ghi dữ liệu, contract BE (`.ai/ESCALATION.md`).
