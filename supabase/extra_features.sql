-- Additional BulaoJi features. Run after schema.sql and security_patch.sql.
create table if not exists public.saved_addresses (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 label text not null, address text not null, city text not null,
 latitude double precision,longitude double precision,
 created_at timestamptz default now()
);
create table if not exists public.favorites (
 customer_id uuid not null references public.profiles(id) on delete cascade,
 technician_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz default now(),primary key(customer_id,technician_id)
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null references public.profiles(id) on delete cascade,
 title text not null, body text not null, read_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.booking_events (
 id uuid primary key default gen_random_uuid(),
 booking_id uuid not null references public.bookings(id) on delete cascade,
 actor_id uuid references public.profiles(id), event text not null,
 created_at timestamptz default now()
);
create table if not exists public.platform_settings (
 key text primary key, value text not null,updated_at timestamptz default now()
);
insert into public.platform_settings(key,value) values ('commission_percent','10'),('support_email','support@example.com') on conflict do nothing;
alter table public.saved_addresses enable row level security;
alter table public.favorites enable row level security;
alter table public.notifications enable row level security;
alter table public.booking_events enable row level security;
alter table public.platform_settings enable row level security;
create policy "Own address records" on public.saved_addresses for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "Own favorites" on public.favorites for all to authenticated using(customer_id=auth.uid()) with check(customer_id=auth.uid() and public.my_role()='customer');
create policy "My notifications" on public.notifications for select to authenticated using(recipient_id=auth.uid() or public.my_role()='admin');
create policy "Mark notifications read" on public.notifications for update to authenticated using(recipient_id=auth.uid()) with check(recipient_id=auth.uid());
create policy "Booking events for participants" on public.booking_events for select to authenticated using(
 public.my_role()='admin' or exists(select 1 from public.bookings b where b.id=booking_id and (b.customer_id=auth.uid() or b.technician_id=auth.uid()))
);
create policy "Admin settings read" on public.platform_settings for select to authenticated using(public.my_role()='admin');
create policy "Admin settings write" on public.platform_settings for all to authenticated using(public.my_role()='admin') with check(public.my_role()='admin');
grant select,insert,update,delete on public.saved_addresses, public.favorites to authenticated;
grant select,update(read_at) on public.notifications to authenticated;
grant select on public.booking_events to authenticated;
grant select,insert,update,delete on public.platform_settings to authenticated;
-- Registration and booking notifications use server side trusted DB triggers.
create or replace function public.event_booking() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if tg_op='INSERT' then
  insert into public.booking_events(booking_id,actor_id,event) values(new.id,new.customer_id,'Booking requested');
 elsif new.status is distinct from old.status then
  insert into public.booking_events(booking_id,actor_id,event) values(new.id,auth.uid(),'Status: '||new.status);
  if new.technician_id is not null then
   insert into public.notifications(recipient_id,title,body) values(new.technician_id,'Booking update','Job '||left(new.id::text,8)||' is '||new.status);
  end if;
  insert into public.notifications(recipient_id,title,body) values(new.customer_id,'Booking update','Your '||new.service_name||' job is '||new.status);
 end if;
 return new;
end $$;
drop trigger if exists trg_booking_events on public.bookings;
create trigger trg_booking_events after insert or update of status on public.bookings for each row execute function public.event_booking();
create or replace function public.notify_new_offer() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.notifications(recipient_id,title,body)
 select customer_id,'New Technician Offer','A technician offered Rs. '||new.price::text||' for '||service_name from public.bookings where id=new.booking_id;
 return new;
end $$;
drop trigger if exists trg_new_offer on public.offers;
create trigger trg_new_offer after insert on public.offers for each row execute function public.notify_new_offer();
-- Improve profile privacy: customers need limited technician name / rating view, not everyone's email/phone.
-- Frontend currently relies on profile selection for admin; do not expose all user data.
drop policy if exists "Profiles visible to signed in users" on public.profiles;
create policy "Users read own or booked partners profiles" on public.profiles for select to authenticated using(
 id=auth.uid() or public.my_role()='admin' or exists(
 select 1 from public.bookings b where (b.customer_id=auth.uid() and b.technician_id=profiles.id) or (b.technician_id=auth.uid() and b.customer_id=profiles.id)
 )
);
-- Explicit rating and complaint visibility restrictions.
drop policy if exists "Read reviews" on public.reviews;
create policy "Read reviews" on public.reviews for select to authenticated using(true);
create policy "Complaint admin update" on public.complaints for update to authenticated using(public.my_role()='admin') with check(public.my_role()='admin');
grant update(state) on public.complaints to authenticated;
-- Only admin can insert/edit services (grant alone doesn't bypass RLS).
-- Supporting SQL to enable PostgREST realtime publications for messages, offers, bookings and notifications.
do $$ begin
 alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.offers;
exception when duplicate_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.bookings;
exception when duplicate_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;
