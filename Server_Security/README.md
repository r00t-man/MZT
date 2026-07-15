# 🔐 Безопасность VPN-сервера — полное руководство

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04%20%7C%20Debian%2012-orange?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-purple)](../LICENSE)

> [!IMPORTANT]
> Материал создан в образовательных целях. Применяйте только на своих серверах и в рамках легальных задач.

Это единая статья взамен прежних 13 отдельных заметок этого раздела (писались с ChatGPT в 2025 году, часть советов устарела или была скопирована из общих гайдов без проверки на реальной нагрузке). В 2026-07 всё пересобрано и **проверено на живом парке** из ~14 продакшен VPN-нод (Xray-core: VLESS/REALITY/XHTTP/Hysteria2, часть под MTProxy) — каждый пункт либо подтверждён вживую, либо явно помечен как непроверенный.

## Содержание

- [1. SSH](#1-ssh)
- [2. Fail2ban](#2-fail2ban)
- [3. Firewall (nftables)](#3-firewall-nftables)
- [4. sysctl и BBR](#4-sysctl-и-bbr)
- [5. sudo — CVE-2025-32463](#5-sudo--cve-2025-32463)
- [6. IPv6 и ICMP](#6-ipv6-и-icmp)
- [7. DNS сервера — шифрование и фильтрация](#7-dns-сервера--шифрование-и-фильтрация)
- [8. Что убрано из старой версии и почему](#8-что-убрано-из-старой-версии-и-почему)

---

## 1. SSH

- **Нестандартный порт** — практично держать по конвенции `22` + последний октет IP (`151.45.20.132` → порт `22132`). Не защита сама по себе, но убирает 95% автоматического шума ботов, сканирующих порт 22.
- **Ключи вместо пароля.** Сгенерировать пару, положить публичный в `~/.ssh/authorized_keys` (`chmod 700 ~/.ssh`, `chmod 600 authorized_keys`), затем в `/etc/ssh/sshd_config`:
  ```ini
  PubkeyAuthentication yes
  PasswordAuthentication no
  PermitRootLogin prohibit-password
  ```
  Перед выключением пароля — обязательно проверить вход по ключу в НОВОЙ сессии, не закрывая старую.

> [!WARNING]
> **Главная грабля, которую 90% гайдов (включая старую версию этой статьи) не упоминают.** На Ubuntu/Debian с cloud-init `sshd_config` обычно содержит `Include /etc/ssh/sshd_config.d/*.conf` РАНЬШЕ строки `PasswordAuthentication no`. У sshd действует правило "первая встреченная директива побеждает" (не последняя!) — а `50-cloud-init.conf` внутри `sshd_config.d/` часто содержит `PasswordAuthentication yes` и обрабатывается первым через `Include`. Итог: ваш явный `no` в конце файла **не действует**, хотя выглядит правильным при простом чтении файла.
>
> **Как проверять правильно — не `grep`, а эффективный конфиг:**
> ```bash
> sshd -T | grep passwordauthentication   # должно быть "no"
> ```
> Если всё ещё `yes` — добавьте override-файл, который сортируется РАНЬШЕ cloud-init (первым по алфавиту), например `/etc/ssh/sshd_config.d/00-a-hardening.conf`:
> ```ini
> PasswordAuthentication no
> ```
> ⚠️ Если у хостера уже есть свой `00-*.conf` (например `00-billpanel.conf` для сброса пароля через веб-консоль) — назовите свой файл ещё раньше по алфавиту (`00-a-...`), иначе он снова проиграет.
>
> Финальная проверка — не доверять даже `sshd -T`, если есть сомнения: реальная проба логином с явным `PasswordAuthentication=yes` должна получить `Permission denied (publickey)` **без** `password` в списке предложенных методов.

- **`AllowUsers root@<ваш IP>`** (или whitelist доверенных сетей) — второй независимый слой поверх ключей.

---

## 2. Fail2ban

```bash
apt update && apt install -y fail2ban nftables
systemctl enable --now nftables 2>/dev/null || true   # опционально, jail сам создаёт свою таблицу
```

### Jail `sshd`

`/etc/fail2ban/jail.local`:
```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 <ваш_домашний/рабочий IP>

[sshd]
enabled  = true
filter   = sshd
port     = 22132
action   = nftables[name=SSH, port=22132, protocol=tcp]
logpath  = %(syslog_authpriv)s
backend  = systemd
findtime = 600
maxretry = 2
bantime  = -1
```

> [!CAUTION]
> **Самая опасная и незаметная ошибка во всей этой теме — писать `port=ssh` вместо реального номера порта.**
> ```ini
> action = nftables[name=SSH, port=ssh, protocol=tcp]   # ❌ выглядит нормально, но НЕ РАБОТАЕТ
> ```
> `ssh` здесь — не волшебное слово "мой текущий SSH-порт", а буквальное имя сервиса, которое nftables резолвит через `/etc/services` — а там `ssh` жёстко привязан к порту **22**, независимо от того, какой порт реально указан в `sshd_config`. Если ваш SSH висит на кастомном порту (а по разделу 1 он должен) — правило забанит порт 22, который **не слушается вообще**, а реальный порт останется полностью открыт для забаненного IP. Бан при этом выглядит рабочим: IP появляется в `fail2ban-client status sshd`, но фактической блокировки не происходит.
>
> Это не гипотетическая проблема — именно так работали правила на 9 из 14 нод в реальном парке, пока не нашли и не поправили руками на порт из конфига явным числом. **Всегда пишите порт числом**, не полагайтесь на `ssh`/`http`/`https` как на алиасы.
>
> **Проверка, что бан реально работает** (chain-правило в fail2ban+nftables создаётся ЛЕНИВО, только при первом реальном бане — поэтому проверка конфига или пустого `nft list ruleset` ничего не докажет):
> ```bash
> fail2ban-client set sshd banip 203.0.113.1   # тестовый бан (TEST-NET, безопасный IP)
> nft list ruleset | grep "dport.*addr-set"    # тут должен быть ВАШ реальный порт
> fail2ban-client set sshd unbanip 203.0.113.1
> ```

### Jail `portscan` — ловушка для сканеров

Идея: банить сразу по всем портам любого, кто постучался в порт, которого на VPN-сервере в принципе не должно быть (FTP/Telnet/СУБД/RDP и т.п.).

`/etc/nftables-portscan.conf`:
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
⚠️ Перед применением — `ss -tlnp` и убедиться, что среди этих портов ничего своего не слушает (loopback уже исключён явно, локальные сервисы на `127.0.0.1` не пострадают).

`/etc/systemd/system/nft-portscan-trap.service`:
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

Обязательный дефолт (без него `banaction_allports` не существует в Debian-сборке `jail.conf`):

`/etc/fail2ban/jail.d/00-defaults-allports.conf`:
```ini
[DEFAULT]
banaction = nftables
banaction_allports = nftables[type=allports]
backend = systemd
```

> [!WARNING]
> `action = %(action_allports)s` (частый совет из старых гайдов) — **не существует**, упадёт с `ERROR interpolation key 'action_allports'`. Работает только `banaction = %(banaction_allports)s` через отдельный `[DEFAULT]`-блок выше.
>
> На минимальных установках без `rsyslog` (только `journald`, нет `/var/log/kern.log`) — `backend = auto` с `logpath=/var/log/kern.log` упадёт при старте (`Have not found any log file`). `backend = systemd` + `journalmatch = _TRANSPORT=kernel` (как в конфиге выше) решает это универсально, ставьте по умолчанию.

Применение:
```bash
systemctl daemon-reload
systemctl enable --now nft-portscan-trap.service
systemctl restart fail2ban
fail2ban-client status portscan
```

---

## 3. Firewall (nftables)

**Не копируйте готовый `policy drop`-шаблон вслепую.** Любой такой пример в интернете (включая старую версию этой статьи) рассчитан на конкретный набор портов автора — обычно только SSH + панель управления. Современный VPN на Xray-core реально слушает намного больше:

- VLESS/REALITY, XHTTP, WS — свои TCP-порты на каждый инбаунд
- Hysteria2 — UDP
- WireGuard (если используется для каскадов) — UDP
- MTProxy — свой TCP-порт
- Панель Remnawave / API — если открыта наружу

Перед любым `policy drop` — **сначала выпишите реальные слушающие порты** (`ss -tlnp` и `ss -ulnp`), и только затем стройте allow-list под них. Одна ошибка здесь роняет всю VPN-функциональность сервера, а не просто SSH.

Общий скелет (адаптируйте порты под свой реальный набор):
```nft
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        iif lo accept
        ct state established,related accept

        tcp dport <ваш SSH-порт> accept

        # далее — РЕАЛЬНЫЕ порты ваших VPN-инбаундов, не пример из гайда
        tcp dport { ... } accept
        udp dport { ... } accept
    }
    chain forward { type filter hook forward priority 0; policy drop; }
    chain output  { type filter hook output priority 0; policy accept; }
}
```

---

## 4. sysctl и BBR

**Не копируйте типовые "VPN sysctl" гайды не глядя** — многие рассчитаны на выделенные серверы с 16–32ГБ RAM. На бюджетном VPS с 1–2ГБ статичный `tcp_mem` на несколько гигабайт — прямой риск OOM. Сначала `free -h`, затем профиль по объёму памяти.

```bash
modprobe tcp_bbr
echo tcp_bbr > /etc/modules-load.d/bbr.conf
```

`/etc/sysctl.d/99-vpn-tuning.conf` — профиль **Small (~1ГБ RAM)**:
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
```

**Profile Medium (~2ГБ)** — буферы `16777216` / `tcp_mem = 262144 524288 786432`.
**Profile Large (~6ГБ+)** — буферы `33554432` / `tcp_mem = 786432 1048576 1572864`.

| Параметр | Зачем |
|---|---|
| `bbr` + `fq` | Модель канала вместо реакции на потери пакетов — эффективнее `cubic` на дальних/мобильных маршрутах, где потери — норма, а не перегрузка. `fq` обязателен как напарник (packet pacing) |
| `tcp_fastopen = 3` | Экономит RTT на установку соединения |
| `tcp_keepalive_* = 120/30/5` | Дефолт Linux — 2 часа до первой проверки; для клиентов за мобильным CGNAT это часы "мёртвых" соединений |
| `tcp_tw_reuse = 1` | Переиспользование TIME-WAIT сокетов |
| `somaxconn`/`backlog` = 4096 | Дефолт (128–1000) мал при десятках-сотнях одновременных клиентов |

### Если на сервере MTProxy/Telegram-прокси

**BBR + большие буферы могут ломать MTProto-хендшейк** за DPI/файрволами (симптом вида `uplinkHTTPMethod can be GET only in packet-up mode` или обрыв соединения). Отдельный файл с более высоким приоритетом загрузки (`zz-` гарантирует загрузку последним, переопределяет общий профиль):

`/etc/sysctl.d/99-zz-mtproxy.conf`:
```ini
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = cubic
```

Применить:
```bash
sysctl --system
sysctl net.core.default_qdisc net.ipv4.tcp_congestion_control
```

### Чего НЕ трогать

- `tcp_window_scaling`/`tcp_sack`/`tcp_timestamps` — уже `1` по умолчанию 15+ лет, бессмысленный "твик"
- `icmp_echo_ignore_all` — **не отключайте**, если планируете любой мониторинг (Zabbix/Prometheus/Uptime Kuma). Блокировка ICMP тихо ломает алерты о доступности сервера, а от реальных атак не защищает — сканеры и так проверяют порты напрямую, не через ping
- **IPv6** — не отключайте массово без конкретной причины (подробнее — раздел 6)

---

## 5. sudo — CVE-2025-32463

В коде `sudo` (до 1.9.17p1) была критическая уязвимость (CVE-2025-32463) — локальный root через опцию `chroot`, без записи в `sudoers`.

> [!IMPORTANT]
> **Не спешите компилировать из исходников.** Debian/Ubuntu бэкпортируют security-патчи в СВОЙ номер пакета, не меняя видимый "апстрим"-номер версии. `sudo --version` может показывать старый номер (например `1.9.15p5`) даже когда CVE уже закрыт — это НЕ надёжный индикатор.
>
> **Правильная проверка:**
> ```bash
> apt-get changelog sudo | grep -B15 'CVE-2025-32463' | grep -E '^sudo \('
> ```
> Если версия в выводе **≤** вашей установленной/candidate — патч уже есть, компилировать не нужно.
> ```bash
> apt-cache policy sudo   # сравнить candidate с этой версией
> ```

Если changelog показывает, что патч ещё не дошёл до вашего дистрибутива — тогда компиляция из исходников оправдана:

```bash
apt install -y build-essential libpam0g-dev libssl-dev
cd /usr/src && wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz
tar -xvzf sudo-1.9.17p2.tar.gz && cd sudo-1.9.17p2
./configure && make && make install
```

> [!WARNING]
> **Компиляция создаёт технический долг.** `make install` кладёт бинарь в `/usr/local/bin/sudo`, который перекрывает apt-пакет по `PATH`, но `dpkg` продолжает считать установленным старый пакет (`dpkg -l sudo` не в курсе про компиляцию). Итог: **все будущие CVE на sudo перестанут закрываться автоматически** через `apt upgrade`/unattended-upgrades — никто не узнает о новой уязвимости, пока кто-то вручную не пересоберёт снова. Если апстрим-фикс наконец дошёл до дистрибутива (проверяйте `apt-get changelog` время от времени) — разумно вернуться на управляемый apt-пакет: `apt install --reinstall --allow-downgrades sudo=<версия из candidate>`.

---

## 6. IPv6 и ICMP

**Не отключайте IPv6 массово через GRUB "на всякий случай".** Частый совет из старых гайдов (`ipv6.disable=1` в GRUB + `reboot`) — тяжёлая, необратимая без ребута мера, которая может сломать провижининг у некоторых хостеров (часть облачных провайдеров используют IPv6 для служебных задач) и не нужна большинству современных VPN-стеков (Xray/Reality работает поверх обычного TCP/UDP, IPv6-утечка возможна только если клиентский конфиг самослепо резолвит AAAA — решается на уровне клиента/роутинга, не хоста).

Если утечка IPv6 у клиентов через сам VPN-туннель реально подтверждена — решать точечно на уровне routing/firewall для конкретного интерфейса, не через `disable_ipv6=1` на весь хост.

**ICMP** — не блокируйте `icmp_echo_ignore_all`, см. предупреждение в разделе 4. Это не даёт реальной защиты (порт-сканеры не полагаются на ping), но ломает мониторинг.

---

## 7. DNS сервера — шифрование и фильтрация

### Зачем вообще шифровать исходящий DNS с сервера

По умолчанию DNS-запросы с сервера (например, для обновлений пакетов, проверки доменов, работы самого VPN-софта) уходят открытым текстом на DNS хостинг-провайдера — тот технически видит и может логировать, к каким доменам обращается сервер. Шифрование (DoT/DoH) закрывает именно это — не защищает клиентов VPN-туннеля (это отдельная тема настройки самого VPN-софта), а защищает **сам сервер**.

### Вариант 1 — самый простой и безопасный: DoT напрямую на публичные резолверы

Не требует отдельного сервера. Drop-in конфиг `systemd-resolved`, без `rm -rf` системных файлов, без обязательного ребута:

`/etc/systemd/resolved.conf.d/10-dot.conf`:
```ini
[Resolve]
DNS=94.140.14.14#dns.adguard-dns.com 1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one
FallbackDNS=77.88.8.8#common.dot.dns.yandex.net 77.88.8.1#common.dot.dns.yandex.net
DNSOverTLS=yes
DNSSEC=no
```
```bash
systemctl restart systemd-resolved
resolvectl status   # проверить: DNSOverTLS=yes, "Data was acquired via ... encrypted transport: yes"
```

Если по каким-то причинам DHCP/cloud-init продолжает переопределять DNS поверх этого конфига — добавить в netplan `dhcp4-overrides: use-dns: false` для интерфейса и `network: {config: disabled}` в `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg` (без удаления существующих netplan-файлов).

### Вариант 2 — если нужна ещё и фильтрация (реклама/malware) на уровне DNS

Это уже отдельный проект — свой резолвер (AdGuard Home) как самостоятельный сервис, потенциально на отдельном сервере, если фильтрация нужна не только для одной VPN-ноды, а как персональный DNS-сервис. Кратко: `AdGuard Home` устанавливается официальным скриптом, работает поверх любого IP (порт 53 конфликтует с `systemd-resolved` — либо отключить резолвед, либо явно указать интерфейс), сертификат — Let's Encrypt/certbot, и списки блокировок (Pi-hole/StevenBlack/BlocklistProject и т.п.) добавляются по одному с контролем нагрузки. Это уже не "hardening VPN-ноды", а отдельный сервис — стоит держать вне статьи про безопасность самого сервера. Полная официальная инструкция: https://adguard.com/ru/blog/adguard-home-on-public-server.html

### Чего избегать

Старые версии этой статьи советовали удалять весь `/etc/netplan` и состояние cloud-init (`rm -rf /var/lib/cloud/...`) ради "полностью локально управляемой" сети. Технически рабочий подход, но избыточно рискованный на проде — легко потерять сетевой доступ без консоли хостера, и требует обязательного ребута. Вариант 1 выше даёт тот же результат (шифрованный исходящий DNS) без этого риска.

---

## 8. Что убрано из старой версии и почему

- **Кейс VPS с масками `/32` и `/24` + "как это влияет на VPN-фингерпринт"** — был написан целиком про **OpenVPN** и специфичное для него сжатие **LZO** (характерные паттерны трафика, по которым фингерпринт-сайты якобы отличают OpenVPN). Современные VPN-стеки на **Xray-core** (VLESS/REALITY/XHTTP/Hysteria2) не используют OpenVPN и LZO вообще — вся эта логика неприменима. Если у вас реально OpenVPN — сетевая проблема с маской `/32` осталась актуальной темой, но fingerprint-часть можно смело игнорировать.
- **dnscrypt-proxy / DoH-обвязка под собственный DNS-сервер** — актуально только если вы пошли по варианту 2 из раздела 7 (свой резолвер). Полная официальная документация `dnscrypt-proxy`/AdGuard покрывает это лучше разрозненных версионных инструкций отсюда.
- **Отдельные "troubleshooting"-заметки про ошибки Netplan/DoT** (`ifdown: unknown interface`, лишний DNS `1.1.1.1` из старого DHCP lease) — актуальны только при выборе тяжёлого пути (удаление netplan/cloud-init state), который сам по себе теперь не рекомендуется, см. раздел 7.
