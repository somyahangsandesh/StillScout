import { assertEquals } from "jsr:@std/assert";
import {
  AlertLevel,
  buildWebhookPayload,
  computeUsageStatus,
  DEFAULT_ALERT_THRESHOLD_FRACTION,
  DEFAULT_GLOBAL_DAILY_PICK_CEILING,
  formatAlertMessage,
  resolveAlertThresholdFraction,
  resolveGlobalDailyCeiling,
  shouldSendAlert,
  utcDateString,
} from "./lib.ts";

Deno.test("resolveGlobalDailyCeiling falls back to default for missing/invalid values", () => {
  assertEquals(resolveGlobalDailyCeiling(undefined), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling(""), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling("not_a_number"), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling("-5"), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling("0"), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
});

Deno.test("resolveGlobalDailyCeiling parses a valid positive integer", () => {
  assertEquals(resolveGlobalDailyCeiling("30000"), 30000);
});

Deno.test("resolveAlertThresholdFraction falls back to default for missing/out-of-range values", () => {
  assertEquals(resolveAlertThresholdFraction(undefined), DEFAULT_ALERT_THRESHOLD_FRACTION);
  assertEquals(resolveAlertThresholdFraction(""), DEFAULT_ALERT_THRESHOLD_FRACTION);
  assertEquals(resolveAlertThresholdFraction("not_a_number"), DEFAULT_ALERT_THRESHOLD_FRACTION);
  assertEquals(resolveAlertThresholdFraction("0"), DEFAULT_ALERT_THRESHOLD_FRACTION);
  assertEquals(resolveAlertThresholdFraction("1"), DEFAULT_ALERT_THRESHOLD_FRACTION);
  assertEquals(resolveAlertThresholdFraction("1.5"), DEFAULT_ALERT_THRESHOLD_FRACTION);
});

Deno.test("resolveAlertThresholdFraction parses a valid fraction", () => {
  assertEquals(resolveAlertThresholdFraction("0.8"), 0.8);
});

Deno.test("computeUsageStatus reports no alert level below threshold", () => {
  const status = computeUsageStatus({ total: 100, ceiling: 1000, thresholdFraction: 0.7 });
  assertEquals(status.level, null);
  assertEquals(status.percent, 10);
});

Deno.test("computeUsageStatus reports warning at/above threshold, below ceiling", () => {
  const atThreshold = computeUsageStatus({ total: 700, ceiling: 1000, thresholdFraction: 0.7 });
  assertEquals(atThreshold.level, "warning");
  assertEquals(atThreshold.percent, 70);

  const justUnder = computeUsageStatus({ total: 699, ceiling: 1000, thresholdFraction: 0.7 });
  assertEquals(justUnder.level, null);

  const between = computeUsageStatus({ total: 950, ceiling: 1000, thresholdFraction: 0.7 });
  assertEquals(between.level, "warning");
});

Deno.test("computeUsageStatus reports critical once ceiling is reached or exceeded", () => {
  const atCeiling = computeUsageStatus({ total: 1000, ceiling: 1000, thresholdFraction: 0.7 });
  assertEquals(atCeiling.level, "critical");
  assertEquals(atCeiling.percent, 100);

  const overCeiling = computeUsageStatus({ total: 1200, ceiling: 1000, thresholdFraction: 0.7 });
  assertEquals(overCeiling.level, "critical");
  assertEquals(overCeiling.percent, 120);
});

Deno.test("computeUsageStatus clamps negative totals and non-positive ceilings defensively", () => {
  const negativeTotal = computeUsageStatus({ total: -50, ceiling: 1000, thresholdFraction: 0.7 });
  assertEquals(negativeTotal.total, 0);
  assertEquals(negativeTotal.level, null);

  const zeroCeiling = computeUsageStatus({ total: 5, ceiling: 0, thresholdFraction: 0.7 });
  assertEquals(zeroCeiling.ceiling, 1);
  assertEquals(zeroCeiling.level, "critical");
});

Deno.test("shouldSendAlert is false when there is no level", () => {
  assertEquals(
    shouldSendAlert({ level: null, alreadyAlertedLevelsToday: [] }),
    false,
  );
});

Deno.test("shouldSendAlert is true the first time a level is reached today", () => {
  assertEquals(
    shouldSendAlert({ level: "warning", alreadyAlertedLevelsToday: [] }),
    true,
  );
});

Deno.test("shouldSendAlert dedups the same level already alerted today", () => {
  assertEquals(
    shouldSendAlert({ level: "warning", alreadyAlertedLevelsToday: ["warning"] }),
    false,
  );
});

Deno.test("shouldSendAlert still alerts a distinct, more urgent level even if another already fired today", () => {
  const alreadyAlerted: AlertLevel[] = ["warning"];
  assertEquals(
    shouldSendAlert({ level: "critical", alreadyAlertedLevelsToday: alreadyAlerted }),
    true,
  );
});

Deno.test("formatAlertMessage includes total, ceiling, percent, and timestamp", () => {
  const status = computeUsageStatus({ total: 700, ceiling: 1000, thresholdFraction: 0.7 });
  const message = formatAlertMessage(status, { nowIso: "2026-07-28T10:00:00.000Z" });
  assertEquals(message.includes("700"), true);
  assertEquals(message.includes("1000"), true);
  assertEquals(message.includes("70"), true);
  assertEquals(message.includes("2026-07-28T10:00:00.000Z"), true);
  assertEquals(message.includes("WARNING"), true);
});

Deno.test("formatAlertMessage labels critical alerts distinctly from warnings", () => {
  const status = computeUsageStatus({ total: 1000, ceiling: 1000, thresholdFraction: 0.7 });
  const message = formatAlertMessage(status, { nowIso: "2026-07-28T10:00:00.000Z" });
  assertEquals(message.includes("CRITICAL"), true);
});

Deno.test("buildWebhookPayload sets both text (Slack) and content (Discord) keys", () => {
  const payload = buildWebhookPayload("hello");
  assertEquals(payload.text, "hello");
  assertEquals(payload.content, "hello");
});

Deno.test("utcDateString formats a fixed timestamp as a UTC calendar date", () => {
  const ms = Date.parse("2026-07-28T23:59:59.000Z");
  assertEquals(utcDateString(ms), "2026-07-28");
});
