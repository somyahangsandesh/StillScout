// Pure helpers for usage-alert — importable from Deno tests without
// starting the edge runtime.

// NOTE: `DEFAULT_GLOBAL_DAILY_PICK_CEILING` and `resolveGlobalDailyCeiling`
// are intentionally duplicated from `supabase/functions/vision-score/lib.ts`
// rather than cross-imported — Supabase deploys each function directory
// independently, and reaching into a sibling function's source is fragile.
// If you change the default or parsing logic here, change it there too
// (and vice versa) — both read the same `GLOBAL_DAILY_PICK_CEILING` secret
// and must agree on what it means.
export const DEFAULT_GLOBAL_DAILY_PICK_CEILING = 20_000;

export function resolveGlobalDailyCeiling(raw: string | undefined): number {
  const parsed = raw ? Number.parseInt(raw, 10) : NaN;
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_GLOBAL_DAILY_PICK_CEILING;
  }
  return parsed;
}

/** Default fraction of the global ceiling that triggers a "warning" alert. */
export const DEFAULT_ALERT_THRESHOLD_FRACTION = 0.7;

/** Parses `USAGE_ALERT_THRESHOLD_FRACTION`, falling back to a sane default
 * for any missing/non-numeric/out-of-(0,1) value. */
export function resolveAlertThresholdFraction(raw: string | undefined): number {
  const parsed = raw ? Number.parseFloat(raw) : NaN;
  if (!Number.isFinite(parsed) || parsed <= 0 || parsed >= 1) {
    return DEFAULT_ALERT_THRESHOLD_FRACTION;
  }
  return parsed;
}

/**
 * "warning" = usage crossed the configurable threshold fraction (default
 * 70%) of the global ceiling. "critical" = the ceiling itself was reached
 * (i.e. `vision-score` is now actively rejecting requests with
 * `GLOBAL_CAP_REACHED`). Each level alerts at most once per UTC day.
 */
export type AlertLevel = "warning" | "critical";

export interface UsageStatus {
  total: number;
  ceiling: number;
  /** total / ceiling, e.g. 0.734 */
  fraction: number;
  /** fraction as a percentage rounded to one decimal, e.g. 73.4 */
  percent: number;
  /** null when usage is below the warning threshold — no alert warranted. */
  level: AlertLevel | null;
}

export function computeUsageStatus(opts: {
  total: number;
  ceiling: number;
  thresholdFraction: number;
}): UsageStatus {
  const ceiling = Math.max(opts.ceiling, 1);
  const total = Math.max(opts.total, 0);
  const fraction = total / ceiling;
  const percent = Math.round(fraction * 1000) / 10;

  let level: AlertLevel | null = null;
  if (fraction >= 1) {
    level = "critical";
  } else if (fraction >= opts.thresholdFraction) {
    level = "warning";
  }

  return { total, ceiling, fraction, percent, level };
}

/** Dedup: only alert for [level] if it hasn't already fired today. Each
 * level (warning, critical) is tracked independently so crossing 100% after
 * already having warned at 70% still sends a second, more urgent alert. */
export function shouldSendAlert(opts: {
  level: AlertLevel | null;
  alreadyAlertedLevelsToday: AlertLevel[];
}): boolean {
  if (!opts.level) return false;
  return !opts.alreadyAlertedLevelsToday.includes(opts.level);
}

export function formatAlertMessage(
  status: UsageStatus,
  opts: { nowIso: string },
): string {
  const label = status.level === "critical"
    ? "🚨 CRITICAL"
    : "⚠️ WARNING";
  return (
    `${label}: StillScout global daily Gemini spend at ${status.percent}% of ceiling\n` +
    `Picks used today: ${status.total} / ${status.ceiling}\n` +
    `Time: ${opts.nowIso}`
  );
}

/**
 * Slack incoming webhooks expect `{"text": "..."}`. Discord webhooks expect
 * `{"content": "..."}` and ignore unknown fields, so sending both keys in
 * one body satisfies either platform without needing to detect which one
 * is configured. See docs/USAGE_ALERTS_SETUP.md for details.
 */
export function buildWebhookPayload(message: string): Record<string, unknown> {
  return { text: message, content: message };
}

/** UTC calendar date, e.g. "2026-07-28" — matches the `date` column keying
 * used by `global_daily_spend` (Postgres `current_date`, UTC by default on
 * Supabase) and by `usage_alert_state`. */
export function utcDateString(nowMs: number = Date.now()): string {
  return new Date(nowMs).toISOString().slice(0, 10);
}
