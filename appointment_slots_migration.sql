-- Run this once in Supabase SQL Editor for an existing project.
-- Keeps customer/pet details private while exposing only occupied date/time pairs.

alter table public.appointments
  add column if not exists customer_name text,
  add column if not exists customer_email text;

-- Older versions tied guest bookings to an authenticated user_id.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'user_id'
  ) then
    alter table public.appointments alter column user_id drop not null;
  end if;
end $$;

alter table public.appointments
  drop constraint if exists appointments_no_sunday;

alter table public.appointments
  add constraint appointments_no_sunday
  check (extract(dow from appointment_date) <> 0) not valid;

create unique index if not exists appointments_one_active_booking_per_slot
  on public.appointments (appointment_date, appointment_time)
  where status <> 'Cancelled';

drop policy if exists "guest appointment slots read" on public.appointments;
drop policy if exists "own appts read" on public.appointments;
drop policy if exists "own appts insert" on public.appointments;
drop policy if exists "own appts update" on public.appointments;
drop policy if exists "guest appointments insert" on public.appointments;
create policy "guest appointments insert"
  on public.appointments
  for insert to anon, authenticated
  with check (true);
create policy "guest appointment slots read"
  on public.appointments
  for select to anon, authenticated
  using (status <> 'Cancelled');

revoke select on table public.appointments from anon, authenticated;
grant insert on table public.appointments to anon, authenticated;
grant select (appointment_date, appointment_time)
  on table public.appointments to anon, authenticated;

notify pgrst, 'reload schema';
