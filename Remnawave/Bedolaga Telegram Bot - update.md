# 🤖 Remnawave Bedolaga Telegram Bot — Обновление и бэкап

Полная инструкция по безопасному обновлению Telegram-бота с сохранением данных и возможностью отката.

---

## 🚀 Общая схема

```text id="m1l9sx"
git pull
   ↓
docker build
   ↓
backup (files + db)
   ↓
alembic migrate
   ↓
docker up
```

---

## 📁 Структура проекта

| Путь                                   | Описание       |
| -------------------------------------- | -------------- |
| `/opt/remnawave-bedolaga-telegram-bot` | исходники бота |
| `/srv/backup_opt`                      | бэкапы         |
| `.env`                                 | конфигурация   |
| `data/`, `logs/`, `uploads/`           | данные         |

---

## 🐳 Контейнеры

| Контейнер             | Назначение   |
| --------------------- | ------------ |
| `remnawave_bot`       | основной бот |
| `remnawave_bot_db`    | PostgreSQL   |
| `remnawave_bot_redis` | Redis        |

---

## 🛡️ 1. Бэкап (ОБЯЗАТЕЛЬНО)

### 📦 Бэкап файлов

```bash id="s9w1fx"
DATE=$(date +%F-%H%M%S)

mkdir -p /srv/backup_opt

cp -a /opt/remnawave-bedolaga-telegram-bot \
/srv/backup_opt/bot_backup_$DATE
```

---

### 🗄️ Дамп базы данных

```bash id="q5d0yz"
docker exec remnawave_bot_db \
pg_dump -U remnawave_user remnawave_bot \
> /srv/backup_opt/bot_db_$DATE.sql
```

---

## 📥 2. Обновление кода

```bash id="1q9t6o"
cd /opt/remnawave-bedolaga-telegram-bot
git pull
```

---

## 🏗️ 3. Сборка контейнеров

```bash id="c4t8ay"
docker compose build
```

---

## ⛔ 4. Остановка

```bash id="c5o2k1"
docker compose down
```

---

## 🧠 5. Миграции базы данных

> ⚠️ Критически важный шаг

```bash id="z6m8eu"
docker compose run --rm bot alembic upgrade head
```

---

## ▶️ 6. Запуск

```bash id="o3v7kn"
docker compose up -d
```

---

## ✅ Проверка

### Контейнеры

```bash id="2h6xpc"
docker ps
```

---

### Логи

```bash id="2exqcf"
docker logs -f remnawave_bot
```

---

### Healthcheck

```bash id="7yyvfn"
curl http://localhost:8080/health
```

---

## 🔙 Откат (Rollback)

### 📂 Восстановление файлов

```bash id="b4ozs2"
rm -rf /opt/remnawave-bedolaga-telegram-bot

cp -a /srv/backup_opt/bot_backup_ДАТА \
/opt/remnawave-bedolaga-telegram-bot
```

---

### 🗄️ Восстановление БД

```bash id="j9l7ps"
docker exec -i remnawave_bot_db \
psql -U remnawave_user remnawave_bot \
< /srv/backup_opt/bot_db_ДАТА.sql
```

---

### ▶️ Перезапуск

```bash id="q4tgso"
cd /opt/remnawave-bedolaga-telegram-bot
docker compose up -d
```

---

## ⚠️ Возможные проблемы

### ❌ Бот не стартует

Проверь:

```bash id="1l7a5g"
docker logs remnawave_bot
```

---

### ❌ Ошибки ENV (Pydantic)

Причина:

* новые переменные в `.env.example`
* неправильные типы (например `int` вместо строки)

👉 Решение:

* сравнить `.env` и `.env.example`

---

### ❌ Не работает API

Проверь:

* порт `8080`
* nginx прокси
* сеть Docker

---

## 🧠 Как это работает

* код обновляется через `git`
* Docker собирает новый образ
* Alembic обновляет структуру БД
* бот запускается с новой логикой

---

## 🔥 Рекомендации

* всегда делай бэкап перед обновлением
* не редактируй `.env` без понимания
* проверяй CHANGELOG перед апдейтом
* держи бэкапы минимум 2–3 версии

---

## 🎉 Готово!
