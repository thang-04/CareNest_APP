// Đăng nhập Keycloak như AppAuth của App (PKCE, client carenest-mobile) cho script kiểm với BE local.
// Không in token, không in mật khẩu.
import { createHash, randomBytes } from "node:crypto";

export const CLIENT = "carenest-mobile";
export const REDIRECT = "carenest://oauth/callback";
export const SCOPE = "openid profile";

export const b64url = (buf) => buf.toString("base64url");

export const form = (fields) => ({
  method: "POST",
  headers: { "content-type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams(fields),
});

export const json = async (res) => {
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

export function authUrl(disc, redirect, challenge) {
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
export async function signIn(disc, username, password) {
  const jar = new Jar();
  const verifier = b64url(randomBytes(32));
  const challenge = b64url(createHash("sha256").update(verifier).digest());
  let res = await fetch(authUrl(disc, REDIRECT, challenge), { redirect: "manual" });
  jar.add(res);
  const page = await res.text();
  const action = page.match(/<form[^>]*action="([^"]*login-actions\/authenticate[^"]*)"/)?.[1];
  if (res.status !== 200 || !action) return { error: `trang đăng nhập ${res.status}` };
  res = await fetch(action.replaceAll("&amp;", "&"), {
    ...form({ username, password, credentialId: "" }),
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
