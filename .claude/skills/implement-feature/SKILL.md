---
name: implement-feature
description: Use for new CareNest mobile screens or features for Parent, Teacher or Kitchen Staff ("thêm màn hình", "làm tính năng", "implement", "phụ huynh xem", "điểm danh", "báo ăn", "quan sát", "suất ăn bếp", "thực đơn", "dị ứng", "đơn nghỉ", "sự cố CSVC"). Routes to the role feature doc, BE module card and the feature workflow.
---

# Implement feature — CareNest_APP

1. Read `../../../AGENTS.md` (invariants) if not already in context.
2. Find the screen/domain: grep `keywords` in `../../../.ai/CONTEXT_MAP.yaml`, read `docs/features/<role>/README.md` and the BE module card it points to.
3. Follow `../../../.ai/workflows/implement-feature.md` with profile `../../../.ai/profiles/feature.md`.
4. Never implement a PENDING/OPEN rule as decided, never recompute business numbers on the client — ask or render what BE returns.
