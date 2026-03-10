# Базовые команды Ubuntu 24 для подготовки VPN-ноды

Эта статья обновлена как **универсальный стартовый чеклист** для чистой **Ubuntu 24.04 LTS**: от первичной подготовки сервера до базового hardening под VPN-ноду.

> ⚠️ Команды ниже даны как безопасная база. Подставляйте свои значения: `USERNAME`, `SSH_PORT`, `SERVER_IP`, `VPN_PORTS`.

---

## 0) Быстрая логика подготовки

1. Обновить систему и поставить базовые пакеты.
2. Создать отдельного sudo-пользователя.
3. Настроить SSH-ключи и усилить SSH.
4. Включить firewall (в репозитории используется `nftables`) и открыть только нужные порты.
5. Включить Fail2Ban.
6. Применить базовые сетевые sysctl-параметры.
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
- [ ] Применён `sysctl` профиль.
- [ ] Проверены DNS, время и ошибки в журналах.

---

> 💡 Практика: перед сетевыми изменениями держите 2 SSH-сессии (рабочую и резервную), а при удалённой настройке используйте `tmux`.
