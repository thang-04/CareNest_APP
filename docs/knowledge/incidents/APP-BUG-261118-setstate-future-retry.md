---
id: APP-BUG-261118-setstate-future-retry
type: bug
roles: [all]
screens: [parent-my-child, kitchen-meals, management]
platforms: [both]
be_refs: []
status: fixed
date: 2026-11-18
keywords: [Thử lại, retry, setState, Future, FutureBuilder]
similar_to: []
---

# APP-BUG-261118-setstate-future-retry — Bấm "Thử lại" báo lỗi setState, màn không tải lại

## Symptom
Bản debug: bấm "Thử lại" ở trạng thái lỗi tải, màn vẫn đứng ở lỗi và console báo:
```text
setState() callback argument returned a Future.
```

## Điều kiện tái hiện
Mọi role có màn dùng `FutureBuilder` + nút "Thử lại" viết `onRetry: () => setState(() => _future = source.load())`. Lần tải đầu lỗi (dữ liệu giả ném lỗi), bấm "Thử lại". Chỉ bản debug: kiểm tra nằm trong `assert` của `State.setState`.

## Attempts — đã thử (cập nhật mỗi phiên điều tra, để phiên sau không lặp lại)
| # | Cách thử | Kết quả | Vì sao không đúng / bài học |
| --- | --- | --- | --- |
| 1 | Widget test bấm "Thử lại" ở Bé của tôi (`_FlakySource` lỗi lần đầu) | Fail với assertion trên | Closure mũi tên trả về giá trị phép gán (một Future) |
| 2 | Đổi closure sang thân khối `setState(() { _future = widget.load(); })` | Pass | — |

## Root cause
APP: closure mũi tên `() => _future = load()` trả về giá trị phép gán là `Future`; `State.setState` (debug) ném lỗi sau khi chạy closure và trước `markNeedsBuild`, nên màn không vẽ lại. Bằng chứng: test `Lỗi tải ⇒ báo lỗi, "Thử lại" tải lại hồ sơ` (`test/features/parent/my_child/my_child_screens_test.dart`).

## Fix
Closure thân khối `setState(() { _future = load(); })` ở mọi chỗ gán trường kiểu `Future` (user cho sửa 18/11): Bé của tôi (`_ProfileLoaderState`), bếp `kitchen_meals_screen.dart`, các màn `lib/features/management/*` (approvals, meal_adjustment, principal_approvals, campuses, campus_children, meal_count_confirm — cả lúc gán `Future.value` sau khi xác nhận, nutrition_balance, reward_batch, reward_proposals, school_children): 15 chỗ. Tìm lại: grep `setState\(\(\) => _[a-zA-Z]+ = ` rồi xem trường có kiểu `Future` không.

## Regression test
`test/features/parent/my_child/my_child_screens_test.dart` › `Lỗi tải ⇒ báo lỗi, "Thử lại" tải lại hồ sơ` (fail trước fix, pass sau fix) và `test/features/kitchen/kitchen_meals/kitchen_meals_screen_test.dart` › `K03: lỗi tải ⇒ "Thử lại" tải lại số suất`.

## Ảnh hưởng
Bản release không có assert nên tải lại bình thường; trước khi sửa, bản debug và widget test hỏng nút "Thử lại" (và cập nhật sau khi xác nhận ở màn chốt suất).

## Lesson
Trong `setState` chỉ gán bằng thân khối khi giá trị là `Future`; viết test bấm "Thử lại" cho màn có trạng thái lỗi.
