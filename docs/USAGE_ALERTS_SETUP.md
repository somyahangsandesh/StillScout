# Usage alerts — early warning before the global spend ceiling trips

`vision-score` enforces `GLOBAL_DAILY_PICK_CEILING` (default 20,000
picks/day, see `docs/REVENUECAT_WEBHOOK_SETUP.md`) as a circuit-breaker
across every user/tier. That ceiling rejects requests with a hard `429
GLOBAL_CAP_REACHED` once tripped — by definition, too late to act on
gracefully.

The new `usage-alert` edge function closes that gap: on each invocation it
reads today's total from `global_daily_spend` and, once usage crosses a
configurable threshold (default **70%** of the ceiling), posts a message to
a Slack or Discord webhook. It fires again at **100%** (ceiling reached) as
a separate, more urgent alert. Each level alerts **at most once per UTC
day** (tracked in the new `usage_alert_state` table) so a 30–60 minute
schedule doesn't spam the channel.

If `USAGE_ALERT_WEBHOOK_URL` isn't set, the function logs a warning and
returns `200 { alerted: false }` — it never fails/crashes on missing
config, so it's safe to deploy before you've set up a webhook.

## 1. Apply the new migration

```bash
export PATH="$HOME/.local/bin:$PATH"
supabase login   # or export SUPABASE_ACCESS_TOKEN=sbp_…
supabase db push --project-ref "$SUPABASE_PROJECT_REF"
```

This creates `usage_alert_state` (from
`supabase/migrations/20260728000002_usage_alert_state.sql`). You can also
apply it by pasting the file into the Supabase SQL editor if you'd rather
not use the CLI.

## 2. Deploy the function

```bash
supabase functions deploy usage-alert --project-ref "$SUPABASE_PROJECT_REF"
```

## 3. Create a webhook and set the secret

Pick Slack or Discord (both work — see [Webhook payload format](#webhook-payload-format) below):

- **Slack**: create an [Incoming Webhook](https://api.slack.com/messaging/webhooks) for the channel you want alerts in and copy its URL.
- **Discord**: in the target channel, go to **Channel Settings → Integrations → Webhooks → New Webhook** and copy its URL.

Set it as a Supabase secret — **never commit this value**:

```bash
supabase secrets set USAGE_ALERT_WEBHOOK_URL='paste_the_webhook_url' \
  --project-ref "$SUPABASE_PROJECT_REF"
```

Optional tuning secrets (both default to sane values if unset):

```bash
# Fraction of GLOBAL_DAILY_PICK_CEILING that triggers the first ("warning") alert.
supabase secrets set USAGE_ALERT_THRESHOLD_FRACTION='0.7' \
  --project-ref "$SUPABASE_PROJECT_REF"

# Must match the value set for vision-score — see docs/REVENUECAT_WEBHOOK_SETUP.md.
supabase secrets set GLOBAL_DAILY_PICK_CEILING='20000' \
  --project-ref "$SUPABASE_PROJECT_REF"
```

## 4. Schedule it — Supabase Dashboard Cron Job (recommended)

No SQL required:

1. In the [Supabase dashboard](https://supabase.com/dashboard), go to **Edge Functions → Cron Jobs** (or **Integrations → Cron**, naming varies by dashboard version).
2. Click **Create a new cron job**.
3. **Function**: select `usage-alert`.
4. **Schedule**: every 30–60 minutes, e.g. `*/30 * * * *`.
5. Save. The dashboard handles auth (it calls the function with the project's service role, or you can supply an `Authorization: Bearer <anon-key>` header if prompted — either is fine since the function only reads `global_daily_spend`/`usage_alert_state` via its own service-role client, not the caller's).

### Optional advanced alternative: `pg_cron` + `pg_net`

If your project already has the `pg_cron` and `pg_net` extensions enabled
and you'd rather manage the schedule as SQL, you can add a migration like:

```sql
select cron.schedule(
  'usage-alert-every-30-min',
  '*/30 * * * *',
  $$
  select net.http_post(
    url := 'https://<project-ref>.functions.supabase.co/usage-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')
    )
  );
  $$
);
```

This repo does **not** ship that migration by default — it requires
storing your service role key in Supabase Vault first (`select
vault.create_secret('<service-role-key>', 'service_role_key')`, run once
from the SQL editor, never committed to git) and is more fragile to get
right than the dashboard cron job above. Only use this path if you have a
specific reason to keep scheduling as code.

## 5. Test it manually

```bash
curl -i -X POST "https://<project-ref>.functions.supabase.co/usage-alert" \
  -H "Authorization: Bearer <anon-or-service-role-key>"
```

Expected response shape:

```json
{"ok":true,"alerted":false,"total":123,"ceiling":20000,"fraction":0.006,"percent":0.6,"level":null}
```

- `alerted: true` means a webhook message was just sent (and recorded in `usage_alert_state`, so it won't repeat today for that level).
- `alerted: false` with `level: null` means usage is comfortably below the threshold.
- `alerted: false, reason: "already_alerted_today"` means the threshold was already crossed and alerted earlier today — expected behavior, not a bug.

To force-test an actual alert without waiting for real traffic, temporarily
lower the threshold/ceiling via secrets (e.g.
`GLOBAL_DAILY_PICK_CEILING=1`), invoke the function once, confirm the
webhook message arrives, then restore the real values.

## Webhook payload format

The function POSTs a JSON body containing **both** `text` (what Slack
incoming webhooks read) and `content` (what Discord webhooks read):

```json
{"text": "⚠️ WARNING: ...", "content": "⚠️ WARNING: ..."}
```

Slack ignores the unknown `content` field and Discord ignores the unknown
`text` field, so the same payload works for either platform without
needing to detect which one is configured. If you use a different webhook
provider that's strict about unknown fields, you may need to adapt
`buildWebhookPayload` in `supabase/functions/usage-alert/lib.ts`.

## Required secrets — summary

| Secret | Used by | Purpose |
| --- | --- | --- |
| `USAGE_ALERT_WEBHOOK_URL` | `usage-alert` | Slack/Discord webhook URL to POST alerts to (required — omit to disable alerting gracefully) |
| `USAGE_ALERT_THRESHOLD_FRACTION` | `usage-alert` | Optional — fraction of the ceiling that triggers a "warning" alert (default `0.7`) |
| `GLOBAL_DAILY_PICK_CEILING` | `usage-alert`, `vision-score` | Optional — must be kept in sync between both functions (default 20,000) |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are already provided
automatically inside every Supabase edge function runtime — no manual setup
needed for those.
