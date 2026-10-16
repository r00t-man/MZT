#!/usr/bin/env bash
# Honest VPN · аудит конфигурации ноды и сетевых признаков (локальная проверка).
#
# Скрипт ничего не меняет на сервере, только читает. Конфиг Xray (с ключами) держит во временном файле
# с правами 600 и удаляет при выходе; ключи и UUID на экран не выводит.
#
# На самой ноде (root), полная проверка:
#   sudo bash rkn-node-check.sh
# Снаружи, с любого сервера или ПК (без доступа к ноде — часть пунктов):
#   bash rkn-node-check.sh --remote <IP или домен> [--sni домен-заглушки] [--node-port 2222]
#
# Что проверяется (5 пунктов):
#   1. Selfsteal на 443: Reality ведёт на СВОЙ сайт на этом же сервере, домен смотрит на этот сервер,
#      на 443 отдаётся настоящий сертификат домена; несколько транспортов — через SNI-разводку на 443.
#   2. HTTP 301 на 80: http://домен/ отвечает постоянным редиректом 301 на https://.
#   3. Нет Trojan и VLESS без Vision (вложенный TLS виден по размерам пакетов).
#   4. Порт Remnanode (по умолчанию 2222) снаружи закрыт: RST/DROP для всех, кроме IP панели.
#   5. Заглушка отдаёт TLS 1.2, TLS 1.3 и заголовок HSTS.
#
# Флаги: --remote ХОСТ | --sni ДОМЕН | --node-port ПОРТ | --no-color | --help
# ВАЖНО: никакие внешние API для сканирования портов не вызываются.
# Доступность Node Port из интернета проверяйте с отдельной машины через --remote.

set -u
VERSION="1.1-offline (16.10.2026)"

REMOTE="" SNI="" NODE_PORT="" COLOR=1
usage() {
  cat <<'EOF'
Honest VPN: локальный аудит ноды. Ничего не меняет, только читает.
  На ноде (root):  sudo bash rkn-node-check.sh
  Снаружи:         bash rkn-node-check.sh --remote <IP|домен> [--sni домен] [--node-port 2222]
Флаги:
  --remote ХОСТ     проверить чужую/свою ноду снаружи (пункт 3 — только на самой ноде)
  --sni ДОМЕН       домен сайта-заглушки (на ноде берётся из Reality serverNames)
  --node-port ПОРТ  порт Remnanode (на ноде определяется сам, по умолчанию 2222)
  --no-color        без цвета
Пункты: 1) selfsteal на 443  2) HTTP 301 на 80  3) нет Trojan и VLESS без Vision
        4) порт Remnanode закрыт снаружи  5) заглушка: TLS 1.2, TLS 1.3, HSTS
Подробная инструкция: раздел «Безопасность и проверки» локальной БЗ Honest VPN.
EOF
}
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) REMOTE="${2:-}"; shift 2 ;;
    --sni) SNI="${2:-}"; shift 2 ;;
    --node-port) NODE_PORT="${2:-}"; shift 2 ;;
    --no-color) COLOR=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Неизвестный флаг: $1 (см. --help)"; exit 2 ;;
  esac
done
[ -t 1 ] || COLOR=0
if [ "$COLOR" = 1 ]; then
  G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'
else
  G="" Y="" R="" B="" D="" N=""
fi

have() { command -v "$1" >/dev/null 2>&1; }
TMPD=$(mktemp -d 2>/dev/null || echo /tmp/rkncheck.$$); mkdir -p "$TMPD"; chmod 700 "$TMPD"
trap 'rm -rf "$TMPD"' EXIT
CFG="$TMPD/xray.json"

# ── итог по пунктам: худший статус пункта (OK < INFO < WARN < FAIL), SKIP — не проверялся ───────────────
declare -A WORST
TITLES=("" "Selfsteal на 443" "HTTP 301 на 80" "Нет Trojan и VLESS без Vision" "Порт Remnanode закрыт снаружи" "Заглушка: TLS 1.2, TLS 1.3, HSTS")
rank() { case "$1" in FAIL) echo 3 ;; WARN) echo 2 ;; OK) echo 1 ;; INFO) echo 0 ;; NA) echo -1 ;; *) echo -2 ;; esac; }
mark() {  # mark ПУНКТ СТАТУС ТЕКСТ
  local item="$1" st="$2" txt="$3" icon
  case "$st" in
    OK) icon="${G}✔${N}" ;; WARN) icon="${Y}⚠${N}" ;; FAIL) icon="${R}✘${N}" ;; SKIP|NA) icon="${D}–${N}" ;; *) icon="${D}ℹ${N}" ;;
  esac
  echo "   $icon $txt"
  local cur="${WORST[$item]:-}"
  if [ "$st" != "SKIP" ] && { [ -z "$cur" ] || [ "$(rank "$st")" -gt "$(rank "$cur")" ]; }; then WORST[$item]="$st"; fi
  [ "$st" = "SKIP" ] && [ -z "$cur" ] && WORST[$item]="SKIP"
  return 0
}
head_item() { echo; echo "${B}$1. ${TITLES[$1]}${N}"; }

# ── сетевые помощники ────────────────────────────────────────────────────────────────────────────────────
resolve4() {  # все IPv4 адреса имени
  if have getent; then getent ahostsv4 "$1" 2>/dev/null | awk '{print $1}' | sort -u
  elif have dig; then dig +short A "$1" | grep -E '^[0-9.]+$'
  else python3 -c "import socket,sys;print('\n'.join(sorted({a[4][0] for a in socket.getaddrinfo(sys.argv[1],None,socket.AF_INET)})))" "$1" 2>/dev/null
  fi
}
is_ip() { [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$1" == *:*:* ]]; }

tls_try() {  # tls_try IP SNI VER(1_2|1_3) → печатает «ok|fail протокол проверка»
  local out ver vfy
  out=$(timeout 12 openssl s_client -connect "$1:443" -servername "$2" "-tls$3" -verify_hostname "$2" -brief </dev/null 2>&1)
  if echo "$out" | grep -q "CONNECTION ESTABLISHED"; then
    ver=$(echo "$out" | sed -n 's/^Protocol version: *//p' | head -1)
    vfy=$(echo "$out" | sed -n 's/^Verification: *//p' | head -1)
    echo "ok ${ver:-?} ${vfy:-?}"
  else
    echo "fail"
  fi
}
http_head() {  # http_head URL RESOLVE → заголовки ответа (без тела)
  curl -s -o /dev/null -D - --max-time 10 --resolve "$2" "$1" 2>/dev/null | tr -d '\r'
}
ext_port() {  # внешняя доступность не может быть достоверно измерена с самой ноды
  echo "off"
}
tcp_probe() {  # tcp_probe HOST PORT (для --remote) → open|closed|filtered
  local rc; timeout 6 bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null; rc=$?
  if [ $rc -eq 0 ]; then echo open; elif [ $rc -eq 124 ]; then echo filtered; else echo closed; fi
}

echo "${B}Honest VPN · аудит безопасности ноды${N} ${D}v$VERSION${N}"
for t in curl openssl; do have "$t" || { echo "${R}Нужен $t:${N} apt install -y $t"; exit 2; }; done

# ═════════════════════════════════════ режим «снаружи» ═════════════════════════════════════════════════
if [ -n "$REMOTE" ]; then
  if is_ip "$REMOTE"; then IP="$REMOTE"; else IP=$(resolve4 "$REMOTE" | head -1); [ -z "$SNI" ] && SNI="$REMOTE"; fi
  [ -z "$IP" ] && { echo "${R}Не удалось определить IP для $REMOTE${N}"; exit 2; }
  NODE_PORT="${NODE_PORT:-2222}"
  echo "Проверка снаружи: ${B}$IP${N}${SNI:+ · домен заглушки $SNI} · порт ноды $NODE_PORT"
  [ -z "$SNI" ] && echo "${Y}Домен заглушки не указан (--sni) — пункты 1, 2 и 5 проверить не получится.${N}"

  head_item 1
  if [ -n "$SNI" ]; then
    r=$(tls_try "$IP" "$SNI" 1_3)
    if [[ "$r" == ok* ]] && [[ "$r" == *OK* ]]; then mark 1 OK "на $IP:443 настоящий сертификат $SNI (проверка цепочки пройдена)"
    elif [[ "$r" == ok* ]]; then mark 1 FAIL "на $IP:443 сертификат НЕ для $SNI или недоверенный — так выглядит «кража» чужого сайта"
    else mark 1 FAIL "на $IP:443 TLS с SNI $SNI не поднимается"; fi
    if resolve4 "$SNI" | grep -qx "$IP"; then mark 1 OK "$SNI указывает на этот сервер ($IP)"
    else mark 1 FAIL "$SNI указывает не на $IP ($(resolve4 "$SNI" | tr '\n' ' ')) — для РКН это несовпадение IP и SNI"; fi
    mark 1 INFO "куда ведёт Reality (target) и сколько транспортов — видно только на самой ноде"
  else mark 1 SKIP "нужен --sni"; fi

  head_item 2
  if [ -n "$SNI" ]; then
    h=$(http_head "http://$SNI/" "$SNI:80:$IP"); code=$(echo "$h" | awk 'NR==1{print $2}'); loc=$(echo "$h" | sed -n 's/^[Ll]ocation: *//p' | head -1)
    case "$code" in
      301) [[ "$loc" == https://* ]] && mark 2 OK "http://$SNI/ → 301 $loc" || mark 2 WARN "301, но ведёт не на https: ${loc:-пусто}" ;;
      308) mark 2 WARN "308 вместо 301 (тоже постоянный редирект; рекомендация — именно 301) → $loc" ;;
      302|307) mark 2 FAIL "$code — временный редирект, нужен постоянный 301" ;;
      "") mark 2 FAIL "порт 80 не отвечает — нужен открытый 80 с редиректом 301 на https" ;;
      *) mark 2 FAIL "ответ $code вместо 301 на https" ;;
    esac
  else mark 2 SKIP "нужен --sni"; fi

  head_item 3
  mark 3 SKIP "проверяется только на самой ноде (нужен конфиг Xray) — запустите скрипт там"

  head_item 4
  st=$(tcp_probe "$IP" "$NODE_PORT")
  case "$st" in
    open) mark 4 FAIL "порт $NODE_PORT открыт отсюда. Если вы запускаете не с сервера панели — его видит весь интернет" ;;
    closed) mark 4 OK "порт $NODE_PORT закрыт (RST)" ;;
    *) mark 4 OK "порт $NODE_PORT не отвечает (DROP)" ;;
  esac

  head_item 5
  if [ -n "$SNI" ]; then
    for v in 1_3 1_2; do
      r=$(tls_try "$IP" "$SNI" "$v"); name="TLS ${v/_/.}"
      if [[ "$r" == ok* ]]; then mark 5 OK "$name: есть"; else mark 5 FAIL "$name: рукопожатие не проходит"; fi
    done
    h=$(http_head "https://$SNI/" "$SNI:443:$IP"); hsts=$(echo "$h" | grep -i '^strict-transport-security:' | head -1)
    if [ -n "$hsts" ]; then
      ma=$(echo "$hsts" | grep -oiE 'max-age=[0-9]+' | cut -d= -f2)
      if [ "${ma:-0}" -ge 15552000 ]; then mark 5 OK "HSTS: ${hsts#*: }"; else mark 5 WARN "HSTS есть, но max-age ${ma:-0} мало (нужно от 15552000, лучше 31536000)"; fi
    else mark 5 FAIL "нет заголовка Strict-Transport-Security"; fi
  else mark 5 SKIP "нужен --sni"; fi
else
# ═════════════════════════════════════ режим «на ноде» ═════════════════════════════════════════════════
  [ "$(id -u)" = 0 ] || { echo "${R}Запустите от root${N} (нужен доступ к конфигу Xray и правилам файрвола) или используйте --remote"; exit 2; }
  have ss || { echo "${R}Нужен ss:${N} apt install -y iproute2"; exit 2; }
  PY=1; have python3 || PY=0

  # публичный адрес ноды
  PUBIP=""
  [ -z "$PUBIP" ] && PUBIP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oE 'src [0-9.]+' | awk '{print $2}')

  # конфиг Xray: Remnawave (живой, с внутреннего сокета), xray -config, типовые пути панелей
  CFG_SRC=""
  P=$(pgrep -x rw-core | head -1)
  if [ -n "$P" ] && have nsenter; then
    SRC=$(tr '\0' ' ' </proc/$P/cmdline | grep -oE '@rwint-[A-Za-z0-9]+:/internal/get-config\?token=[A-Za-z0-9]+' | head -1)
    if [ -n "$SRC" ]; then
      SOCK=${SRC%%:*}; SOCK=${SOCK#@}; UP=${SRC#@*:}
      nsenter -t "$P" -n curl -s --max-time 6 --abstract-unix-socket "$SOCK" "http://l$UP" -o "$CFG" 2>/dev/null && CFG_SRC="Remnawave, живой конфиг ноды"
    fi
  fi
  if [ -z "$CFG_SRC" ]; then
    for P2 in $(pgrep -x xray) $(pgrep -x rw-core); do
      f=$(tr '\0' ' ' </proc/$P2/cmdline | grep -oE '(-config|-c|--config)[ =][^ ]+' | head -1 | sed -E 's/^(-config|-c|--config)[ =]//')
      [ -z "$f" ] || [[ "$f" == @* ]] && continue
      for cand in "/proc/$P2/root$f" "$f"; do [ -f "$cand" ] && cp "$cand" "$CFG" && CFG_SRC="файл $f" && break 2; done
    done
  fi
  if [ -z "$CFG_SRC" ]; then
    for f in /usr/local/x-ui/bin/config.json /usr/local/etc/xray/config.json /etc/xray/config.json /var/lib/marzban/xray_config.json /opt/marzban/xray_config.json; do
      [ -f "$f" ] && cp "$f" "$CFG" && CFG_SRC="файл $f" && break
    done
  fi
  [ -s "$CFG" ] && chmod 600 "$CFG"

  # порт ноды Remnawave: кто слушает (rw-node), иначе NODE_PORT из .env, иначе 2222
  RW_NODE=0
  if [ -z "$NODE_PORT" ]; then
    NODE_PORT=$(ss -ltnpH 2>/dev/null | grep -E '"rw-node"|"node"' | awk '{print $4}' | sed -E 's/.*:([0-9]+)$/\1/' | head -1)
    [ -n "$NODE_PORT" ] && RW_NODE=1
    [ -z "$NODE_PORT" ] && NODE_PORT=$(grep -hsE '^(NODE_PORT|APP_PORT)=' /opt/remnanode/.env /opt/remnawave/node/.env 2>/dev/null | head -1 | cut -d= -f2 | tr -d '"')
  else RW_NODE=1; fi
  [ -n "$NODE_PORT" ] && ss -ltnH "sport = :$NODE_PORT" 2>/dev/null | grep -q . && RW_NODE=1

  echo "Сервер: ${B}${PUBIP:-?}${N} · конфиг Xray: ${CFG_SRC:-не найден} · Remnanode: $([ "$RW_NODE" = 1 ] && echo "порт $NODE_PORT" || echo "не найден")"

  # ── разбор конфига (python3) → строки «СТАТУС<TAB>ПУНКТ<TAB>ТЕКСТ» + служебные SNI/TARGET ─────────────
  ANALYSIS=""
  if [ -s "$CFG" ] && [ "$PY" = 1 ]; then
    LOCALIPS=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | tr '\n' ' ')
    ANALYSIS=$(LISTEN443="$(ss -ltnpH 'sport = :443' 2>/dev/null | head -3)" PUBIP="$PUBIP" LOCALIPS="$LOCALIPS" python3 - "$CFG" <<'PYEOF'
import json, os, re, socket, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
try:
    c = json.loads(raw)
except ValueError:   # xray допускает комментарии — уберём построчные // и /* */
    raw2 = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)
    raw2 = "\n".join(l for l in raw2.splitlines() if not l.strip().startswith("//"))
    c = json.loads(raw2)
pub = os.environ.get("PUBIP", "")
mine = set(os.environ.get("LOCALIPS", "").split()) | ({pub} if pub else set())
l443 = os.environ.get("LISTEN443", "")
out = []
def emit(st, item, txt): out.append(f"{st}\t{item}\t{txt}")
LOCAL = ("127.0.0.1", "localhost", "::1", "[::1]")
def is_local_target(t):
    t = str(t if t is not None else "")
    if t.startswith("/") or t.startswith("@") or t.isdigit():   # путь сокета или просто порт = localhost
        return True
    host = t.rsplit(":", 1)[0] if ":" in t and not t.startswith("[") else t.split("]")[0].lstrip("[")
    return host in LOCAL or host.startswith("127.")
def public_listen(ib):
    l = str(ib.get("listen") or "0.0.0.0")
    return not (l in LOCAL or l.startswith("127.") or l.startswith("/") or l.startswith("@"))
def resolve(name):
    try:
        return sorted({a[4][0] for a in socket.getaddrinfo(name, None, socket.AF_INET)})
    except OSError:
        return []

inb = [i for i in c.get("inbounds", []) if i.get("protocol") not in ("tunnel", "dokodemo-door")]
tls_public = []
reality = []
for ib in inb:
    ss = ib.get("streamSettings") or {}
    sec = ss.get("security") or "none"
    net = ss.get("network") or "raw"
    tag = ib.get("tag") or "?"
    proto = ib.get("protocol")
    if public_listen(ib) and sec in ("tls", "reality"):
        tls_public.append((tag, ib.get("port")))
    if sec == "reality":
        reality.append(ib)
    # ── пункт 3 ──
    if proto == "trojan":
        emit("FAIL", 3, f"{tag}: Trojan — вложенный TLS виден по размерам пакетов, уберите этот inbound")
    elif proto == "vless" and sec in ("tls", "reality"):
        st = ib.get("settings") or {}
        base = st.get("flow") or ""
        cl = st.get("clients") or []
        if net in ("raw", "tcp"):
            if cl:
                bad = sum(1 for x in cl if (x.get("flow") or base) != "xtls-rprx-vision")
                if bad:
                    emit("FAIL", 3, f"{tag}: VLESS без Vision у {bad} из {len(cl)} клиентов — нужен flow xtls-rprx-vision")
                else:
                    emit("OK", 3, f"{tag}: VLESS + {sec.upper() if sec=='tls' else 'Reality'} + Vision ({len(cl)} клиентов)")
            elif base == "xtls-rprx-vision":
                emit("OK", 3, f"{tag}: VLESS + Vision (flow на уровне inbound)")
            else:
                emit("WARN", 3, f"{tag}: клиентов в конфиге нет, flow не задан — проверьте, что у пользователей xtls-rprx-vision")
        else:
            emit("WARN", 3, f"{tag}: VLESS поверх {net} с {sec} — Vision на этом транспорте невозможен, вложенный TLS виден; держите только как резерв или за CDN")
    elif proto == "vmess" and sec in ("tls", "reality"):
        emit("WARN", 3, f"{tag}: VMess поверх {sec} — вложенный TLS; основным держите VLESS + Reality + Vision")
    elif proto in ("vless", "vmess", "trojan") and sec == "none" and public_listen(ib):
        emit("WARN", 3, f"{tag}: {proto} без шифрования снаружи (порт {ib.get('port')}) — если это не за CDN/nginx, закройте")
if not any(l.startswith(("FAIL\t3", "OK\t3", "WARN\t3")) for l in out):
    emit("INFO", 3, "VLESS/Trojan-inbound'ов не найдено")

# ── пункт 1: selfsteal ──
proc443 = re.findall(r'users:\(\("([^"]+)"', l443)
if not reality:
    emit("WARN", 1, "Reality-inbound'ов нет — selfsteal не настроен")
seen_names = set()
for ib in reality:
    tag = ib.get("tag") or "?"
    rs = (ib.get("streamSettings") or {}).get("realitySettings") or {}
    tgt = rs.get("target") or rs.get("dest") or ""
    names = [n for n in (rs.get("serverNames") or []) if n]
    port = ib.get("port")
    where = f"порт {port}" if public_listen(ib) else f"за SNI-разводкой ({ib.get('listen')})"
    if public_listen(ib) and str(port) != "443":
        emit("WARN", 1, f"{tag}: Reality на порту {port}, а не на 443")
    if is_local_target(tgt):
        emit("OK", 1, f"{tag}: Reality ({where}) ведёт на свою заглушку {tgt}")
    else:
        emit("FAIL", 1, f"{tag}: Reality ведёт на чужой сайт {tgt} — нужен свой домен и заглушка на этом сервере")
    for n in names[:4]:
        if n in seen_names:
            continue
        seen_names.add(n)
        ips = resolve(n)
        hit = [x for x in ips if x in mine]
        if hit:
            emit("OK", 1, f"{n} указывает на этот сервер ({', '.join(hit)})")
        elif ips and not mine:
            emit("INFO", 1, f"{n} → {', '.join(ips)} (адрес сервера определить не удалось — сверьте сами)")
        elif ips:
            emit("FAIL", 1, f"{n} указывает на {', '.join(ips)}, а не на {pub or 'этот сервер'} — РКН видит несовпадение IP и SNI")
        else:
            emit("FAIL", 1, f"{n} не резолвится — нужен свой домен с A-записью на этот сервер")
        out.append(f"SNI\t-\t{n}")
    if is_local_target(tgt) and not str(tgt).startswith(("/", "@")):
        out.append(f"TARGET\t-\t{tgt if ':' in str(tgt) else '127.0.0.1:' + str(tgt)}")
if len(tls_public) > 1:
    ports = ", ".join(f"{t}:{p}" for t, p in tls_public)
    emit("WARN", 1, f"несколько TLS/Reality-транспортов на разных портах ({ports}) — сведите на 443 через SNI-разводку nginx/caddy")
if proc443:
    p = proc443[0]
    if p in ("nginx", "caddy", "haproxy", "angie"):
        emit("OK", 1, f"443 держит {p} — SNI-разводка по сокетам")
    elif p not in ("rw-core", "xray"):
        emit("INFO", 1, f"443 держит процесс {p}")
print("\n".join(out))
PYEOF
)
  elif [ -s "$CFG" ]; then
    ANALYSIS=$'WARN\t1\tнет python3 — конфиг не разобран (apt install -y python3)\nWARN\t3\tнет python3 — конфиг не разобран (apt install -y python3)'
  else
    ANALYSIS=$'WARN\t1\tконфиг Xray не найден — Reality/target проверить не получилось\nSKIP\t3\tконфиг Xray не найден — протоколы не проверены'
  fi
  [ -z "$SNI" ] && SNI=$(echo "$ANALYSIS" | awk -F'\t' '$1=="SNI"{print $3; exit}')
  TARGET=$(echo "$ANALYSIS" | awk -F'\t' '$1=="TARGET"{print $3; exit}')
  show() { echo "$ANALYSIS" | awk -F'\t' -v i="$1" '$2==i{print $1"\t"$3}' | while IFS=$'\t' read -r st txt; do mark "$1" "$st" "$txt"; done; }
  # mark внутри while (подоболочка) не обновит WORST — пересчитаем отдельно
  worst_from() { echo "$ANALYSIS" | awk -F'\t' -v i="$1" '$2==i{print $1}' | while read -r st; do echo "$(rank "$st") $st"; done | sort -n | tail -1 | awk '{print $2}'; }
  merge() { local w; w=$(worst_from "$1"); [ -n "$w" ] && { local cur="${WORST[$1]:-}"; if [ -z "$cur" ] || [ "$cur" = SKIP ] || [ "$(rank "$w")" -gt "$(rank "$cur")" ]; then WORST[$1]="$w"; fi; }; return 0; }

  # ── 1. selfsteal ──
  head_item 1; show 1; merge 1
  if [ -n "$SNI" ] && [ -n "$PUBIP" ]; then
    r=$(tls_try "$PUBIP" "$SNI" 1_3)
    if [[ "$r" == ok*OK* ]]; then mark 1 OK "на $PUBIP:443 отдаётся настоящий сертификат $SNI"
    elif [[ "$r" == ok* ]]; then mark 1 FAIL "на 443 сертификат не для $SNI или недоверенный (${r#ok })"
    else mark 1 WARN "TLS на $PUBIP:443 с SNI $SNI не поднялся (проверьте снаружи: --remote)"; fi
  fi
  if [ -n "$TARGET" ]; then
    tp=${TARGET##*:}
    if ss -ltnH "sport = :$tp" 2>/dev/null | awk '{print $4}' | grep -qE '^(0\.0\.0\.0|\*|\[::\]):'; then
      st=$(ext_port "$tp")
      case "$st" in
        open) mark 1 WARN "заглушка слушает все адреса и открыта снаружи ($PUBIP:$tp) — привяжите её к 127.0.0.1" ;;
        closed|filtered) mark 1 INFO "заглушка слушает все адреса (порт $tp), но снаружи закрыта файрволом — надёжнее привязать к 127.0.0.1" ;;
        *) mark 1 INFO "заглушка слушает все адреса (порт $tp) — надёжнее привязать к 127.0.0.1" ;;
      esac
    fi
  fi

  # ── 2. HTTP 301 на 80 ──
  head_item 2
  if [ -n "$SNI" ]; then
    h=$(http_head "http://$SNI/" "$SNI:80:${PUBIP:-127.0.0.1}")
    [ -z "$h" ] && h=$(http_head "http://$SNI/" "$SNI:80:127.0.0.1")
    code=$(echo "$h" | awk 'NR==1{print $2}'); loc=$(echo "$h" | sed -n 's/^[Ll]ocation: *//p' | head -1)
    case "$code" in
      301) [[ "$loc" == https://* ]] && mark 2 OK "http://$SNI/ → 301 $loc" || mark 2 WARN "301, но ведёт не на https: ${loc:-пусто}" ;;
      308) mark 2 WARN "308 вместо 301 (тоже постоянный редирект; рекомендация — именно 301) → $loc" ;;
      302|307) mark 2 FAIL "$code — временный редирект, нужен постоянный 301" ;;
      "") mark 2 FAIL "порт 80 не отвечает — нужен открытый 80 с редиректом 301 на https" ;;
      *) mark 2 FAIL "ответ $code вместо 301 на https" ;;
    esac
  else mark 2 SKIP "домен заглушки не найден в конфиге — укажите --sni"; fi

  # ── 3. протоколы ──
  head_item 3; show 3; merge 3

  # ── 4. порт Remnanode ──
  head_item 4
  if [ "$RW_NODE" != 1 ]; then
    mark 4 NA "Remnanode на этом сервере не найден — пункт не применим (или укажите --node-port)"
  else
    lst=$(ss -ltnH "sport = :$NODE_PORT" 2>/dev/null | awk '{print $4}' | tr '\n' ' ')
    panels=$(ss -tnH state established "( sport = :$NODE_PORT )" 2>/dev/null | awk '{print $4}' | sed -E 's/^\[?(::ffff:)?([0-9.]+)\]?:[0-9]+$/\2/' | sort -u | tr '\n' ' ' | sed 's/ $//')
    [ -n "$panels" ] && mark 4 INFO "к порту $NODE_PORT сейчас подключена панель: $panels"
    if echo "$lst" | grep -qE '(^| )(127\.|\[::1\])'; then
      mark 4 OK "порт $NODE_PORT слушает только localhost"
    else
      st=$(ext_port "$NODE_PORT")
      case "$st" in
        open) mark 4 FAIL "порт $NODE_PORT доступен с внешнего проверяющего узла ($PUBIP:$NODE_PORT)" ;;
        closed) mark 4 OK "порт $NODE_PORT недоступен извне (RST)" ;;
        filtered) mark 4 OK "порт $NODE_PORT недоступен извне (DROP)" ;;
        *) [ "$st" = off ] && mark 4 INFO "внешняя проверка не выполняется на самой ноде — анализирую локальные правила firewall; дополнительно проверяйте с другого узла"
           LOCAL_OK=""
           if have ufw && ufw status verbose 2>/dev/null | grep -q "Status: active"; then
             rules=$(ufw status 2>/dev/null | grep -E "^$NODE_PORT(/tcp)?[[:space:]]")
             if ufw status verbose 2>/dev/null | grep -qE "Default: (deny|reject) \(incoming\)" && [ -n "$rules" ] \
                && ! echo "$rules" | grep -q "Anywhere" && ! echo "$rules" | grep -qiE "DENY|REJECT"; then
               LOCAL_OK="ufw: порт $NODE_PORT разрешён только для $(echo "$rules" | awk '{print $3}' | sort -u | tr '\n' ' ' | sed 's/ $//')"
             fi
           elif have iptables && iptables -S INPUT 2>/dev/null | grep -qE '^-P INPUT (DROP|REJECT)'; then
             r=$(iptables -S INPUT 2>/dev/null | grep -E -- "--dport $NODE_PORT\b" | grep -- "-j ACCEPT")
             if [ -n "$r" ] && ! echo "$r" | grep -qv -- " -s "; then
               LOCAL_OK="iptables: порт $NODE_PORT принимается только с $(echo "$r" | grep -oE -- '-s [0-9./]+' | awk '{print $2}' | tr '\n' ' ')"
             fi
           fi
           if [ -n "$LOCAL_OK" ]; then mark 4 OK "$LOCAL_OK (по правилам на сервере; файрвол хостера снаружи не проверялся)"
           else mark 4 WARN "снаружи проверить не удалось, а в правилах ufw/iptables ограничения порта $NODE_PORT не видно — проверьте с другого сервера: --remote $PUBIP"; fi ;;
      esac
      if have ufw && ufw status 2>/dev/null | grep -q "Status: active"; then
        rules=$(ufw status 2>/dev/null | grep -E "^$NODE_PORT(/tcp)?[[:space:]]" | sed -E 's/[[:space:]]+/ /g' | tr '\n' ';')
        [ -n "$rules" ] && [ -z "${LOCAL_OK:-}" ] && mark 4 INFO "ufw: $rules"
      fi
      if [ "${WORST[4]:-}" = FAIL ]; then
        pip=$(echo "$panels" | awk '{print $1}')
        echo "     ${D}Закрыть (ufw, порт 22 не трогаем):${N}"
        echo "       ufw allow from ${pip:-<IP_ПАНЕЛИ>} to any port $NODE_PORT proto tcp comment 'remnanode: только панель'"
        echo "       ufw deny $NODE_PORT/tcp"
      fi
    fi
  fi

  # ── 5. заглушка: TLS 1.2 / 1.3 / HSTS ──
  head_item 5
  if [ -n "$SNI" ]; then
    for v in 1_3 1_2; do
      r=$(tls_try "${PUBIP:-127.0.0.1}" "$SNI" "$v"); name="TLS ${v/_/.}"
      if [[ "$r" == ok* ]]; then mark 5 OK "$name: есть"; else mark 5 FAIL "$name: рукопожатие не проходит"; fi
    done
    h=$(http_head "https://$SNI/" "$SNI:443:${PUBIP:-127.0.0.1}"); hsts=$(echo "$h" | grep -i '^strict-transport-security:' | head -1)
    if [ -n "$hsts" ]; then
      ma=$(echo "$hsts" | grep -oiE 'max-age=[0-9]+' | cut -d= -f2)
      if [ "${ma:-0}" -ge 15552000 ]; then mark 5 OK "HSTS: ${hsts#*: }"; else mark 5 WARN "HSTS есть, но max-age ${ma:-0} мало (нужно от 15552000, лучше 31536000)"; fi
    elif [ -z "$h" ]; then mark 5 FAIL "https://$SNI/ не ответил"
    else mark 5 FAIL "нет заголовка Strict-Transport-Security"; fi
  else mark 5 SKIP "домен заглушки не найден — укажите --sni"; fi
fi

# ═════════════════════════════════════ итог ════════════════════════════════════════════════════════════
echo; echo "${B}Итог${N}"
okn=0 badn=0 warnn=0 skipn=0
for i in 1 2 3 4 5; do
  st="${WORST[$i]:-SKIP}"
  case "$st" in
    FAIL) echo "   ${R}✘${N} $i. ${TITLES[$i]}"; badn=$((badn+1)) ;;
    WARN) echo "   ${Y}⚠${N} $i. ${TITLES[$i]}"; warnn=$((warnn+1)) ;;
    OK|INFO) echo "   ${G}✔${N} $i. ${TITLES[$i]}"; okn=$((okn+1)) ;;
    NA) echo "   ${D}–${N} $i. ${TITLES[$i]} ${D}(не применимо)${N}"; okn=$((okn+1)) ;;
    *) echo "   ${D}–${N} $i. ${TITLES[$i]} ${D}(не проверялся)${N}"; skipn=$((skipn+1)) ;;
  esac
done
echo
echo "В порядке: $okn из 5 · замечаний: $warnn · исправить: $badn$([ "$skipn" -gt 0 ] && echo " · не проверялось: $skipn")"
echo "Подробности: статья «5 проверок безопасности ноды» в БЗ Honest VPN."
[ "$badn" -gt 0 ] && exit 1
exit 0
