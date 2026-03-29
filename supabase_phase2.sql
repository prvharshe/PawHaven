-- ============================================================
-- PawHaven — Phase 2 Supabase Setup
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ============================================================
-- 1. STORAGE BUCKETS
-- Create these in Dashboard → Storage, or run via SQL:
-- ============================================================

-- insert into storage.buckets (id, name, public)
-- values ('pet-photos', 'pet-photos', true)
-- on conflict do nothing;

-- insert into storage.buckets (id, name, public)
-- values ('avatars', 'avatars', true)
-- on conflict do nothing;

-- Storage RLS policies (allow authenticated uploads to own folder)
-- create policy "Authenticated users can upload pet photos"
--   on storage.objects for insert to authenticated
--   with check (bucket_id = 'pet-photos');

-- create policy "Authenticated users can upload their avatar"
--   on storage.objects for insert to authenticated
--   with check (
--     bucket_id = 'avatars' AND
--     (storage.foldername(name))[1] = auth.uid()::text
--   );

-- create policy "Public read on pet-photos"
--   on storage.objects for select using (bucket_id = 'pet-photos');

-- create policy "Public read on avatars"
--   on storage.objects for select using (bucket_id = 'avatars');

-- ============================================================
-- 2. get_user_threads() RPC
-- Returns all conversation threads for a given user,
-- newest message first.
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
    -- "other user" = whoever is NOT p_user_id in the thread
    case
      when m.sender_id   = p_user_id then m.receiver_id
      else m.sender_id
    end                                                       as other_user_id,
    last_m.body                                               as last_message,
    last_m.created_at                                         as last_message_at,
    count(*) filter (
      where m.receiver_id = p_user_id and m.read = false
    )                                                         as unread_count
  from messages m
  -- join to get the latest message per thread
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

-- Grant execute to authenticated users
grant execute on function public.get_user_threads(uuid) to authenticated;

-- ============================================================
-- 3. REALTIME
-- Enable Realtime publication on the messages table so
-- ChatService.messageStream() receives live inserts.
-- Run each statement separately if needed.
-- ============================================================

-- Add messages to the supabase_realtime publication
alter publication supabase_realtime add table public.messages;

-- ============================================================
-- 4. ADDITIONAL RLS POLICIES (Phase 2 additions)
-- ============================================================

-- Allow authenticated users to delete their own pets
-- (already in phase 1 schema, but adding explicit policy for delete)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename   = 'pets'
      and policyname  = 'Fosters can delete their own pets'
  ) then
    execute $policy$
      create policy "Fosters can delete their own pets"
        on public.pets for delete
        using (auth.uid() = foster_id);
    $policy$;
  end if;
end;
$$;

-- Allow users to update their own message read status
create policy if not exists "Receivers can mark messages as read"
  on public.messages for update
  using (auth.uid() = receiver_id);

-- ============================================================
-- 5. INDEXES (Phase 2 additions for chat performance)
-- ============================================================

create index if not exists messages_sender_receiver_idx
  on public.messages(sender_id, receiver_id);

create index if not exists messages_created_at_idx
  on public.messages(created_at desc);

-- ============================================================
-- VERIFICATION QUERIES
-- Run these after setup to confirm everything is working:
-- ============================================================

-- Check realtime is enabled on messages:
-- select * from pg_publication_tables where pubname = 'supabase_realtime';

-- Test the RPC (replace with a real user UUID from your users table):
-- select * from get_user_threads('00000000-0000-0000-0000-000000000000');

-- Check buckets exist:
-- select * from storage.buckets;
