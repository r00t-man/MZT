# 🛡️ Fail2ban и сетевая настройка VPN-сервера (BBR, sysctl)

Практическая инструкция по защите VPN-сервера (Ubuntu 24.04) от брутфорса SSH и сканирования портов через **fail2ban + nftables**, и по разумной сетевой настройке ядра (**BBR** и sysctl-твики) для лучшей работы VPN-трафика на нестабильных/дальних каналах.

Рассчитано на одиночный сервер или небольшой парк нод, без внешнего мониторинга — только штатные средства Linux.

---

## 📑 Содержание

- [Защита SSH через fail2ban](#защита-ssh-через-fail2ban)
- [Защита от сканирования портов (бан по всем портам)](#защита-от-сканирования-портов-бан-сразу-по-всем-портам)
- [Сетевые sysctl-твики: BBR и буферы](#сетевые-sysctl-твики-bbr-и-буферы)
- [Если на сервере крутится Telegram-прокси (MTProxy)](#если-на-сервере-крутится-telegram-прокси-mtproxy)
- [Чеклист проверки](#чеклист-проверки)

---

## Защита SSH через fail2ban

Ставим fail2ban с бэкендом **nftables** — на Ubuntu 24.04 это корректный современный выбор (iptables больше не дефолт):

```bash
apt update && apt install -y fail2ban nftables
systemctl enable --now nftables
```

Создаём `/etc/fail2ban/jail.local`. **Обязательно впиши сюда свой реальный IP** (домашний/рабочий/VPN, с которого заходишь по SSH) — иначе рано или поздно забанишь сам себя, причём навсегда (см. `bantime` ниже):

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 ТВОЙ_IP_1 ТВОЙ_IP_2

[sshd]
enabled  = true
filter   = sshd
action   = nftables[name=SSH, port=ssh, protocol=tcp]
logpath  = %(syslog_authpriv)s
backend  = systemd
findtime = 600
maxretry = 2
bantime  = -1
```

Пояснения:

| Параметр | Значение | Смысл |
|---|---|---|
| `findtime` / `maxretry` | 600с / 2 | 2 неудачные попытки за 10 минут = бан. Жёстко, но оправдано, если вход только по ключу — легитимных неудачных попыток быть не должно. |
| `bantime` | `-1` | Бан навсегда. Разбанить вручную: `fail2ban-client set sshd unbanip <IP>`. Если такая жёсткость не нужна — поставь число секунд, например `3600`. |
| `backend` | `systemd` | Универсально работает и с классическим rsyslog (`/var/log/auth.log`), и на серверах без него (чистый `journald`) — см. грабли ниже. |
| `action` | `nftables[name=SSH, port=ssh, ...]` | Банит только SSH-порт, не весь трафик с IP (в отличие от джейла ниже). |

Если SSH висит на нестандартном порту — поменяй `port = ssh` здесь и в `/etc/ssh/sshd_config` на реальный номер.

Применить:
```bash
systemctl restart fail2ban
fail2ban-client status sshd
```

**Грабля:** на некоторых минимальных установках Ubuntu вообще нет rsyslog (только `journald`, файла `/var/log/auth.log` не существует) — fail2ban с `backend = auto` в этом случае падает с `Have not found any log file`. `backend = systemd` (как в конфиге выше) решает эту проблему сразу, без диагностики — можно ставить по умолчанию.

---

## Защита от сканирования портов (бан сразу по всем портам)

Идея: на портах, которых на VPN-сервере в принципе не должно быть (FTP, RDP, MySQL, Redis и т.п.), ставим nftables-ловушку. Одно обращение туда — это сканер, и он банится **сразу на всех портах**, а не только на том, куда постучался.

### `/etc/nftables-portscan.conf`
```
#!/usr/sbin/nft -f
table inet portscan
delete table inet portscan

table inet portscan {
	chain input {
		type filter hook input priority filter - 5; policy accept;
		iifname "lo" return
		tcp dport { 21, 23, 25, 110, 143, 445, 1433, 1434, 3306, 3389, 5432, 5900, 5901, 6379, 7001, 8080, 8081, 8888, 9200, 11211, 27017 } ct state new limit rate 4/minute log prefix "PORTSCAN: " drop
	}
}
```

⚠️ **Перед применением проверь `ss -tlnp`** на сервере — убедись, что среди этих портов ничего своего не слушает. Если что-то реально висит на одном из них (например, локальная БД) — либо убери порт из списка, либо держи его строго на `127.0.0.1` (loopback явно исключён строкой `iifname "lo" return`, так что локальные сервисы не пострадают).

### `/etc/systemd/system/nft-portscan-trap.service`
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

### `/etc/fail2ban/filter.d/portscan.conf`
```ini
[Definition]
failregex = ^.*PORTSCAN: .*SRC=<HOST> .*$
ignoreregex =
```

### `/etc/fail2ban/jail.d/portscan.conf`
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

### Обязательный файл с дефолтами для бана по всем портам

`%(banaction_allports)s` не входит в стандартную сборку `jail.conf` Debian/Ubuntu — его нужно объявить самому:

`/etc/fail2ban/jail.d/00-defaults-allports.conf`
```ini
[DEFAULT]
banaction = nftables
banaction_allports = nftables[type=allports]
backend = systemd
```

**Грабля:** если написать `action = %(action_allports)s` напрямую (частый совет из старых гайдов в интернете) — fail2ban падает с `ERROR interpolation key 'action_allports'`, такого шаблона просто не существует. Работает только связка `banaction_allports` + отдельный `[DEFAULT]`-блок, как выше.

Применение:
```bash
systemctl daemon-reload
systemctl enable --now nft-portscan-trap.service
systemctl restart fail2ban
nft list table inet portscan
fail2ban-client status portscan
```

Список забаненных: `fail2ban-client status portscan` → строка `Banned IP list`. Разбанить: `fail2ban-client set portscan unbanip <IP>` (полезно, если сам погонял nmap по своему серверу и попал под собственную ловушку).

---

## Сетевые sysctl-твики: BBR и буферы

**Важно:** не копируй типовые «VPN sysctl» гайды из интернета не глядя — многие из них рассчитаны на выделенные серверы с 16–32ГБ RAM. На бюджетном VPS с 1–2ГБ некоторые советуемые значения (например статичный `tcp_mem` на несколько гигабайт) банально больше, чем есть памяти на сервере целиком — это прямой риск OOM.

Сначала проверь объём RAM: `free -h`, и выбери подходящий профиль ниже.

### BBR + fq — основной твик

Классический `cubic` воспринимает потерю пакета как сигнал перегрузки канала и резко режет скорость. На дальних/зарубежных маршрутах и мобильных сетях потери пакетов — норма, а не перегрузка, поэтому `cubic` там теряет скорость без повода. `bbr` строит модель канала (пропускная способность + RTT) вместо реакции на потери — для VPN-трафика это существенно эффективнее. `fq` (Fair Queueing) обязателен как напарник — он даёт точный packet pacing, на котором построен алгоритм BBR.

```bash
modprobe tcp_bbr
echo tcp_bbr > /etc/modules-load.d/bbr.conf
```

### `/etc/sysctl.d/99-vpn-tuning.conf`

**Профиль Small (~1ГБ RAM)** — большинство бюджетных VPS:
```ini
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.ipv4.tcp_rmem = 4096 131072 8388608
net.ipv4.tcp_wmem = 4096 131072 8388608
net.ipv4.tcp_mem = 131072 262144 393216

net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1

net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 4096

net.ipv4.icmp_echo_ignore_all = 0
```

**Профиль Medium (~2ГБ RAM)** — только буферы отличаются:
```ini
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 131072 16777216
net.ipv4.tcp_wmem = 4096 131072 16777216
net.ipv4.tcp_mem = 262144 524288 786432
```

**Профиль Large (~6ГБ+ RAM)**:
```ini
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 131072 33554432
net.ipv4.tcp_wmem = 4096 131072 33554432
net.ipv4.tcp_mem = 786432 1048576 1572864
```

Что означают остальные параметры:

| Параметр | Зачем |
|---|---|
| `tcp_fastopen = 3` | TCP Fast Open в обе стороны — экономит один RTT на установку соединения, заметно при частых переподключениях клиентов. |
| `tcp_keepalive_time/intvl/probes = 120/30/5` | Дефолт Linux — 2 часа до первой проверки живости соединения. Для клиентов за мобильным NAT/CGNAT это означает часы «мёртвых» соединений — таймаут NAT у операторов обычно короче. 120с надёжнее. |
| `tcp_fin_timeout = 15` | Быстрее освобождает сокет после закрытия соединения (дефолт 60с) — важно при большом числе переподключений. |
| `tcp_tw_reuse = 1` | Разрешает переиспользовать TIME-WAIT сокеты для новых исходящих соединений. |
| `somaxconn / netdev_max_backlog / tcp_max_syn_backlog = 4096` | Очереди на приём новых соединений/пакетов — дефолт (128–1000) мал при десятках-сотнях одновременных клиентов. |

Применить:
```bash
sysctl --system
sysctl net.core.default_qdisc net.ipv4.tcp_congestion_control net.core.rmem_max
```

### Что НЕ стоит трогать

- **`tcp_window_scaling / tcp_sack / tcp_timestamps`** — уже `1` по умолчанию в любом современном ядре 15+ лет, включать «как твик» бессмысленно.
- **`icmp_echo_ignore_all`** — не отключай ping «для безопасности», если планируешь ставить любой мониторинг (Zabbix/Prometheus/Uptime Kuma и т.п.) — блокировка ICMP тихо ломает алерты о доступности, а от реальных атак не защищает: сканеры и так проверяют порты напрямую, а не ходят через ping.
- **IPv6** — не отключай массово без конкретной причины.

---

## Если на сервере крутится Telegram-прокси (MTProxy)

Если на этом же сервере работает MTProxy или похожий Telegram-прокси, учти: **BBR + большие TCP-буферы (8МБ+) может ломать MTProto-хендшейк** за DPI/файрволами, блокирующими Telegram напрямую (наблюдаемая ошибка вида `uplinkHTTPMethod can be GET only in packet-up mode`). Для такого сервера безопаснее оставить классику — отдельным файлом с более высоким приоритетом загрузки (например `/etc/sysctl.d/99-zz-mtproxy.conf`, префикс `zz-` гарантирует, что он загрузится последним и переопределит общий шаблон):

```ini
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = cubic
```

---

## Чеклист проверки

```bash
systemctl status fail2ban
fail2ban-client status
fail2ban-client status sshd
fail2ban-client status portscan
nft list table inet portscan
sysctl net.core.default_qdisc net.ipv4.tcp_congestion_control
ss -tlnp   # сверить, что ловушка не задела реальный сервис
```
