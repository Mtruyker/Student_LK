# Деплой Student_LK на GitHub Pages

Автоматический деплой Flutter PWA через GitHub Actions. Каждый `git push` → сборка → публикация на `https://mtruyker.github.io/Student_LK/`

---

## Шаг 1: Добавить Secrets в GitHub (2 минуты)

1. Зайди в [github.com/Mtruyker/Student_LK/settings/secrets/actions](https://github.com/Mtruyker/Student_LK/settings/secrets/actions)

2. Нажми **New repository secret** для каждого:

| Name | Value | Откуда |
|------|-------|--------|
| `SUPABASE_URL` | `https://xxx.supabase.co` | Supabase → Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | `eyJhbGciOi...` | Supabase → Settings → API → anon public |

### Где взять Supabase credentials:

1. Зайди в [Supabase Dashboard](https://supabase.com/dashboard)
2. Выбери проект
3. **Settings** → **API**
4. Скопируй:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** → `SUPABASE_ANON_KEY`

---

## Шаг 2: Включить GitHub Pages (1 минута)

1. Зайди в [github.com/Mtruyker/Student_LK/settings/pages](https://github.com/Mtruyker/Student_LK/settings/pages)

2. **Source**: 
   - Выбери **GitHub Actions** (НЕ "Deploy from a branch")

3. Нажми **Save**

---

## Шаг 3: Запустить первый деплой (30 секунд)

Workflow уже загружен в `.github/workflows/deploy.yml`, поэтому достаточно любого изменения:

```bash
# Пустой коммит для триггера
git commit --allow-empty -m "Trigger first GitHub Pages deployment"
git push origin main
```

Или отредактируй `README.md` через веб-интерфейс GitHub и сохрани.

---

## Шаг 4: Проверить статус деплоя (3-5 минут)

1. Зайди на [github.com/Mtruyker/Student_LK/actions](https://github.com/Mtruyker/Student_LK/actions)
2. Открой последний workflow run
3. Дождись завершения (3-5 минут)

Если всё правильно:
- ✅ Setup Flutter
- ✅ Get dependencies
- ✅ Build web
- ✅ Upload artifact
- ✅ Deploy to GitHub Pages

---

## Шаг 5: Открыть приложение

После успешного деплоя приложение доступно по адресу:

**https://mtruyker.github.io/Student_LK/**

---

## Шаг 6: Настроить Supabase Redirect (1 минута)

1. Зайди в **Supabase Dashboard** → **Authentication** → **URL Configuration**

2. Добавь в **Redirect URLs**:
   ```
   https://mtruyker.github.io/Student_LK/
   https://mtruyker.github.io
   ```

3. Установи **Site URL**:
   ```
   https://mtruyker.github.io/Student_LK/
   ```

---

## Как студенты будут устанавливать PWA

**📱 iPhone:**
1. Открой Safari → https://mtruyker.github.io/Student_LK/
2. Нажми кнопку «Поделиться» (квадрат со стрелкой вверх)
3. Прокрути вниз → выбери **«На экран "Домой"»**
4. Готово! Теперь можешь открывать ЛК как обычное приложение

**🤖 Android:**
1. Открой Chrome → https://mtruyker.github.io/Student_LK/
2. Chrome предложит **«Установить приложение»** — нажми «Установить»
3. Или через меню (⋮) → **«Добавить на главный экран»**

---

## Что происходит при каждом git push

1. **GitHub Actions** запускает workflow
2. Устанавливает Flutter 3.24.0
3. Запускает `flutter pub get`
4. Собирает `flutter build web --release` с:
   - `--base-href /Student_LK/` (путь для GitHub Pages)
   - Supabase credentials из secrets
5. Загружает `build/web` в GitHub Pages
6. GitHub Pages деплоит на production
7. Весь процесс занимает **3-5 минут**

---

## Кастомный домен (опционально)

Если есть свой домен (например, `lk.novouzensk-tech.ru`):

1. Зайди в [github.com/Mtruyker/Student_LK/settings/pages](https://github.com/Mtruyker/Student_LK/settings/pages)

2. В разделе **Custom domain** введи: `lk.novouzensk-tech.ru`

3. Нажми **Save**

4. GitHub покажет DNS-записи для настройки:
   ```
   Type: CNAME
   Name: lk
   Value: mtruyker.github.io
   ```

5. Добавь их в регистраторе домена

6. Дождись propagation (5-10 минут)

7. GitHub автоматически выпустит HTTPS-сертификат

8. Обновить `--base-href` в `.github/workflows/deploy.yml`:
   ```yaml
   flutter build web --release \
     --base-href / \
     --dart-define=...
   ```

9. Обновить Supabase Redirect URLs на новый домен

---

## Troubleshooting

### Проблема: Workflow failed на шаге "Build web"

**Причина**: Secrets не добавлены.

**Решение**: Добавить `SUPABASE_URL` и `SUPABASE_ANON_KEY` в Settings → Secrets → Actions.

### Проблема: 404 при открытии https://mtruyker.github.io/Student_LK/

**Причина 1**: GitHub Pages не включен.

**Решение**: Settings → Pages → Source: **GitHub Actions**.

**Причина 2**: Деплой ещё не завершился.

**Решение**: Проверить статус в Actions → дождаться завершения.

### Проблема: Белый экран после открытия

**Причина**: Неверный `base-href` (Flutter ищет файлы по неправильному пути).

**Решение**: Убедись, что в `deploy.yml` указано:
```yaml
--base-href /Student_LK/
```

И что ты открываешь именно `https://mtruyker.github.io/Student_LK/` (с большой буквы S и L).

### Проблема: Supabase auth не работает

**Причина**: Redirect URL не добавлен в Supabase.

**Решение**: Добавить в Supabase Dashboard → Authentication → URL Configuration:
```
https://mtruyker.github.io/Student_LK/
```

### Проблема: PWA не предлагает установку на iPhone

**Причина**: HTTPS и manifest.json уже настроены, но нужен Safari (не Chrome!).

**Решение**: 
1. Открыть в **Safari** (обязательно!)
2. Кнопка «Поделиться» → «На экран "Домой"»

### Проблема: Долгая сборка (>10 минут)

**Причина**: GitHub Actions скачивает Flutter каждый раз.

**Решение**: Добавить кэширование в `deploy.yml`:
```yaml
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: |
      /opt/hostedtoolcache/flutter
      ~/.pub-cache
    key: flutter-${{ runner.os }}-${{ hashFiles('**/pubspec.lock') }}
```

---

## Мониторинг деплоев

### GitHub Actions

- Все деплои: https://github.com/Mtruyker/Student_LK/actions
- Email-уведомления: Settings → Notifications → Actions

### Логи

- Build logs: Actions → последний workflow run → Build → Build web

---

## Ограничения GitHub Pages

- ✅ **Бесплатно** навсегда
- ✅ **HTTPS** автоматом
- ✅ **Кастомный домен** бесплатно
- ✅ **100 GB bandwidth/месяц** (хватит на 10,000+ студентов)
- ✅ **Автодеплой** при каждом push
- ⚠️ **Публичный репозиторий** (для приватного — GitHub Pro)
- ⚠️ **Только статика** (но для Flutter PWA + Supabase — идеально)

---

## Итого

После настройки:
- ✅ Каждый `git push` автоматически деплоит на GitHub Pages
- ✅ Сборка с Supabase credentials
- ✅ HTTPS автоматом
- ✅ PWA работает на iPhone/Android
- ✅ Бесплатно навсегда
- ✅ Деплой занимает 3-5 минут
- ✅ URL: https://mtruyker.github.io/Student_LK/

**Стоимость**: $0  
**Время на настройку**: 5 минут  
**Автообновления**: Да  
**HTTPS**: Да  
**PWA**: Да  
**Кастомный домен**: Да (бесплатно)
