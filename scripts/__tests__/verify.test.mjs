import assert from "node:assert/strict";
import { test } from "node:test";
import { formatFlutterSummary, formatSummary, parseFlutterStep, parseMavenOutput, selectQuickTests } from "../verify.mjs";

const PASS_OUTPUT = [
  "[INFO] --- surefire:3.5.6:test (default-test) @ carenest-be ---",
  "[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 12.3 s -- in com.carenest.contract.OpenApiSnapshotTest",
  "[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.2 s -- in com.carenest.architecture.ArchitectureRulesTest",
  "[INFO] Results:",
  "[INFO] ",
  "[INFO] Tests run: 12, Failures: 0, Errors: 0, Skipped: 0",
  "[INFO] --- spotless:3.10.3:check (default) @ carenest-be ---",
  "[INFO] BUILD SUCCESS",
].join("\r\n");

test("parse: chỉ cộng dòng tổng, không cộng dòng từng class; trạng thái cổng", () => {
  const parsed = parseMavenOutput(PASS_OUTPUT);
  assert.equal(parsed.tests, 12);
  assert.equal(parsed.build, "SUCCESS");
  assert.equal(parsed.spotless, "ok");
  const line = formatSummary("full", parsed, 0, 36, "target/verify.log");
  assert.equal(
    line,
    "VERIFY PASS full | tests 12 fail 0 err 0 skip 0 | archunit ok | snapshot ok | spotless ok | 36s | log target/verify.log",
  );
});

test("parse: cộng surefire + failsafe", () => {
  const parsed = parseMavenOutput("[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 1\n[WARNING] Tests run: 3, Failures: 0, Errors: 0, Skipped: 2");
  assert.deepEqual([parsed.tests, parsed.skipped], [8, 3]);
});

test("parse: ArchUnit fail ⇒ tên test + dòng chi tiết có File.java:line", () => {
  const out = [
    "[ERROR] Tests run: 11, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 3 s <<< FAILURE! -- in com.carenest.architecture.ArchitectureRulesTest",
    "[INFO] Results:",
    "[ERROR] Failures: ",
    "[ERROR]   ArchitectureRulesTest.servicesDoNotBuildHttpResponses Architecture Violation - Rule 'x' was violated (2 times):",
    "Method <com.carenest.service.tmp.TmpService.status()> gets field <HttpStatus.OK> in (TmpService.java:7)",
    "Method <...> has return type <HttpStatus> in (TmpService.java:0)",
    "[INFO] ",
    "[ERROR] Tests run: 24, Failures: 1, Errors: 0, Skipped: 0",
    "[INFO] BUILD FAILURE",
    "[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.5.6:test: There are test failures.",
  ].join("\n");
  const parsed = parseMavenOutput(out);
  assert.equal(parsed.problems.length, 1);
  assert.match(parsed.problems[0], /servicesDoNotBuildHttpResponses.*→ .*TmpService.java:7/);
  const summary = formatSummary("full", parsed, 1, 35, "target/verify.log");
  assert.match(summary, /^VERIFY FAIL full \| tests 24 fail 1 .*archunit FAIL/);
  assert.match(summary, /Chi tiết: grep -n "ERROR" target\/verify.log$/);
});

test("parse: Spotless fail chỉ lấy tên file, bỏ dòng diff", () => {
  const out = [
    "[INFO] --- spotless:3.10.3:check (default) @ carenest-be ---",
    "[ERROR] Failed to execute goal com.diffplug.spotless:spotless-maven-plugin:3.10.3:check (default) on project carenest-be: The following files had format violations:",
    "[ERROR]     src\\test\\java\\com\\carenest\\contract\\OpenApiSnapshotTest.java",
    "[ERROR]         @@ -1,3 +1,3 @@",
    "[ERROR]         -  private   static",
    "[INFO] BUILD FAILURE",
  ].join("\n");
  const parsed = parseMavenOutput(out);
  assert.equal(parsed.spotless, "FAIL");
  assert.deepEqual(parsed.problems, ["format: src\\test\\java\\com\\carenest\\contract\\OpenApiSnapshotTest.java (sửa: mvnw spotless:apply)"]);
});

test("parse: lỗi compile và fallback 'Failed to execute goal'", () => {
  const compile = parseMavenOutput("[ERROR] /D:/x/src/main/java/A.java:[10,5] cannot find symbol\n[INFO] BUILD FAILURE");
  assert.deepEqual(compile.problems, ["/D:/x/src/main/java/A.java:[10,5] cannot find symbol"]);
  const other = parseMavenOutput("[INFO] BUILD FAILURE\n[ERROR] Failed to execute goal x:y: boom");
  assert.deepEqual(other.problems, ["Failed to execute goal x:y: boom"]);
});

test("summary: test bị skip (không Docker) ⇒ cảnh báo chưa kiểm chứng", () => {
  const parsed = parseMavenOutput(
    [
      "[WARNING] Tests run: 1, Failures: 0, Errors: 0, Skipped: 1, Time elapsed: 0 s -- in com.carenest.contract.OpenApiSnapshotTest",
      "Could not find a valid Docker environment",
      "[WARNING] Tests run: 12, Failures: 0, Errors: 0, Skipped: 1",
      "[INFO] BUILD SUCCESS",
    ].join("\n"),
  );
  const summary = formatSummary("full", parsed, 0, 20, "target/verify.log");
  assert.match(summary, /^VERIFY PASS full .*skip 1 \| archunit - \| snapshot SKIP/);
  assert.match(summary, /CẢNH BÁO: 1 test bị skip \(không có Docker\) ⇒ phần đó CHƯA kiểm chứng/);
});

test("summary: exit code ≠ 0 luôn là FAIL dù có BUILD SUCCESS", () => {
  assert.match(formatSummary("quick", parseMavenOutput("[INFO] BUILD SUCCESS"), 1, 1, "l"), /^VERIFY FAIL quick/);
});

const TESTS = [
  "src/test/java/com/carenest/service/child/ChildServiceTest.java",
  "src/test/java/com/carenest/repository/ScopeQueryIntegrationTest.java",
  "src/test/java/com/carenest/repository/account/UserAccountRepositoryIntegrationTest.java",
  "src/test/java/com/carenest/CareNestApplicationTests.java",
];

test("quick: map class → XxxTest / XxxIntegrationTest, luôn kèm ArchUnit", () => {
  const pick = selectQuickTests(
    ["src/main/java/com/carenest/service/child/ChildService.java", "src/main/java/com/carenest/repository/account/UserAccountRepository.java"],
    TESTS,
  );
  assert.deepEqual(pick.tests.sort(), ["ArchitectureRulesTest", "ChildServiceTest", "UserAccountRepositoryIntegrationTest"]);
  assert.equal(pick.needsFull, false);
  assert.equal(pick.allTests, false);
});

test("quick: đổi controller/dto ⇒ thêm snapshot; đổi test ⇒ chạy chính test đó", () => {
  const pick = selectQuickTests(
    ["src/main/java/com/carenest/controller/child/ChildController.java", "src/test/java/com/carenest/x/FooTest.java"],
    TESTS,
  );
  assert.ok(pick.tests.includes("OpenApiSnapshotTest"));
  assert.ok(pick.tests.includes("FooTest"));
});

test("quick: đổi pom/resources ⇒ cần full; class không có test ⇒ chạy toàn bộ test", () => {
  assert.equal(selectQuickTests(["src/main/resources/db/migration/V2__x.sql"], TESTS).needsFull, true);
  assert.equal(selectQuickTests(["pom.xml"], TESTS).needsFull, true);
  assert.equal(selectQuickTests(["src/main/java/com/carenest/utils/NewUtil.java"], TESTS).allTests, true);
  assert.deepEqual(selectQuickTests([], TESTS), { tests: ["ArchitectureRulesTest"], needsFull: false, allTests: false });
});

test("flutter: format đổi file ⇒ FAIL + tên file", () => {
  const step = parseFlutterStep("format", "Changed lib/app.dart\nFormatted 3 files (1 changed) in 0.10 seconds.\n", 1);
  assert.equal(step.status, "FAIL");
  assert.deepEqual(step.problems, ["format: lib/app.dart (sửa: dart format lib test)"]);
  assert.equal(parseFlutterStep("format", "Formatted 3 files (0 changed) in 0.10 seconds.\n", 0).status, "ok");
});

test("flutter: analyze đếm issue và lấy dòng lỗi", () => {
  const out = [
    "Analyzing carenest_app...",
    "",
    "  error • Undefined name 'x' • lib/app.dart:3:5 • undefined_identifier",
    "   info • Use 'const' • lib/main.dart:7:3 • prefer_const_constructors",
    "",
    "2 issues found. (ran in 1.2s)",
  ].join("\r\n");
  const step = parseFlutterStep("analyze", out, 1);
  assert.equal(step.status, "2 issues");
  assert.equal(step.problems.length, 2);
  assert.match(step.problems[0], /^analyze: error • Undefined name 'x' • lib\/app\.dart:3:5/);
  assert.equal(parseFlutterStep("analyze", "No issues found! (ran in 0.9s)\n", 0).status, "ok");
});

test("flutter: test lấy số đếm cuối, skip và test fail", () => {
  const out = [
    "00:01 +0: loading test/a_test.dart",
    "00:02 +1: test/a_test.dart: theme primary",
    "00:02 +1 -1: test/a_test.dart: button loading [E]",
    "00:03 +2 ~1 -1: Some tests failed.",
  ].join("\n");
  const step = parseFlutterStep("test", out, 1);
  assert.deepEqual([step.tests, step.failures, step.skipped], [4, 1, 1]);
  assert.equal(step.status, "FAIL");
  assert.deepEqual(step.problems, ["test: test/a_test.dart: button loading"]);
  const pass = parseFlutterStep("test", "00:02 +5: All tests passed!\n", 0);
  assert.deepEqual([pass.status, pass.tests, pass.failures], ["ok", 5, 0]);
});

test("flutter summary: bước chưa chạy hiện '-', skip ⇒ cảnh báo", () => {
  const steps = {
    format: parseFlutterStep("format", "Formatted 3 files (0 changed)", 0),
    analyze: parseFlutterStep("analyze", "No issues found!", 0),
    test: parseFlutterStep("test", "00:02 +3 ~1: All tests passed!", 0),
  };
  const lines = formatFlutterSummary(steps, 0, 20, "verify.log").split("\n");
  assert.equal(lines[0], "VERIFY PASS full | format ok | analyze ok | tests 4 fail 0 skip 1 | 20s | log verify.log");
  assert.match(lines[1], /1 test bị skip/);
  const failed = formatFlutterSummary({ format: parseFlutterStep("format", "Changed lib/a.dart", 1) }, 1, 2, "verify.log");
  assert.match(failed, /^VERIFY FAIL full \| format FAIL \| analyze - \| tests - \| 2s \| log verify\.log\n- format: lib\/a\.dart/);
});
