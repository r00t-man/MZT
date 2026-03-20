# 🧰 MZT — Linux Server Scripts & Guides

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![Scripts Count](https://img.shields.io/badge/Scripts-7-success?style=flat-square&logo=gnubash&logoColor=white)](https://github.com/r00t-man/MZT/tree/main/files)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=flat-square&logo=linux)
![Tested](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04%20%7C%20Debian%2012-orange?style=flat-square)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

---

# 📚 О репозитории
## 🌐 Также есть [сайт второго репозитория linux-help](https://r00t-man.github.io/linux-help/) 

## 🧭 Быстрая Навигация

[![Scripts](https://img.shields.io/badge/Scripts-install-blue?style=for-the-badge&logo=gnubash)](#-one-click-install)
[![Guides](https://img.shields.io/badge/Guides-linux%20server-green?style=for-the-badge&logo=linux)](#-основные-гайды)
[![Server Security](https://img.shields.io/badge/Server%20Security-hardening-red?style=for-the-badge&logo=letsencrypt)](#-server-security)
[![VPN Docs](https://img.shields.io/badge/VPN-documentation-orange?style=for-the-badge&logo=wireguard)](#-vpn-инструкции)
[![Wiki](https://img.shields.io/badge/Wiki-server%20knowledge-purple?style=for-the-badge&logo=github)](https://github.com/r00t-man/MZT/tree/main/my-wiki)
[![Info](https://img.shields.io/badge/Info-routing%20notes-yellow?style=for-the-badge&logo=readthedocs)](https://github.com/r00t-man/MZT/tree/main/info)

**MZT** — это коллекция:

- 🧰 скриптов для администрирования Linux  
- 📡 сетевых инструментов и прокси  
- 🔐 инструкций по безопасности серверов  
- 🐳 утилит для управления Docker  
- 🧹 инструментов для обслуживания VPS  

Репозиторий используется как **мини-вики по администрированию серверов и сетевых сервисов**.

---

# 🚀 Установка в один клик

Некоторые скрипты можно установить **одной командой**.

| Script | Description | Install |
|------|------|------|
| 🧹 **Ultra Clean VPS** | Очистка и оптимизация сервера | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/Ultra_Clean_VPS.sh)` |
| 🐳 **Dockermon** | Интерактивный Docker-менеджер с отдельной командой `dockermon` | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh)` |
| 🔐 **Audit History** | Логирование команд Linux | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/audit-history.sh)` |
| 📡 **MTProto Proxy** | Установка MTProxy для Telegram | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/tg_mtproxy.sh)` |
| 🌐 **SOCKS5 Proxy (Dante)** | Менеджер пользователей SOCKS5 | `bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/Proxy_socks5_dante.sh)` |
| ☁️ **Cloudflare WARP (remnanode)** | Установка и настройка WARP для remnanode | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/warp-remnanode.sh)` |
| 📊 **Grafana + Prometheus (Central)** | Центральный сервер мониторинга | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)` |
| 🛰️ **Node Exporter Agent** | Агент мониторинга для удалённых нод | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)` |

---

# 📚 Основные гайды

📖 Основные инструкции и статьи находятся здесь:

👉 https://github.com/r00t-man/MZT/tree/main/my-wiki

Там находятся гайды по:

- 🐳 Docker  
- 🔐 безопасности серверов  
- 📡 прокси и сетевым сервисам  
- ☁️ Cloudflare WARP для remnanode
- 🧹 обслуживанию VPS  
- 📊 мониторингу серверов через Grafana + Prometheus

### 🆕 Новая статья: Dockermon

- 📘 Гайд: [Dockermon — интерактивное управление Docker из терминала](./my-wiki/Dockermon%20—%20интерактивное%20управление%20Docker%20из%20терминала.md)
- 🚀 Установка в одну команду:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh)
```

- ▶️ Запуск после установки:

```bash
dockermon
```

---

### 🆕 Новая статья: Grafana + Prometheus

- 📘 Гайд: [Grafana Prometheus Setup](./my-wiki/Grafana%20Prometheus%20Setup.md)
- 🚀 Быстрый старт (центральный сервер):

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)
```

- 🛰️ Быстрый старт (агенты/ноды):

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)
```

---

# ℹ️ Раздел Info

В корне репозитория добавлен раздел **info** с отдельными тематическими статьями:

- 🛣️ Правила маршрутизации Remna
- ⚖️ Конфиг балансировки в Remnawave (leastLoad / leastPing / roundRobin)
- 📌 Шпаргалка: VLESS → JSON (дополнение к Remna)
- 📘 Базовые команды Ubuntu 24 для подготовки VPN-ноды
- 🔄 Автоматическая передача файлов между серверами через rsync и SSH
- 📊 Мониторинг Beszel — быстрый старт
- 🤖 Docker-контейнер с Telegram-ботом через Xray proxy
- 🐳 Dockermon — интерактивное управление Docker из терминала

👉 https://github.com/r00t-man/MZT/tree/main/info

---

# 🔐 Server Security

Отдельный раздел с универсальными материалами по защите серверов:

👉 https://github.com/r00t-man/MZT/tree/main/Server_Security

Включает:

- базовый hardening сервера
- безопасную настройку `sudo`
- hardening через `sysctl.conf`
- SSH-ключи
- безопасную DNS-конфигурацию (DoT + DNSSEC)
- сетевой кейс VPS с масками `/32` и `/24`

---

# 📡 VPN инструкции 3X-UI

Полная серия инструкций по развёртыванию и настройке VPN находится в папке **VPN_3x-ui**:

👉 https://github.com/r00t-man/MZT/tree/main/VPN_3x-ui

Включает:

- установка собственного VPN  
- каскадные конфигурации  
- настройка DNS (DoH / DoT)  
- оптимизация сети  

---

# 📂 Структура репозитория

```

MZT
│
├── files
│   ├── Ultra_Clean_VPS.sh
│   ├── dockermon.sh
│   ├── audit-history.sh
│   ├── tg_mtproxy.sh
│   ├── Proxy_socks5_dante.sh
│   ├── install_grafana_prometheus.sh
│   └── install_node_exporter_agent.sh
│
├── help
│   └── Programms.md
│
├── my-wiki
│   ├── Audit-history.md
│   ├── Dockermon — интерактивное управление Docker из терминала.md
│   ├── MTProxy_TG.md
│   ├── WARP-remna.md
│   ├── Ultra Clean VPS.md
│   └── Grafana Prometheus Setup.md
│
├── info
│   ├── README.md
│   ├── Автоматическая передача файлов между серверами через rsync и SSH.md
│   ├── Балансировка remna.md
│   ├── Шпаргалка VLESS в балансировочный JSON для remna.md
│   ├── Базовые команды Ubuntu 24 для подготовки VPN-ноды.md
│   ├── Мониторинг Beszel — быстрый старт.md
│   ├── Dockermon — интерактивное управление Docker из терминала.md
│   └── Правила маршрутизации Remna.md
│
├── Server_Security
│   ├── README.md
│   ├── 02_Настройка безопасности сервера.md
│   ├── 03_Безопасная настройка sudo.md
│   ├── 06_Настройка безопасности sysctl.conf.md
│   ├── 07_Настройка SSH-ключей.md
│   ├── 12_Безопасная DNS-конфигурация сервера (DoT + DNSSEC).md
│   └── 13_Сетевой кейс VPS маски 24 и 32.md
│
└── VPN_3x-ui
    ├── 00_Введение в технологию.md
    ├── 01_Установка своего VPN.md
    ├── 04_Настройка каскадного VPN.md
    ├── 05_Настройка правил для доменов.md
    ├── 08_Установка собственного DNS.md
    ├── 09_Настройка DNS (DoT) на VPN.md
    ├── 10_Настройка DNS (DoH) на VPN.md
    ├── 11_DNS (DoT) - Возможна ошибка.md
    └── 14_Размывка трафика VPN.md

```

---

# 🧭 Использование репозитория

Репозиторий можно использовать как:

- 📚 **базу знаний по администрированию Linux**
- 🧰 **набор полезных серверных скриптов**
- 📡 **практические инструкции по настройке VPN**
- 🔐 **гайд по безопасности серверов**

---

# ⚠️ Дисклеймер

> [!IMPORTANT]
> Все материалы опубликованы **исключительно в образовательных целях**.

Информация предназначена для:

- администрирования серверов  
- тестирования сетевых технологий  
- повышения безопасности инфраструктуры  

Автор не несёт ответственности за использование материалов в противоправных целях.  
Пользователь обязан соблюдать законодательство своей страны.
