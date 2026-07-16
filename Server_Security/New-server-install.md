# 🆕 Новый сервер — чек-лист первичной настройки

[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04%20%7C%20Debian%2012-orange?style=flat-square)]()
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
| `tmux` | не терять сессию при обрыве SSH — см. [отдельную статью про screen](../info/Работа%20со%20screen%20—%20мультиплексор%20терминала.md) (альтернатива tmux) |
| `jq` | разбор JSON — пригодится для любых API (панели, боты) |
| `unzip` | архивы |
| `lsof` | какой процесс держит порт/файл |
| `iperf3` | тест пропускной способности канала (нужен, только если планируете каскадный VPN между двумя серверами) |
| `dos2unix` | чинит CRLF в скриптах, скопированных из Windows/браузера |
| `openssl` | ручная работа с сертификатами/TLS-хендшейком |
| `rsync` | синхронизация файлов — см. [отдельную статью](../info/Автоматическая%20передача%20файлов%20между%20серверами%20через%20rsync%20и%20SSH.md) |
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

На сервере (под нужным пользователем) — замените строку с ключом на свой публичный ключ:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAA... ваш_публичный_ключ
EOF
chmod 600 ~/.ssh/authorized_keys
```

Базовый блок в `/etc/ssh/sshd_config` — правим существующие строки на месте (не дублируем в конец файла,
иначе при повторной директиве в sshd_config побеждает **первая**, а не последняя — см. предупреждение
ниже про cloud-init, тот же принцип):

```bash
sed -i 's/^#\?Port .*/Port SSH_PORT/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
sshd -t && systemctl restart ssh
```

> [!WARNING]
> **На Ubuntu/Debian с cloud-init простой `PasswordAuthentication no` в конце файла может НЕ сработать** —
> `Include /etc/ssh/sshd_config.d/*.conf` в начале файла подключает `50-cloud-init.conf` с `yes`, и
> побеждает **первая** встреченная директива, не последняя. Проверять не `grep`-ом файла, а эффективный
> конфиг: `sshd -T | grep passwordauthentication` (должно быть `no`). Полный разбор и фикс — в
> [разделе 1 основного гайда](./README.md#1-ssh).

> [!IMPORTANT]
> Перед выключением пароля — обязательно проверить вход по ключу в **новой** SSH-сессии, не закрывая
> текущую. Заранее откройте `SSH_PORT` в firewall, когда будете его настраивать (шаг 9) — иначе рискуете
> потерять доступ при смене порта.

---

## 5) Fail2ban для SSH

```bash
mkdir -p /etc/fail2ban
cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled  = true
port     = SSH_PORT
filter   = sshd
backend  = systemd
findtime = 600
maxretry = 3
bantime  = 1h
EOF
systemctl enable --now fail2ban
fail2ban-client status sshd
```

> [!CAUTION]
> Когда дойдёте до firewall (nftables) — `action` в jail должен банить по **явному номеру** `SSH_PORT`,
> а не алиасу `port=ssh` (тот резолвится в 22 через `/etc/services`, даже если SSH реально висит на другом
> порту — бан молча не сработает). Подробности — [раздел 2 основного гайда](./README.md#2-fail2ban).

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
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
sysctl --system
```

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
- [ ] Вход по SSH только по ключам (`sshd -T | grep passwordauthentication` → `no`), пароль отключён
      **после** проверки входа по ключу в новой сессии.
- [ ] `fail2ban` активен, jail `sshd` видит нужный порт.
- [ ] `sudo` проверен на CVE-2025-32463.
- [ ] Базовая сетевая гигиена (`sysctl`) применена.
- [ ] Время (UTC) и DNS в порядке.
- [ ] Swap добавлен, если RAM ≤ 2ГБ и свопа не было.
- [ ] Firewall (nftables) настроен — отдельно, см. основной гайд.

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Полный разбор SSH/fail2ban/nftables/
sysctl/sudo/IPv6/DNS — в [основном гайде](./README.md). Остальные разделы — в [корневом README](../README.md).*
