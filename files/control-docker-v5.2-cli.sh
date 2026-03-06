#!/usr/bin/env bash

set -u
export TERM="${TERM:-xterm}"

BASE_DIR="/opt/control-docker"
LOG_DIR="$BASE_DIR/log"
TMP_DIR="/tmp/control-docker-cli"

mkdir -p "$LOG_DIR" "$TMP_DIR"

CURRENT_FILTER="all"
SEARCH_TERM=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

cleanup() {
  stty sane 2>/dev/null || true
  tput cnorm 2>/dev/null || true
  rm -rf "$TMP_DIR"/* 2>/dev/null || true
}

on_interrupt() {
  cleanup
  echo
  echo "Завершено по Ctrl+C"
  exit 130
}

trap cleanup EXIT
trap on_interrupt INT TERM

require_bin() {
  command -v "$1" >/dev/null 2>&1
}

check_requirements() {
  if ! require_bin docker; then
    echo "Ошибка: docker не найден."
    exit 1
  fi
}

pause_console() {
  echo
  read -r -p "Нажмите Enter для продолжения..."
}

menu_description() {
  local key="$1"

  case "$key" in
    main)
      echo "Главный раздел управления Docker: отсюда можно перейти к контейнерам, compose-проектам, логам, очистке и служебным операциям."
      ;;
    select_container)
      echo "Список контейнеров Docker. Здесь выбирается конкретный контейнер для просмотра логов, диагностики, перезапуска, входа внутрь и других действий."
      ;;
    container_actions)
      echo "Меню управления выбранным контейнером. Подходит для диагностики проблем, просмотра логов, проверки состояния, перезапуска и обслуживания."
      ;;
    filter)
      echo "Фильтр списка контейнеров. Удобно, когда контейнеров много и нужно показывать только запущенные, остановленные или перезапускающиеся."
      ;;
    search)
      echo "Поиск по имени контейнера или образа. Помогает быстро найти нужный сервис без ручного просмотра всего списка."
      ;;
    bulk)
      echo "Массовые действия сразу над несколькими контейнерами: запуск, остановка, перезапуск, удаление и сохранение логов."
      ;;
    compose)
      echo "Раздел Docker Compose-проектов. Нужен для просмотра состояния проекта, логов всех сервисов и перезапуска всего compose-стека."
      ;;
    images)
      echo "Работа с Docker images. Здесь можно посмотреть список образов и удалить ненужные, чтобы освободить место на диске."
      ;;
    volumes)
      echo "Работа с Docker volumes. Полезно для контроля постоянных данных контейнеров и удаления неиспользуемых томов."
      ;;
    networks)
      echo "Работа с Docker networks. Используется для просмотра и удаления сетей Docker, когда нужно навести порядок или устранить сетевые конфликты."
      ;;
    cleanup_logs)
      echo "Очистка старых сохранённых лог-файлов из /opt/control-docker/log. Полезно, если накопилось много диагностических файлов."
      ;;
    prune)
      echo "Меню очистки Docker-мусора: неиспользуемые контейнеры, образы, volume и сети. Использовать осторожно, так как операции удаляющие."
      ;;
    logs)
      echo "Просмотр последних строк логов контейнера. Подходит для быстрой диагностики ошибок, падений, проблем запуска и сетевых сбоев."
      ;;
    live_logs)
      echo "Потоковый просмотр логов в реальном времени. Удобно при перезапуске сервиса, тестировании или отслеживании активности прямо сейчас."
      ;;
    save_logs)
      echo "Сохранение части логов контейнера в файл. Полезно для архивации, передачи в поддержку или последующего анализа."
      ;;
    inspect_summary)
      echo "Краткая сводка по контейнеру: образ, статус, сети, порты, монтирования и health. Удобно для быстрого обзора конфигурации."
      ;;
    inspect_raw)
      echo "Полный raw-вывод docker inspect. Используется для глубокой диагностики и поиска точных параметров контейнера."
      ;;
    stats)
      echo "Текущая статистика использования ресурсов контейнером: CPU, память, сеть, диск. Полезно при поиске перегрузки."
      ;;
    top)
      echo "Показывает процессы внутри контейнера. Нужен, когда надо понять, что именно запущено внутри сервиса."
      ;;
    health)
      echo "Проверка health status контейнера. Полезно для сервисов с healthcheck: можно увидеть текущее состояние и историю проверок."
      ;;
    events)
      echo "Поток событий Docker для выбранного контейнера. Удобно при отладке перезапусков, падений, пересоздания и других изменений состояния."
      ;;
    exec)
      echo "Вход внутрь контейнера через shell. Используется для ручной диагностики, проверки файлов, конфигов и сетевой доступности изнутри."
      ;;
    export_diag)
      echo "Экспортирует диагностику контейнера в архив tar.gz: inspect, logs, stats, top и краткую сводку. Удобно для архива и передачи другому администратору."
      ;;
    remove_container)
      echo "Удаление контейнера. Использовать только если контейнер больше не нужен или должен быть пересоздан заново."
      ;;
    *)
      echo "Выберите нужное действие."
      ;;
  esac
}

clear_screen() {
  local title="${1:-Главное меню}"
  local desc="${2:-Выберите нужное действие.}"

  clear
  echo -e "${CYAN}============================================================${NC}"
  echo -e "${CYAN}              CONTROL DOCKER MANAGER v5.2 CLI               ${NC}"
  echo -e "${CYAN}============================================================${NC}"
  echo -e "${BOLD}Раздел      :${NC} $title"
  echo -e "${BOLD}Описание    :${NC} $desc"
  echo -e "${BOLD}Папка логов :${NC} $LOG_DIR"
  echo -e "${BOLD}Фильтр      :${NC} $CURRENT_FILTER"
  echo -e "${BOLD}Поиск       :${NC} ${SEARCH_TERM:-<нет>}"
  echo -e "${CYAN}============================================================${NC}"
  echo
}

confirm() {
  local prompt="$1"
  local ans
  read -r -p "$prompt [y/N]: " ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

input_number() {
  local prompt="$1"
  local value
  while true; do
    read -r -p "$prompt: " value
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf '%s\n' "$value"
      return 0
    fi
    echo "Нужно ввести число."
  done
}

input_positive_number() {
  local prompt="$1"
  local value
  while true; do
    read -r -p "$prompt: " value
    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
      printf '%s\n' "$value"
      return 0
    fi
    echo "Нужно ввести положительное число."
  done
}

run_and_show() {
  "$@"
  local rc=$?
  echo
  echo "Код завершения: $rc"
  pause_console
}

docker_compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return 0
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
    return 0
  fi

  return 1
}

status_colored() {
  local status="$1"
  case "$status" in
    Up*) printf "${GREEN}%s${NC}" "$status" ;;
    Exited*) printf "${RED}%s${NC}" "$status" ;;
    Restarting*) printf "${YELLOW}%s${NC}" "$status" ;;
    Created*) printf "${BLUE}%s${NC}" "$status" ;;
    *) printf "%s" "$status" ;;
  esac
}

run_interactive_stream() {
  local title="$1"
  local desc="$2"
  shift 2

  cleanup
  trap - INT TERM
  clear

  echo -e "${CYAN}============================================================${NC}"
  echo -e "${CYAN} $title${NC}"
  echo -e "${BOLD}Описание    :${NC} $desc"
  echo -e "${CYAN} Для выхода нажми Ctrl+C${NC}"
  echo -e "${CYAN}============================================================${NC}"
  echo

  "$@"
  local rc=$?

  trap on_interrupt INT TERM

  echo
  echo "Просмотр остановлен. Код завершения: $rc"
  pause_console
  return 0
}

get_containers() {
  local filter_args=()

  case "$CURRENT_FILTER" in
    all) filter_args=() ;;
    running) filter_args=(--filter "status=running") ;;
    exited) filter_args=(--filter "status=exited") ;;
    restarting) filter_args=(--filter "status=restarting") ;;
    *) filter_args=() ;;
  esac

  mapfile -t CONTAINERS < <(
    docker ps -a "${filter_args[@]}" \
      --format '{{.Names}}|{{.Status}}|{{.Image}}|{{.ID}}'
  )

  if [ -n "$SEARCH_TERM" ]; then
    local filtered=()
    local entry name status image id
    for entry in "${CONTAINERS[@]}"; do
      IFS='|' read -r name status image id <<< "$entry"
      if [[ "$name" == *"$SEARCH_TERM"* ]] || [[ "$image" == *"$SEARCH_TERM"* ]]; then
        filtered+=("$entry")
      fi
    done
    CONTAINERS=("${filtered[@]}")
  fi
}

print_containers() {
  get_containers

  if [ "${#CONTAINERS[@]}" -eq 0 ]; then
    echo "Контейнеры не найдены."
    return 1
  fi

  local i=1 entry name status image id
  for entry in "${CONTAINERS[@]}"; do
    IFS='|' read -r name status image id <<< "$entry"
    printf "%2d) %-28s | " "$i" "$name"
    status_colored "$status"
    printf " | %s\n" "$image"
    ((i++))
  done

  return 0
}

select_container() {
  local n index
  clear_screen "Выбор контейнера" "$(menu_description select_container)"
  print_containers || {
    pause_console
    return 1
  }

  echo
  echo "0) Назад"
  echo

  while true; do
    n="$(input_number "Выберите номер контейнера")"
    if [ "$n" -eq 0 ]; then
      return 1
    fi
    if [ "$n" -ge 1 ] && [ "$n" -le "${#CONTAINERS[@]}" ]; then
      index=$((n - 1))
      IFS='|' read -r SELECTED_NAME SELECTED_STATUS SELECTED_IMAGE SELECTED_ID <<< "${CONTAINERS[$index]}"
      return 0
    fi
    echo "Нет такого пункта."
  done
}

select_multiple_containers() {
  clear_screen "Массовые действия" "$(menu_description bulk)"
  print_containers || {
    pause_console
    return 1
  }

  echo
  echo "Введи номера контейнеров через пробел."
  echo "Пример: 1 3 5"
  echo "0 - назад"
  echo

  local nums n index name status image id
  read -r -p "Номера: " nums

  [ -z "$nums" ] && return 1
  [ "$nums" = "0" ] && return 1

  SELECTED_CONTAINERS=()

  for n in $nums; do
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#CONTAINERS[@]}" ]; then
      index=$((n - 1))
      IFS='|' read -r name status image id <<< "${CONTAINERS[$index]}"
      SELECTED_CONTAINERS+=("$name")
    fi
  done

  [ "${#SELECTED_CONTAINERS[@]}" -gt 0 ]
}

show_last_logs() {
  local cname="$1"
  local lines
  clear_screen "Просмотр логов" "$(menu_description logs)"
  lines="$(input_positive_number "Сколько строк логов вывести")"
  echo
  docker logs --tail "$lines" "$cname" 2>&1
  pause_console
}

follow_logs() {
  local cname="$1"
  run_interactive_stream "LIVE LOGS: $cname" "$(menu_description live_logs)" docker logs -f --tail 100 "$cname"
}

save_logs_to_file() {
  local cname="$1"
  local lines timestamp dir file

  clear_screen "Сохранение логов" "$(menu_description save_logs)"
  lines="$(input_positive_number "Сколько строк логов сохранить")"

  dir="$LOG_DIR/$cname"
  mkdir -p "$dir"
  timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
  file="$dir/${timestamp}_${lines}-lines.log"

  if docker logs --tail "$lines" "$cname" >"$file" 2>&1; then
    echo
    echo "Логи сохранены:"
    echo "$file"
  else
    echo
    echo "Не удалось сохранить логи контейнера $cname"
  fi

  pause_console
}

restart_container() {
  local cname="$1"
  clear_screen "Перезапуск контейнера" "$(menu_description container_actions)"
  confirm "Перезапустить контейнер $cname?" || return
  run_and_show docker restart "$cname"
}

start_container() {
  local cname="$1"
  clear_screen "Запуск контейнера" "$(menu_description container_actions)"
  confirm "Запустить контейнер $cname?" || return
  run_and_show docker start "$cname"
}

stop_container() {
  local cname="$1"
  clear_screen "Остановка контейнера" "$(menu_description container_actions)"
  confirm "Остановить контейнер $cname?" || return
  run_and_show docker stop "$cname"
}

remove_container() {
  local cname="$1"
  clear_screen "Удаление контейнера" "$(menu_description remove_container)"
  confirm "Удалить контейнер $cname? Это docker rm -f." || return
  run_and_show docker rm -f "$cname"
}

inspect_summary() {
  local cname="$1"
  clear_screen "Inspect summary" "$(menu_description inspect_summary)"
  docker inspect "$cname" --format=$'Name: {{.Name}}\nImage: {{.Config.Image}}\nState: {{.State.Status}}\nRunning: {{.State.Running}}\nStartedAt: {{.State.StartedAt}}\nFinishedAt: {{.State.FinishedAt}}\nRestartCount: {{.RestartCount}}\nHealth: {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}\nNetworks: {{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}\nPorts: {{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}\nMounts: {{range .Mounts}}{{.Source}} -> {{.Destination}}; {{end}}'
  pause_console
}

inspect_raw() {
  local cname="$1"
  clear_screen "Inspect raw" "$(menu_description inspect_raw)"
  docker inspect "$cname"
  pause_console
}

stats_container() {
  local cname="$1"
  clear_screen "Docker stats" "$(menu_description stats)"
  docker stats --no-stream "$cname"
  pause_console
}

top_container() {
  local cname="$1"
  clear_screen "Docker top" "$(menu_description top)"
  docker top "$cname"
  pause_console
}

health_container() {
  local cname="$1"
  clear_screen "Health status" "$(menu_description health)"
  echo "Container: $cname"
  echo
  docker inspect "$cname" --format 'State: {{.State.Status}}'
  docker inspect "$cname" --format 'Running: {{.State.Running}}'
  docker inspect "$cname" --format 'RestartCount: {{.RestartCount}}'
  echo

  if docker inspect "$cname" --format '{{if .State.Health}}yes{{else}}no{{end}}' | grep -q yes; then
    docker inspect "$cname" --format 'Health: {{.State.Health.Status}}'
    echo
    echo "Health log:"
    docker inspect "$cname" --format '{{range .State.Health.Log}}{{.Start}} | exit={{.ExitCode}} | {{.Output}}{{println}}{{end}}'
  else
    echo "Health: none"
  fi

  pause_console
}

events_container() {
  local cname="$1"
  run_interactive_stream "DOCKER EVENTS: $cname" "$(menu_description events)" docker events --filter "container=$cname"
}

exec_container() {
  local cname="$1"

  if ! docker inspect -f '{{.State.Running}}' "$cname" 2>/dev/null | grep -q true; then
    clear_screen "Exec внутрь контейнера" "$(menu_description exec)"
    echo "Контейнер не запущен. exec невозможен."
    pause_console
    return
  fi

  cleanup
  trap - INT TERM
  clear

  echo -e "${CYAN}============================================================${NC}"
  echo -e "${CYAN} EXEC INTO: $cname${NC}"
  echo -e "${BOLD}Описание    :${NC} $(menu_description exec)"
  echo -e "${CYAN} Для выхода используй: exit${NC}"
  echo -e "${CYAN}============================================================${NC}"
  echo

  if docker exec "$cname" sh -c 'command -v bash' >/dev/null 2>&1; then
    docker exec -it "$cname" bash
  elif docker exec "$cname" sh -c 'command -v ash' >/dev/null 2>&1; then
    docker exec -it "$cname" ash
  else
    docker exec -it "$cname" sh
  fi

  trap on_interrupt INT TERM
  pause_console
}

export_container_diagnostics() {
  local cname="$1"
  local export_dir="$LOG_DIR/$cname"
  local ts archive tmpwork

  ts="$(date '+%Y-%m-%d_%H-%M-%S')"
  tmpwork="$TMP_DIR/diag_${cname}_$$"
  archive="$export_dir/${ts}_diagnostics.tar.gz"

  mkdir -p "$export_dir" "$tmpwork"

  docker inspect "$cname" >"$tmpwork/inspect.json" 2>&1
  docker logs --tail 500 "$cname" >"$tmpwork/logs_500.txt" 2>&1
  docker stats --no-stream "$cname" >"$tmpwork/stats.txt" 2>&1
  docker top "$cname" >"$tmpwork/top.txt" 2>&1

  {
    echo "Container: $cname"
    echo "Created: $ts"
    echo
    docker ps -a --filter "name=^/${cname}$"
  } >"$tmpwork/summary.txt" 2>&1

  tar -czf "$archive" -C "$tmpwork" .

  clear_screen "Экспорт диагностики" "$(menu_description export_diag)"
  echo "Диагностика экспортирована:"
  echo "$archive"
  pause_console
}

bulk_save_logs() {
  local lines timestamp cname dir file

  clear_screen "Массовое сохранение логов" "$(menu_description bulk)"
  lines="$(input_positive_number "Сколько строк логов сохранить для каждого контейнера")"

  for cname in "${SELECTED_CONTAINERS[@]}"; do
    dir="$LOG_DIR/$cname"
    mkdir -p "$dir"
    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
    file="$dir/${timestamp}_${lines}-lines.log"
    docker logs --tail "$lines" "$cname" >"$file" 2>&1
  done

  echo
  echo "Логи сохранены в:"
  echo "$LOG_DIR"
  pause_console
}

bulk_action_menu() {
  select_multiple_containers || return

  while true; do
    clear_screen "Массовые действия" "$(menu_description bulk)"
    echo "Выбраны контейнеры:"
    printf ' - %s\n' "${SELECTED_CONTAINERS[@]}"
    echo
    echo "1) Restart выбранных"
    echo "2) Start выбранных"
    echo "3) Stop выбранных"
    echo "4) Сохранить последние N строк логов"
    echo "5) Удалить выбранные контейнеры"
    echo "0) Назад"
    echo

    local action
    action="$(input_number "Выберите действие")"

    case "$action" in
      1)
        confirm "Перезапустить выбранные контейнеры?" || continue
        for cname in "${SELECTED_CONTAINERS[@]}"; do
          echo "===== RESTART: $cname ====="
          docker restart "$cname"
          echo
        done
        pause_console
        ;;
      2)
        confirm "Запустить выбранные контейнеры?" || continue
        for cname in "${SELECTED_CONTAINERS[@]}"; do
          echo "===== START: $cname ====="
          docker start "$cname"
          echo
        done
        pause_console
        ;;
      3)
        confirm "Остановить выбранные контейнеры?" || continue
        for cname in "${SELECTED_CONTAINERS[@]}"; do
          echo "===== STOP: $cname ====="
          docker stop "$cname"
          echo
        done
        pause_console
        ;;
      4)
        bulk_save_logs
        ;;
      5)
        confirm "Удалить выбранные контейнеры? Это docker rm -f." || continue
        for cname in "${SELECTED_CONTAINERS[@]}"; do
          echo "===== REMOVE: $cname ====="
          docker rm -f "$cname"
          echo
        done
        pause_console
        return
        ;;
      0)
        return
        ;;
      *)
        echo "Нет такого пункта."
        sleep 1
        ;;
    esac
  done
}

change_filter_menu() {
  while true; do
    clear_screen "Фильтр контейнеров" "$(menu_description filter)"
    echo "1) all"
    echo "2) running"
    echo "3) exited"
    echo "4) restarting"
    echo "0) Назад"
    echo

    local choice
    choice="$(input_number "Выберите фильтр")"

    case "$choice" in
      1) CURRENT_FILTER="all"; return ;;
      2) CURRENT_FILTER="running"; return ;;
      3) CURRENT_FILTER="exited"; return ;;
      4) CURRENT_FILTER="restarting"; return ;;
      0) return ;;
      *) echo "Нет такого пункта."; sleep 1 ;;
    esac
  done
}

search_menu() {
  clear_screen "Поиск контейнера" "$(menu_description search)"
  echo "Пустой ввод = сброс поиска."
  echo
  read -r -p "Введите строку поиска: " SEARCH_TERM
}

get_compose_projects() {
  local compose_cmd
  if ! compose_cmd="$(docker_compose_cmd)"; then
    COMPOSE_PROJECTS=()
    return 1
  fi

  mapfile -t COMPOSE_PROJECTS < <(
    docker ps -a --format '{{.Label "com.docker.compose.project"}}' | sed '/^$/d' | sort -u
  )

  return 0
}

select_compose_project() {
  clear_screen "Docker Compose" "$(menu_description compose)"
  get_compose_projects || true

  if [ "${#COMPOSE_PROJECTS[@]}" -eq 0 ]; then
    echo "Compose-проекты не найдены."
    pause_console
    return 1
  fi

  local i=1
  local project
  for project in "${COMPOSE_PROJECTS[@]}"; do
    printf "%2d) %s\n" "$i" "$project"
    ((i++))
  done

  echo
  echo "0) Назад"
  echo

  local n
  while true; do
    n="$(input_number "Выберите проект")"
    if [ "$n" -eq 0 ]; then
      return 1
    fi
    if [ "$n" -ge 1 ] && [ "$n" -le "${#COMPOSE_PROJECTS[@]}" ]; then
      SELECTED_PROJECT="${COMPOSE_PROJECTS[$((n - 1))]}"
      return 0
    fi
    echo "Нет такого пункта."
  done
}

compose_project_menu() {
  select_compose_project || return

  local compose_cmd
  compose_cmd="$(docker_compose_cmd)" || {
    clear_screen "Docker Compose" "$(menu_description compose)"
    echo "docker compose / docker-compose не найден."
    pause_console
    return
  }

  while true; do
    clear_screen "Docker Compose: $SELECTED_PROJECT" "$(menu_description compose)"
    echo "1) compose ps"
    echo "2) compose logs (last N)"
    echo "3) compose logs -f"
    echo "4) compose restart"
    echo "0) Назад"
    echo

    local action lines
    action="$(input_number "Выберите действие")"

    case "$action" in
      1)
        clear_screen "Compose PS" "$(menu_description compose)"
        bash -lc "$compose_cmd -p '$SELECTED_PROJECT' ps"
        pause_console
        ;;
      2)
        clear_screen "Compose logs" "$(menu_description compose)"
        lines="$(input_positive_number "Сколько строк логов вывести")"
        echo
        bash -lc "$compose_cmd -p '$SELECTED_PROJECT' logs --tail '$lines'"
        pause_console
        ;;
      3)
        run_interactive_stream "COMPOSE LOGS -F: $SELECTED_PROJECT" "Потоковый просмотр логов всех сервисов compose-проекта в реальном времени." bash -lc "$compose_cmd -p '$SELECTED_PROJECT' logs -f --tail 100"
        ;;
      4)
        clear_screen "Compose restart" "$(menu_description compose)"
        confirm "Перезапустить compose project $SELECTED_PROJECT?" || continue
        bash -lc "$compose_cmd -p '$SELECTED_PROJECT' restart"
        pause_console
        ;;
      0)
        return
        ;;
      *)
        echo "Нет такого пункта."
        sleep 1
        ;;
    esac
  done
}

list_images() {
  clear_screen "Docker images" "$(menu_description images)"
  docker images
  pause_console
}

remove_image_menu() {
  local images
  mapfile -t images < <(docker images --format '{{.Repository}}:{{.Tag}}|{{.ID}}|{{.Size}}')

  clear_screen "Удаление images" "$(menu_description images)"

  if [ "${#images[@]}" -eq 0 ]; then
    echo "Docker images не найдены."
    pause_console
    return
  fi

  local i=1 entry ref id size
  for entry in "${images[@]}"; do
    IFS='|' read -r ref id size <<< "$entry"
    printf "%2d) %-40s | %-20s | %s\n" "$i" "$ref" "$id" "$size"
    ((i++))
  done

  echo
  echo "Введи номера образов через пробел. 0 - назад."
  echo

  local nums n index
  read -r -p "Номера: " nums
  [ -z "$nums" ] && return
  [ "$nums" = "0" ] && return

  confirm "Удалить выбранные images? Это docker rmi -f." || return

  for n in $nums; do
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#images[@]}" ]; then
      index=$((n - 1))
      IFS='|' read -r ref id size <<< "${images[$index]}"
      echo "===== REMOVE IMAGE: $ref ($id) ====="
      docker rmi -f "$id"
      echo
    fi
  done

  pause_console
}

images_menu() {
  while true; do
    clear_screen "Docker images" "$(menu_description images)"
    echo "1) Показать images"
    echo "2) Удалить images"
    echo "0) Назад"
    echo

    local choice
    choice="$(input_number "Выберите действие")"

    case "$choice" in
      1) list_images ;;
      2) remove_image_menu ;;
      0) return ;;
      *) echo "Нет такого пункта."; sleep 1 ;;
    esac
  done
}

list_volumes() {
  clear_screen "Docker volumes" "$(menu_description volumes)"
  docker volume ls
  pause_console
}

remove_volume_menu() {
  local volumes
  mapfile -t volumes < <(docker volume ls --format '{{.Name}}|{{.Driver}}')

  clear_screen "Удаление volumes" "$(menu_description volumes)"

  if [ "${#volumes[@]}" -eq 0 ]; then
    echo "Docker volumes не найдены."
    pause_console
    return
  fi

  local i=1 entry name driver
  for entry in "${volumes[@]}"; do
    IFS='|' read -r name driver <<< "$entry"
    printf "%2d) %-45s | %s\n" "$i" "$name" "$driver"
    ((i++))
  done

  echo
  echo "Введи номера volume через пробел. 0 - назад."
  echo

  local nums n index
  read -r -p "Номера: " nums
  [ -z "$nums" ] && return
  [ "$nums" = "0" ] && return

  confirm "Удалить выбранные volumes?" || return

  for n in $nums; do
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#volumes[@]}" ]; then
      index=$((n - 1))
      IFS='|' read -r name driver <<< "${volumes[$index]}"
      echo "===== REMOVE VOLUME: $name ====="
      docker volume rm "$name"
      echo
    fi
  done

  pause_console
}

volumes_menu() {
  while true; do
    clear_screen "Docker volumes" "$(menu_description volumes)"
    echo "1) Показать volumes"
    echo "2) Удалить volumes"
    echo "0) Назад"
    echo

    local choice
    choice="$(input_number "Выберите действие")"

    case "$choice" in
      1) list_volumes ;;
      2) remove_volume_menu ;;
      0) return ;;
      *) echo "Нет такого пункта."; sleep 1 ;;
    esac
  done
}

list_networks() {
  clear_screen "Docker networks" "$(menu_description networks)"
  docker network ls
  pause_console
}

remove_network_menu() {
  local networks
  mapfile -t networks < <(docker network ls --format '{{.Name}}|{{.Driver}}')

  clear_screen "Удаление networks" "$(menu_description networks)"

  if [ "${#networks[@]}" -eq 0 ]; then
    echo "Docker networks не найдены."
    pause_console
    return
  fi

  local i=1 entry name driver
  for entry in "${networks[@]}"; do
    IFS='|' read -r name driver <<< "$entry"
    printf "%2d) %-45s | %s\n" "$i" "$name" "$driver"
    ((i++))
  done

  echo
  echo "Введи номера network через пробел. 0 - назад."
  echo

  local nums n index
  read -r -p "Номера: " nums
  [ -z "$nums" ] && return
  [ "$nums" = "0" ] && return

  confirm "Удалить выбранные networks?" || return

  for n in $nums; do
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#networks[@]}" ]; then
      index=$((n - 1))
      IFS='|' read -r name driver <<< "${networks[$index]}"
      echo "===== REMOVE NETWORK: $name ====="
      docker network rm "$name"
      echo
    fi
  done

  pause_console
}

networks_menu() {
  while true; do
    clear_screen "Docker networks" "$(menu_description networks)"
    echo "1) Показать networks"
    echo "2) Удалить networks"
    echo "0) Назад"
    echo

    local choice
    choice="$(input_number "Выберите действие")"

    case "$choice" in
      1) list_networks ;;
      2) remove_network_menu ;;
      0) return ;;
      *) echo "Нет такого пункта."; sleep 1 ;;
    esac
  done
}

cleanup_old_logs() {
  local days

  clear_screen "Очистка старых логов" "$(menu_description cleanup_logs)"
  days="$(input_number "Удалить .log файлы старше скольких дней")"
  confirm "Удалить .log файлы старше $days дней из $LOG_DIR ?" || return

  echo
  find "$LOG_DIR" -type f -name "*.log" -mtime +"$days" -print -delete
  pause_console
}

prune_menu() {
  while true; do
    clear_screen "Docker prune" "$(menu_description prune)"
    echo "1) docker container prune"
    echo "2) docker image prune -a"
    echo "3) docker volume prune"
    echo "4) docker network prune"
    echo "5) docker system prune -a --volumes"
    echo "0) Назад"
    echo

    local action
    action="$(input_number "Выберите действие")"

    case "$action" in
      1)
        confirm "Удалить все stopped containers?" || continue
        run_and_show docker container prune -f
        ;;
      2)
        confirm "Удалить неиспользуемые images (docker image prune -a)?" || continue
        run_and_show docker image prune -a -f
        ;;
      3)
        confirm "Удалить неиспользуемые volumes?" || continue
        run_and_show docker volume prune -f
        ;;
      4)
        confirm "Удалить неиспользуемые networks?" || continue
        run_and_show docker network prune -f
        ;;
      5)
        confirm "Выполнить docker system prune -a --volumes ?" || continue
        run_and_show docker system prune -a --volumes -f
        ;;
      0)
        return
        ;;
      *)
        echo "Нет такого пункта."
        sleep 1
        ;;
    esac
  done
}

container_actions_menu() {
  local cname="$1"

  while true; do
    local status image
    status="$(docker ps -a --filter "name=^/${cname}$" --format '{{.Status}}' | head -n1)"
    image="$(docker ps -a --filter "name=^/${cname}$" --format '{{.Image}}' | head -n1)"

    clear_screen "Контейнер: $cname" "$(menu_description container_actions)"
    echo -e "${BOLD}Статус   :${NC} ${status:-unknown}"
    echo -e "${BOLD}Образ    :${NC} ${image:-unknown}"
    echo
    echo "1)  Посмотреть последние N строк логов"
    echo "2)  Live logs -f"
    echo "3)  Сохранить последние N строк логов в файл"
    echo "4)  Restart"
    echo "5)  Start"
    echo "6)  Stop"
    echo "7)  Inspect summary"
    echo "8)  Inspect raw"
    echo "9)  Stats"
    echo "10) Top"
    echo "11) Health status"
    echo "12) Docker events"
    echo "13) Exec внутрь контейнера"
    echo "14) Экспорт диагностики в tar.gz"
    echo "15) Удалить контейнер"
    echo "0)  Назад"
    echo

    local action
    action="$(input_number "Выберите действие")"

    case "$action" in
      1) show_last_logs "$cname" ;;
      2) follow_logs "$cname" ;;
      3) save_logs_to_file "$cname" ;;
      4) restart_container "$cname" ;;
      5) start_container "$cname" ;;
      6) stop_container "$cname" ;;
      7) inspect_summary "$cname" ;;
      8) inspect_raw "$cname" ;;
      9) stats_container "$cname" ;;
      10) top_container "$cname" ;;
      11) health_container "$cname" ;;
      12) events_container "$cname" ;;
      13) exec_container "$cname" ;;
      14) export_container_diagnostics "$cname" ;;
      15) remove_container "$cname"; return ;;
      0) return ;;
      *) echo "Нет такого пункта."; sleep 1 ;;
    esac
  done
}

main_menu() {
  while true; do
    clear_screen "Главное меню" "$(menu_description main)"
    echo "1)  Выбрать контейнер"
    echo "2)  Сменить фильтр"
    echo "3)  Поиск контейнера/образа"
    echo "4)  Массовые действия"
    echo "5)  Docker Compose projects"
    echo "6)  Docker images"
    echo "7)  Docker volumes"
    echo "8)  Docker networks"
    echo "9)  Очистить старые лог-файлы"
    echo "10) Prune меню"
    echo "0)  Выход"
    echo

    local choice
    choice="$(input_number "Выберите действие")"

    case "$choice" in
      1) select_container && container_actions_menu "$SELECTED_NAME" ;;
      2) change_filter_menu ;;
      3) search_menu ;;
      4) bulk_action_menu ;;
      5) compose_project_menu ;;
      6) images_menu ;;
      7) volumes_menu ;;
      8) networks_menu ;;
      9) cleanup_old_logs ;;
      10) prune_menu ;;
      0) exit 0 ;;
      *) echo "Нет такого пункта."; sleep 1 ;;
    esac
  done
}

main() {
  check_requirements
  main_menu
}

main
