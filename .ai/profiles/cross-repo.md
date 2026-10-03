# Profile CROSS-REPO — APP + BE (+ FE)

Mức: L3.

1. Đọc `BE:docs/system/CROSS_REPO_MAP.md`: ownership + điểm chạm (auth, endpoint/DTO/error, PAR-*, MealCount/menu, push).
2. Liệt kê thay đổi thuộc APP / BE / FE / contract dùng chung.
3. Repo sibling có sẵn (`../CareNest_BE`, `../CareNest_FE`) ⇒ đọc `AGENTS.md` + `.ai/ROUTER.md` của repo đó. Không có ⇒ dùng remote, báo giới hạn kiểm chứng. Không giả định cả ba được checkout.
4. BE sở hữu rule + contract; APP sở hữu UI/state/integration. Không copy business rule sang APP, không workaround ở APP để che lỗi BE.
5. Contract chưa có/không khớp ⇒ mô tả thay đổi cần thống nhất (endpoint, field, error code, ví dụ) trước khi code. **Không tự sửa BE/FE.**
6. Lỗi contract/nghiệp vụ phát hiện qua APP ⇒ ghi (hoặc đề xuất nội dung để BE ghi) vào `BE:docs/knowledge/CROSS_MODULE_ISSUES.md`; phía APP chỉ ghi 1 dòng `ISSUE_INDEX.md` trỏ sang.
