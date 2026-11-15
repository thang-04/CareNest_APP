## Task Jira

- <mã-jira>: <link>

## Thay đổi

-

## Tác động

<!-- Bắt buộc khi PR chạm vùng dùng chung (guard.sharedGlobs trong .claude/hooks/harness.config.json) hoặc module của người khác.
     Dán phần chính của: node scripts/ai-layer/impact.mjs <file> -->

- Vùng dùng chung / module người khác: không | có —
- Màn hình/feature bị ảnh hưởng, luồng người dùng đổi thế nào:
- Người phụ trách phần bị ảnh hưởng đã xem:

## Kiểm thử

- Lệnh + kết quả thật (chưa chạy ⇒ ghi rõ): `node scripts/verify.mjs` →

## Thiết kế (PR có giao diện)

<!-- Theo DESIGN.md: Phần A chung với web, Phần B riêng App. Không có giao diện ⇒ ghi "không". -->

- [ ] Chỉ dùng token (`AppColors`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppShadows`) và widget `lib/core/widgets`; icon qua `AppIcons`
- [ ] Badge/nhãn cùng tông, cùng chữ với web (§3.2); thuật ngữ theo người đọc (§10.2)
- [ ] Đủ trạng thái tải / rỗng / lỗi / 403 (§9, §B7); chữ 2,0 và màn 360 không cắt
- [ ] Khác web ⇒ đã thêm dòng `DESIGN.md` §B1 (ghi lý do): không | có —
- [ ] `node scripts/verify.mjs` PASS (gồm kiểm thiết kế)
