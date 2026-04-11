-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.remote_sessions enable row level security;

-- Profiles: users can read their own + public profiles, update only their own
create policy "Users can read own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can read public profiles"
    on public.profiles for select
    using (is_public = true);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- Remote sessions: users can only read/write their own
create policy "Users can read own sessions"
    on public.remote_sessions for select
    using (auth.uid() = user_id);

create policy "Users can insert own sessions"
    on public.remote_sessions for insert
    with check (auth.uid() = user_id);

-- Sessions are append-only — no update or delete from client
-- (Admin can still delete via service role if needed)
