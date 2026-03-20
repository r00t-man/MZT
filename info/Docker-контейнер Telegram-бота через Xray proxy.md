# 🤖 Docker-контейнер с Telegram-ботом через Xray proxy: как восстановить доступ к Telegram API

Эта инструкция пригодится, если одновременно выполняются несколько условий:

- бот работает в Docker;
- сервер находится в РФ или у провайдера, где есть проблемы с доступом к `api.telegram.org`;
- контейнер стартует, но бот не отвечает на команды;
- в логах появляются ошибки вида:

```text
Cannot connect to host api.telegram.org:443 ssl:default [None]
```

или:

```text
ClientConnectorError: Cannot connect to host api.telegram.org:443
```

Ниже разобран рабочий способ, при котором **только контейнер бота** выходит в интернет через Xray proxy, а локальные сервисы вроде PostgreSQL и Redis продолжают работать напрямую.

---

## 1. Установка Xray

Установка Xray:

```bash
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
```

После установки основной конфиг обычно находится здесь:

```bash
/usr/local/etc/xray/config.json
```

Открыть его для редактирования можно так:

```bash
nano /usr/local/etc/xray/config.json
```

---

## 2. Настройка Xray: локальный HTTP proxy

Нужно создать или проверить inbound типа `http`.

Пример рабочего блока:

```json
{
  "inbounds": [
    {
      "tag": "http-in",
      "listen": "172.20.0.1",
      "port": 2081,
      "protocol": "http",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "YOUR_SERVER",
            "port": 443,
            "users": [
              {
                "id": "YOUR_UUID",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls"
      }
    }
  ]
}
```

### Важный момент

Если Xray слушает только:

```json
"listen": "127.0.0.1"
```

то Docker-контейнер до него **не достучится**.

Если контейнер работает в кастомной bridge-сети Docker, Xray должен слушать адрес gateway этой сети. В примере выше это:

```bash
172.20.0.1
```

---

## 3. Проверка конфига Xray

Перед перезапуском сервиса проверьте конфиг:

```bash
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
```

Если всё корректно, перезапустите Xray:

```bash
systemctl restart xray
systemctl status xray --no-pager
```

Проверьте, что proxy действительно слушает нужный адрес и порт:

```bash
ss -lntp | grep 2081
```

Ожидаемый результат:

```text
LISTEN 0 4096 172.20.0.1:2081 0.0.0.0:* users:(("xray",pid=...,fd=...))
```

---

## 4. Проверка proxy на хосте

Если Xray HTTP proxy уже поднят, проверьте его с хоста:

```bash
curl --proxy http://127.0.0.1:2081 https://ifconfig.me
```

или, если он слушает на gateway Docker-сети:

```bash
curl --proxy http://172.20.0.1:2081 https://ifconfig.me
```

Если в ответе возвращается IP удалённого узла или VPN, значит proxy работает.

---

## 5. Настройка Docker Compose для бота

Предположим, контейнер бота называется `bot`, а в одной сети с ним находятся `postgres` и `redis`.

В этом случае в сервис бота нужно добавить proxy-переменные окружения.

Пример рабочего `docker-compose.yml`:

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
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - bot_network

  redis:
    image: redis:7-alpine
    container_name: remnawave_bot_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - bot_network

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
      DOCKER_ENV: 'true'
      DATABASE_MODE: 'auto'
      POSTGRES_HOST: 'postgres'
      POSTGRES_PORT: '5432'
      POSTGRES_DB: '${POSTGRES_DB:-remnawave_bot}'
      POSTGRES_USER: '${POSTGRES_USER:-remnawave_user}'
      POSTGRES_PASSWORD: '${POSTGRES_PASSWORD:-secure_password_123}'
      REDIS_URL: 'redis://redis:6379/0'

      HTTP_PROXY: 'http://172.20.0.1:2081'
      HTTPS_PROXY: 'http://172.20.0.1:2081'
      ALL_PROXY: 'http://172.20.0.1:2081'
      http_proxy: 'http://172.20.0.1:2081'
      https_proxy: 'http://172.20.0.1:2081'
      all_proxy: 'http://172.20.0.1:2081'

      NO_PROXY: 'localhost,127.0.0.1,postgres,redis'
      no_proxy: 'localhost,127.0.0.1,postgres,redis'

    ports:
      - '8080:8080'
    networks:
      - bot_network

volumes:
  postgres_data:
  redis_data:

networks:
  bot_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
```

---

## 6. Почему не стоит бездумно использовать `host.docker.internal`

На первый взгляд кажется, что proxy можно передать так:

```yaml
HTTP_PROXY: http://host.docker.internal:2081
```

Но на Linux это часто приводит к ошибке.

Например, внутри контейнера проверка может показать:

```bash
docker exec -it remnawave_bot sh -lc 'getent hosts host.docker.internal'
```

Результат:

```text
172.17.0.1 host.docker.internal
```

При этом Xray может слушать на другом адресе:

```text
172.20.0.1:2081
```

Из-за этого контейнер подключается не туда и получает:

```text
Connection refused
```

Если у вас используется статическая bridge-сеть, надёжнее указывать **прямой IP gateway Docker-сети**.

---

## 7. Проверка, что контейнер действительно видит proxy

Проверка TCP-доступности:

```bash
docker exec -it remnawave_bot sh -lc 'python - <<EOF
import socket
s=socket.create_connection(("172.20.0.1",2081),5)
print("tcp ok")
s.close()
EOF'
```

Проверка HTTP через proxy:

```bash
docker exec -it remnawave_bot sh -lc 'python - <<EOF
import urllib.request
proxy_support = urllib.request.ProxyHandler({
    "http": "http://172.20.0.1:2081",
    "https": "http://172.20.0.1:2081",
})
opener = urllib.request.build_opener(proxy_support)
print(opener.open("https://ifconfig.me").read().decode()[:200])
EOF'
```

Если возвращается IP VPN/Xray-узла, значит контейнер уже выходит наружу через proxy.

---

## 8. Проверка переменных окружения внутри контейнера

Убедитесь, что proxy-переменные действительно доступны внутри контейнера:

```bash
docker exec -it remnawave_bot sh -lc 'env | grep -i proxy'
```

Ожидаемо вы увидите примерно следующее:

```text
HTTP_PROXY=http://172.20.0.1:2081
HTTPS_PROXY=http://172.20.0.1:2081
ALL_PROXY=http://172.20.0.1:2081
NO_PROXY=localhost,127.0.0.1,postgres,redis
...
```

---

## 9. Почему бот может не работать даже при исправном proxy

Даже если контейнер умеет выходить в интернет через proxy, сам Python-код может **игнорировать proxy env**.

Чаще всего это проявляется в таких случаях:

- `aiohttp.ClientSession()`;
- `aiogram Bot(...)`.

Именно тогда в логах снова появляются ошибки вида:

```text
Cannot connect to host api.telegram.org:443 ssl:default [None]
```

---

## 10. Исправление `aiohttp.ClientSession()`

Все места, где создаётся:

```python
aiohttp.ClientSession()
```

нужно перевести на:

```python
aiohttp.ClientSession(trust_env=True)
```

Если используется вариант с timeout:

```python
aiohttp.ClientSession(timeout=timeout)
```

его нужно заменить на:

```python
aiohttp.ClientSession(trust_env=True, timeout=timeout)
```

Так `aiohttp` начнёт использовать `HTTP_PROXY` и `HTTPS_PROXY` из окружения контейнера.

---

## 11. Исправление `aiogram Bot(...)`

Для `aiogram` одного `trust_env=True` часто недостаточно. Надёжнее сразу создавать `AiohttpSession` с proxy.

Пример:

```python
import os
from aiogram import Bot
from aiogram.client.session.aiohttp import AiohttpSession

telegram_proxy = os.getenv("HTTPS_PROXY") or os.getenv("HTTP_PROXY")

bot = Bot(
    token=settings.BOT_TOKEN,
    session=AiohttpSession(proxy=telegram_proxy) if telegram_proxy else None
)
```

На практике такие изменения часто приходится вносить сразу в несколько мест проекта, например:

- `app/bot.py`;
- `main.py`;
- `app/cabinet/dependencies.py`.

---

## 12. Обязательный пакет: `aiohttp-socks`

После подключения proxy-сессии у `aiogram` может появиться ошибка:

```text
In order to use aiohttp client for proxy requests, install aiohttp-socks
```

Это означает, что для работы proxy в `aiogram` нужен дополнительный пакет:

```text
aiohttp-socks
```

Его нужно добавить в `requirements.txt`.

Пример команды:

```bash
cp requirements.txt requirements.txt.bak-$(date +%F-%H%M%S)
grep -qxF 'aiohttp-socks' requirements.txt || echo 'aiohttp-socks' >> requirements.txt
```

---

## 13. Почему не стоит ставить пакет прямо в уже запущенный контейнер

Попытка установить зависимость напрямую внутри контейнера:

```bash
docker exec -it remnawave_bot sh -lc '/opt/venv/bin/pip install aiohttp-socks'
```

может закончиться ошибкой вида:

```text
Permission denied: '/opt/venv/lib/python3.13/site-packages/...'
```

Обычно причина в том, что контейнер запущен под непривилегированным пользователем, например `app`.

Правильный способ — **добавить зависимость в `requirements.txt` и пересобрать образ**.

---

## 14. Пересборка контейнера после добавления зависимости

После изменения зависимостей пересоберите контейнер:

```bash
docker compose down
docker compose up -d --build --force-recreate bot
```

Проверьте, что пакет действительно попал в образ:

```bash
docker exec -it remnawave_bot sh -lc '/opt/venv/bin/pip show aiohttp-socks'
```

---

## 15. Проверка логов бота

После пересборки удобно проверить логи:

```bash
docker logs -f --tail 200 remnawave_bot
```

Если всё исправлено, из логов должны исчезнуть ошибки вида:

```text
Cannot connect to host api.telegram.org:443
```

и:

```text
In order to use aiohttp client for proxy requests, install aiohttp-socks
```

---

## 16. Проверка статуса контейнера

Полезные команды:

```bash
docker ps
docker inspect -f 'RestartCount={{.RestartCount}} Health={{.State.Health.Status}}' remnawave_bot
```

Что важно проверить:

- `RestartCount=0` — контейнер не падает;
- `Health=healthy` — приложение поднялось полностью.

Если healthcheck всё ещё в статусе `starting`, дополнительно проверьте:

- отвечает ли `/health`;
- не пустой ли `WEB_API_DEFAULT_TOKEN`;
- не отключён ли веб-сервер настройками.

---

## 17. Полезные диагностические команды

### Посмотреть адрес proxy, который слушает Xray

```bash
ss -lntp | grep 2081
```

### Проверить env внутри контейнера

```bash
docker exec -it remnawave_bot sh -lc 'env | grep -i proxy'
```

### Проверить резолв `host.docker.internal`

```bash
docker exec -it remnawave_bot sh -lc 'getent hosts host.docker.internal || cat /etc/hosts'
```

### Проверить доступ к proxy по TCP

```bash
docker exec -it remnawave_bot sh -lc 'python - <<EOF
import socket
s=socket.create_connection(("172.20.0.1",2081),5)
print("tcp ok")
s.close()
EOF'
```

### Проверить внешний IP контейнера через proxy

```bash
docker exec -it remnawave_bot sh -lc 'python - <<EOF
import urllib.request
proxy_support = urllib.request.ProxyHandler({
    "http": "http://172.20.0.1:2081",
    "https": "http://172.20.0.1:2081",
})
opener = urllib.request.build_opener(proxy_support)
print(opener.open("https://ifconfig.me").read().decode()[:200])
EOF'
```

### Смотреть логи бота

```bash
docker logs -f --tail 200 remnawave_bot
```

---

## 18. Краткий итог

Если Telegram-бот в Docker не может достучаться до Telegram API на российском сервере, рабочая схема обычно выглядит так:

1. установить Xray на хосте;
2. поднять HTTP proxy inbound;
3. слушать не только `127.0.0.1`, а gateway Docker-сети, например `172.20.0.1`;
4. передать контейнеру `HTTP_PROXY`, `HTTPS_PROXY` и `ALL_PROXY`;
5. оставить `NO_PROXY` для `postgres`, `redis` и `localhost`;
6. проверить, что контейнер действительно выходит наружу через proxy;
7. включить `trust_env=True` для `aiohttp.ClientSession()`;
8. перевести `aiogram Bot(...)` на `AiohttpSession(proxy=...)`;
9. добавить зависимость `aiohttp-socks`;
10. пересобрать контейнер.

После этого бот обычно начинает нормально работать с Telegram API даже там, где прямой доступ к Telegram ограничивается.
