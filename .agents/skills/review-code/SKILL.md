---
name: review-code
description: Use when reviewing CareNest mobile diffs, PRs or files ("review", "kiểm tra code", "audit", "xem giúp PR"). Checks client-side business rules, token/child-data privacy, push content, API envelope handling, async state, UX states, tests and engineering memory.
---

# Review code — CareNest_APP

1. Read `../../../AGENTS.md` (invariants) if not already in context.
2. Follow `../../../.ai/workflows/review-code.md`; read the feature doc of the touched role (`docs/features/<role>/README.md`).
3. Escalate context via `../../../.ai/ESCALATION.md` when the diff touches token storage, push, health/allergy/parent-visible data or BE contract.
