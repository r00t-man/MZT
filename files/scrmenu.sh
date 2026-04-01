#!/usr/bin/env bash

set -u

SCREEN_BIN="$(command -v screen || true)"

if [[ -z "${SCREEN_BIN}" ]]; then
  echo "Ошибка: screen не установлен."
  echo "Установить можно так:"
  echo "  apt update && apt install -y screen"
  exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

pause() {
  echo
  read -rp "Нажмите Enter для продолжения..."
}

line() {
  echo -e "${CYAN}============================================================${NC}"
}

show_screen_start_hint() {
  clear
  echo -e "${CYAN}============================================================${NC}"
  echo -e "${WHITE}${BOLD}                Новая screen-сессия запускается${NC}"
  echo -e "${CYAN}============================================================${NC}"
  echo
  echo -e "${YELLOW}Сейчас будет открыта новая screen-сессия.${NC}"
  echo -e "${YELLOW}Краткая справка появится уже внутри неё.${NC}"
  echo
  echo -e "${CYAN}============================================================${NC}"
  echo -e "${YELLOW}Через 5 секунд откроется новая screen-сессия...${NC}"
  sleep 5
}

header() {
  clear
  line
  echo -e "${WHITE}${BOLD}                 Screen Manager CLI Menu v 1.0${NC}"
  echo -e "${YELLOW}${BOLD}                 Вайбкоддинг рулит и GiS =]${NC}"
  line
  echo
  echo -e "${CYAN}===================== ${WHITE}Подсказка${CYAN} =====================${NC}"
  echo -e "${YELLOW}🚀 7:${NC} запуск команды в фоне внутри новой screen-сессии"
  echo -e "${YELLOW}🖥️  8:${NC} создание пустой фоновой shell-сессии для ручной работы позже"
  echo -e "${CYAN}============================================================${NC}"
  echo
}

get_screen_list() {
  screen -ls 2>/dev/null | awk '
    /^[[:space:]]*[0-9]+\./ {
      gsub(/^[[:space:]]+/, "", $1)
      print $1
    }'
}

print_screen_list() {
  local sessions
  sessions="$(get_screen_list)"
  if [[ -z "${sessions}" ]]; then
    echo -e "${YELLOW}⚠ Активных screen-сессий нет.${NC}"
    return 1
  fi

  echo -e "${GREEN}${BOLD}📋 Список screen-сессий:${NC}"
  echo
  local i=1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo -e " ${CYAN}[$i]${NC} ${WHITE}$line${NC}"
    ((i++))
  done <<< "$sessions"
  echo
  return 0
}

select_session() {
  local sessions_array=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && sessions_array+=("$line")
  done < <(get_screen_list)

  if [[ ${#sessions_array[@]} -eq 0 ]]; then
    echo
    echo -e "${YELLOW}⚠ Нет доступных сессий.${NC}"
    return 1
  fi

  echo -e "${GREEN}${BOLD}🎯 Выберите сессию:${NC}"
  local i
  for i in "${!sessions_array[@]}"; do
    echo -e " ${CYAN}[$((i+1))]${NC} ${WHITE}${sessions_array[$i]}${NC}"
  done
  echo

  read -rp "Введите номер: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}✖ Ошибка: нужно ввести число.${NC}"
    return 1
  fi

  if (( num < 1 || num > ${#sessions_array[@]} )); then
    echo -e "${RED}✖ Ошибка: неверный номер.${NC}"
    return 1
  fi

  SELECTED_SESSION="${sessions_array[$((num-1))]}"
  return 0
}

create_session() {
  header
  echo -e "${BLUE}${BOLD}➕ Создание новой screen-сессии${NC}"
  echo
  read -rp "Введите имя новой сессии: " sname

  if [[ -z "${sname// }" ]]; then
    echo -e "${RED}✖ Имя не может быть пустым.${NC}"
    pause
    return
  fi

  if screen -ls | grep -q "[[:space:]]*[0-9]\+\.${sname}[[:space:]]"; then
    echo -e "${RED}✖ Сессия с таким именем уже существует.${NC}"
    pause
    return
  fi

  echo -e "${GREEN}✔ Подготавливаю запуск screen -S ${WHITE}${sname}${NC}"
  sleep 1
  show_screen_start_hint
  exec screen -S "$sname" bash -c '
    printf "\033[2J\033[H";
    echo -e "\033[0;36m============================================================\033[0m";
    echo -e "\033[1;37m                 Добро пожаловать в screen\033[0m";
    echo -e "\033[0;36m============================================================\033[0m";
    echo;
    echo -e "\033[1;33mПолезные команды:\033[0m";
    echo -e " \033[0;35m⎋ Выйти без остановки сессии:\033[0m \033[1;37mCtrl+A затем D\033[0m";
    echo -e " \033[0;32m➕ Новое окно:\033[0m              \033[1;37mCtrl+A затем C\033[0m";
    echo -e " \033[0;32m➡ Следующее окно:\033[0m         \033[1;37mCtrl+A затем N\033[0m";
    echo -e " \033[0;32m⬅ Предыдущее окно:\033[0m        \033[1;37mCtrl+A затем P\033[0m";
    echo -e " \033[0;32m📋 Список окон:\033[0m            \033[1;37mCtrl+A затем \"\033[0m";
    echo -e " \033[0;32m🛑 Завершить текущее окно:\033[0m \033[1;37mexit\033[0m";
    echo;
    echo -e "\033[0;36m============================================================\033[0m";
    echo;
    exec bash
  '
}

create_detached_with_command() {
  header
  echo -e "${BLUE}${BOLD}🚀 Создание detached-сессии с командой${NC}"
  echo
  read -rp "Введите имя новой сессии: " sname
  read -rp "Введите команду для запуска: " cmd

  if [[ -z "${sname// }" || -z "${cmd// }" ]]; then
    echo -e "${RED}✖ Имя и команда не должны быть пустыми.${NC}"
    pause
    return
  fi

  screen -dmS "$sname" bash -lc "$cmd; echo; echo 'Команда завершена. Нажмите Enter или закройте окно.'; read -r"
  echo -e "${GREEN}✔ Сессия ${WHITE}${sname}${GREEN} создана и запущена в фоне.${NC}"
  pause
}

attach_session() {
  header
  print_screen_list || { pause; return; }
  select_session || { pause; return; }

  echo -e "${GREEN}✔ Подключение к ${WHITE}${SELECTED_SESSION}${NC}"
  sleep 1
  exec screen -r "$SELECTED_SESSION"
}

force_attach_session() {
  header
  print_screen_list || { pause; return; }
  select_session || { pause; return; }

  echo -e "${GREEN}✔ Принудительное переподключение к ${WHITE}${SELECTED_SESSION}${NC}"
  sleep 1
  exec screen -dr "$SELECTED_SESSION"
}

kill_session() {
  header
  print_screen_list || { pause; return; }
  select_session || { pause; return; }

  echo
  read -rp "Точно завершить ${SELECTED_SESSION}? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    screen -S "$SELECTED_SESSION" -X quit
    echo -e "${GREEN}✔ Сессия завершена.${NC}"
  else
    echo -e "${YELLOW}⚠ Отменено.${NC}"
  fi
  pause
}

rename_session() {
  header
  print_screen_list || { pause; return; }
  select_session || { pause; return; }

  read -rp "Введите новое имя для ${SELECTED_SESSION}: " newname
  if [[ -z "${newname// }" ]]; then
    echo -e "${RED}✖ Имя не может быть пустым.${NC}"
    pause
    return
  fi

  screen -S "$SELECTED_SESSION" -X sessionname "$newname"
  echo -e "${GREEN}✔ Сессия переименована в ${WHITE}${newname}${NC}"
  pause
}

show_detailed_info() {
  header
  echo -e "${BLUE}${BOLD}ℹ Подробная информация${NC}"
  echo
  screen -ls || true
  echo
  echo -e "${CYAN}================= ${WHITE}Управление внутри screen${CYAN} =================${NC}"
  echo -e "${YELLOW}⌨ Ctrl+A D${NC}   - отсоединиться"
  echo -e "${YELLOW}⌨ Ctrl+A C${NC}   - создать новое окно"
  echo -e "${YELLOW}⌨ Ctrl+A N${NC}   - следующее окно"
  echo -e "${YELLOW}⌨ Ctrl+A P${NC}   - предыдущее окно"
  echo -e "${YELLOW}⌨ Ctrl+A \"${NC}   - список окон"
  echo -e "${CYAN}============================================================${NC}"
  pause
}

cleanup_dead_screens() {
  header
  echo -e "${BLUE}${BOLD}🧹 Очистка битых / dead screen-сессий${NC}"
  echo
  screen -wipe
  echo
  pause
}

quick_shell_detached() {
  header
  echo -e "${BLUE}${BOLD}🖥️ Быстрый запуск фоновой shell-сессии${NC}"
  echo
  local ts
  ts="$(date +%d%m%Y-%H%M%S)"
  local sname="shell-${ts}"
  screen -dmS "$sname" bash
  echo -e "${GREEN}✔ Создана detached-сессия: ${WHITE}${sname}${NC}"
  pause
}

show_help_block() {
  echo -e "${CYAN}======================= ${WHITE}Главное меню${CYAN} =======================${NC}"
  echo -e "${GREEN} 1)${NC} 📋 Показать все screen-сессии"
  echo -e "${GREEN} 2)${NC} ➕ Создать новую screen-сессию"
  echo -e "${GREEN} 3)${NC} 🔌 Подключиться к существующей сессии"
  echo -e "${GREEN} 4)${NC} ♻ Принудительно переподключиться (screen -dr)"
  echo -e "${GREEN} 5)${NC} ❌ Завершить сессию"
  echo -e "${GREEN} 6)${NC} ✏ Переименовать сессию"
  echo -e "${GREEN} 7)${NC} 🚀 Создать detached-сессию с командой"
  echo -e "${GREEN} 8)${NC} 🖥️ Быстро создать фоновую shell-сессию"
  echo -e "${GREEN} 9)${NC} 🧹 Очистить dead-сессии (screen -wipe)"
  echo -e "${GREEN}10)${NC} ℹ Показать подробную информацию"
  echo -e "${RED} 0)${NC} 🚪 Выход"
  echo -e "${CYAN}============================================================${NC}"
  echo
}

main_loop() {
  while true; do
    header
    show_help_block
    read -rp "Выберите пункт: " choice
    echo

    case "$choice" in
      1) header; print_screen_list; echo; pause ;;
      2) create_session ;;
      3) attach_session ;;
      4) force_attach_session ;;
      5) kill_session ;;
      6) rename_session ;;
      7) create_detached_with_command ;;
      8) quick_shell_detached ;;
      9) cleanup_dead_screens ;;
      10) show_detailed_info ;;
      0) echo -e "${GREEN}До встречи 👋${NC}"; exit 0 ;;
      *) echo -e "${RED}✖ Неверный пункт меню.${NC}"; pause ;;
    esac
  done
}

main_loop
