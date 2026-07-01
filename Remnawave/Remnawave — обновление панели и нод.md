# 🔄 Remnawave — Обновление панели и нод

Полная инструкция по безопасному обновлению Remnawave: панель (Docker), ноды (remnanode), и исправление типовых ошибок после апдейта.

---

## 🚀 Общая схема

```text
docker compose pull   ← новые образы
        ↓
docker compose up -d  ← рестарт с новым образом
        ↓
docker restart nginx  ← сброс DNS-кеша (ОБЯЗАТЕЛЬНО!)
        ↓
проверка статуса нод
```

> ⚠️ **Критический момент:** После перезапуска контейнер `remnawave` получает **новый внутренний IP** в Docker-сети. Nginx кеширует старый IP и начинает отдавать `502 Bad Gateway`. Перезапуск nginx — обязательный шаг.

---

## 📁 Структура

| Путь | Описание |
|------|----------|
| `/opt/remnawave/` | docker-compose панели |
| `/opt/remnawave/.env` | конфигурация (не коммитить!) |
| `/opt/remnawave/nginx/` | конфиг nginx-контейнера |
| `/opt/certs/` | SSL-сертификаты |

---

## 🐳 Контейнеры

| Контейнер | Назначение |
|-----------|------------|
| `remnawave` | основное приложение (API, PM2) |
| `remnawave-db` | PostgreSQL |
| `remnawave-redis` | Redis |
| `remnawave-nginx` | реверс-прокси (SSL-терминация) |
| `remnawave-subscription-page` | страница подписки |

---

## 🛡️ 1. Бэкап перед обновлением

```bash id="bk1x9z"
DATE=$(date +%F-%H%M%S)
mkdir -p /srv/backup_opt

# бэкап .env и конфигов
cp /opt/remnawave/.env /srv/backup_opt/remnawave_env_$DATE
cp -a /opt/remnawave/nginx/ /srv/backup_opt/remnawave_nginx_$DATE

# дамп базы данных
docker exec remnawave-db \
  pg_dump -U postgres postgres \
  > /srv/backup_opt/remnawave_db_$DATE.sql

echo "✅ Бэкап: /srv/backup_opt/remnawave_db_$DATE.sql"
```

---

## 📥 2. Обновление образов

```bash id="pu2w7a"
cd /opt/remnawave
docker compose pull
```

---

## 🔁 3. Перезапуск панели

```bash id="up3k4b"
cd /opt/remnawave
docker compose up -d
```

---

## ⏳ 4. Подождать старта (10–15 сек)

```bash id="wt4m2c"
sleep 15
docker logs remnawave --tail=10
```

Убедись что в логах видно:

```
[NestApplication]   Nest application successfully started
```

---

## 🌐 5. Перезапустить nginx (КРИТИЧНО)

```bash id="nx5r8d"
docker restart remnawave-nginx
```

> 💡 **Почему это обязательно:** При каждом рестарте контейнер `remnawave` получает новый IP в Docker-сети. Nginx резолвит DNS при старте и кеширует IP. Без перезапуска nginx будет ходить на старый (несуществующий) адрес → `502 Bad Gateway`.

---

## ✅ 6. Проверка

```bash id="ch6e9f"
# статус контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep remnawave

# проверка API
curl -s -o /dev/null -w "%{http_code}" https://panel.example.com/api
```

Ожидаемый результат: `200`

---

## 🤖 Автоматический скрипт

Все шаги в одной команде:

```bash id="sc7g5h"
bash <(curl -s https://raw.githubusercontent.com/r00t-man/MZT/main/files/update_remnawave.sh)
```

Или запустить локально (если скрипт уже скачан):

```bash id="sc7loc"
bash /opt/github/MZT/files/update_remnawave.sh
```

---

## 🔙 Откат (Rollback)

### Восстановить .env

```bash id="rb1e2w"
cp /srv/backup_opt/remnawave_env_ДАТА /opt/remnawave/.env
```

### Восстановить БД

```bash id="rb2d3x"
docker exec -i remnawave-db \
  psql -U postgres postgres \
  < /srv/backup_opt/remnawave_db_ДАТА.sql
```

### Откатить образ

```bash id="rb3i4y"
cd /opt/remnawave

# посмотреть доступные теги
docker images remnawave

# откатиться на конкретный образ — правь image: в docker-compose.yml
docker compose up -d

docker restart remnawave-nginx
```

---

## ⚠️ Возможные проблемы

### ❌ 502 Bad Gateway после обновления

**Причина:** nginx кешировал старый внутренний IP контейнера.

**Диагностика:**

```bash id="dg1a5z"
docker logs remnawave-nginx --tail=10 | grep "Connection refused"
```

**Решение:**

```bash id="fx1b6k"
docker restart remnawave-nginx
```

---

### ❌ Ноды показывают ECONNREFUSED в логах панели

**Причина:** remnanode на нодах потерял связь с панелью во время даунтайма и стал `inactive`.

**Диагностика:**

```bash id="dg2n7m"
docker logs remnawave --tail=20 | grep "ECONNREFUSED\|health check"
```

**Решение:** ноды **восстанавливаются автоматически** — панель сама переподключается и перезапускает Xray на нодах в течение 1–2 минут после старта.

Если нода так и не поднялась — зайди на неё и проверь:

```bash id="fx2n8p"
ssh node-XX "docker ps | grep remnanode && docker logs remnanode --tail=10"
```

---

### ❌ `Reverse proxy and HTTPS are required` в логах remnawave

**Причина:** запрос дошёл до remnawave без заголовка `X-Forwarded-Proto: https`. Бывает при прямом обращении к порту 3000 или неправильном nginx-конфиге.

**Решение:** убедись что в nginx-конфиге для панели есть:

```nginx id="ng3x9q"
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host   $host;
```

Если запрос идёт через HTTP-локалхост (напр. из скриптов) — это норма, ошибка в логах не критична.

---

### ❌ API панели недоступен (бот пишет ошибку)

**Быстрая диагностика:**

```bash id="dg4a1b"
# статус контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}"

# прямая проверка API
curl -s -o /dev/null -w "%{http_code}" https://panel.example.com/api

# что видит nginx
docker logs remnawave-nginx --tail=5

# что происходит внутри remnawave
docker logs remnawave --tail=20 | grep -E "ERROR|started|listening"
```

---

### ❌ Контейнер не стартует (crash loop)

```bash id="dg5c2d"
docker logs remnawave --tail=50

# проверь ENV на синтаксические ошибки
docker compose config
```

Частые причины:
- новые обязательные переменные в `.env` (сравни с changelog)
- недоступна база данных (`remnawave-db` не успел стартовать)

---

## 🔄 Обновление нод (remnanode)

Remnanode на нодах обновляются **автоматически через панель** — Remnawave сам пушит новую конфигурацию Xray при изменении. Вручную обновлять бинарь remnanode нужно только при мажорных апдейтах.

### Ручное обновление remnanode на ноде

```bash id="nd1u3e"
ssh node-XX

# посмотреть текущую версию
docker exec remnanode ./rw-node --version

# обновить образ
cd /opt/remnanode   # или где лежит docker-compose
docker compose pull
docker compose up -d

# проверка
docker logs remnanode --tail=10
```

### Массовое обновление всех нод скриптом

```bash id="nd2m4f"
bash /opt/update_nodes.sh
```

---

## 🧠 Как это работает

- Remnawave — NestJS-приложение, запущенное в Docker через PM2
- При `docker compose up -d` контейнер получает **новый IP** в overlay-сети Docker (это нормально)
- nginx использует DNS Docker-сети для резолва имени `remnawave`, но кеширует IP при старте
- Поэтому: **сначала поднять remnawave → дождаться старта → перезапустить nginx**

---

## 🔥 Рекомендации

- всегда делай дамп БД перед обновлением
- читай CHANGELOG перед мажорным апдейтом — там новые ENV-переменные
- используй скрипт `update_remnawave.sh` — он делает всё в правильном порядке
- держи 2–3 последних дампа БД (автобэкап каждый час — `backup_remna_hour.sh`)
- после обновления проверяй что все ноды подключены в UI панели

---

## 🎉 Готово!
