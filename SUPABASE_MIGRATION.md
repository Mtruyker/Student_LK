# Полная схема Supabase

Выполните этот SQL целиком в `Supabase -> SQL Editor`.
Скрипт создает таблицы, триггеры, backfill и RLS-политики для всех ролей приложения.

Главное изменение этой версии: роли хранятся в `auth.users.raw_app_meta_data`, а не в `raw_user_meta_data`.

```sql
create extension if not exists pgcrypto;

create table if not exists public.teachers (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  first_name text,
  group_name text,
  student_identifier text unique,
  phone text,
  curator text default 'Не назначен',
  curator_teacher_id uuid references public.teachers(id) on delete set null,
  attendance double precision not null default 0 check (attendance between 0 and 1),
  completed_assignments integer not null default 0,
  total_assignments integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject text not null,
  grade integer not null,
  progress double precision not null default 0,
  teacher text,
  completed_tasks integer not null default 0,
  total_tasks integer not null default 0,
  date_label text,
  created_at timestamptz not null default now()
);

create table if not exists public.schedule_lessons (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  teacher_id uuid references public.teachers(id) on delete set null,
  weekday integer not null check (weekday between 1 and 7),
  time text not null,
  subject text not null,
  room text,
  teacher text,
  lesson_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  title text not null,
  status text not null default 'Готов',
  updated_at_label text,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  title text not null,
  description text not null,
  date_label text,
  created_at timestamptz not null default now()
);

create table if not exists public.certificate_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  type text not null,
  comment text not null default '',
  status text not null default 'new',
  created_at timestamptz not null default now()
);

create table if not exists public.curator_messages (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  curator_teacher_id uuid references public.teachers(id) on delete set null,
  message text not null,
  status text not null default 'new',
  teacher_reply text not null default '',
  teacher_reply_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.students
  add column if not exists curator_teacher_id uuid references public.teachers(id) on delete set null;

alter table public.schedule_lessons
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

alter table public.curator_messages
  add column if not exists curator_teacher_id uuid references public.teachers(id) on delete set null;

alter table public.curator_messages
  add column if not exists status text not null default 'new';

alter table public.curator_messages
  add column if not exists teacher_reply text not null default '';

alter table public.curator_messages
  add column if not exists teacher_reply_at timestamptz;

create index if not exists idx_students_curator_teacher_id
  on public.students(curator_teacher_id);

create index if not exists idx_students_group_name
  on public.students(group_name);

create index if not exists idx_grades_student_id
  on public.grades(student_id);

create index if not exists idx_schedule_lessons_student_id
  on public.schedule_lessons(student_id);

create index if not exists idx_schedule_lessons_teacher_id
  on public.schedule_lessons(teacher_id);

create index if not exists idx_documents_student_id
  on public.documents(student_id);

create index if not exists idx_announcements_student_id
  on public.announcements(student_id);

create index if not exists idx_certificate_requests_student_id
  on public.certificate_requests(student_id);

create index if not exists idx_curator_messages_student_id
  on public.curator_messages(student_id);

create index if not exists idx_curator_messages_teacher_id
  on public.curator_messages(curator_teacher_id);

create or replace function public.auth_role()
returns text
language sql
stable
as $$
  select lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', ''));
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select public.auth_role() = 'admin';
$$;

create or replace function public.is_teacher()
returns boolean
language sql
stable
as $$
  select public.auth_role() = 'teacher';
$$;

create or replace function public.resolve_user_role(
  target_user_id uuid,
  app_metadata jsonb default '{}'::jsonb,
  user_metadata jsonb default '{}'::jsonb
)
returns text
language sql
stable
as $$
  select case
    when lower(coalesce(app_metadata ->> 'role', '')) in ('student', 'teacher', 'admin')
      then lower(app_metadata ->> 'role')
    when lower(coalesce(user_metadata ->> 'role', '')) in ('student', 'teacher', 'admin')
      then lower(user_metadata ->> 'role')
    when exists (
      select 1
      from public.teachers t
      where t.id = target_user_id
    ) then 'teacher'
    when exists (
      select 1
      from public.students s
      where s.id = target_user_id
    ) then 'student'
    else ''
  end;
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_students_updated_at on public.students;
create trigger set_students_updated_at
before update on public.students
for each row
execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  resolved_role text;
begin
  resolved_role := public.resolve_user_role(
    new.id,
    coalesce(new.raw_app_meta_data, '{}'::jsonb),
    coalesce(new.raw_user_meta_data, '{}'::jsonb)
  );

  if resolved_role = '' then
    resolved_role := 'student';
  end if;

  update auth.users
  set raw_app_meta_data =
    coalesce(raw_app_meta_data, '{}'::jsonb) ||
    jsonb_build_object('role', resolved_role)
  where id = new.id;

  if resolved_role = 'teacher' then
    insert into public.teachers (id, email, full_name)
    values (
      new.id,
      new.email,
      coalesce(new.raw_user_meta_data ->> 'fullName', 'Преподаватель')
    )
    on conflict (id) do nothing;
  elsif resolved_role = 'admin' then
    null;
  else
    insert into public.students (
      id,
      email,
      full_name,
      first_name,
      group_name,
      student_identifier,
      phone,
      curator
    )
    values (
      new.id,
      new.email,
      coalesce(new.raw_user_meta_data ->> 'fullName', 'Студент'),
      coalesce(
        new.raw_user_meta_data ->> 'firstName',
        split_part(
          coalesce(new.raw_user_meta_data ->> 'fullName', 'Студент'),
          ' ',
          1
        )
      ),
      coalesce(new.raw_user_meta_data ->> 'group', 'Не указана'),
      'STU-' || upper(substr(replace(new.id::text, '-', ''), 1, 8)),
      coalesce(new.raw_user_meta_data ->> 'phone', ''),
      'Не назначен'
    )
    on conflict (id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

update public.students
set student_identifier = coalesce(
  student_identifier,
  'STU-' || upper(substr(replace(id::text, '-', ''), 1, 8))
)
where student_identifier is null;

update public.students s
set curator_teacher_id = t.id
from public.teachers t
where s.curator_teacher_id is null
  and s.curator = t.full_name;

update public.schedule_lessons sl
set teacher_id = t.id
from public.teachers t
where sl.teacher_id is null
  and sl.teacher = t.full_name;

update public.curator_messages cm
set curator_teacher_id = s.curator_teacher_id
from public.students s
where cm.student_id = s.id
  and cm.curator_teacher_id is null
  and s.curator_teacher_id is not null;

update public.curator_messages
set status = 'answered'
where coalesce(teacher_reply, '') <> ''
  and status = 'new';

update auth.users u
set raw_app_meta_data =
  coalesce(u.raw_app_meta_data, '{}'::jsonb) ||
  jsonb_build_object(
    'role',
    public.resolve_user_role(
      u.id,
      coalesce(u.raw_app_meta_data, '{}'::jsonb),
      coalesce(u.raw_user_meta_data, '{}'::jsonb)
    )
  )
where public.resolve_user_role(
  u.id,
  coalesce(u.raw_app_meta_data, '{}'::jsonb),
  coalesce(u.raw_user_meta_data, '{}'::jsonb)
) <> '';

alter table public.teachers enable row level security;
alter table public.students enable row level security;
alter table public.grades enable row level security;
alter table public.schedule_lessons enable row level security;
alter table public.documents enable row level security;
alter table public.announcements enable row level security;
alter table public.certificate_requests enable row level security;
alter table public.curator_messages enable row level security;

drop policy if exists teachers_admin_all on public.teachers;
create policy teachers_admin_all
on public.teachers
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists teachers_select_self on public.teachers;
create policy teachers_select_self
on public.teachers
for select
using (auth.uid() = id);

drop policy if exists students_admin_all on public.students;
create policy students_admin_all
on public.students
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists students_select_self on public.students;
create policy students_select_self
on public.students
for select
using (auth.uid() = id);

drop policy if exists students_update_self on public.students;
create policy students_update_self
on public.students
for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists students_select_assigned_teacher on public.students;
create policy students_select_assigned_teacher
on public.students
for select
using (
  public.is_teacher()
  and (
    curator_teacher_id = auth.uid()
    or exists (
      select 1
      from public.schedule_lessons sl
      where sl.student_id = students.id
        and sl.teacher_id = auth.uid()
    )
  )
);

drop policy if exists grades_admin_all on public.grades;
create policy grades_admin_all
on public.grades
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists grades_select_own on public.grades;
create policy grades_select_own
on public.grades
for select
using (student_id = auth.uid());

drop policy if exists schedule_lessons_admin_all on public.schedule_lessons;
create policy schedule_lessons_admin_all
on public.schedule_lessons
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists schedule_lessons_select_own_student on public.schedule_lessons;
create policy schedule_lessons_select_own_student
on public.schedule_lessons
for select
using (student_id = auth.uid());

drop policy if exists schedule_lessons_select_teacher on public.schedule_lessons;
create policy schedule_lessons_select_teacher
on public.schedule_lessons
for select
using (teacher_id = auth.uid());

drop policy if exists documents_admin_all on public.documents;
create policy documents_admin_all
on public.documents
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists documents_select_own on public.documents;
create policy documents_select_own
on public.documents
for select
using (student_id = auth.uid());

drop policy if exists documents_insert_own on public.documents;
create policy documents_insert_own
on public.documents
for insert
with check (student_id = auth.uid());

drop policy if exists announcements_admin_all on public.announcements;
create policy announcements_admin_all
on public.announcements
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists announcements_select_own on public.announcements;
create policy announcements_select_own
on public.announcements
for select
using (student_id = auth.uid());

drop policy if exists announcements_insert_own on public.announcements;
create policy announcements_insert_own
on public.announcements
for insert
with check (student_id = auth.uid());

drop policy if exists certificate_requests_admin_all on public.certificate_requests;
create policy certificate_requests_admin_all
on public.certificate_requests
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists certificate_requests_select_own on public.certificate_requests;
create policy certificate_requests_select_own
on public.certificate_requests
for select
using (student_id = auth.uid());

drop policy if exists certificate_requests_insert_own on public.certificate_requests;
create policy certificate_requests_insert_own
on public.certificate_requests
for insert
with check (student_id = auth.uid());

drop policy if exists curator_messages_admin_all on public.curator_messages;
create policy curator_messages_admin_all
on public.curator_messages
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists curator_messages_select_own_student on public.curator_messages;
create policy curator_messages_select_own_student
on public.curator_messages
for select
using (student_id = auth.uid());

drop policy if exists curator_messages_insert_own_student on public.curator_messages;
create policy curator_messages_insert_own_student
on public.curator_messages
for insert
with check (student_id = auth.uid());

drop policy if exists curator_messages_select_teacher on public.curator_messages;
create policy curator_messages_select_teacher
on public.curator_messages
for select
using (curator_teacher_id = auth.uid());

drop policy if exists curator_messages_update_teacher on public.curator_messages;
create policy curator_messages_update_teacher
on public.curator_messages
for update
using (curator_teacher_id = auth.uid())
with check (curator_teacher_id = auth.uid());
```

## Назначение администратора

Теперь роль администратора нужно назначать в `app_metadata`.
Сделать это можно прямо в `SQL Editor`:

```sql
update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
where email = 'admin@example.com';
```

После этого нужно заново войти в приложение, чтобы JWT обновился.
