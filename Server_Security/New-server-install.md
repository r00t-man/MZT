# 🆕 Новый сервер — чек-лист первичной настройки

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04-orange?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-purple)](../LICENSE)

Копипаст-чеклист для только что купленного VPS: с чего начать **до** установки любого VPN-стека
(3X-UI/Xray/Remnawave и т.п.) — минимальная безопасность + пакеты для администрирования/диагностики.
Команды идут по порядку, блоками — можно копировать целиком в терминал root-сессии.

> [!NOTE]
> **Firewall (nftables) сюда намеренно не входит** — это отдельная большая тема со своими граблями
> (`port=ssh` в fail2ban-правилах, portscan-ловушка и т.д.), см. [раздел 3 основного гайда](./README.md#3-firewall-nftables).
> Здесь — всё, что имеет смысл сделать **до** настройки firewall.

---

## 📋 Порядок действий

1. Обновить систему, поставить пакеты для администрирования/диагностики.
2. Завести отдельного sudo-пользователя (не работать под root постоянно).
3. Настроить SSH-ключи, отключить вход по паролю.
4. Fail2ban для SSH.
5. Проверить/закрыть sudo CVE-2025-32463.
6. Базовая сетевая гигиена (`sysctl`).
7. Время и DNS.
8. Swap (если мало RAM).
9. **Firewall (nftables)** — отдельно, см. [основной гайд](./README.md#3-firewall-nftables).
10. Финальная проверка перед установкой VPN-стека.

---

## 1) Обновление системы

```bash
apt update && apt full-upgrade -y && apt autoremove -y && apt autoclean -y
reboot
```

После перезагрузки:

```bash
cat /etc/os-release
uname -r
```

> [!TIP]
> Автообновления безопасности (не обязательно, но полезно на серверах без постоянного присмотра):
> ```bash
> apt install -y unattended-upgrades
> dpkg-reconfigure -plow unattended-upgrades
> ```

---

## 2) Пакеты: администрирование и диагностика

```bash
apt install -y \
  curl wget ca-certificates gnupg lsb-release \
  git nano mc vim htop tmux jq unzip \
  lsof iperf3 dos2unix \
  openssl rsync socat \
  dnsutils mtr-tiny ncdu whois \
  fail2ban
```

| Пакет | Зачем |
|---|---|
| `curl`/`wget` | скачивание установочных скриптов |
| `ca-certificates`/`gnupg`/`lsb-release` | нужны для подключения сторонних apt-репозиториев по HTTPS/GPG |
| `git` | клонирование репозиториев |
| `nano`/`mc`/`vim` | редактор + файловый менеджер |
| `htop` | мониторинг процессов/нагрузки |
| `tmux` | не терять сессию при обрыве SSH — см. [отдельную статью про screen](../wiki/Работа%20со%20screen%20—%20мультиплексор%20терминала.md) (альтернатива tmux) |
| `jq` | разбор JSON — пригодится для любых API (панели, боты) |
| `unzip` | архивы |
| `lsof` | какой процесс держит порт/файл |
| `iperf3` | тест пропускной способности канала (нужен, только если планируете каскадный VPN между двумя серверами) |
| `dos2unix` | чинит CRLF в скриптах, скопированных из Windows/браузера |
| `openssl` | ручная работа с сертификатами/TLS-хендшейком |
| `rsync` | синхронизация файлов — см. [отдельную статью](../wiki/Автоматическая%20передача%20файлов%20между%20серверами%20через%20rsync%20и%20SSH.md) |
| `socat` | проброс/отладка сетевых соединений |
| `dnsutils` (`dig`/`nslookup`) | диагностика DNS |
| `mtr-tiny` | сетевая диагностика (traceroute + ping в реальном времени) |
| `ncdu` | интерактивный анализ занятого места на диске |
| `whois` | who is владелец домена/IP |
| `fail2ban` | защита от перебора паролей — настраивается в шаге 4 |

---

## 3) Отдельный sudo-пользователь

Не работайте на сервере постоянно под `root`:

```bash
adduser USERNAME
usermod -aG sudo USERNAME
id USERNAME
```

Проверка:

```bash
su - USERNAME
sudo -v
```

---

## 4) SSH-ключи и жёсткий SSH

> [!CAUTION]
> Это шаг, на котором чаще всего теряют доступ к серверу. Не закрывайте текущую
> SSH-сессию, пока новый вход не проверен из **отдельного** окна. Если у провайдера
> есть VNC/консоль восстановления — заранее убедитесь, что вы знаете, как в неё зайти.

### 4.1 Ключ

На сервере (под нужным пользователем) добавьте **свой** публичный ключ. Приватный
остаётся на вашем ПК, на сервер он не попадает никогда.

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAA... ваш_публичный_ключ
EOF
chmod 600 ~/.ssh/authorized_keys
```

Тут же, из другого окна, проверьте что вход по ключу работает (пока с портом 22 и
ещё включённым паролем — просто убедиться, что ключ принят):

```bash
ssh -o PreferredAuthentications=publickey USER@SERVER_IP
```

### 4.2 Выбор порта

```bash
SSH_PORT=22222          # ← ваш порт: 1024–65535, любой кроме 22.
```

Все команды ниже используют переменную `$SSH_PORT` — подставьте её один раз и
копируйте блоки как есть. В **конфигурационные файлы** (`sshd_config.d`, `jail.local`)
переменная не подставится — там номер придётся вписать руками, это отмечено.

Смена порта — это защита только от фонового шума автосканеров (меньше строк в логах,
меньше нагрузки на fail2ban). От целевой атаки не спасает. Ключи + fail2ban важнее.

### 4.3 Каталог privilege separation

```bash
mkdir -p /run/sshd && chmod 0755 /run/sshd
```

`/run` — это tmpfs, каталог `/run/sshd` пересоздаётся при старте `ssh.service`
(`RuntimeDirectory=sshd`). Но `sshd -t` его сам **не создаёт** и падает с
`Missing privilege separation directory: /run/sshd`, а вместе с ним падает
`ExecStartPre=/usr/sbin/sshd -t` в юните — и sshd не стартует вообще. Одна строка
выше снимает эту грабль.

### 4.4 Конфиг sshd (drop-in, не сам `sshd_config`)

Правим **только** свой файл в `sshd_config.d/`. Имя `00-a-…` — чтобы он сортировался
**раньше** `50-cloud-init.conf`: у sshd выигрывает **первая** встреченная директива,
а не последняя, и `50-cloud-init.conf` с `PasswordAuthentication yes` иначе победит.

```bash
cat > /etc/ssh/sshd_config.d/00-a-hardening.conf <<EOF
Port ${SSH_PORT}
Port 22
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
```

Вторая строка `Port 22` — временная страховка на время перехода. Уберёте её позже,
когда новый порт подтверждён.

```bash
sshd -t && echo "=== config OK ==="
```

> [!CAUTION]
> Если `sshd -t` вывел **любую** ошибку — **остановитесь и почините файл**. Не
> делайте `restart`: перезапуск со сломанным конфигом = потеря доступа. Частые
> причины: вписали `Port SSH_PORT` вместо числа; забыли шаг 4.3; лишний символ
> после nano.

### 4.5 Применить порт — выберите ОДИН вариант

В Ubuntu 24.04 слушающим сокетом SSH по умолчанию управляет **не sshd, а systemd**
(`ssh.socket`). Поэтому просто `systemctl restart ssh` новый порт **не подхватывает**.
Два рабочих пути:

#### Вариант A — отключить socket-activation (рекомендуется)

`Port` из `sshd_config` начинает работать ровно так, как во всех обычных гайдах.
Минус только один: sshd занимает ~5 МБ ОЗУ постоянно, а не поднимается по первому
коннекту — на сервере это неважно.

```bash
systemctl disable --now ssh.socket
systemctl unmask ssh.service 2>/dev/null || true
systemctl enable --now ssh.service
systemctl restart ssh.service
```

#### Вариант B — оставить socket-activation (дефолт Ubuntu 24.04)

Работает, если в systemd есть генератор `sshd-socket-generator` (Ubuntu 24.04.1+ и
свежие обновления 24.04). Он при **каждом** `daemon-reload` читает `Port` из
`sshd_config.d/` и сам настраивает сокет на нужный порт (dual-stack).

```bash
test -x /usr/lib/systemd/system-generators/sshd-socket-generator \
  && { systemctl daemon-reload && systemctl restart ssh.socket; echo "socket-activation: OK"; } \
  || echo "!!! генератора НЕТ — используйте Вариант A"
```

> [!CAUTION]
> **Никогда не создавайте и не редактируйте `/etc/systemd/system/ssh.socket.d/*`
> вручную.** Голый `ListenStream=<порт>` под унаследованной из базового юнита
> директивой `BindIPv6Only=ipv6-only` поднимает **только IPv6-сокет**, `ss -tlnp`
> показывает его так же, как dual-stack — отличить нельзя, снаружи `Connection
> refused` по обоим адресам. Разбор реального инцидента (закончился переустановкой
> ОС) — [раздел 1.4 основного гайда](./README.md#14-socket-activation--самое-опасное-место-на-ubuntu-2404).

### 4.6 Проверка (обязательно, до закрытия текущей сессии)

```bash
sshd -T | grep -E '^(port|passwordauthentication|permitrootlogin|pubkeyauthentication) '
ss -tlnp | grep -E ":($SSH_PORT|22)\b"
systemctl is-active ssh.service
```

Ожидаем: `port $SSH_PORT` (и `port 22`), `passwordauthentication no`,
`permitrootlogin without-password`, сокет слушает на новом порту, сервис `active`.

> [!WARNING]
> Проверяем **эффективный** конфиг (`sshd -T`), а не `grep`-ом файла — из-за
> правила «первая директива побеждает» файл может выглядеть верно, а работать иначе
> (полный разбор — [раздел 1.3](./README.md#13-грабля-cloud-init--первая-директива-побеждает)).

Затем из **нового** окна на другой машине:

```bash
ssh -p $SSH_PORT USER@SERVER_IP
```

Зашло по ключу — только теперь можно закрыть первую сессию. **Пароль уже отключён**
(`PasswordAuthentication no` в 4.4) — если бы вход по ключу не работал, вы бы это
увидели здесь, ещё имея живую первую сессию.

### 4.7 Убрать страховочный порт 22

Когда новый порт подтверждён:

```bash
sed -i '/^Port 22$/d' /etc/ssh/sshd_config.d/00-a-hardening.conf
sshd -t && systemctl restart ssh.service      # Вариант A
# или, для Варианта B:  sshd -t && systemctl daemon-reload && systemctl restart ssh.socket
```

> [!IMPORTANT]
> Порт `$SSH_PORT` нужно **открыть в firewall** (шаг 9, nftables) и, если у провайдера
> есть внешний firewall в панели (Aeza, Hetzner Cloud, Oracle и т.п.) — **и там тоже**.
> Открывайте новый порт **до** того, как уберёте `Port 22` и правило для 22.

---

## 5) Fail2ban для SSH

fail2ban читает журнал systemd, находит неудачные попытки входа и банит IP через
nftables. Ставили пакет в шаге 2.

Впишите **свой номер порта** вместо `SSH_PORT` в двух местах (это конфиг-файл,
переменная `$SSH_PORT` тут не сработает):

```bash
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled  = true
port     = SSH_PORT
filter   = sshd
backend  = systemd
findtime = 600
maxretry = 3
bantime  = 1h
action   = nftables[name=SSH, port=SSH_PORT, protocol=tcp]
EOF

sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/fail2ban/jail.local   # подставит номер, если $SSH_PORT ещё в этой сессии
grep -E 'port|action' /etc/fail2ban/jail.local             # убедиться, что стоит число, а не SSH_PORT

systemctl enable --now fail2ban
fail2ban-client status sshd
```

> [!CAUTION]
> В `action` — **явный номер** порта, а не алиас `port=ssh`: тот резолвится в 22
> через `/etc/services`, даже если SSH на другом порту, и бан молча не срабатывает
> (проверено: так «работали» правила на 9 из 14 нод реального парка).

> [!NOTE]
> `backend = systemd` + `filter = sshd` работает на Ubuntu 24.04 «из коробки», в том
> числе при socket-activation: сокет отдаёт соединение единому `ssh.service`
> (`Accept=no`), sshd пишет в журнал как `_COMM=sshd` под `ssh.service`, а стандартный
> `journalmatch = _SYSTEMD_UNIT=sshd.service` матчится через штатный алиас
> `sshd.service → ssh.service`. Проверить, что джейл реально видит события:
> `fail2ban-client status sshd` → ненулевой `Total failed` после нескольких
> неудачных попыток.

> [!IMPORTANT]
> **После смены порта SSH** обязательно поправьте `port`/`action` в `jail.local`
> на новый номер и `systemctl restart fail2ban` — иначе jail слушает старый порт
> и правило бана создаётся не на тот порт.

Джейлы `recidive` (повторные баны — дольше) и `portscan` (ловушка на сканеров) —
[раздел 2 основного гайда](./README.md#2-fail2ban).

---

## 6) sudo — проверить CVE-2025-32463

```bash
apt-get changelog sudo | grep -B15 'CVE-2025-32463' | grep -E '^sudo \('
apt-cache policy sudo
```

Если версия в changelog **≤** вашей установленной/candidate — патч уже есть, ничего делать не нужно.
Если нет — компиляция из исходников и разбор технического долга от неё — в
[разделе 5 основного гайда](./README.md#5-sudo--cve-2025-32463) (там же — почему **не стоит** торопиться
с `make install` не глядя).

---

## 7) Базовая сетевая гигиена (`sysctl`)

```bash
cat > /etc/sysctl.d/98-hygiene.conf <<'EOF'
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
sysctl --system
```

> [!NOTE]
> `rp_filter = 2` (loose), а не `1` (strict) — для Xray-нод разницы нет (клиентский трафик не
> маршрутизируется ядром), но если на ноде есть WireGuard-каскад или policy-routing с несколькими
> таблицами, strict-режим молча роняет пакеты с асимметричным маршрутом. Loose безопаснее по умолчанию.

> [!NOTE]
> Это базовая гигиена, не тюнинг под VPN-трафик. Полный профиль BBR/`fq` с готовыми пресетами под
> объём RAM (Small/Medium/Large) — в [разделе 4 основного гайда](./README.md#4-sysctl-и-bbr), настраивать
> отдельно, когда определитесь с VPN-стеком (там же — предупреждение про MTProxy, которому BBR может
> ломать хендшейк).

---

## 8) Время и DNS

```bash
timedatectl
timedatectl set-timezone UTC
resolvectl query github.com
```

Точное время критично для TLS/сертификатов. Если хотите ещё и зашифровать DNS-запросы **с самого
сервера** (DoT) — отдельный раздел: [раздел 7 основного гайда](./README.md#7-dns-сервера--шифрование-и-фильтрация).

---

## 9) Swap (если мало RAM)

На бюджетных VPS (1–2 ГБ) часто нет свопа вообще — при пиковой нагрузке (например, компиляция чего-то
из исходников) сервер может уйти в OOM вместо просто подтормаживания.

```bash
free -h   # если swap = 0 и RAM ≤ 2ГБ — имеет смысл добавить
```

```bash
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
swapon --show
```

---

## 10) Firewall (nftables)

Не входит в этот чек-лист — отдельная тема, см. [раздел 3 основного гайда](./README.md#3-firewall-nftables)
(таблица/цепочки, portscan-ловушка, интеграция с fail2ban).

---

## 11) Финальная проверка перед установкой VPN-стека

```bash
ip -br a
ip r
ss -tulpen
sudo systemctl --failed
sudo journalctl -p err -b --no-pager
```

Если всё чисто — можно переходить к установке VPN-стека.

---

## ✅ Чек-лист

- [ ] Система обновлена и перезагружена.
- [ ] Поставлены пакеты для администрирования/диагностики.
- [ ] Создан отдельный sudo-пользователь, не работаем под root.
- [ ] `mkdir /run/sshd` сделан, `sshd -t` проходит без ошибок.
- [ ] Вход по SSH только по ключам (`sshd -T | grep passwordauthentication` → `no`), пароль отключён,
      вход по ключу подтверждён из **новой** сессии на **другой машине**.
- [ ] Порт сменён одним из вариантов: **A** — `disable ssh.socket` + `enable ssh.service` (`Port` из
      `sshd_config.d/` работает), **B** — оставлен `ssh.socket` + `daemon-reload` (нужен
      `sshd-socket-generator`). Ручной `ssh.socket.d/` — НИКОГДА. `sshd -T | grep '^port '` и
      `ss -tlnp` показывают новый порт.
- [ ] `fail2ban` активен, jail `sshd` слушает **новый** порт и банит по **явному номеру** (не `port=ssh`);
      после смены порта `jail.local` обновлён и `fail2ban` перезапущен.
- [ ] `sudo` проверен на CVE-2025-32463.
- [ ] Базовая сетевая гигиена (`sysctl`) применена.
- [ ] Время (UTC) и DNS в порядке.
- [ ] Swap добавлен, если RAM ≤ 2ГБ и свопа не было.
- [ ] Firewall (nftables) настроен — отдельно, см. основной гайд.

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Полный разбор SSH/fail2ban/nftables/
sysctl/sudo/IPv6/DNS — в [основном гайде](./README.md). Остальные разделы — в [корневом README](../README.md).*
