# Remna Help
## Схема проекта:

```text
                                      INTERNET
                                          |
                                          v
                              +----------------------+
                              | DNS / A-records      |
                              | panel.domen-1.ru     |
                              | users.domen-2.ru     |
                              | lk.domen-2.ru        |
                              +----------+-----------+
                                         |
                                         v
                                +------------------+
                                | remnawave-nginx  |
                                | nginx:1.28       |
                                | :443 / :80       |
                                +--------+---------+
                                         |
          +------------------------------+------------------------------+
          |                              |                              |
          |                              |                              |
          v                              v                              v

+----------------------+      +---------------------------+    +----------------------+
| panel.domen-1.ru     |      | users.domen-2.ru          |    | lk.domen-2.ru        |
| /                    |      | /                         |    | /                    |
| -> remnawave:3000    |      | -> subscription:3010      |    | -> /srv/cabinet      |
+----------------------+      +---------------------------+    +----------+-----------+
                                                                             |
                                                                             |
                                            +--------------------------------+----------------------+
                                            |                                                       |
                                            v                                                       v
                                 +------------------------+                              +----------------------+
                                 | /api/                  |                              | /api/cabinet/        |
                                 | -> remnawave:3000      |                              | -> remnawave_bot:8080|
                                 +------------------------+                              +----------------------+


========================================================================================
                               DOCKER NETWORKS / SERVICES
========================================================================================

                 remnawave-network (172.18.0.0/16)
     ----------------------------------------------------------------
       |                    |                       |                |
       v                    v                       v                v
+---------------+   +----------------------+   +--------------+   +------------------+
| remnawave     |   | remnawave-subscript. |   | remnawave-   |   | remnawave_bot    |
| backend       |   | page                 |   | nginx        |   | bot web/api      |
| :3000         |   | :3010                |   | reverse proxy|   | :8080            |
+-------+-------+   +----------------------+   +--------------+   +---------+--------+
        |                                                                      |
        |                                                                      |
        v                                                                      v
+---------------+                                                     (виден nginx'у
| remnawave-db  |                                                      и может ходить
| postgres      |                                                      в remnawave API)
+---------------+
        |
        v
+---------------+
| remnawave-    |
| redis/valkey  |
+---------------+


                    bot-network (172.20.0.0/16)
     ----------------------------------------------------------------
       |                    |                    |
       v                    v                    v
+---------------+   +----------------+   +---------------------+
| remnawave_bot |   | remnawave_     |   | remnawave_          |
| main service  |   | bot_db         |   | bot_redis           |
| python main.py|   | postgres:15    |   | redis:7             |
+---------------+   +----------------+   +---------------------+


========================================================================================
                                   FILESYSTEM
========================================================================================

/opt/certs
 ├─ panel_fullchain.pem
 ├─ panel_privkey.key
 ├─ users_fullchain.pem
 ├─ users_privkey.key
 ├─ lk_fullchain.pem
 └─ lk_privkey.key

/opt/remnawave/
 ├─ docker-compose.yml
 ├─ nginx/
 │  ├─ docker-compose.yml
 │  └─ nginx.conf
 └─ subscription/
    └─ docker-compose.yml

/opt/remnawave-bedolaga-telegram-bot/
 ├─ docker-compose.yml
 └─ .env

/opt/bedolaga-cabinet/
 └─ исходники cabinet

/srv/cabinet/
 └─ собранная статика cabinet
```

И более коротко, логически:

```text
Telegram user
    |
    v
@YOUR_BOT_USERNAME
    |
    v
remnawave_bot
    | \
    |  \__ bot_db
    |  \__ bot_redis
    |
    \____ remnawave API

Browser
   |
   v
nginx:443
   |-- panel.domen-1.ru  -> remnawave
   |-- users.domen-2.ru  -> remnawave-subscription-page
   |-- lk.domen-2.ru     -> /srv/cabinet
   |                        |-- /api/          -> remnawave
   |                        \-- /api/cabinet/  -> remnawave_bot
```

Ключевая идея у тебя такая:

* `nginx` сидит в `remnawave-network`
* `remnawave_bot` сидит **в двух сетях сразу**
* поэтому бот одновременно:

  * видит свои `bot_db` и `bot_redis` в `bot-network`
  * доступен nginx и Remnawave в `remnawave-network`

Cхема: 
3 веб-домена
1 Telegram-бот
отдельная статика cabinet в `/srv/cabinet`
nginx раздаёт cabinet и проксирует `/api/` в Remnawave, а `/api/cabinet/` в bot backend.    

# 0. Текущая рабочая схема, если кратко

* `panel.domen-1.ru` → Remnawave panel
* `users.domen-2.ru` → subscription page
* `lk.domen-2.ru` → Bedolaga cabinet
* `@telegram_vpn_bot` → Telegram bot
* certs → `/opt/certs`
* cabinet static → `/srv/cabinet`
* nginx config → `/opt/remnawave/nginx/nginx.conf`
* bot config → `/opt/remnawave-bedolaga-telegram-bot/.env`
* remnawave network → `172.18.0.0/16`
* bot network → `172.20.0.0/16`
* bot подключён в обе сети
* BotFather domain добавлен

# 1. Что именно ты поднимаешь

В итоге на сервере будут работать 3 веб-домена и 1 Telegram-бот:

* панель Remnawave
  `https://panel.domen-1.ru`

* домен подписок Remnawave
  `https://users.domen-2.ru`

* cabinet Bedolaga
  `https://lk.domen-2.ru`

* Telegram-бот
  `@YOUR_BOT_USERNAME`

# 2. Итоговая архитектура

На сервере работают такие сервисы:

## Remnawave

* `remnawave` — backend панели
* `remnawave-db` — PostgreSQL
* `remnawave-redis` — Valkey/Redis

## Subscription page

* `remnawave-subscription-page`

## Nginx

* `remnawave-nginx`

## Bedolaga bot

* `remnawave_bot`
* `remnawave_bot_db`
* `remnawave_bot_redis`

## Frontend cabinet

* исходники собираются отдельно
* готовая статика кладётся в `/srv/cabinet`
* nginx её раздаёт

# 3. Каталоги

Создай такую структуру:

```bash
mkdir -p /opt/certs
mkdir -p /opt/remnawave
mkdir -p /opt/remnawave/subscription
mkdir -p /opt/remnawave/nginx
mkdir -p /opt/remnawave-bedolaga-telegram-bot
mkdir -p /opt/bedolaga-cabinet
mkdir -p /srv/cabinet
```

Итог:

* `/opt/certs` — все TLS-серты
* `/opt/remnawave` — основной стек Remnawave
* `/opt/remnawave/subscription` — subscription page
* `/opt/remnawave/nginx` — nginx
* `/opt/remnawave-bedolaga-telegram-bot` — бот
* `/opt/bedolaga-cabinet` — исходники cabinet
* `/srv/cabinet` — собранная статика cabinet

# 4. Подготовка сервера

На Ubuntu 24.04:

```bash
apt update
apt install -y docker.io docker-compose-plugin git curl
systemctl enable --now docker
```

Проверь:

```bash
docker --version
docker compose version
```

# 5. DNS

До запуска сервисов должны быть готовы A-записи:

* `panel.domen-1.ru` → IP сервера
* `users.domen-2.ru` → IP сервера
* `lk.domen-2.ru` → IP сервера

# 6. Сертификаты

Все сертификаты хранятся в `/opt/certs`.

Нужно получить 3 пары:

```text
/opt/certs/panel_fullchain.pem
/opt/certs/panel_privkey.key

/opt/certs/users_fullchain.pem
/opt/certs/users_privkey.key

/opt/certs/lk_fullchain.pem
/opt/certs/lk_privkey.key
```

Имена файлов важны, потому что они уже зашиты в nginx.

# 7. Развёртывание Remnawave

Перейди в `/opt/remnawave` и создай `docker-compose.yml`.

## `/opt/remnawave/docker-compose.yml`

```yaml
x-common: &common
  ulimits:
    nofile:
      soft: 1048576
      hard: 1048576
  restart: always
  networks:
    - remnawave-network

x-logging: &logging
  logging:
    driver: json-file
    options:
      max-size: 100m
      max-file: 5

x-env: &env
  env_file: .env

services:
  remnawave:
    image: remnawave/backend:2
    container_name: remnawave
    hostname: remnawave
    <<: [*common, *logging, *env]
    ports:
      - 127.0.0.1:3000:${APP_PORT:-3000}
      - 127.0.0.1:3001:${METRICS_PORT:-3001}
    healthcheck:
      test: ['CMD-SHELL', 'curl -f http://localhost:${METRICS_PORT:-3001}/health']
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
    depends_on:
      remnawave-db:
        condition: service_healthy
      remnawave-redis:
        condition: service_healthy

  remnawave-db:
    image: postgres:17.6
    container_name: remnawave-db
    hostname: remnawave-db
    <<: [*common, *logging, *env]
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - TZ=UTC
    ports:
      - 127.0.0.1:6767:5432
    volumes:
      - remnawave-db-data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}']
      interval: 3s
      timeout: 10s
      retries: 3

  remnawave-redis:
    image: valkey/valkey:8.1-alpine
    container_name: remnawave-redis
    hostname: remnawave-redis
    <<: [*common, *logging]
    command: >
      valkey-server
      --save ""
      --appendonly no
      --maxmemory-policy noeviction
      --loglevel warning
    healthcheck:
      test: ['CMD', 'valkey-cli', 'ping']
      interval: 3s
      timeout: 3s
      retries: 3

networks:
  remnawave-network:
    name: remnawave-network
    driver: bridge
    external: false

volumes:
  remnawave-db-data:
    name: remnawave-db-data
    driver: local
    external: false
```

## `/opt/remnawave/.env`

Минимально тебе нужны такие параметры:

```env
APP_PORT=3000
METRICS_PORT=3001

DATABASE_URL=postgresql://postgres:YOUR_DB_PASSWORD@remnawave-db:5432/postgres

REDIS_HOST=remnawave-redis
REDIS_PORT=6379

JWT_AUTH_SECRET=YOUR_LONG_SECRET
JWT_API_TOKENS_SECRET=YOUR_LONG_SECRET

FRONT_END_DOMAIN=panel.domen-1.ru
SUB_PUBLIC_DOMAIN=users.domen-2.ru

POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_DB_PASSWORD
POSTGRES_DB=postgres
```

Запуск:

```bash
cd /opt/remnawave
docker compose up -d
```

Проверка:

```bash
docker ps
docker logs --tail=100 remnawave
```

# 8. Развёртывание subscription page

Каталог:
`/opt/remnawave/subscription`

## `/opt/remnawave/subscription/docker-compose.yml`

```yaml
services:
  remnawave-subscription-page:
    image: remnawave/subscription-page:latest
    container_name: remnawave-subscription-page
    hostname: remnawave-subscription-page
    restart: always
    env_file:
      - .env
    ports:
      - "127.0.0.1:3010:3010"
    networks:
      - remnawave-network

networks:
  remnawave-network:
    external: true
```

## `/opt/remnawave/subscription/.env`

```env
APP_PORT=3010
REMNAWAVE_PANEL_URL=http://remnawave:3000
REMNAWAVE_API_TOKEN=YOUR_REMNAWAVE_API_TOKEN
CUSTOM_SUB_PREFIX=
```

Запуск:

```bash
cd /opt/remnawave/subscription
docker compose up -d
```

Проверка:

```bash
docker logs --tail=100 remnawave-subscription-page
```

# 9. Развёртывание Bedolaga bot

Склонируй репозиторий:

```bash
cd /opt
git clone https://github.com/BEDOLAGA-DEV/remnawave-bedolaga-telegram-bot.git
mv remnawave-bedolaga-telegram-bot /opt/remnawave-bedolaga-telegram-bot
cd /opt/remnawave-bedolaga-telegram-bot
cp .env.example .env
```

## `/opt/remnawave-bedolaga-telegram-bot/docker-compose.yml`

Используй такую рабочую версию:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: remnawave_bot_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-remnawave_bot}
      POSTGRES_USER: ${POSTGRES_USER:-remnawave_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-secure_password_123}
      POSTGRES_INITDB_ARGS: '--encoding=UTF8 --locale=C'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - bot_network
    healthcheck:
      test:
        [
          'CMD-SHELL',
          'pg_isready -U ${POSTGRES_USER:-remnawave_user} -d ${POSTGRES_DB:-remnawave_bot}',
        ]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s

  redis:
    image: redis:7-alpine
    container_name: remnawave_bot_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - bot_network
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 30s
      timeout: 10s
      retries: 3

  bot:
    build: .
    container_name: remnawave_bot
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    env_file:
      - .env
    environment:
      FORCE_COLOR: '1'
      DOCKER_ENV: 'true'
      DATABASE_MODE: 'auto'
      POSTGRES_HOST: 'postgres'
      POSTGRES_PORT: '5432'
      POSTGRES_DB: '${POSTGRES_DB:-remnawave_bot}'
      POSTGRES_USER: '${POSTGRES_USER:-remnawave_user}'
      POSTGRES_PASSWORD: '${POSTGRES_PASSWORD:-secure_password_123}'
      REDIS_URL: 'redis://redis:6379/0'
      TZ: 'Europe/Moscow'
      LOCALES_PATH: '${LOCALES_PATH:-/app/locales}'
    volumes:
      - ./logs:/app/logs:rw
      - ./data:/app/data:rw
      - ./locales:/app/locales:rw
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - ./uploads:/app/uploads:rw
      - ./vpn_logo.png:/app/vpn_logo.png:ro
    ports:
      - '${WEB_API_PORT:-8080}:8080'
    networks:
      - bot_network
      - remnawave-network
    healthcheck:
      test:
        [
          'CMD-SHELL',
          'python -c "import requests, os; requests.get(''http://localhost:8080/health'', headers={''X-API-Key'': os.environ.get(''WEB_API_DEFAULT_TOKEN'')}, timeout=5) or exit(1)"',
        ]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  bot_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    driver_opts:
      com.docker.network.driver.mtu: 1350

  remnawave-network:
    external: true
```

## Ключевые переменные `/opt/remnawave-bedolaga-telegram-bot/.env`

Обязательно проверь и задай:

```env
BOT_TOKEN=YOUR_BOT_TOKEN

REMNAWAVE_API_URL=https://panel.domen-1.ru
REMNAWAVE_API_KEY=YOUR_REMNAWAVE_API_KEY
REMNAWAVE_AUTH_TYPE=api_key

CABINET_ENABLED=true
CABINET_URL=https://lk.domen-2.ru
CABINET_JWT_SECRET=YOUR_RANDOM_SECRET
CABINET_ALLOWED_ORIGINS=https://lk.domen-2.ru
CABINET_EMAIL_AUTH_ENABLED=false

WEB_API_ENABLED=true
WEB_API_HOST=0.0.0.0
WEB_API_PORT=8080
WEB_API_ALLOWED_ORIGINS=https://lk.domen-2.ru
WEB_API_DEFAULT_TOKEN=YOUR_RANDOM_API_TOKEN

MAIN_MENU_MODE=default
CONNECT_BUTTON_MODE=miniapp_subscription
MINIAPP_STATIC_PATH=miniapp
```

### Важно

Не оставляй пустыми поля, которые ожидаются как числа.
Например, если не используешь такие параметры, удаляй строки совсем:

```env
FREEKASSA_PAYMENT_SYSTEM_ID=
LOG_ROTATION_TOPIC_ID=
```

### Каталоги бота

Перед первым запуском создай:

```bash
cd /opt/remnawave-bedolaga-telegram-bot
mkdir -p data/backups data/temp logs uploads locales
chmod -R 777 data logs uploads locales
```

Запуск:

```bash
cd /opt/remnawave-bedolaga-telegram-bot
docker compose up -d --build
```

Проверка:

```bash
docker logs --tail=200 remnawave_bot
```

Ты должен увидеть в логах, что:

* HTTP-сервисы активны
* web api запущен на `0.0.0.0:8080`

# 10. Сборка Bedolaga cabinet

```bash
cd /opt
git clone https://github.com/BEDOLAGA-DEV/bedolaga-cabinet.git
mv bedolaga-cabinet /opt/bedolaga-cabinet
cd /opt/bedolaga-cabinet
cp .env.example .env
```

## `/opt/bedolaga-cabinet/.env`

```env
VITE_API_URL=/api
VITE_TELEGRAM_BOT_USERNAME=YOUR_BOT_USERNAME_WITHOUT_AT

VITE_APP_NAME=YOUR_APP_NAME
VITE_APP_LOGO=Y

CABINET_PORT=3020
```

Пример:

```env
VITE_API_URL=/api
VITE_TELEGRAM_BOT_USERNAME=telegram_vpn_bot
VITE_APP_NAME=telegram_vpn
VITE_APP_LOGO=H
CABINET_PORT=3020
```

## Сборка статики

```bash
cd /opt/bedolaga-cabinet
docker compose build
docker create --name tmp_cabinet bedolaga-cabinet-cabinet-frontend:latest
mkdir -p ./cabinet-dist
docker cp tmp_cabinet:/usr/share/nginx/html/. ./cabinet-dist/
docker rm tmp_cabinet
mkdir -p /srv/cabinet
cp -r ./cabinet-dist/* /srv/cabinet/
```

Проверь:

```bash
ls -lah /srv/cabinet
```

Должны быть:

* `index.html`
* `assets/`
* `miniapp/`

# 11. Развёртывание nginx

Каталог:
`/opt/remnawave/nginx`

## `/opt/remnawave/nginx/docker-compose.yml`

```yaml
services:
  remnawave-nginx:
    image: nginx:1.28
    container_name: remnawave-nginx
    hostname: remnawave-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /opt/remnawave/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /opt/certs:/opt/certs:ro
      - /srv/cabinet:/srv/cabinet:ro
    networks:
      - remnawave-network

networks:
  remnawave-network:
    name: remnawave-network
    external: true
```

## `/opt/remnawave/nginx/nginx.conf`

Подставь свои домены и сертификаты:

```nginx
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    server_tokens off;
    client_max_body_size 50m;

    upstream remnawave {
        server remnawave:3000;
    }

    upstream remnawave_subscription_page {
        server remnawave-subscription-page:3010;
    }

    upstream remnawave_bot_web {
        server remnawave_bot:8080;
    }

    server {
        listen 80;
        listen [::]:80;
        server_name panel.domen-1.ru users.domen-2.ru lk.domen-2.ru;

        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        http2 on;
        server_name panel.domen-1.ru;

        ssl_certificate /opt/certs/panel_fullchain.pem;
        ssl_certificate_key /opt/certs/panel_privkey.key;

        location / {
            proxy_http_version 1.1;
            proxy_pass http://remnawave;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        http2 on;
        server_name users.domen-2.ru;

        ssl_certificate /opt/certs/users_fullchain.pem;
        ssl_certificate_key /opt/certs/users_privkey.key;

        location / {
            proxy_http_version 1.1;
            proxy_pass http://remnawave_subscription_page;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        http2 on;
        server_name lk.domen-2.ru;

        ssl_certificate /opt/certs/lk_fullchain.pem;
        ssl_certificate_key /opt/certs/lk_privkey.key;

        root /srv/cabinet;
        index index.html;

        location /api/cabinet/ {
            proxy_http_version 1.1;
            proxy_pass http://remnawave_bot_web/cabinet/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
        }

        location /api/ {
            proxy_http_version 1.1;
            proxy_pass http://remnawave;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
        }

        location / {
            try_files $uri $uri/ /index.html;
        }
    }

    server {
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        server_name _;

        ssl_certificate /opt/certs/panel_fullchain.pem;
        ssl_certificate_key /opt/certs/panel_privkey.key;

        return 444;
    }
}
```

## Запуск nginx

```bash
cd /opt/remnawave/nginx
docker compose up -d
docker exec remnawave-nginx nginx -t
docker exec remnawave-nginx nginx -s reload
```

# 12. Порядок запуска всего проекта

Вот правильная последовательность:

## Шаг 1

Подготовить DNS и сертификаты

## Шаг 2

Поднять Remnawave:

```bash
cd /opt/remnawave
docker compose up -d
```

## Шаг 3

Поднять subscription page:

```bash
cd /opt/remnawave/subscription
docker compose up -d
```

## Шаг 4

Поднять Bedolaga bot:

```bash
cd /opt/remnawave-bedolaga-telegram-bot
docker compose up -d --build
```

## Шаг 5

Собрать cabinet и скопировать статику:

```bash
cd /opt/bedolaga-cabinet
docker compose build
docker create --name tmp_cabinet bedolaga-cabinet-cabinet-frontend:latest
mkdir -p ./cabinet-dist
docker cp tmp_cabinet:/usr/share/nginx/html/. ./cabinet-dist/
docker rm tmp_cabinet
mkdir -p /srv/cabinet
cp -r ./cabinet-dist/* /srv/cabinet/
```

## Шаг 6

Поднять nginx:

```bash
cd /opt/remnawave/nginx
docker compose up -d
docker exec remnawave-nginx nginx -t
docker exec remnawave-nginx nginx -s reload
```

# 13. Проверки после запуска

## Панель

```bash
curl -Ik https://panel.domen-1.ru
```

## Подписки

```bash
curl -Ik https://users.domen-2.ru
```

## Cabinet статика

```bash
curl -Ik https://lk.domen-2.ru
```

## Cabinet backend

```bash
curl -k https://lk.domen-2.ru/api/cabinet/branding
curl -k https://lk.domen-2.ru/api/cabinet/auth/oauth/providers
```

Ожидаемо:

```json
{"name":"Cabinet", ...}
{"providers":[]}
```

## API Remnawave за cabinet-доменом

```bash
curl -k https://lk.domen-2.ru/api/system/stats
```

## Проверка контейнеров

```bash
docker ps
```

## Проверка сети

```bash
docker network inspect remnawave-network
docker network inspect remnawave-bedolaga-telegram-bot_bot_network
```

# 14. BotFather

Очень важный шаг.

У бота в BotFather нужно:

* открыть настройки домена логина
* добавить `lk.domen-2.ru`

Без этого Telegram Login Widget может не завершать авторизацию.

# 15. Что менять при переносе на новый сервер

На новом проекте тебе надо заменить:

## В Remnawave

* `FRONT_END_DOMAIN`
* `SUB_PUBLIC_DOMAIN`
* все секреты и пароли

## В subscription

* `REMNAWAVE_API_TOKEN`

## В боте

* `BOT_TOKEN`
* `REMNAWAVE_API_URL`
* `REMNAWAVE_API_KEY`
* `CABINET_URL`
* `CABINET_ALLOWED_ORIGINS`
* `WEB_API_ALLOWED_ORIGINS`
* `CABINET_JWT_SECRET`
* `WEB_API_DEFAULT_TOKEN`

## Во frontend cabinet

* `VITE_TELEGRAM_BOT_USERNAME`
* `VITE_APP_NAME`
* `VITE_APP_LOGO`

## В nginx

* `server_name`
* пути к сертификатам, если названия файлов другие

## В DNS

* A-записи

## В BotFather

* новый домен кабинета

# 16. Типовые проблемы

## Cabinet открывается, но логин по Telegram не работает

Проверяй:

* `CABINET_ENABLED=true`
* `WEB_API_ENABLED=true`
* bot в сети `remnawave-network`
* `lk.domen-2.ru` добавлен в BotFather
* `curl https://lk.domen-2.ru/api/cabinet/branding` отдаёт JSON

## Nginx не стартует

Проверяй:

```bash
docker logs remnawave-nginx
docker exec remnawave-nginx nginx -t
```

## `host not found in upstream`

Контейнер не поднят или не в той сети.

## `duplicate listen options`

Убери `reuseport`, если он где-то остался.

## Бот падает с validation error

Не оставляй пустые числовые поля в `.env`.

## Бот падает с `Permission denied`

Выдай права на:

* `data`
* `logs`
* `uploads`
* `locales`

Например:

```bash
chmod -R 777 data logs uploads locales
```
