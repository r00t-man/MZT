# Базовые команды Ubuntu 24 для подготовки VPN-ноды

Эта статья обновлена как **универсальный стартовый чеклист** для чистой **Ubuntu 24.04 LTS**: от первичной подготовки сервера до базового hardening под VPN-ноду.

> [!IMPORTANT]
> Команды ниже даны как безопасная база. Подставляйте свои значения: `USERNAME`, `SSH_PORT`, `SERVER_IP`, `VPN_PORTS`.

> [!NOTE]
> Эта статья заточена конкретно под подготовку VPN-ноды (включает `nftables`, `ip_forward`). Если нужен
> универсальный чеклист для **любого** нового сервера (без привязки к VPN, зато с пакетами для
> администрирования/диагностики) — см.
> [Новый сервер — чек-лист первичной настройки](../Server_Security/New-server-install.md).

---

## 0) Быстрая логика подготовки

1. Обновить систему и поставить базовые пакеты.
2. Создать отдельного sudo-пользователя.
3. Настроить SSH-ключи и усилить SSH.
4. Включить firewall (в репозитории используется `nftables`) и открыть только нужные порты.
5. Включить Fail2Ban.
6. Применить базовые сетевые sysctl-параметры + BBR/fq и swap.
7. Проверить время, логи, открытые сокеты и автозапуск сервисов.

---

## 1) Обновление системы (чистый сервер)

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
sudo reboot
```

После перезагрузки:

```bash
cat /etc/os-release
uname -r
```

---

## 2) Установка базовых пакетов для администрирования и защиты

```bash
sudo apt install -y \
  curl wget ca-certificates gnupg lsb-release \
  git vim nano htop tmux jq unzip \
  openssl rsync socat \
  fail2ban nftables
```

Опционально (автообновления безопасности):

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 3) Создание отдельного пользователя и sudo

```bash
sudo adduser USERNAME
sudo usermod -aG sudo USERNAME
id USERNAME
```

Проверка sudo от нового пользователя:

```bash
su - USERNAME
sudo -v
```

---

## 4) SSH-ключи и безопасный SSH

На сервере (под нужным пользователем):

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Базовый блок в `/etc/ssh/sshd_config`:

```ini
Port SSH_PORT
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin prohibit-password
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

Проверка и перезапуск:

```bash
sudo sshd -t
sudo systemctl restart ssh
sudo systemctl status ssh --no-pager
```

> [!WARNING]
> Перед сменой SSH-порта обязательно заранее откройте его в firewall.

---

## 5) Firewall (nftables) — минимальная универсальная база

Создать правила `/etc/nftables.conf`:

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0;
    policy drop;

    iif "lo" accept
    ct state established,related accept

    # ICMP (пинг/диагностика)
    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept

    # SSH
    tcp dport SSH_PORT accept

    # VPN-порты (пример)
    tcp dport { 443 } accept
    udp dport { 443 } accept
  }

  chain forward {
    type filter hook forward priority 0;
    policy drop;
  }

  chain output {
    type filter hook output priority 0;
    policy accept;
  }
}
```

Применить:

```bash
sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables
sudo systemctl restart nftables
sudo nft list ruleset
```

---

## 6) Fail2Ban для SSH

`/etc/fail2ban/jail.local`:

```ini
[sshd]
enabled = true
port = SSH_PORT
filter = sshd
backend = systemd
findtime = 600
maxretry = 3
bantime = 1h
action = nftables[name=SSH, port=ssh, protocol=tcp]
```

Запуск и проверка:

```bash
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

---

## 7) Базовый sysctl-hardening

Создать файл `/etc/sysctl.d/99-vpn-node.conf`:

```conf
# Базовая сетевая гигиена
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Если VPN требует маршрутизацию/NAT — включить:
net.ipv4.ip_forward = 1
```

Применить:

```bash
sudo sysctl --system
sysctl net.ipv4.ip_forward
```

### 7.1) BBR + fq — отдельный профиль именно под VPN-трафик

Базовая гигиена выше — общая для любого сервера. Для VPN-ноды отдельно важен алгоритм управления перегрузкой TCP: клиенты часто сидят на нестабильных/мобильных сетях с высоким RTT и потерями пакетов, и BBR на таких сетях заметно снижает задержки/буферизацию по сравнению с дефолтным `cubic`.

Создать `/etc/sysctl.d/99-vpn-tuning.conf`:

```conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
```

`fq` (Fair Queue) обязателен как пара к `bbr` — без неё BBR работает не в полную силу (это официальная рекомендация авторов BBR).

Проверить, что применилось и что модуль ядра вообще поддерживает BBR:

```bash
sudo sysctl --system
sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc
sysctl net.ipv4.tcp_available_congestion_control   # bbr должен быть в списке
```

Если `bbr` не в списке доступных — модуль ядра не подгружен: `sudo modprobe tcp_bbr` и добавить `tcp_bbr` в `/etc/modules-load.d/`.

> [!TIP]
> Более полный профиль (TCP-буферы, keepalive под CGNAT/мобильные сети, TCP Fast Open) — см. пример шаблона в статье [Ansible — эталонная настройка парка серверов](./Ansible%20—%20эталонная%20настройка%20парка%20серверов%20с%20нуля.md#8-роль--из-чего-состоит), раздел про `templates/`.

### 7.2) Swap — не забыть на маленьких VPS

Частая причина случайных OOM-килов на VPS с 1-2GB RAM — отсутствие свопа вообще (некоторые образы облачных провайдеров его не создают по умолчанию). Проверить и создать при необходимости:

```bash
swapon --show   # пусто = свопа нет вообще

sudo fallocate -l 512M /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Размер подбирать под RAM — 512MB-1GB достаточно для лёгкой VPN-ноды (1-2 vCPU, 1-2GB RAM), не пытаться копировать пропорции десктопа.

#### Своп не даёт себя изменить — три частые причины

Сначала диагностика — что вообще сейчас даёт своп:

```bash
swapon --show    # колонка TYPE: file / partition / zram (!)
cat /proc/swaps
free -h
```

**1. `swapoff` виснет или падает `Cannot allocate memory`**

Значит, своп реально используется, и в RAM физически некуда переместить обратно вытесненные страницы — своп нельзя выключить, если некуда деть его содержимое.

```bash
# временно добавляем ВТОРОЙ swap, чтобы дать ядру место для манёвра
sudo fallocate -l 512M /swapfile2
sudo chmod 600 /swapfile2
sudo mkswap /swapfile2
sudo swapon /swapfile2

sudo swapoff /swapfile   # теперь должно пройти — есть куда переложить страницы
# дальше делаем что нужно с /swapfile (пересоздать/удалить/изменить размер)
sudo swapoff /swapfile2 && sudo rm /swapfile2   # убираем временный
```

**2. Нельзя просто "увеличить" уже активный swap-файл**

`fallocate`/`truncate` на уже включённом свопе не работают как ожидается — файл нужно пересоздать целиком:

```bash
sudo swapoff /swapfile
sudo rm /swapfile
sudo fallocate -l 1G /swapfile      # новый размер
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

`/etc/fstab` трогать не нужно, если путь `/swapfile` не менялся — строка остаётся валидной.

**3. Своп есть, а файла нигде нет — Ubuntu 24.04 часто ставит `zram` по умолчанию**

На многих облачных VPS-образах уже крутится **zram-своп** (сжатая область в самой RAM, отдельный механизм, не файл на диске) — `swapon --show` покажет `TYPE=partition`, `NAME=/dev/zram0`, а искать `/swapfile` бесполезно, его и не было.

```bash
swapon --show          # видишь /dev/zram0 — это оно
systemctl status systemd-zram-setup@zram0.service 2>/dev/null
sudo systemctl disable --now systemd-zram-setup@zram0.service
# или, если стоит пакет zram-tools/zram-config:
sudo apt remove --purge zram-tools
```

Можно и не выключать — zram и обычный swapfile спокойно живут вместе одновременно (у каждого своя строка в `swapon --show`, у обычного файла можно задать приоритет выше через `swapon -p 10 /swapfile`).

---

## 8) DNS и время (важно для TLS/сертификатов)

Проверка времени и таймзоны:

```bash
timedatectl
sudo timedatectl set-timezone UTC
```

Проверка DNS:

```bash
resolvectl status
resolvectl query github.com
```

---

## 9) Что проверить перед установкой VPN-панели/ядра

```bash
ip -br a
ip r
ss -tulpen
sudo systemctl --failed
sudo journalctl -p err -b --no-pager
```

Если всё чисто — можно переходить к установке VPN-стека (например, 3X-UI/Xray).

---

## 10) Мини-чеклист «сервер готов к VPN-ноде»

- [ ] Система обновлена и перезагружена.
- [ ] Создан отдельный sudo-пользователь.
- [ ] Вход по SSH только по ключам.
- [ ] Сменён стандартный SSH-порт.
- [ ] `nftables` включён, открыты только нужные порты.
- [ ] `fail2ban` активен и видит `sshd` jail.
- [ ] Применён базовый `sysctl` профиль.
- [ ] BBR + `fq` включены (`tcp_congestion_control`/`default_qdisc`).
- [ ] Swap создан (если RAM ≤ 2GB и его не было изначально).
- [ ] Проверены DNS, время и ошибки в журналах.

---

> [!TIP]
> Практика: перед сетевыми изменениями держите 2 SSH-сессии (рабочую и резервную), а при удалённой настройке используйте `tmux`.

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Остальные статьи — в
[wiki/README.md](./README.md).*
