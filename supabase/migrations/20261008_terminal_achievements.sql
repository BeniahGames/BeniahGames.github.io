-- beniah.games terminal: account-synced achievements.
-- Applied to project nqhejsnfwfcilktnyqbi on 2026-10-08.

-- ---------------------------------------------------------------- catalog
-- The server's own list of what counts as an achievement and what it is
-- worth. Clients may read it; only the service role may change it.
create table if not exists public.terminal_achievements (
  code        text primary key,
  name        text not null,
  hint        text,
  xp          integer not null default 10 check (xp >= 0),
  sort_order  integer not null default 0
);

alter table public.terminal_achievements enable row level security;

create policy "terminal achievements are public"
  on public.terminal_achievements for select to anon, authenticated using (true);

insert into public.terminal_achievements (code, name, hint, xp, sort_order) values
  ('boot',     'FIRST CONTACT',   'switch the terminal on',                  5,  1),
  ('rtfm',     'RTFM',            'ask for HELP',                            5,  2),
  ('explorer', 'EXPLORER',        'visit every screen',                      15, 3),
  ('rack',     'RACK COMPLETE',   'open every cartridge dossier',            15, 4),
  ('whoami',   'IDENTITY CRISIS', 'a classic question',                      10, 5),
  ('sudo',     'NICE TRY',        'ask for permissions you do not have',     10, 6),
  ('coffee',   'FUEL',            'what every developer actually runs on',   10, 7),
  ('konami',   'THE CODE',        'up, up, down, down ...',                  25, 8),
  ('digger',   'SPELUNKER',       'find three commands HELP never mentions', 20, 9),
  ('all',      'COMPLETIONIST',   'unlock everything else',                  50, 10)
on conflict (code) do update
  set name = excluded.name, hint = excluded.hint,
      xp = excluded.xp, sort_order = excluded.sort_order;

-- ------------------------------------------------------------------- sync
-- Merges the browser's achievement list into the account's and awards XP for
-- whatever is genuinely new. Codes are validated against the catalog, so a
-- tampered client cannot invent achievements or grant itself XP, and the
-- merge is a union: syncing a fresh browser never erases earned progress.
create or replace function public.sync_terminal_achievements(p_codes text[])
returns table (
  codes       text[],
  newly_added text[],
  total_xp    integer,
  user_level  integer,
  role_code   text,
  role_name   text
)
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
  uid        uuid := auth.uid();
  v_existing text[];
  v_valid    text[];
  v_added    text[];
  v_merged   text[];
  v_gain     integer := 0;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  insert into public.user_progress (user_id) values (uid)
    on conflict (user_id) do nothing;

  select coalesce(
           (select array_agg(v) from jsonb_array_elements_text(p.achievements) as e(v)),
           array[]::text[])
    into v_existing
    from public.profiles p
   where p.id = uid;

  if not found then
    raise exception 'profile_missing' using errcode = 'P0002';
  end if;

  v_existing := coalesce(v_existing, array[]::text[]);

  select coalesce(array_agg(t.code order by t.sort_order), array[]::text[])
    into v_valid
    from public.terminal_achievements t
   where t.code = any (coalesce(p_codes, array[]::text[]));

  select coalesce(array_agg(c order by c), array[]::text[])
    into v_added
    from unnest(v_valid) as u(c)
   where not (c = any (v_existing));

  v_merged := v_existing;

  if array_length(v_added, 1) is not null then
    v_merged := v_existing || v_added;

    select coalesce(sum(t.xp), 0) into v_gain
      from public.terminal_achievements t
     where t.code = any (v_added);

    update public.profiles set achievements = to_jsonb(v_merged) where id = uid;
  end if;

  if v_gain > 0 then
    select a.new_xp, a.new_level, a.current_role_code, a.current_role_name
      into total_xp, user_level, role_code, role_name
      from public.award_xp(v_gain) a;
  else
    select pr.xp, pr.level into total_xp, user_level
      from public.user_progress pr where pr.user_id = uid;
    select rt.code, rt.name into role_code, role_name
      from public.role_tiers rt
      join public.user_current_role cr on cr.role_id = rt.id
     where cr.user_id = uid;
  end if;

  codes       := v_merged;
  newly_added := v_added;
  return next;
end;
$fn$;

revoke all on function public.sync_terminal_achievements(text[]) from public, anon;
grant execute on function public.sync_terminal_achievements(text[]) to authenticated;
