# 🐳 Control Docker CLI v5.2 

Интерактивный CLI-инструмент для удобного управления Docker прямо из терминала через отдельную команду `mondoc`.

Скрипт позволяет управлять контейнерами, логами, compose-проектами, volumes, networks и Docker-ресурсами через простое текстовое меню.

Работает на **Ubuntu / Debian / Linux с Docker**


## 📥 Скачать

👉 [Скачать dockermon.sh](https://raw.githubusercontent.com/r00t-man/MZT/3ab93f22126c46616201e07f37572848f9848f02/files/dockermon.sh)

Либо сразу на сервере

## 🚀 Быстрая установка

```bash
sudo mkdir -p /opt/control-docker/log
cd /opt/control-docker
sudo wget -O /opt/control-docker/dockermon.sh https://raw.githubusercontent.com/r00t-man/MZT/3ab93f22126c46616201e07f37572848f9848f02/files/dockermon.sh
sudo chmod +x /opt/control-docker/dockermon.sh
sudo ln -sf /opt/control-docker/dockermon.sh /usr/local/bin/mondoc
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
/opt/control-docker/dockermon.sh
```

---

## 4️⃣ Сделать скрипт исполняемым

```bash
sudo chmod +x /opt/control-docker/dockermon.sh
```

---

## 5️⃣ Создать команду `mondoc`

Чтобы запускать скрипт отдельной командой без конфликта с Docker:

```bash
sudo ln -sf /opt/control-docker/dockermon.sh /usr/local/bin/mondoc
```

---

## 6️⃣ Обновить кеш команд

```bash
hash -r
```

### Зачем нужен `hash -r`

Bash кэширует пути к командам.
После создания новой команды (`mondoc`) полезно очистить этот кеш, чтобы оболочка увидела изменения сразу.

---

# ▶️ Проверка установки

Проверь, что команда доступна в системе:

```bash
mondoc --help
```

Если всё установлено правильно, команда покажет краткую справку и не будет конфликтовать с реальным Docker CLI.

---

# ▶️ Запуск

После установки скрипт можно запускать так:

```bash
mondoc
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
 ├─ dockermon.sh
 └─ log/
      container-name/
           log-files
```

Глобальная команда будет доступна через путь:

```
/usr/local/bin/mondoc
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
