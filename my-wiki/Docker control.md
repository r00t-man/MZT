# 🐳 Control Docker CLI v5.2

Интерактивный CLI-инструмент для удобного управления Docker прямо из терминала.

Скрипт позволяет управлять контейнерами, логами, compose-проектами, volumes, networks и Docker-ресурсами через простое текстовое меню.

Работает на **Ubuntu / Debian / Linux с Docker**


## 📥 Скачать

👉 [Скачать control-docker-v5.2-cli.sh](https://raw.githubusercontent.com/r00t-man/MZT/3ab93f22126c46616201e07f37572848f9848f02/files/control-docker-v5.2-cli.sh)

Либо сразу на сервере

## 🚀 Быстрая установка

```bash
sudo mkdir -p /opt/control-docker/log
cd /opt/control-docker
sudo wget -O /opt/control-docker/control-docker-v5.2-cli.sh https://raw.githubusercontent.com/r00t-man/MZT/3ab93f22126c46616201e07f37572848f9848f02/files/control-docker-v5.2-cli.sh
sudo chmod +x /opt/control-docker/control-docker-v5.2-cli.sh
sudo ln -sf /opt/control-docker/control-docker-v5.2-cli.sh /usr/local/bin/control-docker
hash -r
```

---

# ✨ Возможности

## 🧱 Контейнеры

* просмотр списка контейнеров
* фильтрация (running / exited / restarting)
* поиск по имени или образу
* restart / start / stop
* удаление контейнера
* `docker exec` внутрь контейнера
* просмотр процессов (`docker top`)
* просмотр ресурсов (`docker stats`)
* проверка health-status
* `docker inspect` (краткий и полный)

---

## 📜 Работа с логами

* просмотр последних **N строк**
* **live logs** (`docker logs -f`)
* сохранение логов в файл
* массовое сохранение логов нескольких контейнеров

Все сохранённые логи хранятся в:

```
/opt/control-docker/log
```

Структура:

```
/opt/control-docker/log/
   container-name/
       2026-03-06_14-25-10_200-lines.log
```

---

## 📦 Docker Compose

Поддержка compose-проектов:

* просмотр сервисов
* просмотр логов
* live logs
* restart проекта

Работает с:

```
docker compose
```

или

```
docker-compose
```

---

## 🧹 Очистка Docker

Встроенное меню очистки:

* `docker container prune`
* `docker image prune`
* `docker volume prune`
* `docker network prune`
* `docker system prune`

---

## 🗂 Docker ресурсы

Отдельные разделы для:

* 🖼 Docker Images
* 💾 Docker Volumes
* 🌐 Docker Networks

Можно быстро просмотреть и удалить неиспользуемые ресурсы.

---

## 📦 Экспорт диагностики контейнера

Скрипт умеет автоматически собирать диагностику:

```
inspect
logs
stats
top
summary
```

и сохранять её архивом:

```
container_diagnostics.tar.gz
```

Это удобно для:

* передачи другому администратору
* диагностики проблем
* хранения логов

---

# 🚀 Установка (с нуля)

## 1️⃣ Установить Docker

Если Docker ещё не установлен:

```bash
curl -fsSL https://get.docker.com | bash
```

Проверка:

```bash
docker --version
```

---

## 2️⃣ Создать папку скрипта

```bash
sudo mkdir -p /opt/control-docker/log
```

---

## 3️⃣ Поместить скрипт

Скопируй файл скрипта в:

```
/opt/control-docker/control-docker-v5.2-cli.sh
```

---

## 4️⃣ Сделать скрипт исполняемым

```bash
sudo chmod +x /opt/control-docker/control-docker-v5.2-cli.sh
```

---

## 5️⃣ Создать глобальную команду

Чтобы запускать скрипт одной командой:

```bash
sudo ln -sf /opt/control-docker/control-docker-v5.2-cli.sh /usr/local/bin/control-docker
```

---

## 6️⃣ Обновить кеш команд

```bash
hash -r
```

### Зачем нужен `hash -r`

Bash кэширует пути к командам.
После создания новой команды (`control-docker`) нужно очистить этот кеш, чтобы оболочка увидела новую команду.

---

# ▶️ Запуск

После установки скрипт можно запускать так:

```bash
control-docker
```

Откроется интерактивное CLI-меню.

---

# 🧭 Главное меню

```
1) Выбрать контейнер
2) Сменить фильтр
3) Поиск контейнера
4) Массовые действия
5) Docker Compose projects
6) Docker images
7) Docker volumes
8) Docker networks
9) Очистить старые лог-файлы
10) Docker prune меню
```

Каждый раздел имеет **подробное описание в шапке меню**, чтобы понимать:

* что делает команда
* когда её использовать

---

# ⌨ Управление

### Навигация

```
0  — назад
Enter — подтвердить
Ctrl+C — выход
```

---

### В потоковых режимах

```
docker logs -f
docker events
compose logs -f
```

нажатие

```
Ctrl+C
```

останавливает только поток логов и **возвращает в меню**, не закрывая скрипт.

---

# 📂 Где хранятся данные

```
/opt/control-docker
```

### структура

```
/opt/control-docker
 ├─ control-docker-v5.2-cli.sh
 └─ log/
      container-name/
           log-files
```

---

# 🛠 Требования

* Linux
* Docker
* Bash

Поддерживаемые системы:

* Ubuntu
* Debian
* Proxmox
* VPS / Dedicated servers

---

# 💡 Примеры использования

### Быстро посмотреть логи контейнера

```
Выбрать контейнер
→ Logs
→ указать количество строк
```

---

### Отладить контейнер

```
Выбрать контейнер
→ Exec
```

---

### Проверить нагрузку

```
Выбрать контейнер
→ Stats
```

---

### Посмотреть события контейнера

```
Выбрать контейнер
→ Docker events
```

---

### Очистить мусор Docker

```
Prune menu
→ docker system prune
```

---

# ⚠️ Внимание

Команды удаления могут удалить:

* контейнеры
* volumes
* images
* networks

Используйте их осторожно.

---

# 📜 Лицензия

Free to use.

---

Если хочешь — я могу ещё сделать:

* **README с красивыми GitHub badges**
* **gif-демо интерфейса**
* **скриншоты меню**
* **автоустановку одной командой (`curl | bash`)** для этого скрипта.
