-- Study Groups
create table public.study_groups (
    id uuid primary key default gen_random_uuid(),
    name text not null check (char_length(name) between 1 and 50),
    invite_code text unique not null default substr(replace(gen_random_uuid()::text, '-', ''), 1, 8),
    created_by uuid not null references public.profiles(id) on delete cascade,
    max_members int not null default 20,
    created_at timestamptz not null default now()
);

-- Group Members (junction table)
create table public.group_members (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.study_groups(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    role text not null default 'member' check (role in ('admin', 'member')),
    joined_at timestamptz not null default now(),
    unique (group_id, user_id)
);

-- Indexes
create index idx_group_members_group on public.group_members(group_id);
create index idx_group_members_user on public.group_members(user_id);
create index idx_groups_invite_code on public.study_groups(invite_code);

-- RLS
alter table public.study_groups enable row level security;
alter table public.group_members enable row level security;

-- Study Groups policies: members can read their groups
create policy "Members can read their groups"
    on public.study_groups for select
    using (
        id in (select group_id from public.group_members where user_id = auth.uid())
    );

-- Any authenticated user can create a group
create policy "Authenticated users can create groups"
    on public.study_groups for insert
    with check (auth.uid() = created_by);

-- Only group admin can update group
create policy "Admin can update group"
    on public.study_groups for update
    using (
        id in (
            select group_id from public.group_members
            where user_id = auth.uid() and role = 'admin'
        )
    );

-- Only group admin can delete group
create policy "Admin can delete group"
    on public.study_groups for delete
    using (
        id in (
            select group_id from public.group_members
            where user_id = auth.uid() and role = 'admin'
        )
    );

-- Group Members policies: members can read fellow members
create policy "Members can read group members"
    on public.group_members for select
    using (
        group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

-- Authenticated users can insert themselves (via RPC, but needed for the function)
create policy "Users can join groups"
    on public.group_members for insert
    with check (auth.uid() = user_id);

-- Users can remove themselves
create policy "Users can leave groups"
    on public.group_members for delete
    using (auth.uid() = user_id);
