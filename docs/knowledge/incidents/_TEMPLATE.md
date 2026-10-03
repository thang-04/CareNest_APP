---
id: BUG-000            # BUG-xxx | CASE-xxx | ENV-xxx | CTR-xxx
type: bug              # bug | edge-case | env | contract
roles: [teacher]       # parent | teacher | kitchen | all
screens: [attendance-batch]
platforms: [android]   # android | ios | both
be_refs: [ATT-01, docs/modules/attendance.md]   # rule ID / card BE liên quan
status: fixed          # fixed | workaround | open
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

## Attempts — đã thử
| # | Cách thử | Kết quả | Vì sao không đúng / bài học |
| --- | --- | --- | --- |
| 1 | | | |

## Root cause
Nguyên nhân + **bằng chứng** (file:line, log, network trace, test chứng minh). Phân loại: APP / contract / thiết bị-môi trường / nghiệp vụ BE.

## Fix
Thay đổi gì, ở đâu (file/PR/commit). Vì sao cách này đúng.

## Regression test
Tên test + vị trí. Test fail trước fix, pass sau fix. Không có test tự động ⇒ ghi bước kiểm tra tay + thiết bị.

## Ảnh hưởng
Role/màn hình khác; cache/offline queue cần xóa; BE/FE cần đổi (link mục `CROSS_MODULE_ISSUES.md` ở BE nếu có).

## Lesson
1–2 câu tổng quát. Nếu lặp ở chỗ khác ⇒ thêm vào `docs/knowledge/PATTERNS.md`.
