# Task

## Обновление от 2026-03-05 (windows-admin)

Сделано:

- Добавлен Windows target в Flutter-проект (`windows/` runner через `flutter create --platforms=windows .`).
- Реализован отдельный entrypoint админ-приложения: `lib/main_admin.dart`.
- Добавлен модуль администратора в Flutter:
  - `lib/admin/models/admin_models.dart`
  - `lib/admin/repositories/admin_repository.dart`
  - `lib/admin/state/admin_app_state.dart`
  - `lib/admin/pages/admin_login_page.dart`
  - `lib/admin/pages/admin_dashboard_page.dart`
- Админский UI поддерживает:
  - вход администратора
  - список студентов
  - редактирование профиля студента
  - редактирование расписания студента
  - импорт расписания из Excel (`.xlsx`) в форму расписания (в том числе сеточный формат по группам)
  - массовое применение расписания ко всем студентам через кнопку `Импорт всем` (по совпадению поля `Группа`)
- Расширен backend API:
  - `POST /admin/login`
  - `GET /admin/students`
  - `GET /admin/students/{id}`
  - `PUT /admin/students/{id}/profile`
  - `PUT /admin/students/{id}/schedule`
- Добавлены переменные окружения backend:
  - `ADMIN_EMAIL`
  - `ADMIN_PASSWORD`
- Добавлена авто-реконнекция к PostgreSQL в `PostgresStudentStore`, чтобы backend восстанавливался после кратковременного падения БД.

Проверено:

- `dart analyze` (backend) — без ошибок.
- `flutter analyze` (frontend) — без ошибок.
- `docker compose up --build -d backend` — backend успешно пересобран.
- Админский API (login/list/get/update profile/update schedule) — успешно.
- Регресс студенческого API (`register/login/cabinet`) — успешно.
- `flutter build windows -t lib/main_admin.dart --dart-define=API_BASE_URL=http://127.0.0.1:8080` — успешная сборка.

## Обновление от 2026-03-05 (продолжение)

Сделано после появления нового эмулятора:

- Integration test регистрации успешно пройден на Android:
  - `flutter test integration_test/register_flow_test.dart -d emulator-5554 ...`
  - результат: `All tests passed!`

Дополнительно закрыт пункт с проверкой `500` и устойчивостью backend:

- Подтверждено, что при остановке PostgreSQL backend отдает `500` (`Internal server error.`).
- Выявлен дефект: после возврата БД соединение в `PostgresStudentStore` оставалось закрытым до перезапуска backend-контейнера.
- Исправлено в `backend/lib/src/postgres_student_store.dart`:
  - добавлен авто-reconnect к PostgreSQL при ошибке `connection is not open` / `connection closed`;
  - добавлен повтор запроса после успешного reconnect;
  - добавлена синхронизация reconnect, чтобы не открывать несколько соединений параллельно.
- Проверка после правки:
  - `db down` -> `POST /auth/login` возвращает `500` (ожидаемо),
  - `db up` -> `POST /auth/login` снова `200` без перезапуска backend.
- `dart analyze` для `backend/` после изменений: `No issues found!`.
- Backend пересобран и поднят через `docker compose up --build -d backend`.

Статус кодировки:

- Подозрения на `Р...` подтверждены как артефакт вывода консоли без явного UTF-8.
- По проекту не найдено поврежденных строк в `.dart` файлах.

## Обновление от 2026-03-05

Сделано:

- Поднята служба `com.docker.service`, проверен статус контейнеров `backend` и `db`.
- Повторно проверен backend flow:
  - `POST /auth/register` -> `201` + `token` + `cabinet`
  - `POST /auth/login` -> `200` + `token`
  - `GET /student/cabinet` -> `200` + `profile`
- Проверены error-ответы backend:
  - невалидный JSON -> `400` (`Request body must be valid JSON.`)
  - неверные креды -> `401` (`Invalid credentials.`)
  - нет bearer token -> `401` (`Missing bearer token.`)
  - повторная регистрация -> `409` (`Пользователь с таким e-mail уже зарегистрирован.`)
- Убрана временная ручная маршрутизация `method + path` в `backend/lib/src/server.dart`; `POST /auth/login` и `POST /auth/register` переведены на `router.post(...)`.
- После правок backend пересобран (`docker compose up --build -d backend`) и повторно проверен.
- `dart analyze` в `backend/` проходит (`No issues found!`) при запуске вне sandbox.

Блокер по integration test:

- `flutter test integration_test/register_flow_test.dart -d emulator-5554 ...` не удалось выполнить:
  - в среде нет активного `emulator-5554`;
  - доступный AVD `Pixel_9` падает при старте: `Your device does not have enough disk space to run avd: Pixel_9`;
  - web/desktop fallback для `integration_test` здесь не подходит (`Web devices are not supported for integration tests yet`, для `windows` не включен desktop target).

Примечание по кодировке:

- Файлы проекта в UTF-8; ранее вид `Р...` в части команд был вызван выводом консоли без явного `-Encoding UTF8`.

## Текущее состояние

Проект состоит из двух частей:

- Flutter-клиент в корне проекта.
- Dart backend в папке `backend/`.

Уже сделано:

- Flutter-приложение переведено на `Provider`.
- Добавлен backend на Dart.
- Backend переведен на PostgreSQL.
- Подготовлен и запущен `Docker`-стек через `docker-compose.yml`.
- Flutter уже умеет работать с backend через:
  - `POST /auth/login`
  - `GET /student/cabinet`
- Добавлена регистрация:
  - экран регистрации в Flutter
  - метод `signUp` в состоянии и репозитории
  - endpoint `POST /auth/register` в backend
  - создание студента в PostgreSQL

## На чем остановился

Остановка была на финальной проверке регистрации end-to-end.

Что уже подтверждено:

- `Docker` backend пересобирается и поднимается.
- `POST /auth/login` работает.
- `POST /auth/register` уже доходит до backend и отрабатывает корректно при нормальном JSON-запросе.
- Проверка через PowerShell `Invoke-WebRequest` + `ConvertTo-Json` вернула `201 Created`.

Что было выявлено по ходу:

- Проверка через `curl.exe` в PowerShell с inline JSON давала ложные ошибки из-за формата тела запроса.
- Для обхода странного поведения на маршруте регистрации в `backend/lib/src/server.dart` был добавлен явный dispatch по `method + path` для:
  - `/auth/login`
  - `/auth/register`

## Что еще нужно сделать

### 1. Дожать проверку backend регистрации

Нужно повторно проверить после последних правок:

- `POST /auth/register`
- `POST /auth/login`
- `GET /student/cabinet`

Рекомендуемая проверка регистрации:

```powershell
$payload = @{
  fullName = 'Test User'
  group = 'PI-301'
  email = 'student_' + [guid]::NewGuid().ToString('N').Substring(0,8) + '@example.com'
  password = 'student123'
  phone = '+79990001122'
}

$body = $payload | ConvertTo-Json

Invoke-WebRequest `
  -Uri 'http://127.0.0.1:8080/auth/register' `
  -Method Post `
  -ContentType 'application/json' `
  -Body $body `
  -UseBasicParsing
```

Ожидаемый результат:

- статус `201`
- в ответе есть `token`
- в ответе есть `cabinet`

### 2. Проверить Flutter integration test регистрации

Нужно прогнать:

```powershell
flutter test integration_test\register_flow_test.dart -d emulator-5554 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=API_LOGIN_PATH=/auth/login `
  --dart-define=API_REGISTER_PATH=/auth/register `
  --dart-define=API_CABINET_PATH=/student/cabinet
```

Ожидаемый результат:

- тест проходит
- после регистрации открывается главный экран

### 3. Проверить и при необходимости почистить backend код

После успешной проверки нужно убедиться, что в `backend/lib/src/server.dart` не осталось временной диагностики, если она больше не нужна.

Сейчас отдельно проверить:

- обработку невалидного JSON
- ответы `400`, `401`, `409`, `500`

### 4. Привести тексты в проекте к нормальной кодировке

В части файлов есть поломанные русские строки вида `Р...`.

Нужно отдельно пройтись по:

- `lib/state/student_app_state.dart`
- `lib/repositories/student_repository.dart`
- `lib/pages/login_page.dart`
- `lib/pages/register_page.dart`
- другим экранам, где есть такой текст

Цель:

- сохранить файлы в UTF-8
- вернуть нормальные русские сообщения и подписи

### 5. Добить стабильную проверку анализа

`dart analyze` для backend в текущем окружении несколько раз зависал по таймауту, хотя сборка контейнера проходила успешно.

Нужно повторить локально:

```powershell
cd backend
dart analyze
```

Если снова виснет:

- проверить окружение Dart
- проверить блокировки `.dart_tool`
- при необходимости запустить анализ уже на чистой машине или сервере

## Ключевые файлы

- `backend/lib/src/server.dart`
- `backend/lib/src/postgres_student_store.dart`
- `lib/repositories/student_repository.dart`
- `lib/state/student_app_state.dart`
- `lib/pages/login_page.dart`
- `lib/pages/register_page.dart`
- `integration_test/register_flow_test.dart`
- `docker-compose.yml`

## Приоритет следующего шага

Сначала нужно сделать пункт `1`, потом пункт `2`.

Если оба проходят, можно переходить к чистке текста и полировке.

## Обновление от 2026-03-05 (teacher-app)

Сделано:

- Добавлен backend API для преподавателя:
  - `POST /teacher/login`
  - `GET /teacher/dashboard`
- Добавлена роль `teacher` в JWT (`issueTeacherToken`).
- В backend добавлено хранение обращений к куратору в таблице `curator_messages`.
- `POST /student/curator/contact` теперь:
  - сохраняет сообщение в `curator_messages`,
  - оставляет уведомление в `announcements` студента.
- В backend реализована сборка teacher dashboard:
  - расписание преподавателя (по совпадению `lesson.teacher` и `TEACHER_NAME`),
  - сообщения студентов, где `curator_name = TEACHER_NAME`.
- Добавлено отдельное Flutter-приложение преподавателя:
  - entrypoint: `lib/main_teacher.dart`
  - модули: `lib/teacher/models`, `lib/teacher/repositories`, `lib/teacher/state`, `lib/teacher/pages`
  - UI: вход преподавателя, просмотр расписания, просмотр сообщений куратора.
- Добавлены переменные окружения backend:
  - `TEACHER_EMAIL`
  - `TEACHER_PASSWORD`
  - `TEACHER_NAME`

Проверено:

- `dart analyze` в `backend/` — без ошибок.
- `dart analyze` в корне Flutter-проекта — без ошибок.
- `docker compose up --build -d backend` — backend успешно пересобран.
- Smoke-тесты API:
  - `POST /teacher/login` -> `200`
  - `GET /teacher/dashboard` -> `200`
  - поток `student /curator/contact -> teacher/dashboard` подтвержден (сообщение появляется в teacher dashboard).

## Обновление от 2026-03-05 (teacher-mobile-register)

Сделано:

- Переведена авторизация преподавателя с env-кредов на БД (`teachers`):
  - `POST /teacher/register`
  - `POST /teacher/login`
- Teacher JWT теперь содержит `sub = teacher_id` и `role = teacher`.
- Добавлена таблица `teachers` и миграция `curator_messages.curator_teacher_id`.
- `POST /student/curator/contact` теперь связывает сообщение с аккаунтом преподавателя-куратора (если найден по `full_name`).
- `GET /teacher/dashboard` теперь работает по `teacher_id` из токена и показывает сообщения по `curator_teacher_id`.
- В teacher Flutter app добавлена регистрация прямо на экране входа (переключение вход/регистрация).
- Teacher app готово для мобильного запуска через `lib/main_teacher.dart`.

Проверено:

- `dart analyze` (backend) — без ошибок.
- `dart analyze` + `flutter analyze` (frontend) — без ошибок.
- Smoke-тест: `teacher/register -> teacher/dashboard -> student/curator/contact -> teacher/dashboard` прошел успешно, сообщение доставлено зарегистрированному преподавателю.

## Обновление от 2026-03-05 (stability-fix + future-goals)

Сделано сегодня дополнительно:

- Исправлен runtime-crash на мобильном при отправке сообщения куратору (`_dependents.isEmpty`).
- В `ProfilePage` переписана логика диалога сообщения:
  - убран ручной `TextEditingController.dispose()` после `showDialog`,
  - добавлен безопасный `onChanged` + `unfocus()` перед `pop()`.
- В `StudentAppState` убран принудительный сброс `_cabinetData = null` в action-методах
  `requestCertificate` и `contactCurator` при `AuthException`, чтобы не ломать дерево виджетов
  в момент закрытия диалога/IME.
- Проверки после фикса:
  - `dart analyze` — без ошибок,
  - `flutter analyze` — без ошибок.

## Цели на будущее

1. Привести все русские строки проекта к чистому UTF-8 (убрать артефакты `Р...` в UI и документации).
2. Доделать teacher mobile UX:
   - фильтры расписания по дням,
   - статус обработки сообщений куратора (новое/прочитано/в работе),
   - экран деталей сообщения + ответ студенту.
3. Сделать полноценные роли и аккаунты:
   - управление преподавателями из админки,
   - назначение куратора из списка преподавателей (по `teacher_id`, не по строке ФИО).
4. Добавить push-уведомления:
   - преподавателю о новых сообщениях,
   - студенту о ответе куратора и готовности справки.
5. Расширить функционал справок:
   - типы справок, вложения, статусы выполнения, история заявок.
6. Подготовить production-развертывание:
   - домен + HTTPS,
   - доступ backend с любых устройств,
   - резервное копирование БД и базовый мониторинг.
7. Добавить e2e/integration тесты для новых потоков:
   - `teacher/register/login/dashboard`,
   - `student -> curator/contact -> teacher/dashboard`,
   - регресс student/admin сценариев на Android.
