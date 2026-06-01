# Доработки проекта Student Cabinet

## Выполнено

### 1. Вынесение общей логики в shared-модуль
- `lib/shared/exceptions.dart` — единые `AppAuthException` и `AppDataException`
- `lib/shared/api_client.dart` — базовый `BaseApiClient` (buildUri, decodeJson, extractMessage, token management)
- `lib/shared/helpers.dart` — общий `weekdayLabel()`
- `lib/shared/widgets/error_banner.dart` — виджет ошибки
- `lib/shared/widgets/password_field.dart` — поле пароля с toggle
- `lib/shared/widgets/auth_submit_button.dart` — кнопка входа с индикатором
- Все три репозитория наследуют `BaseApiClient`
- Все state-классы используют общие исключения
- Все login-страницы используют shared-виджеты

### 2. Разбить большие файлы
- `student_repository.dart` — demo-данные вынесены в `demo_student_repository.dart`
- `schedule_excel_importer.dart` — хелперы вынесены в `excel_parse_helpers.dart`
- `home_page.dart` — виджеты вынесены в `lib/pages/widgets/`

### 3. Обработка ошибок сети
- `AppNetworkException` (extends `AppDataException`) в `lib/shared/exceptions.dart`
- `guardedRequest()` в `BaseApiClient` — обёртка с timeout (15 сек), retry (2 попытки при SocketException), обработка SocketException / TimeoutException / HttpException
- Все три репозитория (student, teacher, admin) используют `guardedRequest()`
- Понятные сообщения: «Нет подключения к интернету», «Сервер не отвечает»

---

## Запланировано

### 4. Локализация строк
- Вынести все строки UI в константы или использовать `intl`/`easy_localization`

### 5. Роутинг
- Перейти на `go_router` или `auto_route` вместо прямых `Navigator.push`

### 6. Безопасность
- Убрать захардкоженные admin/teacher credentials из `.env`
- Добавить нормальную систему управления пользователями
- Проверить длину и случайность `JWT_SECRET` в продакшене
- Добавить refresh token flow

### 7. Тестирование
- Unit-тесты для моделей и парсинга JSON
- Unit-тесты для state-классов (signIn, signOut, refresh)
- Моки HTTP через `http.MockClient` или `mockito`
- Тесты для Excel-импортера

### 8. Offline-режим
- Кэширование данных локально (hive или sqflite)
- Отображение кэшированных данных при отсутствии сети

### 9. UX/UI улучшения
- Pull-to-refresh на страницах с данными
- Анимации и transitions между экранами
- Тёмная тема

### 10. Инфраструктура
- CI/CD через GitHub Actions (тесты + сборка)
- Структурированное логирование (Sentry, Crashlytics)
- API-версионирование для обратной совместимости
