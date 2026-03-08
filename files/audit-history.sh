#!/usr/bin/env bash
set -Eeuo pipefail

# =========================================================
# Ubuntu 24.04 - Command Audit + Bash History Logger
# =========================================================
# Что делает:
# - ставит auditd + rsyslog + logrotate
# - логирует execve/execveat через auditd
# - логирует интерактивные bash-команды в /var/log/commands.log
# - добавляет user / ssh ip / tty / host / pid / rc / cmd
# - включает ротацию логов
# - сразу активирует профиль для root
# =========================================================

# -----------------------------
# Настройки удалённого syslog
# -----------------------------
REMOTE_SYSLOG_ENABLED="false"      # true / false
REMOTE_SYSLOG_HOST="192.0.2.10"
REMOTE_SYSLOG_PORT="514"
REMOTE_SYSLOG_PROTOCOL="tcp"       # tcp / udp

FORWARD_AUTH_LOGS="true"
FORWARD_BASH_LOGS="true"
FORWARD_AUDIT_LOGS="true"

# -----------------------------
# Служебные функции
# -----------------------------
info()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERR ]\033[0m $*" >&2; }

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    error "Запусти скрипт от root: sudo bash $0"
    exit 1
  fi
}

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp -a "$f" "${f}.bak.$(date +%F-%H%M%S)"
  fi
}

require_root

info "Обновление системы..."
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y

info "Установка пакетов..."
apt install -y auditd audispd-plugins rsyslog logrotate

# =========================================================
# 1. Auditd rules
# =========================================================
info "Настройка auditd..."

backup_file /etc/audit/rules.d/commands.rules
cat > /etc/audit/rules.d/commands.rules <<'EOF'
# Root commands
-a always,exit -F arch=b64 -S execve -S execveat -F auid=0 -k root-commands
-a always,exit -F arch=b32 -S execve -S execveat -F auid=0 -k root-commands

# Regular users
-a always,exit -F arch=b64 -S execve -S execveat -F auid>=1000 -F auid!=4294967295 -k user-commands
-a always,exit -F arch=b32 -S execve -S execveat -F auid>=1000 -F auid!=4294967295 -k user-commands
EOF

# =========================================================
# 2. Global bash logger
# =========================================================
info "Настройка bash-логирования..."

backup_file /etc/profile.d/history-log.sh
cat > /etc/profile.d/history-log.sh <<'EOF'
[[ -n "${BASH_VERSION:-}" && $- == *i* ]] || return

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
HISTIGNORE='*password*:*passwd*:*token*:*apikey*:*secret*:*Authorization:*'
HISTTIMEFORMAT='%F %T '

shopt -s histappend
shopt -s cmdhist

if ! declare -F __log_and_sync_history >/dev/null 2>&1; then
  __log_and_sync_history() {
    local rc=$?

    history -a
    history -n

    local cmd user ssh_ip pts host
    cmd="$(HISTTIMEFORMAT= history 1 | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]*//')"
    [[ -z "$cmd" ]] && return

    user="$(id -un 2>/dev/null || whoami)"
    host="$(hostname -f 2>/dev/null || hostname)"
    pts="$(tty 2>/dev/null || echo 'notty')"

    if [[ -n "${SSH_CONNECTION:-}" ]]; then
      ssh_ip="$(awk '{print $1}' <<< "${SSH_CONNECTION}")"
    else
      ssh_ip="local"
    fi

    logger -p local6.debug -- "user=${user} ip=${ssh_ip} tty=${pts} host=${host} pid=$$ rc=${rc} cmd=${cmd}"
  }
fi

case ";${PROMPT_COMMAND-};" in
  *";__log_and_sync_history;"*) : ;;
  *)
    if [[ -n "${PROMPT_COMMAND:-}" ]]; then
      PROMPT_COMMAND="__log_and_sync_history; ${PROMPT_COMMAND}"
    else
      PROMPT_COMMAND="__log_and_sync_history"
    fi
    ;;
esac

export HISTSIZE HISTFILESIZE HISTCONTROL HISTIGNORE HISTTIMEFORMAT PROMPT_COMMAND
EOF

chmod 0644 /etc/profile.d/history-log.sh
chown root:root /etc/profile.d/history-log.sh

# Чтобы root точно подхватывал хук
if ! grep -qF 'source /etc/profile.d/history-log.sh' /root/.bashrc 2>/dev/null; then
  echo 'source /etc/profile.d/history-log.sh' >> /root/.bashrc
fi

# =========================================================
# 3. Rsyslog config
# =========================================================
info "Настройка rsyslog..."

backup_file /etc/rsyslog.d/10-commands.conf
cat > /etc/rsyslog.d/10-commands.conf <<'EOF'
local6.*    /var/log/commands.log

module(load="imfile")

input(
  type="imfile"
  File="/var/log/audit/audit.log"
  Tag="auditd:"
  Severity="info"
  Facility="local5"
  PersistStateInterval="200"
  reopenOnTruncate="on"
)
EOF

# создаём лог заранее, чтобы не ждать первого события
touch /var/log/commands.log
chown syslog:adm /var/log/commands.log
chmod 0640 /var/log/commands.log

# =========================================================
# 4. Remote syslog (optional)
# =========================================================
backup_file /etc/rsyslog.d/49-remote-forward.conf

if [[ "${REMOTE_SYSLOG_ENABLED}" == "true" ]]; then
  info "Включена пересылка на удалённый syslog ${REMOTE_SYSLOG_PROTOCOL}://${REMOTE_SYSLOG_HOST}:${REMOTE_SYSLOG_PORT}"

  {
    echo '# Remote syslog forwarding'

    if [[ "${FORWARD_BASH_LOGS}" == "true" ]]; then
      if [[ "${REMOTE_SYSLOG_PROTOCOL}" == "tcp" ]]; then
        cat <<EOF
if (\$syslogfacility-text == 'local6') then {
  action(
    type="omfwd"
    target="${REMOTE_SYSLOG_HOST}"
    port="${REMOTE_SYSLOG_PORT}"
    protocol="tcp"
    TCP_Framing="octet-counted"
    KeepAlive="on"
    action.resumeRetryCount="-1"
    queue.type="linkedList"
    queue.filename="fwd_local6"
    queue.maxdiskspace="256m"
    queue.saveonshutdown="on"
  )
}
EOF
      else
        cat <<EOF
if (\$syslogfacility-text == 'local6') then {
  action(
    type="omfwd"
    target="${REMOTE_SYSLOG_HOST}"
    port="${REMOTE_SYSLOG_PORT}"
    protocol="udp"
    action.resumeRetryCount="-1"
    queue.type="linkedList"
    queue.filename="fwd_local6"
    queue.maxdiskspace="256m"
    queue.saveonshutdown="on"
  )
}
EOF
      fi
    fi

    if [[ "${FORWARD_AUTH_LOGS}" == "true" ]]; then
      if [[ "${REMOTE_SYSLOG_PROTOCOL}" == "tcp" ]]; then
        cat <<EOF
if (\$syslogfacility-text == 'authpriv') then {
  action(
    type="omfwd"
    target="${REMOTE_SYSLOG_HOST}"
    port="${REMOTE_SYSLOG_PORT}"
    protocol="tcp"
    TCP_Framing="octet-counted"
    KeepAlive="on"
    action.resumeRetryCount="-1"
    queue.type="linkedList"
    queue.filename="fwd_authpriv"
    queue.maxdiskspace="256m"
    queue.saveonshutdown="on"
  )
}
EOF
      else
        cat <<EOF
if (\$syslogfacility-text == 'authpriv') then {
  action(
    type="omfwd"
    target="${REMOTE_SYSLOG_HOST}"
    port="${REMOTE_SYSLOG_PORT}"
    protocol="udp"
    action.resumeRetryCount="-1"
    queue.type="linkedList"
    queue.filename="fwd_authpriv"
    queue.maxdiskspace="256m"
    queue.saveonshutdown="on"
  )
}
EOF
      fi
    fi

    if [[ "${FORWARD_AUDIT_LOGS}" == "true" ]]; then
      if [[ "${REMOTE_SYSLOG_PROTOCOL}" == "tcp" ]]; then
        cat <<EOF
if (\$syslogfacility-text == 'local5') then {
  action(
    type="omfwd"
    target="${REMOTE_SYSLOG_HOST}"
    port="${REMOTE_SYSLOG_PORT}"
    protocol="tcp"
    TCP_Framing="octet-counted"
    KeepAlive="on"
    action.resumeRetryCount="-1"
    queue.type="linkedList"
    queue.filename="fwd_local5"
    queue.maxdiskspace="256m"
    queue.saveonshutdown="on"
  )
}
EOF
      else
        cat <<EOF
if (\$syslogfacility-text == 'local5') then {
  action(
    type="omfwd"
    target="${REMOTE_SYSLOG_HOST}"
    port="${REMOTE_SYSLOG_PORT}"
    protocol="udp"
    action.resumeRetryCount="-1"
    queue.type="linkedList"
    queue.filename="fwd_local5"
    queue.maxdiskspace="256m"
    queue.saveonshutdown="on"
  )
}
EOF
      fi
    fi
  } > /etc/rsyslog.d/49-remote-forward.conf
else
  : > /etc/rsyslog.d/49-remote-forward.conf
fi

# =========================================================
# 5. Logrotate
# =========================================================
info "Настройка logrotate..."

backup_file /etc/logrotate.d/commands-log
cat > /etc/logrotate.d/commands-log <<'EOF'
/var/log/commands.log {
  daily
  rotate 90
  compress
  delaycompress
  missingok
  notifempty
  create 0640 syslog adm
  postrotate
    systemctl reload rsyslog >/dev/null 2>&1 || true
  endscript
}
EOF

# =========================================================
# 6. Проверка конфигов
# =========================================================
info "Проверка rsyslog-конфига..."
rsyslogd -N1

# =========================================================
# 7. Применение настроек
# =========================================================
info "Включение и перезапуск служб..."
systemctl enable auditd rsyslog
systemctl restart rsyslog

info "Загрузка audit rules..."
augenrules --load || true
systemctl restart auditd

# Подгрузим профиль сразу в текущую root-сессию скрипта
info "Активация bash-профиля..."
# shellcheck disable=SC1091
source /etc/profile.d/history-log.sh || true

# Тестовая запись
logger -p local6.debug -- "setup completed"
sleep 1

# =========================================================
# 8. Финальная сводка
# =========================================================
echo
echo "========================================================="
echo "✅ УСТАНОВКА ЗАВЕРШЕНА"
echo "========================================================="
echo
echo "Что настроено:"
echo "  - auditd аудит запуска команд root и обычных пользователей"
echo "  - bash history logging -> /var/log/commands.log"
echo "  - логируются: user / ip / tty / host / pid / rc / cmd"
echo "  - настроен logrotate"
echo "  - root автоматически подхватывает профиль через /root/.bashrc"
echo

echo "-------------------"
echo "ПЕРЕЗАПУСК СЛУЖБ"
echo "-------------------"
echo "systemctl restart auditd"
echo "systemctl restart rsyslog"
echo

echo "-------------------"
echo "ПРИМЕНИТЬ ПРОФИЛЬ"
echo "-------------------"
echo "source /etc/profile.d/history-log.sh"
echo "source /root/.bashrc"
echo "exec bash -l"
echo

echo "-------------------"
echo "ЧТО СМОТРЕТЬ"
echo "-------------------"
echo "tail -f /var/log/commands.log"
echo "tail -n 50 /var/log/commands.log"
echo "ausearch -k root-commands -i | tail -n 50"
echo "ausearch -k user-commands -i | tail -n 50"
echo "auditctl -l"
echo "journalctl -u rsyslog -n 50 --no-pager"
echo "journalctl -u auditd -n 50 --no-pager"
echo

echo "-------------------"
echo "ТЕСТ"
echo "-------------------"
echo "echo test_history_check"
echo "tail -n 5 /var/log/commands.log"
echo

echo "-------------------"
echo "ФАЙЛЫ"
echo "-------------------"
echo "/etc/profile.d/history-log.sh"
echo "/etc/rsyslog.d/10-commands.conf"
echo "/etc/rsyslog.d/49-remote-forward.conf"
echo "/etc/audit/rules.d/commands.rules"
echo "/etc/logrotate.d/commands-log"
echo "/var/log/commands.log"
echo

echo "-------------------"
echo "ПРОВЕРКА ПРЯМО СЕЙЧАС"
echo "-------------------"
echo "Последние строки /var/log/commands.log:"
tail -n 5 /var/log/commands.log || true
echo
echo "Активные audit rules:"
auditctl -l || true
echo

info "Готово."
