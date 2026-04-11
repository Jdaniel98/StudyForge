-- Weekly stats for a user (used by dashboard when synced)
create or replace function public.get_weekly_stats(target_user_id uuid)
returns json
language plpgsql
security definer set search_path = ''
as $$
declare
    result json;
    week_start timestamptz;
begin
    -- Only allow users to query their own stats
    if auth.uid() != target_user_id then
        raise exception 'Access denied';
    end if;

    week_start := date_trunc('week', now());

    select json_build_object(
        'total_seconds', coalesce(sum(duration_seconds), 0),
        'session_count', count(*),
        'categories', (
            select json_agg(json_build_object(
                'category', subject_category,
                'total_seconds', cat_total
            ))
            from (
                select subject_category, sum(duration_seconds) as cat_total
                from public.remote_sessions
                where user_id = target_user_id
                  and started_at >= week_start
                  and excluded_from_leaderboard = false
                group by subject_category
            ) cats
        )
    ) into result
    from public.remote_sessions
    where user_id = target_user_id
      and started_at >= week_start
      and excluded_from_leaderboard = false;

    return result;
end;
$$;

-- User profile with stats (for profile screen)
create or replace function public.get_my_profile()
returns json
language plpgsql
security definer set search_path = ''
as $$
declare
    result json;
begin
    select json_build_object(
        'id', p.id,
        'display_name', p.display_name,
        'avatar_url', p.avatar_url,
        'lifetime_study_seconds', p.lifetime_study_seconds,
        'lifetime_session_count', p.lifetime_session_count,
        'is_public', p.is_public,
        'created_at', p.created_at
    ) into result
    from public.profiles p
    where p.id = auth.uid();

    return result;
end;
$$;
