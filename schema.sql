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
  appointment_date date not null,
  appointment_time text not null,
  notes text,
  status text not null default 'Booked' check (status in ('Booked','Cancelled','Completed')),
  created_at timestamptz not null default now()
);

alter table purchases enable row level security;
alter table appointments enable row level security;

-- Guest checkout and appointment booking. Customer records are insert-only from the browser.
create policy "guest purchases insert" on purchases for insert to anon, authenticated with check (true);
create policy "guest appointments insert" on appointments for insert to anon, authenticated with check (true);
