# 🎂 Bedolaga Cabinet — Обновление статического фронтенда

Полная инструкция по обновлению **cabinet (frontend)** через Docker с безопасным бэкапом и возможностью отката.

---

## 🚀 Общая схема

```text
Исходники (/opt/bedolaga-cabinet)
        ↓
docker compose build
        ↓
Временный контейнер
        ↓
Копирование статики
        ↓
/srv/cabinet (nginx раздаёт)
```

---

## 📁 Структура

| Путь                    | Описание          |
| ----------------------- | ----------------- |
| `/opt/bedolaga-cabinet` | исходники cabinet |
| `/srv/cabinet`          | готовая статика   |
| `/srv/backup_opt`       | бэкапы            |
| `remnawave-nginx`       | nginx контейнер   |

---

## 🛡️ 1. Создание бэкапа

Перед любыми обновлениями обязательно делаем бэкап:

```bash
DATE=$(date +%F-%H%M%S)

mkdir -p /srv/backup_opt
cp -a /srv/cabinet /srv/backup_opt/cabinet_backup_$DATE

echo "Бэкап создан: /srv/backup_opt/cabinet_backup_$DATE"
```

---

## 📥 2. Обновление исходников

```bash
cd /opt/bedolaga-cabinet
git pull
```

> 💡 Если не используется git — просто обновите файлы вручную.

---

## 🏗️ 3. Сборка frontend

```bash
cd /opt/bedolaga-cabinet
docker compose build
```

---

## 📦 4. Извлечение статики

```bash
# ищем образ
IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i cabinet | head -n1)

# создаём временный контейнер
CID=$(docker create $IMAGE)

# очищаем старую статику
rm -rf /srv/cabinet/*

# копируем новую
docker cp "$CID":/usr/share/nginx/html/. /srv/cabinet/

# удаляем контейнер
docker rm "$CID"
```

---

## 🔁 5. Перезапуск nginx

```bash
docker restart remnawave-nginx
```

---

## ✅ Проверка

```bash
ls -lah /srv/cabinet
```

Открой в браузере:

```
https://your-domain
```

---

## 🔙 Откат (Rollback)

Если что-то пошло не так:

```bash
rm -rf /srv/cabinet/*
cp -a /srv/backup_opt/cabinet_backup_ДАТА/* /srv/cabinet/

docker restart remnawave-nginx
```

---

## ⚠️ Возможные проблемы

### ❌ Белый экран

* не скопировалась статика
* неправильный образ

### ❌ API не работает

* nginx не проксирует `/api/cabinet`
* контейнер `remnawave_bot` недоступен

---

## 🧠 Полезные команды

Проверка контейнеров:

```bash
docker ps
```

Проверка образов:

```bash
docker images | grep cabinet
```

Проверка сети:

```bash
docker inspect remnawave_bot
```

---

## 💡 Как это работает

* frontend собирается внутри Docker
* результат — обычная статика (HTML/CSS/JS)
* nginx раздаёт её как сайт
* backend (бот) отдаёт API отдельно

👉 Это даёт:

* ⚡ быстрый сайт
* 🔒 безопасность (нет лишних сервисов)
* 🧩 простое обновление

---

## 🔥 Рекомендации

* всегда делай бэкап перед обновлением
* проверяй образ перед копированием
* не редактируй `/srv/cabinet` вручную
* держи nginx и bot в одной сети Docker

---

## 🎉 Готово!

