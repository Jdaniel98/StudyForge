-- Create a new study group (caller becomes admin)
create or replace function public.create_group(group_name text)
returns json
language plpgsql
security definer set search_path = ''
as $$
declare
    new_group public.study_groups;
begin
    insert into public.study_groups (name, created_by)
    values (group_name, auth.uid())
    returning * into new_group;

    insert into public.group_members (group_id, user_id, role)
    values (new_group.id, auth.uid(), 'admin');

    return json_build_object(
        'id', new_group.id,
        'name', new_group.name,
        'invite_code', new_group.invite_code,
        'created_at', new_group.created_at
    );
end;
$$;

-- Join a group via invite code
create or replace function public.join_group(code text)
returns json
language plpgsql
security definer set search_path = ''
as $$
declare
    target_group public.study_groups;
    member_count int;
begin
    select * into target_group
    from public.study_groups
    where invite_code = code;

    if target_group.id is null then
        raise exception 'Invalid invite code';
    end if;

    -- Check if already a member
    if exists (
        select 1 from public.group_members
        where group_id = target_group.id and user_id = auth.uid()
    ) then
        raise exception 'Already a member of this group';
    end if;

    -- Check member cap
    select count(*) into member_count
    from public.group_members
    where group_id = target_group.id;

    if member_count >= target_group.max_members then
        raise exception 'Group is full';
    end if;

    insert into public.group_members (group_id, user_id, role)
    values (target_group.id, auth.uid(), 'member');

    return json_build_object(
        'group_id', target_group.id,
        'group_name', target_group.name
    );
end;
$$;

-- Leave a group
create or replace function public.leave_group(target_group_id uuid)
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
    delete from public.group_members
    where group_id = target_group_id and user_id = auth.uid();

    -- If no members left, delete the group
    if not exists (
        select 1 from public.group_members where group_id = target_group_id
    ) then
        delete from public.study_groups where id = target_group_id;
    end if;
end;
$$;

-- Get group leaderboard (aggregated weekly stats per member — privacy-safe)
create or replace function public.get_group_leaderboard(target_group_id uuid)
returns json
language plpgsql
security definer set search_path = ''
as $$
declare
    result json;
    week_start timestamptz;
begin
    -- Verify caller is a member
    if not exists (
        select 1 from public.group_members
        where group_id = target_group_id and user_id = auth.uid()
    ) then
        raise exception 'Access denied';
    end if;

    week_start := date_trunc('week', now());

    select json_agg(row_data order by total_seconds desc) into result
    from (
        select json_build_object(
            'user_id', gm.user_id,
            'display_name', coalesce(p.display_name, 'Anonymous'),
            'avatar_url', p.avatar_url,
            'total_seconds', coalesce(s.total_seconds, 0),
            'session_count', coalesce(s.session_count, 0),
            'categories', coalesce(s.categories, '[]'::json),
            'role', gm.role
        ) as row_data,
        coalesce(s.total_seconds, 0) as total_seconds
        from public.group_members gm
        join public.profiles p on p.id = gm.user_id
        left join lateral (
            select
                sum(rs.duration_seconds) as total_seconds,
                count(*) as session_count,
                coalesce(
                    json_agg(distinct jsonb_build_object(
                        'category', rs.subject_category,
                        'total_seconds', cat_totals.cat_total
                    )), '[]'::json
                ) as categories
            from public.remote_sessions rs
            left join lateral (
                select rs2.subject_category, sum(rs2.duration_seconds) as cat_total
                from public.remote_sessions rs2
                where rs2.user_id = gm.user_id
                  and rs2.started_at >= week_start
                  and rs2.excluded_from_leaderboard = false
                group by rs2.subject_category
            ) cat_totals on true
            where rs.user_id = gm.user_id
              and rs.started_at >= week_start
              and rs.excluded_from_leaderboard = false
        ) s on true
        where gm.group_id = target_group_id
    ) ranked;

    return coalesce(result, '[]'::json);
end;
$$;

-- Get my groups with member counts
create or replace function public.get_my_groups()
returns json
language plpgsql
security definer set search_path = ''
as $$
declare
    result json;
begin
    select json_agg(row_data) into result
    from (
        select json_build_object(
            'id', g.id,
            'name', g.name,
            'invite_code', g.invite_code,
            'created_by', g.created_by,
            'max_members', g.max_members,
            'created_at', g.created_at,
            'member_count', (
                select count(*) from public.group_members
                where group_id = g.id
            ),
            'my_role', gm.role
        ) as row_data
        from public.group_members gm
        join public.study_groups g on g.id = gm.group_id
        where gm.user_id = auth.uid()
        order by gm.joined_at desc
    ) groups_data;

    return coalesce(result, '[]'::json);
end;
$$;

-- Get global leaderboard (only public profiles, weekly stats)
create or replace function public.get_global_leaderboard(result_limit int default 50)
returns json
language plpgsql
security definer set search_path = ''
as $$
declare
    result json;
    week_start timestamptz;
begin
    week_start := date_trunc('week', now());

    select json_agg(row_data order by total_seconds desc) into result
    from (
        select json_build_object(
            'user_id', p.id,
            'display_name', coalesce(p.display_name, 'Anonymous'),
            'avatar_url', p.avatar_url,
            'total_seconds', coalesce(s.total_seconds, 0),
            'session_count', coalesce(s.session_count, 0),
            'is_me', p.id = auth.uid()
        ) as row_data,
        coalesce(s.total_seconds, 0) as total_seconds
        from public.profiles p
        left join lateral (
            select
                sum(rs.duration_seconds) as total_seconds,
                count(*) as session_count
            from public.remote_sessions rs
            where rs.user_id = p.id
              and rs.started_at >= week_start
              and rs.excluded_from_leaderboard = false
        ) s on true
        where p.is_public = true
          and coalesce(s.total_seconds, 0) > 0
        limit result_limit
    ) ranked;

    return coalesce(result, '[]'::json);
end;
$$;
