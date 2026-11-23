-- Campus Connect database schema
-- ALREADY APPLIED to your Supabase project "campus-connect" (psyjljccsdhmshhthnyk).
-- Kept here so you can recreate the database in a new project: SQL Editor -> paste -> Run.
-- Re-running drops and recreates the app tables (NOT your auth users).

create extension if not exists vector with schema extensions;

drop table if exists notifications cascade;
drop table if exists issues cascade;
drop table if exists issue_groups cascade;
drop table if exists events cascade;
drop table if exists locations cascade;
drop table if exists saved_opportunities cascade;
drop table if exists opportunities cascade;
drop table if exists members cascade;
drop table if exists projects cascade;
drop table if exists knowledge cascade;
drop table if exists skills cascade;
drop table if exists profiles cascade;

-- People -------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text not null,
  year int,
  branch text,
  bio text,
  interests text[] default '{}',
  skills jsonb default '{}'::jsonb,          -- {"ai_ml": 4, "iot": 3}  (level 1-5)
  availability text default 'medium',        -- low | medium | high
  is_discoverable boolean default false,     -- opt-in for Talent Graph
  role text default 'student',               -- student | staff | admin
  created_at timestamptz default now()
);

create table skills (
  name text primary key,                     -- 'ai_ml'
  label text not null,                       -- 'AI / ML'
  category text
);

-- Projects -----------------------------------------------------------------
create table projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references profiles on delete set null,
  title text not null,
  goal text,
  needed_skills text[] default '{}',
  roadmap jsonb default '[]'::jsonb,         -- [{week, task, owner}]
  status text default 'active',
  created_at timestamptz default now()
);

create table members (
  project_id uuid references projects on delete cascade,
  profile_id uuid references profiles on delete cascade,
  role text,
  status text default 'invited',             -- invited | accepted | declined
  primary key (project_id, profile_id)
);

-- Opportunities ------------------------------------------------------------
create table opportunities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type text,                                 -- hackathon | internship | scholarship | workshop | competition | research
  organizer text,
  description text,
  url text,
  source text,
  deadline date,
  min_year int,
  branches text[],                           -- null = all branches
  tags text[] default '{}',
  verified boolean default false
);

create table saved_opportunities (
  profile_id uuid references profiles on delete cascade,
  opportunity_id uuid references opportunities on delete cascade,
  created_at timestamptz default now(),
  primary key (profile_id, opportunity_id)
);

-- Campus map ---------------------------------------------------------------
create table locations (
  id serial primary key,
  name text not null,
  type text,                                 -- academic | lab | hostel | sports | service | food
  lat double precision,
  lng double precision,
  description text,
  accessibility text
);

create table events (
  id uuid primary key default gen_random_uuid(),
  title text,
  description text,
  location_id int references locations on delete set null,
  starts_at timestamptz,
  ends_at timestamptz
);

-- Campus Pulse -------------------------------------------------------------
create table issue_groups (
  id uuid primary key default gen_random_uuid(),
  title text,
  category text,
  location_id int references locations on delete set null,
  priority text default 'medium',            -- low | medium | high
  priority_rule text,
  status text default 'open',                -- open | assigned | in_progress | resolved
  assigned_team text,
  report_count int default 1,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  resolved_at timestamptz
);

create table issues (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles on delete set null,
  group_id uuid references issue_groups on delete cascade,
  description text not null,
  category text,
  location_id int references locations on delete set null,
  lat double precision,
  lng double precision,
  embedding extensions.vector(768),
  created_at timestamptz default now()
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles on delete cascade,
  title text,
  body text,
  link text,
  read boolean default false,
  created_at timestamptz default now()
);

-- AI knowledge base (RAG) --------------------------------------------------
create table knowledge (
  id serial primary key,
  title text,
  content text,
  source text,
  embedding extensions.vector(768)
);

create or replace function match_knowledge(q extensions.vector(768), k int default 4)
returns table (id int, title text, content text, source text, similarity float)
language sql stable
set search_path = public, extensions
as $$
  select id, title, content, source, 1 - (embedding <=> q) as similarity
  from knowledge
  where embedding is not null
  order by embedding <=> q
  limit k;
$$;

-- Foreign-key indexes
create index on projects (owner_id);
create index on members (profile_id);
create index on saved_opportunities (opportunity_id);
create index on events (location_id);
create index on issue_groups (location_id);
create index on issues (group_id);
create index on issues (reporter_id);
create index on issues (location_id);
create index on notifications (profile_id);

-- Row Level Security -------------------------------------------------------
-- Reads happen with the logged-in user's session. All writes go through the
-- app's server routes (service role), which check the user first.
alter table profiles enable row level security;
alter table skills enable row level security;
alter table projects enable row level security;
alter table members enable row level security;
alter table opportunities enable row level security;
alter table saved_opportunities enable row level security;
alter table locations enable row level security;
alter table events enable row level security;
alter table issue_groups enable row level security;
alter table issues enable row level security;
alter table notifications enable row level security;
alter table knowledge enable row level security;

create policy "profiles: discoverable or own" on profiles for select to authenticated
  using (is_discoverable or id = (select auth.uid()));
create policy "skills: read" on skills for select to authenticated using (true);
create policy "projects: read" on projects for select to authenticated using (true);
create policy "members: read" on members for select to authenticated using (true);
create policy "opportunities: read" on opportunities for select to authenticated using (true);
create policy "saved: own" on saved_opportunities for select to authenticated using (profile_id = (select auth.uid()));
create policy "locations: read" on locations for select to authenticated using (true);
create policy "events: read" on events for select to authenticated using (true);
create policy "issue_groups: read" on issue_groups for select to authenticated using (true);
create policy "issues: read" on issues for select to authenticated using (true);
create policy "notifications: own" on notifications for select to authenticated using (profile_id = (select auth.uid()));
create policy "knowledge: read" on knowledge for select to authenticated using (true);

-- Realtime: live updates for the Pulse board and notifications
do $$
begin
  begin alter publication supabase_realtime add table issue_groups; exception when others then null; end;
  begin alter publication supabase_realtime add table notifications; exception when others then null; end;
end $$;
