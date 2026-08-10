# 🧰 Wiki — общие статьи и скрипты

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04%20%7C%20Debian%2012-orange?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-purple)](../LICENSE)

Разрозненные гайды и памятки по администрированию Linux-серверов — не привязанные к конкретному
разделу репозитория: подготовка сервера, Docker, Telegram-прокси, мониторинг, аудит, очистка VPS.

> [!NOTE]
> Статьи про Remnawave (полный деплой стека, обновление, балансировка/маршрутизация, WARP, JSON-профили)
> — в отдельном разделе [🌊 Remnawave](../Remnawave/README.md).

---

## 🧭 Меню — куда сразу перейти

| Если тебе нужно… | Статья | Коротко |
|---|---|---|
| 🐧 Подготовить чистый Ubuntu 24.04 под VPN-ноду с нуля | [Базовые команды Ubuntu 24 для подготовки VPN-ноды](./Базовые%20команды%20Ubuntu%2024%20для%20подготовки%20VPN-ноды.md) | Универсальный чеклист: sudo-пользователь, SSH-ключи, nftables, fail2ban, sysctl-hardening |
| 🤖 Настроить парк серверов через Ansible с нуля (полный туториал для новичка) | [Ansible — эталонная настройка парка серверов](./Ansible%20—%20эталонная%20настройка%20парка%20серверов%20с%20нуля.md) | Установка, SSH-ключи, inventory/роли/плейбуки, dry-run, частые грабли `--check`-режима |
| 🐳 Управлять Docker-контейнерами из интерактивного меню | [Dockermon](./Dockermon%20—%20интерактивное%20управление%20Docker%20из%20терминала.md) | Установка одной командой, меню вместо запоминания `docker`-команд |
| 🤖 Починить Telegram-бота в Docker без доступа к `api.telegram.org` | [Docker-контейнер Telegram-бота через Xray proxy](./Docker-контейнер%20Telegram-бота%20через%20Xray%20proxy.md) | Локальный Xray HTTP-proxy на gateway Docker-сети, `trust_env`/`aiohttp-socks` для `aiogram` |
| 📡 Поднять MTProxy для Telegram (+ каскад RU→EU) | [MTProxy для Telegram](./MTProxy_TG.md) | Установка в один клик, генерация secret, каскадная схема через второй сервер |
| 🌐 Поднять SOCKS5-прокси для Telegram | [SOCKS5 (Dante) Manager](./Proxy%20SOCKS5%20manager.md) | Управление пользователями/паролями, готовые `t.me/socks`-ссылки |
| 🔎 Логировать все команды пользователей на сервере | [Audit History](./Audit-history.md) | auditd + bash-hook + IP SSH-подключений, ротация, опциональный удалённый syslog |
| 🧹 Освободить место на диске (VPS с маленьким диском) | [Ultra Clean VPS](./Ultra%20Clean%20VPS.md) | APT/journald/nginx/Docker-логи, старые ядра, snap, firmware — 1–8 GB места |
| 📊 Поднять центральный мониторинг Prometheus + Grafana | [Grafana Prometheus Setup](./Grafana%20Prometheus%20Setup.md) | Центральный сервер + `node_exporter` на нодах |
| 📊 Поднять лёгкий мониторинг серверов (альтернатива) | [Мониторинг Beszel — быстрый старт](./Мониторинг%20Beszel%20—%20быстрый%20старт.md) | Hub + Agent через Docker Compose, конспект официального гайда |
| 🖥️ Показать сводку по серверу прямо при входе по SSH | [Start SSH MOTD](./Start_SSH_motd.md) | uptime, нагрузка, диск, сеть, systemd и Docker одним экраном |
| 🖥️ Не терять процессы при обрыве SSH-сессии | [Работа со `screen`](./Работа%20со%20screen%20—%20мультиплексор%20терминала.md) | Базовые команды `screen` + готовое CLI-меню `scrmenu` |
| 🔄 Настроить беспарольную синхронизацию между двумя серверами | [Автоматическая передача файлов через rsync и SSH](./Автоматическая%20передача%20файлов%20между%20серверами%20через%20rsync%20и%20SSH.md) | SSH-ключи без пароля + `rsync` + автозапуск по `cron` |
| ⌨️ Растянуть inline-кнопку в Telegram-боте на всю ширину | [Telegram — широкие inline-кнопки U+2800](./Telegram%20—%20широкие%20inline-кнопки%20U+2800.md) | Символ `⠀` (Braille Pattern Blank) вместо схлопывающегося пробела |

---

## 🚀 Быстрая установка `scrmenu` (CLI-меню для `screen`)

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/scrmenu.sh -o /usr/local/bin/scrmenu && chmod +x /usr/local/bin/scrmenu'
```

Запуск: `scrmenu`.

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Остальные разделы — в
[корневом README](../README.md).*
