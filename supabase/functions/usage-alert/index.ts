// =============================================================================
// usage-alert — StillScout Supabase Edge Function
// =============================================================================
// Reads today's global Gemini spend (`global_daily_spend`, populated by
// `vision-score`'s circuit-breaker) and posts a Slack/Discord webhook alert
// once usage crosses a configurable threshold of `GLOBAL_DAILY_PICK_CEILING`
// — so the app owner finds out *before* users start hitting hard 429s.
//
// Invoke manually (testing):
//   curl -X POST https://<project-ref>.functions.supabase.co/usage-alert \
//     -H "Authorization: Bearer <anon-or-service-role-key>"
//
// Invoke on a schedule: see docs/USAGE_ALERTS_SETUP.md (Supabase Dashboard
// Cron Job, point-and-click, no SQL required).
//
// Deploy:  supabase functions deploy usage-alert
// Secrets: supabase secrets set USAGE_ALERT_WEBHOOK_URL=...
//          supabase secrets set USAGE_ALERT_THRESHOLD_FRACTION=0.7   # optional
//          supabase secrets set GLOBAL_DAILY_PICK_CEILING=20000      # optional,
//            must match the value set for vision-score.
// =============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  AlertLevel,
  buildWebhookPayload,
  computeUsageStatus,
  formatAlertMessage,
  resolveAlertThresholdFraction,
  resolveGlobalDailyCeiling,
  shouldSendAlert,
  utcDateString,
} from "./lib.ts";

const GLOBAL_DAILY_PICK_CEILING = resolveGlobalDailyCeiling(
  Deno.env.get("GLOBAL_DAILY_PICK_CEILING"),
);
const ALERT_THRESHOLD_FRACTION = resolveAlertThresholdFraction(
  Deno.env.get("USAGE_ALERT_THRESHOLD_FRACTION"),
);
const WEBHOOK_URL = Deno.env.get("USAGE_ALERT_WEBHOOK_URL") ?? "";

function serviceClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function fetchTodayTotal(today: string): Promise<number> {
  const { data, error } = await serviceClient()
    .from("global_daily_spend")
    .select("count")
    .eq("date", today)
    .maybeSingle();

  if (error) {
    console.warn("[usage-alert] failed to read global_daily_spend:", error.message);
    return 0;
  }
  return (data?.count as number | undefined) ?? 0;
}

async function alreadyAlertedLevelsToday(today: string): Promise<AlertLevel[]> {
  const { data, error } = await serviceClient()
    .from("usage_alert_state")
    .select("level")
    .eq("alert_date", today);

  if (error) {
    // Fail safe toward "already alerted" is wrong here — better to risk one
    // duplicate alert than to silently stay quiet forever, so we treat a
    // read error as "nothing recorded yet" rather than suppressing.
    console.warn("[usage-alert] failed to read usage_alert_state:", error.message);
    return [];
  }
  return (data ?? []).map((row) => row.level as AlertLevel);
}

async function recordAlert(today: string, level: AlertLevel): Promise<void> {
  const { error } = await serviceClient()
    .from("usage_alert_state")
    .upsert({ alert_date: today, level }, { onConflict: "alert_date,level" });

  if (error) {
    console.warn("[usage-alert] failed to record alert state:", error.message);
  }
}

async function postWebhook(message: string): Promise<boolean> {
  if (!WEBHOOK_URL) {
    console.warn(
      "[usage-alert] USAGE_ALERT_WEBHOOK_URL not configured — skipping alert",
    );
    return false;
  }
  try {
    const resp = await fetch(WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(buildWebhookPayload(message)),
      signal: AbortSignal.timeout(10_000),
    });
    if (!resp.ok) {
      console.warn(`[usage-alert] webhook POST failed: ${resp.status}`);
      return false;
    }
    return true;
  } catch (e) {
    console.warn("[usage-alert] webhook POST error:", e);
    return false;
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const today = utcDateString();
  const total = await fetchTodayTotal(today);
  const status = computeUsageStatus({
    total,
    ceiling: GLOBAL_DAILY_PICK_CEILING,
    thresholdFraction: ALERT_THRESHOLD_FRACTION,
  });

  if (!status.level) {
    return jsonResponse({ ok: true, alerted: false, ...status });
  }

  const alertedLevels = await alreadyAlertedLevelsToday(today);
  if (!shouldSendAlert({ level: status.level, alreadyAlertedLevelsToday: alertedLevels })) {
    return jsonResponse({
      ok: true,
      alerted: false,
      reason: "already_alerted_today",
      ...status,
    });
  }

  const message = formatAlertMessage(status, { nowIso: new Date().toISOString() });
  const sent = await postWebhook(message);
  if (sent) {
    await recordAlert(today, status.level);
  }

  return jsonResponse({ ok: true, alerted: sent, ...status });
});
