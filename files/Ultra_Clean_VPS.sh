#!/usr/bin/env bash
# Ultra Clean VPS v2 — безопасная глубокая очистка Ubuntu 24.04
# Оптимизирован для production серверов с Docker (remnanode и др.)
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
# Создаём persistent config — vacuum сбрасывается после перезагрузки
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
log "4. Большие архивные логи (>100MB)"
# ──────────────────────────────────────────────────────────────
# Удаляем только ротированные копии (.log.1, .log.2.gz и т.д.)
# Текущие .log файлы не трогаем
echo "  Ищем большие архивные логи..."
find /var/log -maxdepth 3 \( -name "*.log.[0-9]*" -o -name "*.gz" \) \
     -size +100M 2>/dev/null | while read -r f; do
  SIZE=$(du -h "$f" 2>/dev/null | cut -f1)
  rm -f "$f"
  ok "Удалён $f ($SIZE)"
done
ok "Проверка архивных логов завершена"

# ──────────────────────────────────────────────────────────────
log "5. Nginx: настройка логротации (защита от разрастания)"
# ──────────────────────────────────────────────────────────────
if [ -f /etc/logrotate.d/nginx ]; then
  cat > /etc/logrotate.d/nginx << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 3
    compress
    delaycompress
    notifempty
    size 200M
    create 0640 www-data adm
    sharedscripts
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi \
    endscript
    postrotate
        invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
EOF
  ok "nginx logrotate: 3 дня, ротация при 200MB (было 14 дней)"
else
  skip "nginx не установлен"
fi

# ──────────────────────────────────────────────────────────────
log "6. Docker: безопасная очистка"
# ──────────────────────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
  echo "  Состояние до очистки:"
  docker system df 2>/dev/null || true
  echo ""

  # ВАЖНО: без флага -a
  # docker system prune -a удаляет ВСЕ неиспользуемые образы — опасно на prod
  # docker system prune (без -a) удаляет только dangling images, stopped containers,
  # unused networks, build cache — образы активных контейнеров остаются
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
log "7. Docker: постоянные лимиты логов"
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
else
  skip "Docker не установлен"
fi

# ──────────────────────────────────────────────────────────────
log "8. Документация и man-страницы"
# ──────────────────────────────────────────────────────────────
rm -rf /usr/share/doc/* /usr/share/man/*
ok "Документация удалена (~100-300MB)"

# ──────────────────────────────────────────────────────────────
log "9. Snap (Ubuntu VPS)"
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
log "10. Локали (оставляем en_US + ru_RU)"
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
log "11. Firmware (только для VPS, не для bare-metal!)"
# ──────────────────────────────────────────────────────────────
if dpkg -l 2>/dev/null | grep -q '^ii\s\+linux-firmware\s'; then
  apt-get purge -y linux-firmware || true
  apt-get autoremove --purge -y
  ok "linux-firmware удалён (~300-600MB)"
else
  skip "linux-firmware не установлен"
fi

# ──────────────────────────────────────────────────────────────
log "12. Старые ядра (оставляем текущее + последнее)"
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
log "13. Временные файлы"
# ──────────────────────────────────────────────────────────────
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
ok "Временные файлы удалены"

# ──────────────────────────────────────────────────────────────
log "ФИНАЛЬНЫЙ ОТЧЁТ"
# ──────────────────────────────────────────────────────────────
echo ""
echo "Диск:"
df -h /
echo ""
echo "Топ-15 директорий:"
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
