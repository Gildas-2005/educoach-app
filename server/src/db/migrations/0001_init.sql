-- ============================================================================
-- Educoach — migration initiale (Postgres standard, hors Supabase Auth)
-- L'identité est portée par `users.password_hash` (bcrypt) et `refresh_tokens`.
-- gen_random_uuid() est natif depuis Postgres 13.
-- ============================================================================

create extension if not exists pgcrypto;

-- ---- Types énumérés ----
do $$ begin
  create type user_role as enum ('student','teacher','admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type account_status as enum ('pending','active','blocked');
exception when duplicate_object then null; end $$;

do $$ begin
  create type subscription_tier as enum ('discovery','premium','excellence');
exception when duplicate_object then null; end $$;

do $$ begin
  create type billing_cycle as enum ('monthly','yearly');
exception when duplicate_object then null; end $$;

do $$ begin
  create type payment_method as enum ('mtnMoMo','orangeMoney','visaCard');
exception when duplicate_object then null; end $$;

do $$ begin
  create type payment_status as enum ('pending','succeeded','failed','refunded');
exception when duplicate_object then null; end $$;

-- ---- Fonction utilitaire ----
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- ---- Utilisateurs & sessions ----
create table if not exists users (
  id            uuid primary key default gen_random_uuid(),
  full_name     text not null check (char_length(full_name) between 1 and 120),
  email         text not null check (char_length(email) between 3 and 320),
  password_hash text not null,
  role          user_role not null default 'student',
  status        account_status not null default 'active',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create unique index if not exists users_email_key on users (lower(email));

create table if not exists refresh_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists refresh_tokens_user_idx on refresh_tokens (user_id);

-- ---- Catalogue ----
create table if not exists filieres (
  id     uuid primary key default gen_random_uuid(),
  name   text not null check (char_length(name) between 1 and 160),
  domain text not null check (char_length(domain) between 1 and 120)
);

create table if not exists courses (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (char_length(title) between 1 and 160),
  summary    text check (char_length(summary) <= 1000),
  filiere_id uuid references filieres(id) on delete set null,
  teacher_id uuid references users(id) on delete set null,
  status     text not null default 'published' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now()
);
create index if not exists courses_filiere_idx on courses (filiere_id);
create index if not exists courses_teacher_idx on courses (teacher_id);

create table if not exists lessons (
  id               uuid primary key default gen_random_uuid(),
  course_id        uuid not null references courses(id) on delete cascade,
  title            text not null check (char_length(title) between 1 and 160),
  position         integer not null default 0 check (position >= 0),
  duration_minutes integer check (duration_minutes between 0 and 1440)
);
create index if not exists lessons_course_idx on lessons (course_id, position);

-- ---- Inscriptions & progression ----
create table if not exists enrollments (
  id          uuid primary key default gen_random_uuid(),
  course_id   uuid not null references courses(id) on delete cascade,
  student_id  uuid not null references users(id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  unique (course_id, student_id)
);
create index if not exists enrollments_student_idx on enrollments (student_id);

create table if not exists lesson_progress (
  lesson_id  uuid not null references lessons(id) on delete cascade,
  student_id uuid not null references users(id) on delete cascade,
  percent    integer not null default 0 check (percent between 0 and 100),
  completed  boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (lesson_id, student_id)
);

-- ---- Notes & devoirs ----
create table if not exists assignments (
  id        uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  title     text not null check (char_length(title) between 1 and 160),
  due_at    timestamptz
);
create index if not exists assignments_course_idx on assignments (course_id);

create table if not exists submissions (
  id            uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references assignments(id) on delete cascade,
  student_id    uuid not null references users(id) on delete cascade,
  content       text not null check (char_length(content) <= 20000),
  submitted_at  timestamptz not null default now(),
  unique (assignment_id, student_id)
);

create table if not exists grades (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references users(id) on delete cascade,
  course_id  uuid not null references courses(id) on delete cascade,
  teacher_id uuid references users(id) on delete set null,
  score      integer not null check (score between 0 and 100),
  comment    text check (char_length(comment) <= 500),
  created_at timestamptz not null default now()
);
create index if not exists grades_student_idx on grades (student_id);
create index if not exists grades_teacher_idx on grades (teacher_id);

-- ---- Chat ----
create table if not exists chat_rooms (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 120),
  kind       text not null default 'group' check (kind in ('group','direct')),
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists chat_members (
  room_id   uuid not null references chat_rooms(id) on delete cascade,
  user_id   uuid not null references users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists chat_messages (
  id         uuid primary key default gen_random_uuid(),
  room_id    uuid not null references chat_rooms(id) on delete cascade,
  sender_id  uuid not null references users(id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index if not exists chat_messages_room_idx on chat_messages (room_id, created_at);

-- ---- Abonnements & paiements (simulés) ----
create table if not exists subscriptions (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references users(id) on delete cascade,
  tier                subscription_tier not null,
  billing_cycle       billing_cycle not null,
  status              text not null default 'active' check (status in ('active','past_due','canceled')),
  current_period_end  timestamptz,
  created_at          timestamptz not null default now()
);
create index if not exists subscriptions_user_idx on subscriptions (user_id);

create table if not exists payments (
  id              uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references subscriptions(id) on delete cascade,
  user_id         uuid not null references users(id) on delete cascade,
  method          payment_method not null,
  amount          integer not null check (amount > 0),
  currency        text not null default 'XAF',
  status          payment_status not null default 'pending',
  masked_hint     text check (masked_hint is null or char_length(masked_hint) <= 16),
  created_at      timestamptz not null default now()
);
create index if not exists payments_user_idx on payments (user_id);

-- ---- Triggers updated_at ----
do $$ begin
  drop trigger if exists users_updated_at on users;
  create trigger users_updated_at before update on users
    for each row execute function set_updated_at();
end $$;

-- Note: aucun numéro de carte complet ni CVV n'est stocké (payments.masked_hint
-- uniquement, court). La confirmation d'un paiement réel devra passer par une
-- passerelle PCI DSS côté serveur, jamais dans le client.
