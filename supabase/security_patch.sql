-- Run AFTER supabase/schema.sql. Fix technician approval write privileges.
revoke update(approval_status) on public.technician_profiles from authenticated;
create or replace function public.admin_set_technician_status(p_technician uuid,p_status text)
returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or public.my_role()<>'admin' then raise exception 'Admin access required'; end if;
 if p_status not in ('approved','rejected','suspended','pending') then raise exception 'Invalid approval status'; end if;
 update public.technician_profiles set approval_status=p_status, online=case when p_status='approved' then online else false end,updated_at=now() where user_id=p_technician;
 if not found then raise exception 'Technician not found'; end if;
end $$;
revoke all on function public.admin_set_technician_status(uuid,text) from public,anon;
grant execute on function public.admin_set_technician_status(uuid,text) to authenticated;
-- Only allow technician owners to update fields intended for self service.
-- Prevent changing customer/technician/admin role through direct profile updates.
revoke update on public.profiles from authenticated;
grant update(full_name,phone,city) on public.profiles to authenticated;
-- No arbitrary booking status updates or price changes outside secure RPCs.
revoke update on public.bookings from authenticated;
