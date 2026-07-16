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
[![Server Security](https://img.shields.io/badge/Server%20Security-hardening-red?style=for-the-badge&logo=letsencrypt)](#-server-security)
[![Remnawave](https://img.shields.io/badge/Remnawave-panel%20%2B%20nodes-teal?style=for-the-badge&logo=v2ray)](https://github.com/r00t-man/MZT/tree/main/Remnawave)
[![Wiki](https://img.shields.io/badge/Wiki-server%20knowledge-purple?style=for-the-badge&logo=github)](https://github.com/r00t-man/MZT/tree/main/wiki)

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

# 📚 Wiki — общие статьи

Разрозненные гайды и памятки, не привязанные к конкретному разделу репозитория (статьи по Remnawave —
балансировка/маршрутизация/VLESS→JSON/полный деплой стека/WARP — переехали в раздел
[🌊 Remnawave](#-remnawave--панель-ноды-и-профили)):

👉 [Wiki — все статьи](./wiki/README.md)

Там находятся гайды по:

- 🐳 Docker (Dockermon, Telegram-бот через Xray proxy)
- 🔐 аудиту команд и безопасности серверов
- 📡 MTProxy/SOCKS5-прокси для Telegram
- 🧹 обслуживанию и очистке VPS
- 📊 мониторингу (Grafana + Prometheus, Beszel)
- 🖥️ SSH MOTD, `screen`, подготовке чистого сервера, переносу файлов через rsync

🚀 Быстрая установка `scrmenu` (CLI-меню для `screen`):

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/scrmenu.sh -o /usr/local/bin/scrmenu && chmod +x /usr/local/bin/scrmenu'
```

---

# 🔐 Server Security

Один сводный гайд по защите VPN-сервера — переписан и проверен на реальном парке серверов 2026-07 (раньше это было 13 разрозненных заметок 2025 года, часть устарела/дублировалась):

👉 [Безопасность VPN-сервера — полное руководство](./Server_Security/README.md)

Включает: SSH + разбор реальной ловушки с cloud-init, fail2ban (sshd + ловушка от сканеров портов, с разбором реальной ошибки `port=ssh`), nftables, sysctl/BBR, sudo и CVE-2025-32463 (как проверять патч правильно), IPv6/ICMP, DNS-шифрование с сервера (DoT).

Только что купили сервер? Копипаст-версия без firewall (он отдельно) + пакеты для администрирования/диагностики:

👉 [Новый сервер — чек-лист первичной настройки](./Server_Security/New-server-install.md)

---

# 🌊 Remnawave — панель, ноды и профили

Отдельный раздел про эксплуатацию **Remnawave**: развёртывание всего стека с нуля (панель + бот +
кабинет + nginx), безопасное обновление панели/бота/кабинета (и разбор самой частой поломки —
«Технические работы» из-за разъехавшихся Docker-сетей), готовые JSON-профили инбаундов (блокировка
`.ru`-трафика, маскировка под сайт через nginx+XHTTP, выход через Cloudflare WARP), фильтрация трафика
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
├── wiki
│   ├── README.md   (меню — все общие статьи)
│   ├── Audit-history.md
│   ├── Dockermon — интерактивное управление Docker из терминала.md
│   ├── MTProxy_TG.md
│   ├── Proxy SOCKS5 manager.md
│   ├── Ultra Clean VPS.md
│   ├── Grafana Prometheus Setup.md
│   ├── Start_SSH_motd.md
│   ├── Telegram — широкие inline-кнопки U+2800.md
│   ├── Автоматическая передача файлов между серверами через rsync и SSH.md
│   ├── Базовые команды Ubuntu 24 для подготовки VPN-ноды.md
│   ├── Мониторинг Beszel — быстрый старт.md
│   ├── Docker-контейнер Telegram-бота через Xray proxy.md
│   └── Работа со screen — мультиплексор терминала.md
│
├── Server_Security
│   ├── README.md   (единый гайд — SSH/fail2ban/nftables/sysctl/sudo/IPv6/DNS)
│   └── New-server-install.md   (копипаст-чеклист нового сервера, без firewall)
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
│   ├── Шпаргалка VLESS в балансировочный JSON для remna.md
│   ├── VPN-help-remna-full.md
│   └── WARP-remna.md
│
└── LICENSE

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

