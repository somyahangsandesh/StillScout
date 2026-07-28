-- Server-verified Pro entitlement cache + global daily spend circuit-breaker.
-- Apply via `supabase db push` or MCP apply_migration.

-- ── pro_entitlements ─────────────────────────────────────────────────────
-- Populated exclusively by the `revenuecat-webhook` edge function (service
-- role). `vision-score` reads this table to decide whether a caller is a
-- verified Pro subscriber — it never trusts a client-supplied "is_pro" flag.
create table if not exists public.pro_entitlements (
  app_user_id text        not null primary key,
  is_pro      boolean     not null default false,
  expires_at  timestamptz,
  platform    text,
  updated_at  timestamptz not null default now()
);

alter table public.pro_entitlements enable row level security;

-- No policies are defined on purpose: only the service role (used by the
-- webhook + vision-score edge functions) can read/write this table. Clients
-- authenticate with the anon key and have zero direct access.

create or replace function public.upsert_pro_entitlement(
  p_app_user_id text,
  p_is_pro      boolean,
  p_expires_at  timestamptz,
  p_platform    text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.pro_entitlements (app_user_id, is_pro, expires_at, platform, updated_at)
  values (p_app_user_id, p_is_pro, p_expires_at, p_platform, now())
  on conflict (app_user_id)
  do update set
    is_pro     = excluded.is_pro,
    expires_at = excluded.expires_at,
    platform   = coalesce(excluded.platform, public.pro_entitlements.platform),
    updated_at = now();
end;
$$;

grant execute on function public.upsert_pro_entitlement(text, boolean, timestamptz, text)
  to service_role;

-- ── global_daily_spend ───────────────────────────────────────────────────
-- One row per UTC day. Incremented on every successful Gemini call across
-- ALL users/tiers. This is a pure circuit-breaker against a runaway bug or
-- mass abuse event, not a normal quota — per-device/per-Pro caps remain the
-- primary control.
create table if not exists public.global_daily_spend (
  date  date    not null primary key,
  count integer not null default 0
);

alter table public.global_daily_spend enable row level security;

drop function if exists public.try_reserve_global_quota(integer, integer);
drop function if exists public.release_global_quota(integer);

create or replace function public.try_reserve_global_quota(
  p_count integer,
  p_cap   integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current  integer;
  v_count    integer;
  v_lock_key bigint := hashtext('global_daily_spend')::bigint;
begin
  v_count := greatest(coalesce(p_count, 0), 0);
  if v_count = 0 then
    return true;
  end if;

  perform pg_advisory_lock(v_lock_key);

  begin
    select count into v_current
    from public.global_daily_spend
    where date = current_date;

    if v_current is null then
      v_current := 0;
    end if;

    if v_current + v_count > p_cap then
      perform pg_advisory_unlock(v_lock_key);
      return false;
    end if;

    insert into public.global_daily_spend (date, count)
    values (current_date, v_count)
    on conflict (date)
    do update set count = global_daily_spend.count + v_count;

    perform pg_advisory_unlock(v_lock_key);
    return true;

  exception when others then
    perform pg_advisory_unlock(v_lock_key);
    raise;
  end;
end;
$$;

create or replace function public.release_global_quota(
  p_count integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count    integer;
  v_lock_key bigint := hashtext('global_daily_spend')::bigint;
begin
  v_count := greatest(coalesce(p_count, 0), 0);
  if v_count = 0 then
    return;
  end if;

  perform pg_advisory_lock(v_lock_key);

  begin
    update public.global_daily_spend
    set count = greatest(count - v_count, 0)
    where date = current_date;

    perform pg_advisory_unlock(v_lock_key);

  exception when others then
    perform pg_advisory_unlock(v_lock_key);
    raise;
  end;
end;
$$;

grant execute on function public.try_reserve_global_quota(integer, integer)
  to service_role;
grant execute on function public.release_global_quota(integer)
  to service_role;
