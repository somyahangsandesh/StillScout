-- vision_usage — per-device daily cloud AI quota (StillScout vision-score proxy)
-- Copied from production schema; apply via `supabase db push` or MCP apply_migration.

create table if not exists public.vision_usage (
  device_id  text    not null,
  date       date    not null default current_date,
  count      integer not null default 0,
  primary key (device_id, date)
);

alter table public.vision_usage enable row level security;

drop function if exists public.try_consume_vision_quota(text, integer);

create or replace function public.try_consume_vision_quota(
  p_device_id text,
  p_cap       integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current integer;
  v_lock_key bigint;
begin
  v_lock_key := abs(hashtext(p_device_id)::bigint);
  perform pg_advisory_lock(v_lock_key);

  begin
    select count into v_current
    from public.vision_usage
    where device_id = p_device_id
      and date = current_date;

    if v_current is null then
      v_current := 0;
    end if;

    if v_current >= p_cap then
      perform pg_advisory_unlock(v_lock_key);
      return false;
    end if;

    insert into public.vision_usage (device_id, date, count)
    values (p_device_id, current_date, 1)
    on conflict (device_id, date)
    do update set count = vision_usage.count + 1;

    perform pg_advisory_unlock(v_lock_key);
    return true;

  exception when others then
    perform pg_advisory_unlock(v_lock_key);
    raise;
  end;
end;
$$;

grant execute on function public.try_consume_vision_quota(text, integer)
  to service_role;
