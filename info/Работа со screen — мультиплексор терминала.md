# 🖥️ Работа со `screen` — мультиплексор терминала

`screen` — это мультиплексор терминала: запускаешь сессию, отключаешься от SSH, а процессы внутри продолжают работать. Удобно для ботов, обновлений, миграций и любых долгих задач. 🚀

---

## ⚡ Быстрый старт

### 1) Запуск `screen`

```bash
screen
```

Или сразу с именем сессии:

```bash
screen -S mysession
```

---

### 2) Отключиться от сессии, не останавливая процессы

Нажми:

```text
Ctrl + A, затем D
```

Это «отсоединяет» тебя от сессии, но процессы продолжают работать в фоне. ✅

---

### 3) Посмотреть все сессии

```bash
screen -ls
```

Пример вывода:

```text
There are screens on:
    12345.mysession   (Detached)
    67890.test        (Attached)
```

---

### 4) Вернуться в сессию

По имени:

```bash
screen -r mysession
```

По ID:

```bash
screen -r 12345
```

Если сессия считается уже подключённой (`Attached`), используй принудительное переподключение:

```bash
screen -dr mysession
```

---

## 🧠 Типовой сценарий (бот, парсер, долгий процесс)

```bash
screen -S bot
cd /opt/mybot
python3 main.py
```

Дальше отсоединяешься:

```text
Ctrl + A, D
```

Выходишь из SSH — процесс остаётся работать.

Когда нужно вернуться:

```bash
screen -r bot
```

---

## 🪟 Полезные сочетания клавиш внутри `screen`

### Создать новое окно

```text
Ctrl + A, C
```

### Переключение между окнами

Следующее окно:

```text
Ctrl + A, N
```

Предыдущее окно:

```text
Ctrl + A, P
```

Список окон:

```text
Ctrl + A, "
```

### Закрыть текущее окно

```bash
exit
```

Если это было последнее окно — вся screen-сессия завершится.

---

## 🧹 Как завершить сессию полностью

Вариант 1: зайти в сессию и завершить процесс(ы)

```bash
screen -r mysession
exit
```

Вариант 2: завершить сессию снаружи

```bash
screen -S mysession -X quit
```

---

## 📌 Минимальный набор команд (шпаргалка)

```text
screen -S NAME        # создать сессию
screen -ls            # список сессий
screen -r NAME        # подключиться к сессии
screen -dr NAME       # переподключиться принудительно
Ctrl+A D              # отсоединиться от сессии
exit                  # закрыть окно/сессию
```

---

## 🛠️ Если `screen` не установлен

### Ubuntu / Debian

```bash
apt update && apt install -y screen
```

### RHEL / CentOS / AlmaLinux / Rocky

```bash
dnf install -y screen
```

### Fedora

```bash
dnf install -y screen
```

### Arch Linux

```bash
pacman -Sy --noconfirm screen
```

Проверить установку:

```bash
screen --version
```

---

## ⚠️ Частая ошибка

Если нажал `Ctrl + A` и «ничего не произошло» — это нормально.
`Ctrl + A` в `screen` — служебная клавиша-префикс. После неё нужно нажать вторую клавишу (например, `D`, `C`, `N`).

---

## 🧩 Практичные примеры команд

### Запуск `docker compose` в фоне через `screen`

```bash
screen -S compose
cd /opt/myapp
docker compose up -d
Ctrl + A, D
```

### Обновление бота с GitHub без риска обрыва SSH

```bash
screen -S bot-update
cd /opt/mybot
git pull
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
systemctl restart mybot
Ctrl + A, D
```

### Смотреть логи в отдельном окне `screen`

```text
Ctrl + A, C
```

```bash
journalctl -u mybot -f
```

---

## ✅ Рекомендации

- Давай сессиям понятные имена: `bot`, `deploy`, `logs`, `backup`.
- На один сервис — одна отдельная screen-сессия.
- Для автозапуска после ребута лучше использовать `systemd`, а `screen` — для ручного сопровождения и отладки.
