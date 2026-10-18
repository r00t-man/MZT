#!/usr/bin/env bash
#
# guard.sh — PreToolUse hard-deny для Claude Code на Linux+Docker сервере.
#
# Это ЕДИНСТВЕННЫЙ надёжный предохранитель: агент работает рутом, OS-права секреты не закрывают,
# а deny-правила в settings.json обходятся составными командами. Хук видит ПОЛНУЮ строку
# (включая `a && b`, пайпы, сабшеллы) и блокирует через exit 2.
#
# Логика: блокируем ТОЛЬКО необратимое / выход-из-доступа / утечку секретов.
# Всё остальное (restart, reload, правка конфигов) пропускаем — оно уйдёт на ручной аппрув.
#
# Зависимости: jq. Вход: JSON на stdin. Выход: exit 0 = пропустить, exit 2 = блок.

set -uo pipefail

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"

block() { printf 'BLOCKED by guard.sh: %s\n' "$1" >&2; exit 2; }

# ---- Файловые инструменты: запрещаем трогать секреты и неприкасаемые конфиги ----
case "$tool" in
  Read|Edit|Write|MultiEdit|NotebookEdit)
    fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
    [ -z "$fp" ] && exit 0
    low="$(printf '%s' "$fp" | tr '[:upper:]' '[:lower:]')"

    # Секреты — никогда (чтение/правка)
    case "$low" in
      *_privkey.key|*.key|*/.env|*/.env.*|*.htpasswd*|*/authorized_keys) block "файл-секрет: $fp" ;;
    esac

    # Правка (не чтение) неприкасаемого  # 🔧 подправь пути под себя
    if [ "$tool" != "Read" ]; then
      case "$low" in
        /opt/certs/*)        block "правка сертификатов: $fp" ;;
        /etc/ssh/*)          block "правка конфигурации SSH: $fp" ;;
      esac
    fi
    exit 0
    ;;
  Bash) : ;;   # разбор ниже
  *) exit 0 ;;
esac

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$cmd" ] && exit 0
low="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')"

g() { printf '%s' "$low" | grep -Eq "$1"; }   # без учёта регистра
G() { printf '%s' "$cmd" | grep -Eq "$1"; }    # с учётом регистра (для SQL)

# 1) СЕКРЕТЫ — чтение/копирование/кодирование/вынос ключей, .env, .htpasswd, authorized_keys.
#    Публичные сертификаты (*_fullchain.pem) читать МОЖНО; `ls` каталога — тоже.
reads_verb='\b(cat|less|more|head|tail|tac|nl|base64|xxd|hexdump|od|strings|cp|scp|rsync|curl|wget|nc|ncat|socat|tar|zip|gzip|dd)\b|openssl\s+(rsa|pkey)'
secret_file='(_privkey|\.key([^a-z0-9]|$)|\.env([^a-z0-9]|$)|\.htpasswd|authorized_keys)'
if g "$reads_verb"; then
  g "$secret_file" && block "попытка прочитать/вынести секрет (ключи/.env/.htpasswd/authorized_keys)"
  if g '/opt/certs'; then   # 🔧 путь к каталогу сертов — под себя
    if g '/opt/certs/[^ ]*\*' || ! g '/opt/certs/[^ ]*(fullchain|\.pem)'; then
      block "доступ к каталогу сертов по маске/целиком (возможны приватные ключи)"
    fi
  fi
fi
g '\b(printenv|env)\b\s*$'              && block "дамп окружения (возможны секреты)"
g 'echo\s+\$.*(secret|token|key|pass)'  && block "вывод секрета из переменной окружения"

# 2) FIREWALL — любая мутация развалит Docker-DNAT и положит сетевой доступ
g '\bufw\s+(enable|disable|allow|deny|reject|limit|delete|reset|default|insert)\b' && block "изменение ufw"
g '\biptables\b.*(-A|-I|-D|-F|-X|-P|-N|-Z|--flush|--delete|--policy)'              && block "изменение iptables"
g '\bip6tables\b.*(-A|-I|-D|-F|-X|-P|-N|-Z|--flush)'                               && block "изменение ip6tables"
g '\bnft\s+(add|delete|flush|insert|replace|create|destroy|rename)\b'             && block "изменение nftables"
g '\bnetfilter-persistent\b'                                                       && block "сохранение/сброс netfilter"

# 3) SSH — потеря доступа к серверу (риск локаута)
g '/etc/ssh/sshd_config'                                   && block "правка sshd_config"
g 'authorized_keys'                                        && block "правка authorized_keys"
g '\bsystemctl\s+(stop|restart|reload|disable|mask)\s+ssh' && block "остановка/рестарт SSH-сервиса"
g '\bservice\s+ssh.*\b(stop|restart)\b'                    && block "остановка/рестарт SSH-сервиса"

# 4) DOCKER — необратимое (тома с данными БД)
g '\bdocker\b.*\bcompose\b.*\bdown\b.*(-v|--volumes)' && block "compose down -v (снос томов с данными)"
g '\bdocker(-compose)?\b.*\bdown\b.*(-v|--volumes)'   && block "compose down -v (снос томов с данными)"
g '\bdocker\s+volume\s+(rm|prune)\b'                  && block "удаление/прун docker-томов"
g '\bdocker\s+system\s+prune\b'                       && block "docker system prune"
g '\bdocker\s+network\s+rm\b'                         && block "удаление docker-сети"

# 5) CONTROL-PLANE — 🔧 если есть веб-панель управления докером (portainer/dockhand/...), раскомментируй и впиши имя:
# g '\bdocker\b.*\b(stop|rm|kill|restart|exec|down|pause)\b.*<имя_контейнера>' && block "мутация control-plane"

# 6) POSTGRES — деструктив по БД (через psql / docker exec)
G 'DROP\s+(DATABASE|TABLE|SCHEMA|ROLE|USER)\b' && block "DROP в Postgres"
G 'TRUNCATE\b'                                  && block "TRUNCATE в Postgres"

# 7) Снос файлов / перезапись неприкасаемого  # 🔧 пути под себя
g '\brm\s+(-[a-z]*r[a-z]*f|-[a-z]*f[a-z]*r|-r\s+-f|-f\s+-r)'        && block "rm -rf (рекурсивно+force)"
g '\brm\b.*(/opt/certs|docker-compose|nginx\.conf)'                && block "rm защищённого пути/конфига"
g '>\s*(/opt/certs|/etc/ssh|.*\.key|.*authorized_keys)'            && block "перезапись (>) защищённого файла"
g '\bchmod\s+(-r\s+)?(777|a\+rwx)\b.*(/opt|/etc|/srv)'             && block "chmod 777 на системных путях"

# 8) Апгрейд системы (на проде — не агентом)
g '\bdo-release-upgrade\b'                               && block "do-release-upgrade"
g '\bapt(-get)?\s+(full-upgrade|dist-upgrade|upgrade)\b' && block "apt upgrade на проде"

# 9) Разрушение диска / форк-бомба
g '\bmkfs'                       && block "mkfs"
g '\bdd\b.*of=/dev/'             && block "dd на устройство"
g ':\(\)\s*\{\s*:\|:&\s*\};:'    && block "fork bomb"

exit 0
