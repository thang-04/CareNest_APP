---
id: APP-BUG-261014-greeting-bell-semantics-merge
type: bug
roles: [parent]
screens: [parent-home]
platforms: [both]
be_refs: []
status: fixed
date: 2026-10-14
keywords: [semantics, trình đọc màn hình, chuông thông báo, lời chào, header, container, hero]
similar_to: []
---

# APP-BUG-261014-greeting-bell-semantics-merge — Lời chào và nút chuông bị gộp thành một câu đọc

## Symptom
Sau khi bỏ `AppHeroHeader` ở Trang chủ PH (bố cục H), trình đọc màn hình không còn nút "Thông báo, 2 chưa đọc" riêng. Test widget:
```text
Expected: exactly one matching candidate
  Actual: _ElementPredicateWidgetFinder:<Found 0 widgets with a semantics label named "Thông báo, 2 chưa đọc"
```
Cây semantics có một nút duy nhất với nhãn "Xin chào,\nThông báo, 2 chưa đọc".

## Điều kiện tái hiện
Role Phụ huynh, màn Trang chủ, widget test 360×800 với dữ liệu giả (`FakeParentHomeSource`). Mọi nền tảng.

## Attempts — đã thử
| # | Cách thử | Kết quả | Vì sao không đúng / bài học |
| --- | --- | --- | --- |
| 1 | Dump cây semantics bằng test tạm (`debugDumpSemanticsTree`) | Thấy lời chào và chuông chung một nút | Xác định đây là gộp semantics, không phải chuông mất |

## Root cause
APP. Lời chào bọc `Semantics(header: true)` không có `container: true`, còn `AppHeroBell` dùng `Semantics(button: true, excludeSemantics: true)` cũng không `container`. Hai annotation không tạo nút riêng nên dồn vào cùng một nút cha trong `Row`. Trong `AppHeroHeader` cũ, cấu trúc lồng khác nên không lộ.

## Fix
`lib/features/parent_home/presentation/screens/parent_home_screen.dart`: thêm `container: true` cho `Semantics` của lời chào và bọc nút chuông trong `Semantics(container: true)`.

## Regression test
`test/features/parent_home/parent_home_screen_test.dart` — "Bố cục H (PAR-01): lời chào → thẻ bé → Việc nhanh" kiểm `find.bySemanticsLabel('Thông báo, 2 chưa đọc')`. Fail trước fix, pass sau fix.

## Ảnh hưởng
Các trang chủ GV, Bếp, PHT, HT sẽ bỏ `AppHeroHeader` ở Phase 2–3: đặt lời chào cạnh chuông thì phải dùng `container: true`.

## Lesson
`Semantics` chỉ có `header`/`button` mà không `container` sẽ gộp với anh em trong cùng nút cha; nhóm nội dung cần đọc riêng phải có `container: true`.
