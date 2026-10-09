-- Fixes to the account/signup path found while wiring achievement sync.
-- Applied to project nqhejsnfwfcilktnyqbi on 2026-10-08.

-- 1. is_username_available checked drawguess room names, not profile
--    usernames, so signup's uniqueness check was meaningless. (The site also
--    called it with the wrong argument name, which made PostgREST 404 every
--    request; that is fixed on the client side in index.html.)
create or replace function public.is_username_available(username_to_check text)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $fn$
begin
  if username_to_check is null or length(trim(username_to_check)) = 0 then
    return false;
  end if;

  return not exists (
    select 1 from public.profiles
     where lower(username) = lower(trim(username_to_check))
  );
end;
$fn$;

-- 2. Nothing actually enforced that uniqueness at the database level.
create unique index if not exists profiles_username_lower_key
  on public.profiles (lower(username)) where username is not null;

-- 3. profiles.display_name is UNIQUE and the signup trigger set it to the
--    email's local part, so a second account sharing that local part
--    (x@gmail.com then x@outlook.com) raised inside the trigger and aborted
--    the whole auth.users insert -- signup failed with a 500. Suffix instead.
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
  base      text;
  candidate text;
  n         integer := 0;
begin
  base := nullif(trim(split_part(coalesce(new.email, ''), '@', 1)), '');
  if base is null then
    base := 'player';
  end if;

  candidate := base;
  while n < 50 and exists (
    select 1 from public.profiles where display_name = candidate
  ) loop
    n := n + 1;
    candidate := base || n::text;
  end loop;

  if n >= 50 then
    candidate := base || '-' || substr(new.id::text, 1, 8);
  end if;

  insert into public.profiles (id, display_name)
    values (new.id, candidate)
    on conflict (id) do nothing;

  return new;
end;
$fn$;

-- 4. handle_new_user had no ON CONFLICT (a retried signup would abort) and a
--    mutable search_path on a SECURITY DEFINER function.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $fn$
begin
  insert into public.user_profiles (id, email, display_name)
  values (new.id, lower(new.email), new.raw_user_meta_data->>'display_name')
  on conflict (id) do nothing;
  return new;
end;
$fn$;
