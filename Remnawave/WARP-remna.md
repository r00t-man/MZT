# ☁️ WARP для Remnanode

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04%20%7C%20Debian%2012-orange?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-purple)](../LICENSE)

Скрипт `warp-remnanode.sh` управляет подключением **Cloudflare WARP** через **SOCKS5**-прокси для
**Remnanode**: установка, подключение/отключение, генерация X25519-ключей и `shortId`, готовые
outbound/routing для Remnawave. Подразумевается, что Remnanode уже установлен и работает.

> [!TIP]
> Если интегрируешь WARP с конкретным nginx+XHTTP-профилем — сначала пройди этот гайд (установка,
> статус WARP, генерация ключей), а за интеграцией возвращайся в
> [nginx+xhttp+tls+warp](./nginx+xhttp+tls+warp.md).

---

## 🔧 Установка

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/warp-remnanode.sh)
```

## ⚙️ Основные функции скрипта

- 🚀 **Установка и подключение WARP** — автоматически устанавливает Cloudflare WARP и настраивает
  SOCKS5-прокси для подключений
- 🔄 **Изменение порта** — SOCKS5 по умолчанию на `40000`, можно сменить на любой (1–65535)
- 🔑 **Генерация X25519-ключей и `shortId`** — для использования с Remnanode
- 📊 **Отображение информации** — текущий статус WARP, IP-адреса, готовые outbound/routing для Remnanode

## 📝 Меню скрипта

```text
1)  Установить / подключить WARP
2)  Показать статус WARP
3)  Перезапустить WARP
4)  Отключить WARP
5)  Перерегистрировать WARP
6)  Сгенерировать X25519 ключи
7)  Сгенерировать shortId
8)  Показать конфигурацию outbound для Remnawave
9)  Показать правила маршрутизации для Remnawave
10) Показать полный пример профиля конфигурации
11) Перезапустить Remnanode
12) Выход
```

## 🔒 Предварительные требования

Скрипт требует **root**-прав. Нужны пакеты `curl` (загрузка скриптов), `gpg` (проверка подписей),
`jq` (обработка JSON), `ss` из `iproute2` (мониторинг портов).

> [!NOTE]
> Если каких-то из этих пакетов не хватает — скрипт автоматически их установит.

## 🔄 Обновление

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/warp-remnanode.sh)
```

---

> [!WARNING]
> Скрипт работает только на **Ubuntu и Debian** 🐧, протестирован на **Ubuntu 24.04** и **Debian 12**.
> Применяйте только для законных и образовательных целей.

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Остальные статьи — в
[Remnawave/README.md](./README.md).*
