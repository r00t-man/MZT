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
[![Remnawave](https://img.shields.io/badge/Remnawave-panel%20%2B%20nodes-teal?style=for-the-badge&logo=v2ray)](https://github.com/r00t-man/MZT/tree/main/Remnawave)
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
| 🖥️ **Start SSH MOTD** | Красивый MOTD с метриками сервера и Docker | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/server-stat-modt.sh)` |
| 🌐 **Yandex DNS DoT** | Настройка DNS-over-TLS через Яндекс DNS на сервере | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/ya-dns-dot.sh)` |

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
- 🖥️ кастомному SSH MOTD с быстрым обзором состояния сервера

---


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

### 🆕 Новая статья: Start SSH MOTD

- 📘 Гайд: [Start SSH MOTD](./my-wiki/Start_SSH_motd.md)
- 🚀 Установка в одну команду:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/server-stat-modt.sh)
```

- 🖼️ После установки при входе по SSH показывается сводка по uptime, нагрузке, памяти, диску, сети и Docker.

---

# ℹ️ Раздел Info

В корне репозитория добавлен раздел **info** с отдельными тематическими статьями, не привязанными к
конкретному разделу репозитория (статьи по Remnawave — балансировка/маршрутизация/VLESS→JSON — переехали
в раздел [🌊 Remnawave](#-remnawave--панель-ноды-и-профили)):

- 📘 Базовые команды Ubuntu 24 для подготовки VPN-ноды
- 🔄 Автоматическая передача файлов между серверами через rsync и SSH
- 📊 Мониторинг Beszel — быстрый старт
- 🤖 Docker-контейнер с Telegram-ботом через Xray proxy
- 🖥️ Работа со `screen` — мультиплексор терминала

📘 Прямой файл: [MZT/info/Работа со `screen` — мультиплексор терминала.md](./info/Работа%20со%20screen%20—%20мультиплексор%20терминала.md)

🚀 Быстрая установка `scrmenu` (CLI-меню для `screen`):

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/scrmenu.sh -o /usr/local/bin/scrmenu && chmod +x /usr/local/bin/scrmenu'
```

👉 https://github.com/r00t-man/MZT/tree/main/info

---

# 🔐 Server Security

Один сводный гайд по защите VPN-сервера — переписан и проверен на реальном парке серверов 2026-07 (раньше это было 13 разрозненных заметок 2025 года, часть устарела/дублировалась):

👉 [Безопасность VPN-сервера — полное руководство](./Server_Security/README.md)

Включает: SSH + разбор реальной ловушки с cloud-init, fail2ban (sshd + ловушка от сканеров портов, с разбором реальной ошибки `port=ssh`), nftables, sysctl/BBR, sudo и CVE-2025-32463 (как проверять патч правильно), IPv6/ICMP, DNS-шифрование с сервера (DoT).

Только что купили сервер? Копипаст-версия без firewall (он отдельно) + пакеты для администрирования/диагностики:

👉 [Новый сервер — чек-лист первичной настройки](./Server_Security/Новый%20сервер%20—%20чек-лист%20первичной%20настройки.md)

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

# 🌊 Remnawave — панель, ноды и профили

Отдельный раздел про эксплуатацию **Remnawave**: безопасное обновление панели/бота/кабинета (и разбор
самой частой поломки — «Технические работы» из-за разъехавшихся Docker-сетей), готовые JSON-профили
инбаундов (блокировка `.ru`-трафика, маскировка под сайт через nginx+XHTTP+WARP), фильтрация трафика
на ноде (TaffGuard/mobile443 — обход мобильных глушилок), и балансировка/маршрутизация трафика между
нодами (стратегии `leastLoad`/`leastPing`/`roundRobin`, правила `routing.rules`, шпаргалка VLESS → JSON):

👉 [Remnawave — гайды по эксплуатации панели, нод и профилей](./Remnawave/README.md)

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
│   ├── install_node_exporter_agent.sh
│   └── server-stat-modt.sh
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
│   ├── Grafana Prometheus Setup.md
│   └── Start_SSH_motd.md
│
├── info
│   ├── README.md
│   ├── Автоматическая передача файлов между серверами через rsync и SSH.md
│   ├── Базовые команды Ubuntu 24 для подготовки VPN-ноды.md
│   ├── Мониторинг Beszel — быстрый старт.md
│   ├── Docker-контейнер Telegram-бота через Xray proxy.md
│   └── Работа со screen — мультиплексор терминала.md
│
├── Server_Security
│   ├── README.md   (единый гайд — SSH/fail2ban/nftables/sysctl/sudo/IPv6/DNS)
│   └── Новый сервер — чек-лист первичной настройки.md   (копипаст, без firewall)
│
├── Remnawave
│   ├── README.md   (меню — что внутри и куда сразу перейти)
│   ├── Remnawave — обновление панели и нод.md
│   ├── Bedolaga Telegram Bot - update.md
│   ├── Bedolaga Cabinet - update.md
│   ├── Bedolaga Cabinet - после обновления показывает тех.работы.md
│   ├── block-ru-v2-json.md
│   ├── nginx+xhttp+tls+warp.md
│   ├── Install TaffGuard nftables.md
│   ├── Балансировка remna.md
│   ├── Правила маршрутизации Remna.md
│   ├── Примечание к балансировке remna — резерв для Яндекс-ноды.md
│   └── Шпаргалка VLESS в балансировочный JSON для remna.md
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

---

