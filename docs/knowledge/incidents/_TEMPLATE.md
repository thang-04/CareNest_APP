---
id: APP-BUG-YYMMDD-slug   # APP-BUG- | APP-CASE- | APP-ENV- | APP-CTR- ; tên file = <id>.md
type: bug              # bug | edge-case | env | contract
roles: [teacher]       # parent | teacher | kitchen | all
screens: [attendance-batch]
platforms: [android]   # android | ios | both
be_refs: [ATT-01, BE:docs/modules/attendance.md]   # rule ID / card BE liên quan
status: open           # open (đang điều tra, root cause có thể chưa rõ) | workaround | fixed
date: YYYY-MM-DD
keywords: [điểm danh, double submit, offline]
similar_to: []         # ID incident liên quan (APP hoặc BE)
---

# <ID> — <tiêu đề ngắn mô tả triệu chứng>

## Symptom
Hiện tượng quan sát được. Chuỗi lỗi **nguyên văn** (dòng quyết định, không dán cả stack; che token/dữ liệu trẻ):
```text
<error message / HTTP status + desc / log line>
```

## Điều kiện tái hiện
Role, màn hình, bước, nền tảng + version OS, thiết bị/emulator, build (debug/release), trạng thái mạng, version app. Dữ liệu giả, không dữ liệu trẻ thật.

## Attempts — đã thử (cập nhật mỗi phiên điều tra, để phiên sau không lặp lại)
| # | Cách thử | Kết quả | Vì sao không đúng / bài học |
| --- | --- | --- | --- |
| 1 | | | |

## Root cause
Nguyên nhân + **bằng chứng** (file:line, log, network trace, test chứng minh). Phân loại: APP / contract / thiết bị-môi trường / nghiệp vụ BE. Chưa chứng minh ⇒ ghi `Chưa rõ` + giả thuyết hiện tại.

## Fix
Thay đổi gì, ở đâu (file/PR/commit). Vì sao cách này đúng.

## Regression test
Tên test + vị trí. Test fail trước fix, pass sau fix. Không có test tự động ⇒ ghi bước kiểm tra tay + thiết bị.

## Ảnh hưởng
Role/màn hình khác; cache/offline queue cần xóa; BE/FE cần đổi (link mục `BE:docs/knowledge/CROSS_MODULE_ISSUES.md` nếu có).

## Lesson
1–2 câu tổng quát. Nếu lặp ở chỗ khác ⇒ thêm vào `docs/knowledge/PATTERNS.md`.
