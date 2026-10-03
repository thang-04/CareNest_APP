---
name: fix-bug
description: Use for CareNest mobile app bugs, crashes, wrong display, API errors, failing tests or device/build issues ("lỗi", "bug", "crash", "sai", "không hiện", "không chạy", "màn hình trắng", "test fail", "build lỗi"). Searches engineering memory before investigating and records the fix (including failed attempts) after.
---

# Fix bug — CareNest_APP

1. Read `../../../AGENTS.md` (invariants) if not already in context.
2. Follow `../../../.ai/workflows/fix-bug.md` step by step. It is the source of truth; this skill does not redefine it.
3. Context level starts at L1 (`../../../.ai/profiles/code.md`); escalate via `../../../.ai/ESCALATION.md`.
4. Mandatory: search `docs/knowledge/ISSUE_INDEX.md` before investigating; update engineering memory after fixing when the bug was non-obvious. Contract/business bugs belong to BE — do not patch around them in the app.
