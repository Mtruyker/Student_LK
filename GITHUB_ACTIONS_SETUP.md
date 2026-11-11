# Настройка GitHub Actions для автодеплоя на Vercel

Workflow `.github/workflows/deploy.yml` автоматически собирает Flutter и деплоит на Vercel при каждом `git push`.

---

## Шаг 1: Создать проект на Vercel

### Через веб-интерфейс

1. Зайти на [vercel.com](https://vercel.com)
2. **Sign Up** → Continue with GitHub
3. **Add New... → Project**
4. Выбрать репозиторий `Student_LK`
5. **Framework Preset**: Other
6. **Build Command**: оставить пустым
7. **Output Directory**: `build/web`
8. **Install Command**: оставить пустым
9. Нажать **Deploy** (первый деплой упадёт — это нормально, нам нужен только project ID)

### Получить Project ID и Org ID

После создания проекта:

1. Зайти в **Settings** → **General**
2. Скопировать:
   - **Project ID** (например, `prj_abc123xyz`)
   - **Team ID** или **Org ID** (например, `team_abc123` или `user_abc123`)

---

## Шаг 2: Создать Vercel Token

1. Зайти в **Account Settings** → [**Tokens**](https://vercel.com/account/tokens)
2. Нажать **Create Token**
3. **Token Name**: `GitHub Actions`
4. **Scope**: Full Account
5. **Expiration**: No Expiration (или 1 год)
6. Нажать **Create**
7. **Скопировать токен** (показывается один раз!)

---

## Шаг 3: Добавить Secrets в GitHub

1. Зайти в репозиторий на GitHub: `https://github.com/Mtruyker/Student_LK`
2. **Settings** → **Secrets and variables** → **Actions**
3. Нажать **New repository secret** для каждого:

### Обязательные secrets:

| Name | Value | Где взять |
|------|-------|-----------|
| `VERCEL_TOKEN` | `aBcD1234...` | Vercel Account Settings → Tokens |
| `VERCEL_ORG_ID` | `team_abc123` | Vercel Project Settings → General |
| `VERCEL_PROJECT_ID` | `prj_xyz789` | Vercel Project Settings → General |
| `SUPABASE_URL` | `https://xxx.supabase.co` | Supabase Dashboard → Settings → API |
| `SUPABASE_ANON_KEY` | `eyJhbGciOi...` | Supabase Dashboard → Settings → API → anon public |

### Где взять Supabase credentials:

1. Зайти в [Supabase Dashboard](https://supabase.com/dashboard)
2. Выбрать проект
3. **Settings** → **API**
4. Скопировать:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** → `SUPABASE_ANON_KEY`

---

## Шаг 4: Настроить Supabase Redirect URLs

После первого успешного деплоя:

1. GitHub Actions выдаст URL вида: `https://student-lk-abc123.vercel.app`
2. Зайти в **Supabase Dashboard** → **Authentication** → **URL Configuration**
3. Добавить в **Redirect URLs**:
   ```
   https://student-lk-abc123.vercel.app
   https://student-lk-*.vercel.app
   ```
4. Установить **Site URL**:
   ```
   https://student-lk-abc123.vercel.app
   ```

---

## Шаг 5: Запустить первый деплой

```bash
# Закоммитить workflow
git add .github/workflows/deploy.yml vercel.json GITHUB_ACTIONS_SETUP.md
git commit -m "Add GitHub Actions workflow for Vercel deployment"
git push origin main
```

### Проверить статус деплоя

1. Зайти в репозиторий на GitHub
2. Вкладка **Actions**
3. Открыть последний workflow run
4. Дождаться завершения (3-5 минут)

### Если деплой упал

**Причина 1: Secrets не добавлены**

Ошибка:
```
Error: Required secret 'VERCEL_TOKEN' is not set
```

Решение: добавить все 5 secrets из шага 3.

**Причина 2: Неверный VERCEL_ORG_ID**

Ошибка:
```
Error: The specified scope does not exist
```

Решение: проверить `VERCEL_ORG_ID` — должен начинаться с `team_` или быть user ID.

**Причина 3: Flutter версия**

Ошибка:
```
Version solving failed
```

Решение: обновить версию Flutter в `deploy.yml`:
```yaml
flutter-version: '3.27.0'  # последняя stable
```

---

## Что происходит при каждом git push

1. **GitHub Actions** запускает workflow
2. Устанавливает Flutter 3.24.0
3. Запускает `flutter pub get`
4. Собирает `flutter build web --release` с Supabase credentials
5. Заливает `build/web` на Vercel
6. Vercel деплоит на production URL
7. Весь процесс занимает **3-5 минут**

---

## После успешного деплоя

### Получить URL приложения

В логах GitHub Actions в шаге "Deploy to Vercel":
```
✓ Production: https://student-lk-abc123.vercel.app
```

Или в Vercel Dashboard → Deployments → последний деплой.

### Проверить PWA

**На iPhone:**
1. Открыть Safari → `https://student-lk-abc123.vercel.app`
2. Кнопка «Поделиться» → «На экран "Домой"»
3. Подтвердить → иконка ЛК появится на главном экране

**На Android:**
1. Открыть Chrome → `https://student-lk-abc123.vercel.app`
2. Chrome предложит «Установить приложение»

### Настроить кастомный домен (опционально)

В **Vercel Dashboard** → **Settings** → **Domains**:
1. Добавить домен (например, `lk.novouzensk-tech.ru`)
2. Vercel даст DNS-записи
3. Добавить их в регистраторе домена
4. HTTPS настроится автоматически

---

## Troubleshooting

### Проблема: "Error: No Space left on device" локально

**Решение**: Очистить кэш:
```bash
flutter clean
npm cache clean --force
```

Или удалить ненужные файлы на диске C:.

### Проблема: Долгая сборка (>10 минут)

**Причина**: GitHub Actions скачивает Flutter каждый раз.

**Решение**: Добавить кэширование в `deploy.yml`:
```yaml
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      build
    key: flutter-${{ runner.os }}-${{ hashFiles('**/pubspec.lock') }}
```

### Проблема: Vercel deployment failed

**Причина**: Неверный `vercel-args`.

**Решение**: Убрать `--prod` для preview deployments:
```yaml
vercel-args: ${{ github.ref == 'refs/heads/main' && '--prod' || '' }}
```

### Проблема: Supabase auth не работает

**Причина**: Redirect URL не добавлен в Supabase.

**Решение**: Добавить в Supabase Dashboard → Authentication → URL Configuration:
```
https://student-lk-*.vercel.app
```

---

## Мониторинг деплоев

### GitHub Actions

- Все деплои: `https://github.com/Mtruyker/Student_LK/actions`
- Email-уведомления: Settings → Notifications → Actions

### Vercel Dashboard

- Все деплои: `https://vercel.com/dashboard/deployments`
- Build logs, analytics, metrics

---

## Автоматизация для трёх версий (студент/админ/преподаватель)

Если нужны три отдельных приложения:

### Вариант 1: Три проекта Vercel

Создать три проекта в Vercel:
- `student-lk`
- `admin-lk`
- `teacher-lk`

Для каждого добавить свой `VERCEL_PROJECT_ID` в secrets:
- `VERCEL_PROJECT_ID_STUDENT`
- `VERCEL_PROJECT_ID_ADMIN`
- `VERCEL_PROJECT_ID_TEACHER`

Обновить workflow:
```yaml
- name: Deploy Student version
  uses: amondnet/vercel-action@v25
  with:
    vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID_STUDENT }}
    # ...

- name: Deploy Admin version
  uses: amondnet/vercel-action@v25
  with:
    vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID_ADMIN }}
    # ...
```

### Вариант 2: Один проект, routing по subdomain

Настроить Vercel rewrite rules в `vercel.json`:
```json
{
  "rewrites": [
    {
      "source": "/:path*",
      "destination": "/index.html",
      "has": [{"type": "host", "value": "student.lk.ru"}]
    },
    {
      "source": "/:path*",
      "destination": "/admin/index.html",
      "has": [{"type": "host", "value": "admin.lk.ru"}]
    }
  ]
}
```

---

## Итого

После настройки:
- ✅ Каждый `git push` автоматически деплоит на Vercel
- ✅ Сборка с Supabase credentials
- ✅ HTTPS автоматом
- ✅ PWA работает на iPhone/Android
- ✅ Бесплатно навсегда (в пределах лимитов Vercel)
- ✅ Деплой занимает 3-5 минут

**Стоимость**: $0  
**Время на настройку**: 10 минут  
**Автообновления**: Да  
**HTTPS**: Да  
**PWA**: Да
