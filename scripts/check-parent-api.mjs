#!/usr/bin/env node
// Kiểm các API phụ huynh App gọi (plan 2026-11-25-parent-api-integration) với BE + Keycloak local:
// đăng nhập PKCE như App, gọi đúng đường dẫn/khoảng ngày App dùng, in status + hình dạng (số phần tử, trường App đọc).
// Không in token, mật khẩu, họ tên hay dữ liệu sức khỏe của trẻ.
// Dùng: CARENEST_SEED_PASSWORD=<mật khẩu seed local> node scripts/check-parent-api.mjs [--sources]
//       (tài khoản: CARENEST_PARENT_USER, mặc định phụ huynh 2 con của seed local — BE:docs/TAI_KHOAN_DEV.md)
//       --sources: chạy thêm tool/parent_sources_live_check.dart (các Live…Source Dart với dữ liệu thật, chỉ in số đếm);
//       cần flutter 3.47.6 đầu PATH, token truyền qua biến môi trường của tiến trình con.
import { spawnSync } from "node:child_process";

import { json, signIn } from "./lib/oidc-pkce.mjs";

const ISSUER = process.env.CARENEST_OIDC_ISSUER ?? "http://localhost:8180/realms/carenest";
const API = process.env.CARENEST_API_BASE_URL ?? "http://localhost:8080/api";
const USER = process.env.CARENEST_PARENT_USER ?? "0335474254";
const PW = process.env.CARENEST_SEED_PASSWORD;
if (!PW) {
  console.error("Thiếu CARENEST_SEED_PASSWORD (mật khẩu seed local, xem BE:docs/TAI_KHOAN_DEV.md).");
  process.exit(2);
}

let failures = 0;
const check = (name, ok, detail = "") => {
  if (!ok) failures++;
  console.log(`${ok ? "PASS" : "FAIL"} ${name}${detail ? ` — ${detail}` : ""}`);
};

// Ngày như App (lib/core/integration/api_dates.dart)
const pad = (n) => String(n).padStart(2, "0");
const day = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const now = new Date();
const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
const monday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - ((today.getDay() + 6) % 7));
const eightWeeks = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() - 49);
const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);

const disc = await json(await fetch(`${ISSUER}/.well-known/openid-configuration`));
if (!disc.token_endpoint) {
  console.log(`KẾT QUẢ: không đọc được discovery của ${ISSUER} — BE/Keycloak local đã chạy chưa?`);
  process.exit(1);
}
const login = await signIn(disc, USER, PW);
if (login.error || !login.tokens?.access_token) {
  console.log(`KẾT QUẢ: đăng nhập phụ huynh thất bại — ${login.error ?? login.status}`);
  process.exit(1);
}
const bearer = login.tokens.access_token;

const call = async (method, path, body) => {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      authorization: `Bearer ${bearer}`,
      ...(body ? { "content-type": "application/json" } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const env = await json(res);
  return { status: res.status, errorCode: env.errorCode, data: env.data };
};

// Thử các ngày bắt đầu như App khi BE báo 4109 (khoảng lấn ra ngoài năm học)
const callRange = async (path, starts) => {
  for (const [i, from] of starts.entries()) {
    const r = await call("GET", `${path}${path.includes("?") ? "&" : "?"}from=${day(from)}&to=${day(today)}`);
    if (!(r.status === 400 && r.errorCode === 4109) || i === starts.length - 1) {
      return { ...r, from: day(from) };
    }
  }
};
const recentStarts = [eightWeeks, monday, today];
const monthStarts = [monthStart, monday, today].filter((d, i, all) => i === 0 || d > all[i - 1]);
const keys = (obj) => Object.keys(obj ?? {}).sort().join(",");
const len = (v) => (Array.isArray(v) ? v.length : "—");

const me = await call("GET", "/accounts/me");
const childIds = me.data?.childIds ?? [];
check("/accounts/me: phụ huynh có con", me.status === 200 && childIds.length > 0, `childIds ${childIds.length}`);
const id = childIds[0];

const profile = await call("GET", `/children/${id}/profile`);
check(
  "GET /children/{id}/profile (Bé của tôi, thẻ bé)",
  profile.status === 200 && !!profile.data?.child,
  `cls ${profile.data?.cls ? "có" : "null"}, declaration ${profile.data?.declaration ? "có" : "null"}, guardians ${len(profile.data?.child?.guardians)}, gender ${profile.data?.child?.gender ?? "—"}`,
);

const todayRes = await call("GET", `/children/${id}/attendance/today`);
check(
  "GET /children/{id}/attendance/today (Trang chủ)",
  todayRes.status === 200 && typeof todayRes.data?.status === "string",
  `status ${todayRes.data?.status}, absentPart ${todayRes.data?.absentPart ?? "null"}`,
);

const notes = await call("GET", "/me/notifications");
check("GET /me/notifications (chuông)", notes.status === 200 && typeof notes.data?.unreadCount === "number");

const month = await callRange(`/children/${id}/attendance`, monthStarts);
check(
  "GET /children/{id}/attendance?from&to (điểm danh tháng)",
  month.status === 200 && Array.isArray(month.data?.days),
  `from ${month.from}, days ${len(month.data?.days)}, totals ${keys(month.data?.totals)}`,
);
const health = await callRange(`/children/${id}/daily-health/parent`, monthStarts);
check(
  "GET /children/{id}/daily-health/parent (sức khỏe đầu ngày)",
  health.status === 200 && Array.isArray(health.data),
  `from ${health.from}, entries ${len(health.data)}`,
);

const leaves = await call("GET", "/leave-requests/me");
check("GET /leave-requests/me (đơn đã gửi)", leaves.status === 200 && Array.isArray(leaves.data), `items ${len(leaves.data)}`);
const preview = await call("POST", "/leave-requests/preview", {
  childId: id,
  fromDate: day(today),
  toDate: day(today),
  part: "MORNING",
});
check(
  "POST /leave-requests/preview (bữa của đơn nửa buổi)",
  preview.status === 200 || preview.status === 400,
  preview.status === 200
    ? `eatsApplies ${preview.data?.eatsApplies}, offMeals ${len(preview.data?.offMeals)}, keptMeals ${len(preview.data?.keptMeals)}`
    : `400 errorCode ${preview.errorCode} (hôm nay không xin nghỉ được)`,
);

const daily = await callRange(`/children/${id}/daily-assessments`, recentStarts);
const statuses = {};
for (const d of daily.data ?? []) statuses[d.status] = (statuses[d.status] ?? 0) + 1;
check(
  "GET /children/{id}/daily-assessments (Đánh giá · Ngày)",
  daily.status === 200 && Array.isArray(daily.data),
  `from ${daily.from}, days ${len(daily.data)} ${JSON.stringify(statuses)}`,
);
const weekly = await call("GET", `/children/${id}/weekly-comments`);
check("GET /children/{id}/weekly-comments (Đánh giá · Tuần)", weekly.status === 200 && Array.isArray(weekly.data), `items ${len(weekly.data)}`);
const evals = await call("GET", `/children/${id}/evaluations`);
check(
  "GET /children/{id}/evaluations (Chủ đề · Học kỳ · Cuối năm)",
  evals.status === 200 && Array.isArray(evals.data?.themes),
  `themes ${len(evals.data?.themes)}, semesters ${len(evals.data?.semesters)}, yearEnd ${evals.data?.yearEnd ? "có" : "null"}`,
);

const rewards = await callRange(`/children/${id}/rewards`, recentStarts);
check(
  "GET /children/{id}/rewards (Khen thưởng)",
  rewards.status === 200 && Array.isArray(rewards.data?.flags),
  `from ${rewards.from}, flags ${len(rewards.data?.flags)}, tickets ${len(rewards.data?.tickets)}, yearEndTitles ${len(rewards.data?.yearEndTitles)}`,
);

const book = await call("GET", `/children/${id}/health/published`);
const kinds = {};
for (const r of book.data?.results ?? []) kinds[r.campaignKind] = (kinds[r.campaignKind] ?? 0) + 1;
check(
  "GET /children/{id}/health/published (Sổ sức khỏe)",
  book.status === 200 && Array.isArray(book.data?.results),
  `results ${JSON.stringify(kinds)}, growth ${len(book.data?.growth)}, interpretation ${book.data?.interpretation ? "có" : "null"}`,
);

// AUTH-04: con của người khác ⇒ BE chặn
const other = await call("GET", "/children/999999/attendance/today");
check(
  "Con không thuộc tài khoản ⇒ 403/4108 hoặc 404",
  (other.status === 403 && other.errorCode === 4108) || other.status === 404,
  `status ${other.status}, errorCode ${other.errorCode}`,
);
// ATT-15: khoảng quá 62 ngày ⇒ 400/4109
const tooLong = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 70);
const range = await call("GET", `/children/${id}/attendance?from=${day(tooLong)}&to=${day(today)}`);
check("Khoảng ngày > 62 ngày ⇒ 400/4109", range.status === 400 && range.errorCode === 4109, `status ${range.status}, errorCode ${range.errorCode}`);

if (process.argv.includes("--sources")) {
  const run = spawnSync("flutter", ["test", "tool/parent_sources_live_check.dart", "-r", "expanded"], {
    stdio: "inherit",
    shell: process.platform === "win32",
    env: { ...process.env, CARENEST_TEST_BEARER: bearer, CARENEST_TEST_CHILD: String(id), CARENEST_API_BASE_URL: API },
  });
  check("Live…Source Dart đọc được dữ liệu BE thật", run.status === 0, `exit ${run.status}`);
}

console.log(failures ? `KẾT QUẢ: ${failures} FAIL` : "KẾT QUẢ: tất cả PASS");
process.exit(failures ? 1 : 0);
