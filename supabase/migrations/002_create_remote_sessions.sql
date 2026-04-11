-- Remote sessions — synced from client Core Data
-- Subject is denormalized (string, not FK) to keep the schema simple
create table if not exists public.remote_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    local_id uuid not null,
    subject_name text not null,
    subject_category text not null default 'Custom',
    started_at timestamptz not null,
    ended_at timestamptz not null,
    duration_seconds int not null,
    planned_duration_seconds int not null,
    completed_fully boolean not null default true,
    pomodoro_count smallint not null default 1,
    excluded_from_leaderboard boolean not null default false,
    created_at timestamptz not null default now(),

    -- Prevent duplicate syncs of the same local session
    unique (user_id, local_id)
);

-- Index for common queries
create index if not exists idx_remote_sessions_user_started
    on public.remote_sessions (user_id, started_at desc);

-- Update lifetime stats on profile when a session is inserted
create or replace function public.update_profile_stats()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    update public.profiles
    set lifetime_study_seconds = lifetime_study_seconds + new.duration_seconds,
        lifetime_session_count = lifetime_session_count + 1,
        updated_at = now()
    where id = new.user_id;
    return new;
end;
$$;

create trigger on_session_inserted
    after insert on public.remote_sessions
    for each row execute function public.update_profile_stats();
