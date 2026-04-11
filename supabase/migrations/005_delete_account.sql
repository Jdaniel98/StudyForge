-- Allow users to delete their own account (App Store requirement 5.1.1)
-- CASCADE on profiles and remote_sessions handles cleanup
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
    -- Delete from auth.users — cascades to profiles and remote_sessions
    delete from auth.users where id = auth.uid();
end;
$$;
