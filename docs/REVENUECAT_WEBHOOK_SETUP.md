# RevenueCat webhook → server-verified Pro entitlement

This closes the gap where `vision-score` used to trust a client-claimed "Pro"
flag. Now:

1. RevenueCat calls the new `revenuecat-webhook` edge function on every
   subscription lifecycle event (purchase, renewal, cancellation, expiry, …).
2. That function verifies a shared-secret bearer token, then upserts the
   subscriber's Pro status into a `pro_entitlements` table (service-role
   only — no client can read or write it directly).
3. `vision-score` looks up `pro_entitlements` for the `app_user_id` sent by
   the app (RevenueCat's `Purchases.appUserID`) and only grants the high
   Pro ceiling when that lookup positively confirms an active subscription.
   Any DB error / missing row / expired row falls back to the free cap —
   never the other way around.

Supabase deploy (migrations + functions + `REVENUECAT_WEBHOOK_SECRET`) can be
done from the CLI. The RevenueCat dashboard webhook URL/auth paste is still
manual — follow step 4 below after deploy.

Project ref: `zyadgkgumdgussvkgtsr`.

## 1. Apply the new migration

```bash
export PATH="$HOME/.local/share/supabase:$HOME/.local/bin:$PATH"
supabase login   # or export SUPABASE_ACCESS_TOKEN=sbp_…
supabase link --project-ref zyadgkgumdgussvkgtsr --yes
supabase db push --linked --yes
```

This creates `pro_entitlements`, `global_daily_spend`, and their RPCs
(`upsert_pro_entitlement`, `try_reserve_global_quota`, `release_global_quota`).
You can also apply `supabase/migrations/20260728000001_pro_entitlements_and_global_cap.sql`
by pasting it into the Supabase SQL editor if you'd rather not use the CLI.

## 2. Deploy both edge functions

```bash
# --no-verify-jwt is REQUIRED: RevenueCat sends Bearer <shared-secret>,
# not a Supabase JWT. Gateway JWT verify would 401 before our check runs.
supabase functions deploy revenuecat-webhook \
  --project-ref zyadgkgumdgussvkgtsr --no-verify-jwt
supabase functions deploy vision-score --project-ref zyadgkgumdgussvkgtsr
```

## 3. Generate and set the webhook shared secret

Generate a long random secret yourself (do NOT reuse any existing key):

```bash
openssl rand -hex 32
```

Set it as a Supabase secret — **never commit this value**:

```bash
supabase secrets set REVENUECAT_WEBHOOK_SECRET='paste_the_generated_value' \
  --project-ref zyadgkgumdgussvkgtsr
```

## 4. Configure the webhook in RevenueCat

In the [RevenueCat dashboard](https://app.revenuecat.com):

1. Go to **Project Settings → Integrations → Webhooks**
2. Click **Add webhook** (or edit the existing one)
3. **URL**: `https://zyadgkgumdgussvkgtsr.supabase.co/functions/v1/revenuecat-webhook`
4. **Authorization header value**: `Bearer <the same secret from step 3>`
5. Leave "Events to send" at the default (all events) — the function safely
   ignores event types it doesn't act on (see `decideEntitlementUpdate` in
   `supabase/functions/revenuecat-webhook/lib.ts`)
6. Save, then use RevenueCat's **"Send test event"** button and confirm the
   function returns `200` in Supabase's function logs

Until this webhook fires at least once for a subscriber, `vision-score`
fails safe to the free daily cap for that `app_user_id` (no entitlement
row yet). That is intentional — do **not** backfill Pro without verification.

## 5. Tune the global spend circuit-breaker (optional)

`vision-score` rejects ALL requests (any tier) with `429 GLOBAL_CAP_REACHED`
once total picks across every user exceed `GLOBAL_DAILY_PICK_CEILING` for the
current UTC day. This is a backstop against a runaway bug or coordinated
abuse — it is intentionally much higher than expected steady-state traffic.

Default (when unset): **20,000 picks/day**.

To tune it, estimate your current worst realistic daily volume (e.g. peak
concurrent users × picks/scout × scouts/day), multiply by a healthy safety
margin (3–5×), and set:

```bash
supabase secrets set GLOBAL_DAILY_PICK_CEILING='20000' \
  --project-ref zyadgkgumdgussvkgtsr
```

Watch function logs for `GLOBAL_CAP_REACHED` after launch — if it ever trips
during normal usage, raise the ceiling; if you never see it, it's doing its
job as a silent backstop.

For a proactive heads-up **before** that ceiling trips, see
`docs/USAGE_ALERTS_SETUP.md` — a scheduled `usage-alert` function that
posts a Slack/Discord message once daily spend crosses 70% (configurable)
of `GLOBAL_DAILY_PICK_CEILING`.

## Required secrets — summary

Set via `supabase secrets set`, never hardcoded, never committed:

| Secret | Used by | Purpose |
| --- | --- | --- |
| `GEMINI_API_KEY` | `vision-score` | Server-side Gemini calls (pre-existing) |
| `REVENUECAT_WEBHOOK_SECRET` | `revenuecat-webhook` | Verifies the webhook request is really from RevenueCat |
| `GLOBAL_DAILY_PICK_CEILING` | `vision-score` | Optional — global circuit-breaker ceiling (default 20,000) |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are already provided
automatically inside every Supabase edge function runtime — no manual setup
needed for those.

## How the tiers actually work now

- **Free / trial**: `FREE_DAILY_CAP` = 400 picks/device/day (unchanged).
- **Verified Pro**: `PRO_DAILY_CAP` = 5000 picks/device/day. This is a
  circuit-breaker, not a real limit — at 20 picks/scout that's ~250
  scouts/day, which product copy can honestly call "unlimited."
- **Global**: `GLOBAL_DAILY_PICK_CEILING` (default 20,000) across every
  user/tier combined, independent of the per-device caps above.
- A caller only gets the Pro ceiling when `pro_entitlements.is_pro = true`
  AND `expires_at` (if set) is in the future AND the lookup itself
  succeeded. Any ambiguity resolves to the free cap.

## Residual risk / limitations

- **No revocation for a stolen/shared `app_user_id`.** If someone obtains a
  legitimate Pro subscriber's RevenueCat `app_user_id` (e.g. logged via a
  compromised device), they inherit that account's high cap until the real
  subscription lapses. `PRO_DAILY_CAP` bounds the blast radius per account;
  the global ceiling bounds it fleet-wide.
- **Webhook delivery isn't instantaneous.** There's a small window between a
  purchase/cancellation and the entitlement cache updating — RevenueCat
  retries on non-2xx, but a dropped webhook (rare) means a Pro user briefly
  sees the free cap, or a cancelled user briefly keeps Pro until the next
  successful webhook or a manual backfill query against RevenueCat's REST API.
- **CORS is intentionally left permissive (`*`)** — see the comment block
  above `corsHeaders` in `supabase/functions/vision-score/index.ts` for why
  this doesn't reduce security for a native-mobile-only API.
- **IP soft rate-limit is in-memory per instance**, so it resets on cold
  start and doesn't coordinate across concurrent function instances. It's a
  coarse abuse backstop, not the primary control (the per-device and global
  reservations, which are DB-backed, are).
