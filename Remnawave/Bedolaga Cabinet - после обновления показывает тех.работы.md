# 🚨 Кабинет показывает страницу «Технические работы» после обновления бота

**Версии, при которых замечено:** Remnawave Bedolaga Bot ≥ 2.8.0

> [!NOTE]
> Возникает именно после шагов из [Remnawave Bedolaga Telegram Bot — update](./Bedolaga%20Telegram%20Bot%20-%20update.md)
> (`docker compose down` → `up -d`) — Docker может поднять контейнер бота в новой/другой сети.

---

## 🔍 Симптомы

- `lk.ваш-домен` открывается, но показывает страницу «Ведутся технические работы»
- Прямой запрос к API через nginx возвращает **502 Bad Gateway**
- Локальный `curl http://localhost:8080/cabinet/branding` — работает нормально
- `docker ps` показывает все контейнеры `Up` и `healthy`
- В Redis: `maintenance_status → is_active: false` (режим тех.работ выключен в конфиге)

---

## 🧠 Причина

После обновления бот поднимается в **изолированной сети** `bot_network`, а nginx остаётся в `remnawave-network`. Эти сети не связаны — nginx не может разрезолвить имя контейнера `remnawave_bot`, получает Connection refused и отдаёт 502.

```text
nginx (remnawave-network)
       ↓
  "remnawave_bot:8080"   ←── не резолвится
       ↓
     502 Bad Gateway
       ↓
  React SPA → показывает страницу ошибки
```

Фронтенд (React SPA) при 502 на API-запросах отображает встроенный экран ошибки, который внешне выглядит как «технические работы».

---

## ✅ Быстрый фикс (без перезапуска)

Подключить бот-контейнер к сети nginx:

```bash
docker network connect remnawave-network remnawave_bot
```

Проверка — должен вернуть JSON, не ошибку:

```bash
curl https://lk.ваш-домен/api/cabinet/branding
```

---

## 🔧 Постоянный фикс (чтобы не повторялось)

Отредактировать `/opt/remnawave-bedolaga-telegram-bot/docker-compose.yml`:

### 1. Добавить сеть к сервису `bot`

```yaml
  bot:
    # ... остальные параметры ...
    networks:
      - bot_network
      - remnawave-network    # ← добавить
```

### 2. Объявить внешнюю сеть в секции `networks`

```yaml
networks:
  bot_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    driver_opts:
      com.docker.network.driver.mtu: 1350
  remnawave-network:          # ← добавить блок
    external: true
```

После правки `docker-compose.yml` при следующем `docker compose up -d` бот автоматически окажется в обеих сетях.

---

## 🔬 Диагностика

### Проверить сети контейнеров

```bash
docker inspect remnawave-nginx --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'
docker inspect remnawave_bot   --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'
```

Если в выводе разные сети — проблема именно в этом.

### Проверить ответ API напрямую с сервера

```bash
# Напрямую к боту — должен работать
curl http://localhost:8080/cabinet/branding

# Через nginx — 502 при проблеме
curl -sv https://lk.ваш-домен/api/cabinet/branding
```

### Проверить статус техработ в Redis

```bash
docker exec remnawave_bot_redis redis-cli GET maintenance_status
```

Если `is_active: false` — режим тех.работ выключен, проблема сетевая (не в логике бота).

### Проверить список сетей Docker

```bash
docker network ls
```

---

## 🤔 Почему происходит

При `docker compose up` Docker создаёт сеть с именем `<имя_директории>_<имя_сети>`. Если бот лежит в папке `remnawave-bedolaga-telegram-bot`, сеть называется `remnawave-bedolaga-telegram-bot_bot_network`.

nginx в `remnawave-network` (из основного `docker-compose.yml` Remnawave) не видит контейнеры в `bot_network`. DNS-резолюция имён контейнеров работает только внутри одной сети.

---

## 📋 Чеклист после обновления бота

```
[ ] docker ps — все контейнеры Up и healthy
[ ] curl http://localhost:8080/cabinet/branding — возвращает JSON
[ ] curl https://lk.ваш-домен/api/cabinet/branding — возвращает JSON (не 502)
[ ] docker inspect remnawave_bot --format '{{range ...}}' — содержит remnawave-network
[ ] Открыть кабинет в браузере — нет страницы тех.работ
```

---

## 🔥 Итог

| | |
|---|---|
| **Симптом** | Кабинет показывает «Технические работы» |
| **Реальная причина** | nginx и бот в разных Docker-сетях → 502 |
| **Быстрое решение** | `docker network connect remnawave-network remnawave_bot` |
| **Постоянное решение** | Добавить `remnawave-network: external: true` в `docker-compose.yml` бота |
