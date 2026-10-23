-- IMPORTANT: Run after database.sql. Restrict real-world GPS and exact job addresses.
-- Technicians must not query other worker coordinates or identities before assignment.
drop policy if exists "tech view" on public.kw_tech;
create policy "tech view limited" on public.kw_tech for select to authenticated using(
 id=auth.uid() or public.kw_role()='admin' or exists(
 select 1 from public.kw_jobs j where j.technician_id=kw_tech.id and j.customer_id=auth.uid() and j.status in ('accepted','arrived','working')
 )
);
-- Do not enable public discovery of full-address searching jobs in production.
-- Current connected mode is development-only. Use a secure server-side matching feed
-- exposing area-level position instead of full job records for true dispatch.
