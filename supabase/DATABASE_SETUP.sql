-- ============================================================
-- VERIFIEDMEASURE SAAS INTELLIGENCE PLATFORM
-- Complete Database Schema - Single Paste Setup
-- ============================================================

begin;

-- Extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm";

-- ============================================================
-- ENUMS
-- ============================================================

create type public.workflow_status as enum (
  'new',
  'contacted',
  'qualified',
  'proposal',
  'negotiation',
  'closed_won',
  'closed_lost'
);

create type public.user_role as enum ('user', 'admin', 'super_admin');

-- ============================================================
-- CORE TABLES
-- ============================================================

-- User Profiles
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  company text,
  role public.user_role not null default 'user',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Leads (SaaS Companies)
create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  company text not null,
  email text not null,
  phone text,
  
  -- Company Details
  website text,
  industry text,
  employee_count int,
  annual_revenue bigint,
  founded_year int,
  
  -- Location
  city text,
  state text,
  country text default 'USA',
  
  -- Intelligence
  intelligence_score int not null default 50 check (intelligence_score >= 0 and intelligence_score <= 100),
  tech_stack text[],
  funding_stage text,
  last_funding_amount bigint,
  
  -- Contact Info
  decision_maker_name text,
  decision_maker_title text,
  decision_maker_linkedin text,
  
  -- Workflow
  workflow public.workflow_status not null default 'new',
  
  -- Meta
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Lead Access (Entitlements)
create table if not exists public.lead_access (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, lead_id)
);

-- Credit Ledger
create table if not exists public.credit_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  amount int not null,
  reason text not null,
  lead_id uuid references public.leads(id) on delete set null,
  admin_id uuid references public.user_profiles(id) on delete set null,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Feature Flags
create table if not exists public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Audit Log
create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.user_profiles(id) on delete set null,
  action text not null,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Lead Notes
create table if not exists public.lead_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  note text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Lead Signals (Intelligence Timeline)
create table if not exists public.lead_signals (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.leads(id) on delete cascade,
  signal_type text not null,
  severity int not null default 1,
  title text not null,
  detail text,
  source text,
  meta jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Activity Feed
create table if not exists public.activity_feed (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  action text not null,
  lead_id uuid references public.leads(id) on delete set null,
  ref_type text,
  ref_id uuid,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Saved Views
create table if not exists public.saved_views (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  name text not null,
  description text,
  filters jsonb not null default '{}'::jsonb,
  sort jsonb not null default '{}'::jsonb,
  columns jsonb not null default '{}'::jsonb,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Export Jobs
create table if not exists public.export_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  status text not null default 'queued',
  kind text not null default 'entitled_csv',
  requested_lead_ids uuid[] not null default '{}'::uuid[],
  exported_lead_count int not null default 0,
  error text,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- INDEXES
-- ============================================================

create index if not exists leads_company_idx on public.leads using gin(company gin_trgm_ops);
create index if not exists leads_industry_idx on public.leads(industry);
create index if not exists leads_intelligence_score_idx on public.leads(intelligence_score desc);
create index if not exists leads_workflow_idx on public.leads(workflow);
create index if not exists leads_created_at_idx on public.leads(created_at desc);

create index if not exists lead_access_user_idx on public.lead_access(user_id);
create index if not exists lead_access_lead_idx on public.lead_access(lead_id);

create index if not exists credit_ledger_user_idx on public.credit_ledger(user_id, created_at desc);

create index if not exists lead_notes_lead_idx on public.lead_notes(lead_id, created_at desc);
create index if not exists lead_notes_user_idx on public.lead_notes(user_id);

create index if not exists lead_signals_lead_id_idx on public.lead_signals(lead_id);
create index if not exists lead_signals_occurred_at_idx on public.lead_signals(occurred_at desc);

create index if not exists activity_feed_user_idx on public.activity_feed(user_id, created_at desc);

create index if not exists saved_views_user_idx on public.saved_views(user_id);

create index if not exists export_jobs_user_idx on public.export_jobs(user_id, created_at desc);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Updated At Trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Is Admin Check
create or replace function public.is_admin(p_user_id uuid)
returns boolean
language plpgsql
security definer
as $$
declare
  v_role public.user_role;
begin
  select role into v_role
  from public.user_profiles
  where id = p_user_id;
  
  return v_role in ('admin', 'super_admin');
end;
$$;

-- Get User Credit Balance
create or replace function public.get_credit_balance(p_user_id uuid)
returns int
language plpgsql
security definer
as $$
declare
  v_balance int;
begin
  select coalesce(sum(amount), 0)
  into v_balance
  from public.credit_ledger
  where user_id = p_user_id;
  
  return v_balance;
end;
$$;

-- Unlock Leads (RPC)
create or replace function public.unlock_leads_secure(p_lead_ids uuid[])
returns jsonb
language plpgsql
security definer
as $$
declare
  v_user uuid;
  v_balance int;
  v_cost int;
  v_already_owned int;
  v_new_unlocks int;
  v_lead_id uuid;
begin
  v_user := auth.uid();
  
  if v_user is null then
    raise exception 'Not authenticated';
  end if;
  
  -- Count already owned
  select count(*)
  into v_already_owned
  from public.lead_access
  where user_id = v_user
    and lead_id = any(p_lead_ids);
  
  v_new_unlocks := array_length(p_lead_ids, 1) - v_already_owned;
  v_cost := v_new_unlocks;
  
  if v_new_unlocks = 0 then
    return jsonb_build_object(
      'success', true,
      'unlocked', 0,
      'message', 'All leads already unlocked'
    );
  end if;
  
  -- Check balance
  v_balance := public.get_credit_balance(v_user);
  
  if v_balance < v_cost then
    raise exception 'Insufficient credits. Need % but have %', v_cost, v_balance;
  end if;
  
  -- Grant access
  foreach v_lead_id in array p_lead_ids
  loop
    insert into public.lead_access(user_id, lead_id)
    values (v_user, v_lead_id)
    on conflict (user_id, lead_id) do nothing;
  end loop;
  
  -- Deduct credits
  insert into public.credit_ledger(user_id, amount, reason, meta)
  values (
    v_user,
    -v_cost,
    'unlock_leads',
    jsonb_build_object('lead_ids', p_lead_ids, 'count', v_new_unlocks)
  );
  
  -- Log activity
  foreach v_lead_id in array p_lead_ids
  loop
    insert into public.activity_feed(user_id, action, lead_id, meta)
    values (v_user, 'unlocked', v_lead_id, jsonb_build_object('cost', 1))
    on conflict do nothing;
  end loop;
  
  insert into public.audit_log(user_id, action, meta)
  values (v_user, 'unlock_leads', jsonb_build_object('count', v_new_unlocks, 'cost', v_cost));
  
  return jsonb_build_object(
    'success', true,
    'unlocked', v_new_unlocks,
    'cost', v_cost,
    'new_balance', v_balance - v_cost
  );
end;
$$;

-- Admin Grant Credits
create or replace function public.admin_grant_credits(
  p_target_user_id uuid,
  p_amount int,
  p_reason text
)
returns void
language plpgsql
security definer
as $$
declare
  v_admin uuid;
begin
  v_admin := auth.uid();
  
  if v_admin is null then
    raise exception 'Not authenticated';
  end if;
  
  if not public.is_admin(v_admin) then
    raise exception 'Forbidden: admin role required';
  end if;
  
  insert into public.credit_ledger(user_id, amount, reason, admin_id)
  values (p_target_user_id, p_amount, p_reason, v_admin);
  
  insert into public.audit_log(user_id, action, meta)
  values (v_admin, 'grant_credits', jsonb_build_object(
    'target_user_id', p_target_user_id,
    'amount', p_amount,
    'reason', p_reason
  ));
end;
$$;

-- Set Workflow
create or replace function public.set_workflow_secure(
  p_lead_id uuid,
  p_workflow public.workflow_status
)
returns void
language plpgsql
security definer
as $$
declare
  v_user uuid;
begin
  v_user := auth.uid();
  
  if v_user is null then
    raise exception 'Not authenticated';
  end if;
  
  update public.leads
  set workflow = p_workflow
  where id = p_lead_id;
  
  insert into public.activity_feed(user_id, action, lead_id, meta)
  values (v_user, 'workflow_changed', p_lead_id, jsonb_build_object('workflow', p_workflow::text));
  
  insert into public.audit_log(user_id, action, meta)
  values (v_user, 'workflow_changed', jsonb_build_object('lead_id', p_lead_id, 'workflow', p_workflow::text));
end;
$$;

-- Add Lead Note
create or replace function public.add_lead_note_secure(
  p_lead_id uuid,
  p_note text
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_user uuid;
  v_id uuid;
begin
  v_user := auth.uid();
  
  if v_user is null then
    raise exception 'Not authenticated';
  end if;
  
  insert into public.lead_notes(user_id, lead_id, note)
  values (v_user, p_lead_id, p_note)
  returning id into v_id;
  
  insert into public.activity_feed(user_id, action, lead_id, ref_type, ref_id, meta)
  values (v_user, 'note_added', p_lead_id, 'lead_note', v_id, jsonb_build_object('len', length(p_note)));
  
  return v_id;
end;
$$;

-- Create Export Job
create or replace function public.create_entitled_export_job(
  p_lead_ids uuid[]
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_user uuid;
  v_job uuid;
  v_count int;
begin
  v_user := auth.uid();
  
  if v_user is null then
    raise exception 'Not authenticated';
  end if;
  
  select count(*)
  into v_count
  from public.lead_access
  where user_id = v_user
    and lead_id = any(p_lead_ids);
  
  if v_count <> coalesce(array_length(p_lead_ids, 1), 0) then
    raise exception 'Forbidden: export requires entitlement';
  end if;
  
  insert into public.export_jobs(user_id, status, kind, requested_lead_ids, exported_lead_count)
  values (v_user, 'done', 'entitled_csv', p_lead_ids, v_count)
  returning id into v_job;
  
  insert into public.activity_feed(user_id, action, ref_type, ref_id, meta)
  values (v_user, 'export_requested', 'export_job', v_job, jsonb_build_object('count', v_count));
  
  return v_job;
end;
$$;

-- Admin Set Feature Flag
create or replace function public.admin_set_feature_flag(
  p_key text,
  p_enabled boolean
)
returns void
language plpgsql
security definer
as $$
declare
  v_user uuid;
begin
  v_user := auth.uid();
  
  if v_user is null then
    raise exception 'Not authenticated';
  end if;
  
  if not public.is_admin(v_user) then
    raise exception 'Forbidden';
  end if;
  
  insert into public.feature_flags(key, enabled)
  values (p_key, p_enabled)
  on conflict (key) do update set enabled = excluded.enabled;
  
  insert into public.audit_log(user_id, action, meta)
  values (v_user, 'feature_flag_set', jsonb_build_object('key', p_key, 'enabled', p_enabled));
end;
$$;

-- ============================================================
-- TRIGGERS
-- ============================================================

create trigger user_profiles_set_updated_at
  before update on public.user_profiles
  for each row execute function public.set_updated_at();

create trigger leads_set_updated_at
  before update on public.leads
  for each row execute function public.set_updated_at();

create trigger lead_notes_set_updated_at
  before update on public.lead_notes
  for each row execute function public.set_updated_at();

create trigger feature_flags_set_updated_at
  before update on public.feature_flags
  for each row execute function public.set_updated_at();

create trigger saved_views_set_updated_at
  before update on public.saved_views
  for each row execute function public.set_updated_at();

create trigger export_jobs_set_updated_at
  before update on public.export_jobs
  for each row execute function public.set_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.user_profiles enable row level security;
alter table public.leads enable row level security;
alter table public.lead_access enable row level security;
alter table public.credit_ledger enable row level security;
alter table public.feature_flags enable row level security;
alter table public.audit_log enable row level security;
alter table public.lead_notes enable row level security;
alter table public.lead_signals enable row level security;
alter table public.activity_feed enable row level security;
alter table public.saved_views enable row level security;
alter table public.export_jobs enable row level security;

-- User Profiles
create policy "Users can read own profile"
  on public.user_profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.user_profiles for update
  using (auth.uid() = id);

-- Leads (Preview Model - All Authenticated Can Read)
create policy "Authenticated users can read all leads"
  on public.leads for select
  using (auth.role() = 'authenticated');

-- Lead Access
create policy "Users can read own access"
  on public.lead_access for select
  using (auth.uid() = user_id);

-- Credit Ledger
create policy "Users can read own credits"
  on public.credit_ledger for select
  using (auth.uid() = user_id);

-- Feature Flags
create policy "Authenticated users can read feature flags"
  on public.feature_flags for select
  using (auth.role() = 'authenticated');

-- Audit Log
create policy "Admins can read audit log"
  on public.audit_log for select
  using (
    exists (
      select 1 from public.user_profiles
      where id = auth.uid()
      and role in ('admin', 'super_admin')
    )
  );

-- Lead Notes
create policy "Users can read own notes"
  on public.lead_notes for select
  using (auth.uid() = user_id);

-- Lead Signals
create policy "Authenticated users can read signals"
  on public.lead_signals for select
  using (auth.role() = 'authenticated');

-- Activity Feed
create policy "Users can read own activity"
  on public.activity_feed for select
  using (auth.uid() = user_id);

-- Saved Views
create policy "Users can manage own saved views"
  on public.saved_views for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Export Jobs
create policy "Users can read own exports"
  on public.export_jobs for select
  using (auth.uid() = user_id);

create policy "Users can create own exports"
  on public.export_jobs for insert
  with check (auth.uid() = user_id);

-- ============================================================
-- PERMISSIONS
-- ============================================================

grant usage on schema public to authenticated;

grant select on public.user_profiles to authenticated;
grant update on public.user_profiles to authenticated;

grant select on public.leads to authenticated;
grant select on public.lead_access to authenticated;
grant select on public.credit_ledger to authenticated;
grant select on public.feature_flags to authenticated;
grant select on public.audit_log to authenticated;
grant select on public.lead_notes to authenticated;
grant select on public.lead_signals to authenticated;
grant select on public.activity_feed to authenticated;

grant all on public.saved_views to authenticated;
grant select, insert on public.export_jobs to authenticated;

grant execute on function public.get_credit_balance(uuid) to authenticated;
grant execute on function public.unlock_leads_secure(uuid[]) to authenticated;
grant execute on function public.admin_grant_credits(uuid, int, text) to authenticated;
grant execute on function public.set_workflow_secure(uuid, public.workflow_status) to authenticated;
grant execute on function public.add_lead_note_secure(uuid, text) to authenticated;
grant execute on function public.create_entitled_export_job(uuid[]) to authenticated;
grant execute on function public.admin_set_feature_flag(text, boolean) to authenticated;
grant execute on function public.is_admin(uuid) to authenticated;

-- ============================================================
-- INITIAL DATA
-- ============================================================

-- Insert default feature flags
insert into public.feature_flags(key, enabled, description)
values
  ('detail_drawer', true, 'Enable detail drawer for leads'),
  ('export', true, 'Enable export functionality'),
  ('advanced_filters', true, 'Enable advanced filtering'),
  ('saved_views', true, 'Enable saved views'),
  ('signals', true, 'Enable intelligence signals')
on conflict (key) do nothing;

commit;
