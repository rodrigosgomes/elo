-- Elo - Supabase schema bootstrap
-- Run this script inside Supabase SQL editor.

-- Some Supabase instances run PostgreSQL versions where
-- "create type if not exists" isn't supported. Use procedural guard.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'asset_category_enum') then
    create type asset_category_enum as enum ('IMOVEIS','VEICULOS','FINANCEIRO','CRIPTO','DIVIDAS');
  end if;
  if not exists (select 1 from pg_type where typname = 'asset_status_enum') then
    create type asset_status_enum as enum ('ACTIVE','PENDING_REVIEW','ARCHIVED');
  end if;
  if not exists (select 1 from pg_type where typname = 'document_status_enum') then
    create type document_status_enum as enum ('PENDING_UPLOAD','UPLOADING','ENCRYPTED','AVAILABLE','FAILED');
  end if;
  if not exists (select 1 from pg_type where typname = 'guardian_status_enum') then
    create type guardian_status_enum as enum ('INVITED','VERIFIED','BLOCKED','REVOKED');
  end if;
  if not exists (select 1 from pg_type where typname = 'guardian_event_type_enum') then
    create type guardian_event_type_enum as enum ('INVITATION_SENT','CONTACT_CONFIRMED','REMOVED','TEST_SIMULATED');
  end if;
  if not exists (select 1 from pg_type where typname = 'access_scope_enum') then
    create type access_scope_enum as enum ('TOTAL','DOCUMENTOS');
  end if;
  if not exists (select 1 from pg_type where typname = 'emergency_state_enum') then
    create type emergency_state_enum as enum ('IDLE','MONITORING','ALERT_SENT','AWAITING_RESPONSE','RELEASING','RESOLVED');
  end if;
  if not exists (select 1 from pg_type where typname = 'emergency_event_type_enum') then
    create type emergency_event_type_enum as enum ('DETECCAO','AVISO_GUARDIAO','VERIFICACAO_VIDA','LIBERACAO','TESTE_SIMULADO');
  end if;
  if not exists (select 1 from pg_type where typname = 'action_preference_enum') then
    create type action_preference_enum as enum ('EXCLUIR','MEMORIALIZAR','TRANSFERIR');
  end if;
  if not exists (select 1 from pg_type where typname = 'subscription_cycle_enum') then
    create type subscription_cycle_enum as enum ('MONTHLY','QUARTERLY','YEARLY','OTHER');
  end if;
  if not exists (select 1 from pg_type where typname = 'life_check_channel_enum') then
    create type life_check_channel_enum as enum ('PUSH','EMAIL','SMS');
  end if;
  if not exists (select 1 from pg_type where typname = 'life_check_status_enum') then
    create type life_check_status_enum as enum ('SCHEDULED','SENT','RESPONDED','EXPIRED','FAILED');
  end if;
  if not exists (select 1 from pg_type where typname = 'capsule_type_enum') then
    create type capsule_type_enum as enum ('TEXT','AUDIO','VIDEO');
  end if;
  if not exists (select 1 from pg_type where typname = 'capsule_status_enum') then
    create type capsule_status_enum as enum ('DRAFT','SCHEDULED','RELEASED','CANCELLED');
  end if;
end $$;

-- =============================
-- TABLES
-- =============================

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  full_name text not null,
  avatar_url text,
  zero_knowledge_ready boolean not null default false,
  two_factor_enforced boolean not null default false,
  onboarding_stage text not null default 'start',
  headline_status text,
  trust_header_dismissed_at timestamptz,
  deleted_at timestamptz
);

create table if not exists user_keys (
  id bigserial primary key,
  user_id uuid not null unique references profiles(id) on delete cascade,
  encrypted_private_key text not null,
  recovery_seed_hint text,
  step_up_method text not null,
  secure_storage_provider text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists device_sessions (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  device_info jsonb,
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  push_token text
);

create table if not exists trust_events (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  event_type text not null,
  description text not null,
  created_at timestamptz not null default now(),
  metadata jsonb
);

create table if not exists user_checklists (
  id bigserial primary key,
  user_id uuid not null unique references profiles(id) on delete cascade,
  has_asset boolean not null default false,
  has_guardian boolean not null default false,
  life_check_enabled boolean not null default false,
  protection_ring_score integer not null default 0 check (protection_ring_score between 0 and 100),
  updated_at timestamptz not null default now()
);

create table if not exists assets (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  category asset_category_enum not null,
  title text not null,
  description text,
  value_estimated numeric(14,2),
  value_currency text default 'BRL',
  value_unknown boolean not null default false,
  ownership_percentage numeric(5,2) not null default 100,
  has_proof boolean not null default false,
  status asset_status_enum not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists asset_documents (
  id bigserial primary key,
  asset_id bigint not null references assets(id) on delete cascade,
  storage_path text not null,
  file_type text,
  encrypted_checksum text not null,
  uploaded_at timestamptz not null default now()
);

create table if not exists documents (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text,
  storage_path text not null,
  size_bytes bigint,
  mime_type text,
  tags text[] not null default array[]::text[],
  status document_status_enum not null default 'PENDING_UPLOAD',
  expires_at timestamptz,
  encrypted_at timestamptz,
  checksum text,
  last_accessed_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists document_upload_queue (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  document_id bigint not null references documents(id) on delete cascade,
  retry_count integer not null default 0,
  last_retry_at timestamptz,
  network_policy text,
  status document_status_enum not null default 'PENDING_UPLOAD',
  max_retries integer not null default 3 check (max_retries <= 3),
  retry_reason text,
  offline_blob_checksum text,
  priority smallint not null default 0
);

create table if not exists emergency_protocols (
  id bigserial primary key,
  user_id uuid not null unique references profiles(id) on delete cascade,
  inactivity_timer_days integer not null default 60 check (inactivity_timer_days in (30,60,90)),
  life_check_channel life_check_channel_enum not null default 'PUSH',
  step_up_required boolean not null default true,
  status emergency_state_enum not null default 'MONITORING',
  last_check_sent_at timestamptz,
  last_activity_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists guardians (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  email text not null,
  phone text,
  verification_code text,
  verified_at timestamptz,
  status guardian_status_enum not null default 'INVITED',
  access_scope access_scope_enum not null default 'DOCUMENTOS',
  invited_at timestamptz not null default now(),
  preferred_channel life_check_channel_enum not null default 'EMAIL',
  unique(user_id, email)
);

create table if not exists guardian_events (
  id bigserial primary key,
  guardian_id bigint not null references guardians(id) on delete cascade,
  event_type guardian_event_type_enum not null,
  metadata jsonb,
  created_at timestamptz not null default now(),
  is_test boolean not null default false
);

create table if not exists life_checks (
  id bigserial primary key,
  protocol_id bigint not null references emergency_protocols(id) on delete cascade,
  guardian_id bigint references guardians(id) on delete set null,
  scheduled_at timestamptz not null,
  response_received_at timestamptz,
  status life_check_status_enum not null default 'SCHEDULED',
  channel life_check_channel_enum not null,
  response_channel life_check_channel_enum
);

create table if not exists emergency_events (
  id bigserial primary key,
  protocol_id bigint references emergency_protocols(id) on delete cascade,
  guardian_id bigint references guardians(id) on delete set null,
  event_type emergency_event_type_enum not null,
  payload jsonb,
  occurred_at timestamptz not null default now(),
  is_test boolean not null default false
);

create table if not exists master_credentials (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  encrypted_payload text not null,
  second_factor_hint text,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists legacy_accounts (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  provider_name text not null,
  account_identifier text,
  credential_type text,
  action_preference action_preference_enum not null,
  notes text,
  requires_step_up boolean not null default true,
  linked_credential_id bigint references master_credentials(id),
  verified_at timestamptz,
  verification_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists subscriptions (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  service_name text not null,
  amount numeric(12,2),
  currency text default 'BRL',
  billing_cycle subscription_cycle_enum not null default 'MONTHLY',
  next_charge_at timestamptz,
  cancel_on_emergency boolean not null default false,
  notes text,
  cancelled_at timestamptz,
  cancelled_reason text
);

create table if not exists medical_directives (
  id bigserial primary key,
  user_id uuid not null unique references profiles(id) on delete cascade,
  presets_json jsonb not null,
  legal_document_path text,
  last_signed_at timestamptz,
  updated_at timestamptz not null default now(),
  updated_by_user_id uuid references profiles(id),
  deleted_at timestamptz
);

create table if not exists funeral_preferences (
  id bigserial primary key,
  user_id uuid not null unique references profiles(id) on delete cascade,
  ceremony_type text,
  music_playlist text,
  notes text,
  contact_person text,
  updated_at timestamptz not null default now(),
  updated_by_user_id uuid references profiles(id),
  deleted_at timestamptz
);

create table if not exists capsule_entries (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  capsule_type capsule_type_enum not null,
  storage_path text,
  message_body text,
  recipient_name text not null,
  recipient_email text,
  recipient_phone text,
  release_at timestamptz,
  status capsule_status_enum not null default 'DRAFT',
  linked_guardian_id bigint references guardians(id) on delete set null,
  allow_offline_draft boolean not null default true,
  download_limit integer not null default 1,
  last_notified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists capsule_release_events (
  id bigserial primary key,
  capsule_id bigint not null references capsule_entries(id) on delete cascade,
  event_type text not null,
  event_payload jsonb,
  occurred_at timestamptz not null default now()
);

create table if not exists kpi_metrics (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  metric_type text not null,
  metric_value numeric(10,2),
  recorded_at timestamptz not null default now(),
  metadata jsonb
);

create table if not exists step_up_events (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  event_type text not null,
  success boolean not null default false,
  factor_used text,
  related_resource text,
  metadata jsonb,
  occurred_at timestamptz not null default now()
);

-- =============================
-- INDEXES
-- =============================

create index if not exists idx_assets_user_category on assets (user_id, category);
create index if not exists idx_documents_user_status on documents (user_id, status);
create index if not exists idx_document_queue_user_status on document_upload_queue (user_id, status);
create index if not exists idx_capsules_user_release on capsule_entries (user_id, release_at);
create index if not exists idx_subscriptions_user_cancel on subscriptions (user_id, cancel_on_emergency);
create index if not exists idx_kpi_metrics_user_recorded on kpi_metrics (user_id, recorded_at desc);
create index if not exists idx_trust_events_user_created on trust_events (user_id, created_at desc);
create index if not exists idx_guardians_user_status on guardians (user_id, status);
create index if not exists idx_legacy_accounts_user on legacy_accounts (user_id);
create index if not exists idx_master_credentials_user on master_credentials (user_id);
create index if not exists idx_life_checks_protocol_status on life_checks (protocol_id, status);

-- =============================
-- ROW LEVEL SECURITY & POLICIES
-- =============================

do $$
declare
  r record;
begin
  for r in select tablename from pg_tables where schemaname = 'public' and tablename in (
    'profiles','user_keys','device_sessions','trust_events','user_checklists','assets','asset_documents','documents',
    'document_upload_queue','emergency_protocols','guardians','guardian_events','life_checks','emergency_events',
    'legacy_accounts','master_credentials','subscriptions','medical_directives','funeral_preferences',
    'capsule_entries','capsule_release_events','kpi_metrics','step_up_events'
  ) loop
    execute format('alter table %I enable row level security;', r.tablename);
  end loop;
end $$;

-- Supabase currently doesn't support "create policy if not exists".
-- Drop before create to keep script idempotent.
drop policy if exists profiles_owner on profiles;
create policy profiles_owner on profiles
  for all using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists user_keys_owner on user_keys;
create policy user_keys_owner on user_keys
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists device_sessions_owner on device_sessions;
create policy device_sessions_owner on device_sessions
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists trust_events_owner on trust_events;
create policy trust_events_owner on trust_events
  for insert with check (auth.uid() = user_id);
drop policy if exists trust_events_select on trust_events;
create policy trust_events_select on trust_events
  for select using (auth.uid() = user_id);

drop policy if exists user_checklists_owner on user_checklists;
create policy user_checklists_owner on user_checklists
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists assets_owner on assets;
create policy assets_owner on assets
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists asset_documents_owner on asset_documents;
create policy asset_documents_owner on asset_documents
  for all using (
    exists (
      select 1 from assets a
      where a.id = asset_documents.asset_id and auth.uid() = a.user_id
    )
  )
  with check (
    exists (
      select 1 from assets a
      where a.id = asset_documents.asset_id and auth.uid() = a.user_id
    )
  );

drop policy if exists documents_owner on documents;
create policy documents_owner on documents
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists document_queue_owner on document_upload_queue;
create policy document_queue_owner on document_upload_queue
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists emergency_protocols_owner on emergency_protocols;
create policy emergency_protocols_owner on emergency_protocols
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists guardians_owner on guardians;
create policy guardians_owner on guardians
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists guardian_events_owner on guardian_events;
create policy guardian_events_owner on guardian_events
  for all using (
    exists (
      select 1 from guardians g
      where g.id = guardian_events.guardian_id and auth.uid() = g.user_id
    )
  )
  with check (
    exists (
      select 1 from guardians g
      where g.id = guardian_events.guardian_id and auth.uid() = g.user_id
    )
  );

drop policy if exists life_checks_owner on life_checks;
create policy life_checks_owner on life_checks
  for all using (
    exists (
      select 1 from emergency_protocols ep
      where ep.id = life_checks.protocol_id and auth.uid() = ep.user_id
    )
  )
  with check (
    exists (
      select 1 from emergency_protocols ep
      where ep.id = life_checks.protocol_id and auth.uid() = ep.user_id
    )
  );

drop policy if exists emergency_events_owner on emergency_events;
create policy emergency_events_owner on emergency_events
  for all using (
    exists (
      select 1 from emergency_protocols ep
      where ep.id = emergency_events.protocol_id and auth.uid() = ep.user_id
    )
  )
  with check (
    exists (
      select 1 from emergency_protocols ep
      where ep.id = emergency_events.protocol_id and auth.uid() = ep.user_id
    )
  );

drop policy if exists legacy_accounts_owner on legacy_accounts;
create policy legacy_accounts_owner on legacy_accounts
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists master_credentials_owner on master_credentials;
create policy master_credentials_owner on master_credentials
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists subscriptions_owner on subscriptions;
create policy subscriptions_owner on subscriptions
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists medical_directives_owner on medical_directives;
create policy medical_directives_owner on medical_directives
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists funeral_preferences_owner on funeral_preferences;
create policy funeral_preferences_owner on funeral_preferences
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists capsule_entries_owner on capsule_entries;
create policy capsule_entries_owner on capsule_entries
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists capsule_release_events_owner on capsule_release_events;
create policy capsule_release_events_owner on capsule_release_events
  for all using (
    exists (
      select 1 from capsule_entries ce
      where ce.id = capsule_release_events.capsule_id and auth.uid() = ce.user_id
    )
  )
  with check (
    exists (
      select 1 from capsule_entries ce
      where ce.id = capsule_release_events.capsule_id and auth.uid() = ce.user_id
    )
  );

drop policy if exists kpi_metrics_owner on kpi_metrics;
create policy kpi_metrics_owner on kpi_metrics
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists step_up_events_owner on step_up_events;
create policy step_up_events_owner on step_up_events
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.email, 'Novo usuário'))
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
  
-- =============================
-- SEED HELPERS (OPTIONAL)
-- =============================
-- Example seed for testing; comment out if running in production.
-- insert into profiles (id, full_name)
-- values ('00000000-0000-0000-0000-000000000000', 'Usuario Dev')
-- on conflict (id) do nothing;
