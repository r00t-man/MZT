#!/usr/bin/env bash
# Ultra Clean VPS v3 — безопасная глубокая очистка Ubuntu 24.04
# Оптимизирован для production серверов с Docker и nginx (remnanode и др.)
# https://github.com/r00t-man/MZT

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────
log()  { echo ""; echo "══════════════════════════════"; echo "  $*"; echo "══════════════════════════════"; }
ok()   { echo "  ✔ $*"; }
skip() { echo "  — skip: $*"; }

if [ "$(id -u)" -ne 0 ]; then
  echo "Запусти от root: sudo bash $0"
  exit 1
fi

DISK_BEFORE=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (avail: " $4 ")"}')
echo ""
echo "══════════════════════════════"
echo "  Ultra Clean VPS v3"
echo "  Диск ДО: $DISK_BEFORE"
echo "══════════════════════════════"

# ──────────────────────────────────────────────────────────────
log "1. APT: очистка кешей"
# ──────────────────────────────────────────────────────────────
apt-get clean -y
apt-get autoclean -y
apt-get autoremove --purge -y
dpkg -l | awk '/^rc/ {print $2}' | xargs -r apt-get purge -y
ok "APT кеш очищен"

# ──────────────────────────────────────────────────────────────
log "2. Journald: постоянные лимиты + очистка"
# ──────────────────────────────────────────────────────────────
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/limits.conf << 'EOF'
[Journal]
SystemMaxUse=100M
SystemKeepFree=500M
MaxRetentionSec=7day
EOF
systemctl restart systemd-journald || true
journalctl --vacuum-time=7d   || true
journalctl --vacuum-size=100M || true
ok "Journal: лимит 100MB, хранение 7 дней (настройка постоянная)"

# ──────────────────────────────────────────────────────────────
log "3. APT lists: пересборка индексов"
# ──────────────────────────────────────────────────────────────
rm -rf /var/lib/apt/lists/*
apt-get update -qq
ok "APT индексы пересобраны"

# ──────────────────────────────────────────────────────────────
log "4. Архивные логи /var/log (*.gz, *.log.N >50MB)"
# ──────────────────────────────────────────────────────────────
echo "  Ищем большие архивные логи (>50MB)..."
find /var/log -maxdepth 3 \( -name "*.log.[0-9]*" -o -name "*.gz" \) \
     -size +50M 2>/dev/null | while read -r f; do
  SIZE=$(du -h "$f" 2>/dev/null | cut -f1)
  rm -f "$f"
  ok "Удалён $f ($SIZE)"
done
ok "Проверка архивных логов завершена"

# ──────────────────────────────────────────────────────────────
log "5. Nginx: немедленная очистка накопившихся логов"
# ──────────────────────────────────────────────────────────────
if [ -d /var/log/nginx ]; then
  NGINX_BEFORE=$(du -sh /var/log/nginx/ 2>/dev/null | cut -f1)
  echo "  До: $NGINX_BEFORE"

  # ротированные сжатые — удаляем все
  find /var/log/nginx -type f -name "*.gz" -delete 2>/dev/null || true

  # *.log.2, *.log.3, ... — удаляем
  find /var/log/nginx -type f -regextype posix-extended \
      -regex ".+\.log\.[2-9][0-9]*$" -delete 2>/dev/null || true

  # *.log.1 крупнее 100M — вчерашний лог, уже ротирован, не нужен
  find /var/log/nginx -type f -name "*.log.1" -size +100M -delete 2>/dev/null || true

  NGINX_AFTER=$(du -sh /var/log/nginx/ 2>/dev/null | cut -f1)
  echo "  После: $NGINX_AFTER"
  echo "  Остаток:"
  ls -lh /var/log/nginx/ 2>/dev/null | awk 'NR>1 {printf "    %-10s %s\n", $5, $9}'
  ok "Nginx логи очищены"
else
  skip "Нет /var/log/nginx"
fi

# ──────────────────────────────────────────────────────────────
log "6. Nginx: настройка логротации (защита от разрастания)"
# ──────────────────────────────────────────────────────────────
if [ -f /etc/logrotate.d/nginx ]; then
  cat > /etc/logrotate.d/nginx << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 2
    compress
    delaycompress
    notifempty
    size 100M
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -s /run/nginx.pid ] && kill -USR1 $(cat /run/nginx.pid) 2>/dev/null || true
    endscript
}
EOF
  ok "nginx logrotate: 2 ротации, ротация при 100MB или раз в сутки"
else
  skip "nginx не установлен (/etc/logrotate.d/nginx отсутствует)"
fi

# ──────────────────────────────────────────────────────────────
log "7. Docker: безопасная очистка"
# ──────────────────────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
  echo "  Состояние до очистки:"
  docker system df 2>/dev/null || true
  echo ""

  # без -a: удаляем dangling images, stopped containers, unused networks, build cache
  # образы запущенных контейнеров НЕ трогаем
  docker system prune -f
  docker image prune -f || true

  echo ""
  echo "  Состояние после очистки:"
  docker system df 2>/dev/null || true
  ok "Docker очищен (образы запущенных контейнеров сохранены)"
else
  skip "Docker не установлен"
fi

# ──────────────────────────────────────────────────────────────
log "8. Docker: постоянные лимиты логов + усечение раздувшихся"
# ──────────────────────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
  mkdir -p /etc/docker
  if [ ! -f /etc/docker/daemon.json ] || ! grep -q "max-size" /etc/docker/daemon.json 2>/dev/null; then
    cat > /etc/docker/daemon.json << 'JSON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
JSON
    systemctl restart docker || true
    ok "Docker логи ограничены: 10MB × 3 файла на контейнер"
  else
    skip "Docker log limits уже настроены в daemon.json"
  fi

  # Усечь уже раздувшиеся json-логи существующих контейнеров (>100MB)
  echo "  Проверяем логи запущенных контейнеров..."
  find /var/lib/docker/containers/ -name "*-json.log" -size +100M 2>/dev/null \
    | while read -r logfile; do
        SIZE=$(du -h "$logfile" 2>/dev/null | cut -f1)
        : > "$logfile"
        ok "Усечён лог контейнера: $(basename "$(dirname "$logfile")") ($SIZE → 0)"
      done
else
  skip "Docker не установлен"
fi

# ──────────────────────────────────────────────────────────────
log "9. Документация и man-страницы"
# ──────────────────────────────────────────────────────────────
rm -rf /usr/share/doc/* /usr/share/man/*
ok "Документация удалена (~100-300MB)"

# ──────────────────────────────────────────────────────────────
log "10. Snap (Ubuntu VPS)"
# ──────────────────────────────────────────────────────────────
if dpkg -l 2>/dev/null | grep -q '^ii\s\+snapd\s'; then
  systemctl stop snapd.socket snapd.service 2>/dev/null || true
  systemctl disable snapd.socket snapd.service 2>/dev/null || true
  apt-get purge -y snapd
  rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd
  apt-get autoremove --purge -y
  ok "Snap полностью удалён (~200-400MB)"
else
  skip "Snap не установлен"
fi

# ──────────────────────────────────────────────────────────────
log "11. Локали (оставляем en_US + ru_RU)"
# ──────────────────────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
if ! command -v localepurge >/dev/null 2>&1; then
  apt-get install -y localepurge -qq
fi
cat > /etc/locale.nopurge << 'EOF'
NEEDSCONFIGFIRST="no"
en_US.UTF-8
en_GB.UTF-8
ru_RU.UTF-8
EOF
localepurge || true
ok "Локали: оставлены en_US, en_GB, ru_RU (~200-500MB)"

# ──────────────────────────────────────────────────────────────
log "12. Firmware (только для VPS, не для bare-metal!)"
# ──────────────────────────────────────────────────────────────
if dpkg -l 2>/dev/null | grep -q '^ii\s\+linux-firmware\s'; then
  apt-get purge -y linux-firmware || true
  apt-get autoremove --purge -y
  ok "linux-firmware удалён (~300-600MB)"
else
  skip "linux-firmware не установлен"
fi

# ──────────────────────────────────────────────────────────────
log "13. Старые ядра (оставляем текущее + последнее)"
# ──────────────────────────────────────────────────────────────
CURRENT_KERNEL="$(uname -r)"
KERNEL_PKGS="$(dpkg -l 2>/dev/null | awk '/^ii  linux-image-[0-9]/ {print $2}')"

if [ -n "$KERNEL_PKGS" ]; then
  LATEST_PKG="$(echo "$KERNEL_PKGS" | sort -V | tail -n 1)"
  LATEST_VER="${LATEST_PKG#linux-image-}"

  for P in $KERNEL_PKGS; do
    VER="${P#linux-image-}"
    if [ "$VER" != "$CURRENT_KERNEL" ] && [ "$VER" != "$LATEST_VER" ]; then
      apt-get purge -y "$P" || true
      ok "Удалено старое ядро: $P"
    fi
  done
  dpkg -l 2>/dev/null | awk '/^rc  linux-image-/ {print $2}' | xargs -r apt-get purge -y || true
  apt-get autoremove --purge -y
fi
ok "Старые ядра очищены"

# ──────────────────────────────────────────────────────────────
log "14. Временные файлы"
# ──────────────────────────────────────────────────────────────
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
ok "Временные файлы удалены"

# ──────────────────────────────────────────────────────────────
log "ФИНАЛЬНЫЙ ОТЧЁТ"
# ──────────────────────────────────────────────────────────────
DISK_AFTER=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (avail: " $4 ")"}')

echo ""
echo "  Диск ДО:    $DISK_BEFORE"
echo "  Диск ПОСЛЕ: $DISK_AFTER"
echo ""
echo "Топ-15 директорий по размеру:"
du -xh --max-depth=2 / 2>/dev/null | sort -rh | head -15
echo ""
if command -v docker >/dev/null 2>&1; then
  echo "Docker:"
  docker system df 2>/dev/null || true
  echo ""
  echo "Запущенные контейнеры:"
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
fi
echo ""
echo "✅ ГОТОВО"
