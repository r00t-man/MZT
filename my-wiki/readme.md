# 🧰 MZT — Server Scripts & Guides

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![Xray](https://img.shields.io/badge/Xray-Ready-orange?logo=github)](https://github.com/XTLS/Xray-core)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=flat-square&logo=linux)
![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04%20%7C%20Debian%2012-orange?style=flat-square)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

---

## 📚 О проекте

Этот репозиторий содержит **инструкции, скрипты и заметки по администрированию Linux серверов**.

Основные направления:

- 🖥 администрирование VPS  
- 🔐 безопасность серверов  
- 🐳 управление Docker  
- 📡 MTProxy для Telegram и SOCKS5  
- 🧹 Очистка серверов, особенно если на VPS диск 10 Гб
- 🌐 WARP для Remnanode (установка Cloudflare WARP)

---

# 🚀 One-Click Install

Некоторые скрипты можно установить **одной командой** прямо на сервере.

> Поддерживаемые системы: **Ubuntu 24.04 / Debian 12**

| Script | Description | Install |
|------|------|------|
| 🧹 **Ultra Clean VPS** | Глубокая очистка и оптимизация VPS | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/Ultra_Clean_VPS.sh)` |
| 🐳 **Docker Control CLI** | Интерактивное управление Docker контейнерами | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/control-docker-v5.2-cli.sh)` |
| 🔐 **Audit History** | Логирование всех команд пользователей Linux | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/audit-history.sh)` |
| 📡 **Telegram MTProto Proxy** | Установка и настройка MTProxy для Telegram | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/tg_mtproxy.sh)` |
| 🌐 **SOCKS5 Proxy Manager (Dante)** | Менеджер пользователей SOCKS5 прокси | `bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/Proxy_socks5_dante.sh)` |
| 📡 **WARP** | WARP для Remnanode | `bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/warp-remnanode.sh)` |

# 📂 Навигация (Mini Wiki)

> Репозиторий можно использовать как **мини-вики по администрированию Linux серверов**

| Раздел             | Описание                         |
| ------------------ | -------------------------------- |
| 📜 Audit History   | Логирование команд пользователей |
| 🐳 Docker Control  | Управление Docker через CLI      |
| 📡 MTProto Proxy   | Развёртывание прокси Telegram    |
| 🧹 Ultra Clean VPS | Очистка и оптимизация сервера    |
| 📡 WARP | WARP для Remnanode |

---

# 📊 Разделы

## 📜 Audit History

📖 **Логирование всех команд пользователей Linux**

Позволяет:

* вести аудит действий
* отслеживать изменения
* повышать безопасность сервера

🔗 Инструкция

[https://github.com/r00t-man/MZT/blob/main/my-wiki/Audit-history.md](https://github.com/r00t-man/MZT/blob/main/my-wiki/Audit-history.md)

---

## 🐳 Docker Control

CLI-скрипт для **быстрого управления Docker контейнерами**.

Функции:

* просмотр контейнеров
* перезапуск сервисов
* очистка Docker
* управление образами

🔗 Инструкция

[https://github.com/r00t-man/MZT/blob/main/my-wiki/Docker%20control.md](https://github.com/r00t-man/MZT/blob/main/my-wiki/Docker%20control.md)

---

## 📡 MTProto Proxy для Telegram

Инструкция по **развёртыванию MTProto Proxy**.

Включает:

* установку прокси
* генерацию секретов
* подключение к Telegram

🔗 Инструкция

[https://github.com/r00t-man/MZT/blob/main/my-wiki/MTProxy_TG.md](https://github.com/r00t-man/MZT/blob/main/my-wiki/MTProxy_TG.md)

---

## 🧹 Ultra Clean VPS

Скрипт для **глубокой очистки VPS на Ubuntu / Debian**.

Функции:

* очистка apt
* удаление старых пакетов
* освобождение места
* оптимизация системы

🔗 Инструкция

[https://github.com/r00t-man/MZT/blob/main/my-wiki/Ultra%20Clean%20VPS.md](https://github.com/r00t-man/MZT/blob/main/my-wiki/Ultra%20Clean%20VPS.md)

---

## 🌐 WARP for Remnanode

Скрипт для **настройки и подключения Cloudflare WARP для Remnanode** на **Ubuntu / Debian**.

Функции:

* установка Cloudflare WARP
* настройка SOCKS5 прокси
* подключение и управление WARP
* управление регистрацией и изменением порта

🔗 Инструкция

[https://github.com/r00t-man/MZT/blob/main/my-wiki/WARP-remna.md](https://github.com/r00t-man/MZT/blob/main/my-wiki/WARP-remna.md)

---

# ⚠️ Дисклеймер

> [!IMPORTANT]
> Проект предназначен **исключительно для образовательных целей**.

Материалы демонстрируют технические аспекты:

* администрирования серверов
* настройки сетевых сервисов
* повышения безопасности

Автор не несёт ответственности за последствия использования представленных инструкций.

Пользователь обязан самостоятельно соблюдать законодательство своей страны.

Если вы не согласны с этими условиями — **прекратите использование данного репозитория**.
