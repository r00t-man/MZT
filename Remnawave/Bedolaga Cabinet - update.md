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

> [!IMPORTANT]
> Перед любыми обновлениями обязательно делаем бэкап — откатиться без него можно только пересборкой из исходников заново.

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

> [!TIP]
> Если не используется git — просто обновите файлы вручную.

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

### ❌ API не работает / кабинет показывает «Технические работы»

* nginx не проксирует `/api/cabinet`
* контейнер `remnawave_bot` недоступен

> [!WARNING]
> Отдельная и самая частая причина именно страницы **«Технические работы»** — бот после своего обновления
> поднялся в другой Docker-сети, чем nginx (не связано с этой инструкцией по фронтенду напрямую, но задевает
> тот же nginx и тот же API-путь). Разбор и фикс — в статье
> [Bedolaga Cabinet — после обновления показывает тех.работы](./Bedolaga%20Cabinet%20-%20после%20обновления%20показывает%20тех.работы.md).

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

