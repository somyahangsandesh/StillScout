-- Atomic multi-unit reserve + release for vision-score proxy.

drop function if exists public.try_reserve_vision_quota(text, integer, integer);
drop function if exists public.release_vision_quota(text, integer);

create or replace function public.try_reserve_vision_quota(
  p_device_id text,
  p_count     integer,
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
  v_count integer;
begin
  v_count := greatest(coalesce(p_count, 0), 0);
  if v_count = 0 then
    return true;
  end if;

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

    if v_current + v_count > p_cap then
      perform pg_advisory_unlock(v_lock_key);
      return false;
    end if;

    insert into public.vision_usage (device_id, date, count)
    values (p_device_id, current_date, v_count)
    on conflict (device_id, date)
    do update set count = vision_usage.count + v_count;

    perform pg_advisory_unlock(v_lock_key);
    return true;

  exception when others then
    perform pg_advisory_unlock(v_lock_key);
    raise;
  end;
end;
$$;

create or replace function public.release_vision_quota(
  p_device_id text,
  p_count     integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lock_key bigint;
  v_count integer;
begin
  v_count := greatest(coalesce(p_count, 0), 0);
  if v_count = 0 then
    return;
  end if;

  v_lock_key := abs(hashtext(p_device_id)::bigint);
  perform pg_advisory_lock(v_lock_key);

  begin
    update public.vision_usage
    set count = greatest(count - v_count, 0)
    where device_id = p_device_id
      and date = current_date;

    perform pg_advisory_unlock(v_lock_key);

  exception when others then
    perform pg_advisory_unlock(v_lock_key);
    raise;
  end;
end;
$$;

grant execute on function public.try_reserve_vision_quota(text, integer, integer)
  to service_role;
grant execute on function public.release_vision_quota(text, integer)
  to service_role;
