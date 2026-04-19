# 🚀 Traf Guard — Кастомная Установка на основе wh3r3ar3you

## 🔧 Основные изменения оригинала:
- 🐧 Адаптация под Ubuntu 24.04  
- 🔥 Использование nftables вместо iptables  

---

## 📦 Установка

> [!TIP]
> Но прежде чем запускать скрипт, надо подготовить:

- 📄 JSON профиль в Remnawave  
- 📂 Создать директории логов на хостовой ноде  
- ⚙️ Изменить docker-compose.yml на ноде  

👉 Только потом запустить установку:

> [!WARNING]
> Пока не запускаем

```bash
bash <(curl -Ls https://raw.githubusercontent.com/wh3r3ar3you/mobile443-filter/refs/heads/main/install.sh)
```
> Делаем пока эти шаги: 

## 🚀 Установка и первичная настройка

> ❗ **Первичное обновление списков может занять от 2 до 10 минут** ❗

## ⚙️ Что делает скрипт

После запуска скрипт автоматически:

* 🛡️ Включает `traf_guard`
* 📶 Активирует **mobile ASN allowlist**
* 🔌 Запрашивает **порты для работы**

## 🔧 Требования перед запуском

Перед стартом подготовь:

* 🌐 **API панели Remnawave**
* 🔗 **Адрес панели**
* 👤 **Telegram ID администратора**
* 🔑 **Токен Telegram-бота**

Ещё понадобятся:

* 📄 **Путь к `xray access.log`**

👉 Но его мы сейчас и создадим

## 📂 Основная настройка (обязательно)

Начинаем с работ на самом хосте:

### 1️⃣ Создать каталог логов на хосте

```bash
mkdir -p /var/log/remnanode
chmod 755 /var/log/remnanode
```

### 2️⃣ Исправить docker-compose.yml

👉 На такой — главное отличие в конце добавили папку логов
👉 По сути конфиг стандартный, добавляем только последнюю строку монтирования логов

```yaml
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=2222
      - SECRET_KEY="..."
    volumes:
      - /var/log/remnanode:/var/log/remnanode
```

---

### 3️⃣ Добавить логирование в JSON ноды (изменить профиль в панели Remnawave)

```json
"log": {
  "error": "/var/log/remnanode/error.log",
  "access": "/var/log/remnanode/access.log",
  "loglevel": "warning"
}
```

💡 Почему `warning`, а не `info`

* 💾 Если на сервере всего 1 ГБ RAM и маленький диск — `warning` практичнее
* 📄 `access.log` всё равно будет писаться
* 🔇 Меньше шума в error/logging части

⚠️ Документация прямо предупреждает, что без ротации логи могут быстро вырасти

---

### 4️⃣ Перезапустить контейнер

```bash
cd /opt/remnanode
docker compose down
docker compose up -d
docker compose logs -f -t
```

### 5️⃣ Проверить, что логи появились

📍 На хосте:

```bash
ls -lah /var/log/remnanode
tail -f /var/log/remnanode/access.log
```

📦 Внутри контейнера можно смотреть и штатные xray-логи supervisor, если понадобится диагностика
📘 Документация для node даёт команды tail внутри контейнера по:

* `/var/log/supervisor/xray.out.log`
* `/var/log/supervisor/xray.err.log`

### 6️⃣ Сразу поставить logrotate

```bash
apt install -y logrotate
```

```bash
cat > /etc/logrotate.d/remnanode <<'EOF'
/var/log/remnanode/*.log {
    size 50M
    rotate 5
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF
```

### 🔍 Проверка logrotate

👉 Проверить без принудительной ротации:

```bash
logrotate -d /etc/logrotate.d/remnanode
```

👉 Принудительно применить:

```bash
logrotate -vf /etc/logrotate.d/remnanode
```

## ❗❗❗ Важный момент ❗❗❗

⚠️ logrotate сейчас работает только вручную, если не настроен cron/systemd таймер

### 1️⃣ Проверяем таймер

```bash
systemctl list-timers | grep logrotate
```

👉 Если видишь что-то типа:

```
logrotate.timer
```

✅ значит всё ок — будет крутиться автоматически

### 2️⃣ Если нет таймера — включаем

```bash
systemctl enable logrotate.timer
systemctl start logrotate.timer
systemctl status logrotate.timer
```

> [!CAUTION]
> Теперь запускаем установку основного скрипта:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/wh3r3ar3you/mobile443-filter/refs/heads/main/install.sh)
```
И выбираем полную установку, потом вводим наши данные API ID и прочие.

## 🔥 Адаптация под nftables

Далее устанавливаем адаптацию под **nftables**:

📍 Лучше создать скрипт на хосте, например в `/srv`

> [!IMPORTANT]
> Создай файл по пути nano /srv/01_trafguard.sh
> И туда вставь содержимое из блока 📜 Сам скрипт

```bash
nano /srv/01_trafguard.sh
```

## 📜 Сам скрипт

```bash
set -Eeuo pipefail

TS="$(date +%F-%H%M%S)"
BK="/root/mobile443-nft-backup-$TS"
mkdir -p "$BK"

echo "===> Бэкап текущего состояния"
cp -a /etc/nftables.conf "$BK/" 2>/dev/null || true
cp -a /opt/mobile443 "$BK/" 2>/dev/null || true
cp -a /usr/local/sbin/mobile443-common.sh "$BK/" 2>/dev/null || true
cp -a /usr/local/sbin/mobile443-apply-cache.sh "$BK/" 2>/dev/null || true
iptables-save > "$BK/iptables-save.txt" 2>/dev/null || true
ip6tables-save > "$BK/ip6tables-save.txt" 2>/dev/null || true
ipset save > "$BK/ipset-save.txt" 2>/dev/null || true
nft list ruleset > "$BK/nft-ruleset-before.txt" 2>/dev/null || true
systemctl cat mobile443-apply.service > "$BK/mobile443-apply.service.txt" 2>/dev/null || true

echo "===> Пишем native nftables конфиг"
cat > /etc/nftables.conf <<'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    set traf_guard_government {
        type ipv4_addr
        flags interval
        auto-merge
        comment "Blocked government-related ranges"
    }

    set traf_guard_antiscanner {
        type ipv4_addr
        flags interval
        auto-merge
        comment "Blocked scanners / bad actors"
    }

    set allowed_mobile_443 {
        type ipv4_addr
        flags interval
        auto-merge
        comment "Allowed source IPs for tcp/443 and udp/443"
    }

    set mobile443_deferred_block {
        type ipv4_addr
        flags interval
        auto-merge
        comment "Deferred blocked IPs"
    }

    chain TRAF_GUARD_PRECHECK {
        ip saddr @traf_guard_government log prefix "MOBILE443_TG_GOV: " level warn limit rate 30/minute burst 10 packets
        ip saddr @traf_guard_government drop

        ip saddr @traf_guard_antiscanner log prefix "MOBILE443_TG_SCAN: " level warn limit rate 30/minute burst 10 packets
        ip saddr @traf_guard_antiscanner drop

        return
    }

    chain FILTER_MOBILE_443 {
        jump TRAF_GUARD_PRECHECK

        ip saddr @allowed_mobile_443 accept
        ip saddr @mobile443_deferred_block drop

        log prefix "MOBILE443_BLOCK: " level warn limit rate 30/minute burst 10 packets
        drop
    }

    chain input {
        type filter hook input priority 0;
        policy accept;

        udp dport 443 jump FILTER_MOBILE_443
        tcp dport 443 jump FILTER_MOBILE_443
    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;

        udp dport 443 jump FILTER_MOBILE_443
        tcp dport 443 jump FILTER_MOBILE_443
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}
EOF

echo "===> Переписываем apply-cache под nft"
cat > /usr/local/sbin/mobile443-apply-cache.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
source /usr/local/sbin/mobile443-common.sh

NFT_FAMILY="inet"
NFT_TABLE="filter"
NFT_SET_ALLOW_NAME="allowed_mobile_443"
NFT_SET_GOV_NAME="traf_guard_government"
NFT_SET_ANTISCANNER_NAME="traf_guard_antiscanner"
NFT_SET_DEFERRED_NAME="mobile443_deferred_block"

STATE_DIR="/var/lib/mobile443"
ALLOW_CACHE_FILE="${STATE_DIR}/prefixes.txt"
DEFERRED_FILE="${STATE_DIR}/deferred_block.txt"

mkdir -p "$STATE_DIR"
touch "$ALLOW_CACHE_FILE" "$DEFERRED_FILE"

  echo "[$(date '+%F %T')] $*"
}

  nft list table ${NFT_FAMILY} ${NFT_TABLE} >/dev/null 2>&1 || nft add table ${NFT_FAMILY} ${NFT_TABLE}

  for s in "$NFT_SET_ALLOW_NAME" "$NFT_SET_GOV_NAME" "$NFT_SET_ANTISCANNER_NAME" "$NFT_SET_DEFERRED_NAME"; do
    nft list set ${NFT_FAMILY} ${NFT_TABLE} "$s" >/dev/null 2>&1 || \
      nft add set ${NFT_FAMILY} ${NFT_TABLE} "$s" "{ type ipv4_addr; flags interval; auto-merge; }"
  done
}

  local set_name="$1"
  local file="$2"
  local label="$3"

  nft flush set ${NFT_FAMILY} ${NFT_TABLE} ${set_name}

  [[ -f "$file" ]] || {
    log "WARN ${label}: file not found: ${file}"
    return 0
  }

  while IFS= read -r prefix || [[ -n "$prefix" ]]; do

```

## ⏳ Выполнение

> [!IMPORTANT]
> Выдай права на выполнение и запускай
> 
> ```bash
> chmod +x /srv/01_trafguard.sh
> cd /srv
> ./01_trafguard.sh
> ```
> 
> ⚠️ **Выполнение может занять от 5 до 10 минут — ждём и не прерываем процесс!**

## 🩹 Далее патч 1

> [!NOTE]
> ✅ Этот блок можно просто закинуть в терминал, выполняется сразу:

```bash
cp -a /etc/nftables.conf /etc/nftables.conf.bak.$(date +%F-%H%M%S)

python3 - <<'PY'
from pathlib import Path
p = Path("/etc/nftables.conf")
s = p.read_text()

old = '''    chain FILTER_MOBILE_443 {
        jump TRAF_GUARD_PRECHECK

        ip saddr @allowed_mobile_443 accept
        ip saddr @mobile443_deferred_block drop

        log prefix "MOBILE443_BLOCK: " level warn limit rate 30/minute burst 10 packets
        drop
    }'''

new = '''    chain FILTER_MOBILE_443 {
        ip saddr @allowed_mobile_443 accept

        jump TRAF_GUARD_PRECHECK

        ip saddr @mobile443_deferred_block drop

        log prefix "MOBILE443_BLOCK: " level warn limit rate 30/minute burst 10 packets
        drop
    }'''

if old not in s:
    raise SystemExit("Не найден ожидаемый блок FILTER_MOBILE_443 в /etc/nftables.conf")
p.write_text(s.replace(old, new, 1))
PY

nft -c -f /etc/nftables.conf && systemctl restart nftables

nft list chain inet filter FILTER_MOBILE_443
```

## 📋 Проверка порядка правил (nftables)

В выводе команды:

```bash
nft list chain inet filter FILTER_MOBILE_443
```

📌 Порядок должен быть таким:

```bash
ip saddr @allowed_mobile_443 accept
jump TRAF_GUARD_PRECHECK
ip saddr @mobile443_deferred_block drop
log prefix "MOBILE443_BLOCK: " ...
drop
```

---

## 🧠 Логика работы

Теперь:

* ✅ Если IP есть в `allowed_mobile_443` — он **сразу проходит**
* 🏛️ `government_networks` и 🛡️ `antiscanner` применяются **только к тем**, кто не попал в mobile allowlist

---

## 🩹 Далее патч 2

### 📌 Обязательный патч `mobile443-monitor.sh`

### ⚙️ Функционал:

1. 🚫 Исключает `email: 2` из пользовательских уведомлений
2. 🔕 Не считает отсутствие Telegram проблемой и не спамит этим
3. ⏱️ Ставит cooldown по IP (анти-спам по одному адресу)
4. 📄 Пишет deferred block в `/var/lib/mobile443/deferred_block.txt`
   👉 и сразу применяет через `mobile443-apply.service`
5. 🚨 Оставляет админские алерты по:

   * 🏛️ `government_networks`
   * 🛡️ `antiscanner`

---

## ℹ️ Примечание

```bash
EXEMPT_EMAILS="2"
```

### 🔍 Что это значит

* `email: 2` — это **ID пользователя из Remnawave**

👉 Если нужно несколько:

```bash
EXEMPT_EMAILS="2,5,7"
```

## ✅ Как проверить, что используется

```bash
grep EXEMPT_EMAILS /opt/mobile443/config.conf
```

👉 Если пусто — добавь:

```bash
echo 'EXEMPT_EMAILS="2"' >> /opt/mobile443/config.conf
```

📌 Менять нужно **только**:

```
/opt/mobile443/config.conf
```

---

## 🧠 Почему этого достаточно

* 📥 В скрипте уже есть:

  ```bash
  local exempt="${EXEMPT_EMAILS:-2}"
  ```
* 📦 И в начале:

  ```bash
  source /usr/local/sbin/mobile443-common.sh
  ```

👉 `mobile443-common.sh` подтягивает `config.conf`
➡️ значит любые изменения применяются **без правки скрипта**

## 🔄 Применение

```bash id="l4m8sp"
systemctl restart mobile443-monitor.service
```

## 🚀 Применение Патча 2

> [!NOTE]
> ✅ Этот блок можно просто закинуть в терминал, выполняется сразу:

```bash
set -Eeuo pipefail

cp -a /usr/local/sbin/mobile443-monitor.sh /usr/local/sbin/mobile443-monitor.sh.bak.$(date +%F-%H%M%S)
cp -a /opt/mobile443/config.conf /opt/mobile443/config.conf.bak.$(date +%F-%H%M%S)

cat > /usr/local/sbin/mobile443-monitor.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
source /usr/local/sbin/mobile443-common.sh

NOTIFIED_FILE="${STATE_DIR}/notified.txt"
STATS_BLOCKED_FILE="${STATE_DIR}/stats_blocked.txt"
TG_ALERTS_FILE="${STATE_DIR}/tg_alerts.txt"
DEFERRED_FILE="${STATE_DIR}/deferred_block.txt"
SUPPRESSED_FILE="${STATE_DIR}/suppressed.txt"

NOTIFY_COOLDOWN=21600
ADMIN_ALERT_COOLDOWN=1800
IP_EVENT_COOLDOWN=3600
NO_TG_COOLDOWN=21600

mkdir -p "$STATE_DIR"
touch "$NOTIFIED_FILE" "$STATS_BLOCKED_FILE" "$TG_ALERTS_FILE" "$DEFERRED_FILE" "$SUPPRESSED_FILE"

log() {
  echo "[$(date '+%F %T')] $*"
}

get_last_ts() {
  local file="$1" key="$2"
  grep "^${key} " "$file" 2>/dev/null | tail -1 | awk '{print $2}' || true
}

cooldown_ok() {
  local file="$1" key="$2" cooldown="$3"
  local now last diff
  now=$(date +%s)
  last=$(get_last_ts "$file" "$key")
  [[ -z "$last" ]] && return 0
  diff=$(( now - last ))
  [[ $diff -ge $cooldown ]]
}

mark_ts() {
  local file="$1" key="$2"
  local now tmp
  now=$(date +%s)
  tmp="$(mktemp)"
  grep -v "^${key} " "$file" > "$tmp" 2>/dev/null || true
  echo "${key} ${now}" >> "$tmp"
  install -m 0644 "$tmp" "$file"
  rm -f "$tmp"
}

should_notify() {
  cooldown_ok "$NOTIFIED_FILE" "$1" "$NOTIFY_COOLDOWN"
}

mark_notified() {
  mark_ts "$NOTIFIED_FILE" "$1"
}

should_notify_admin_alert() {
  cooldown_ok "$TG_ALERTS_FILE" "$1" "$ADMIN_ALERT_COOLDOWN"
}

mark_admin_alert() {
  mark_ts "$TG_ALERTS_FILE" "$1"
}

should_process_ip() {
  cooldown_ok "$SUPPRESSED_FILE" "ip:$1" "$IP_EVENT_COOLDOWN"
}

mark_ip_processed() {
  mark_ts "$SUPPRESSED_FILE" "ip:$1"
}

should_log_no_tg() {
  cooldown_ok "$SUPPRESSED_FILE" "no_tg:$1" "$NO_TG_COOLDOWN"
}

mark_no_tg() {
  mark_ts "$SUPPRESSED_FILE" "no_tg:$1"
}

is_exempt_email() {
  local email="$1"
  local exempt="${EXEMPT_EMAILS:-2}"
  [[ ",${exempt}," == *",${email},"* ]]
}

find_user_by_ip() {
  local ip="$1"
  [[ -z "${XRAY_ACCESS_LOG:-}" || ! -f "${XRAY_ACCESS_LOG:-}" ]] && return 0

  tail -n 50000 "$XRAY_ACCESS_LOG" 2>/dev/null \
    | grep -F "from ${ip}:" \
    | grep -oP 'email:\s*\K\S+' \
    | tail -1 || true
}

find_user_by_ip_with_retry() {
  local ip="$1"
  local retries=5
  local delay=1
  local attempt email

  for (( attempt=1; attempt<=retries; attempt++ )); do
    email="$(find_user_by_ip "$ip")"
    if [[ -n "$email" ]]; then
      echo "$email"
      return 0
    fi
    (( attempt < retries )) && sleep "$delay"
  done
  return 0
}

get_remnawave_user() {
  local user_id="$1"
  [[ -z "${REMNAWAVE_API_URL:-}" || -z "${REMNAWAVE_API_TOKEN:-}" ]] && return 0

  curl -sS --max-time 10 \
    -H "Authorization: Bearer ${REMNAWAVE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${REMNAWAVE_API_URL}/api/users/by-id/${user_id}" 2>/dev/null || true
}

extract_tg_id() {
  local api_response="$1"
  local tg_id="" username=""

  if [[ "${TG_ID_SOURCE:-telegramId}" == "username" ]]; then
    username=$(echo "$api_response" | jq -r '.response.username // empty' 2>/dev/null)
    [[ -n "$username" ]] && tg_id=$(echo "$username" | rev | cut -d'_' -f1 | rev)
  elif [[ "${TG_ID_SOURCE:-telegramId}" == "username_custom" ]]; then
    username=$(echo "$api_response" | jq -r '.response.username // empty' 2>/dev/null)
    if [[ -n "$username" ]]; then
      if [[ -z "${TG_USERNAME_SEPARATOR:-}" ]]; then
        tg_id="$username"
      else
        tg_id=$(echo "$username" | rev | cut -d"${TG_USERNAME_SEPARATOR}" -f1 | rev)
      fi
    fi
  else
    tg_id=$(echo "$api_response" | jq -r '.response.telegramId // empty' 2>/dev/null)
  fi

  echo "$tg_id"
}

add_to_deferred_block() {
  local ip="$1"
  local tmp
  tmp="$(mktemp)"
  grep -vFx "$ip" "$DEFERRED_FILE" > "$tmp" 2>/dev/null || true
  echo "$ip" >> "$tmp"
  sort -Vu "$tmp" -o "$tmp"
  install -m 0644 "$tmp" "$DEFERRED_FILE"
  rm -f "$tmp"

  systemctl start mobile443-apply.service >/dev/null 2>&1 || /usr/local/sbin/mobile443-apply-cache.sh >/dev/null 2>&1 || true
  log "Added ${ip} to deferred block nft set for 1 hour-equivalent persistent list"
}

process_blocked() {
  local src_ip="$1"
  local dst_port="$2"
  local now_ts email api_response has_response tg_id msg

  now_ts=$(date '+%F %T')
  echo "${now_ts} ${src_ip} ${dst_port}" >> "$STATS_BLOCKED_FILE"

  if ! should_process_ip "$src_ip"; then
    return 0
  fi

  [[ "${ENABLE_TELEGRAM:-false}" == "true" ]] || {
    mark_ip_processed "$src_ip"
    return 0
  }

  email="$(find_user_by_ip_with_retry "$src_ip")"
  [[ -z "$email" ]] && return 0

  if is_exempt_email "$email"; then
    mark_ip_processed "$src_ip"
    log "Suppressed blocked notification for exempt user '${email}' from IP ${src_ip}"
    return 0
  fi

  add_to_deferred_block "$src_ip"

  api_response="$(get_remnawave_user "$email")"
  if [[ -z "$api_response" ]]; then
    mark_ip_processed "$src_ip"
    log "Blocked ${src_ip}:${dst_port} - failed to get user '${email}' from Remnawave API"
    return 0
  fi

  has_response=$(echo "$api_response" | jq -r '.response // empty' 2>/dev/null)
  if [[ -z "$has_response" || "$has_response" == "null" ]]; then
    mark_ip_processed "$src_ip"
    log "Blocked ${src_ip}:${dst_port} - user '${email}' not found in Remnawave panel"
    return 0
  fi

  tg_id="$(extract_tg_id "$api_response")"
  if [[ -z "$tg_id" || "$tg_id" == "null" ]]; then
    mark_ip_processed "$src_ip"
    if should_log_no_tg "$email"; then
      log "Blocked ${src_ip}:${dst_port} - user '${email}' has no telegram ID (source: ${TG_ID_SOURCE:-telegramId})"
      mark_no_tg "$email"
    fi
    return 0
  fi

  if should_notify "$tg_id"; then
    if [[ -n "${TG_CUSTOM_MESSAGE:-}" ]]; then
      msg="${TG_CUSTOM_MESSAGE//\{ip\}/${src_ip}}"
      msg="$(printf '%b' "$msg")"
    else
      msg="⚠️ <b>Внимание!</b>

Соединение с IP <code>${src_ip}</code> было прервано.

Данный сервер предназначен <b>исключительно для обхода мобильных глушилок</b>, подключение через Wi-Fi не поддерживается, и соединения будут разрываться автоматически.

Пожалуйста, переключитесь на <b>мобильный интернет</b> для стабильной работы."
    fi

    send_tg "$tg_id" "$msg"
    mark_notified "$tg_id"
    log "Notified tg:${tg_id} (${email}) about blocked IP ${src_ip}"
  else
    log "Blocked ${src_ip}:${dst_port} - tg:${tg_id} already notified recently"
  fi

  mark_ip_processed "$src_ip"
}

process_traf_guard_alert() {
  local src_ip="$1"
  local dst_port="$2"
  local reason="$3"
  local key msg

  echo "$(date '+%F %T') ${src_ip} ${dst_port} ${reason}" >> "$STATS_BLOCKED_FILE"

  [[ "${ENABLE_TELEGRAM:-false}" == "true" ]] || return 0
  [[ -n "${TG_ADMIN_ID:-}" ]] || return 0

  key="${reason}_${src_ip}_${dst_port}"
  if ! should_notify_admin_alert "$key"; then
    log "Traffic Guard alert suppressed for ${src_ip}:${dst_port} (${reason})"
    return 0
  fi

  msg="🚨 <b>Traffic Guard alert</b>

Попытка подключения с IP <code>${src_ip}</code> к порту <code>${dst_port}</code>.

Причина блокировки: <b>${reason}</b>."

  send_tg "$TG_ADMIN_ID" "$msg"
  mark_admin_alert "$key"
  log "Traffic Guard alert sent for ${src_ip}:${dst_port} (${reason})"
}

get_log_stream() {
  if command -v journalctl >/dev/null 2>&1; then
    journalctl -kf --no-pager 2>/dev/null
  elif [[ -f /var/log/kern.log ]]; then
    tail -F /var/log/kern.log
  elif [[ -f /var/log/syslog ]]; then
    tail -F /var/log/syslog
  else
    log "ERROR: Cannot find kernel log source"
    exit 1
  fi
}

log "Monitor started, watching for blocked connections..."

get_log_stream | while IFS= read -r line; do
  if [[ "$line" == *"$LOG_PREFIX"* || "$line" == *"$GOV_LOG_PREFIX"* || "$line" == *"$ANTISCANNER_LOG_PREFIX"* ]]; then
    src_ip=""
    dst_port=""
    reason=""

    [[ "$line" =~ SRC=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]] && src_ip="${BASH_REMATCH[1]}"
    [[ "$line" =~ DPT=([0-9]+) ]] && dst_port="${BASH_REMATCH[1]}"

    if [[ -n "$src_ip" && -n "$dst_port" ]]; then
      if [[ "$line" == *"$GOV_LOG_PREFIX"* ]]; then
        reason="government_networks"
        process_traf_guard_alert "$src_ip" "$dst_port" "$reason"
      elif [[ "$line" == *"$ANTISCANNER_LOG_PREFIX"* ]]; then
        reason="antiscanner"
        process_traf_guard_alert "$src_ip" "$dst_port" "$reason"
      else
        process_blocked "$src_ip" "$dst_port"
      fi
    fi
  fi
done
EOF

chmod +x /usr/local/sbin/mobile443-monitor.sh

python3 - <<'PY'
from pathlib import Path
p = Path("/opt/mobile443/config.conf")
s = p.read_text()
if 'EXEMPT_EMAILS=' not in s:
    s += '\nEXEMPT_EMAILS="2"\n'
p.write_text(s)
PY
```

## 🔄 Перезапуск

```bash
systemctl restart mobile443-monitor.service
sleep 7
systemctl status mobile443-monitor.service --no-pager -l | sed -n '1,30p'
tail -n 20 /var/lib/mobile443/suppressed.txt 2>/dev/null || true
````

---

## 🔧 Что изменится

* 🔇 `email: 2` будет тихо подавляться как служебный
* 📭 Сообщение `has no telegram ID` по одному и тому же юзеру не будет сыпаться постоянно
* ⏱️ Один и тот же IP не будет обрабатываться чаще, чем раз в час
* 🚫 `deferred block` будет идти через **nft**, а не через ipset

## 🔍 После этого проверь

```bash
journalctl -u mobile443-monitor.service -n 80 --no-pager
cat /opt/mobile443/config.conf | tail -5
```

👉 Ожидаемо увидишь строку:

```bash
EXEMPT_EMAILS="2"
```

# 📊 🔍 ЛОГИ — последние 20 строк

## 🧠 Xray / Remnanode (кто куда ходит)

```bash
tail -n 20 /var/log/remnanode/access.log
```

```bash
tail -n 20 /var/log/remnanode/error.log
```

## 🚨 mobile443 monitor (блокировки / алерты)

```bash
journalctl -u mobile443-monitor.service -n 20 --no-pager
```

## 🛡️ nftables (ядро / firewall события)

```bash
journalctl -k -n 20 --no-pager
```

## 📦 статистика блоков (накопительный лог)

```bash
tail -n 20 /var/lib/mobile443/stats_blocked.txt
```

## 🧠 suppressed (кто заглушен — exempt / cooldown)

```bash
tail -n 20 /var/lib/mobile443/suppressed.txt
```

## 📬 уведомления (кому слали)

```bash
tail -n 20 /var/lib/mobile443/notified.txt
```

## 🚨 админ алерты (Traffic Guard)

```bash
tail -n 20 /var/lib/mobile443/tg_alerts.txt
```

## 🚫 deferred block (кого временно баним)

```bash
tail -n 20 /var/lib/mobile443/deferred_block.txt
```

# ⚡ 🔴 РЕАЛТАЙМ (live)

## 🧠 Xray (самое важное)

```bash
tail -f /var/log/remnanode/access.log
```

## 🚨 mobile443 monitor

```bash
journalctl -u mobile443-monitor.service -f
```

## 🛡️ firewall (nftables лог)

```bash
journalctl -k -f
```

## 📊 всё вместе (очень удобно)

```bash
multitail \
/var/log/remnanode/access.log \
/var/log/remnanode/error.log \
<(journalctl -u mobile443-monitor.service -f) \
<(journalctl -k -f)
```

👉 если нет:

```bash
apt install -y multitail
```

# 🔥 ТОП команды (будешь юзать чаще всего)

```bash
# кто ломится и куда
tail -f /var/log/remnanode/access.log

# что режет mobile443
journalctl -u mobile443-monitor.service -f

# firewall события
journalctl -k -f
```

# 💡 Бонус — быстро найти клиента по IP

```bash
grep 11.22.33.44 /var/log/remnanode/access.log | tail -20
```

или:

```bash
grep 'email:' /var/log/remnanode/access.log | tail -20
```

# 🧠 Итог

Теперь у тебя есть:

* 📡 кто подключается → `access.log`
* 🚨 кто блокируется → `mobile443-monitor`
* 🛡️ почему блок → `kernel / nftables`
* 🧾 история → `/var/lib/mobile443/*`

## ✅ Result

После выполнения:

* 🛡️ активен traf_guard
* 📡 включена ASN фильтрация
* 📲 Telegram уведомления (опционально)
* 🔍 анализ логов Xray

## 🔥 Architecture

```
Client → Xray → access.log → traf_guard → filtering → Telegram
```
