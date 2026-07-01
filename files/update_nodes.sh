#!/usr/bin/env bash
# update_nodes.sh — обновление remnanode на всех нодах (параллельно)
# https://github.com/r00t-man/MZT
#
# Требования:
#   - ~/.ssh/config с алиасами «Host node-*»
#   - docker + docker compose на каждой ноде
#   - remnanode в одной из стандартных директорий:
#       /opt/remnanode | /root/remnanode | /home/remnanode
#
# Использование:
#   bash update_nodes.sh                       — все ноды из ~/.ssh/config
#   bash update_nodes.sh node-se node-nl       — конкретные ноды
#   EXCLUDE="node-de1" bash update_nodes.sh    — исключить ноду
#
# Переменные окружения:
#   EXCLUDE   — пробел-разделённый список нод для исключения
#   LOG_DIR   — куда писать логи (по умолчанию: ./logs)

set -uo pipefail

# ── Цвета ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# ── Параметры ─────────────────────────────────────────────────────────────────
LOG_DIR="${LOG_DIR:-./logs}"
EXCLUDE="${EXCLUDE:-}"
LOG="$LOG_DIR/update_nodes_$(date +%Y-%m-%d_%H-%M-%S).log"

# ── Логгеры ───────────────────────────────────────────────────────────────────
log()  { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "$LOG"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $*" | tee -a "$LOG"; }
warn() { echo -e "${YELLOW}[!]${NC}    $*" | tee -a "$LOG"; }
err()  { echo -e "${RED}[ERR]${NC}  $*" | tee -a "$LOG"; }

mkdir -p "$LOG_DIR"

# ── Собираем список нод ───────────────────────────────────────────────────────
if [ $# -gt 0 ]; then
    NODES=("$@")
else
    if [[ ! -f ~/.ssh/config ]]; then
        err "~/.ssh/config не найден. Укажи ноды явно: bash update_nodes.sh node-se node-nl"
        exit 1
    fi
    mapfile -t NODES < <(grep -E "^Host node-" ~/.ssh/config | awk '{print $2}' | grep -v '\*' | sort -u)
    if [[ ${#NODES[@]} -eq 0 ]]; then
        err "Ноды не найдены в ~/.ssh/config (ищем «Host node-*»)"
        exit 1
    fi
fi

# Применяем исключения
if [[ -n "$EXCLUDE" ]]; then
    FILTERED=()
    for N in "${NODES[@]}"; do
        skip=0
        for EX in $EXCLUDE; do [[ "$N" == "$EX" ]] && skip=1 && break; done
        [[ $skip -eq 0 ]] && FILTERED+=("$N")
    done
    NODES=("${FILTERED[@]}")
fi

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        Remnawave Node Update — параллельно       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
log "Нод для обновления: ${#NODES[@]}"
log "Список: ${NODES[*]}"
echo ""

# ── Функция обновления одной ноды ─────────────────────────────────────────────
update_node() {
    local NODE=$1
    local NODE_LOG="$LOG.$NODE"

    {
        echo "[$(date '+%H:%M:%S')] === $NODE: старт ==="

        # Проверка SSH-доступности
        if ! ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$NODE" "echo ok" &>/dev/null; then
            echo "[$(date '+%H:%M:%S')] === $NODE: НЕДОСТУПЕН ==="
            echo "FAIL"
            return 1
        fi

        # Текущий образ до обновления
        BEFORE=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$NODE" \
            "docker inspect remnanode --format '{{.Config.Image}}' 2>/dev/null || echo unknown" 2>/dev/null)
        echo "[$(date '+%H:%M:%S')] Текущий образ: $BEFORE"

        # Выполняем обновление на удалённой ноде
        ssh -o ConnectTimeout=60 -o StrictHostKeyChecking=no "$NODE" bash << 'REMOTE'
set -euo pipefail

# Ищем директорию с docker-compose.yml для remnanode
NODE_DIR=""
for DIR in /opt/remnanode /root/remnanode /home/remnanode; do
    [[ -f "$DIR/docker-compose.yml" ]] && NODE_DIR="$DIR" && break
done

if [[ -z "$NODE_DIR" ]]; then
    echo "ERROR: директория remnanode не найдена"
    echo "  Проверено: /opt/remnanode, /root/remnanode, /home/remnanode"
    exit 1
fi

echo "Директория: $NODE_DIR"
cd "$NODE_DIR"

echo "Загрузка нового образа..."
docker compose pull

echo "Перезапуск контейнера..."
docker compose up -d

echo "Проверка статуса..."
sleep 5
STATUS=$(docker inspect remnanode --format '{{.State.Status}}' 2>/dev/null || echo "unknown")
IMAGE=$(docker inspect remnanode --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")

echo "Статус: $STATUS | Образ: $IMAGE"

if [[ "$STATUS" != "running" ]]; then
    echo "ERROR: контейнер не запустился"
    echo "  Логи: docker logs remnanode --tail=20"
    exit 1
fi

echo "OK: обновлён → $IMAGE"
REMOTE

        RC=$?
        if [[ $RC -eq 0 ]]; then
            echo "[$(date '+%H:%M:%S')] === $NODE: УСПЕШНО ==="
            echo "OK"
        else
            echo "[$(date '+%H:%M:%S')] === $NODE: ОШИБКА (exit $RC) ==="
            echo "FAIL"
        fi
    } > "$NODE_LOG" 2>&1

    cat "$NODE_LOG" >> "$LOG"
    tail -1 "$NODE_LOG"
}

# ── Параллельный запуск ───────────────────────────────────────────────────────
declare -A PIDS

for NODE in "${NODES[@]}"; do
    log "Запускаю $NODE..."
    update_node "$NODE" &
    PIDS[$NODE]=$!
done

echo ""
log "Жду завершения..."

SUCCESS=()
FAILED=()

for NODE in "${NODES[@]}"; do
    wait "${PIDS[$NODE]}"
    RESULT=$(tail -1 "$LOG.$NODE" 2>/dev/null || echo "FAIL")

    if [[ "$RESULT" == "OK" ]]; then
        ok "$NODE — обновлена"
        SUCCESS+=("$NODE")
    else
        err "$NODE — ошибка"
        FAILED+=("$NODE")
    fi
done

# ── Итог ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ИТОГ                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
log "Успешно: ${#SUCCESS[@]} / ${#NODES[@]}"
[[ ${#SUCCESS[@]} -gt 0 ]] && log "  ✅ ${SUCCESS[*]}"
[[ ${#FAILED[@]} -gt 0 ]]  && log "  ❌ ${FAILED[*]} — проверь логи в $LOG_DIR/"
log "Полный лог: $LOG"
echo ""

# Если есть ошибки — выходим с кодом 1
[[ ${#FAILED[@]} -eq 0 ]]
