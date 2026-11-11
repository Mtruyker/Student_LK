# Публикация на GitHub Pages и установка на iPhone

Адрес: https://mtruyker.github.io/Student_LK/

Workflow `.github/workflows/deploy.yml` проверяет тест экрана входа, собирает Flutter Web
и публикует сайт при push в `main`. Его также можно запустить вручную
в GitHub → Actions → Build and Deploy to GitHub Pages → Run workflow.
В Settings → Pages источником должен быть выбран GitHub Actions.

Сборка использует тот же Supabase, что и `tool/run_supabase_role.ps1`.
При необходимости задайте `SUPABASE_URL` и `SUPABASE_ANON_KEY` через
GitHub Actions secrets или variables. Secrets имеют приоритет.
Публичный publishable/anon key предназначен для клиентской сборки;
service_role и secret keys в веб-приложении использовать нельзя.
Доступ к данным контролируется Supabase RLS.

В Supabase → Authentication → URL Configuration добавьте
`https://mtruyker.github.io/Student_LK/` в разрешённые Redirect URLs.
Если это основной сайт проекта, укажите этот адрес также в Site URL.
Это необходимо для переходов из писем подтверждения и восстановления пароля.

## На iPhone

1. Откройте адрес сайта в Safari.
2. Нажмите «Поделиться» → «На экран Домой».
3. Если есть переключатель «Открывать как веб-приложение», включите его.
4. Нажмите «Добавить» и запускайте приложение с появившейся иконки.

Это веб-приложение с отдельным окном, установка через App Store не нужна.
Вход и получение актуальных данных требуют интернета.
Проверку установки и работы на физическом iPhone следует выполнить отдельно.

## Локальная проверка сборки

```powershell
flutter test
flutter build web --release --base-href /Student_LK/ --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY --dart-define=SUPABASE_PASSWORD_RESET_REDIRECT_URL=https://mtruyker.github.io/Student_LK/
```

Результат находится в `build/web`. Манифест использует относительные
`start_url` и `scope`, чтобы иконка открывала именно `/Student_LK/`.
