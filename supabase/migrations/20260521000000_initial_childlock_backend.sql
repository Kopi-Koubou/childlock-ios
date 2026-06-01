create schema if not exists childlock_private;

create extension if not exists pgcrypto;

create or replace function childlock_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.parent_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  apple_user_id text unique,
  email text,
  full_name text,
  revenuecat_app_user_id text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.child_profiles (
  id uuid primary key,
  parent_id uuid not null references auth.users(id) on delete cascade,
  age_band text not null check (age_band in ('young', 'middle', 'older')),
  avatar_name text not null,
  interval_minutes integer not null check (interval_minutes in (5, 10, 15, 20, 30)),
  difficulty_override text not null check (difficulty_override in ('auto', 'easy', 'medium', 'hard')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create table if not exists public.app_settings (
  parent_id uuid primary key references auth.users(id) on delete cascade,
  has_completed_onboarding boolean not null default false,
  voice_prompts_enabled boolean not null default true,
  daily_summary_notification boolean not null default true,
  challenge_alert_notification boolean not null default true,
  free_challenges_used_today integer not null default 0,
  free_challenges_reset_date text not null default '',
  active_profile_id uuid,
  updated_at timestamptz not null default now()
);

create table if not exists public.challenge_sessions (
  id uuid primary key,
  parent_id uuid not null references auth.users(id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  session_date date not null,
  screen_time_seconds integer not null default 0,
  challenges_presented integer not null default 0,
  challenges_completed integer not null default 0,
  accuracy numeric(5, 4) not null default 0,
  synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.challenge_results (
  id uuid primary key,
  parent_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references public.challenge_sessions(id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  type text not null check (type in ('math', 'pattern', 'memory', 'puzzle')),
  difficulty_level integer not null check (difficulty_level >= 1),
  presented_at timestamptz not null,
  completed_at timestamptz,
  attempts integer not null default 0 check (attempts >= 0),
  completed boolean not null default false,
  hint_used boolean not null default false,
  solve_time_seconds numeric(8, 3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.device_installs (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  platform text not null default 'ios',
  app_version text,
  build_number text,
  push_token text,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create table if not exists public.subscription_status (
  parent_id uuid primary key references auth.users(id) on delete cascade,
  revenuecat_app_user_id text not null unique,
  entitlement_identifier text,
  is_active boolean not null default false,
  period_type text,
  expires_at timestamptz,
  last_event_type text,
  last_event_at timestamptz,
  raw_payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists child_profiles_parent_id_idx on public.child_profiles(parent_id);
create index if not exists challenge_sessions_parent_date_idx on public.challenge_sessions(parent_id, session_date desc);
create index if not exists challenge_results_parent_presented_idx on public.challenge_results(parent_id, presented_at desc);
create index if not exists device_installs_parent_id_idx on public.device_installs(parent_id);

drop trigger if exists set_parent_profiles_updated_at on public.parent_profiles;
create trigger set_parent_profiles_updated_at
before update on public.parent_profiles
for each row execute function childlock_private.set_updated_at();

drop trigger if exists set_child_profiles_updated_at on public.child_profiles;
create trigger set_child_profiles_updated_at
before update on public.child_profiles
for each row execute function childlock_private.set_updated_at();

drop trigger if exists set_app_settings_updated_at on public.app_settings;
create trigger set_app_settings_updated_at
before update on public.app_settings
for each row execute function childlock_private.set_updated_at();

drop trigger if exists set_challenge_sessions_updated_at on public.challenge_sessions;
create trigger set_challenge_sessions_updated_at
before update on public.challenge_sessions
for each row execute function childlock_private.set_updated_at();

drop trigger if exists set_challenge_results_updated_at on public.challenge_results;
create trigger set_challenge_results_updated_at
before update on public.challenge_results
for each row execute function childlock_private.set_updated_at();

drop trigger if exists set_subscription_status_updated_at on public.subscription_status;
create trigger set_subscription_status_updated_at
before update on public.subscription_status
for each row execute function childlock_private.set_updated_at();

alter table public.parent_profiles enable row level security;
alter table public.child_profiles enable row level security;
alter table public.app_settings enable row level security;
alter table public.challenge_sessions enable row level security;
alter table public.challenge_results enable row level security;
alter table public.device_installs enable row level security;
alter table public.subscription_status enable row level security;

drop policy if exists "Parents can read their own profile" on public.parent_profiles;
create policy "Parents can read their own profile"
on public.parent_profiles for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "Parents can insert their own profile" on public.parent_profiles;
create policy "Parents can insert their own profile"
on public.parent_profiles for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists "Parents can update their own profile" on public.parent_profiles;
create policy "Parents can update their own profile"
on public.parent_profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "Parents can manage own child profiles" on public.child_profiles;
create policy "Parents can manage own child profiles"
on public.child_profiles for all
to authenticated
using ((select auth.uid()) = parent_id)
with check ((select auth.uid()) = parent_id);

drop policy if exists "Parents can manage own settings" on public.app_settings;
create policy "Parents can manage own settings"
on public.app_settings for all
to authenticated
using ((select auth.uid()) = parent_id)
with check ((select auth.uid()) = parent_id);

drop policy if exists "Parents can manage own sessions" on public.challenge_sessions;
create policy "Parents can manage own sessions"
on public.challenge_sessions for all
to authenticated
using ((select auth.uid()) = parent_id)
with check ((select auth.uid()) = parent_id);

drop policy if exists "Parents can manage own challenge results" on public.challenge_results;
create policy "Parents can manage own challenge results"
on public.challenge_results for all
to authenticated
using ((select auth.uid()) = parent_id)
with check ((select auth.uid()) = parent_id);

drop policy if exists "Parents can manage own device installs" on public.device_installs;
create policy "Parents can manage own device installs"
on public.device_installs for all
to authenticated
using ((select auth.uid()) = parent_id)
with check ((select auth.uid()) = parent_id);

drop policy if exists "Parents can read own subscription status" on public.subscription_status;
create policy "Parents can read own subscription status"
on public.subscription_status for select
to authenticated
using ((select auth.uid()) = parent_id);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on
  public.parent_profiles,
  public.child_profiles,
  public.app_settings,
  public.challenge_sessions,
  public.challenge_results,
  public.device_installs,
  public.subscription_status
to authenticated;
