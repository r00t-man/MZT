#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# SOCKS5 Dante Manager
# Main user: gisproxy
# Passwords: random hex
# =========================================================

MAIN_USER="gisproxy"
CONFIG_FILE="/etc/danted.conf"
BACKUP_FILE="/etc/danted.conf_bak"
CREDS_FILE="/root/.dante_socks_users"
SERVICE_NAME="danted"
DEFAULT_EDITOR="${EDITOR:-nano}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1"
    exit 1
  }
}

pause() {
  echo
  read -r -p "Нажмите Enter для возврата в меню..."
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Запусти скрипт от root."
    exit 1
  fi
}

init_files() {
  touch "$CREDS_FILE"
  chmod 600 "$CREDS_FILE"
}

generate_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 16
  else
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n'
  fi
}

detect_network() {
  IFACE=""
  IPV4=""
  IFACE_V6=""
  IPV6=""

  local out

  out="$(ip -o -4 route get 1.1.1.1 2>/dev/null || true)"
  if [[ -n "$out" ]]; then
    IFACE="$(awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}' <<<"$out")"
    IPV4="$(awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' <<<"$out")"
  fi

  out="$(ip -o -6 route get 2606:4700:4700::1111 2>/dev/null || true)"
  if [[ -n "$out" ]]; then
    IFACE_V6="$(awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}' <<<"$out")"
    IPV6="$(awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' <<<"$out")"
  fi

  if [[ -z "${IFACE}" && -z "${IFACE_V6}" ]]; then
    IFACE="$(ip -br link | awk '$1!="lo" && $2 ~ /UP/ {print $1; exit}')"
    IFACE_V6="$IFACE"
  fi

  if [[ -z "${IPV4}" && -n "${IFACE}" ]]; then
    IPV4="$(ip -o -4 addr show dev "${IFACE}" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || true)"
  fi

  if [[ -z "${IPV6}" && -n "${IFACE_V6}" ]]; then
    IPV6="$(ip -o -6 addr show dev "${IFACE_V6}" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || true)"
  fi

  if [[ -z "${IFACE}" ]]; then
    IFACE="${IFACE_V6}"
  fi

  if [[ -z "${IFACE}" ]]; then
    echo "Не удалось определить сетевой интерфейс."
    exit 1
  fi

  if [[ -z "${IPV4}" && -z "${IPV6}" ]]; then
    echo "Не удалось определить IP сервера."
    echo "Проверь вручную: ip -c -br a"
    exit 1
  fi
}

validate_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] || return 1
  (( port >= 1 && port <= 65535 )) || return 1
  return 0
}

port_in_use() {
  local port="$1"
  ss -tulpn 2>/dev/null | grep -qE "[:.]${port}\b"
}

choose_port() {
  local choice port

  while true; do
    echo "Выберите порт:"
    echo "1) 8443   (рекомендуется)"
    echo "2) 9443   (рекомендуется)"
    echo "3) 1194   (альтернативный)"
    echo "4) 51820  (альтернативный)"
    echo "5) Свой порт"
    echo
    read -r -p "Выбор [1-5]: " choice

    case "$choice" in
      1) port="8443" ;;
      2) port="9443" ;;
      3) port="1194" ;;
      4) port="51820" ;;
      5) read -r -p "Введите свой порт: " port ;;
      *) echo "Неверный выбор."; echo; continue ;;
    esac

    if ! validate_port "$port"; then
      echo "Некорректный порт."
      echo
      continue
    fi

    echo "$port"
    return 0
  done
}

get_current_port() {
  if [[ -f "$CONFIG_FILE" ]]; then
    awk '/^internal:/ {for(i=1;i<=NF;i++) if($i=="port"){print $(i+2); exit}}' "$CONFIG_FILE"
  fi
}

get_current_iface() {
  if [[ -f "$CONFIG_FILE" ]]; then
    awk '/^external:/ {print $2; exit}' "$CONFIG_FILE"
  fi
}

save_credential() {
  local user="$1"
  local pass="$2"
  grep -v "^${user}:" "$CREDS_FILE" > "${CREDS_FILE}.tmp" || true
  echo "${user}:${pass}" >> "${CREDS_FILE}.tmp"
  mv "${CREDS_FILE}.tmp" "$CREDS_FILE"
  chmod 600 "$CREDS_FILE"
}

remove_credential() {
  local user="$1"
  grep -v "^${user}:" "$CREDS_FILE" > "${CREDS_FILE}.tmp" || true
  mv "${CREDS_FILE}.tmp" "$CREDS_FILE"
  chmod 600 "$CREDS_FILE"
}

get_password_from_store() {
  local user="$1"
  awk -F: -v u="$user" '$1==u {print substr($0, index($0,$2)); exit}' "$CREDS_FILE" 2>/dev/null
}

list_saved_users() {
  if [[ -s "$CREDS_FILE" ]]; then
    cut -d: -f1 "$CREDS_FILE"
  fi
}

ensure_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt update -y
  apt install -y dante-server python3 curl iproute2 gawk passwd nano openssl
}

create_or_update_user() {
  local username="$1"
  local password="$2"

  if id "${username}" &>/dev/null; then
    echo "[*] Пользователь ${username} уже существует, обновляю пароль..."
  else
    echo "[*] Создаю пользователя ${username} ..."
    useradd -M -s /usr/sbin/nologin "${username}"
  fi

  echo "${username}:${password}" | chpasswd
  usermod -s /usr/sbin/nologin "${username}"
  save_credential "$username" "$password"
}

write_config() {
  local port="$1"
  local iface="$2"

  [[ -f "$CONFIG_FILE" ]] && cp -f "$CONFIG_FILE" "$BACKUP_FILE"

  cat >"$CONFIG_FILE" <<EOF
logoutput: syslog

internal: 0.0.0.0 port = ${port}
external: ${iface}

socksmethod: username
clientmethod: none

user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: connect disconnect error
}
EOF
}

restart_service() {
  systemctl enable "$SERVICE_NAME"
  systemctl restart "$SERVICE_NAME"
}

is_listening() {
  local port="$1"
  if ss -tulpn | grep -qE "[:.]${port}\b"; then
    echo "yes"
  else
    echo "no"
  fi
}

make_tg_link() {
  local server="$1"
  local port="$2"
  local user="$3"
  local pass="$4"

  python3 - <<PY
import urllib.parse
server = "${server}"
port = "${port}"
user = "${user}"
pwd  = "${pass}"
print(f"https://t.me/socks?server={urllib.parse.quote(server, safe='')}&port={port}&user={urllib.parse.quote(user, safe='')}&pass={urllib.parse.quote(pwd, safe='')}")
PY
}

ufw_installed() {
  command -v ufw >/dev/null 2>&1
}

ufw_active() {
  ufw status 2>/dev/null | grep -q "^Status: active"
}

offer_open_port_ufw() {
  local port="$1"

  if ! ufw_installed; then
    return 0
  fi

  if ! ufw_active; then
    return 0
  fi

  echo
  read -r -p "UFW активен. Открыть порт ${port}/tcp и ${port}/udp? [Y/n]: " ans
  ans="${ans:-Y}"

  if [[ "$ans" =~ ^[YyАаДд]$ ]]; then
    ufw allow "${port}/tcp"
    ufw allow "${port}/udp"
    echo "Порт ${port} открыт в UFW."
  else
    echo "Пропускаю открытие порта в UFW."
  fi
}

show_current_settings() {
  detect_network
  local port iface server listen_status

  port="$(get_current_port || true)"
  iface="$(get_current_iface || true)"
  server="${IPV4:-${IPV6}}"

  echo
  echo "=== Current SOCKS5 (Dante) settings ==="
  echo "Service : ${SERVICE_NAME}"
  echo "Status  : $(systemctl is-active "${SERVICE_NAME}" 2>/dev/null || true)"
  echo "Iface   : ${iface:-unknown}"
  [[ -n "${IPV4}" ]] && echo "IPv4    : ${IPV4}"
  [[ -n "${IPV6}" ]] && echo "IPv6    : ${IPV6}"
  echo "Port    : ${port:-unknown}"

  if [[ -n "${port}" ]]; then
    listen_status="$(is_listening "$port")"
    echo "Listen  : ${listen_status}"
  fi

  echo
  if ufw_installed; then
    echo "UFW     : $(ufw status 2>/dev/null | head -n1 | sed 's/^Status: //')"
  else
    echo "UFW     : not installed"
  fi

  echo
  echo "--- Users from local store ---"
  if [[ -s "$CREDS_FILE" && -n "${port}" ]]; then
    while IFS=: read -r user pass; do
      [[ -z "$user" ]] && continue
      echo "User    : $user"
      echo "Pass    : $pass"
      echo "Link    : $(make_tg_link "$server" "$port" "$user" "$pass")"
      echo
    done < "$CREDS_FILE"
  else
    echo "Нет сохранённых пользователей."
    echo
    echo "Примечание: отображаются только пользователи, добавленные этим скриптом."
  fi
}

install_or_reinstall() {
  require_root
  ensure_packages
  init_files
  detect_network

  local port password server listen_status

  port="$(choose_port)"

  if port_in_use "$port"; then
    echo
    echo "Порт $port уже занят."
    return 1
  fi

  password="$(generate_password)"
  create_or_update_user "$MAIN_USER" "$password"
  write_config "$port" "$IFACE"
  restart_service
  offer_open_port_ufw "$port"

  listen_status="$(is_listening "$port")"
  server="${IPV4:-${IPV6}}"

  echo
  echo "=== SOCKS5 (Dante) ready ==="
  echo "Iface   : ${IFACE}"
  [[ -n "${IPV4}" ]] && echo "IPv4    : ${IPV4}"
  [[ -n "${IPV6}" ]] && echo "IPv6    : ${IPV6}"
  echo "Port    : ${port}"
  echo "User    : ${MAIN_USER}"
  echo "Pass    : ${password}"
  echo "Listen  : ${listen_status}"
  echo
  echo "Telegram link:"
  make_tg_link "$server" "$port" "$MAIN_USER" "$password"

  if [[ "${listen_status}" != "yes" ]]; then
    echo
    echo "Danted не слушает порт. Проверь:"
    echo "  systemctl status danted --no-pager -l"
    echo "  journalctl -xeu danted --no-pager | tail -80"
  fi
}

add_new_user() {
  require_root
  init_files

  local username password
  read -r -p "Введите имя нового пользователя: " username

  if [[ -z "${username}" ]]; then
    echo "Имя пользователя не может быть пустым."
    return
  fi

  if [[ ! "$username" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Допустимы только: a-z A-Z 0-9 . _ -"
    return
  fi

  password="$(generate_password)"
  create_or_update_user "$username" "$password"

  echo
  echo "Пользователь добавлен/обновлён:"
  echo "User: $username"
  echo "Pass: $password"

  local port server
  detect_network
  port="$(get_current_port || true)"
  server="${IPV4:-${IPV6}}"

  if [[ -n "${port}" ]]; then
    echo
    echo "Telegram link:"
    make_tg_link "$server" "$port" "$username" "$password"
  else
    echo
    echo "Порт не найден. Сначала установи Dante."
  fi
}

delete_user() {
  require_root
  init_files

  echo "Сохранённые пользователи:"
  list_saved_users || true
  echo

  local username
  read -r -p "Введите имя пользователя для удаления: " username

  if [[ -z "${username}" ]]; then
    echo "Имя пользователя не может быть пустым."
    return
  fi

  if [[ "${username}" == "${MAIN_USER}" ]]; then
    echo "Основного пользователя ${MAIN_USER} лучше не удалять."
    return
  fi

  if id "${username}" &>/dev/null; then
    userdel "${username}" || true
  fi

  remove_credential "$username"
  echo "Пользователь ${username} удалён."
}

change_user_password() {
  require_root
  init_files

  echo "Сохранённые пользователи:"
  list_saved_users || true
  echo

  local username password
  read -r -p "Введите имя пользователя для смены пароля: " username

  if [[ -z "${username}" ]]; then
    echo "Имя пользователя не может быть пустым."
    return
  fi

  if ! id "${username}" &>/dev/null; then
    echo "Пользователь ${username} не существует."
    return
  fi

  password="$(generate_password)"
  echo "${username}:${password}" | chpasswd
  save_credential "$username" "$password"

  detect_network
  local port server
  port="$(get_current_port || true)"
  server="${IPV4:-${IPV6}}"

  echo
  echo "Пароль обновлён:"
  echo "User: $username"
  echo "Pass: $password"

  if [[ -n "${port}" ]]; then
    echo
    echo "Telegram link:"
    make_tg_link "$server" "$port" "$username" "$password"
  fi
}

change_proxy_port() {
  require_root
  detect_network

  local current_port new_port
  current_port="$(get_current_port || true)"

  echo "Текущий порт: ${current_port:-не найден}"
  echo

  new_port="$(choose_port)"

  if [[ -n "${current_port}" && "${new_port}" == "${current_port}" ]]; then
    echo "Это уже текущий порт."
    return
  fi

  if port_in_use "$new_port"; then
    echo "Порт $new_port уже занят."
    return
  fi

  write_config "$new_port" "$IFACE"
  restart_service
  offer_open_port_ufw "$new_port"

  echo "Порт изменён на $new_port."
}

show_one_user_link() {
  require_root
  init_files
  detect_network

  local username pass port server
  port="$(get_current_port || true)"
  server="${IPV4:-${IPV6}}"

  if [[ -z "${port}" ]]; then
    echo "Порт не найден. Сначала установи Dante."
    return
  fi

  echo "Сохранённые пользователи:"
  list_saved_users || true
  echo

  read -r -p "Введите имя пользователя: " username

  if [[ -z "${username}" ]]; then
    echo "Имя пользователя не может быть пустым."
    return
  fi

  pass="$(get_password_from_store "$username" || true)"

  if [[ -z "${pass}" ]]; then
    echo "Нет данных по пользователю ${username} в локальном хранилище."
    echo "Ссылка доступна только для пользователей, добавленных этим скриптом."
    return
  fi

  echo
  echo "User: $username"
  echo "Pass: $pass"
  echo "Link: $(make_tg_link "$server" "$port" "$username" "$pass")"
}

delete_all_except_main() {
  require_root
  init_files

  echo "Будут удалены все пользователи из локального списка, кроме ${MAIN_USER}."
  read -r -p "Продолжить? [y/N]: " confirm

  if [[ ! "$confirm" =~ ^[YyДд]$ ]]; then
    echo "Отменено."
    return
  fi

  local user
  while IFS= read -r user; do
    [[ -z "$user" ]] && continue
    [[ "$user" == "$MAIN_USER" ]] && continue

    if id "$user" &>/dev/null; then
      userdel "$user" || true
    fi
    remove_credential "$user"
    echo "Удалён: $user"
  done < <(list_saved_users || true)

  echo "Готово. Оставлен только ${MAIN_USER}."
}

edit_config() {
  require_root
  need_cmd "$DEFAULT_EDITOR"
  "$DEFAULT_EDITOR" "$CONFIG_FILE"
  echo
  echo "Если менял конфиг вручную — перезапусти сервис через меню."
}

show_service_status() {
  systemctl status "${SERVICE_NAME}" --no-pager -l || true
}

restart_dante() {
  require_root
  systemctl restart "${SERVICE_NAME}"
  echo "Сервис перезапущен."
}

show_menu() {
  clear
  cat <<'EOF'
╔══════════════════════════════════════════════════════╗
║                SOCKS5 Dante Manager                 ║
║                 Main user: gisproxy                 ║
║              Random secret-like passwords           ║
╚══════════════════════════════════════════════════════╝

1)  Установить / переустановить SOCKS5 (Dante)
2)  Показать текущие настройки прокси
3)  Добавить нового пользователя
4)  Удалить пользователя
5)  Сменить пароль пользователю
6)  Показать ссылку для выбранного пользователя
7)  Удалить всех пользователей кроме gisproxy
8)  Редактировать /etc/danted.conf
9)  Сменить порт прокси
10) Перезапустить danted
11) Показать статус danted
0)  Выход
EOF
  echo
}

main() {
  require_root
  need_cmd ip
  need_cmd awk
  need_cmd ss
  need_cmd systemctl
  init_files

  while true; do
    show_menu
    read -r -p "Выбор [0-11]: " choice
    echo

    case "${choice}" in
      1) install_or_reinstall; pause ;;
      2) show_current_settings; pause ;;
      3) add_new_user; pause ;;
      4) delete_user; pause ;;
      5) change_user_password; pause ;;
      6) show_one_user_link; pause ;;
      7) delete_all_except_main; pause ;;
      8) edit_config; pause ;;
      9) change_proxy_port; pause ;;
      10) restart_dante; pause ;;
      11) show_service_status; pause ;;
      0) exit 0 ;;
      *) echo "Неверный выбор."; pause ;;
    esac
  done
}

main "$@"
