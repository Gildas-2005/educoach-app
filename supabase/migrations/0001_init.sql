-- =============================================================================
-- Educoach — schéma initial (Supabase / PostgreSQL)
-- Périmètre : identités & rôles, filières & cours, inscriptions, progression,
-- notes & devoirs, chat, abonnements & paiements.
--
-- Sécurité : RLS activé sur TOUTES les tables. L'accès client passe par la clé
-- `anon` (publique) + les policies ; la `service_role` (CI/migrations) bypasse
-- le RLS et ne doit JAMAIS être exposée au bundle.
-- Fonctions SECURITY DEFINER pour éviter la récursion de policy sur `profiles`.
-- =============================================================================

create extension if not exists "pgcrypto";

-- Schema applicatif pour les helpers SECURITY DEFINER (évite l'encombrement de public).
create schema if not exists app;

-- Trigger générique : maintient updated_at à jour.
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Types énumérés
-- ---------------------------------------------------------------------------
create type user_role       as enum ('student', 'teacher', 'admin');
create type account_status  as enum ('pending', 'active', 'blocked');
create type subscription_tier   as enum ('discovery', 'premium', 'excellence');
create type billing_cycle   as enum ('monthly', 'yearly');
create type payment_method  as enum ('mtnMoMo', 'orangeMoney', 'visaCard');
create type payment_status  as enum ('pending', 'succeeded', 'failed', 'refunded');

-- ---------------------------------------------------------------------------
-- Tronc commun : metadonnées auth.users -> profiles côté création
-- ---------------------------------------------------------------------------
create or replace function app.current_role()
returns user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function app.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(app.current_role() = 'admin', false);
$$;

create or replace function app.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, first_name, last_name, email, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name',  ''),
    new.email,
    coalesce((new.raw_user_meta_data ->> 'role')::user_role, 'student'),
    -- Les enseignants sont en attente de validation ; les étudiants actifs.
    case
      when coalesce((new.raw_user_meta_data ->> 'role')::user_role, 'student') = 'teacher'
        then 'pending'
      else 'active'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();

-- ---------------------------------------------------------------------------
-- Profils (identité + rôle)
-- ---------------------------------------------------------------------------
create table profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  first_name    text not null default '',
  last_name     text not null default '',
  email         text,
  phone         text,
  role          user_role not null default 'student',
  status        account_status not null default 'active',
  level         text,                       -- ex. "Licence 2"
  department    text,                       -- discipline enseignement
  matricule     text,
  avatar_url    text,
  accent        text,                        -- couleur d'accent hex
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create trigger set_updated_at before update on profiles
  for each row execute function handle_updated_at();

-- ---------------------------------------------------------------------------
-- Filières & cours
-- ---------------------------------------------------------------------------
create table filieres (
  code        text primary key,
  name        text not null,
  domain      text not null,
  color       text,
  description text,
  created_at  timestamptz not null default now()
);

create table courses (
  code         text primary key,
  filiere_code text not null references filieres (code) on delete cascade,
  title        text not null,
  teacher_id   uuid references profiles (id) on delete set null,
  credits      integer not null default 0,
  ects         integer not null default 0,
  semester     text,
  description  text,
  color        text,
  published    boolean not null default false,
  created_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Inscriptions (un étudiant suit un cours)
-- ---------------------------------------------------------------------------
create table enrollments (
  user_id    uuid not null references profiles (id) on delete cascade,
  course_code text not null references courses (code) on delete cascade,
  enrolled_at timestamptz not null default now(),
  primary key (user_id, course_code)
);

-- ---------------------------------------------------------------------------
-- Leçons & progression
-- ---------------------------------------------------------------------------
create table lessons (
  id          uuid primary key default gen_random_uuid(),
  course_code text not null references courses (code) on delete cascade,
  title       text not null,
  position    integer not null default 0,
  duration_s  integer not null default 0
);

create table lesson_progress (
  user_id     uuid not null references profiles (id) on delete cascade,
  lesson_id   uuid not null references lessons (id) on delete cascade,
  completed   boolean not null default false,
  score       integer,
  updated_at  timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

-- ---------------------------------------------------------------------------
-- Notes
-- ---------------------------------------------------------------------------
create table grades (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references profiles (id) on delete cascade,
  course_code text not null references courses (code) on delete cascade,
  note_sur20  numeric(4,2) not null check (note_sur20 >= 0 and note_sur20 <= 20),
  coef        integer not null default 1,
  term        text,
  graded_at   date not null default current_date,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Devoirs & rendus
-- ---------------------------------------------------------------------------
create table assignments (
  id          uuid primary key default gen_random_uuid(),
  course_code text not null references courses (code) on delete cascade,
  title       text not null,
  due_at      timestamptz,
  max_points  integer not null default 20
);

create table submissions (
  id            uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references assignments (id) on delete cascade,
  user_id       uuid not null references profiles (id) on delete cascade,
  submitted_at  timestamptz not null default now(),
  score         integer,
  feedback      text,
  unique (assignment_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Chat (rooms + membres + messages)
-- ---------------------------------------------------------------------------
create table chat_rooms (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  course_code text references courses (code) on delete cascade,
  created_at timestamptz not null default now()
);

create table chat_members (
  room_id  uuid not null references chat_rooms (id) on delete cascade,
  user_id  uuid not null references profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table chat_messages (
  id         bigint generated always as identity primary key,
  room_id    uuid not null references chat_rooms (id) on delete cascade,
  author_id  uuid not null references profiles (id) on delete cascade,
  body       text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Abonnements & paiements
-- ---------------------------------------------------------------------------
create table subscriptions (
  user_id                 uuid primary key references profiles (id) on delete cascade,
  tier                    subscription_tier not null default 'discovery',
  cycle                   billing_cycle not null default 'monthly',
  status                  payment_status not null default 'pending',
  renews_at               timestamptz,
  cancel_at_period_end    boolean not null default false,
  updated_at              timestamptz not null default now()
);

create trigger set_updated_at before update on subscriptions
  for each row execute function handle_updated_at();

-- Paiements : on ne stocke JAMAIS de PAN/CVV, uniquement un mask + référence.
create table payments (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references profiles (id) on delete cascade,
  amount_fcfa  integer not null check (amount_fcfa >= 0),
  method       payment_method not null,
  masked_hint  text,                        -- ex. "•••• 4242" / "+237 6•• •• •• 45"
  status       payment_status not null default 'pending',
  provider_ref text,                         -- référence renvoyée par la passerelle
  created_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Index
-- ---------------------------------------------------------------------------
create index idx_courses_filiere on courses (filiere_code);
create index idx_enrollments_user on enrollments (user_id);
create index idx_progress_user on lesson_progress (user_id);
create index idx_grades_user on grades (user_id);
create index idx_messages_room on chat_messages (room_id, created_at);
create index idx_payments_user on payments (user_id, created_at);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table profiles        enable row level security;
alter table filieres        enable row level security;
alter table courses         enable row level security;
alter table enrollments     enable row level security;
alter table lessons         enable row level security;
alter table lesson_progress enable row level security;
alter table grades          enable row level security;
alter table assignments     enable row level security;
alter table submissions     enable row level security;
alter table chat_rooms      enable row level security;
alter table chat_members    enable row level security;
alter table chat_messages   enable row level security;
alter table subscriptions   enable row level security;
alter table payments        enable row level security;

-- Profils : chacun lit/édite son profil ; un admin lit tout.
create policy "profiles: self read"  on profiles for select using (id = auth.uid() or app.is_admin());
create policy "profiles: self update" on profiles for update using (id = auth.uid());
create policy "profiles: admin read all" on profiles for select using (app.is_admin());

-- Catalogue pédagogique : lecture publique authentifiée ; écriture prof/admin.
create policy "filieres: read"  on filieres  for select using (auth.uid() is not null);
create policy "filieres: write" on filieres  for all    using (app.is_admin()) with check (app.is_admin());

create policy "courses: read"   on courses   for select using (auth.uid() is not null);
create policy "courses: write"  on courses   for all    using (app.is_admin() or app.current_role() = 'teacher')
                                                       with check (app.is_admin() or app.current_role() = 'teacher');

-- Inscriptions : l'étudiant gère les siennes ; prof/admin lisent la classe.
create policy "enrollments: self"     on enrollments for select using (user_id = auth.uid() or app.is_admin() or app.current_role() = 'teacher');
create policy "enrollments: self add" on enrollments for insert with check (user_id = auth.uid());
create policy "enrollments: self del" on enrollments for delete using (user_id = auth.uid());

-- Leçons : lecture pour tous les connectés ; écriture prof/admin.
create policy "lessons: read"  on lessons for select using (auth.uid() is not null);
create policy "lessons: write" on lessons for all   using (app.current_role() = 'teacher' or app.is_admin())
                                       with check (app.current_role() = 'teacher' or app.is_admin());

-- Progression : strictement propre à l'étudiant.
create policy "progress: own"     on lesson_progress for select using (user_id = auth.uid());
create policy "progress: own upsert" on lesson_progress for insert with check (user_id = auth.uid());
create policy "progress: own update" on lesson_progress for update using (user_id = auth.uid());

-- Notes : l'étudiant lit les siennes ; prof/admin écrivent.
create policy "grades: own read" on grades for select using (user_id = auth.uid() or app.is_admin() or app.current_role() = 'teacher');
create policy "grades: staff write" on grades for all  using (app.current_role() = 'teacher' or app.is_admin())
                                       with check (app.current_role() = 'teacher' or app.is_admin());

-- Devoirs : lecture connectée ; écriture prof/admin.
create policy "assignments: read" on assignments for select using (auth.uid() is not null);
create policy "assignments: write" on assignments for all   using (app.current_role() = 'teacher' or app.is_admin())
                                       with check (app.current_role() = 'teacher' or app.is_admin());

-- Rendus : l'étudiant soumet et lit les siens ; prof lit/corrige.
create policy "submissions: own read" on submissions for select using (user_id = auth.uid() or app.current_role() = 'teacher' or app.is_admin());
create policy "submissions: own insert" on submissions for insert with check (user_id = auth.uid());
create policy "submissions: staff grade" on submissions for update using (app.current_role() = 'teacher' or app.is_admin());

-- Chat : membres seulement.
create policy "rooms: read"    on chat_rooms for select using (auth.uid() is not null);
create policy "rooms: write"   on chat_rooms for all    using (app.is_admin() or app.current_role() = 'teacher')
                                       with check (app.is_admin() or app.current_role() = 'teacher');
create policy "members: read"  on chat_members for select using (user_id = auth.uid() or app.is_admin());
create policy "members: join"  on chat_members for insert with check (user_id = auth.uid());
create policy "messages: room" on chat_messages for select using (
  exists (select 1 from chat_members m where m.room_id = chat_messages.room_id and m.user_id = auth.uid())
  or app.is_admin()
);
create policy "messages: send" on chat_messages for insert with check (
  author_id = auth.uid()
  and exists (select 1 from chat_members m where m.room_id = chat_messages.room_id and m.user_id = auth.uid())
);

-- Abonnements & paiements : propre à l'utilisateur (admin lit tout).
create policy "subs: own"      on subscriptions for select using (user_id = auth.uid() or app.is_admin());
create policy "subs: own write" on subscriptions for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "payments: own"  on payments for select using (user_id = auth.uid() or app.is_admin());
-- Insertion paiement : seulement son propre compte (la confirmation réelle se fait
-- côté serveur via une Edge Function avec la service_role, jamais depuis le client).
create policy "payments: own insert" on payments for insert with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Realtime (chat)
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table chat_messages;
