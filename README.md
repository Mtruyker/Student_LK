# student_cabinet_flutter_app

Flutter-приложение личного кабинета студента, администратора и преподавателя.
Текущая версия использует **Supabase** как основной backend для Auth, PostgreSQL и RLS.

## Стек
- Frontend: Flutter + Provider
- Backend: Supabase Auth + Postgres + Row Level Security
- Legacy backend: папка `backend/` сохранена как архив и подключается только через явный флаг

## Быстрый старт

### 1. Создайте проект в Supabase
1. Создайте новый проект на [supabase.com](https://supabase.com).
2. Откройте `SQL Editor`.
3. Выполните SQL из файла [SUPABASE_MIGRATION.md](./SUPABASE_MIGRATION.md).

### 2. Запускайте приложение только с env-конфигом

В проекте больше нет зашитых `SUPABASE_URL` и `SUPABASE_ANON_KEY`.
Их нужно передавать через `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Для admin/teacher entrypoint используется тот же подход:

```bash
flutter run -t lib/main_admin.dart \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

flutter run -t lib/main_teacher.dart \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Если не передать переменные, приложение завершится с ошибкой bootstrap-конфигурации.

## Режимы backend

### Основной режим

По умолчанию проект работает через Supabase:

```bash
--dart-define=USE_SUPABASE=true
```

Этот флаг можно не указывать, потому что он включен по умолчанию.

### Legacy API

Старый backend включается только явно:

```bash
flutter run \
  --dart-define=USE_SUPABASE=false \
  --dart-define=ENABLE_LEGACY_API=true \
  --dart-define=API_BASE_URL=http://localhost:8080
```

Для admin/teacher legacy-режим работает так же.

### Demo mode

Demo-режим для студента тоже включается только явно:

```bash
flutter run \
  --dart-define=USE_SUPABASE=false \
  --dart-define=ENABLE_DEMO_MODE=true
```

Важно: `demo` и `legacy API` больше не включаются автоматически. Это сделано специально, чтобы production-сборка не откатывалась на небезопасный fallback.

## Роли

### Главное правило

Роли теперь хранятся в `auth.users.raw_app_meta_data`, а не в `user_metadata`.
RLS и клиентская проверка ролей опираются именно на `app_metadata`.

### Студент
- Регистрируется прямо в приложении.
- При регистрации приложение передает роль в `user_metadata`, а SQL-триггер переносит ее в `app_metadata`.
- После регистрации создается запись в таблице `students`.

### Преподаватель
- Может зарегистрироваться в приложении преподавателя.
- SQL-триггер записывает `role = teacher` в `app_metadata`.
- После регистрации создается запись в таблице `teachers`.

### Администратор
- Создается как обычный пользователь Supabase Auth.
- Затем роль назначается через `SQL Editor`.

Пример назначения администратора по e-mail:

```sql
update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
where email = 'admin@example.com';
```

После смены роли нужно полностью выйти из приложения и войти заново, чтобы получить новый JWT.

## Деплой как PWA

Проект можно задеплоить как **Progressive Web App** — студенты смогут добавить на главный экран iPhone/Android через кнопку «Поделиться» в Safari или «Установить» в Chrome.

**Хостинг**: GitHub Pages (бесплатно, автодеплой, HTTPS)

Подробная инструкция: [GITHUB_PAGES_SETUP.md](./GITHUB_PAGES_SETUP.md)

### Быстрый старт:

1. Добавить secrets в GitHub:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

2. Включить GitHub Pages:
   - Settings → Pages → Source: **GitHub Actions**

3. Запушить в main:
   ```bash
   git push origin main
   ```

4. Приложение доступно: `https://mtruyker.github.io/Student_LK/`

5. Настроить в Supabase Dashboard → Authentication → URL Configuration:
   ```
   Site URL: https://mtruyker.github.io/Student_LK/
   Redirect URLs: https://mtruyker.github.io/Student_LK/
   ```

## Что хранится в базе

Проект использует таблицы:
- `students`
- `teachers`
- `grades`
- `schedule_lessons`
- `documents`
- `announcements`
- `certificate_requests`
- `curator_messages`

## Важные замечания

- Администратор редактирует профиль студента и расписание, но **не меняет `auth.users.email` из приложения**.
- Для связи студент -> куратор -> преподаватель используется поле `students.curator_teacher_id`.
- RLS-политики и триггеры полностью описаны в [SUPABASE_MIGRATION.md](./SUPABASE_MIGRATION.md).
- Для production не используйте `ENABLE_DEMO_MODE=true`.

## Проверка

После установки зависимостей можно прогнать:

```bash
flutter analyze
flutter test
```

## Integration Tests

`integration_test/` теперь ориентирован на реальный Supabase flow по ролям:
- `student_login_flow_test.dart`
- `admin_login_flow_test.dart`
- `teacher_login_flow_test.dart`

Тесты по умолчанию автоматически `skip`, если не переданы обязательные `dart-define`.

Для запуска student login flow:

```bash
flutter test integration_test/student_login_flow_test.dart -d windows \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=TEST_STUDENT_EMAIL=student@example.com \
  --dart-define=TEST_STUDENT_PASSWORD=student-password
```

Для запуска admin login flow:

```bash
flutter test integration_test/admin_login_flow_test.dart -d windows \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=TEST_ADMIN_EMAIL=admin@example.com \
  --dart-define=TEST_ADMIN_PASSWORD=admin-password
```

Для запуска teacher login flow:

```bash
flutter test integration_test/teacher_login_flow_test.dart -d windows \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=TEST_TEACHER_EMAIL=teacher@example.com \
  --dart-define=TEST_TEACHER_PASSWORD=teacher-password
```

При необходимости можно заменить `-d windows` на другой поддерживаемый device, например `-d chrome`.

Старый `register_flow_test.dart` удален намеренно: он был завязан на legacy/docker backend и больше не отражал production-маршрут проекта.

## Stage 2

- Optional password recovery redirect:

```bash
--dart-define=SUPABASE_PASSWORD_RESET_REDIRECT_URL=YOUR_APP_RESET_URL
```

- Stage 2 flows now covered in code:
  - student sends certificate requests and sees document statuses;
  - admin processes `certificate_requests`, updates their statuses and manages student documents;
  - teacher can move curator messages into work and reply from the dashboard;
  - teacher replies are shown to the student as cabinet updates.

Теперь запуск из PowerShell совсем короткий:

.\tool\run_student.ps1
.\tool\run_admin.ps1
.\tool\run_teacher.ps1
Если захочешь запускать не windows, а например chrome, можно так:

.\tool\run_student.ps1 -Device chrome
.\tool\run_admin.ps1 -Device chrome
.\tool\run_teacher.ps1 -Device chrome
