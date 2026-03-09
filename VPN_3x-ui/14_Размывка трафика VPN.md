# ⚙️ Advanced NetEm Traffic Shaper  
### *Эмуляция сети и маскировка VPN-трафика под «реальный интернет»*

> ⚠️ **Дисклеймер:**  
> Данный материал предоставлен **исключительно в образовательных и исследовательских целях**.  
> Применяйте только в **соответствии с законами вашей страны** и **на своих устройствах**.  
> Автор не несёт ответственности за любое неправомерное использование приведённых примеров.

---

## 📖 Содержание

1. [Зачем нужен NetEm и tc](#-для-чего-нужны-tc-и-netem)  
2. [Как NetEm помогает маскировать трафик](#-как-netem-помогает-маскировать)  
3. [Скрипт `netem-advanced.sh`](#-скрипт-netem-advancedsh)  
4. [Systemd-служба `netem-advanced.service`](#-systemd-служба-netem-advancedservice)  
5. [Мониторинг и проверка](#-мониторинг-и-проверка)  
6. [Интерпретация команд `tc`](#-интерпретация-команд-tc)  
7. [Аналогия](#-аналогия)  
8. [Итог](#-итог)

---

## 💡 Для чего нужны `tc` и `netem`

### 🔧 Технически

**`tc` (Traffic Control)** — это инструмент Linux для управления сетевым трафиком.  
Он позволяет ограничивать скорость, добавлять задержки, потери пакетов, изменять порядок и многое другое.

Работает на уровне **очередей (qdisc)** — перед отправкой пакет попадает под управление `tc`.

**`netem` (Network Emulator)** — модуль внутри `tc`, эмулирующий "плохую" сеть.

| Эффект | Параметр | Пример |
|:--|:--|:--|
| Задержка | `delay` | `delay 100ms` |
| Джиттер | `delay 100ms 20ms` | разброс ±20 мс |
| Потеря пакетов | `loss` | `loss 5%` |
| Дублирование | `duplicate` | `dup 2%` |
| Переупорядочивание | `reorder` | `reorder 3%` |

🧪 **Пример:**
```bash
tc qdisc add dev eth0 root netem delay 100ms loss 5% reorder 2%
````

→ Всё, что проходит через `eth0`, теперь идёт с задержкой, потерями и перемешиванием пакетов.

---

## 🌐 Как NetEm помогает маскировать

Трафик **VPN**, **DoH**, **DoT**, **DNSCrypt** выглядит *слишком чисто*:

* одинаковые размеры пакетов,
* стабильная скорость,
* идеальная периодичность.

🕵️ DPI (Deep Packet Inspection) видит такие закономерности и может определить VPN-трафик.

💡 **Решение:** добавить естественные сетевые "артефакты", свойственные реальной сети.

| Эффект      | Имитация                  | Польза                           |
| :---------- | :------------------------ | :------------------------------- |
| `delay`     | сетевую задержку          | создаёт естественную латентность |
| `jitter`    | колебания времени отклика | трафик становится "живым"        |
| `loss`      | потерю пакетов            | типично для Wi-Fi и 4G           |
| `duplicate` | дубликаты TCP-пакетов     | добавляет хаос                   |
| `reorder`   | перестановку пакетов      | делает поток менее предсказуемым |

🎭 В итоге шифрованный поток становится похож на реальный интернет-трафик:
хаотичный, с колебаниями, естественный и «человечный».

---

## 🧰 Скрипт `netem-advanced.sh`

> Версия: **stable-2025.10.25-gisoman**
> Расположить в `/usr/local/bin/netem-advanced.sh`
> Сделать исполняемым:
>
> ```bash
> nano /usr/local/bin/netem-advanced.sh
> chmod +x /usr/local/bin/netem-advanced.sh
> ```

## Интерфейс enp0s7 - замените на свой в скрипте ниже <br>


```bash
#!/usr/bin/env bash
# netem-advanced.sh — устойчивый шейпер с дружелюбным восстановлением qdisc
# Версия: stable-2025.10.25-gisoman
set -euo pipefail

IFACE="${1:-enp0s7}"
IFB="ifb0"
LOG_TAG="netem"

BASE_RATE="100Mbit"
BURST="10000b"
LATENCY="40ms"
HTB_R2Q=100

MIN_DELAY=3
MAX_DELAY=15
MAX_JITTER=6
MAX_LOSS=3
MAX_DUP=2
MAX_REORDER=2
INTERVAL=6

log() {
  logger -t "$LOG_TAG" "$@"
  echo "$LOG_TAG: $@" >&2
}

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root"; exit 2
fi

ensure_ifb() {
  if ! ip link show "$IFB" &>/dev/null; then
    modprobe ifb numifbs=1 || true
    ip link add "$IFB" type ifb || true
    ip link set dev "$IFB" up
    tc qdisc add dev "$IFACE" ingress 2>/dev/null || true
    tc filter add dev "$IFACE" parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev "$IFB" 2>/dev/null || true
    log "Initialized $IFB and attached ingress mirror to $IFACE"
  fi
}

reset_tree() {
  local dev="$1"
  tc qdisc del dev "$dev" root 2>/dev/null || true
  tc qdisc add dev "$dev" root handle 1: htb default 10 r2q ${HTB_R2Q}
  tc class add dev "$dev" parent 1: classid 1:10 htb rate 400Mbit ceil 500Mbit burst 1600b cburst 1500b
  tc qdisc add dev "$dev" parent 1:10 handle 10: tbf rate "$BASE_RATE" burst "$BURST" latency "$LATENCY"
  tc qdisc add dev "$dev" parent 10: handle 20: netem delay 5ms 1ms distribution normal
  tc qdisc replace dev "$dev" parent 20: fq_codel || true
  log "Rebuilt qdisc tree on $dev (r2q=${HTB_R2Q})"
}

safe_update_netem() {
  local dev="$1"; local args="$2"
  local try=0 max_try=2
  while : ; do
    if tc qdisc show dev "$dev" | grep -qE "netem.*handle 20:"; then
      if tc qdisc change dev "$dev" parent 10: handle 20: netem $args 2>/dev/null; then
        return 0
      fi
      if tc qdisc replace dev "$dev" parent 10: handle 20: netem $args 2>/dev/null; then
        return 0
      fi
    else
      if tc qdisc replace dev "$dev" parent 10: handle 20: netem $args 2>/dev/null; then
        return 0
      fi
    fi
    ((try++))
    log "Warning: update netem failed on $dev (try $try/$max_try)."
    sleep 0.5
    if [ "$try" -ge "$max_try" ]; then
      log "Persistent failure updating netem on $dev — rebuilding tree."
      reset_tree "$dev"
      return 1
    fi
  done
}

apply_netem() {
  local dev="$1"
  local delay=$((RANDOM % (MAX_DELAY - MIN_DELAY + 1) + MIN_DELAY))
  local jitter=$((RANDOM % (MAX_JITTER + 1)))
  local loss=$((RANDOM % (MAX_LOSS + 1)))
  local dup=$((RANDOM % (MAX_DUP + 1)))
  local reorder=$((RANDOM % (MAX_REORDER + 1)))
  local args="delay ${delay}ms ${jitter}ms distribution normal loss ${loss}% duplicate ${dup}% reorder ${reorder}% corrupt 0%"
  if safe_update_netem "$dev" "$args"; then
    log "Applied netem on $dev: delay=${delay}ms±${jitter}ms loss=${loss}% dup=${dup}% reorder=${reorder}%"
  else
    log "Applied netem fallback on $dev (after reset)"
  fi
}

apply_tbf_burst() {
  local dev="$1"
  local rate=$((70000 + RANDOM % 20000))
  tc qdisc change dev "$dev" parent 1:10 handle 10: tbf rate "${rate}kbit" burst "$BURST" latency "$LATENCY" 2>/dev/null || true
  log "Applied TBF burst on $dev: ${rate}kbit"
  sleep 8
  tc qdisc change dev "$dev" parent 1:10 handle 10: tbf rate "$BASE_RATE" burst "$BURST" latency "$LATENCY" 2>/dev/null || true
  log "Removed temporary burst on $dev"
}

ensure_ifb
reset_tree "$IFACE"
reset_tree "$IFB"
log "Started netem advanced loop on $IFACE (mirror $IFB) - HTB r2q=${HTB_R2Q}"

while true; do
  apply_netem "$IFACE"
  apply_netem "$IFB"
  if (( RANDOM % 3 == 0 )); then
    apply_tbf_burst "$IFACE"
  fi
  sleep "$INTERVAL"
done
```

---

## 🧩 Systemd-служба `netem-advanced.service`

> Расположить: `/etc/systemd/system/netem-advanced.service`
> ```bash
> nano /etc/systemd/system/netem-advanced.service
> ```

```ini
[Unit]
# Version: stable-2025.10.25-gisoman
Description=Advanced Netem Traffic Shaper
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/netem-advanced.sh enp0s7
Restart=always
RestartSec=5

AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
PrivateTmp=true

Nice=0
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 🚀 Активация и запуск

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now netem-advanced.service
```

---

## 🧭 Мониторинг и проверка

### Просмотр логов службы

```bash
journalctl -u netem-advanced.service -f
```

### Проверка текущих правил

```bash
tc qdisc show dev enp0s7
tc qdisc show dev ifb0
tc class show dev enp0s7
tc -s qdisc show dev enp0s7
```

---

## 🔍 Интерпретация команд `tc`

| Команда                       | Что показывает              | Зачем                      |
| :---------------------------- | :-------------------------- | :------------------------- |
| `tc qdisc show dev enp0s7`    | Активные очереди (qdisc)    | Проверить текущие правила  |
| `tc qdisc show dev ifb0`      | Настройки входящего трафика | Контроль inbound потока    |
| `tc class show dev enp0s7`    | Классы HTB                  | Приоритеты и лимиты        |
| `tc -s qdisc show dev enp0s7` | Статистика пакетов          | Потери, задержки, загрузка |

---

## 🛣️ Аналогия

Представь, что `tc` — это **транспортная система Linux**:

| Компонент | Аналогия                             |
| :-------- | :----------------------------------- |
| `qdisc`   | светофоры и камеры                   |
| `class`   | полосы движения                      |
| `netem`   | участок дороги с туманом и выбоинами |
| `tc -s`   | счётчик машин и событий              |

---

## ✅ Итог

`Netem Advanced Shaper` делает шифрованный трафик **похожим на реальный** —
добавляет задержки, джиттер, потери и хаос,
чтобы потоки выглядели естественно и не вызывали подозрений у DPI.

---

© 2025 · **gisoman / Netem Advanced Shaper**
🧾 Лицензия: MIT
