#!/usr/bin/env bash
#
# setup-wizard.sh — интерактивный помощник для заполнения CLAUDE.md и настройки SSH
#
# Что делает:
#   1. Сканирует ВСЕ Docker-контейнеры (включая остановленные) и дописывает черновик
#      секции "Контейнеры" в /opt/CLAUDE.md — дальше руками подчищаешь/уточняешь.
#   2. (Опционально, можно пропустить) Заводит SSH-доступ к твоим нодам/серверам:
#      просит IP/порт/логин, копирует туда SSH-ключ, проверяет вход по ключу и
#      только ПОСЛЕ успешной проверки закрывает на ноде вход по паролю/root+пароль.
#   3. (Опционально, можно пропустить) Настраивает вход НА ЭТОТ сервер по ключу с
#      твоего компьютера — тоже с проверкой перед отключением пароля.
#   4. (Опционально, можно пропустить) Спрашивает адрес Remnawave-панели и API-ключ:
#      ключ кладётся в отдельный файл с правами 600 (защищён guard.sh как *.key),
#      в CLAUDE.md пишется только адрес панели и путь к файлу — не сам ключ.
#   5. (Опционально, можно пропустить) Спрашивает Cloudflare Global API Key + email
#      аккаунта (для управления доменами/поддоменами/A-записями через API):
#      та же схема — секрет в отдельном файле с правами 600, в CLAUDE.md только
#      email аккаунта и путь к файлу — не сам ключ.
#
# Каждый опциональный шаг можно пропустить — тогда скрипт печатает те же команды
# руками, с объяснением что каждая делает и зачем.
#
# Безопасность: пароли никогда не сохраняются в переменных/файлах — их спрашивает
# сам ssh-copy-id/ssh в момент подключения. Вход по паролю НИКОГДА не отключается
# без предварительной успешной проверки входа по ключу.

set -uo pipefail

CLAUDE_MD="${CLAUDE_MD:-/opt/CLAUDE.md}"
NODES_KEY="${NODES_KEY:-$HOME/.ssh/id_ed25519_nodes}"
SSH_CONFIG="$HOME/.ssh/config"
PANEL_KEY_FILE="${PANEL_KEY_FILE:-/opt/.claude/remnawave_api.key}"
CF_KEY_FILE="${CF_KEY_FILE:-/opt/.claude/cloudflare_api.key}"

c_bold=$'\033[1m'; c_dim=$'\033[2m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_reset=$'\033[0m'
say()  { printf '%s\n' "$*"; }
head_() { printf '\n%s%s%s\n' "$c_bold" "$*" "$c_reset"; }
ok()   { printf '%s✅ %s%s\n' "$c_green" "$*" "$c_reset"; }
warn() { printf '%s⚠️  %s%s\n' "$c_yellow" "$*" "$c_reset"; }
err()  { printf '%s❌ %s%s\n' "$c_red" "$*" "$c_reset"; }

ask_yn() {
    # ask_yn "вопрос" -> возвращает 0 (да) или 1 (нет/пропуск)
    local prompt="$1" reply
    read -rp "$prompt [y/N/s=пропустить] " reply
    case "$reply" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
head_ "1/5 — Сканирую Docker-контейнеры (включая остановленные)"
# ═══════════════════════════════════════════════════════════════════════════

if ! command -v docker &>/dev/null; then
    warn "docker не найден в PATH — пропускаю автосканирование, впиши контейнеры в CLAUDE.md руками."
else
    containers="$(docker ps -a --format '| {{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}} |' 2>/dev/null)"
    if [ -z "$containers" ]; then
        warn "Ни одного контейнера не найдено (docker ps -a пуст)."
    else
        say "Найдено контейнеров: $(printf '%s\n' "$containers" | wc -l)"
        printf '%s\n' "$containers"

        block="$(cat <<EOF

## Контейнеры на сервере (автообнаружено $(date '+%Y-%m-%d %H:%M'), проверь и подчисти руками)

| Имя | Образ | Статус | Порты |
|-----|-------|--------|-------|
$containers

EOF
)"
        if [ -f "$CLAUDE_MD" ]; then
            if grep -q "^## Контейнеры на сервере" "$CLAUDE_MD" 2>/dev/null; then
                warn "В $CLAUDE_MD уже есть секция «Контейнеры на сервере» — не дублирую, допиши руками при необходимости."
            else
                printf '%s\n' "$block" >> "$CLAUDE_MD"
                ok "Секция с контейнерами дописана в $CLAUDE_MD"
            fi
        else
            warn "$CLAUDE_MD не найден — вот черновик секции, вставь его сам:"
            printf '%s\n' "$block"
        fi
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════
head_ "2/5 — SSH-доступ к твоим нодам/серверам (опционально)"
# ═══════════════════════════════════════════════════════════════════════════
say "Если этот сервер управляет другими серверами по SSH (нодами) — заведём туда"
say "ключевой доступ и закроем вход по паролю. Пароль вводится напрямую в ssh-copy-id/ssh,"
say "скрипт его нигде не сохраняет."
say ""

if ask_yn "Настроить SSH-ключи для нод сейчас?"; then
    if [ ! -f "$NODES_KEY" ]; then
        say "Генерирую отдельный ключ для нод: $NODES_KEY"
        ssh-keygen -t ed25519 -f "$NODES_KEY" -N "" -C "claude-agent-nodes" </dev/null
    else
        ok "Ключ $NODES_KEY уже существует, использую его."
    fi

    while true; do
        say ""
        read -rp "Алиас ноды (например node-de1, Enter чтобы закончить): " alias
        [ -z "$alias" ] && break
        read -rp "  IP или домен: " node_ip
        read -rp "  SSH порт [22]: " node_port; node_port="${node_port:-22}"
        read -rp "  Логин [root]: " node_user; node_user="${node_user:-root}"

        say "  Копирую публичный ключ на $node_user@$node_ip:$node_port (сейчас попросит пароль ноды)..."
        if ssh-copy-id -i "${NODES_KEY}.pub" -p "$node_port" -o StrictHostKeyChecking=accept-new "$node_user@$node_ip"; then
            ok "Ключ скопирован."
        else
            err "Не удалось скопировать ключ — проверь IP/порт/пароль. Нода пропущена."
            continue
        fi

        say "  Проверяю вход по ключу БЕЗ пароля..."
        if ssh -i "$NODES_KEY" -p "$node_port" -o BatchMode=yes -o ConnectTimeout=8 \
               -o StrictHostKeyChecking=accept-new "$node_user@$node_ip" 'echo OK' 2>/dev/null | grep -q OK; then
            ok "Вход по ключу работает."
        else
            err "Вход по ключу не подтвердился — НЕ отключаю пароль на этой ноде. Проверь вручную."
            continue
        fi

        if ask_yn "  Закрыть на ЭТОЙ ноде вход по паролю и root+пароль (только после успешной проверки ключа)?"; then
            say "  Правлю sshd_config на ноде (с бэкапом и проверкой синтаксиса перед reload)..."
            ssh -i "$NODES_KEY" -p "$node_port" "$node_user@$node_ip" '
                set -e
                cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
                sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
                sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
                if sshd -t; then
                    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || service ssh reload
                    echo "RELOAD_OK"
                else
                    echo "SSHD_TEST_FAILED — конфиг не тронут дальше, проверь руками"
                fi
            '
            ok "Пароль/root+пароль на $alias закрыты (вход теперь только по ключу)."
        else
            say "  Пароль на ноде оставлен как есть — можно закрыть позже той же командой."
        fi

        mkdir -p "$(dirname "$SSH_CONFIG")"
        if ! grep -q "^Host $alias\$" "$SSH_CONFIG" 2>/dev/null; then
            cat >> "$SSH_CONFIG" <<CFG

Host $alias
    HostName $node_ip
    Port $node_port
    User $node_user
    IdentityFile $NODES_KEY
    StrictHostKeyChecking accept-new
CFG
            ok "Добавлен алиас '$alias' в $SSH_CONFIG — теперь просто 'ssh $alias'."
        else
            warn "Алиас '$alias' уже есть в $SSH_CONFIG, не дублирую."
        fi
    done
else
    say ""
    say "${c_dim}Пропущено. Сделай то же самое руками, шаг за шагом:${c_reset}"
    cat <<'MANUAL'

  1) Сгенерируй отдельный ключ для нод (один на все, переиспользуется):
       ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_nodes -C "claude-agent-nodes"
     → создаст пару ключей; .pub можно свободно копировать куда угодно, приватный
       (без .pub) остаётся только здесь.

  2) Скопируй публичный ключ на ноду (введи пароль ноды, когда попросит):
       ssh-copy-id -i ~/.ssh/id_ed25519_nodes.pub -p <ПОРТ> <ЛОГИН>@<IP>
     → допишет ключ в ~/.ssh/authorized_keys на удалённом сервере.

  3) Проверь, что заходит по ключу БЕЗ пароля (обязательно ДО следующего шага!):
       ssh -i ~/.ssh/id_ed25519_nodes -p <ПОРТ> <ЛОГИН>@<IP> echo OK
     → если напечатало OK без запроса пароля — можно закрывать вход по паролю.

  4) На ноде закрой вход по паролю и root+пароль:
       sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
       sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
       sudo sshd -t && sudo systemctl reload ssh
     → `sshd -t` проверяет синтаксис ДО применения (не даст себя запереть битым
       конфигом); `reload`, не `restart` — не рвёт текущую SSH-сессию.

  5) Добавь алиас в ~/.ssh/config на этом сервере (агент сможет ходить по имени):
       cat >> ~/.ssh/config <<EOF
       Host <ALIAS>
           HostName <IP>
           Port <ПОРТ>
           User <ЛОГИН>
           IdentityFile ~/.ssh/id_ed25519_nodes
       EOF
     → дальше просто `ssh <ALIAS>`, без пароля и без явных портов/ключей.

MANUAL
fi

# ═══════════════════════════════════════════════════════════════════════════
head_ "3/5 — Вход НА ЭТОТ сервер по ключу с твоего компьютера (опционально)"
# ═══════════════════════════════════════════════════════════════════════════
say "Чтобы самому заходить на этот сервер (где живёт агент) по ключу, а не паролю."
say ""

if ask_yn "Настроить сейчас?"; then
    read -rp "Вставь СВОЙ публичный ключ (содержимое ~/.ssh/id_ed25519.pub с твоего компьютера), Enter — пропустить: " pubkey
    if [ -z "$pubkey" ]; then
        warn "Ключ не введён, пропускаю."
    else
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
        if grep -qF "$pubkey" ~/.ssh/authorized_keys 2>/dev/null; then
            warn "Такой ключ уже есть в authorized_keys."
        else
            printf '%s\n' "$pubkey" >> ~/.ssh/authorized_keys
            ok "Ключ добавлен в ~/.ssh/authorized_keys."
        fi
        warn "НЕ закрывай эту SSH-сессию! Открой НОВОЕ окно терминала со своего компьютера и проверь:"
        say "    ssh -o BatchMode=yes $(whoami)@$(hostname -I 2>/dev/null | awk '{print $1}') echo OK"
        say "Только после того, как это сработает БЕЗ запроса пароля — возвращайся сюда."
        if ask_yn "Вход по ключу с твоего ПК подтверждён? Закрыть вход по паролю НА ЭТОМ сервере?"; then
            cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
            sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            if sshd -t; then
                systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || service ssh reload
                ok "Вход по паролю на этом сервере закрыт."
            else
                err "sshd -t не прошёл — конфиг НЕ применён, проверь /etc/ssh/sshd_config руками."
            fi
        else
            say "Ок, пароль оставлен включённым — закроешь позже теми же командами."
        fi
    fi
else
    say ""
    say "${c_dim}Пропущено. Сделай то же самое руками на СВОЁМ компьютере и на сервере:${c_reset}"
    cat <<'MANUAL'

  1) На своём компьютере (если ключа ещё нет):
       ssh-keygen -t ed25519 -C "мой-ноутбук"
     → создаст ~/.ssh/id_ed25519 (приватный) и id_ed25519.pub (публичный).

  2) Скопируй ключ на сервер (введи пароль сервера, когда попросит):
       ssh-copy-id -p <ПОРТ_СЕРВЕРА> <ЛОГИН>@<IP_СЕРВЕРА>
     → допишет твой публичный ключ в ~/.ssh/authorized_keys на сервере.
     Если ssh-copy-id недоступен — вставь содержимое id_ed25519.pub вручную
     в конец ~/.ssh/authorized_keys на сервере (через уже открытую сессию).

  3) Проверь вход по ключу БЕЗ пароля (в НОВОМ окне терминала, старую сессию не закрывай):
       ssh -o BatchMode=yes <ЛОГИН>@<IP_СЕРВЕРА> echo OK
     → должно напечатать OK без запроса пароля.

  4) Только после успешной проверки — закрой вход по паролю НА СЕРВЕРЕ:
       sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
       sudo sshd -t && sudo systemctl reload ssh
     → если пропустишь шаг 3 и сразу отключишь пароль без рабочего ключа —
       рискуешь потерять доступ к серверу насовсем (если это VPS без консоли
       у хостера — восстановление может быть долгим/платным).

MANUAL
fi

# ═══════════════════════════════════════════════════════════════════════════
head_ "4/5 — Remnawave-панель: адрес и API-ключ (опционально)"
# ═══════════════════════════════════════════════════════════════════════════
say "Если агент должен ходить в API Remnawave-панели (сквады/ноды/юзеры) — сохраним"
say "адрес панели в $CLAUDE_MD, а сам API-ключ — в отдельный файл с правами 600,"
say "который guard.sh защищает так же, как остальные *.key (не даёт читать/выносить)."
say ""

if ask_yn "Настроить доступ к Remnawave-панели сейчас?"; then
    read -rp "Адрес панели (например https://panel.example.com): " panel_url
    read -rp "API-ключ панели (вставь значение, не будет отображаться в истории): " -s panel_key
    say ""

    if [ -z "$panel_url" ] || [ -z "$panel_key" ]; then
        warn "Адрес или ключ не введены, пропускаю."
    else
        mkdir -p "$(dirname "$PANEL_KEY_FILE")"
        printf '%s\n' "$panel_key" > "$PANEL_KEY_FILE"
        chmod 600 "$PANEL_KEY_FILE"
        ok "API-ключ сохранён в $PANEL_KEY_FILE (chmod 600)."

        block="$(cat <<EOF

## Remnawave-панель (автозаполнено $(date '+%Y-%m-%d %H:%M'))

- Адрес: $panel_url
- API-ключ: $PANEL_KEY_FILE (защищён guard.sh, агенту не читать/не выводить содержимое)

EOF
)"
        if [ -f "$CLAUDE_MD" ]; then
            if grep -q "^## Remnawave-панель" "$CLAUDE_MD" 2>/dev/null; then
                warn "В $CLAUDE_MD уже есть секция «Remnawave-панель» — не дублирую, поправь руками."
            else
                printf '%s\n' "$block" >> "$CLAUDE_MD"
                ok "Секция с адресом панели дописана в $CLAUDE_MD."
            fi
        else
            warn "$CLAUDE_MD не найден — вот черновик секции, вставь его сам:"
            printf '%s\n' "$block"
        fi
    fi
else
    say ""
    say "${c_dim}Пропущено. Сделай то же самое руками:${c_reset}"
    cat <<MANUAL

  1) Сохрани API-ключ панели в отдельный файл с правами 600 (не в CLAUDE.md!):
       mkdir -p $(dirname "$PANEL_KEY_FILE")
       echo '<API_КЛЮЧ>' > $PANEL_KEY_FILE
       chmod 600 $PANEL_KEY_FILE
     → имя файла оканчивается на .key — guard.sh уже блокирует чтение/вынос
       таких файлов тем же правилом, что и остальные секреты.

  2) В $CLAUDE_MD впиши только адрес и путь к файлу (без самого ключа):
       ## Remnawave-панель
       - Адрес: <URL_ПАНЕЛИ>
       - API-ключ: $PANEL_KEY_FILE

MANUAL
fi

# ═══════════════════════════════════════════════════════════════════════════
head_ "5/5 — Cloudflare Global API Key: домены/поддомены/A-записи (опционально)"
# ═══════════════════════════════════════════════════════════════════════════
say "Если агент должен управлять DNS через Cloudflare API (создавать домены/поддомены,"
say "A-записи) — сохраним email аккаунта и Global API Key. Сам ключ — в отдельный файл"
say "с правами 600, который guard.sh защищает так же, как остальные *.key."
say ""
warn "Global API Key даёт полный доступ ко ВСЕМ зонам аккаунта. Если нужен доступ только"
warn "к одной зоне — в Cloudflare лучше выпустить Scoped API Token (My Profile → API Tokens)"
warn "и просто вставить его сюда вместо Global Key, схема хранения та же."

if ask_yn "Настроить доступ к Cloudflare сейчас?"; then
    read -rp "Email аккаунта Cloudflare: " cf_email
    read -rp "Global API Key (или Scoped API Token), не будет отображаться в истории: " -s cf_key
    say ""

    if [ -z "$cf_email" ] || [ -z "$cf_key" ]; then
        warn "Email или ключ не введены, пропускаю."
    else
        mkdir -p "$(dirname "$CF_KEY_FILE")"
        printf 'email=%s\napi_key=%s\n' "$cf_email" "$cf_key" > "$CF_KEY_FILE"
        chmod 600 "$CF_KEY_FILE"
        ok "Email + ключ сохранены в $CF_KEY_FILE (chmod 600)."

        block="$(cat <<EOF

## Cloudflare API (автозаполнено $(date '+%Y-%m-%d %H:%M'))

- Email аккаунта: $cf_email
- Ключ: $CF_KEY_FILE (защищён guard.sh, агенту не читать/не выводить содержимое)
- Назначение: управление доменами/поддоменами/A-записями через Cloudflare API

EOF
)"
        if [ -f "$CLAUDE_MD" ]; then
            if grep -q "^## Cloudflare API" "$CLAUDE_MD" 2>/dev/null; then
                warn "В $CLAUDE_MD уже есть секция «Cloudflare API» — не дублирую, поправь руками."
            else
                printf '%s\n' "$block" >> "$CLAUDE_MD"
                ok "Секция с Cloudflare дописана в $CLAUDE_MD."
            fi
        else
            warn "$CLAUDE_MD не найден — вот черновик секции, вставь его сам:"
            printf '%s\n' "$block"
        fi
    fi
else
    say ""
    say "${c_dim}Пропущено. Сделай то же самое руками:${c_reset}"
    cat <<MANUAL

  1) Сохрани email + ключ в отдельный файл с правами 600 (не в CLAUDE.md!):
       mkdir -p $(dirname "$CF_KEY_FILE")
       printf 'email=%s\napi_key=%s\n' '<EMAIL>' '<GLOBAL_API_KEY>' > $CF_KEY_FILE
       chmod 600 $CF_KEY_FILE
     → имя файла оканчивается на .key — guard.sh уже блокирует чтение/вынос
       таких файлов тем же правилом, что и остальные секреты.

  2) В $CLAUDE_MD впиши только email и путь к файлу (без самого ключа):
       ## Cloudflare API
       - Email аккаунта: <EMAIL>
       - Ключ: $CF_KEY_FILE

MANUAL
fi

head_ "Готово"
say "Дозаполни $CLAUDE_MD руками: что нельзя трогать, рабочие процессы диагностики,"
say "и загляни в README — секции про settings.json/guard.sh объясняют остальное."
