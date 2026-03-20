# 🐳 Dockermon — интерактивное управление Docker из терминала

`dockermon` — это интерактивный CLI-скрипт для администрирования Docker прямо из консоли. Он устанавливает команду `dockermon`, убирает старые ссылки `control-docker`, создаёт основной файл в `/opt/control-docker/dockermon.sh` и открывает текстовое меню для работы с контейнерами, логами, compose-проектами, image, volume и network.

Подходит для случаев, когда нужно быстро посмотреть логи, перезапустить контейнер, зайти внутрь через `exec`, выгрузить диагностику или почистить Docker без ручного набора длинных команд.

---

## ⚙️ Что делает установочный скрипт

После запуска `files/dockermon.sh`:

- создаёт каталог `/opt/control-docker`
- записывает основной CLI-файл в `/opt/control-docker/dockermon.sh`
- создаёт глобальную команду `/usr/local/bin/dockermon`
- удаляет старые бинарные ссылки `control-docker`
- удаляет старые docker plugin-пути `docker-control`, если они остались от прошлой версии
- обновляет кеш команд через `hash -r`

---

## 🚀 Установка в одну команду

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh)
```

После установки запуск:

```bash
dockermon
```

Проверка справки:

```bash
dockermon --help
```

---

## 🛠️ Ручная установка

### 1) Убедись, что Docker установлен

Проверка:

```bash
docker --version
```

Если Docker ещё не установлен:

```bash
curl -fsSL https://get.docker.com | bash
```

---

### 2) Создай рабочую папку

```bash
sudo mkdir -p /opt/control-docker
```

---

### 3) Скачай установочный скрипт

```bash
sudo wget -O /tmp/dockermon-installer.sh https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh
```

или так:

```bash
curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh -o /tmp/dockermon-installer.sh
```

---

### 4) Сделай файл исполняемым

```bash
sudo chmod +x /tmp/dockermon-installer.sh
```

---

### 5) Запусти установку

```bash
sudo bash /tmp/dockermon-installer.sh
```

Скрипт сам создаст:

- `/opt/control-docker/dockermon.sh`
- `/usr/local/bin/dockermon`

---

## 📂 Что будет в системе после установки

```text
/opt/control-docker/
├── dockermon.sh
└── log/

/usr/local/bin/dockermon
```

Логи и экспорт диагностики сохраняются в:

```text
/opt/control-docker/log
```

---

## 🧭 Краткое руководство

### Запуск

```bash
dockermon
```

После запуска откроется главное меню:

```text
1) Выбрать контейнер
2) Сменить фильтр
3) Поиск контейнера/образа
4) Массовые действия
5) Docker Compose projects
6) Docker images
7) Docker volumes
8) Docker networks
9) Очистить старые лог-файлы
10) Prune меню
0) Выход
```

---

## 🔍 Что можно делать через меню

### Контейнеры

- смотреть список контейнеров
- фильтровать по статусу: `all`, `running`, `exited`, `restarting`
- искать контейнер по имени или образу
- запускать, останавливать и перезапускать контейнер
- удалять контейнер

### Диагностика

- смотреть последние строки логов
- открывать `live logs`
- сохранять логи в файл
- смотреть `docker inspect` в кратком и полном виде
- смотреть `docker stats`
- смотреть процессы через `docker top`
- проверять `health status`
- следить за `docker events`
- экспортировать диагностику контейнера в `tar.gz`

### Работа внутри контейнера

- входить в контейнер через `bash`, `ash` или `sh`

### Docker Compose

- смотреть `compose ps`
- выводить `compose logs`
- запускать потоковые `compose logs -f`
- перезапускать весь compose-проект

### Ресурсы Docker

- смотреть и удалять `images`
- смотреть и удалять `volumes`
- смотреть и удалять `networks`
- запускать `prune`-операции через отдельное меню

---

## 📝 Практические примеры

### Быстро посмотреть логи контейнера

```text
Выбрать контейнер
→ Посмотреть последние N строк логов
```

### Зайти внутрь контейнера

```text
Выбрать контейнер
→ Exec внутрь контейнера
```

### Проверить, что нагружает сервис

```text
Выбрать контейнер
→ Stats
```

### Собрать архив для диагностики

```text
Выбрать контейнер
→ Экспорт диагностики в tar.gz
```

### Почистить Docker-мусор

```text
Prune меню
→ выбрать нужный тип очистки
```

---

## ⚠️ Важно

- Для работы требуется установленный `docker`.
- Команды удаления (`rm`, `rmi`, `prune`) нужно использовать осторожно.
- Для установки обычно нужен `root` или `sudo`.
- Если раньше использовались старые команды `control-docker`, установщик удалит их автоматически.

---

## ✅ Короткий итог

`dockermon` — это удобная текстовая оболочка над Docker для повседневного администрирования. Если нужен быстрый доступ к контейнерам, логам, compose-проектам и очистке Docker без запоминания десятков команд, этот вариант подойдёт как для VPS, так и для обычного Linux-сервера.
