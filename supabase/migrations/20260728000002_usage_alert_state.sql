-- Dedup state for the `usage-alert` edge function, so repeated scheduled
-- invocations within the same UTC day don't spam the alert webhook once a
-- threshold has already fired.
-- Apply via `supabase db push` or MCP apply_migration.

-- ── usage_alert_state ────────────────────────────────────────────────────
-- One row per (UTC day, alert level) that has already been sent. "warning"
-- fires once usage crosses USAGE_ALERT_THRESHOLD_FRACTION (default 70%) of
-- GLOBAL_DAILY_PICK_CEILING; "critical" fires once the ceiling itself is
-- reached. Each level is tracked independently so a critical alert can
-- still fire the same day a warning already did.
create table if not exists public.usage_alert_state (
  alert_date date        not null,
  level      text        not null,
  alerted_at timestamptz not null default now(),
  primary key (alert_date, level)
);

alter table public.usage_alert_state enable row level security;

-- No policies are defined on purpose: only the service role (used by the
-- `usage-alert` edge function) can read/write this table. Clients
-- authenticate with the anon key and have zero direct access.
