# Развёртывание Student_LK как PWA (Progressive Web App)

## Что такое PWA?

PWA (Progressive Web App) — это веб-приложение, которое ведёт себя как нативное:
- **iOS**: кнопка Safari «Поделиться» → «На экран "Домой"» → иконка приложения на главном экране
- **Android**: Chrome предлагает «Установить приложение» автоматически
- Работает в полноэкранном режиме без браузерной панели
- Может работать офлайн (если настроен service worker)

---

## ✅ Что уже сделано

1. **Добавлена web-платформа**:
   ```bash
   flutter create --platforms=web .
   ```

2. **Настроен `web/manifest.json`**:
   - Название: "Личный кабинет студента"
   - Короткое имя: "ЛК Студента"
   - `display: standalone` — полноэкранный режим
   - Тёмная тема: `background_color: #05070C`, `theme_color: #38BDF8`
   - Иконки 192px и 512px (maskable для Android)

3. **Добавлены iOS-мета-теги в `web/index.html`**:
   - `apple-mobile-web-app-capable` — включает полноэкранный режим
   - `apple-mobile-web-app-status-bar-style` — прозрачная строка статуса
   - `apple-mobile-web-app-title` — название на главном экране
   - `apple-touch-icon` — иконка приложения

4. **Добавлен базовый service worker** (`web/flutter_service_worker.js`):
   - Flutter перегенерирует его при сборке
   - Обеспечивает кэширование для офлайн-работы

---

## 🚀 Как собрать и развернуть

### 1. Сборка для production

```bash
# Студенческое приложение
flutter build web --release \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_PASSWORD_RESET_REDIRECT_URL=https://yourdomain.com

# Админское приложение
flutter build web --release -t lib/main_admin.dart \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# Преподавательское приложение
flutter build web --release -t lib/main_teacher.dart \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Результат: папка `build/web/` — готовая статика для хостинга.

### 2. Локальный тест

```bash
# Запустить на локальном Chrome
flutter run -d chrome \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# Открыть в браузере http://localhost:PORT
```

### 3. Варианты хостинга

#### **A. Firebase Hosting (рекомендуется)**

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Выбрать папку: build/web
# Single-page app: Yes
# Перезаписать index.html: No

firebase deploy
```

**Плюсы**:
- Бесплатно до 10 GB/месяц
- Автоматический HTTPS
- CDN по всему миру
- Кастомный домен

#### **B. GitHub Pages**

```bash
# 1. Создать репозиторий на GitHub
# 2. Собрать проект
flutter build web --release --base-href "/student_cabinet/"

# 3. Закоммитить build/web в ветку gh-pages
cd build/web
git init
git add .
git commit -m "Deploy PWA"
git branch -M gh-pages
git remote add origin https://github.com/YOUR_USERNAME/student_cabinet.git
git push -f origin gh-pages
```

Приложение доступно: `https://YOUR_USERNAME.github.io/student_cabinet/`

#### **C. Vercel**

```bash
npm install -g vercel
cd build/web
vercel --prod
```

#### **D. Netlify**

Drag-and-drop папку `build/web` на [app.netlify.com/drop](https://app.netlify.com/drop)

#### **E. Свой сервер (Nginx)**

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    root /var/www/student_cabinet;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Кэширование статики
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff|woff2|ttf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Скопировать `build/web/*` в `/var/www/student_cabinet`.

---

## 📱 Как установить на iPhone

1. Открыть Safari на iPhone
2. Перейти на `https://yourdomain.com`
3. Нажать кнопку **«Поделиться»** (квадрат со стрелкой вверх)
4. Прокрутить вниз → выбрать **«На экран "Домой"»**
5. Подтвердить → иконка появится на главном экране

Приложение откроется в полноэкранном режиме без Safari-панели.

---

## 🤖 Как установить на Android

1. Открыть Chrome на Android
2. Перейти на `https://yourdomain.com`
3. Chrome автоматически предложит **«Установить приложение»** (баннер снизу)
4. Нажать «Установить» → иконка появится на главном экране

Альтернативно: **Меню (⋮)** → **«Добавить на главный экран»**.

---

## 🔧 Настройки перед деплоем

### 1. Заменить дефолтные иконки

Сейчас используются Flutter-шаблоны. Создайте свои иконки:

```bash
# Нужны PNG-файлы:
# - 192×192 (для Android и iOS)
# - 512×512 (для Android splash screen)
# - maskable версии (Android адаптивные иконки)

# Сервисы для генерации:
# - https://www.pwabuilder.com/imageGenerator
# - https://realfavicongenerator.net/
```

Заменить файлы в `web/icons/`.

### 2. Добавить HTTPS

**Обязательно для PWA!** Без HTTPS:
- Service worker не работает
- iOS не покажет кнопку «На экран "Домой"»
- Некоторые API (геолокация, камера) заблокированы

Firebase Hosting / Vercel / Netlify добавляют HTTPS автоматически.

### 3. Обновить CSP (Content Security Policy)

Если Supabase требует, добавить в `web/index.html`:

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self' https://*.supabase.co; 
               style-src 'self' 'unsafe-inline'; 
               script-src 'self' 'unsafe-inline' 'unsafe-eval';">
```

### 4. Настроить редирект для password reset

В Supabase Dashboard → **Authentication** → **URL Configuration**:

```
Site URL: https://yourdomain.com
Redirect URLs: https://yourdomain.com
```

Обновить флаг при сборке:
```bash
--dart-define=SUPABASE_PASSWORD_RESET_REDIRECT_URL=https://yourdomain.com
```

---

## 🧪 Проверка PWA

### Lighthouse Audit (Chrome DevTools)

1. Открыть DevTools (F12)
2. Вкладка **Lighthouse**
3. Выбрать **Progressive Web App**
4. Нажать **Analyze page load**

Целевые метрики:
- ✅ Installable
- ✅ PWA Optimized
- ✅ Fast and reliable (service worker)
- ✅ Works offline

### PWA Testing Tools

- [PWABuilder](https://www.pwabuilder.com/) — проверка манифеста и service worker
- [Manifest Validator](https://manifest-validator.appspot.com/)

---

## 🐛 Известные ограничения

### iOS Safari
- ❌ Нет push-уведомлений (iOS 16.4+ поддерживает только через установленное PWA)
- ❌ Нет background sync
- ⚠️ Service worker ограничен (очищается при неактивности 7+ дней)
- ⚠️ Каждый раз перезагружает приложение при открытии

### Android Chrome
- ✅ Полная поддержка PWA
- ✅ Push-уведомления работают
- ✅ Background sync работает

### Решение для push на iOS

Если критичны уведомления:
1. Опубликовать в App Store (Flutter → Xcode → iTunes Connect)
2. Использовать hybrid: PWA для desktop, native для iOS

---

## 📦 Структура build/web

После сборки:
```
build/web/
├── index.html              # Точка входа
├── manifest.json           # PWA манифест
├── flutter_service_worker.js  # Service worker
├── icons/                  # Иконки приложения
├── assets/                 # Ресурсы (изображения, шрифты)
├── canvaskit/             # Flutter Web Engine
└── main.dart.js           # Скомпилированный Dart

Размер: ~2-5 MB (сжатые)
```

---

## 🚀 Чек-лист перед деплоем

- [ ] Собрать с production-флагами Supabase
- [ ] Заменить дефолтные иконки на брендированные
- [ ] Проверить `manifest.json` (название, цвета)
- [ ] Добавить HTTPS-хостинг
- [ ] Настроить редирект для password reset в Supabase
- [ ] Протестировать на iPhone Safari (кнопка «На экран "Домой"»)
- [ ] Протестировать на Android Chrome (баннер установки)
- [ ] Запустить Lighthouse PWA Audit (>90 баллов)
- [ ] Проверить офлайн-режим (отключить Wi-Fi, открыть PWA)

---

## 📞 Поддержка

После деплоя студенты смогут:
1. Открыть сайт на телефоне
2. Добавить на главный экран
3. Пользоваться как нативным приложением

**Инструкция для студентов** (можно разослать в группу):

> 📱 **Как установить ЛК на телефон:**
> 
> **iPhone:**
> 1. Открой Safari → student-lk.yourdomain.com
> 2. Нажми «Поделиться» (квадрат со стрелкой вверх)
> 3. Выбери «На экран "Домой"»
> 
> **Android:**
> 1. Открой Chrome → student-lk.yourdomain.com
> 2. Нажми «Установить приложение» в всплывающем окне
> 
> Готово! Теперь можешь открывать ЛК как обычное приложение.

---

**Следующий шаг**: выбрать хостинг (рекомендую Firebase Hosting — бесплатно и просто) и задеплоить `build/web`.
