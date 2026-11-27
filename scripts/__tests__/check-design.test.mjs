// Cổng thiết kế App: đếm vi phạm theo file, so baseline, --update chỉ hạ.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";
import { compare, main, measure } from "../check-design.mjs";
import { makeRepo, writeFiles } from "./helpers.mjs";

const SCREEN = "lib/features/demo/presentation/screens/demo_screen.dart";
const quiet = (fn) => {
  const log = console.log;
  console.log = () => {};
  try {
    return fn();
  } finally {
    console.log = log;
  }
};

test("đếm đúng luật theo phạm vi, bỏ dòng comment, không nhầm AppIcons", () => {
  const root = makeRepo({
    [SCREEN]: [
      "// Icons.add trong comment không tính",
      "final a = Icons.add; final b = AppIcons.save;",
      "Text('x', style: TextStyle(fontSize: 14));",
      "SizedBox(height: 8); SizedBox(height: AppSpacing.space2);",
      "ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: x));",
      "const c = Color(0xFF000000);",
    ].join("\n"),
    "lib/core/constants/colors.dart": "const brand = Color(0xFF4FB0F5);",
    "lib/core/widgets/app_button.dart": "Icons.add; fontSize: 1;",
  });
  const m = measure(root);
  assert.deepEqual(m.icon, { [SCREEN]: 1 });
  assert.deepEqual(m.textStyle, { [SCREEN]: 1 });
  assert.deepEqual(m.rawNumber, { [SCREEN]: 1 });
  assert.deepEqual(m.rawWidget, { [SCREEN]: 1 });
  assert.deepEqual(m.hex, { [SCREEN]: 1 });
});

test("hằng có chữ số trong tên (AppSpacing.space1) không tính là số tay", () => {
  const root = makeRepo({
    [SCREEN]: [
      "EdgeInsets.only(top: AppSpacing.space1);",
      "EdgeInsets.only(",
      "  left: AppSpacing.pagePadding,",
      "  bottom: AppSpacing.space3,",
      ");",
      "EdgeInsets.symmetric(vertical: AppSpacing.space2);",
      "EdgeInsets.only(top: 6);",
      "EdgeInsets.fromLTRB(0, AppSpacing.space2, 0, 12);",
    ].join("\n"),
  });
  assert.deepEqual(measure(root).rawNumber, { [SCREEN]: 2 });
});

test("file mới có vi phạm hoặc vượt baseline ⇒ FAIL; bằng baseline ⇒ ok", () => {
  const baseline = { icon: { [SCREEN]: 1 } };
  assert.deepEqual(compare({ icon: { [SCREEN]: 1 } }, baseline), []);
  assert.equal(compare({ icon: { [SCREEN]: 2 } }, baseline).length, 1);
  assert.equal(compare({ icon: { "lib/features/x/new.dart": 1 } }, baseline).length, 1);
});

test("--update ghi mốc đầu, hạ được, từ chối nâng", () => {
  const root = makeRepo({ [SCREEN]: "Icons.add; Icons.close;", "scripts/.keep": "" });
  const run = (...args) => quiet(() => main([...args, "--root", root]));
  const baselineOf = () => JSON.parse(readFileSync(join(root, "scripts", "design-baseline.json"), "utf8"));

  assert.equal(run("--update"), 0);
  assert.equal(baselineOf().icon[SCREEN], 2);
  assert.equal(run(), 0);

  writeFiles(root, { [SCREEN]: "Icons.add; Icons.close; Icons.home;" });
  assert.equal(run(), 1);
  assert.equal(run("--update"), 1);
  assert.equal(baselineOf().icon[SCREEN], 2);

  writeFiles(root, { [SCREEN]: "Icons.add;" });
  assert.equal(run("--update"), 0);
  assert.equal(baselineOf().icon[SCREEN], 1);
});
