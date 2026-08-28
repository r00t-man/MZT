# 🔐 Безопасность VPN-сервера — полное руководство

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04-orange?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-purple)](../LICENSE)

> [!IMPORTANT]
> Материал создан в образовательных целях. Применяйте только на своих серверах и в рамках легальных задач.

Это единая статья взамен прежних 13 отдельных заметок этого раздела (писались с ChatGPT в 2025 году, часть советов устарела или была скопирована из общих гайдов без проверки на реальной нагрузке). Всё пересобрано и **проверено на живом парке** из ~20 продакшен VPN-нод (Xray-core: VLESS/REALITY/XHTTP/Hysteria2, часть под MTProxy). Раскатка на парк — через Ansible, но каждый шаг здесь дан и в ручном варианте.

> [!NOTE]
> **Целевая ОС — Ubuntu 24.04 LTS.** Это важно: в 24.04 OpenSSH перешёл на **socket-activation** (`ssh.socket`), и старые инструкции по смене SSH-порта из интернета (и из прошлой версии этой статьи) на ней **приводят к потере доступа**. См. раздел 1.4 — это самая частая и самая дорогая ошибка во всей теме.

> [!TIP]
> Только что купили сервер и не знаете, с чего начать? [Новый сервер — чек-лист первичной настройки](./New-server-install.md) —
> копипаст-версия этой статьи (без firewall, он отдельно) + пакеты для администрирования/диагностики.

## Содержание

- [0. Что должно стоять на Ubuntu 24.04 (пакеты и подготовка)](#0-что-должно-стоять-на-ubuntu-2404)
- [1. SSH](#1-ssh)
  - [1.1 Порт](#11-нестандартный-порт) · [1.2 Ключи](#12-ключи-вместо-пароля) · [1.3 Грабля cloud-init](#13-грабля-cloud-init--первая-директива-побеждает) · [1.4 Socket-activation (Ubuntu 24.04)](#14-socket-activation--самое-опасное-место-на-ubuntu-2404) · [1.5 Слабый VPS](#15-слабый-vps--kex_exchange_identification-connection-reset) · [1.6 Долгие команды по SSH](#16-долгие-команды-по-ssh)
- [2. Fail2ban](#2-fail2ban)
- [3. Firewall (nftables)](#3-firewall-nftables)
- [4. sysctl и BBR](#4-sysctl-и-bbr)
- [5. sudo — CVE-2025-32463](#5-sudo--cve-2025-32463)
- [6. IPv6 и ICMP](#6-ipv6-и-icmp)
- [7. DNS сервера — шифрование и фильтрация](#7-dns-сервера--шифрование-и-фильтрация)
- [8. После смены порта/IP — обновить внешний мониторинг](#8-после-смены-портаip--обновить-внешний-мониторинг)
- [9. Что убрано из старой версии и почему](#9-что-убрано-из-старой-версии-и-почему)

---

## 0. Что должно стоять на Ubuntu 24.04

Минимальный набор, без которого разделы ниже не заработают:

```bash
apt update && apt full-upgrade -y && apt autoremove -y
apt install -y \
  fail2ban nftables \
  curl wget ca-certificates gnupg jq unzip git \
  htop tmux lsof \
  dnsutils mtr-tiny whois ncdu \
  openssl rsync socat dos2unix
```

| Пакет | Зачем именно здесь |
|---|---|
| `fail2ban` | раздел 2 — джейлы `sshd`/`recidive`/`portscan` |
| `nftables` | раздел 3 — фильтрация, и `banaction = nftables` для fail2ban. Бинарь `/usr/sbin/nft` |
| `jq` | разбор JSON API панелей/ботов при диагностике |
| `tmux` | не терять сессию при обрыве SSH (либо `systemd-run`, см. 1.6) |
| `dnsutils`/`mtr-tiny`/`whois` | диагностика сети и DNS |
| `ncdu`/`lsof` | «кто съел диск», «кто держит порт» |
| `dos2unix` | чинит CRLF в скриптах, скопированных из браузера/Windows |

### Что уже есть в Ubuntu 24.04 и трогать не надо

- **systemd 255+** с генератором `sshd-socket-generator` — сам делает dual-stack сокет под ваш нестандартный порт (раздел 1.4).
- **`iptables-nft`** — слой совместимости, через который Docker пишет свои NAT-правила в nftables. Не удалять `iptables`, не переключать `update-alternatives` на legacy — сломаете проброс портов контейнеров.
- **`systemd-resolved`** — штатный DNS-stub на `127.0.0.53`. Через него же делается DoT (раздел 7).
- **`unattended-upgrades`** — рекомендуется включить на серверах без постоянного присмотра:
  ```bash
  apt install -y unattended-upgrades
  dpkg-reconfigure -plow unattended-upgrades
  ```

### Swap — если RAM ≤ 2 ГБ

Бюджетные VPS часто идут вообще без свопа → OOM-kill вместо подтормаживания под пиком (например при компиляции чего-либо из исходников — см. раздел 5).

```bash
free -h    # swap = 0 и RAM ≤ 2ГБ → добавить
fallocate -l 1G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## 1. SSH

### 1.1 Нестандартный порт

Практично держать по конвенции `22` + последний октет IP (`203.0.113.132` → порт `22132`). Не защита сама по себе, но убирает 95% автоматического шума ботов, сканирующих порт 22. Если получается длинновато — берут короче (`203.0.113.7` → `2297` вместо `22007`); единого железного правила «всегда 5 цифр» нет.

> [!NOTE]
> **Всегда меняйте порт только через drop-in `sshd_config.d/`, а не в самом `sshd_config`.** И на Ubuntu 24.04 после смены порта обязателен `daemon-reload && restart ssh.socket` — см. раздел 1.4, там же почему ручная правка `ssh.socket` = кирпич.

### 1.2 Ключи вместо пароля

Сгенерировать пару (ed25519, не RSA), положить публичный в `~/.ssh/authorized_keys` (`chmod 700 ~/.ssh`, `chmod 600 authorized_keys`). Наш стандартный drop-in — **`/etc/ssh/sshd_config.d/00-a-hardening.conf`**:

```ini
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
```

`PermitRootLogin prohibit-password` (синоним `without-password`) — root по-прежнему может зайти, но **только по ключу**. Именно это даёт `ssh root@node` без пароля и одновременно закрывает брутфорс.

> [!IMPORTANT]
> Перед выключением пароля — обязательно проверить вход по ключу в **новой** сессии, не закрывая старую. Частая причина «ключ не принимается» — права: `700` на `~/.ssh`, `600` на `authorized_keys`, иначе sshd молча игнорирует файл.

Второй независимый слой поверх ключей — `AllowUsers root@<ваш IP>` (или whitelist доверенных сетей) в том же drop-in.

### 1.3 Грабля cloud-init — «первая директива побеждает»

> [!WARNING]
> **Этого не упоминают 90% гайдов.** На Ubuntu/Debian с cloud-init `sshd_config` содержит `Include /etc/ssh/sshd_config.d/*.conf` РАНЬШЕ строки `PasswordAuthentication no`. У sshd действует правило «первая встреченная директива побеждает» (не последняя!) — а `50-cloud-init.conf` внутри `sshd_config.d/` часто содержит `PasswordAuthentication yes` и обрабатывается первым. Итог: ваш явный `no` в конце файла **не действует**.
>
> **Проверять не `grep`-ом файла, а эффективным конфигом:**
> ```bash
> sshd -T | grep -E 'passwordauthentication|permitrootlogin|^port '
> ```
> Если всё ещё `yes` — положите override, который сортируется РАНЬШЕ cloud-init по алфавиту: `/etc/ssh/sshd_config.d/00-a-hardening.conf`. Если у хостера уже есть свой `00-*.conf` (например `00-billpanel.conf` для сброса пароля через веб-консоль) — назовите свой файл ещё раньше (`00-a-...`).
>
> Финальная проверка — реальная проба логином с `-o PreferredAuthentications=password -o PubkeyAuthentication=no`: должно прийти `Permission denied (publickey)` **без** запроса пароля.

### 1.4 Socket-activation — самое опасное место на Ubuntu 24.04

В Ubuntu 24.04 OpenSSH поставляется **с socket-activation**. Слушающим сокетом управляет не `sshd`, а systemd-юнит `ssh.socket`:

```bash
systemctl list-units 'ssh*'
# ssh.service  loaded active running  OpenBSD Secure Shell server
# ssh.socket   loaded active running  OpenBSD Secure Shell server socket
```

Есть третий, невидимый участник — генератор `/usr/lib/systemd/system-generators/sshd-socket-generator`. При **каждом** `systemctl daemon-reload` он сам читает `Port` из `sshd_config` (включая ваши `.conf` из `sshd_config.d/`) и пишет `/run/systemd/generator/ssh.socket.d/addresses.conf` с правильным dual-stack:

```ini
[Socket]
ListenStream=
ListenStream=0.0.0.0:22132
ListenStream=[::]:22132
```

Обратите внимание — генератор явно прописывает **обе** строки, IPv4 и IPv6.

> [!CAUTION]
> **Реальный инцидент — одна ручная правка отрезала сервер насмерть, спасла только переустановка ОС.**
>
> При смене порта вместо правки `Port` в `sshd_config.d` был создан ручной drop-in **самого socket-юнита** — `/etc/systemd/system/ssh.socket.d/override.conf` с голыми `ListenStream=22` / `ListenStream=22153` (без явного адреса). После `daemon-reload && restart ssh.socket` — `ss -tlnp` показывал оба порта как слушающие (`[::]:22`, `[::]:22153`), но **снаружи** оба отвечали `Connection refused`.
>
> **Причина:** базовый `ssh.socket` несёт директиву `BindIPv6Only=ipv6-only`. Ручной override переопределяет ТОЛЬКО `ListenStream=` (то, что в нём явно написано) — `BindIPv6Only=ipv6-only` из базового файла остаётся в силе. Голый `ListenStream=<порт>` без `0.0.0.0:` под активным `BindIPv6Only=ipv6-only` создаёт **только IPv6-сокет**, без IPv4 вообще. `ss -tlnp` при этом показывает `[::]:PORT` как listening — форма вывода одинаковая для dual-stack и для IPv6-only, отличить нельзя. Форс-ребут не помогает (override — файл на диске). VNC у провайдера не было → переустановка ОС.

**Правильный способ смены SSH-порта на Ubuntu 24.04:**

```bash
# 1. И старый, и новый порт временно — чтобы не потерять доступ
cat > /etc/ssh/sshd_config.d/10-port.conf << 'EOF'
Port 22
Port 22132
EOF

# 2. Проверить синтаксис ДО применения
sshd -t

# 3. Перегенерировать сокет и перезапустить — НИКАКИХ ручных ssh.socket.d/*
systemctl daemon-reload
systemctl restart ssh.socket

# 4. Сверить, что слушают ОБА семейства адресов
ss -tlnp | grep -E 'sshd|:22132'
sshd -T | grep -i '^port'
```

**Проверить новый порт РЕАЛЬНЫМ подключением с другой машины** (не с самой ноды!) ПЕРЕД тем как убирать старый:

```bash
ssh -p 22132 root@203.0.113.132 "echo OK-NEW-PORT"
```

Только после этого — оставить в `10-port.conf` один `Port 22132`, повторить `daemon-reload && restart ssh.socket`.

> [!TIP]
> **Правило на все времена:** никогда не создавать и не редактировать `/etc/systemd/system/ssh.socket.d/*`. Штатный `sshd-socket-generator` уже решает dual-stack правильно — помогать ему не нужно.
>
> **Запасной вариант** (если генератор почему-то не сработал на конкретном образе) — отключить socket-activation целиком и растить sshd напрямую:
> ```bash
> systemctl disable --now ssh.socket
> systemctl enable --now ssh.service
> systemctl restart ssh.service
> ```
> `sshd` сам биндит порт через `getaddrinfo`/`AddressFamily any`, не зависит от socket-опций systemd. Рабочий фолбэк, но уводит от единообразия с остальным парком — не основной метод.

### 1.5 Слабый VPS — `kex_exchange_identification: Connection reset`

> [!WARNING]
> На бюджетных VPS (≤1 vCPU / ≤1 ГБ RAM) быстрые **последовательные** SSH-подключения рвутся с `kex_exchange_identification: read: Connection reset by peer` — сервер не успевает форкать `sshd` подряд. Проявляется при Ansible (каждая задача = новое соединение; даже один `ping`-модуль открывает 3-4 подряд) — падает `UNREACHABLE` на `Gathering Facts`, хотя ручной `ssh` секундой раньше работал.
>
> **Фикс — переиспользовать соединение** (`~/.ssh/config` на управляющей машине):
> ```ini
> Host node-*
>     ControlMaster auto
>     ControlPersist 120s
>     ControlPath /tmp/ssh-cp/%h-%p-%r
> ```
> `mkdir -p /tmp/ssh-cp` заранее. Для Ansible — либо это в `~/.ssh/config`, либо `-e 'ansible_ssh_common_args="-o ControlMaster=auto -o ControlPersist=120s -o ControlPath=/tmp/ssh-cp/%h-%p-%r"'`. На нодах с 2+ ГБ RAM проблемы нет.

### 1.6 Долгие команды по SSH

Для установок/сборок/скриптов, которые не должны прерваться при обрыве SSH — **не `nohup ... & disown`** (дважды за месяц не пережил закрытие сессии), а transient systemd-юнит:

```bash
ssh node "systemd-run --unit=install-job --collect -- /path/to/script.sh"
ssh node "journalctl -u install-job -f"      # прогресс
ssh node "systemctl status install-job"      # статус позже, другим подключением
```

`--collect` сам удалит юнит после завершения. Юнит живёт независимо от PAM-сессии.

---

## 2. Fail2ban

На обычной ноде — **три джейла**: `sshd` (из пакета), `recidive` (наш) и `portscan` (наш).

```bash
apt install -y fail2ban nftables
```

Джейл `sshd` включается сам: пакет ставит `/etc/fail2ban/jail.d/defaults-debian.conf` с `banaction = nftables`, `banaction_allports = nftables[type=allports]`, `backend = systemd`, `[sshd] enabled = true`. Бан идёт через отдельную nftables-таблицу `inet f2b-table` (не iptables).

### Иерархия конфигов — порядок значим (в отличие от SSH!)

```
/etc/fail2ban/jail.conf        ← пакетный дефолт, ❌ НИКОГДА не редактируем (перезатрётся апдейтом)
/etc/fail2ban/jail.d/*.conf    ← drop-in'ы, читаются по алфавиту
    defaults-debian.conf       ← ставит ПАКЕТ (banaction, backend, sshd on)
    portscan.conf              ← наш
/etc/fail2ban/jail.local       ← ОДИН наш override, применяется ПОСЛЕДНИМ (тут [recidive])
```

`jail.conf` → `jail.d/*.conf` (по алфавиту) → `jail.local`. Каждый следующий файл **переопределяет** предыдущий для той же секции. У SSH логика обратная («первая директива побеждает») — не путать.

### Джейл `sshd` — правим только порт

Дефолты пакета (`bantime 600 / findtime 600 / maxretry 5`) устраивают. Единственное, что надо задать явно — **реальный номер порта** в `action`:

`/etc/fail2ban/jail.local`:
```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 <ваш домашний/рабочий IP>

[sshd]
enabled = true
port    = 22132
action  = nftables[name=SSH, port=22132, protocol=tcp]
```

> [!CAUTION]
> **Самая опасная и незаметная ошибка — писать `port=ssh` вместо числа.**
> ```ini
> action = nftables[name=SSH, port=ssh, protocol=tcp]   # ❌ выглядит нормально, но НЕ РАБОТАЕТ
> ```
> `ssh` здесь — не «мой текущий SSH-порт», а буквальное имя сервиса, которое nftables резолвит через `/etc/services` → жёстко **22**, независимо от `sshd_config`. Если SSH на кастомном порту (раздел 1) — правило банит порт 22, который не слушается, а реальный порт остаётся открыт для забаненного IP. Бан выглядит рабочим (IP в `fail2ban-client status sshd`), фактической блокировки нет. Именно так «работали» правила на 9 из 14 нод реального парка.
>
> Порт можно вытащить программно, не вбивать руками:
> ```bash
> PORT=$(sshd -T | awk '/^port /{print $2; exit}')
> ```
>
> **Проверка, что бан реально применяется** (chain-правило создаётся ЛЕНИВО, только при первом бане — проверка конфига ничего не докажет):
> ```bash
> fail2ban-client set sshd banip 203.0.113.1
> nft list ruleset | grep -A3 'set addr-set-sshd'   # тут должен быть ВАШ порт
> fail2ban-client set sshd unbanip 203.0.113.1
> ```

### Джейл `recidive` — бан за рецидив

Если IP уже банился джейлом `sshd` несколько раз за сутки — это системный сканер, банить навсегда. В `/etc/fail2ban/jail.local`:

```ini
[recidive]
enabled  = true
filter   = recidive
logpath  = /var/log/fail2ban.log
findtime = 86400
maxretry = 3
bantime  = -1
action   = nftables[name=RECIDIVE, port=22132, protocol=tcp]
```

`port` — снова **реальный SSH-порт числом** (та же грабля, что выше). Recidive банит только по SSH-порту.

### Джейл `portscan` — ловушка для сканеров

Идея: банить сразу по всем портам любого, кто постучался в порт, которого на VPN-сервере в принципе не бывает (FTP/Telnet/СУБД/RDP и т.п.). Один хит → бан на всех портах на 24 часа.

`/etc/nftables-portscan.conf`:
```nft
#!/usr/sbin/nft -f
table inet portscan
delete table inet portscan

table inet portscan {
    chain input {
        type filter hook input priority filter - 5; policy accept;
        iifname "lo" return
        tcp dport { 21, 23, 25, 110, 143, 445, 1433, 1434, 3306, 3389,
                    5432, 5900, 5901, 6379, 7001, 8081, 8888, 9200,
                    11211, 27017 } ct state new limit rate 4/minute \
                    log prefix "PORTSCAN: " drop
    }
}
```

> [!WARNING]
> **Порт `8080` сознательно НЕ включён в список** (был раньше — убран). Коллизия с легитимными сервисами сразу в двух местах: панель управления/бот часто слушает `0.0.0.0:8080`, и базовый паттерн ноды вешает XHTTP-инбаунд на `8080` напрямую (без nginx). `iifname "lo" return` спасает только loopback-сервисы (пример: `mongod` на `127.0.0.1:27017`) — публично слушающий `8080` через него не исключить.
>
> **Перед применением на КАЖДОЙ ноде** — сверить реальные слушающие порты со списком trap-портов:
> ```bash
> ss -tlnp | grep -E ':(21|23|25|110|143|445|1433|1434|3306|3389|5432|5900|5901|6379|7001|8081|8888|9200|11211|27017)\b'
> ```
> Если что-то нашлось (кроме `127.0.0.1`-only) — либо перенести сервис, либо вычеркнуть порт из локальной копии файла.

`/etc/systemd/system/nft-portscan-trap.service` (грузит правило при старте — `nftables.service` намеренно выключен, см. раздел 3):
```ini
[Unit]
Description=Load portscan trap nftables rules
After=network.target fail2ban.service
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/nft -f /etc/nftables-portscan.conf
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

`/etc/fail2ban/filter.d/portscan.conf`:
```ini
[Definition]
failregex = ^.*PORTSCAN: .*SRC=<HOST> .*$
ignoreregex =
```

`/etc/fail2ban/jail.d/portscan.conf`:
```ini
[portscan]
enabled = true
filter = portscan
backend = systemd
journalmatch = _TRANSPORT=kernel
findtime = 3600
maxretry = 1
bantime = 86400
banaction = %(banaction_allports)s
```

> [!WARNING]
> `banaction = %(banaction_allports)s`, **не** `action = %(action_allports)s` — шаблона `action_allports` в Debian-сборке `jail.conf` не существует, падает с `ERROR interpolation key 'action_allports'`. `banaction_allports` определён пакетным `defaults-debian.conf` как `nftables[type=allports]`.
>
> `backend = systemd` + `journalmatch = _TRANSPORT=kernel` — **не опционально**. Минимальные образы Ubuntu 24.04 идут без `rsyslog` (только journald, `/var/log/kern.log` не существует). `nft` пишет `log prefix` через kernel-логирование в journald. При `backend = auto` + `logpath=/var/log/kern.log` на таких нодах fail2ban падает при старте (`Have not found any log file`). `backend = systemd` работает одинаково с rsyslog и без него.

### Применение и проверка

```bash
systemctl daemon-reload
systemctl enable --now nft-portscan-trap.service
systemctl restart fail2ban

fail2ban-client status          # sshd, recidive, portscan
nft list tables                 # inet f2b-table (сам fail2ban) + inet portscan (наша ловушка)
```

> [!NOTE]
> `fail2ban-client get <jail> ignoreip` всегда отвечает «No IP address/network is ignored», даже когда `ignoreip` из `[DEFAULT]` реально работает — это особенность репорта команды, не баг конфига. Не полагаться на неё как на диагностику.

---

## 3. Firewall (nftables)

### Главный факт: на ноде НЕТ единого «файла файрвола»

`nft list ruleset` показывает **несколько независимых таблиц от разных владельцев** в общем адресном пространстве ядра. Они не пересекаются. Редактировать руками можно только свои.

| Таблица | Владелец | Трогаем? |
|---|---|---|
| `table inet portscan` | наш `nft-portscan-trap.service` (раздел 2) | ✅ через свой файл |
| `table inet exporter_guard` | наш `nft-exporter-guard-trap.service` (ниже) | ✅ через свой файл |
| `table inet f2b-table` | сам `fail2ban` напрямую | ❌ через джейлы |
| `table ip nat` / `table ip filter` (+ IPv6) | `dockerd` через `iptables-nft` | ❌ никогда (в выводе: `managed by iptables-nft, do not touch!`) |
| `table ip remnanode` / `table ip6 remnanode6` | сам контейнер Xray/ноды (`cap_add: NET_ADMIN`) | ❌ никогда, пересоздаётся при рестарте контейнера |

### `nftables.service` — выключен намеренно

```bash
systemctl is-enabled nftables.service   # disabled
```

Это не забытая настройка. Штатный `nftables.service` грузит единый `/etc/nftables.conf` — но у нас правила приходят из разных источников, каждый грузит себя сам своим oneshot-юнитом при старте. Единого `/etc/nftables.conf` с нашими правилами нет и не должно быть.

> [!WARNING]
> **Не копируйте готовый `policy drop`-шаблон вслепую.** Любой пример из интернета (и из старой версии этой статьи) рассчитан на набор портов автора — обычно только SSH + панель. Современный VPN на Xray-core слушает намного больше:
> - VLESS/REALITY, XHTTP, WS — свои TCP-порты на каждый инбаунд
> - Hysteria2 — UDP
> - WireGuard (для каскадов) — UDP
> - MTProxy — свой TCP-порт
> - Панель / API — если открыта наружу
>
> **Сначала выпишите реальные слушающие порты** (`ss -tlnp` и `ss -ulnp`), и только затем стройте allow-list. Одна ошибка здесь роняет весь VPN, а не только SSH.

### Если всё же нужен полный `policy drop`

Свой уникальный файл + свой oneshot-юнит (как `nft-portscan-trap.service`), **не** `/etc/nftables.conf`, **не** дописывать в чужую таблицу:

```nft
#!/usr/sbin/nft -f
table inet fw
delete table inet fw

table inet fw {
    chain input {
        type filter hook input priority 0; policy drop;

        iif lo accept
        ct state established,related accept
        ct state invalid drop

        ip6 nexthdr icmpv6 accept
        ip protocol icmp accept          # НЕ блокировать ICMP — ломает мониторинг (раздел 6)

        tcp dport 22132 accept           # ваш реальный SSH-порт

        # РЕАЛЬНЫЕ порты ваших VPN-инбаундов — не пример из гайда
        tcp dport { 443, 8443 } accept
        udp dport { 443 } accept
    }
    chain forward { type filter hook forward priority 0; policy drop; }
    chain output  { type filter hook output priority 0; policy accept; }
}
```

> [!CAUTION]
> Docker-таблицы работают в семействе `ip`/`ip6` с хуками более высокого приоритета и не мешают этой `inet fw`, но **проверьте проброс портов контейнеров** после применения (`curl` на опубликованный порт извне). Если что-то отвалилось — не подгонять правила Docker, а пересмотреть свой allow-list.

### Allowlist на node_exporter (порт 9100)

Если стоит Prometheus `node_exporter` — по умолчанию он отдаёт **всю системную информацию** (CPU/RAM/диск/сеть/список ФС) кому угодно в интернете + выдаёт «тут мониторинг». Закрыть до одного IP скрейпера отдельной таблицей:

`/etc/nftables-exporter-guard.conf`:
```nft
#!/usr/sbin/nft -f
table inet exporter_guard
delete table inet exporter_guard

table inet exporter_guard {
    chain input {
        type filter hook input priority filter - 4; policy accept;
        iifname "lo" accept
        tcp dport 9100 ip saddr 203.0.113.10 accept   # ваш Prometheus
        tcp dport 9100 drop
    }
}
```

Плюс свой `nft-exporter-guard-trap.service` по образцу `nft-portscan-trap.service`. Проверка — `curl http://<нода>:9100/metrics` с чужого IP (таймаут) и со скрейпера (`200 OK`).

---

## 4. sysctl и BBR

> [!WARNING]
> **Не копируйте типовые «VPN sysctl» гайды не глядя** — многие рассчитаны на выделенные серверы с 16–32 ГБ RAM. На бюджетном VPS с 1–2 ГБ статичный `tcp_mem` на несколько гигабайт — прямой риск OOM (это больше физической памяти сервера целиком). Сначала `free -h`, затем профиль по объёму памяти.

```bash
modprobe tcp_bbr
echo tcp_bbr > /etc/modules-load.d/bbr.conf     # переживёт ребут
```

`/etc/sysctl.d/99-vpn-tuning.conf` — профиль **Small (~1 ГБ RAM, большинство нод)**:
```ini
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.ipv4.tcp_rmem = 4096 131072 8388608
net.ipv4.tcp_wmem = 4096 131072 8388608
net.ipv4.tcp_mem  = 131072 262144 393216

net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1

net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 4096
```

**Profile Medium (~2 ГБ)** — буферы `16777216`, `tcp_mem = 262144 524288 786432`.
Для нод с большим объёмом RAM (6 ГБ+) можно поднять до `33554432` / `786432 1048576 1572864`, но в реальном парке таких нод сейчас нет — профиль на бюджетных VPS не нужен.

Применить без ребута: `sysctl --system`, проверить `sysctl net.core.default_qdisc net.ipv4.tcp_congestion_control`.

| Параметр | Зачем |
|---|---|
| `bbr` + `fq` | Модель канала вместо реакции на потери — эффективнее `cubic` на дальних/мобильных маршрутах, где потери норма. `fq` обязателен как напарник (packet pacing, на нём построен сам BBR) |
| `tcp_fastopen = 3` | −1 RTT на установку соединения (VLESS/XHTTP handshake) |
| `tcp_keepalive_* = 120/30/5` | Дефолт Linux — 2 часа; для клиентов за мобильным CGNAT это часы «мёртвых» соединений |
| `somaxconn`/`backlog` = 4096 | Дефолт (128–1000) мал при десятках-сотнях одновременных клиентов |

### Если на сервере MTProxy / Telegram-прокси

> [!CAUTION]
> **BBR + большие буферы ломают MTProto-хендшейк** за DPI/ТСПУ (симптом: `uplinkHTTPMethod can be GET only in packet-up mode` или обрыв). Отдельный файл с гарантированно последней загрузкой по алфавиту — `/etc/sysctl.d/99-zz-mtproxy.conf`:
> ```ini
> net.core.default_qdisc = fq_codel
> net.ipv4.tcp_congestion_control = cubic
> ```
> ⚠️ Проверьте реальное имя файла-исключения (`ls /etc/sysctl.d/ | grep -i mtproxy`) — если он назван без `zz`-префикса, он грузится РАНЬШЕ общего профиля и не переопределяет его. Нода несколько минут работает на BBR — ровно та комбинация, что ломает хендшейк.

### Чего НЕ трогать

- `tcp_window_scaling` / `tcp_sack` / `tcp_timestamps` — уже `1` по умолчанию 15+ лет, бессмысленный «твик» (можно прописать явно для читаемости, эффекта нет).
- `icmp_echo_ignore_all` — **не отключать**, если есть любой мониторинг (Zabbix/Prometheus/Uptime Kuma). Блокировка ICMP тихо ломает алерты о доступности, а от атак не защищает (сканеры проверяют порты напрямую). Ищите, кто ставит параметр, по ВСЕМ файлам: `grep -r icmp_echo /etc/sysctl.conf /etc/sysctl.d/`.
- **IPv6** — не отключать массово (раздел 6).

---

## 5. sudo — CVE-2025-32463

В `sudo` (до 1.9.17p1) была критическая уязвимость — локальный root через опцию `chroot`, без записи в `sudoers`.

> [!IMPORTANT]
> **Не спешите компилировать из исходников.** Debian/Ubuntu бэкпортируют security-патчи в СВОЙ номер пакета, не меняя видимый «апстрим»-номер. `sudo --version` может показывать `1.9.15p5` даже когда CVE уже закрыт — это НЕ индикатор.
>
> **Правильная проверка:**
> ```bash
> apt-get changelog sudo | grep -B15 'CVE-2025-32463' | grep -E '^sudo \('
> apt-cache policy sudo
> ```
> Если версия в changelog **≤** установленной/candidate — патч уже есть, компилировать не нужно. На актуальной Ubuntu 24.04 (`noble-security`) он давно бэкпортирован — в норме делать ничего не надо.

Если changelog показывает, что патч ещё не дошёл — тогда компиляция оправдана:
```bash
apt install -y build-essential libpam0g-dev libssl-dev
cd /usr/src && wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz
tar -xvzf sudo-1.9.17p2.tar.gz && cd sudo-1.9.17p2
./configure && make && make install
```

> [!WARNING]
> **Компиляция создаёт технический долг.** `make install` кладёт бинарь в `/usr/local/bin/sudo`, который перекрывает apt-пакет по `PATH`, но `dpkg -l sudo` продолжает считать установленным старый пакет. Итог: **будущие CVE на sudo перестанут закрываться** через `apt upgrade`/unattended-upgrades. Когда апстрим-фикс дойдёт до дистрибутива — вернуться на управляемый пакет: `apt install --reinstall sudo` (при необходимости `--allow-downgrades sudo=<candidate>`), убрать `/usr/local/bin/sudo`.

---

## 6. IPv6 и ICMP

**Не отключайте IPv6 массово через GRUB «на всякий случай».** `ipv6.disable=1` + `reboot` — тяжёлая, необратимая без ребута мера, может сломать провижининг у части хостеров (используют IPv6 для служебных задач) и не нужна современным VPN-стекам (Xray/Reality поверх обычного TCP/UDP; IPv6-утечка у клиента решается на уровне клиентского роутинга, не хоста).

Если утечка IPv6 через сам туннель реально подтверждена — решать точечно на routing/firewall конкретного интерфейса, не `disable_ipv6=1` на весь хост.

**ICMP** — не блокировать `icmp_echo_ignore_all` (раздел 4). Реальной защиты не даёт (порт-сканеры не полагаются на ping), но ломает мониторинг доступности. Если ставите `policy drop` в nftables — явно разрешить `icmp` и `icmpv6` (пример в разделе 3).

---

## 7. DNS сервера — шифрование и фильтрация

### Зачем шифровать исходящий DNS с сервера

По умолчанию DNS-запросы сервера (обновления пакетов, проверка доменов, работа VPN-софта) уходят открытым текстом на DNS хостера — тот видит и может логировать, к каким доменам обращается сервер. DoT/DoH закрывает именно это — не клиентов туннеля (отдельная тема), а **сам сервер**.

### Вариант 1 — простой и безопасный: DoT напрямую на публичные резолверы

Не требует отдельного сервера. Drop-in `systemd-resolved`, без `rm -rf` системных файлов, без обязательного ребута.

`/etc/systemd/resolved.conf.d/10-dot.conf`:
```ini
[Resolve]
DNS=1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one
FallbackDNS=9.9.9.9#dns.quad9.net
DNSOverTLS=yes
DNSSEC=no
```
```bash
systemctl restart systemd-resolved
resolvectl status    # DNSOverTLS=yes, "encrypted transport: yes"
```

> [!NOTE]
> `systemd-resolved` кэширует и **отрицательные** ответы (NXDOMAIN), причём negative-cache переживает `resolvectl flush-caches` — если после смены DNS домен всё ещё «не резолвится», нужен полный `systemctl restart systemd-resolved`, а не flush.

Если DHCP/cloud-init продолжает переопределять DNS поверх этого — добавить в netplan `dhcp4-overrides: {use-dns: false}` для интерфейса и `network: {config: disabled}` в `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg` (без удаления существующих netplan-файлов).

### Вариант 2 — если нужна ещё и фильтрация (реклама/malware)

Это уже отдельный проект — свой резолвер (AdGuard Home) как самостоятельный сервис, потенциально на отдельном сервере. Порт 53 конфликтует с `systemd-resolved` — либо отключить резолвед, либо явно указать интерфейс. Сертификат — Let's Encrypt/certbot, списки блокировок добавлять по одному с контролем нагрузки. Это не «hardening VPN-ноды» — держать вне этой статьи. Официальная инструкция: https://adguard.com/ru/blog/adguard-home-on-public-server.html

### Чего избегать

Старые версии статьи советовали удалять весь `/etc/netplan` и состояние cloud-init (`rm -rf /var/lib/cloud/...`) ради «полностью локально управляемой» сети. Технически рабочий, но избыточно рискованный на проде — легко потерять сеть без консоли хостера, требует ребута. Вариант 1 даёт тот же результат без риска.

---

## 8. После смены порта/IP — обновить внешний мониторинг

> [!WARNING]
> Список таргетов вашего мониторинга (Prometheus `static_configs`, Zabbix-хосты, Uptime Kuma) — **статичный, ни с чем не синхронизируется автоматически.** Ни смена SSH-порта, ни смена IP ноды, ни миграция домена не обновляют его сами.
>
> Реальный случай: после флотовой рандомизации SSH-портов 6 нод весь день слали `probe_success=0` (ложный алерт «протокол недоступен») — Prometheus `blackbox_ssh` стучался в порт 22, который уже закрыт харденингом. Обнаружено только вечером при отдельном аудите.
>
> **В тот же чек-лист, что `~/.ssh/config`:** проверить и обновить target-листы мониторинга, затем перезагрузить конфиг (`promtool check config && curl -X POST http://localhost:9090/-/reload` для Prometheus — `systemctl reload` этот unit не поддерживает), подождать один scrape-интервал и подтвердить `up` реальным запросом, а не «конфиг применился».

---

## 9. Что убрано из старой версии и почему

- **Прямая правка `/etc/ssh/sshd_config` через `sed`** — заменено на drop-in `sshd_config.d/00-a-hardening.conf`. Свой файл легко найти/сравнить между нодами и он не конфликтует с тем, что туда пишет cloud-init.
- **`systemctl restart ssh` после смены порта** — на Ubuntu 24.04 недостаточно, нужен `daemon-reload && restart ssh.socket` (раздел 1.4). Старый совет на 24.04 оставлял ноду на прежнем порту либо (при ручной правке `ssh.socket`) отрезал насмерть.
- **Кейс VPS с масками `/32` и `/24` + «влияние на VPN-фингерпринт»** — был целиком про **OpenVPN** и специфичное для него сжатие **LZO**. Xray-core (VLESS/REALITY/XHTTP/Hysteria2) не использует ни OpenVPN, ни LZO — логика неприменима. Если у вас реально OpenVPN — сетевая проблема с `/32` актуальна, fingerprint-часть игнорируйте.
- **dnscrypt-proxy / DoH-обвязка под собственный DNS-сервер** — актуально только для варианта 2 раздела 7. Официальная документация AdGuard/dnscrypt-proxy покрывает это лучше.
- **«Troubleshooting»-заметки про ошибки Netplan/DoT** (`ifdown: unknown interface`, лишний `1.1.1.1` из старого DHCP lease) — актуальны только при тяжёлом пути (удаление netplan/cloud-init state), который больше не рекомендуется.
- **Массовое отключение IPv6 через GRUB** и **`icmp_echo_ignore_all`** — оба совета из старых статей вредны для нашего стека (ломают провижининг хостера и мониторинг соответственно), см. разделы 6 и 4.
