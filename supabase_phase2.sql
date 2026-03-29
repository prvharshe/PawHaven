-- ============================================================
-- PawHaven — Phase 2 Supabase Setup
-- Paste this entire file into:
-- Supabase Dashboard → SQL Editor → New Query → Run
-- ============================================================


-- ============================================================
-- 1. get_user_threads() RPC
-- ============================================================

create or replace function public.get_user_threads(p_user_id uuid)
returns table (
  thread_id       uuid,
  pet_id          uuid,
  other_user_id   uuid,
  last_message    text,
  last_message_at timestamptz,
  unread_count    bigint
)
language sql
security definer
set search_path = public
as $$
  select
    m.thread_id,
    m.pet_id,
    case
      when m.sender_id = p_user_id then m.receiver_id
      else m.sender_id
    end                                         as other_user_id,
    last_m.body                                 as last_message,
    last_m.created_at                           as last_message_at,
    count(*) filter (
      where m.receiver_id = p_user_id and m.read = false
    )                                           as unread_count
  from messages m
  join lateral (
    select body, created_at
    from messages inner_m
    where inner_m.thread_id = m.thread_id
    order by inner_m.created_at desc
    limit 1
  ) last_m on true
  where m.sender_id = p_user_id or m.receiver_id = p_user_id
  group by m.thread_id, m.pet_id, other_user_id, last_m.body, last_m.created_at
  order by last_m.created_at desc;
$$;

grant execute on function public.get_user_threads(uuid) to authenticated;


-- ============================================================
-- 2. REALTIME — enable live inserts on messages
-- ============================================================

alter publication supabase_realtime add table public.messages;


-- ============================================================
-- 3. RLS POLICIES
-- CREATE POLICY has no IF NOT EXISTS, so we guard with DO blocks.
-- ============================================================

-- Fosters can delete their own pets
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'pets'
      and policyname = 'Fosters can delete their own pets'
  ) then
    execute $p$
      create policy "Fosters can delete their own pets"
        on public.pets for delete
        using (auth.uid() = foster_id);
    $p$;
  end if;
end;
$$;

-- Receivers can mark their messages as read
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'messages'
      and policyname = 'Receivers can mark messages as read'
  ) then
    execute $p$
      create policy "Receivers can mark messages as read"
        on public.messages for update
        using (auth.uid() = receiver_id);
    $p$;
  end if;
end;
$$;


-- ============================================================
-- 4. INDEXES
-- ============================================================

create index if not exists messages_sender_receiver_idx
  on public.messages(sender_id, receiver_id);

create index if not exists messages_created_at_idx
  on public.messages(created_at desc);


-- ============================================================
-- 5. STORAGE BUCKETS
-- Run the two INSERT statements below, then create policies
-- in Dashboard → Storage → (bucket) → Policies, or uncomment
-- the policy statements and run them here.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('pet-photos', 'pet-photos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Storage RLS (uncomment if not setting via Dashboard)
-- create policy "Public read pet-photos"
--   on storage.objects for select
--   using (bucket_id = 'pet-photos');

-- create policy "Authenticated upload pet-photos"
--   on storage.objects for insert to authenticated
--   with check (bucket_id = 'pet-photos');

-- create policy "Public read avatars"
--   on storage.objects for select
--   using (bucket_id = 'avatars');

-- create policy "Authenticated upload avatars"
--   on storage.objects for insert to authenticated
--   with check (bucket_id = 'avatars');


-- ============================================================
-- VERIFICATION (run individually after setup)
-- ============================================================

-- select * from pg_publication_tables where pubname = 'supabase_realtime';
-- select * from storage.buckets;
-- select * from get_user_threads('paste-a-real-user-uuid-here');
