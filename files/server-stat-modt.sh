#!/bin/bash

set -e

echo "Создание файла /etc/update-motd.d/99-server-stats..."
if [ ! -f /etc/update-motd.d/99-server-stats ]; then
    sudo touch /etc/update-motd.d/99-server-stats
    sudo chmod +x /etc/update-motd.d/99-server-stats
fi

echo "Проверка зависимостей..."
if ! command -v curl >/dev/null 2>&1; then
    echo "curl не найден, устанавливаю..."
    sudo apt-get update
    sudo apt-get install -y curl
fi

echo "Отключение лишних MOTD блоков..."
sudo chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/60-unminimize 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/85-fwupd 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/90-updates-available 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/91-contract-ua-esm-status 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/91-release-upgrade 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/92-unattended-upgrades 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/95-hwe-eol 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/97-overlayroot 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/98-fsck-at-reboot 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/98-reboot-required 2>/dev/null || true
sudo rm -f /etc/update-motd.d/50-landscape-sysinfo

echo "Отключение ненужных systemd юнитов..."
sudo systemctl disable --now motd-news.service 2>/dev/null || true
sudo systemctl mask motd-news.service 2>/dev/null || true
sudo systemctl reset-failed motd-news.service 2>/dev/null || true

echo "Сброс статуса failed юнитов..."
sudo systemctl reset-failed 2>/dev/null || true

echo "Отключение ненужных таймеров apt..."
sudo systemctl stop apt-daily.timer 2>/dev/null || true
sudo systemctl stop apt-daily-upgrade.timer 2>/dev/null || true
sudo systemctl disable apt-daily.timer 2>/dev/null || true
sudo systemctl disable apt-daily-upgrade.timer 2>/dev/null || true

echo "Настройка MOTD..."

FILE="/etc/update-motd.d/99-server-stats"

sudo tee "$FILE" > /dev/null <<'EOF'
#!/bin/sh

RESET="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"

RED="$(printf '\033[1;31m')"
GREEN="$(printf '\033[1;32m')"
YELLOW="$(printf '\033[1;33m')"
BLUE="$(printf '\033[1;34m')"
MAGENTA="$(printf '\033[1;35m')"
PURPLE="$(printf '\033[1;35m')"
CYAN="$(printf '\033[1;36m')"
WHITE="$(printf '\033[1;37m')"
ORANGE="$(printf '\033[38;5;214m')"
GRAY="$(printf '\033[38;5;245m')"

LABEL_W=18
VALUE_W=30
BAR_W=22

color_by_pct() {
  pct="$1"
  if [ "$pct" -lt 50 ]; then
    printf "%s" "$GREEN"
  elif [ "$pct" -lt 70 ]; then
    printf "%s" "$YELLOW"
  elif [ "$pct" -lt 85 ]; then
    printf "%s" "$ORANGE"
  else
    printf "%s" "$RED"
  fi
}

safe_int() {
  v="$1"
  printf '%s' "$v" | awk '{printf("%d",$1)}'
}

bar_pct() {
  pct="$1"
  width="${2:-22}"

  [ -z "$pct" ] && pct=0
  [ "$pct" -lt 0 ] 2>/dev/null && pct=0
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100

  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))
  color="$(color_by_pct "$pct")"

  i=0
  printf "%s" "$color"
  while [ "$i" -lt "$filled" ]; do
    printf "█"
    i=$((i + 1))
  done

  printf "%s" "$GRAY"
  i=0
  while [ "$i" -lt "$empty" ]; do
    printf "░"
    i=$((i + 1))
  done

  printf "%s" "$RESET"
}

print_metric_plain() {
  color="$1"
  label="$2"
  value="$3"
  printf "%s%-*s%s %-*s\n" "$color" "$LABEL_W" "$label" "$RESET" "$VALUE_W" "$value"
}

print_metric_color_value() {
  label_color="$1"
  value_color="$2"
  label="$3"
  value="$4"
  printf "%s%-*s%s %s%-*s%s\n" "$label_color" "$LABEL_W" "$label" "$RESET" "$value_color" "$VALUE_W" "$value" "$RESET"
}

print_metric_bar() {
  color="$1"
  label="$2"
  value="$3"
  pct="$4"
  suffix="$5"

  printf "%s%-*s%s %-*s " "$color" "$LABEL_W" "$label" "$RESET" "$VALUE_W" "$value"
  bar_pct "$pct" "$BAR_W"
  printf "  %s(%s)%s\n" "$(color_by_pct "$pct")" "$suffix" "$RESET"
}

UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //')"
[ -z "$UPTIME" ] && UPTIME="$(uptime | sed 's/.*up \([^,]*\), .*/\1/')"

BOOT_TIME="$(uptime -s 2>/dev/null)"
[ -z "$BOOT_TIME" ] && BOOT_TIME="$(who -b 2>/dev/null | awk '{print $3" "$4}')"
[ -z "$BOOT_TIME" ] && BOOT_TIME="unknown"

if [ -f /var/run/reboot-required ]; then
  REBOOT_REQUIRED="yes"
  REBOOT_COLOR="$RED"
else
  REBOOT_REQUIRED="no"
  REBOOT_COLOR="$GREEN"
fi

CPU_CORES="$(nproc 2>/dev/null)"
[ -z "$CPU_CORES" ] && CPU_CORES=1

LOAD1="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"
LOAD5="$(awk '{print $2}' /proc/loadavg 2>/dev/null)"
LOAD15="$(awk '{print $3}' /proc/loadavg 2>/dev/null)"

LOAD1_PCT="$(awk -v l="$LOAD1" -v c="$CPU_CORES" 'BEGIN { p=(l/c)*100; if (p<0) p=0; if (p>100) p=100; printf "%d", p }')"
LOAD5_PCT="$(awk -v l="$LOAD5" -v c="$CPU_CORES" 'BEGIN { p=(l/c)*100; if (p<0) p=0; if (p>100) p=100; printf "%d", p }')"
LOAD15_PCT="$(awk -v l="$LOAD15" -v c="$CPU_CORES" 'BEGIN { p=(l/c)*100; if (p<0) p=0; if (p>100) p=100; printf "%d", p }')"

MEM_LINE="$(free -m | awk '/^Mem:/ {print $2" "$3" "$7}')"
MEM_TOTAL_MB="$(printf '%s\n' "$MEM_LINE" | awk '{print $1}')"
MEM_USED_MB="$(printf '%s\n' "$MEM_LINE" | awk '{print $2}')"
MEM_AVAIL_MB="$(printf '%s\n' "$MEM_LINE" | awk '{print $3}')"

MEM_PCT="$(awk -v u="$MEM_USED_MB" -v t="$MEM_TOTAL_MB" 'BEGIN { if (t==0) print 0; else printf "%d", (u/t)*100 }')"
MEM_USED_H="$(free -h | awk '/^Mem:/ {print $3}')"
MEM_TOTAL_H="$(free -h | awk '/^Mem:/ {print $2}')"
MEM_AVAIL_H="$(free -h | awk '/^Mem:/ {print $7}')"

DISK_TOTAL_H="$(df -h / | awk 'NR==2 {print $2}')"
DISK_FREE_H="$(df -h / | awk 'NR==2 {print $4}')"
DISK_USED_PCT_RAW="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"
DISK_USED_PCT="$(safe_int "$DISK_USED_PCT_RAW")"

DEFAULT_IFACE="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
[ -z "$DEFAULT_IFACE" ] && DEFAULT_IFACE="unknown"

DEFAULT_GW="$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')"
[ -z "$DEFAULT_GW" ] && DEFAULT_GW="unknown"

IPV4_LOCAL="$(ip -4 -o addr show dev "$DEFAULT_IFACE" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)"
[ -z "$IPV4_LOCAL" ] && IPV4_LOCAL="not assigned"

IPV6="$(ip -6 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | awk '!/^fe80/' | paste -sd ', ' -)"
[ -z "$IPV6" ] && IPV6="not assigned"

PUBLIC_IP="$(
  timeout 2 curl -4 -fsS ifconfig.me 2>/dev/null || \
  timeout 2 curl -4 -fsS api.ipify.org 2>/dev/null || \
  timeout 2 curl -4 -fsS icanhazip.com 2>/dev/null
)"
PUBLIC_IP="$(printf '%s' "$PUBLIC_IP" | tr -d '\r\n[:space:]')"
[ -z "$PUBLIC_IP" ] && PUBLIC_IP="unavailable"

IPV4_WITH_GW="$IPV4_LOCAL (gw $DEFAULT_GW)"

DNS_SERVERS="$(awk '/^nameserver / {print $2}' /etc/resolv.conf 2>/dev/null | paste -sd ', ' -)"
[ -z "$DNS_SERVERS" ] && DNS_SERVERS="not found"

UPSTREAM_DNS="$(resolvectl dns "$DEFAULT_IFACE" 2>/dev/null | sed -n 's/^.*: //p' | xargs)"

if [ -z "$UPSTREAM_DNS" ]; then
  UPSTREAM_DNS="$(resolvectl status 2>/dev/null | awk '
    /^Global$/ {in_global=1; next}
    in_global && /^[[:space:]]*Link / {exit}
    in_global && /DNS Servers:/ {
      sub(/.*DNS Servers:[[:space:]]*/, "", $0)
      print
      exit
    }' | xargs)"
fi

UPSTREAM_DNS="$(printf '%s' "$UPSTREAM_DNS" | sed 's/[[:space:]]\+/, /g')"
[ -z "$UPSTREAM_DNS" ] && UPSTREAM_DNS="not found"

if command -v systemctl >/dev/null 2>&1; then
  FAILED_UNITS="$(systemctl --failed --no-legend --no-pager 2>/dev/null | grep -c '\.service\|\.mount\|\.timer\|\.socket\|\.target\|\.scope\|\.slice' 2>/dev/null)"
  [ -z "$FAILED_UNITS" ] && FAILED_UNITS=0
else
  FAILED_UNITS=0
fi

if [ "$FAILED_UNITS" -eq 0 ] 2>/dev/null; then
  FAILED_COLOR="$GREEN"
  FAILED_HINT="ok"
  FAILED_LOGS=""
else
  FAILED_COLOR="$RED"
  FAILED_HINT="systemctl --failed --no-pager"
  FAILED_LOGS="journalctl -p 3 -xb --no-pager"
fi

DOCKER_INSTALLED=0
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    DOCKER_INSTALLED=1
  fi
fi

if [ "$DOCKER_INSTALLED" -eq 1 ]; then
  DOCKER_TOTAL="$(docker ps -aq 2>/dev/null | wc -l | awk '{print $1}')"
  DOCKER_RUNNING="$(docker ps -q 2>/dev/null | wc -l | awk '{print $1}')"
  DOCKER_EXITED="$(docker ps -aq -f status=exited 2>/dev/null | wc -l | awk '{print $1}')"
  DOCKER_RESTARTING="$(docker ps -aq -f status=restarting 2>/dev/null | wc -l | awk '{print $1}')"

  DOCKER_SIZE="$(docker system df --format '{{.Size}}' 2>/dev/null | awk '
    BEGIN{sum=0}
    {
      gsub(/,/,".",$0)
      if ($0 ~ /GB$/) {sub(/GB$/,"",$0); sum+=($0*1024)}
      else if ($0 ~ /MB$/) {sub(/MB$/,"",$0); sum+=$0}
      else if ($0 ~ /kB$/) {sub(/kB$/,"",$0); sum+=($0/1024)}
      else if ($0 ~ /B$/) {sub(/B$/,"",$0); sum+=($0/1024/1024)}
    }
    END{
      if (sum >= 1024) printf "%.1fG", sum/1024;
      else printf "%.0fM", sum;
    }')"
  [ -z "$DOCKER_SIZE" ] && DOCKER_SIZE="unknown"

  DOCKER_BRIDGES="$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(docker0|br-)' | wc -l | awk '{print $1}')"
  DOCKER_VETH="$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -c '^veth')"

  DOCKER_CONTAINERS_VAL="$DOCKER_TOTAL total / $DOCKER_RUNNING running / $DOCKER_EXITED exited"

  if [ "$DOCKER_RESTARTING" -eq 0 ] 2>/dev/null; then
    DOCKER_RESTART_COLOR="$GREEN"
  else
    DOCKER_RESTART_COLOR="$RED"
  fi
else
  DOCKER_TOTAL="n/a"
  DOCKER_RUNNING="n/a"
  DOCKER_EXITED="n/a"
  DOCKER_RESTARTING="n/a"
  DOCKER_SIZE="n/a"
  DOCKER_BRIDGES="n/a"
  DOCKER_VETH="n/a"
  DOCKER_CONTAINERS_VAL="docker unavailable"
  DOCKER_RESTART_COLOR="$GRAY"
fi

LOAD1_VAL="$LOAD1 ($LOAD1_PCT%)"
LOAD5_VAL="$LOAD5 ($LOAD5_PCT%)"
LOAD15_VAL="$LOAD15 ($LOAD15_PCT%)"
RAM_VAL="$MEM_USED_H / $MEM_TOTAL_H used"
DISK_VAL="$DISK_FREE_H free / $DISK_TOTAL_H total"
DOCKER_LINKS_VAL="$DOCKER_BRIDGES bridge / $DOCKER_VETH veth"

printf "\n"
printf "%s%sServer Metrics%s\n" "$BOLD" "$CYAN" "$RESET"
printf "%s────────────────────────────────────────────────────────────────────%s\n" "$GRAY" "$RESET"

print_metric_plain "$BLUE"    "Uptime:"          "$UPTIME"
print_metric_plain "$BLUE"    "Boot time:"       "$BOOT_TIME"
print_metric_color_value "$BLUE" "$REBOOT_COLOR" "Reboot required:" "$REBOOT_REQUIRED"
print_metric_color_value "$BLUE" "$FAILED_COLOR" "Failed units:" "$FAILED_UNITS"
print_metric_color_value "$BLUE" "$FAILED_COLOR" "Failed check:" "$FAILED_HINT"
if [ "$FAILED_UNITS" -ne 0 ] 2>/dev/null; then
  print_metric_color_value "$BLUE" "$FAILED_COLOR" "Failed logs:" "$FAILED_LOGS"
fi
print_metric_plain "$BLUE"    "CPU cores:"       "$CPU_CORES"

print_metric_bar   "$BLUE"    "Load 1m:"         "$LOAD1_VAL"     "$LOAD1_PCT"     "$LOAD1_PCT%"
print_metric_bar   "$BLUE"    "Load 5m:"         "$LOAD5_VAL"     "$LOAD5_PCT"     "$LOAD5_PCT%"
print_metric_bar   "$BLUE"    "Load 15m:"        "$LOAD15_VAL"    "$LOAD15_PCT"    "$LOAD15_PCT%"
print_metric_bar   "$MAGENTA" "RAM:"             "$RAM_VAL"       "$MEM_PCT"       "$MEM_PCT%, avail $MEM_AVAIL_H"
print_metric_bar   "$YELLOW"  "Disk /:"          "$DISK_VAL"      "$DISK_USED_PCT" "$DISK_USED_PCT% used"

print_metric_plain "$GREEN"   "Iface:"           "$DEFAULT_IFACE"
print_metric_plain "$GREEN"   "IPv4:"            "$IPV4_WITH_GW"
print_metric_plain "$GREEN"   "Public IPv4:"     "$PUBLIC_IP"
print_metric_plain "$PURPLE"  "IPv6:"            "$IPV6"
print_metric_plain "$CYAN"    "Local DNS:"       "$DNS_SERVERS"
print_metric_plain "$CYAN"    "Upstream DNS:"    "$UPSTREAM_DNS"

print_metric_plain "$YELLOW"  "Docker links:"    "$DOCKER_LINKS_VAL"
print_metric_plain "$YELLOW"  "Containers:"      "$DOCKER_CONTAINERS_VAL"
print_metric_plain "$YELLOW"  "Docker size:"     "$DOCKER_SIZE"
print_metric_color_value "$YELLOW" "$DOCKER_RESTART_COLOR" "Restarting ct:" "$DOCKER_RESTARTING"

printf "\n"
EOF

sudo chmod +x /etc/update-motd.d/99-server-stats

echo "Проверка результата..."
run-parts /etc/update-motd.d/

echo "Все настройки завершены!"
echo "Откройте новую сессию в терминале"
