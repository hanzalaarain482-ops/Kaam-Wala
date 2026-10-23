-- KaamWala production-development database (fresh Supabase project)
create extension if not exists pgcrypto;
create table public.kw_profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null default '', phone text, role text not null default 'customer' check(role in ('customer','technician','admin')),
 city text default 'Karachi', created_at timestamptz default now());
create table public.kw_tech(
 id uuid primary key references public.kw_profiles(id) on delete cascade,
 service text not null default 'Electrician', approved boolean not null default false,
 online boolean not null default false, lat double precision, lng double precision,
 last_seen timestamptz, experience integer default 0, bio text default '');
create table public.kw_rates(
 id uuid primary key default gen_random_uuid(),
 city text not null, area text not null, service text not null,
 minimum integer not null check(minimum>0),
 unique(city,area,service));
create table public.kw_jobs(
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references public.kw_profiles(id),
 technician_id uuid references public.kw_profiles(id),
 service text not null, city text not null,area text not null,
 address text not null, lat double precision not null,lng double precision not null,
 minimum integer not null check(minimum>0),offer integer not null check(offer>0),
 status text not null default 'searching' check(status in('searching','accepted','arrived','working','completed','cancelled')),
 created_at timestamptz not null default now());
create table public.kw_bids(
 id uuid primary key default gen_random_uuid(),job_id uuid not null references public.kw_jobs(id) on delete cascade,
 technician_id uuid not null references public.kw_profiles(id),created_at timestamptz default now(),
 unique(job_id,technician_id));
create table public.kw_messages(
 id uuid primary key default gen_random_uuid(),job_id uuid not null references public.kw_jobs(id) on delete cascade,
 sender_id uuid not null references public.kw_profiles(id), body text not null check(length(body) between 1 and 1500),created_at timestamptz default now());
create table public.kw_reviews(
 id uuid primary key default gen_random_uuid(),job_id uuid unique not null references public.kw_jobs(id),
 customer_id uuid not null references public.kw_profiles(id), technician_id uuid not null references public.kw_profiles(id),
 stars integer not null check(stars between 1 and 5), comment text default '',created_at timestamptz default now());
create table public.kw_tickets(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.kw_profiles(id),
 details text not null, status text default 'open',created_at timestamptz default now());
create table public.kw_saved(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.kw_profiles(id) on delete cascade,
 label text not null,address text not null,city text not null,area text not null,
 lat double precision not null,lng double precision not null);
create or replace function public.kw_role() returns text language sql stable security definer set search_path=public as $$
 select role from public.kw_profiles where id=auth.uid()
$$;
create or replace function public.kw_signup() returns trigger language plpgsql security definer set search_path=public as $$
declare r text;
begin
 r:=case when new.raw_user_meta_data->>'role'='technician' then 'technician' else 'customer' end;
 insert into public.kw_profiles(id,name,role,phone) values(new.id,coalesce(new.raw_user_meta_data->>'name',''),r,new.raw_user_meta_data->>'phone');
 if r='technician' then insert into public.kw_tech(id) values(new.id);end if;
 return new;
end $$;
create trigger kw_on_signup after insert on auth.users for each row execute function public.kw_signup();
alter table public.kw_profiles enable row level security;
alter table public.kw_tech enable row level security;
alter table public.kw_rates enable row level security;
alter table public.kw_jobs enable row level security;
alter table public.kw_bids enable row level security;
alter table public.kw_messages enable row level security;
alter table public.kw_reviews enable row level security;
alter table public.kw_tickets enable row level security;
alter table public.kw_saved enable row level security;
create policy "own profiles admin" on public.kw_profiles for select to authenticated using(id=auth.uid() or public.kw_role()='admin' or exists(select 1 from public.kw_jobs j where (j.customer_id=auth.uid() and j.technician_id=kw_profiles.id) or (j.technician_id=auth.uid() and j.customer_id=kw_profiles.id)));
create policy "self profile edit" on public.kw_profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "tech view" on public.kw_tech for select to authenticated using(approved or id=auth.uid() or public.kw_role()='admin');
create policy "tech self location" on public.kw_tech for update to authenticated using(id=auth.uid() and public.kw_role()='technician') with check(id=auth.uid());
create policy "rates view" on public.kw_rates for select to authenticated using(true);
create policy "rates admin" on public.kw_rates for all to authenticated using(public.kw_role()='admin') with check(public.kw_role()='admin');
create policy "jobs authorized view" on public.kw_jobs for select to authenticated using(customer_id=auth.uid() or technician_id=auth.uid() or public.kw_role()='admin' or
 (status='searching' and public.kw_role()='technician' and exists(select 1 from public.kw_tech t where t.id=auth.uid() and t.approved and t.online and t.service=kw_jobs.service)));
create policy "bids view" on public.kw_bids for select to authenticated using(technician_id=auth.uid() or public.kw_role()='admin' or exists(select 1 from public.kw_jobs j where j.id=job_id and j.customer_id=auth.uid()));
create policy "bids insert" on public.kw_bids for insert to authenticated with check(technician_id=auth.uid() and exists(select 1 from public.kw_jobs j join public.kw_tech t on t.id=auth.uid() where j.id=job_id and j.status='searching' and t.approved and t.online and j.service=t.service));
create policy "messages view" on public.kw_messages for select to authenticated using(public.kw_role()='admin' or exists(select 1 from public.kw_jobs j where j.id=job_id and (j.customer_id=auth.uid() or j.technician_id=auth.uid())));
create policy "messages insert" on public.kw_messages for insert to authenticated with check(sender_id=auth.uid() and exists(select 1 from public.kw_jobs j where j.id=job_id and j.status in('accepted','arrived','working') and (j.customer_id=auth.uid() or j.technician_id=auth.uid())));
create policy "reviews view" on public.kw_reviews for select to authenticated using(true);
create policy "reviews insert" on public.kw_reviews for insert to authenticated with check(customer_id=auth.uid() and exists(select 1 from public.kw_jobs j where j.id=job_id and j.customer_id=auth.uid() and j.technician_id=kw_reviews.technician_id and j.status='completed'));
create policy "tickets own" on public.kw_tickets for select to authenticated using(user_id=auth.uid() or public.kw_role()='admin');
create policy "tickets insert" on public.kw_tickets for insert to authenticated with check(user_id=auth.uid());
create policy "saved own" on public.kw_saved for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
-- Secure RPCs are required; direct mutation of sensitive columns is revoked
revoke all on public.kw_profiles,public.kw_tech,public.kw_rates,public.kw_jobs,public.kw_bids,public.kw_messages,public.kw_reviews,public.kw_tickets,public.kw_saved from anon,authenticated;
grant select on public.kw_profiles,public.kw_tech,public.kw_rates,public.kw_jobs,public.kw_bids,public.kw_messages,public.kw_reviews,public.kw_tickets,public.kw_saved to authenticated;
grant update(name,phone,city) on public.kw_profiles to authenticated;
grant update(service,online,lat,lng,last_seen,experience,bio) on public.kw_tech to authenticated;
grant insert,update,delete on public.kw_rates to authenticated;
grant insert on public.kw_bids,public.kw_messages,public.kw_reviews,public.kw_tickets,public.kw_saved to authenticated;
grant delete on public.kw_saved to authenticated;
create or replace function public.kw_set_approval(p_user uuid,p_approved boolean) returns void language plpgsql security definer set search_path=public as $$
begin
 if public.kw_role()<>'admin' then raise exception 'Admin only';end if;
 update public.kw_tech set approved=p_approved,online=case when p_approved then online else false end where id=p_user;
end $$;
create or replace function public.kw_book(p_service text,p_city text,p_area text,p_address text,p_lat double precision,p_lng double precision,p_offer integer)
returns uuid language plpgsql security definer set search_path=public as $$
declare vmin integer; vjob uuid;
begin
 if public.kw_role()<>'customer' then raise exception 'Only customers book';end if;
 select minimum into vmin from public.kw_rates where city=p_city and area=p_area and service=p_service;
 if vmin is null then raise exception 'This area/service has no configured price';end if;
 if p_offer<vmin then raise exception 'Offer below minimum';end if;
 if p_lat not between -90 and 90 or p_lng not between -180 and 180 then raise exception 'Invalid GPS';end if;
 insert into public.kw_jobs(customer_id,service,city,area,address,lat,lng,minimum,offer)
 values(auth.uid(),p_service,p_city,p_area,p_address,p_lat,p_lng,vmin,p_offer) returning id into vjob;
 return vjob;
end $$;
create or replace function public.kw_raise_offer(p_job uuid,p_price integer) returns void language plpgsql security definer set search_path=public as $$
begin
 update public.kw_jobs set offer=p_price where id=p_job and customer_id=auth.uid() and status='searching' and p_price>offer;
 if not found then raise exception 'Only an increased offer is allowed';end if;
end $$;
create or replace function public.kw_select_bid(p_bid uuid) returns void language plpgsql security definer set search_path=public as $$
declare vjob uuid;vtech uuid;
begin
 select job_id,technician_id into vjob,vtech from public.kw_bids where id=p_bid;
 update public.kw_jobs set technician_id=vtech,status='accepted' where id=vjob and customer_id=auth.uid() and status='searching';
 if not found then raise exception 'Offer no longer available';end if;
end $$;
create or replace function public.kw_job_status(p_job uuid,p_status text) returns void language plpgsql security definer set search_path=public as $$
declare j public.kw_jobs;
begin
 select * into j from public.kw_jobs where id=p_job for update;
 if p_status='cancelled' and auth.uid() in(j.customer_id,j.technician_id) and j.status in('searching','accepted','arrived') then
 update public.kw_jobs set status='cancelled' where id=p_job;
 elsif j.technician_id=auth.uid() and ((j.status='accepted' and p_status='arrived') or (j.status='arrived' and p_status='working') or (j.status='working' and p_status='completed')) then
 update public.kw_jobs set status=p_status where id=p_job;
 else raise exception 'Invalid transition';end if;
end $$;
revoke all on function public.kw_set_approval(uuid,boolean),public.kw_book(text,text,text,text,double precision,double precision,integer),public.kw_raise_offer(uuid,integer),public.kw_select_bid(uuid),public.kw_job_status(uuid,text) from public,anon;
grant execute on function public.kw_set_approval(uuid,boolean),public.kw_book(text,text,text,text,double precision,double precision,integer),public.kw_raise_offer(uuid,integer),public.kw_select_bid(uuid),public.kw_job_status(uuid,text) to authenticated;
insert into public.kw_rates(city,area,service,minimum)
select 'Karachi',a,s,m from (values ('Gulshan-e-Iqbal'),('DHA'),('Clifton'),('Saddar'),('North Nazimabad')) x(a)
cross join (values ('Tyre Puncture',350),('Electrician',550),('Plumber',500),('AC Technician',800),('Car Mechanic',700),('Bike Mechanic',450),('Carpenter',650),('Painter',750),('Cleaning',600)) y(s,m);
-- Seeded pricing is ILLUSTRATIVE. Admin must review and set market rates.
-- To create first admin: sign up as customer, then SQL Editor:
-- update public.kw_profiles set role='admin' where id=(select id from auth.users where email='YOUR_ADMIN_EMAIL');
