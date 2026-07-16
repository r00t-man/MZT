# 🔄 Remnawave — Обновление панели и нод

Полное руководство по безопасному обновлению Remnawave: панель (Docker), remnanode, и разбор всех типичных ошибок после апдейта.

---

## ⚡ Быстрая шпаргалка

| Задача | Скрипт | Что делает |
|--------|--------|-----------|
| Обновить панель | `update_remnawave.sh` | pull + up -d + nginx restart |
| Обновить все ноды | `update_nodes.sh` | параллельный docker pull на каждой ноде |
| Обновить панель + ноды | `update_remnawave.sh --nodes` | оба за один запуск |

```bash id="qs1x1z"
# Панель (бэкап + pull + restart nginx)
bash <(curl -s https://raw.githubusercontent.com/r00t-man/MZT/main/files/update_remnawave.sh)

# Ноды — все
bash <(curl -s https://raw.githubusercontent.com/r00t-man/MZT/main/files/update_nodes.sh)

# Конкретные ноды
bash update_nodes.sh node-se node-nl node-ee1
```

---

## 🚀 Общая схема

```text
┌─────────────────────────────────────────────┐
│              ОБНОВЛЕНИЕ ПАНЕЛИ               │
├─────────────────────────────────────────────┤
│  1. Бэкап .env + дамп PostgreSQL            │
│  2. docker compose pull   ← новые образы    │
│  3. docker compose up -d  ← рестарт         │
│  4. sleep 15-20           ← ждём PM2        │
│  5. docker restart nginx  ← ОБЯЗАТЕЛЬНО ⚠️  │
│  6. curl проверка API     ← HTTP 200        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│              ОБНОВЛЕНИЕ НОД                  │
├─────────────────────────────────────────────┤
│  Автоматически: конфиг Xray пушит панель    │
│  Вручную (редко): docker compose pull+up    │
│  Скрипт: update_nodes.sh (параллельно)      │
└─────────────────────────────────────────────┘
```

> [!WARNING]
> **Главный нюанс панели:** При `docker compose up -d` контейнер `remnawave` получает **новый внутренний IP** в Docker-сети. Nginx кешировал старый — начинает отдавать `502 Bad Gateway`. **Перезапуск nginx — обязательный шаг.**

---

## 📁 Структура

| Путь | Описание |
|------|----------|
| `/opt/remnawave/` | docker-compose панели |
| `/opt/remnawave/.env` | конфигурация (не коммитить!) |
| `/opt/remnawave/nginx/` | конфиг nginx-контейнера |
| `/opt/certs/` | SSL-сертификаты |

---

## 🐳 Контейнеры панели

| Контейнер | Назначение |
|-----------|------------|
| `remnawave` | основное приложение (NestJS + PM2) |
| `remnawave-db` | PostgreSQL |
| `remnawave-redis` | Redis |
| `remnawave-nginx` | реверс-прокси (SSL-терминация) |
| `remnawave-subscription-page` | страница подписки |

---

## 🛡️ 1. Бэкап перед обновлением

> [!TIP]
> Всегда делать перед мажорными обновлениями. При минорных патчах — по желанию.

```bash id="bk1x9z"
DATE=$(date +%F-%H%M%S)
mkdir -p /srv/backup_opt

# бэкап конфигурации
cp /opt/remnawave/.env /srv/backup_opt/remnawave_env_$DATE
cp -a /opt/remnawave/nginx/ /srv/backup_opt/remnawave_nginx_$DATE

# дамп базы данных
docker exec remnawave-db \
  pg_dump -U postgres postgres \
  > /srv/backup_opt/remnawave_db_$DATE.sql

echo "✅ Бэкап: /srv/backup_opt/remnawave_db_$DATE.sql"
```

---

## 📥 2. Обновление образов панели

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

## ⏳ 4. Ожидание старта (15–20 сек)

```bash id="wt4m2c"
sleep 20
docker logs remnawave --tail=10
```

Ищем в логах:

```
[NestApplication]   Nest application successfully started
```

---

## 🌐 5. Перезапустить nginx (КРИТИЧНО)

```bash id="nx5r8d"
docker restart remnawave-nginx
```

> [!NOTE]
> **Почему это обязательно:** При каждом рестарте контейнер `remnawave` получает новый IP в Docker overlay-сети. Nginx резолвит имя `remnawave` через DNS Docker при старте и кеширует IP. Без рестарта nginx будет ходить на старый (несуществующий) адрес → `502 Bad Gateway`.

---

## ✅ 6. Проверка

```bash id="ch6e9f"
# статус контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep remnawave

# проверка API
curl -s -o /dev/null -w "%{http_code}" https://<YOUR_PANEL_DOMAIN>/api
```

Ожидаемый результат: `200`

---

## 🤖 Автоматический скрипт панели

Все шаги в одной команде (бэкап + pull + рестарт + проверка):

```bash id="sc7g5h"
bash <(curl -s https://raw.githubusercontent.com/r00t-man/MZT/main/files/update_remnawave.sh)
```

Локальный запуск:

```bash id="sc7loc"
bash /path/to/update_remnawave.sh
```

Флаги:

| Флаг | Действие |
|------|----------|
| без флагов | только панель |
| `--nodes` | панель + все ноды (последовательно) |

---

## 🖥️ Обновление нод (remnanode)

### Как это устроено

- **Конфигурация Xray** — обновляется **автоматически** через панель. После изменения конфига Remnawave сам пушит новый `config.json` на ноды и перезапускает Xray.
- **Бинарь remnanode** — обновляется вручную командой `docker compose pull` на каждой ноде.

Ручное обновление нужно только при мажорных релизах с новой версией remnanode image.

---

### Обновить одну ноду

```bash id="nd1u3e"
ssh node-XX

# текущая версия
docker inspect remnanode --format '{{.Config.Image}}'

# обновить
cd /opt/remnanode
docker compose pull
docker compose up -d

# проверить
docker logs remnanode --tail=10
```

---

### Массовое обновление всех нод (скрипт)

```bash id="nd2m4f"
# Все ноды (берёт Host node-* из ~/.ssh/config)
bash <(curl -s https://raw.githubusercontent.com/r00t-man/MZT/main/files/update_nodes.sh)

# Конкретные ноды
bash update_nodes.sh node-se node-nl node-ee1

# Исключить ноду
EXCLUDE="node-de1" bash update_nodes.sh
```

Скрипт запускает обновление **параллельно** на всех нодах и выводит итоговый отчёт.

> [!NOTE]
> Ноды без remnanode (например, серверы только с node_exporter) нужно исключить через `EXCLUDE=`.

---

## 🔙 Откат (Rollback)

### Восстановить .env

```bash id="rb1e2w"
cp /srv/backup_opt/remnawave_env_ДАТА /opt/remnawave/.env
cd /opt/remnawave && docker compose up -d
docker restart remnawave-nginx
```

### Восстановить БД

```bash id="rb2d3x"
docker exec -i remnawave-db \
  psql -U postgres postgres \
  < /srv/backup_opt/remnawave_db_ДАТА.sql
```

### Откатить образ

```bash id="rb3i4y"
# Посмотреть доступные образы
docker images remnawave

# Указать конкретный тег в docker-compose.yml → image: remnawave/remnawave:x.y.z
cd /opt/remnawave
docker compose up -d
docker restart remnawave-nginx
```

---

## ⚠️ Возможные проблемы

### ❌ 502 Bad Gateway после обновления

**Причина:** nginx кешировал старый внутренний IP контейнера `remnawave`.

**Диагностика:**
```bash id="dg1a5z"
docker logs remnawave-nginx --tail=10 | grep "connect() failed"
```

**Решение:**
```bash id="fx1b6k"
docker restart remnawave-nginx
```

---

### ❌ Ноды показывают ECONNREFUSED / отключились

**Причина:** Во время даунтайма панели remnanode на нодах потерял соединение — это **нормально**.

**Ожидаемое поведение:** Панель автоматически переподключается к нодам и перезапускает Xray в течение **1–2 минут** после старта.

**Если нода не поднялась через 3 минуты:**
```bash id="dg2n7m"
# Проверить логи на ноде
ssh node-XX "docker logs remnanode --tail=20"

# Проверить статус контейнера
ssh node-XX "docker ps | grep remnanode"
```

---

### ❌ Контейнер remnawave не стартует (crash loop)

```bash id="dg5c2d"
# Смотреть логи
docker logs remnawave --tail=50

# Проверить корректность ENV
docker compose config
```

**Частые причины:**
- В мажорном обновлении появились **новые обязательные переменные** в `.env` — сравни с `.env.example` в репозитории
- `remnawave-db` не успел стартовать — подожди 10 сек и повтори `docker compose up -d`
- Ошибка синтаксиса в `.env` — проверь кавычки и спецсимволы

---

### ❌ API панели недоступен (бот пишет ошибку)

```bash id="dg4a1b"
# Статус контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}"

# Прямая проверка API
curl -s -o /dev/null -w "%{http_code}" https://<YOUR_PANEL_DOMAIN>/api

# Что видит nginx
docker logs remnawave-nginx --tail=5

# Что происходит внутри remnawave
docker logs remnawave --tail=20 | grep -E "ERROR|started|listening"
```

---

### ❌ `Reverse proxy and HTTPS are required` в логах

**Причина:** Запрос дошёл до remnawave без заголовка `X-Forwarded-Proto: https`. При прямом обращении к порту 3000 — норма.

**Решение:** В nginx-конфиге для панели должны быть:
```nginx id="ng3x9q"
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host   $host;
```

---

### ❌ Нода не обновляется скриптом (update_nodes.sh)

```bash id="dg6n3k"
# Проверить SSH-доступность
ssh -v node-XX "echo ok"

# Проверить путь до remnanode
ssh node-XX "ls /opt/remnanode /root/remnanode 2>/dev/null"

# Запустить обновление вручную на ноде
ssh node-XX "cd /opt/remnanode && docker compose pull && docker compose up -d"
```

---

## 🧠 Как это работает

- Remnawave — NestJS-приложение, работающее в Docker через PM2
- При `docker compose up -d` контейнер получает **новый IP** в overlay-сети Docker (это нормальное поведение Docker)
- Nginx использует DNS Docker для резолва имени `remnawave`, но кеширует результат при старте
- Правильная последовательность: **поднять remnawave → дождаться PM2 → перезапустить nginx**
- Remnanode (на нодах) — отдельный бинарь в Docker, хранит конфиг Xray. Получает обновления конфига от панели автоматически

---

## 🔥 Рекомендации

- Всегда делай **дамп БД** перед мажорными обновлениями
- Читай **CHANGELOG** перед мажорным апдейтом — там новые ENV-переменные
- Используй скрипты — они делают всё в правильном порядке и логируют результат
- Держи **2–3 последних дампа** (автобэкап каждый час через `backup_remna_hour.sh`)
- После обновления **проверяй в UI панели** что все ноды подключены — зелёные
- Ноды с только `node_exporter` (без remnanode) **исключи** из `update_nodes.sh` через `EXCLUDE=`

---

## 📋 Чеклист после обновления

- [ ] `docker ps` — все 5 контейнеров `Up`
- [ ] `curl` на API — HTTP `200`
- [ ] В UI панели все ноды зелёные (1–2 мин на восстановление)
- [ ] Подписки открываются у клиентов
- [ ] Нет ошибок в `docker logs remnawave --tail=30`

---

## 🎉 Готово!
