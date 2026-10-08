-- Run this in Supabase: SQL Editor > New query > Run

create table purchases (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  customer_email text not null,
  order_ref text not null,
  item_name text not null,
  category text not null check (category in ('Food','Treats','Accessories')),
  quantity int not null check (quantity > 0),
  unit_price numeric(10,2) not null,
  total numeric(10,2) not null,
  created_at timestamptz not null default now()
);

create table appointments (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  customer_email text not null,
  pet_name text not null,
  pet_type text not null,
  service text not null,
  appointment_date date not null constraint appointments_no_sunday check (extract(dow from appointment_date) <> 0),
  appointment_time text not null,
  notes text,
  status text not null default 'Booked' check (status in ('Booked','Cancelled','Completed')),
  created_at timestamptz not null default now()
);

alter table purchases enable row level security;
alter table appointments enable row level security;

-- A slot is 30 minutes long; a date/time can have only one non-cancelled booking.
create unique index if not exists appointments_one_active_booking_per_slot
  on public.appointments (appointment_date, appointment_time)
  where status <> 'Cancelled';

-- Guest checkout and appointment booking. Customer records are insert-only from the browser.
create policy "guest purchases insert" on purchases for insert to anon, authenticated with check (true);
create policy "guest appointments insert" on appointments for insert to anon, authenticated with check (true);

-- Expose only date/time availability to the browser, never customer or pet details.
revoke select on table public.appointments from anon, authenticated;
grant select (appointment_date, appointment_time) on table public.appointments to anon, authenticated;
grant insert on table public.appointments to anon, authenticated;
create policy "guest appointment slots read" on appointments for select to anon, authenticated using (status <> 'Cancelled');
