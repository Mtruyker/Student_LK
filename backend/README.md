# student_cabinet_backend (Архив / Legacy)

**Внимание:** Этот проект больше не используется в текущей версии приложения. Весь функционал перенесен на **Supabase**.

Данный репозиторий оставлен для ознакомления с оригинальной архитектурой на Dart Shelf + Docker.

## Старый стек
- Dart (Shelf)
- PostgreSQL 16
- JWT (Manual handling)
- Docker Compose & Caddy

## Оригинальные инструкции по запуску (Legacy)

### Локальный запуск
1. Установите Docker и Docker Compose.
2. Скопируйте `.env.example` в `.env`.
3. Запустите контейнеры:
```bash
docker compose up --build
```

### Деплой на сервер (Caddy)
Для продакшена использовался `docker-compose.prod.yml` с автоматическим HTTPS:
```bash
docker compose -f docker-compose.prod.yml up -d
```

---
*Для работы с актуальной версией приложения используйте инструкции из основного [README.md](../README.md).*
