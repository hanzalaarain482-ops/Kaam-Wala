-- BulaoJi service marketplace • run on a fresh Supabase project
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 email text,
 phone text,
 role text not null default 'customer' check(role in ('customer','technician','admin')),
 city text not null default 'Karachi',
 created_at timestamptz not null default now()
);
create table if not exists public.services (
 id uuid primary key default gen_random_uuid(),
 name text unique not null,
 icon text not null default '🛠️',
 active boolean not null default true
);
create table if not exists public.technician_profiles (
 user_id uuid primary key references public.profiles(id) on delete cascade,
 services text[] not null default '{}',
 bio text default '',
 city text not null default 'Karachi',
 experience_years integer not null default 0 check(experience_years>=0),
 approval_status text not null default 'pending' check(approval_status in ('pending','approved','rejected','suspended')),
 online boolean not null default false,
 updated_at timestamptz not null default now()
);
create table if not exists public.bookings (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references public.profiles(id),
 technician_id uuid references public.profiles(id),
 service_name text not null,
 address text not null,
 city text not null,
 latitude double precision,
 longitude double precision,
 description text not null,
 offered_price numeric(12,2) not null check (offered_price>0),
 agreed_price numeric(12,2),
 status text not null default 'open' check(status in ('open','accepted','in_progress','completed','cancelled')),
 cancel_reason text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.offers (
 id uuid primary key default gen_random_uuid(),
 booking_id uuid not null references public.bookings(id) on delete cascade,
 technician_id uuid not null references public.profiles(id),
 price numeric(12,2) not null check(price>0),
 created_at timestamptz not null default now(),
 unique(booking_id, technician_id)
);
create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(),
 booking_id uuid not null references public.bookings(id) on delete cascade,
 sender_id uuid not null references public.profiles(id),
 body text not null check(char_length(body) between 1 and 3000),
 created_at timestamptz not null default now()
);
create table if not exists public.reviews (
 id uuid primary key default gen_random_uuid(),
 booking_id uuid not null unique references public.bookings(id) on delete cascade,
 customer_id uuid not null references public.profiles(id),
 technician_id uuid not null references public.profiles(id),
 rating integer not null check(rating between 1 and 5),
 comment text not null default '',
 created_at timestamptz not null default now()
);
create table if not exists public.complaints (
 id uuid primary key default gen_random_uuid(),
 booking_id uuid references public.bookings(id),
 author_id uuid not null references public.profiles(id),
 details text not null check(char_length(details)>5),
 state text not null default 'open',
 created_at timestamptz not null default now()
);
create index if not exists bookings_status_city on public.bookings(status,city);
create index if not exists booking_customer on public.bookings(customer_id);
create index if not exists booking_technician on public.bookings(technician_id);
create index if not exists offers_booking on public.offers(booking_id);
create index if not exists message_booking on public.messages(booking_id,created_at);
create or replace function public.my_role() returns text language sql stable security definer set search_path=public as $$
 select role from public.profiles where id=auth.uid()
$$;
create or replace function public.on_signup() returns trigger language plpgsql security definer set search_path=public as $$
declare urole text;
begin
 urole:=case when new.raw_user_meta_data->>'role'='technician' then 'technician' else 'customer' end;
 insert into public.profiles(id,email,full_name,phone,role)
 values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name',''),coalesce(new.raw_user_meta_data->>'phone',''),urole);
 if urole='technician' then insert into public.technician_profiles(user_id) values(new.id); end if;
 return new;
end $$;
drop trigger if exists trg_signup on auth.users;
create trigger trg_signup after insert on auth.users for each row execute function public.on_signup();
alter table public.profiles enable row level security;
alter table public.services enable row level security;
alter table public.technician_profiles enable row level security;
alter table public.bookings enable row level security;
alter table public.offers enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;
alter table public.complaints enable row level security;
create policy "Profiles visible to signed in users" on public.profiles for select to authenticated using(true);
create policy "Update own profile safe fields" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid() and role=public.my_role());
create policy "Read services" on public.services for select using(active or public.my_role()='admin');
create policy "Admin manages services" on public.services for all to authenticated using(public.my_role()='admin') with check(public.my_role()='admin');
create policy "Read technician profiles" on public.technician_profiles for select to authenticated using(true);
create policy "Technician edits own profile" on public.technician_profiles for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid() and approval_status in ('pending','approved','rejected','suspended'));
create policy "Admin technician edits" on public.technician_profiles for update to authenticated using(public.my_role()='admin') with check(public.my_role()='admin');
create policy "View eligible bookings" on public.bookings for select to authenticated using(
 public.my_role()='admin' or customer_id=auth.uid() or technician_id=auth.uid()
 or (status='open' and public.my_role()='technician' and exists
 (select 1 from public.technician_profiles t where t.user_id=auth.uid() and t.approval_status='approved' and t.city=bookings.city and bookings.service_name=any(t.services)))
);
create policy "Customer creates own jobs" on public.bookings for insert to authenticated with check(customer_id=auth.uid() and technician_id is null and agreed_price is null and status='open');
create policy "View booking offers" on public.offers for select to authenticated using(
 technician_id=auth.uid() or public.my_role()='admin' or exists(select 1 from public.bookings b where b.id=booking_id and b.customer_id=auth.uid())
);
create policy "Technician submits offers" on public.offers for insert to authenticated with check(
 technician_id=auth.uid() and public.my_role()='technician' and exists(
 select 1 from public.technician_profiles t join public.bookings b on b.city=t.city
 where t.user_id=auth.uid() and t.approval_status='approved' and t.online and b.id=booking_id and b.status='open' and b.service_name=any(t.services))
);
create policy "Technician adjusts own offers" on public.offers for update to authenticated using(technician_id=auth.uid()) with check(technician_id=auth.uid());
create policy "Read booking conversation" on public.messages for select to authenticated using(
 public.my_role()='admin' or exists(select 1 from public.bookings b where b.id=booking_id and (b.customer_id=auth.uid() or b.technician_id=auth.uid()))
);
create policy "Write booking conversation" on public.messages for insert to authenticated with check(
 sender_id=auth.uid() and exists(select 1 from public.bookings b where b.id=booking_id and b.status in ('accepted','in_progress') and (b.customer_id=auth.uid() or b.technician_id=auth.uid()))
);
create policy "Read reviews" on public.reviews for select to authenticated using(true);
create policy "Customers can rate completed jobs" on public.reviews for insert to authenticated with check(
 customer_id=auth.uid() and exists(select 1 from public.bookings b where b.id=booking_id and b.status='completed' and b.customer_id=auth.uid() and b.technician_id=reviews.technician_id)
);
create policy "View own complaints or admin" on public.complaints for select to authenticated using(author_id=auth.uid() or public.my_role()='admin');
create policy "Submit complaint" on public.complaints for insert to authenticated with check(author_id=auth.uid());
grant usage on schema public to authenticated,anon;
grant select on public.profiles,public.technician_profiles,public.bookings,public.offers,public.messages,public.reviews,public.services,public.complaints to authenticated;
grant insert on public.bookings,public.offers,public.messages,public.reviews,public.complaints to authenticated;
grant update(full_name,phone,city) on public.profiles to authenticated;
grant update(services,bio,city,experience_years,online) on public.technician_profiles to authenticated;
grant update(price) on public.offers to authenticated;
grant insert,update,delete on public.services to authenticated;
grant update(approval_status) on public.technician_profiles to authenticated;
-- sensitive state transitions are only permitted through controlled RPCs.
create or replace function public.accept_offer(p_offer uuid) returns void language plpgsql security definer set search_path=public as $$
declare o public.offers; b public.bookings;
begin
 select * into o from public.offers where id=p_offer; if not found then raise exception 'Offer missing'; end if;
 select * into b from public.bookings where id=o.booking_id for update;
 if b.customer_id<>auth.uid() or b.status<>'open' then raise exception 'Not allowed or already booked'; end if;
 update public.bookings set technician_id=o.technician_id,agreed_price=o.price,status='accepted',updated_at=now() where id=b.id;
end $$;
create or replace function public.transition_job(p_booking uuid,p_status text,p_reason text default null) returns void language plpgsql security definer set search_path=public as $$
declare b public.bookings;
begin
 select * into b from public.bookings where id=p_booking for update;
 if not found then raise exception 'Booking not found'; end if;
 if p_status='cancelled' and b.status in ('open','accepted','in_progress') and auth.uid() in (b.customer_id,b.technician_id) then
 update public.bookings set status='cancelled',cancel_reason=left(coalesce(p_reason,'Cancelled by user'),300),updated_at=now() where id=b.id;
 elsif auth.uid()=b.technician_id and ((b.status='accepted' and p_status='in_progress') or (b.status='in_progress' and p_status='completed')) then
 update public.bookings set status=p_status,updated_at=now() where id=b.id;
 else raise exception 'Invalid status transition'; end if;
end $$;
revoke all on function public.accept_offer(uuid) from public,anon;
revoke all on function public.transition_job(uuid,text,text) from public,anon;
grant execute on function public.accept_offer(uuid) to authenticated;
grant execute on function public.transition_job(uuid,text,text) to authenticated;
insert into public.services(name,icon) values
('Tyre Puncture','🚗'),('Car Mechanic','🔧'),('Bike Mechanic','🏍️'),
('Electrician','⚡'),('Plumber','🚰'),('Painter','🎨'),
('Carpenter','🪚'),('AC Technician','❄️'),('Home Cleaning','🧹'),
('Locksmith','🔐'),('Appliance Repair','🧺'),('Towing','🚚')
on conflict(name) do nothing;
-- Create the first admin manually after registering a customer (SQL Editor only):
-- update public.profiles set role='admin' where email='you@example.com';
