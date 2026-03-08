#!/bin/bash

# ==========================================================
#   Telega MTProxy + Kaskad Manager
# ==========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
NC='\033[0m'

PROXY_CONTAINER="mtproto-proxy"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Запустите скрипт от root${NC}"
        exit 1
    fi
}

get_ip() {
    curl -s -4 --max-time 5 https://api.ipify.org \
    || curl -s -4 --max-time 5 https://icanhazip.com \
    || echo "0.0.0.0"
}

install_deps() {
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi

    if ! command -v qrencode &>/dev/null; then
        apt-get update -y >/dev/null 2>&1
        apt-get install -y qrencode >/dev/null 2>&1 || yum install -y qrencode
    fi

    if ! command -v iptables &>/dev/null; then
        apt-get update -y >/dev/null 2>&1
        apt-get install -y iptables >/dev/null 2>&1
    fi
}

pause_screen() {
    echo
    read -p "Нажмите Enter для возврата в меню..."
}

show_header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║               Telega MTProxy + Kaskad                ║${NC}"
    echo -e "${YELLOW}║                  Вайб кодинг рулит                   ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"
    echo
}

container_exists() {
    docker ps -a --format '{{.Names}}' | grep -qx "$PROXY_CONTAINER"
}

container_running() {
    docker ps --format '{{.Names}}' | grep -qx "$PROXY_CONTAINER"
}

show_config() {
    if ! container_exists; then
        echo -e "${RED}MTProxy контейнер не найден!${NC}"
        return 1
    fi

    local secret ip port link
    secret=$(docker inspect "$PROXY_CONTAINER" --format='{{range .Config.Cmd}}{{.}} {{end}}' 2>/dev/null | awk '{print $NF}')
    port=$(docker inspect "$PROXY_CONTAINER" --format='{{range $p, $conf := .HostConfig.PortBindings}}{{(index $conf 0).HostPort}}{{end}}' 2>/dev/null | head -n 1)
    ip=$(get_ip)

    port=${port:-443}
    link="tg://proxy?server=$ip&port=$port&secret=$secret"

    echo -e "${GREEN}=== ДАННЫЕ ПОДКЛЮЧЕНИЯ MTProxy ===${NC}"
    echo "IP: $ip"
    echo "Port: $port"
    echo "Secret: $secret"
    echo "Link: $link"
    echo

    qrencode -t ANSIUTF8 "$link"
    return 0
}

choose_domain() {
    local domains domain_choice
    domains=(
        "google.com"
        "github.com"
        "wikipedia.org"
        "stackoverflow.com"
        "bbc.com"
        "cnn.com"
        "reuters.com"
        "cloudflare.com"
    )

    echo -e "${CYAN}Выберите домен маскировки:${NC}"
    echo "1) google.com"
    echo "2) github.com"
    echo "3) wikipedia.org"
    echo "4) stackoverflow.com"
    echo "5) bbc.com"
    echo "6) cnn.com"
    echo "7) reuters.com"
    echo "8) cloudflare.com"
    echo "9) Ввести свой домен"
    echo

    read -p "Выбор [1-9]: " domain_choice

    case "$domain_choice" in
        1) DOMAIN="google.com" ;;
        2) DOMAIN="github.com" ;;
        3) DOMAIN="wikipedia.org" ;;
        4) DOMAIN="stackoverflow.com" ;;
        5) DOMAIN="bbc.com" ;;
        6) DOMAIN="cnn.com" ;;
        7) DOMAIN="reuters.com" ;;
        8) DOMAIN="cloudflare.com" ;;
        9)
            read -p "Введите свой домен для fake TLS/SNI: " DOMAIN
            DOMAIN="${DOMAIN// /}"
            if [ -z "$DOMAIN" ]; then
                DOMAIN="google.com"
            fi
            ;;
        *)
            DOMAIN="google.com"
            ;;
    esac
}

choose_port() {
    local port_choice
    echo
    echo -e "${CYAN}Выберите порт:${NC}"
    echo "1) 443   (рекомендуется)"
    echo "2) 1194  (если 443 занят, например VPN/сайт)"
    echo "3) 51820 (если 443 занят, например VPN/сайт)"
    echo "4) Свой порт"
    echo

    read -p "Выбор [1-4]: " port_choice

    case "$port_choice" in
        1) PORT=443 ;;
        2) PORT=1194 ;;
        3) PORT=51820 ;;
        4)
            read -p "Введите свой порт: " PORT
            ;;
        *)
            PORT=443
            ;;
    esac

    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo -e "${YELLOW}Некорректный порт, будет использован 443.${NC}"
        PORT=443
    fi
}

install_proxy() {
    show_header
    choose_domain
    choose_port

    echo
    echo -e "${YELLOW}[*] Генерация секрета для домена ${WHITE}$DOMAIN${NC}"
    SECRET=$(docker run --rm nineseconds/mtg:2 generate-secret --hex "$DOMAIN")
    if [ -z "$SECRET" ]; then
        echo -e "${RED}Не удалось сгенерировать secret.${NC}"
        pause_screen
        return
    fi

    echo -e "${YELLOW}[*] Остановка старого контейнера (если был)...${NC}"
    docker stop "$PROXY_CONTAINER" &>/dev/null
    docker rm "$PROXY_CONTAINER" &>/dev/null

    echo -e "${YELLOW}[*] Запуск MTProxy на порту ${WHITE}$PORT${NC}"
    if ! docker run -d \
        --name "$PROXY_CONTAINER" \
        --restart always \
        -p "$PORT:$PORT" \
        nineseconds/mtg:2 simple-run \
        -n 1.1.1.1 \
        -i prefer-ipv4 \
        "0.0.0.0:$PORT" \
        "$SECRET" >/dev/null; then
        echo -e "${RED}Не удалось запустить контейнер. Возможно порт занят.${NC}"
        pause_screen
        return
    fi

    echo
    echo -e "${GREEN}[OK] MTProxy установлен / обновлён.${NC}"
    echo
    show_config
    pause_screen
}

restart_proxy() {
    show_header
    if ! container_exists; then
        echo -e "${RED}MTProxy контейнер не найден.${NC}"
        pause_screen
        return
    fi

    docker restart "$PROXY_CONTAINER"
    echo -e "${GREEN}Прокси перезапущен.${NC}"
    pause_screen
}

proxy_logs() {
    show_header
    if ! container_exists; then
        echo -e "${RED}MTProxy контейнер не найден.${NC}"
        pause_screen
        return
    fi

    echo -e "${CYAN}Логи MTProxy. Для выхода нажмите Ctrl+C${NC}"
    echo
    docker logs -f "$PROXY_CONTAINER"
}

delete_proxy() {
    show_header
    if ! container_exists; then
        echo -e "${YELLOW}MTProxy контейнер уже отсутствует.${NC}"
        pause_screen
        return
    fi

    read -p "Удалить MTProxy контейнер? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        docker stop "$PROXY_CONTAINER" &>/dev/null
        docker rm "$PROXY_CONTAINER" &>/dev/null
        echo -e "${GREEN}Прокси удалён.${NC}"
    else
        echo "Отменено."
    fi
    pause_screen
}

get_iface() {
    ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}'
}

apply_rule() {
    show_header

    read -p "Введите IP назначения: " TARGET
    read -p "Введите порт: " PORT

    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo -e "${RED}Некорректный порт.${NC}"
        pause_screen
        return
    fi

    IFACE=$(get_iface)
    if [ -z "$IFACE" ]; then
        echo -e "${RED}Не удалось определить сетевой интерфейс.${NC}"
        pause_screen
        return
    fi

    iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT
    iptables -t nat -A PREROUTING -p tcp --dport "$PORT" -j DNAT --to-destination "$TARGET:$PORT"

    if ! iptables -t nat -C POSTROUTING -o "$IFACE" -j MASQUERADE 2>/dev/null; then
        iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
    fi

    iptables -I FORWARD -p tcp -d "$TARGET" --dport "$PORT" -j ACCEPT
    iptables -I FORWARD -p tcp -s "$TARGET" --sport "$PORT" -j ACCEPT

    echo
    echo -e "${GREEN}Правило добавлено:${NC}"
    echo "TCP $PORT -> $TARGET:$PORT"
    pause_screen
}

list_rules() {
    show_header
    echo -e "${GREEN}Активные правила DNAT:${NC}"
    echo
    iptables -t nat -S PREROUTING | grep DNAT || echo "Правил нет."
    pause_screen
}

delete_rule() {
    show_header

    local rules
    rules=$(iptables -t nat -S PREROUTING | grep DNAT)

    if [ -z "$rules" ]; then
        echo "Правил нет."
        pause_screen
        return
    fi

    echo "$rules"
    echo
    read -p "Введите порт правила для удаления: " PORT

    iptables -t nat -S PREROUTING | grep " --dport $PORT " | while read -r r; do
        iptables -t nat -D ${r#-A }
    done

    iptables -S INPUT | grep " --dport $PORT " | while read -r r; do
        iptables -D ${r#-A }
    done

    iptables -S FORWARD | grep -E " --dport $PORT | --sport $PORT " | while read -r r; do
        iptables -D ${r#-A }
    done

    echo -e "${GREEN}Правило(а) для порта $PORT удалено.${NC}"
    pause_screen
}

flush_rules() {
    show_header
    read -p "Удалить ВСЕ правила Kaskad/PREROUTING? (y/n): " confirm

    if [[ "$confirm" == "y" ]]; then
        iptables -t nat -F PREROUTING
        echo -e "${GREEN}Все правила PREROUTING очищены.${NC}"
        echo -e "${YELLOW}Внимание: очищена вся цепочка PREROUTING nat.${NC}"
    else
        echo "Отменено."
    fi

    pause_screen
}

main_menu() {
    while true; do
        show_header
        echo "1) Установить / Обновить прокси"
        echo "2) Показать данные подключения"
        echo "3) Настроить правило MTProxy Kaskad"
        echo "4) Перезапустить прокси"
        echo "5) Посмотреть активные правила"
        echo "6) Удалить одно правило"
        echo "7) Сбросить ВСЕ настройки"
        echo "8) Логи прокси"
        echo "9) Удалить прокси"
        echo "0) Выход"
        echo

        read -p "Пункт: " choice

        case "$choice" in
            1) install_proxy ;;
            2) show_header; show_config; pause_screen ;;
            3) apply_rule ;;
            4) restart_proxy ;;
            5) list_rules ;;
            6) delete_rule ;;
            7) flush_rules ;;
            8) proxy_logs ;;
            9) delete_proxy ;;
            0) exit 0 ;;
            *) echo "Неверный выбор"; sleep 1 ;;
        esac
    done
}

check_root
install_deps
main_menu
