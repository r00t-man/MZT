# ℹ️ Info — разрозненные заметки по администрированию

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![License](https://img.shields.io/badge/License-MIT-purple)](../LICENSE)

Короткие тематические статьи и памятки, которые не привязаны к конкретному разделу репозитория:
подготовка сервера с нуля, перенос файлов, мониторинг, Docker, `screen`.

> [!NOTE]
> Статьи про Remnawave (балансировка, маршрутизация, VLESS→JSON) переехали в
> [🌊 Remnawave](../Remnawave/README.md) — там свой раздел про эксплуатацию панели и нод.

---

## 🧭 Меню — куда сразу перейти

| Если тебе нужно… | Статья | Коротко |
|---|---|---|
| 🐧 Подготовить чистый Ubuntu 24.04 под VPN-ноду с нуля | [Базовые команды Ubuntu 24 для подготовки VPN-ноды](./Базовые%20команды%20Ubuntu%2024%20для%20подготовки%20VPN-ноды.md) | Универсальный чеклист: sudo-пользователь, SSH-ключи, nftables, fail2ban, sysctl-hardening |
| 📊 Поднять лёгкий мониторинг серверов | [Мониторинг Beszel — быстрый старт](./Мониторинг%20Beszel%20—%20быстрый%20старт.md) | Конспект официального гайда на русском: Hub + Agent через Docker Compose |
| 🔄 Настроить беспарольную синхронизацию между двумя серверами | [Автоматическая передача файлов через rsync и SSH](./Автоматическая%20передача%20файлов%20между%20серверами%20через%20rsync%20и%20SSH.md) | SSH-ключи без пароля + `rsync` + автозапуск по `cron` |
| 🤖 Починить Telegram-бота в Docker, у которого нет доступа к `api.telegram.org` | [Docker-контейнер Telegram-бота через Xray proxy](./Docker-контейнер%20Telegram-бота%20через%20Xray%20proxy.md) | Локальный Xray HTTP-proxy на gateway Docker-сети, `trust_env`/`aiohttp-socks` для `aiogram` |
| 🖥️ Не терять процессы при обрыве SSH-сессии | [Работа со `screen` — мультиплексор терминала](./Работа%20со%20screen%20—%20мультиплексор%20терминала.md) | Базовые команды `screen` + готовое CLI-меню `scrmenu` |
| 🐳 Управлять Docker-контейнерами из интерактивного меню | [Dockermon](../my-wiki/Dockermon%20—%20интерактивное%20управление%20Docker%20из%20терминала.md) | Установка одной командой, меню вместо запоминания `docker` команд |
| 📈 Развернуть центральный Prometheus + Grafana | [Grafana Prometheus Setup](../my-wiki/Grafana%20Prometheus%20Setup.md) | Центральный сервер + агент `node_exporter` на нодах |
| 🔑 Показать сводку по серверу прямо при входе по SSH | [Start SSH MOTD](../my-wiki/Start_SSH_motd.md) | uptime, нагрузка, диск, сеть, systemd и Docker одним экраном |
| 🔐 Зашифровать DNS-запросы с самого сервера (DoT) | [Server Security, раздел 7 — DNS](../Server_Security/README.md#7-dns-сервера--шифрование-и-фильтрация) | DoT напрямую на публичные резолверы, без отдельного локального DNS-сервиса |

---

## 🚀 Быстрая установка `scrmenu` (CLI-меню для `screen`)

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/scrmenu.sh -o /usr/local/bin/scrmenu && chmod +x /usr/local/bin/scrmenu'
```

Запуск: `scrmenu`.

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Остальные разделы — в
[корневом README](../README.md).*
