# ℹ️ Раздел Info

В этой папке собраны отдельные тематические статьи и справка по настройкам, не привязанные к
конкретному разделу репозитория.

> [!NOTE]
> Статьи про Remnawave (балансировка, маршрутизация, VLESS→JSON) переехали в
> [Remnawave](../Remnawave/README.md) — там свой раздел про эксплуатацию панели и нод.

## 📚 Материалы

- 📘 [Базовые команды Ubuntu 24 для подготовки VPN-ноды](./Базовые%20команды%20Ubuntu%2024%20для%20подготовки%20VPN-ноды.md)
- 📊 [Мониторинг Beszel — быстрый старт](./Мониторинг%20Beszel%20—%20быстрый%20старт.md)
- 🔄 [Автоматическая передача файлов между серверами через rsync и SSH](./Автоматическая%20передача%20файлов%20между%20серверами%20через%20rsync%20и%20SSH.md)
- 🤖 [Docker-контейнер с Telegram-ботом через Xray proxy](./Docker-контейнер%20Telegram-бота%20через%20Xray%20proxy.md)
- 🐳 [Dockermon — интерактивное управление Docker из терминала](../my-wiki/Dockermon%20—%20интерактивное%20управление%20Docker%20из%20терминала.md)
- 🖥️ [Работа со `screen` — мультиплексор терминала](./Работа%20со%20screen%20—%20мультиплексор%20терминала.md)

**Быстрая установка `scrmenu` (CLI-меню для `screen`):**

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/scrmenu.sh -o /usr/local/bin/scrmenu && chmod +x /usr/local/bin/scrmenu'
```

---

## 🔐 Новая статья в Server Security

- 📘 [Изменение DNS на серверах Яндекса (DoT)](../Server_Security/14_%D0%98%D0%B7%D0%BC%D0%B5%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5%20DNS%20%D0%BD%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0%D1%85%20%D0%AF%D0%BD%D0%B4%D0%B5%D0%BA%D1%81%D0%B0%20(DoT).md)

---

## 🆕 Новая статья по мониторингу

- 📘 [Grafana Prometheus Setup](../my-wiki/Grafana%20Prometheus%20Setup.md)

**Быстрый старт (центральный сервер):**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)
```

**Быстрый старт (агенты/ноды):**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)
```

---

## 🖥️ Полезный SSH-инструмент

- 📘 [Start SSH MOTD](../my-wiki/Start_SSH_motd.md)

**Установка в одну команду:**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/server-stat-modt.sh)
```

Показывает красивый MOTD при входе по SSH: uptime, загрузку, диск, сеть, systemd и Docker.

---
