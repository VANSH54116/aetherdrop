-- ============================================================================
-- AetherDrop Core Schema
-- Source: AetherDrop_Master_Blueprint.md (Step 4.4), made idempotent.
-- Applied via the Supabase Management API.
-- ============================================================================

-- 1. Extensions --------------------------------------------------------------
create extension if not exists "uuid-ossp";

-- 2. Profiles ----------------------------------------------------------------
create table if not exists public.profiles (
    id uuid references auth.users(id) on delete cascade primary key,
    email text unique not null,
    display_name text not null,
    avatar_id text not null default 'starter_cyber_01',
    frame_id text not null default 'frame_slate_01',
    xp bigint not null default 0,
    level int not null default 1,
    total_bytes_sent bigint not null default 0,
    total_files_sent int not null default 0,
    unlocked_avatars text[] default array['starter_cyber_01', 'starter_cyber_02', 'starter_cyber_03', 'starter_cyber_04'],
    unlocked_badges text[] default array['badge_first_node'],
    is_online boolean default true,
    last_seen timestamptz default now(),
    created_at timestamptz default now()
);

create index if not exists idx_profiles_email on public.profiles (lower(email));
create index if not exists idx_profiles_display_name on public.profiles (lower(display_name));

-- 3. Peer connections --------------------------------------------------------
create table if not exists public.peer_connections (
    id uuid default uuid_generate_v4() primary key,
    user_a uuid references public.profiles(id) on delete cascade,
    user_b uuid references public.profiles(id) on delete cascade,
    streak_count int default 1,
    last_transfer_at timestamptz default now(),
    total_shared_bytes bigint default 0,
    unique (user_a, user_b)
);

-- 4. Global ecosystem stats --------------------------------------------------
create table if not exists public.ecosystem_stats (
    id int primary key default 1,
    total_users bigint default 1,
    total_transfers bigint default 0,
    total_gigabytes_warped numeric(12, 2) default 0.00
);

insert into public.ecosystem_stats (id, total_users, total_transfers, total_gigabytes_warped)
values (1, 1, 0, 0.00)
on conflict (id) do nothing;

-- 5. Row Level Security ------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.peer_connections enable row level security;
alter table public.ecosystem_stats enable row level security;

-- profiles
drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
create policy "Public profiles are viewable by everyone"
on public.profiles for select
using (true);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- peer_connections
drop policy if exists "Users can view their own peer connections" on public.peer_connections;
create policy "Users can view their own peer connections"
on public.peer_connections for select
using (auth.uid() = user_a or auth.uid() = user_b);

drop policy if exists "Users can insert or update peer connections" on public.peer_connections;
create policy "Users can insert or update peer connections"
on public.peer_connections for all
using (auth.uid() = user_a or auth.uid() = user_b)
with check (auth.uid() = user_a or auth.uid() = user_b);

-- ecosystem_stats
drop policy if exists "Anyone can view ecosystem stats" on public.ecosystem_stats;
create policy "Anyone can view ecosystem stats"
on public.ecosystem_stats for select
using (true);

drop policy if exists "Authenticated users can increment stats" on public.ecosystem_stats;
create policy "Authenticated users can increment stats"
on public.ecosystem_stats for update
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

-- 6. XP / transfer function --------------------------------------------------
create or replace function public.record_transfer_and_award_xp(
    p_user_id uuid,
    p_bytes_sent bigint,
    p_files_count int,
    p_is_folder boolean
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_xp_gained bigint;
    v_new_xp bigint;
    v_new_level int;
    v_new_avatars text[];
begin
    -- 50 base + 10 per 100MB + 150 bonus for folders
    v_xp_gained := 50 + (p_bytes_sent / 104857600) * 10 + (case when p_is_folder then 150 else 0 end);

    update public.profiles
    set
        xp = xp + v_xp_gained,
        total_bytes_sent = total_bytes_sent + p_bytes_sent,
        total_files_sent = total_files_sent + p_files_count,
        level = greatest(1, floor(sqrt((xp + v_xp_gained) / 25.0))::int),
        last_seen = now()
    where id = p_user_id
    returning xp, level, unlocked_avatars into v_new_xp, v_new_level, v_new_avatars;

    if v_new_level >= 5 and not ('cyber_kitsune_05' = any(v_new_avatars)) then
        update public.profiles set unlocked_avatars = array_append(unlocked_avatars, 'cyber_kitsune_05') where id = p_user_id;
    end if;
    if v_new_level >= 10 and not ('holo_samurai_10' = any(v_new_avatars)) then
        update public.profiles set unlocked_avatars = array_append(unlocked_avatars, 'holo_samurai_10') where id = p_user_id;
    end if;
    if v_new_level >= 25 and not ('astral_phoenix_25' = any(v_new_avatars)) then
        update public.profiles set unlocked_avatars = array_append(unlocked_avatars, 'astral_phoenix_25') where id = p_user_id;
    end if;
    if v_new_level >= 50 and not ('apex_singularity_50' = any(v_new_avatars)) then
        update public.profiles set unlocked_avatars = array_append(unlocked_avatars, 'apex_singularity_50') where id = p_user_id;
    end if;

    update public.ecosystem_stats
    set
        total_transfers = total_transfers + 1,
        total_gigabytes_warped = total_gigabytes_warped + round((p_bytes_sent::numeric / 1073741824.0), 4)
    where id = 1;

    return jsonb_build_object('xp_gained', v_xp_gained, 'new_xp', v_new_xp, 'new_level', v_new_level);
end;
$$;

revoke all on function public.record_transfer_and_award_xp(uuid, bigint, int, boolean) from public;
revoke all on function public.record_transfer_and_award_xp(uuid, bigint, int, boolean) from anon;
grant execute on function public.record_transfer_and_award_xp(uuid, bigint, int, boolean) to authenticated;

-- 7. Realtime ----------------------------------------------------------------
do $$
declare
    t text;
begin
    foreach t in array array['profiles', 'peer_connections', 'ecosystem_stats'] loop
        if not exists (
            select 1 from pg_publication_tables
            where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
        ) then
            execute format('alter publication supabase_realtime add table public.%I', t);
        end if;
    end loop;
end
$$;

-- Realtime UPDATE/DELETE payloads should carry full rows.
alter table public.profiles replica identity full;
alter table public.peer_connections replica identity full;
alter table public.ecosystem_stats replica identity full;
