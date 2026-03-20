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
| 🐳 **Dockermon** | Новая интерактивная команда `dockermon` для управления Docker | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh)` |
| 🔐 **Audit History** | Логирование всех команд пользователей Linux | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/audit-history.sh)` |
| 📡 **Telegram MTProto Proxy** | Установка и настройка MTProxy для Telegram | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/tg_mtproxy.sh)` |
| 🌐 **SOCKS5 Proxy Manager (Dante)** | Менеджер пользователей SOCKS5 прокси | `bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/Proxy_socks5_dante.sh)` |
| 📡 **WARP** | WARP для Remnanode | `bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/warp-remnanode.sh)` |
| 📊 **Grafana + Prometheus (Central)** | Центральный сервер мониторинга | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)` |
| 🛰️ **Node Exporter Agent** | Агент мониторинга для удалённых нод | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)` |


---

## 🆕 Новая статья: Dockermon

📘 Краткая инструкция: [Dockermon — интерактивное управление Docker из терминала](./Dockermon%20—%20интерактивное%20управление%20Docker%20из%20терминала.md)

🚀 **Установка в одну команду:**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh)
```

▶️ **Запуск после установки:**

```bash
dockermon
```

## 🆕 Новая статья: Grafana + Prometheus

📘 Инструкция: [Grafana Prometheus Setup](./Grafana%20Prometheus%20Setup.md)

🚀 **Быстрый старт (центральный сервер):**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)
```

🛰️ **Быстрый старт (агенты/ноды):**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)
```

# 📂 Навигация (Mini Wiki)

> Репозиторий можно использовать как **мини-вики по администрированию Linux серверов**

| Раздел             | Описание                         |
| ------------------ | -------------------------------- |
| 📜 Audit History   | Логирование команд пользователей |
| 🐳 Dockermon       | Интерактивное управление Docker  |
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

## 🐳 Dockermon

Интерактивный CLI-скрипт для **удобного управления Docker из терминала**.

Функции:

* просмотр контейнеров и фильтрация
* работа с логами и диагностикой
* compose-проекты, images, volumes, networks
* очистка Docker и экспорт диагностики

🔗 Инструкция

[https://github.com/r00t-man/MZT/blob/main/my-wiki/Dockermon%20%E2%80%94%20%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%B2%D0%BD%D0%BE%D0%B5%20%D1%83%D0%BF%D1%80%D0%B0%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5%20Docker%20%D0%B8%D0%B7%20%D1%82%D0%B5%D1%80%D0%BC%D0%B8%D0%BD%D0%B0%D0%BB%D0%B0.md](https://github.com/r00t-man/MZT/blob/main/my-wiki/Dockermon%20%E2%80%94%20%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%B2%D0%BD%D0%BE%D0%B5%20%D1%83%D0%BF%D1%80%D0%B0%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5%20Docker%20%D0%B8%D0%B7%20%D1%82%D0%B5%D1%80%D0%BC%D0%B8%D0%BD%D0%B0%D0%BB%D0%B0.md)

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
