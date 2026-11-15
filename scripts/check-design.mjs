#!/usr/bin/env node
// Cổng thiết kế App (DESIGN.md §13.2, §B8): đếm vi phạm theo từng file Dart trong lib/, so với scripts/design-baseline.json.
// File vượt baseline hoặc file mới có vi phạm ⇒ exit 1. Sửa bớt nợ ⇒ `--update` để hạ baseline; `--update` từ chối nâng.
// Nợ cũ giữ trong baseline (không bắt sửa hàng loạt); code mới dùng token/widget chung.
// Dùng: node scripts/check-design.mjs [--update] [--root <dir>]
import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

// Đường dẫn tính từ lib/. Luật lấy đúng lệnh grep của DESIGN.md §13.2.
export const CHECKS = {
  hex: {
    label: "màu ngoài token — dùng colorScheme / AppStatusColors",
    scope: /^/,
    skip: /^core\/constants\/(colors|sizes|shadows)\.dart$/,
    re: /Color\(0x|Colors\.(?:white|black|grey|red|blue|green)\b/g,
  },
  textStyle: {
    label: "fontSize/fontWeight ở feature — dùng textTheme",
    scope: /^features\//,
    skip: /^$/,
    re: /\b(?:fontSize|fontWeight):/g,
  },
  rawNumber: {
    label: "số tay trong BorderRadius/EdgeInsets/SizedBox — dùng AppSpacing/AppRadius/AppSizes",
    scope: /^features\//,
    skip: /^$/,
    re: /BorderRadius\.circular\([1-9]|EdgeInsets\.[a-zA-Z]+\([^)]*[1-9]|SizedBox\((?:width|height): *[1-9]/g,
  },
  icon: {
    label: "Icons.* ở feature — dùng AppIcons",
    scope: /^features\//,
    skip: /^$/,
    re: /\b(?:Icons|TablerIcons)\./g,
  },
  blur: {
    label: "BackdropFilter — kính chỉ ở hero, không trong list",
    scope: /^/,
    skip: /(^|\/)app_hero_[a-z_]+\.dart$/,
    re: /\bBackdropFilter\b/g,
  },
  rawWidget: {
    label: "widget Material thô ở feature — dùng widget lib/core/widgets",
    scope: /^features\//,
    skip: /^$/,
    re: /\b(?:ElevatedButton|AlertDialog|SnackBar|ListTile|CircleAvatar)\(/g,
  },
};

const walk = (dir) =>
  readdirSync(dir).flatMap((name) => {
    const abs = join(dir, name);
    return statSync(abs).isDirectory() ? walk(abs) : [abs];
  });

// Bỏ dòng comment để không bắt nhầm ví dụ trong doc comment
const stripComments = (text) => text.replace(/^\s*\/\/.*$/gm, "");

export function measure(root) {
  const lib = join(root, "lib");
  const result = Object.fromEntries(Object.keys(CHECKS).map((k) => [k, {}]));
  if (!existsSync(lib)) return result;
  for (const abs of walk(lib)) {
    if (!abs.endsWith(".dart")) continue;
    const rel = relative(root, abs).replaceAll("\\", "/");
    const inLib = rel.slice("lib/".length);
    let text = null;
    for (const [key, check] of Object.entries(CHECKS)) {
      if (!check.scope.test(inLib) || check.skip.test(inLib)) continue;
      text ??= stripComments(readFileSync(abs, "utf8"));
      const count = (text.match(check.re) || []).length;
      if (count) result[key][rel] = count;
    }
  }
  return result;
}

export function compare(current, baseline) {
  const problems = [];
  for (const [key, files] of Object.entries(current)) {
    for (const [file, count] of Object.entries(files)) {
      const allowed = baseline[key]?.[file] ?? 0;
      if (count > allowed) problems.push(`${file}: ${CHECKS[key].label} ${count} > baseline ${allowed}`);
    }
  }
  return problems;
}

const total = (m) => Object.values(m).reduce((s, n) => s + n, 0);

export function main(argv) {
  const rootArg = argv.indexOf("--root");
  const root = rootArg >= 0 ? argv[rootArg + 1] : join(fileURLToPath(new URL(".", import.meta.url)), "..");
  const baselinePath = join(root, "scripts", "design-baseline.json");
  const current = measure(root);
  const old = existsSync(baselinePath) ? JSON.parse(readFileSync(baselinePath, "utf8")) : null;
  if (argv.includes("--update")) {
    // Chỉ hạ: có baseline mà file vượt mức ⇒ từ chối; chưa có baseline ⇒ ghi mốc đầu tiên
    const raised = old ? compare(current, old) : [];
    if (raised.length) {
      console.log(`check-design: --update từ chối nâng baseline (${raised.length} file vượt mức):`);
      for (const p of raised.slice(0, 15)) console.log(`  ${p}`);
      return 1;
    }
    writeFileSync(baselinePath, `${JSON.stringify(current, null, 2)}\n`);
    console.log(`check-design: đã ghi baseline (${Object.entries(current).map(([k, v]) => `${k} ${total(v)}`).join(" · ")})`);
    return 0;
  }
  const baseline = old ?? {};
  const problems = compare(current, baseline);
  const summary = Object.entries(current).map(([k, v]) => `${k} ${total(v)}/${total(baseline[k] || {})}`).join(" · ");
  if (problems.length) {
    console.log(`check-design: FAIL · ${summary}`);
    for (const p of problems.slice(0, 15)) console.log(`  ${p}`);
    console.log("  Dùng token / widget chung (DESIGN.md §2, §B4). Sửa bớt nợ ⇒ node scripts/check-design.mjs --update");
    return 1;
  }
  console.log(`check-design: ok · ${summary} (hiện tại/baseline)`);
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) process.exitCode = main(process.argv.slice(2));
