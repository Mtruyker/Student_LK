# Деплой Student_LK на Vercel (с Supabase)

## Почему Vercel для Supabase-проектов

- **Бесплатно** для личных проектов (100 GB bandwidth/месяц)
- **Автоматический HTTPS** с сертификатом
- **Edge Network** — быстрая загрузка по всему миру
- **Идеальная интеграция** с Supabase (Vercel от создателей Next.js)
- **Автодеплой** при git push
- **Кастомный домен** бесплатно

---

## 🚀 Деплой за 5 минут

### Вариант A: Через веб-интерфейс (проще)

1. **Зарегистрироваться на Vercel**
   - Зайти на [vercel.com](https://vercel.com)
   - Нажать **Sign Up** → выбрать **Continue with GitHub**
   - Авторизовать Vercel в GitHub

2. **Импортировать проект**
   - Нажать **Add New...** → **Project**
   - Выбрать репозиторий `Student_LK`
   - Нажать **Import**

3. **Настроить переменные окружения**
   - В разделе **Environment Variables** добавить:
   ```
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key
   ```
   - Нажать **Deploy**

4. **Готово!**
   - Vercel соберёт и задеплоит проект
   - Получишь URL вида: `https://student-lk-abc123.vercel.app`

### Вариант B: Через CLI (для автоматизации)

```bash
# 1. Установить Vercel CLI
npm install -g vercel

# 2. Войти в аккаунт
vercel login

# 3. Перейти в проект
cd G:\Student_LK

# 4. Задеплоить (первый раз — настройка, потом автоматом)
vercel

# Vercel спросит:
# ? Set up and deploy "G:\Student_LK"? [Y/n] → Y
# ? Which scope? → выбрать свой аккаунт
# ? Link to existing project? [y/N] → N
# ? What's your project's name? → student-lk
# ? In which directory is your code located? → ./

# 5. Добавить environment variables
vercel env add SUPABASE_URL
# Вставить: https://your-project.supabase.co

vercel env add SUPABASE_ANON_KEY
# Вставить: your-anon-key

# 6. Production deploy
vercel --prod
```

---

## 🎯 После первого деплоя

### 1. Получить URL приложения

После деплоя Vercel выдаст URL:
```
✅ Deployed to production: https://student-lk.vercel.app
```

### 2. Настроить Supabase

В **Supabase Dashboard** → **Authentication** → **URL Configuration**:

```
Site URL: https://student-lk.vercel.app
Redirect URLs: https://student-lk.vercel.app
```

Добавить в список **Redirect URLs**:
- `https://student-lk.vercel.app`
- `https://student-lk-*.vercel.app` (для preview-деплоев)

### 3. Кастомный домен (опционально)

В **Vercel Dashboard** → **Settings** → **Domains**:
1. Добавить свой домен (например, `lk.novouzensk-tech.ru`)
2. Vercel даст DNS-записи для настройки
3. Добавить их в регистраторе домена
4. HTTPS настроится автоматически

---

## 📱 Как студенты будут устанавливать

После деплоя отправь студентам инструкцию:

---

**📱 Как установить Личный кабинет на телефон**

**iPhone:**
1. Открой Safari → lk.novouzensk-tech.ru
2. Нажми кнопку «Поделиться» (квадрат со стрелкой вверх)
3. Прокрути вниз → выбери **«На экран "Домой"»**
4. Готово! Теперь можешь открывать ЛК как обычное приложение

**Android:**
1. Открой Chrome → lk.novouzensk-tech.ru
2. Chrome предложит **«Установить приложение»** — нажми «Установить»
3. Или через меню (⋮) → **«Добавить на главный экран»**

---

## 🔄 Автодеплой при изменениях

После первого деплоя **каждый git push автоматически деплоит** новую версию:

```bash
# Внёс изменения в код
git add .
git commit -m "Добавил новую фичу"
git push origin main

# Vercel автоматически:
# 1. Заметит изменения в GitHub
# 2. Запустит сборку
# 3. Задеплоит на production
# 4. Пришлёт уведомление
```

**Preview deployments**: каждый Pull Request получает свой временный URL для тестирования.

---

## 🎨 Три приложения на одном домене

Можно задеплоить все три версии (студент/админ/преподаватель) на **разные поддомены**:

### Вариант 1: Отдельные проекты Vercel

```bash
# Студенческое
vercel --prod --name student-lk

# Админское (указать entry point в vercel.json)
vercel --prod --name admin-lk

# Преподавательское
vercel --prod --name teacher-lk
```

Получишь:
- `https://student-lk.vercel.app`
- `https://admin-lk.vercel.app`
- `https://teacher-lk.vercel.app`

### Вариант 2: Один проект, роутинг по path

Можно задеплоить один проект и роутить:
- `/` → студент
- `/admin` → админ
- `/teacher` → преподаватель

Но это сложнее (нужны rewrite rules), проще три отдельных проекта.

---

## ⚙️ Настройки для production

### 1. Добавить CSP (Content Security Policy)

Создать `vercel.json`:
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self' https://*.supabase.co; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data: https:;"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        }
      ]
    }
  ]
}
```

### 2. Включить аналитику Vercel

В **Vercel Dashboard** → **Analytics**:
- Бесплатно отслеживает:
  - Количество визитов
  - Скорость загрузки
  - География пользователей
  - Web Vitals (Core Web Vitals для PWA)

### 3. Мониторинг ошибок (опционально)

Добавить Sentry для отлова ошибок:
```bash
flutter pub add sentry_flutter
```

---

## 🐛 Troubleshooting

### Проблема: Build failed на Vercel

**Причина**: Flutter не установлен в build-окружении Vercel.

**Решение**: Использовать GitHub Actions для сборки, а на Vercel деплоить только `build/web`:

1. Создать `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          
      - name: Build web
        run: |
          flutter pub get
          flutter build web --release \
            --dart-define=USE_SUPABASE=true \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./build/web
```

2. Добавить secrets в GitHub:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `VERCEL_TOKEN` (из Vercel Settings → Tokens)
   - `VERCEL_ORG_ID` и `VERCEL_PROJECT_ID` (из `.vercel/project.json`)

### Проблема: PWA не предлагает установку на iPhone

**Причина**: Нужен HTTPS и корректный `manifest.json`.

**Решение**: Vercel даёт HTTPS автоматом, проверь:
1. Открой Safari DevTools → Application → Manifest
2. Убедись, что `display: standalone`
3. Иконки 192px и 512px присутствуют

### Проблема: Офлайн-режим не работает

**Причина**: Service worker не зарегистрирован.

**Решение**: Flutter генерирует SW автоматом при сборке. Проверь в `build/web/flutter_service_worker.js`.

---

## 📊 Что проверить после деплоя

- [ ] Открывается на iPhone Safari без ошибок
- [ ] Кнопка «На экран "Домой"» доступна
- [ ] После добавления открывается в полный экран
- [ ] Логин через Supabase работает
- [ ] Офлайн-режим работает (отключить Wi-Fi, открыть PWA)
- [ ] Lighthouse PWA Audit > 90 баллов
- [ ] Редирект password reset работает
- [ ] Открывается на Android Chrome
- [ ] Chrome предлагает «Установить приложение»

---

## 🎉 Итого

После деплоя на Vercel:
1. Студенты получат ссылку `https://student-lk.vercel.app`
2. Смогут добавить на главный экран через Safari/Chrome
3. Приложение будет работать как нативное
4. Автоматические обновления при каждом git push
5. Бесплатно навсегда (в пределах 100 GB/месяц)

**Стоимость**: $0 ✅  
**Время на деплой**: 5 минут ✅  
**Автообновления**: Да ✅  
**HTTPS**: Да ✅  
**Кастомный домен**: Да (бесплатно) ✅
