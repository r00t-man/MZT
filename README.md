# 🧰 MZT — Linux Server Scripts & Guides

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=flat-square&logo=linux)
![Tested](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04%20%7C%20Debian%2012-orange?style=flat-square)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

---

# 📚 О репозитории

**MZT** — это коллекция:

- 🧰 скриптов для администрирования Linux  
- 📡 сетевых инструментов и прокси  
- 🔐 инструкций по безопасности серверов  
- 🐳 утилит для работы с Docker  
- 🧹 скриптов обслуживания VPS  

Репозиторий используется как **мини-вики по администрированию серверов**.

---

# 🚀 One-Click Install

Некоторые скрипты можно установить **одной командой**.

| Script | Description | Install |
|------|------|------|
| 🧹 Ultra Clean VPS | Очистка и оптимизация сервера | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/Ultra_Clean_VPS.sh)` |
| 🐳 Docker Control | Управление Docker контейнерами | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/control-docker-v5.2-cli.sh)` |
| 🔐 Audit History | Логирование команд Linux | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/audit-history.sh)` |
| 📡 MTProto Proxy | Установка MTProxy для Telegram | `bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/tg_mtproxy.sh)` |
| 🌐 SOCKS5 Proxy | SOCKS5 прокси менеджер (Dante) | `bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/Proxy_socks5_dante.sh)` |

---

# 📂 Структура репозитория

```

MZT
│
├── files
│   ├── Ultra_Clean_VPS.sh
│   ├── control-docker-v5.2-cli.sh
│   ├── audit-history.sh
│   ├── tg_mtproxy.sh
│   └── Proxy_socks5_dante.sh
│
├── help
│   └── Programms.md
│
├── my-wiki
│   ├── Audit-history.md
│   ├── Docker control.md
│   ├── MTProxy_TG.md
│   └── Ultra Clean VPS.md
│
└── VPN guides
├── 00_Введение в технологию.md
├── 01_Установка своего VPN.md
├── 02_Настройка безопасности.md
├── 03_Обновление sudo.md
├── 04_Настройка каскадного VPN.md
├── 05_Настройка правил для доменов.md
├── 06_Настройка sysctl.conf.md
├── 07_Настройка SSH ключей.md
├── 08_Установка собственного DNS.md
├── 09_Настройка DNS (DoT).md
├── 10_Настройка DNS (DoH).md
├── 11_Ошибка DNS (DoT).md
├── 12_Настройка DNS на сервере.md
├── 13_Маски 24 и 32.md
└── 14_Размывка трафика VPN.md

```

---

# 📚 Основные инструкции

### 🔐 Безопасность сервера

- SSH ключи
- sysctl hardening
- обновление sudo

### 📡 VPN

- установка собственного VPN
- каскадные конфигурации
- настройка DNS
- маскировка трафика

### 🐳 Docker

- управление контейнерами
- обслуживание Docker

### 🧹 Обслуживание VPS

- очистка системы
- оптимизация диска
- аудит команд

---

# 🧭 Быстрый переход к инструкциям

📖 Основные гайды находятся здесь:

https://github.com/r00t-man/MZT/tree/main/my-wiki

---

# ⚠️ Дисклеймер

> [!IMPORTANT]
> Все материалы публикуются **исключительно в образовательных целях**.

Информация предназначена для:

- администрирования серверов  
- тестирования сетевых технологий  
- повышения безопасности  

Автор не несёт ответственности за использование материалов в противоправных целях.

Пользователь обязан соблюдать законодательство своей страны.
