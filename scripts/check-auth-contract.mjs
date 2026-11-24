#!/usr/bin/env node
// Kiểm contract đăng nhập của App với BE + Keycloak local (docs/integration/AUTH_FLOW.md), không cần emulator:
// PKCE của client carenest-mobile, /accounts/me theo role, refresh, logout, mã lỗi. Không in token, không in mật khẩu.
// Cần BE + Keycloak local đang chạy; tài khoản seed và mật khẩu theo BE:docs/TAI_KHOAN_DEV.md (Node >= 20).
// Dùng: CARENEST_SEED_PASSWORD=<mật khẩu seed local> node scripts/check-auth-contract.mjs
//       (đổi đích: CARENEST_OIDC_ISSUER, CARENEST_API_BASE_URL — mặc định như env/local.example.json)
import { createHash, randomBytes } from "node:crypto";

const ISSUER = process.env.CARENEST_OIDC_ISSUER ?? "http://localhost:8180/realms/carenest";
const API = process.env.CARENEST_API_BASE_URL ?? "http://localhost:8080/api";
const CLIENT = "carenest-mobile";
const REDIRECT = "carenest://oauth/callback";
const SCOPE = "openid profile";
const PW = process.env.CARENEST_SEED_PASSWORD;
if (!PW) {
  console.error("Thiếu CARENEST_SEED_PASSWORD (mật khẩu seed local, xem BE:docs/TAI_KHOAN_DEV.md).");
  process.exit(2);
}

// Tài khoản seed local của BE, mỗi role App một tài khoản + Hiệu trưởng (token App bị chặn)
const ACCOUNTS = [
  ["GV", "0343484905", { status: 200, role: "TEACHER" }],
  ["Bếp", "kitchen", { status: 200, role: "KITCHEN_STAFF" }],
  ["Phụ huynh", "0335474254", { status: 200, role: "PARENT", children: true }],
  ["Hiệu trưởng (token App)", "principal", { status: 403, errorCode: 1101 }],
];

let failures = 0;
const check = (name, ok, detail = "") => {
  if (!ok) failures++;
  console.log(`${ok ? "PASS" : "FAIL"} ${name}${detail ? ` — ${detail}` : ""}`);
};
const b64url = (buf) => buf.toString("base64url");
const claims = (jwt) => JSON.parse(Buffer.from(jwt.split(".")[1], "base64url").toString());
const form = (fields) => ({
  method: "POST",
  headers: { "content-type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams(fields),
});
const json = async (res) => {
  const text = await res.text();
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text.slice(0, 80) };
  }
};

class Jar {
  cookies = new Map();
  add(res) {
    for (const line of res.headers.getSetCookie()) {
      const [pair] = line.split(";");
      const i = pair.indexOf("=");
      this.cookies.set(pair.slice(0, i).trim(), pair.slice(i + 1));
    }
  }
  header() {
    return [...this.cookies].map(([k, v]) => `${k}=${v}`).join("; ");
  }
}

function authUrl(disc, redirect, challenge) {
  const url = new URL(disc.authorization_endpoint);
  url.search = new URLSearchParams({
    client_id: CLIENT,
    redirect_uri: redirect,
    response_type: "code",
    scope: SCOPE,
    code_challenge: challenge,
    code_challenge_method: "S256",
    state: b64url(randomBytes(8)),
    prompt: "login",
  }).toString();
  return url;
}

// Giống AppAuth: mở trang đăng nhập, gửi form, bắt redirect carenest://, đổi code + code_verifier lấy token
async function signIn(disc, username) {
  const jar = new Jar();
  const verifier = b64url(randomBytes(32));
  const challenge = b64url(createHash("sha256").update(verifier).digest());
  let res = await fetch(authUrl(disc, REDIRECT, challenge), { redirect: "manual" });
  jar.add(res);
  const page = await res.text();
  const action = page.match(/<form[^>]*action="([^"]*login-actions\/authenticate[^"]*)"/)?.[1];
  if (res.status !== 200 || !action) return { error: `trang đăng nhập ${res.status}` };
  res = await fetch(action.replaceAll("&amp;", "&"), {
    ...form({ username, password: PW, credentialId: "" }),
    redirect: "manual",
    headers: { "content-type": "application/x-www-form-urlencoded", cookie: jar.header() },
  });
  const location = res.headers.get("location") ?? "";
  if (!location.startsWith(REDIRECT)) {
    const body = await res.text();
    const title = body.match(/<title>([^<]*)<\/title>/)?.[1]?.trim();
    const error = body.match(/(?:input-error|kc-feedback-text)[^>]*>\s*([^<]+)/)?.[1]?.trim();
    return { error: `không redirect về App (${res.status}) ${title ?? ""} ${error ?? ""}`.trim() };
  }
  const code = new URL(location).searchParams.get("code");
  res = await fetch(
    disc.token_endpoint,
    form({
      grant_type: "authorization_code",
      client_id: CLIENT,
      code,
      redirect_uri: REDIRECT,
      code_verifier: verifier,
    }),
  );
  return { status: res.status, tokens: await json(res) };
}

const refresh = (disc, refreshToken) =>
  fetch(
    disc.token_endpoint,
    form({ grant_type: "refresh_token", client_id: CLIENT, refresh_token: refreshToken, scope: SCOPE }),
  );

const me = (bearer) =>
  fetch(`${API}/accounts/me`, { headers: bearer ? { authorization: `Bearer ${bearer}` } : {} });

// --- Không cần đăng nhập ---
const discRes = await fetch(`${ISSUER}/.well-known/openid-configuration`);
const disc = await json(discRes);
check("discovery: issuer khớp CARENEST_OIDC_ISSUER của App", discRes.status === 200 && disc.issuer === ISSUER, disc.issuer);
check(
  "discovery: có end_session_endpoint .../protocol/openid-connect/logout",
  disc.end_session_endpoint === `${ISSUER}/protocol/openid-connect/logout`,
);
if (discRes.status !== 200) {
  console.log(`KẾT QUẢ: không đọc được discovery của ${ISSUER} — BE/Keycloak local đã chạy chưa?`);
  process.exit(1);
}

{
  const res = await fetch(authUrl(disc, "carenest://wrong/callback", b64url(randomBytes(32))), { redirect: "manual" });
  const body = await res.text();
  check(
    "Keycloak từ chối redirect sai (client thật sự kiểm redirect)",
    res.status >= 400 || /redirect_uri/i.test(body),
    `status ${res.status}`,
  );
}

{
  const res = await me(null);
  const env = await json(res);
  check(
    "GET /accounts/me không token ⇒ 401 + errorCode 1002",
    res.status === 401 && env.code === 401 && env.errorCode === 1002,
    `status ${res.status}, errorCode ${env.errorCode}`,
  );
}

{
  // Mã kích hoạt sai nên BE từ chối trước khi đặt mật khẩu; mật khẩu giả
  const dummyPw = "Thu#nghiem2026";
  const res = await fetch(`${API}/parent-activation`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ phone: "0399999990", code: "000000", newPassword: dummyPw, confirmPassword: dummyPw }),
  });
  const env = await json(res);
  check(
    "POST /parent-activation mã sai ⇒ 400 + errorCode 1006 (không cần Bearer)",
    res.status === 400 && env.errorCode === 1006,
    `status ${res.status}, errorCode ${env.errorCode}, desc "${env.desc ?? ""}"`,
  );
}

{
  const res = await refresh(disc, "khong-phai-token");
  const body = await json(res);
  check(
    "refresh token rác ⇒ 400 invalid_grant (App coi là hết phiên)",
    res.status === 400 && body.error === "invalid_grant",
    `status ${res.status}, error ${body.error}`,
  );
}

// --- Theo tài khoản seed (mỗi role) ---
for (const [label, username, expected] of ACCOUNTS) {
  const login = await signIn(disc, username);
  if (login.error || login.status !== 200 || !login.tokens.access_token) {
    check(`${label}: đăng nhập PKCE + đổi code`, false, login.error ?? `token ${login.status} ${login.tokens?.error ?? ""}`);
    continue;
  }
  const { access_token: bearer, refresh_token: firstRefresh, expires_in: ttl, refresh_expires_in: refreshTtl } =
    login.tokens;
  const c = claims(bearer);
  const aud = [].concat(c.aud ?? []);
  check(
    `${label}: đăng nhập PKCE + đổi code`,
    true,
    `access ${ttl}s, refresh ${refreshTtl}s, iss ${c.iss === ISSUER ? "khớp" : c.iss}, azp ${c.azp}, aud ${aud.join("+")}`,
  );
  check(`${label}: token có aud carenest-api, azp carenest-mobile`, aud.includes("carenest-api") && c.azp === CLIENT);

  const meRes = await me(bearer);
  const env = await json(meRes);
  if (expected.status === 200) {
    const roles = env.data?.roles ?? [];
    const kids = env.data?.childIds ?? [];
    check(
      `${label}: /accounts/me 200, có role ${expected.role}${expected.children ? ", có con" : ""}`,
      meRes.status === 200 && roles.includes(expected.role) && (!expected.children || kids.length > 0),
      `status ${meRes.status}, roles ${roles.join("+")}, childIds ${kids.length}`,
    );
  } else {
    check(
      `${label}: /accounts/me ${expected.status} + errorCode ${expected.errorCode} (App báo "dùng trên Web")`,
      meRes.status === expected.status && env.errorCode === expected.errorCode,
      `status ${meRes.status}, errorCode ${env.errorCode}`,
    );
  }

  const r1 = await refresh(disc, firstRefresh);
  const t1 = await json(r1);
  check(
    `${label}: refresh ⇒ token mới`,
    r1.status === 200 && !!t1.access_token,
    `status ${r1.status}, refresh token ${t1.refresh_token && t1.refresh_token !== firstRefresh ? "đổi mới" : "giữ nguyên"}`,
  );
  const latest = t1.refresh_token ?? firstRefresh;

  const out = await fetch(disc.end_session_endpoint, form({ client_id: CLIENT, refresh_token: latest }));
  check(`${label}: logout (client_id + refresh_token) ⇒ 204`, out.status === 204, `status ${out.status}`);

  const r2 = await refresh(disc, latest);
  const t2 = await json(r2);
  check(
    `${label}: refresh sau logout ⇒ invalid_grant (phiên đã thu hồi)`,
    r2.status === 400 && t2.error === "invalid_grant",
    `status ${r2.status}, error ${t2.error}`,
  );
}

console.log(failures ? `KẾT QUẢ: ${failures} FAIL` : "KẾT QUẢ: tất cả PASS");
process.exit(failures ? 1 : 0);
