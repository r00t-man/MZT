# 🛡️ Изменение DNS на серверах Яндекса (DoT через systemd-resolved)

Ниже — готовая инструкция и автоматический скрипт для Ubuntu Server/VPS, который переводит сервер на **DNS Яндекса** с шифрованием **DNS-over-TLS (DoT)**.

Скрипт делает всё автоматически:

- проверяет, что сетевой интерфейс `eth0` существует;
- определяет его фактический `MAC`;
- отключает получение DNS от DHCP через `netplan`;
- включает DoT в `systemd-resolved`;
- настраивает **AdGuard + Cloudflare** как основные DNS;
- добавляет **Yandex DNS** как резервный DoT;
- создаёт бэкапы изменяемых файлов;
- применяет настройки и показывает итоговую проверку.

## ⚡ Установка в одну команду

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/ya-dns-dot.sh)
```

---

## 📑 Содержание

- [⚡ Установка в одну команду](#-установка-в-одну-команду)
- [1) Скрипт](#1-скрипт)
- [2) Как сохранить и запустить](#2-как-сохранить-и-запустить)
- [3) Что именно меняет скрипт](#3-что-именно-меняет-скрипт)
- [4) Варианты профиля Yandex DNS](#4-варианты-профиля-yandex-dns)
- [5) Проверка, что DoT реально работает](#5-проверка-что-dot-реально-работает)

---

## 1) Скрипт

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
CLOUDINIT_DISABLE_FILE="/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
RESOLVED_DROPIN_DIR="/etc/systemd/resolved.conf.d"
RESOLVED_DOT_FILE="${RESOLVED_DROPIN_DIR}/10-dot.conf"
IFACE="eth0"

# Основные DNS (AdGuard + Cloudflare) и резерв Yandex (DoT)
PRIMARY_DNS="94.140.14.14#dns.adguard-dns.com 1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one"
FALLBACK_DNS="77.88.8.8#common.dot.dns.yandex.net 77.88.8.1#common.dot.dns.yandex.net"

log()  { echo -e "\e[1;32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[1;31m[ERR ]\e[0m $*" >&2; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Запусти скрипт от root: sudo bash $0"
    exit 1
  fi
}

check_requirements() {
  command -v netplan >/dev/null 2>&1 || { err "netplan не найден"; exit 1; }
  command -v resolvectl >/dev/null 2>&1 || { err "resolvectl не найден"; exit 1; }
  systemctl is-enabled systemd-resolved >/dev/null 2>&1 || warn "systemd-resolved не включён, пробую продолжить"
}

check_iface() {
  if ! ip link show "${IFACE}" >/dev/null 2>&1; then
    err "Интерфейс ${IFACE} не найден"
    ip -br link || true
    exit 1
  fi
}

get_mac() {
  local mac
  mac="$(tr '[:upper:]' '[:lower:]' < "/sys/class/net/${IFACE}/address")"
  if [[ ! "${mac}" =~ ^([0-9a-f]{2}:){5}[0-9a-f]{2}$ ]]; then
    err "Не удалось определить MAC для ${IFACE}: ${mac}"
    exit 1
  fi
  echo "${mac}"
}

backup_file() {
  local f="$1"
  if [[ -f "${f}" ]]; then
    local ts
    ts="$(date +%F-%H-%M-%S)"
    cp -a "${f}" "${f}.bak.${ts}"
    log "Создан бэкап: ${f}.bak.${ts}"
  fi
}

write_cloudinit_disable() {
  mkdir -p /etc/cloud/cloud.cfg.d
  cat > "${CLOUDINIT_DISABLE_FILE}" <<'EOC'
network: {config: disabled}
EOC
  log "Cloud-init network config отключён: ${CLOUDINIT_DISABLE_FILE}"
}

write_netplan() {
  local mac="$1"
  backup_file "${NETPLAN_FILE}"

  cat > "${NETPLAN_FILE}" <<EON
network:
  version: 2
  ethernets:
    ${IFACE}:
      match:
        macaddress: "${mac}"
      set-name: "${IFACE}"
      dhcp4: true
      dhcp6: false
      dhcp4-overrides:
        use-dns: false
EON

  chmod 600 "${NETPLAN_FILE}"
  log "Записан netplan конфиг: ${NETPLAN_FILE}"
}

write_resolved_dot() {
  mkdir -p "${RESOLVED_DROPIN_DIR}"
  backup_file "${RESOLVED_DOT_FILE}"

  cat > "${RESOLVED_DOT_FILE}" <<EOR
[Resolve]
DNS=${PRIMARY_DNS}
FallbackDNS=${FALLBACK_DNS}
DNSOverTLS=yes
DNSSEC=no
EOR

  chmod 644 "${RESOLVED_DOT_FILE}"
  log "Записан systemd-resolved DoT конфиг: ${RESOLVED_DOT_FILE}"
}

apply_config() {
  log "Проверяю netplan..."
  netplan generate

  log "Применяю netplan..."
  netplan apply

  log "Перезапускаю systemd-resolved..."
  systemctl restart systemd-resolved
}

show_result() {
  echo
  log "Итоговая проверка:"
  echo "--------------------------------------------------"
  resolvectl status || true
  echo "--------------------------------------------------"
  resolvectl query ya.ru || true
  echo "--------------------------------------------------"
}

main() {
  require_root
  check_requirements
  check_iface

  local mac
  mac="$(get_mac)"

  log "Найден интерфейс: ${IFACE}"
  log "MAC адрес: ${mac}"

  write_cloudinit_disable
  write_netplan "${mac}"
  write_resolved_dot
  apply_config
  show_result

  log "Готово."
  log "Ожидаемый признак успеха: +DNSOverTLS в выводе resolvectl"
  log "И строка: Data was acquired via local or encrypted transport: yes"
}

main "$@"
```

---

## 2) Как сохранить и запустить

```bash
cat > /root/setup-yandex-dot-dns.sh <<'SCRIPT'
# (вставь сюда скрипт выше целиком)
SCRIPT

chmod +x /root/setup-yandex-dot-dns.sh
bash /root/setup-yandex-dot-dns.sh
```

---

## 3) Что именно меняет скрипт

Скрипт управляет тремя файлами:

- `/etc/netplan/50-cloud-init.yaml`
  - оставляет DHCP для адреса,
  - но отключает получение DNS от DHCP (`dhcp4-overrides: use-dns: false`).

- `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg`
  - отключает перегенерацию сети со стороны `cloud-init`.

- `/etc/systemd/resolved.conf.d/10-dot.conf`
  - включает DoT,
  - задаёт AdGuard + Cloudflare как основные резолверы,
  - добавляет Yandex DNS как резерв.

---

## 4) Варианты профиля Yandex DNS

Если нужно переключить резервный профиль Яндекса, меняй значение `FALLBACK_DNS` в скрипте:

### Safe

```bash
FALLBACK_DNS="77.88.8.88#safe.dot.dns.yandex.net 77.88.8.2#safe.dot.dns.yandex.net"
```

### Family

```bash
FALLBACK_DNS="77.88.8.7#family.dot.dns.yandex.net 77.88.8.3#family.dot.dns.yandex.net"
```

---

## 5) Проверка, что DoT реально работает

После применения конфига:

```bash
resolvectl status
resolvectl query ya.ru
```

Ожидаемые признаки:

- в статусе виден `DNSOverTLS=yes`;
- в выводе запроса есть строка: `Data was acquired via local or encrypted transport: yes`.

Если это так — DNS-запросы идут в шифрованном виде.
