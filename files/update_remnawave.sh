#!/usr/bin/env bash
# update_remnawave.sh — безопасное обновление панели Remnawave
# https://github.com/r00t-man/MZT
#
# Использование:
#   bash update_remnawave.sh          — обновить панель
#   bash update_remnawave.sh --nodes  — обновить панель + все ноды

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REMNAWAVE_DIR="${REMNAWAVE_DIR:-/opt/remnawave}"
BACKUP_DIR="${BACKUP_DIR:-/srv/backup_opt}"
NGINX_CONTAINER="${NGINX_CONTAINER:-remnawave-nginx}"
PANEL_URL="${PANEL_URL:-https://panel.example.com/api}"
UPDATE_NODES="${1:-}"

log()  { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

# ── Проверка зависимостей ────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || err "docker не найден"
[[ -d "$REMNAWAVE_DIR" ]] || err "Директория $REMNAWAVE_DIR не найдена. Установи REMNAWAVE_DIR."

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        Remnawave Update Script               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Бэкап ────────────────────────────────────────────────────────────────
DATE=$(date +%F-%H%M%S)
mkdir -p "$BACKUP_DIR"

log "Шаг 1/5 — Бэкап конфигурации..."
cp "$REMNAWAVE_DIR/.env" "$BACKUP_DIR/remnawave_env_$DATE" 2>/dev/null \
  && ok ".env сохранён: $BACKUP_DIR/remnawave_env_$DATE" \
  || warn ".env не найден, пропускаем бэкап конфига"

log "Создание дампа БД..."
if docker exec remnawave-db pg_dump -U postgres postgres \
    > "$BACKUP_DIR/remnawave_db_$DATE.sql" 2>/dev/null; then
  ok "Дамп БД: $BACKUP_DIR/remnawave_db_$DATE.sql"
else
  warn "Не удалось создать дамп БД — продолжаем без него"
fi

# ── 2. Обновление образов ────────────────────────────────────────────────────
log "Шаг 2/5 — Загрузка новых образов..."
cd "$REMNAWAVE_DIR"
docker compose pull
ok "Образы загружены"

# ── 3. Перезапуск панели ─────────────────────────────────────────────────────
log "Шаг 3/5 — Перезапуск контейнеров..."
docker compose up -d
ok "Контейнеры запущены"

# ── 4. Ожидание готовности ───────────────────────────────────────────────────
log "Шаг 4/5 — Ожидание старта приложения (20 сек)..."
sleep 5
for i in $(seq 1 15); do
  printf "."
  sleep 1
done
echo ""

# Проверяем что приложение запустилось
if docker logs remnawave --since 30s 2>&1 | grep -q "Nest application successfully started"; then
  ok "Remnawave запустился успешно"
else
  warn "Сообщение о старте не найдено в логах — проверь вручную"
fi

# ── 5. Перезапуск nginx (сброс DNS-кеша) ────────────────────────────────────
log "Шаг 5/5 — Перезапуск nginx (сброс кеша Docker IP)..."
docker restart "$NGINX_CONTAINER"
sleep 3
ok "Nginx перезапущен"

# ── Проверка ─────────────────────────────────────────────────────────────────
echo ""
log "Проверка статуса..."

HTTP_CODE=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" "$PANEL_URL" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "401" ]]; then
  ok "API отвечает (HTTP $HTTP_CODE) ✅"
else
  warn "API вернул HTTP $HTTP_CODE — проверь логи:"
  echo "  docker logs remnawave --tail=20"
  echo "  docker logs $NGINX_CONTAINER --tail=10"
fi

echo ""
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|remnawave"

# ── Обновление нод (опционально) ─────────────────────────────────────────────
if [[ "$UPDATE_NODES" == "--nodes" ]]; then
  echo ""
  echo -e "${CYAN}══ Обновление нод ══${NC}"

  if [[ ! -f ~/.ssh/config ]]; then
    warn "~/.ssh/config не найден — пропускаем обновление нод"
  else
    NODES=$(grep -E "^Host node-" ~/.ssh/config | awk '{print $2}' | grep -v "\*" | sort -u)

    if [[ -z "$NODES" ]]; then
      warn "Ноды не найдены в ~/.ssh/config (ищем 'Host node-*')"
    else
      for NODE in $NODES; do
        log "Обновляю $NODE..."
        if ssh -o ConnectTimeout=8 -o BatchMode=yes "$NODE" \
          "cd /opt/remnanode 2>/dev/null || cd \$(find /opt -name 'docker-compose.yml' -path '*/remnanode/*' -exec dirname {} \; 2>/dev/null | head -1) && docker compose pull -q && docker compose up -d -q" \
          2>/dev/null; then
          ok "$NODE — обновлён"
        else
          warn "$NODE — недоступен или remnanode не найден"
        fi
      done
    fi
  fi
fi

# ── Итог ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Обновление завершено ✅            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "  Бэкап БД:    $BACKUP_DIR/remnawave_db_$DATE.sql"
echo "  Бэкап .env:  $BACKUP_DIR/remnawave_env_$DATE"
echo ""
echo "  Если что-то пошло не так:"
echo "  → docker logs remnawave --tail=30"
echo "  → docker logs $NGINX_CONTAINER --tail=10"
echo "  → docker restart $NGINX_CONTAINER  (если 502 Bad Gateway)"
echo ""
