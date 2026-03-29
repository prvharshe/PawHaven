-- ============================================================
-- PawHaven — Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Enable PostGIS for geographic queries (nearby pets/fosters/vets)
create extension if not exists postgis;

-- ============================================================
-- TABLES
-- ============================================================

-- users (mirrors auth.users with app-specific profile data)
create table public.users (
  id                   uuid primary key references auth.users(id) on delete cascade,
  role                 text not null default 'adopter'
                         check (role in ('foster', 'adopter', 'both')),
  display_name         text not null,
  bio                  text,
  avatar_url           text,
  location_point       geography(Point, 4326),
  city                 text,
  verified             boolean not null default false,
  available_for_intake boolean not null default false,
  created_at           timestamptz not null default now()
);

-- pets
create table public.pets (
  id             uuid primary key default gen_random_uuid(),
  foster_id      uuid not null references public.users(id) on delete cascade,
  name           text not null,
  species        text not null check (species in ('dog','cat','bird','rabbit','other')),
  breed          text,
  age_months     int,
  size           text check (size in ('small','medium','large')),
  gender         text not null default 'unknown'
                   check (gender in ('male','female','unknown')),
  description    text,
  health_notes   text,
  behavior_notes text,
  vaccinated     boolean not null default false,
  neutered       boolean not null default false,
  status         text not null default 'available'
                   check (status in ('available','pending','adopted')),
  location_point geography(Point, 4326),
  city           text,
  photos         text[] not null default '{}',
  created_at     timestamptz not null default now()
);

-- messages
create table public.messages (
  id          uuid primary key default gen_random_uuid(),
  thread_id   uuid not null,
  pet_id      uuid references public.pets(id) on delete set null,
  sender_id   uuid not null references public.users(id) on delete cascade,
  receiver_id uuid not null references public.users(id) on delete cascade,
  body        text not null,
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);

-- saved_pets
create table public.saved_pets (
  user_id uuid not null references public.users(id) on delete cascade,
  pet_id  uuid not null references public.pets(id) on delete cascade,
  primary key (user_id, pet_id)
);

-- vet_listings
create table public.vet_listings (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  address        text,
  phone          text,
  website        text,
  location_point geography(Point, 4326),
  hours          jsonb,
  verified       boolean not null default false,
  created_at     timestamptz not null default now()
);

-- reports
create table public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  target_type text not null check (target_type in ('pet','user','message')),
  target_id   uuid not null,
  reason      text not null,
  status      text not null default 'pending'
                check (status in ('pending','reviewed','dismissed')),
  created_at  timestamptz not null default now()
);

-- blocked_users
create table public.blocked_users (
  blocker_id uuid not null references public.users(id) on delete cascade,
  blocked_id uuid not null references public.users(id) on delete cascade,
  primary key (blocker_id, blocked_id)
);

-- ============================================================
-- INDEXES
-- ============================================================

create index pets_foster_id_idx       on public.pets(foster_id);
create index pets_status_idx          on public.pets(status);
create index pets_species_idx         on public.pets(species);
create index pets_created_at_idx      on public.pets(created_at desc);
create index pets_location_idx        on public.pets using gist(location_point);
create index messages_thread_id_idx   on public.messages(thread_id);
create index messages_receiver_idx    on public.messages(receiver_id);
create index users_location_idx       on public.users using gist(location_point);
create index vet_location_idx         on public.vet_listings using gist(location_point);

-- ============================================================
-- TRIGGER: Auto-create user profile on sign-up
-- When someone signs up via Supabase Auth, this trigger inserts
-- a matching row in public.users using the metadata from signUp().
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', 'Anonymous'),
    coalesce(new.raw_user_meta_data->>'role', 'adopter')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Enable RLS on every table, then define access policies.
-- ============================================================

alter table public.users         enable row level security;
alter table public.pets          enable row level security;
alter table public.messages      enable row level security;
alter table public.saved_pets    enable row level security;
alter table public.vet_listings  enable row level security;
alter table public.reports       enable row level security;
alter table public.blocked_users enable row level security;

-- ---- users ----
create policy "Public profiles are viewable by everyone"
  on public.users for select using (true);

create policy "Users can update their own profile"
  on public.users for update using (auth.uid() = id);

-- ---- pets ----
create policy "Available pets are viewable by everyone"
  on public.pets for select using (true);

create policy "Fosters can insert their own pets"
  on public.pets for insert with check (auth.uid() = foster_id);

create policy "Fosters can update their own pets"
  on public.pets for update using (auth.uid() = foster_id);

create policy "Fosters can delete their own pets"
  on public.pets for delete using (auth.uid() = foster_id);

-- ---- messages ----
create policy "Users can view their own messages"
  on public.messages for select
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "Authenticated users can send messages"
  on public.messages for insert
  with check (auth.uid() = sender_id);

-- ---- saved_pets ----
create policy "Users can manage their own saved pets"
  on public.saved_pets for all using (auth.uid() = user_id);

-- ---- vet_listings ----
create policy "Vet listings are public"
  on public.vet_listings for select using (true);

-- ---- reports ----
create policy "Users can submit reports"
  on public.reports for insert with check (auth.uid() = reporter_id);

-- ---- blocked_users ----
create policy "Users manage their own blocks"
  on public.blocked_users for all using (auth.uid() = blocker_id);

-- ============================================================
-- STORAGE
-- Run separately in: Storage → New Bucket
-- Or via Dashboard → Storage → Create bucket "pet-photos"
-- with Public access = true
-- ============================================================
-- insert into storage.buckets (id, name, public)
-- values ('pet-photos', 'pet-photos', true);

-- ============================================================
-- SAMPLE DATA (optional — seed for development)
-- ============================================================
-- Uncomment and run after creating your first auth user:
--
-- insert into public.pets (foster_id, name, species, breed, age_months, size, gender,
--   description, vaccinated, neutered, status, city, photos)
-- values (
--   '<your-user-uuid>',
--   'Bella', 'dog', 'Golden Retriever', 14, 'medium', 'female',
--   'Friendly and loves cuddles. Great with kids.',
--   true, true, 'available', 'Mumbai',
--   array['https://<your-project>.supabase.co/storage/v1/object/public/pet-photos/sample.jpg']
-- );
