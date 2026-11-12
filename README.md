# CareNest Mobile

App Flutter của CareNest (Trường Mầm non Thượng Hồng — 1 trường, 2 điểm trường) cho Phụ huynh, Giáo viên, Nhân viên bếp. Business rule, phân quyền và API contract thuộc repo `CareNest_BE`.

## Chạy

```bash
flutter pub get
flutter run                       # mặc định USE_MOCK=true: dữ liệu giả, chưa gọi BE
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://<host>:8080/api
```

Cần Dart SDK khớp `environment.sdk` trong `pubspec.yaml`. Cấu hình môi trường: `lib/core/config/env.dart` (đọc từ `--dart-define`, không chứa bí mật).

## Kiểm tra trước khi báo xong

```bash
node scripts/verify.mjs           # dart format + flutter analyze + flutter test
node scripts/check-ai-layer.mjs   # khi sửa docs/, .ai/, .claude/, .agents/
```

## Tài liệu

- Người và AI agent bắt đầu từ `AGENTS.md`; chỉ mục tài liệu: `docs/INDEX.md`.
- Quy chuẩn UI và kiến trúc: `DESIGN.md`.
- Tích hợp BE: `docs/integration/BACKEND_INTEGRATION.md`; danh sách endpoint BE: `docs/integration/BE_API_INDEX.md`.
