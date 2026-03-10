#!/usr/bin/env bash
set -euo pipefail

WARP_DIR="/etc/warp-remnanode"
CONF_FILE="$WARP_DIR/config"
LOG_FILE="/var/log/warp-remnanode.log"
DEFAULT_PORT="40000"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SOCKS_PORT="$DEFAULT_PORT"

log() {
  echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
}

msg() {
  echo -e "$*"
}

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root"
    exit 1
  fi
}

init_config() {
  mkdir -p "$WARP_DIR"
  touch "$LOG_FILE"
  if [[ ! -f "$CONF_FILE" ]]; then
    cat > "$CONF_FILE" <<EOF
SOCKS_PORT="${DEFAULT_PORT}"
EOF
  fi
  # shellcheck disable=SC1090
  source "$CONF_FILE"
  SOCKS_PORT="${SOCKS_PORT:-$DEFAULT_PORT}"
}

save_config() {
  cat > "$CONF_FILE" <<EOF
SOCKS_PORT="${SOCKS_PORT}"
EOF
}

need_cmds() {
  local pkgs=()
  command -v curl >/dev/null 2>&1 || pkgs+=(curl)
  command -v gpg >/dev/null 2>&1 || pkgs+=(gnupg)
  command -v jq >/dev/null 2>&1 || pkgs+=(jq)
  command -v ss >/dev/null 2>&1 || pkgs+=(iproute2)
  if [[ ${#pkgs[@]} -gt 0 ]]; then
    apt-get update -y
    apt-get install -y "${pkgs[@]}"
  fi
}

detect_ubuntu() {
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" && "${ID:-}" != "debian" ]]; then
    msg "${RED}Поддерживаются Ubuntu/Debian${NC}"
    exit 1
  fi
  OS_CODENAME="${VERSION_CODENAME:-noble}"
}

warp_installed() {
  command -v warp-cli >/dev/null 2>&1
}

warp_status_raw() {
  warp-cli --accept-tos status 2>/dev/null || true
}

warp_connected() {
  warp_status_raw | grep -qi "Connected"
}

port_in_use() {
  ss -lntup | awk '{print $5}' | grep -qE "[:.]${1}$"
}

install_warp_repo() {
  detect_ubuntu
  mkdir -p /usr/share/keyrings
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
    | gpg --dearmor --yes -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

  cat > /etc/apt/sources.list.d/cloudflare-client.list <<EOF
deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ ${OS_CODENAME} main
EOF

  apt-get update -y
  apt-get install -y cloudflare-warp
}

install_warp() {
  if warp_installed; then
    msg "${YELLOW}WARP уже установлен${NC}"
    return
  fi

  msg "${CYAN}Устанавливаю Cloudflare WARP...${NC}"
  install_warp_repo
  warp-cli --accept-tos registration new
  warp-cli --accept-tos mode proxy
  warp-cli --accept-tos proxy port "${SOCKS_PORT}"
  warp-cli --accept-tos connect || true
  sleep 3

  log "WARP installed, proxy port ${SOCKS_PORT}"
  msg "${GREEN}WARP установлен${NC}"
}

ensure_registered() {
  local st
  st="$(warp_status_raw)"
  if echo "$st" | grep -qi "Registration Missing"; then
    msg "${YELLOW}Регистрация отсутствует, создаю новую...${NC}"
    warp-cli --accept-tos registration new
  fi
}

set_proxy_mode() {
  ensure_registered
  warp-cli --accept-tos mode proxy
  warp-cli --accept-tos proxy port "${SOCKS_PORT}"
  log "Proxy mode set on ${SOCKS_PORT}"
}

connect_warp() {
  ensure_registered
  set_proxy_mode
  warp-cli --accept-tos connect || true
  sleep 3
  if warp_connected; then
    msg "${GREEN}WARP подключён${NC}"
    log "WARP connected"
  else
    msg "${RED}WARP не подключился${NC}"
  fi
}

disconnect_warp() {
  warp-cli --accept-tos disconnect || true
  msg "${YELLOW}WARP отключён${NC}"
  log "WARP disconnected"
}

restart_warp() {
  disconnect_warp
  sleep 1
  connect_warp
}

change_port() {
  read -r -p "Новый SOCKS5 порт [1-65535]: " new_port
  [[ "$new_port" =~ ^[0-9]+$ ]] || { msg "${RED}Некорректный порт${NC}"; return; }
  (( new_port >= 1 && new_port <= 65535 )) || { msg "${RED}Некорректный порт${NC}"; return; }

  if port_in_use "$new_port"; then
    msg "${RED}Порт ${new_port} уже занят${NC}"
    return
  fi

  SOCKS_PORT="$new_port"
  save_config
  set_proxy_mode
  restart_warp
  msg "${GREEN}Порт изменён на ${SOCKS_PORT}${NC}"
  log "Port changed to ${SOCKS_PORT}"
}

show_ips() {
  local direct_ip warp_ip
  direct_ip="$(curl -4 -s --max-time 8 https://ifconfig.me || echo 'N/A')"
  warp_ip="$(curl -4 -s --max-time 12 --proxy "socks5h://127.0.0.1:${SOCKS_PORT}" https://ifconfig.me || echo 'N/A')"

  echo
  msg "${WHITE}Обычный IP:${NC} ${CYAN}${direct_ip}${NC}"
  msg "${WHITE}IP через WARP SOCKS:${NC} ${CYAN}${warp_ip}${NC}"
  echo
}

show_status() {
  echo
  msg "${WHITE}=== WARP status ===${NC}"
  warp_status_raw
  echo
  msg "${WHITE}=== Прослушка SOCKS ===${NC}"
  ss -lntup | grep -E "[:.]${SOCKS_PORT}\b" || echo "Порт ${SOCKS_PORT} не слушается"
  echo
  msg "${WHITE}=== Проверка remnanode ===${NC}"
  docker ps --filter name=^/remnanode$ --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
  echo
  show_ips
}

re_register() {
  msg "${YELLOW}Перерегистрация WARP...${NC}"
  warp-cli --accept-tos disconnect || true
  warp-cli --accept-tos registration delete >/dev/null 2>&1 || true
  warp-cli --accept-tos registration new
  set_proxy_mode
  connect_warp
  log "WARP re-registered"
}

show_remnawave_outbound() {
  cat <<EOF
{
  "tag": "WARP",
  "protocol": "socks",
  "settings": {
    "servers": [
      {
        "address": "127.0.0.1",
        "port": ${SOCKS_PORT}
      }
    ]
  },
  "streamSettings": {
    "sockopt": {
      "mark": 255
    }
  }
}
EOF
}

show_remnawave_routing_examples() {
  cat <<'EOF'
[
  {
    "domain": [
      "geosite:openai",
      "domain:chatgpt.com",
      "domain:chat.openai.com",
      "domain:claude.ai",
      "domain:anthropic.com",
      "domain:gemini.google.com"
    ],
    "outboundTag": "WARP"
  }
]
EOF
}

show_full_profile_example() {
  cat <<EOF
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "tag": "XHTTP-INNER",
      "listen": "@xhttp",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "host": "github.com",
          "mode": "auto",
          "path": "/"
        }
      }
    },
    {
      "tag": "REALITY-ENTRY",
      "port": 443,
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "fallbacks": [
          {
            "dest": "@xhttp"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "xver": 0,
          "target": "github.com:443",
          "shortIds": [
            "**********"
          ],
          "privateKey": "**********",
          "serverNames": [
            "github.com",
            "www.github.com"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "WARP",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": ${SOCKS_PORT}
          }
        ]
      }
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "domain": [
          "regexp:\\.ru$",
          "regexp:\\.su$",
          "regexp:\\.рф$",
          "regexp:\\.xn--p1ai$"
        ],
        "outboundTag": "DIRECT"
      }
    ]
  }
}
EOF
}

generate_keys() {
  # Generate X25519 keys
  msg "${CYAN}Генерация X25519 ключей...${NC}"
  docker exec -it remnanode sh -lc 'xray x25519'
}

generate_shortid() {
  # Generate shortId
  msg "${CYAN}Генерация shortId (hex)...${NC}"
  docker exec -it remnanode sh -lc 'head -c 8 /dev/urandom | xxd -p -c 256'
}

menu() {
  while true; do
    clear
    msg "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    msg "${CYAN}║           WARP for Remnanode Manager         ║${NC}"
    msg "${YELLOW}║                Вайб кодиннг рулит            ║${NC}"
    msg "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo
    msg " 1) Установить / подключить WARP"
    msg " 2) Показать статус"
    msg " 3) Перезапустить WARP"
    msg " 4) Отключить WARP"
    msg " 5) Перерегистрировать WARP"
    msg " 6) Сгенерировать X25519 ключи"
    msg " 7) Сгенерировать shortId"
    msg " 8) Показать outbound для Remnawave"
    msg " 9) Показать routing rules для Remnawave"
    msg "10) Показать полный пример Config Profile"
    msg "11) Перезапустить remnanode"
    msg " 0) Выход"
    echo
    read -r -p "Выбор: " choice

    case "$choice" in
      1) install_and_connect; read -r -p "Enter..." ;;
      2) show_status; read -r -p "Enter..." ;;
      3) restart_warp; show_status; read -r -p "Enter..." ;;
      4) disconnect_warp; read -r -p "Enter..." ;;
      5) re_register; show_status; read -r -p "Enter..." ;;
      6) generate_keys; read -r -p "Enter..." ;;
      7) generate_shortid; read -r -p "Enter..." ;;
      8) show_remnawave_outbound; echo; read -r -p "Enter..." ;;
      9) show_remnawave_routing_examples; echo; read -r -p "Enter..." ;;
      10) show_full_profile_example; echo; read -r -p "Enter..." ;;
      11) restart_remnanode; read -r -p "Enter..." ;;
      0) exit 0 ;;
      *) msg "${RED}Неверный выбор${NC}"; sleep 1 ;;
    esac
  done
}

need_root
init_config
need_cmds
menu
