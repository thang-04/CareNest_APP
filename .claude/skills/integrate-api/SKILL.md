---
name: integrate-api
description: Use when connecting CareNest mobile screens to backend endpoints, handling auth/login/token/refresh, error responses, offline retry, or push notifications/deep links ("gọi API", "tích hợp API", "endpoint", "đăng nhập", "token", "401", "403", "push", "thông báo", "deep link", "mất mạng"). Routes to backend contract sources and the integration workflow.
---

# Integrate API — CareNest_APP

1. Read `../../../AGENTS.md` (invariants) if not already in context.
2. Follow `../../../.ai/workflows/integrate-api.md`; read `docs/integration/BACKEND_INTEGRATION.md` and the BE contract it points to.
3. Start at L2 (`../../../.ai/profiles/feature.md`); auth, push or a needed BE contract change ⇒ L3 (`../../../.ai/profiles/cross-repo.md` or `architecture.md`).
4. Never invent endpoint/response shapes or pick an auth/push mechanism — BE owns the contract; ask when it is missing.
