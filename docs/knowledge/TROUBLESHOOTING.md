# Troubleshooting — build, thiết bị, môi trường

Cách xử lý nhanh lỗi môi trường: cài đặt toolchain, build Android/iOS, emulator/simulator, máy thật, bundler, kết nối tới BE local, chứng chỉ/ký app. Mỗi mục: triệu chứng (chuỗi lỗi nguyên văn) → nguyên nhân → cách xử lý → đã thử không hiệu quả → link `APP-ENV-YYMMDD-slug` nếu có incident.

> Chưa có mục nào (chưa có source). Thêm ngay khi gặp lỗi môi trường tốn >15 phút. Ghi rõ OS máy dev (Windows/macOS), version toolchain, nền tảng đích.

## Nhóm gợi ý (thêm mục vào đúng nhóm)

- Toolchain & cài đặt (Node, JDK/Android SDK, Xcode/CocoaPods)
- Build Android · Build iOS
- Emulator / simulator / máy thật
- Kết nối BE local (base URL, `localhost` trên emulator, HTTP cleartext, prefix `/api`)
- Push trên thiết bị (khi chốt provider)

## Format

```markdown
### <chuỗi lỗi hoặc triệu chứng ngắn>
- Môi trường: OS dev, version toolchain, Android/iOS, emulator/máy thật
- Nguyên nhân: ...
- Xử lý: lệnh/bước cụ thể
- Đã thử không hiệu quả: ...
- Incident: APP-ENV-YYMMDD-slug
```
