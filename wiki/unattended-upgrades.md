# unattended-upgrades в Ubuntu 24.04 LTS и новее

Практическое руководство администратора: установка, политика обновлений, расписание, перезагрузки, needrestart, nginx, Docker и диагностика.

**Дата проверки документации: 24 октября 2026 года.** Основной пример — Ubuntu Server 24.04 LTS (noble). Для более новых выпусков сначала сверяйте установленные версии пакетов, локальные man-страницы и unit-файлы. Команды из файла не выполнялись на ваших серверах.

## Содержание

1. [Назначение и границы](#1-назначение-и-границы)
2. [Особенности Ubuntu 24.04 и новых выпусков](#2-особенности-ubuntu-2404-и-новых-выпусков)
3. [Компоненты и файлы](#3-компоненты-и-файлы)
4. [Первичный аудит без изменений](#4-первичный-аудит-без-изменений)
5. [Резервная копия настроек](#5-резервная-копия-настроек)
6. [Установка и включение](#6-установка-и-включение)
7. [Готовая базовая политика](#7-готовая-базовая-политика)
8. [Репозитории и происхождение пакетов](#8-репозитории-и-происхождение-пакетов)
9. [Симуляция и первый запуск](#9-симуляция-и-первый-запуск)
10. [Расписание systemd](#10-расписание-systemd)
11. [Перезагрузка ОС](#11-перезагрузка-ос)
12. [needrestart и рестарты сервисов](#12-needrestart-и-рестарты-сервисов)
13. [nginx и проверка исправлений](#13-nginx-и-проверка-исправлений)
14. [Docker, Remnawave и Xray](#14-docker-remnawave-и-xray)
15. [Исключения и hold](#15-исключения-и-hold)
16. [Журналы и уведомления](#16-журналы-и-уведомления)
17. [Диагностика](#17-диагностика)
18. [Отключение и возврат настроек](#18-отключение-и-возврат-настроек)
19. [Практическая политика для VPN-флота](#19-практическая-политика-для-vpn-флота)
20. [Частые вопросы](#20-частые-вопросы)
21. [Итоговая проверка](#21-итоговая-проверка)
22. [Официальные источники](#22-официальные-источники)

---

## 1. Назначение и границы

`unattended-upgrades` автоматически устанавливает обновления DEB-пакетов из разрешённых источников APT. Это не менеджер всех приложений сервера.

| Объект | Что делает unattended-upgrades |
|---|---|
| nginx, OpenSSL, OpenSSH из разрешённых APT-источников | Может обновлять установленные пакеты |
| Ядро, установленное пакетами Ubuntu | Может установить обновление; переход на новое ядро обычно требует reboot |
| nginx из стороннего APT-репозитория | Только если его источник отдельно разрешён и версия подходит политике APT |
| Docker Engine из APT | Зависит от происхождения пакета и политики источников |
| Образ nginx/Remnawave/Xray в Docker | Не обновляет образ и не пересоздаёт контейнер |
| Бинарник Xray, скачанный вручную | Не обновляет |
| Snap, Flatpak, Python venv, npm | Управляются своими механизмами |
| Переход Ubuntu 24.04 → 26.04 | Не выполняет; это отдельный release upgrade |

**Четыре разных события:**

1. Установлен новый пакет на диск.
2. Перезапущена служба, чтобы использовать новый код или библиотеки.
3. Пересоздан контейнер из нового образа.
4. Перезагружен сервер, например для нового ядра.

Одно событие не гарантирует остальные. Особенно важно: `Automatic-Reboot "false"` запрещает автоматическую перезагрузку средствами unattended-upgrades, но не запрещает рестарты служб.

## 2. Особенности Ubuntu 24.04 и новых выпусков

### Ubuntu 24.04 LTS

В Ubuntu 24.04 изменилось поведение `needrestart` при APT-транзакциях: затронутые службы могут автоматически перезапускаться и при интерактивных, и при фоновых обновлениях. Обновление общей библиотеки способно затронуть сервис, пакет которого непосредственно не обновлялся. См. источник [2].

Например: unattended-upgrades обновляет библиотеку → needrestart обнаруживает процесс со старой библиотекой → выполняется рестарт службы → часть клиентских соединений может оборваться. Reboot ОС при этом не нужен.

### Ubuntu новее 24.04

- Не копируйте codename `noble` в конфигурацию другого выпуска. Используйте поддерживаемые подстановки `${distro_id}` и `${distro_codename}`.
- После обновления выпуска повторно проверяйте APT-hook needrestart, параметры таймеров и итоговый `apt-config dump`.
- Используйте только поддерживаемый выпуск: больший номер версии сам по себе не означает наличие действующих security-обновлений.
- В документации Ubuntu описана возможность отсрочки обновлений пользователем начиная с 25.04 (`Postpone-For-Days`). Это отдельная функция с зависимостью от версии пакета и механизма уведомлений; не включайте её на 24.04 по аналогии. Для headless VPN-сервера понятнее управлять расписанием и окнами обслуживания.

Проверка выпуска:

```bash
cat /etc/os-release
uname -r
apt-cache policy unattended-upgrades apt needrestart
```

Точный статус поддержки проверяйте по [9], а не только по дате в этом руководстве.

## 3. Компоненты и файлы

| Компонент / путь | Для чего нужен |
|---|---|
| `apt-daily.timer` | Планирует обновление индексов/фоновые действия APT |
| `apt-daily.service` | Исполняет соответствующее действие |
| `apt-daily-upgrade.timer` | Планирует запуск обновлений |
| `apt-daily-upgrade.service` | Запускает установку через механизм APT periodic |
| `/usr/lib/apt/apt.systemd.daily` | Проверяет периодичность, отметки времени и настройки |
| `/etc/apt/apt.conf.d/20auto-upgrades` | Обычно включает периодические действия |
| `/etc/apt/apt.conf.d/50unattended-upgrades` | Поставляемые настройки unattended-upgrades |
| `/etc/apt/apt.conf.d/99zz-local-unattended-upgrades` | Локальная политика из этого руководства |
| `/etc/apt/apt.conf.d/99needrestart` | APT-hook needrestart, если установлен |
| `/etc/needrestart/conf.d/` | Локальные настройки needrestart |
| `/var/log/unattended-upgrades/` | Журналы автоматических обновлений |
| `/var/log/apt/history.log` | История APT-транзакций |
| `/var/log/dpkg.log` | Изменения состояния пакетов |
| `/var/lib/apt/periodic/` | Отметки времени периодических действий |
| `/run/reboot-required` | Признак рекомендованной перезагрузки, если создан пакетами |
| `unattended-upgrades.service` | На типовой Ubuntu — компонент координации завершения работы; проверяйте `systemctl cat`, это не основной планировщик |

**Не редактируйте vendor unit-файлы в `/usr/lib/systemd/system` или `/lib/systemd/system`.** Используйте drop-in в `/etc/systemd/system`.

APT читает фрагменты конфигурации по имени; позднее скалярное значение обычно заменяет раннее. Списки могут дополняться, а не заменяться. Для их явного сброса применяется `#clear`. `/etc/apt/apt.conf` и параметры командной строки тоже могут влиять на результат. Проверяйте итог, а не один файл. См. [4].

## 4. Первичный аудит без изменений

Команды ниже читают состояние. Отсутствие необязательного пакета или файла допустимо.

```bash
hostnamectl
timedatectl
cat /etc/os-release
dpkg-query -W unattended-upgrades apt needrestart
systemctl list-timers --all apt-daily.timer apt-daily-upgrade.timer
systemctl cat apt-daily.timer apt-daily-upgrade.timer
systemctl cat apt-daily.service apt-daily-upgrade.service
systemctl status apt-daily.service apt-daily-upgrade.service --no-pager
```

Для завершившегося oneshot-сервиса `inactive (dead)` может быть нормой. Посмотрите последнюю ошибку и расписание, а не только active/inactive.

```bash
apt-config dump | grep -E 'APT::Periodic|Unattended-Upgrade'
sudo grep -RnsE 'APT::Periodic|Unattended-Upgrade' /etc/apt/apt.conf.d/ /etc/apt/apt.conf 2>/dev/null
sudo cat /etc/apt/apt.conf.d/99needrestart
sudo grep -RnsE 'restart|override_rc' /etc/needrestart/needrestart.conf /etc/needrestart/conf.d/ 2>/dev/null
apt-mark showhold
df -h / /var /boot
df -i / /var
free -h
```

Не публикуйте полный вывод APT-конфигурации без просмотра: в общей конфигурации могут присутствовать адреса прокси и данные частных репозиториев.

## 5. Резервная копия настроек

**Изменяет файловую систему:** создаёт копии, ничего не обновляет.

Выполните блок в одной shell-сессии. Переменная `uu_backup_dir` используется дальше при ручном восстановлении.

```bash
uu_backup_dir="/root/backup-unattended-$(date +%Y%m%d-%H%M%S)"
sudo install -d -m 700 "$uu_backup_dir"
sudo cp -a /etc/apt/apt.conf.d "$uu_backup_dir/"
if [ -f /etc/apt/apt.conf ]; then
  sudo cp -a /etc/apt/apt.conf "$uu_backup_dir/"
fi
if [ -d /etc/needrestart ]; then
  sudo cp -a /etc/needrestart "$uu_backup_dir/"
fi
sudo systemctl cat apt-daily.timer apt-daily-upgrade.timer | sudo tee "$uu_backup_dir/apt-timers-before.txt" >/dev/null
sudo apt-config dump | sudo tee "$uu_backup_dir/apt-config-before.txt" >/dev/null
sudo chmod -R go-rwx "$uu_backup_dir"
echo "Копия: $uu_backup_dir"
```

Если уже есть локальные drop-in таймеров, сохраните их отдельно:

```bash
if [ -d /etc/systemd/system/apt-daily.timer.d ]; then
  sudo cp -a /etc/systemd/system/apt-daily.timer.d "$uu_backup_dir/"
fi
if [ -d /etc/systemd/system/apt-daily-upgrade.timer.d ]; then
  sudo cp -a /etc/systemd/system/apt-daily-upgrade.timer.d "$uu_backup_dir/"
fi
```

Копия конфигурации не заменяет резервную копию данных и не откатывает версии пакетов.

## 6. Установка и включение

**Изменяет систему.** Установка пакетов может запускать APT-hooks и рестарты служб уже на этом шаге. На рабочем сервере выполняйте в согласованное окно, имея консоль провайдера.

```bash
sudo apt update
sudo apt install unattended-upgrades
```

В стандартной Ubuntu пакет часто уже установлен. В минимальном VPS-образе состояние может отличаться.

Интерактивный способ включения:

```bash
sudo dpkg-reconfigure unattended-upgrades
```

Либо явно задайте периодичность через файл следующего раздела. Если используете локальный файл, его значения могут перекрыть результат `dpkg-reconfigure`.

`needrestart` проверяйте отдельно; если отсутствует, при необходимости установите его в окно обслуживания:

```bash
sudo apt install needrestart
```

## 7. Готовая базовая политика

**Предлагаемый профиль для начала:** ежедневные security-обновления Ubuntu, без автоматического reboot, без автоматического удаления зависимостей. Рестарты служб регулируются отдельно (§12).

Пример ниже намеренно **заменяет** списки источников на Ubuntu base + security и очищает `Origins-Pattern`, чтобы не оставить незаметное разрешение сторонних источников. Base release добавлен для возможных зависимостей; `-updates` и `-backports` не разрешены. ESM здесь не включён — если используете Ubuntu Pro, добавьте нужные источники после проверки §8.

**Изменяет политику APT:**

```bash
sudo tee /etc/apt/apt.conf.d/99zz-local-unattended-upgrades >/dev/null <<'EOF'
// Локальная политика. Подстановки раскрывает unattended-upgrades.
APT::Periodic::Enable "1";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";

#clear Unattended-Upgrade::Allowed-Origins;
#clear Unattended-Upgrade::Origins-Pattern;
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
};

Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "false";
Unattended-Upgrade::Remove-New-Unused-Dependencies "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "false";
EOF

apt-config dump | grep -E 'APT::Periodic|Unattended-Upgrade'
```

Имя heredoc заключено в кавычки: shell не подставляет `${distro_id}`. Это правильно — значения подставит unattended-upgrades.

Этот файл не очищает существующий `Package-Blacklist`, не снимает hold и не отменяет pinning. Они могут продолжать исключать пакеты.

Файл не требует рестарта демона unattended-upgrades: параметры будут прочитаны при следующем запуске. Таймеры проверьте и при необходимости включите **после** симуляции (§9):

```bash
sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
```

Из-за `Persistent=true` и просроченного календарного события включение таймера может вскоре вызвать запуск. Сначала настройте желаемое расписание, если важен момент установки.

## 8. Репозитории и происхождение пакетов

`apt update` загружает индексы. `apt upgrade` рассматривает кандидатов по общей политике APT. unattended-upgrades дополнительно ограничивает происхождение обновлений. Успех обычного `apt upgrade` не доказывает, что тот же пакет будет установлен автоматически.

### Посмотреть, откуда пакет

```bash
apt-cache policy nginx nginx-common openssl openssh-server
apt-cache policy docker.io docker-ce containerd containerd.io
```

В выводе важны `Installed`, `Candidate` и репозитории доступных версий. В `apt-cache policy` без имени пакета видны поля Release (`o=`, `a=`, `n=`, `l=`), необходимые для настройки Origins-Pattern.

```bash
apt-cache policy
```

Репозиторий задаёт собственные Origin/Label/Suite — имя URL не заменяет эти поля.

### Добавить обычные обновления Ubuntu

Если принято решение устанавливать и `-updates`, добавьте **одну строку в существующий блок** Allowed-Origins локального файла:

```text
"${distro_id}:${distro_codename}-updates";
```

Это расширяет круг автоматически устанавливаемых обновлений и изменений поведения. После изменения выполните dry-run.

### Ubuntu Pro / ESM

```bash
pro status
```

Команда доступна, если установлен клиент Ubuntu Pro. Сверьте фактические источники. Типовые записи из поставляемой конфигурации:

```text
"${distro_id}ESMApps:${distro_codename}-apps-security";
"${distro_id}ESM:${distro_codename}-infra-security";
```

Добавляйте их в тот же блок Allowed-Origins, только когда соответствующие репозитории включены и доступны. Наличие строки не предоставляет подписку Pro и не гарантирует покрытие любого пакета Universe. Проверяйте конкретный пакет и USN.

### Сторонние репозитории

Не включайте все сторонние источники широким правилом. Сначала изучите происхождение и политику совместимости конкретного поставщика. Можно использовать точный Origins-Pattern, основанный на реальных Release-полях, но сначала подготовьте dry-run на одном узле.

**Не смешивайте `noble`, другой codename или старый выпуск ради получения свежего nginx.** Это не настройка автоматических обновлений, а риск несовместимых зависимостей.

## 9. Симуляция и первый запуск

Сначала обновите индексы (изменяет кеш APT, но не устанавливает обновления):

```bash
sudo apt update
```

Затем симуляция:

```bash
sudo unattended-upgrade --dry-run --debug
```

Dry-run не устанавливает обновления, но может читать/создавать диагностические файлы и журналы; это не режим «вообще без записи на диск». Обращайте внимание на `Allowed origins`, список исключений, kept-back и кандидатов. Строки с dpkg в диагностике симуляции сами по себе не означают реальную установку. См. [3].

**Реальная установка — только в выбранное окно:**

```bash
sudo unattended-upgrade --verbose
```

Это немедленный ручной запуск backend, а не ожидание таймера; он способен устанавливать пакеты и вызывать рестарты. Не запускайте параллельно с другой APT-транзакцией.

После завершения:

```bash
sudo tail -n 100 /var/log/unattended-upgrades/unattended-upgrades.log
sudo tail -n 100 /var/log/unattended-upgrades/unattended-upgrades-dpkg.log
systemctl --failed
test -f /run/reboot-required && cat /run/reboot-required
```

Если последний `test` завершился с кодом 1 и ничего не вывел, файла нет — это не сбой установки.

## 10. Расписание systemd

### Сначала узнать реальное расписание

```bash
timedatectl
systemctl cat apt-daily.timer apt-daily-upgrade.timer
systemctl list-timers --all apt-daily.timer apt-daily-upgrade.timer
systemctl show apt-daily-upgrade.timer -p NextElapseUSecRealtime -p LastTriggerUSec
```

Не считайте системный timezone равным вашему местному времени. Все примеры ниже с `UTC` используют UTC: **03:15 UTC = 08:15 Екатеринбург / Новый Уренгой**, **06:15 Москва**. Если нужна другая зона, задайте её явно в OnCalendar или используйте локальное время сервера осознанно.

### Ежедневное окно: индексы 02:45 UTC, установка 03:15 UTC

**Меняет расписание, затем перезапускает только таймеры.** Не заменяет ограничения §7.

```bash
sudo install -d /etc/systemd/system/apt-daily.timer.d
sudo tee /etc/systemd/system/apt-daily.timer.d/90-local-schedule.conf >/dev/null <<'EOF'
[Timer]
OnCalendar=
OnCalendar=*-*-* 02:45:00 UTC
RandomizedDelaySec=0
AccuracySec=1min
Persistent=true
EOF

sudo install -d /etc/systemd/system/apt-daily-upgrade.timer.d
sudo tee /etc/systemd/system/apt-daily-upgrade.timer.d/90-local-schedule.conf >/dev/null <<'EOF'
[Timer]
OnCalendar=
OnCalendar=*-*-* 03:15:00 UTC
RandomizedDelaySec=0
AccuracySec=1min
Persistent=true
EOF

sudo systemctl daemon-reload
sudo systemctl restart apt-daily.timer apt-daily-upgrade.timer
systemctl list-timers --all apt-daily.timer apt-daily-upgrade.timer
```

Пустой `OnCalendar=` сбрасывает vendor-расписание; без него можно получить несколько запусков. `RandomizedDelaySec=0` убирает случайную задержку **таймера**, а `Persistent=true` разрешает догоняющий запуск после простоя. См. [5].

Возможны другие задержки: занятый APT-lock, загрузка индексов, состояние сети, внутренние проверки periodic, дополнительные drop-in. В старых или изменённых установках проверьте `RandomSleep` в `apt.systemd.daily`. Календарь задаёт момент попытки запуска, а не точное начало/конец установки.

### Если нельзя запускаться после включения днём

В обоих drop-in замените `Persistent=true` на `Persistent=false`, выполните daemon-reload и restart таймеров. Цена — пропущенное окно не будет автоматически догоняться этим таймером. При длительном простое обновления задержатся.

### Проверка календаря

```bash
systemd-analyze calendar '*-*-* 03:15:00 UTC'
systemd-analyze calendar '*-*-* 00,06,12,18:00:00 UTC'
```

### Раз в 6 часов или в 00:00 и 08:00

В соответствующем timer drop-in можно заменить OnCalendar, например:

```ini
OnCalendar=
OnCalendar=*-*-* 00,06,12,18:00:00 UTC
```

Или:

```ini
OnCalendar=
OnCalendar=*-*-* 00,08:00:00 UTC
```

**Важно:** при `APT::Periodic::Unattended-Upgrade "1"` более частый запуск таймера не означает установку каждые 6 часов: periodic проверяет отметки времени. Если реально нужна такая периодичность, изучите поддержку значения `always` в установленном `/usr/lib/apt/apt.systemd.daily`, согласованно настройте обновление индексов и сначала испытайте на одном узле. Не удаляйте stamp-файлы как постоянный способ обхода периодичности.

Для нескольких серверов распределяйте окна: A — 03:15 UTC, B — 03:45, origin — 04:15; либо задавайте небольшую случайную задержку. Числа — пример, а не универсальное безопасное окно.

## 11. Перезагрузка ОС

### Проверить необходимость

```bash
if [ -f /run/reboot-required ]; then
  cat /run/reboot-required
  if [ -f /run/reboot-required.pkgs ]; then
    cat /run/reboot-required.pkgs
  fi
else
  echo 'Флаг reboot-required отсутствует'
fi
uname -r
```

Отсутствие флага не доказывает, что все процессы уже используют обновлённые библиотеки.

### Оставить reboot ручным

В локальной политике:

```text
Unattended-Upgrade::Automatic-Reboot "false";
```

После установки обновлений выберите окно, проверьте резервный доступ и выполните `sudo reboot` вручную. Эта команда немедленно прервёт сеанс и соединения.

### Разрешить автоматический reboot по необходимости

Это **альтернативный профиль**, не добавляйте его одновременно с противоположным значением без понимания порядка файлов:

```text
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "04:30";
```

Время reboot задаётся в локальном времени сервера. Это не отдельный ежедневный reboot-таймер: unattended-upgrades должен выполнить запуск, увидеть необходимость и запланировать reboot. Если указанное время уже прошло, может быть выбрано следующее наступление времени. Проверьте поведение локальной версии.

`WithUsers=false` относится к обнаруживаемым пользовательским сеансам; VPN-клиенты и TCP-соединения не эквивалентны вошедшим пользователям. На VPN-узле отсутствие SSH-сеанса не означает отсутствие клиентов.

Для серверов A/B/origin первоначально лучше оставить reboot ручным и обновлять роли последовательно. Livepatch — отдельный механизм для части исправлений ядра, не универсальная замена reboot.

## 12. needrestart и рестарты сервисов

### Откуда берётся неожиданный рестарт

Есть минимум три независимых причины:

1. Maintainer scripts обновляемого пакета сами вызывают действия над его службой.
2. `needrestart` перезапускает процессы после замены используемых библиотек.
3. Собственный deploy/hook/скрипт администратора перезапускает сервис.

Управление needrestart не блокирует автоматически первые и третьи причины.

### Посмотреть, какие процессы требуют обновления

```bash
sudo needrestart -r l
```

Это режим списка для **данного ручного вызова**, не изменение будущего поведения APT. Вывод зависит от версии и установленных компонентов.

### Исключить конкретные службы из автоперезапуска needrestart

Сначала выясните реальные unit names:

```bash
systemctl list-units --type=service --all | grep -E 'nginx|docker|containerd|xray|remna'
```

Пример исключений для systemd-служб nginx и Docker на хосте:

```bash
sudo install -d /etc/needrestart/conf.d
sudo tee /etc/needrestart/conf.d/99-local-critical-services.conf >/dev/null <<'EOF'
# Исключения только для needrestart; перезапуск в окно выполняется вручную.
$nrconf{override_rc}{qr(^nginx\.service$)} = 0;
$nrconf{override_rc}{qr(^docker\.service$)} = 0;
$nrconf{override_rc}{qr(^containerd\.service$)} = 0;
EOF

sudo perl -c /etc/needrestart/conf.d/99-local-critical-services.conf
sudo needrestart -r l
```

Добавление отдельных ключей сохраняет другие записи `override_rc`; полная замена хеша могла бы их стереть. Такой способ исключений описан Canonical [2]. Контейнер с именем `remnanode` не становится автоматически systemd-службой `remnanode.service`.

**Цена исключения:** процессы могут продолжать использовать уязвимый код. Назначьте ручной restart в ближайшее окно и проверку после него. Не превращайте исключение в бессрочный запрет.

### Почему `$nrconf{restart} = 'l'` не универсальный рецепт

В Ubuntu 24.04 APT-hook может вызывать needrestart с `-m u`. Поэтому одного параметра в needrestart.conf недостаточно, чтобы без проверки обещать «службы больше не рестартуют». Прочитайте фактический hook:

```bash
sudo cat /etc/apt/apt.conf.d/99needrestart
sudo grep -RnsE 'needrestart|-m u|NEEDRESTART' /etc/apt/apt.conf.d/ /etc/needrestart/ 2>/dev/null
```

Canonical описывает изменение hook с удалением `-m u` как способ вернуть прежнее поведение. Это изменение пакетного файла; делайте его только осознанно, с копией и повторной проверкой после обновления пакета. В этом руководстве предпочтение отдано точечным исключениям и окну обслуживания.

Не удаляйте needrestart только ради исчезновения сообщений. `DEBIAN_FRONTEND=noninteractive` также не означает запрет рестартов.

## 13. nginx и проверка исправлений

### Определить, какой nginx обслуживает трафик

```bash
command -v nginx
nginx -v
dpkg-query -W -f='${Package}\t${Version}\n' 'nginx*'
apt-cache policy nginx nginx-common
systemctl status nginx --no-pager
sudo ss -ltnp
```

Если nginx в Docker, дополнительно смотрите §14. Ubuntu-пакет на хосте может вообще не участвовать в обработке ваших подключений.

### Почему `nginx -v` мало

Ubuntu переносит исправления в стабильные версии пакета. Базовая версия вроде `1.24.0` может сохраниться после security-патчей; сравнивайте **полную DEB-версию**, выпуск Ubuntu и исправленную версию из конкретного Ubuntu Security Notice. Исправление для одного выпуска не переносится в другой сравнением последней цифры ревизии.

```bash
dpkg-query -W -f='${Version}\n' nginx
apt-cache policy nginx
apt changelog nginx
```

`apt changelog` требует доступа к источнику changelog и не является самостоятельным доказательством состояния работающего процесса. Точные CVE и номера исправленных пакетов проверяйте на [7], не используйте старое сообщение в чате как источник истины.

### После обновления

```bash
sudo nginx -t
systemctl status nginx --no-pager
systemctl show nginx -p MainPID -p ExecMainStartTimestamp -p ActiveEnterTimestamp
sudo journalctl -u nginx --since '2 hours ago' --no-pager
sudo needrestart -r l
```

Затем проверьте настоящий VPN-путь, а не только страницу `/`: успешный ответ декоя не доказывает работу XHTTP.

`nginx -s reload` / `systemctl reload nginx` перечитывает конфигурацию и меняет workers, но **не является универсальной заменой обновления исполняемого кода master-процесса**. Для гарантированного запуска нового бинарника обычно планируют restart или документированное обновление бинарника на лету. Последнее здесь не рассматривается.

Ручной `sudo systemctl restart nginx` может прервать длинные потоки XHTTP. Выполняйте после проверки конфигурации и переключения клиентов на резерв, если он есть.

## 14. Docker, Remnawave и Xray

### Два слоя обновлений

```text
Ubuntu хоста → APT → unattended-upgrades
Контейнеры → образы поставщика → pull + контролируемое пересоздание
```

Обновление `openssl` на хосте не обновляет автоматически библиотеки внутри образа контейнера. Ядро хоста при этом общее с обычными Linux-контейнерами. Bind mounts и приложения, использующие файлы хоста, требуют отдельной оценки.

### Инвентаризация

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
docker images --digests
docker info --format '{{.LiveRestoreEnabled}}'
apt-cache policy docker-ce docker.io containerd.io containerd
```

Для конкретного nginx-контейнера после замены placeholder:

```bash
docker exec NGINX_CONTAINER nginx -v
```

Не выполняйте `docker inspect` без отбора полей для публичного отчёта: env могут содержать токены.

### Что не происходит автоматически

- `apt upgrade` не выполняет `docker compose pull`.
- `docker compose pull` только скачивает образ, не обновляет запущенный контейнер.
- `restart` контейнера запускает тот же контейнер, не заменяет его новым образом.
- Тег `latest` не означает, что уже запущенный контейнер сам получил последний образ.

Обновление образов — отдельный deploy: резервная копия данных → изучение release notes/миграций → получение образа → пересоздание → проверка → сохранённый план возврата. Не копируйте бездумно `docker compose down -v`: удаление volumes может уничтожить данные.

### Обновление Docker Engine

APT-обновление Docker Engine или containerd способно повлиять на работающие контейнеры. `live-restore` уменьшает простой при некоторых сценариях, но имеет ограничения по версиям и конфигурации; не гарантирует сохранение VPN-сессий. Проверяйте его по [6].

Для Remnawave/Xray отдельно контролируйте:

1. Ubuntu и nginx хоста.
2. Docker Engine/containerd.
3. Образ panel/node и версию реально запущенного Xray.
4. Подписки и совместимость клиентов.
5. Сквозную сессию, включая длинный download.

Обновлять эти слои одновременно без необходимости неудобно для диагностики. На узлах с малой RAM сначала смотрите `MemAvailable`, swap, OOM и место на диске, а не только колонку `free`.

## 15. Исключения и hold

### Исключить пакет только из unattended-upgrades

Пример временной блокировки nginx-пакетов в локальной APT-конфигурации:

```text
Unattended-Upgrade::Package-Blacklist {
    "^nginx$";
    "^nginx-.*";
    "^libnginx-mod-.*";
};
```

Это регулярные выражения. Проверяйте реальные имена установленных пакетов. Другие библиотеки всё равно могут обновиться; needrestart может затронуть nginx (§12).

Если обновление исключено, security-исправление не будет установлено автоматически. Запишите причину, ответственного и дату ручного обновления.

### apt-mark hold

```bash
sudo apt-mark hold nginx nginx-common
apt-mark showhold
```

Hold влияет шире, чем blacklist unattended-upgrades: он мешает обычным автоматическим решениям APT обновлять пакет. Это не защита от любой явно принудительной команды администратора.

Снять hold:

```bash
sudo apt-mark unhold nginx nginx-common
```

Снятие hold не убирает blacklist, pinning или проблемы зависимостей. И наоборот.

## 16. Журналы и уведомления

### Основные журналы

```bash
sudo tail -n 100 /var/log/unattended-upgrades/unattended-upgrades.log
sudo tail -n 100 /var/log/unattended-upgrades/unattended-upgrades-dpkg.log
sudo journalctl -u apt-daily.service -u apt-daily-upgrade.service --since yesterday --no-pager
sudo less /var/log/apt/history.log
sudo less /var/log/dpkg.log
```

Ротированные журналы могут быть сжаты. Если файлы есть:

```bash
sudo zgrep -hE 'Start-Date|Commandline|Upgrade:|End-Date' /var/log/apt/history.log*.gz
```

Чтобы выяснить причину рестарта, сопоставьте время APT/dpkg с журналом нужной службы. Совпадение по времени — подсказка, а не окончательное доказательство.

### Email

При настроенной исходящей почте можно добавить в локальный файл:

```text
Unattended-Upgrade::Mail "admin@example.com";
Unattended-Upgrade::MailReport "on-change";
```

`admin@example.com` — placeholder. Выберите режим, поддерживаемый вашей версией (`always`, `only-on-error`, `on-change`), и проверьте доставку. Одна строка Mail без MTA/доступного почтового транспорта не отправит письмо.

Для Telegram/мониторинга лучше использовать существующий защищённый механизм уведомлений: не вставляйте токен бота в общедоступный файл или командную строку. Контролируйте не только наличие ошибок, но и отсутствие успешных запусков несколько дней.

## 17. Диагностика

### «Пакет не обновляется»

```bash
sudo apt update
apt-cache policy PACKAGE_NAME
apt-mark showhold
apt-config dump | grep -E 'APT::Periodic|Unattended-Upgrade'
sudo unattended-upgrade --dry-run --debug
```

По порядку проверьте: источник разрешён → есть подходящая версия → нет hold/blacklist/pinning → зависимости решаются → репозиторий доступен → конфигурационный файл не требует ручного решения. Кандидат из неразрешённого `-updates` тоже может влиять на результат; решайте по debug, не включайте все источники вслепую.

### «Таймер включён, но установки нет»

```bash
systemctl list-timers --all apt-daily.timer apt-daily-upgrade.timer
systemctl cat apt-daily-upgrade.timer apt-daily-upgrade.service
sudo journalctl -u apt-daily-upgrade.service --since '3 days ago' --no-pager
sudo ls -l /var/lib/apt/periodic/
```

Возможны отсутствие обновлений, периодический интервал ещё не истёк, disable в позднем конфиге, другое окно, недоступная сеть, ошибка APT. `enabled` не равно «последний запуск успешен».

### «Could not get lock»

```bash
ps -eo pid,etime,cmd | grep -E '[a]pt|[d]pkg|[u]nattended'
systemctl status apt-daily.service apt-daily-upgrade.service --no-pager
```

Дождитесь текущей транзакции и изучите журнал. **Не удаляйте lock-файлы и не применяйте `kill -9` к dpkg ради ускорения.** Наличие файла само по себе не доказывает удерживаемую блокировку.

Если APT действительно аварийно прервался, процессов установки уже нет и окно обслуживания открыто, восстановление может потребовать:

```bash
sudo dpkg --configure -a
sudo apt-get -f install
```

Обе команды изменяют систему и способны вызвать рестарты. Сначала посмотрите, что предлагает APT, не добавляйте `-y` автоматически.

### «Обновление требует решения по конфигу»

Сравните локальный и пакетный конфиг вручную, сохраните копии, проверьте синтаксис и завершите обновление в окно. Универсальные `--force-confnew` или `--force-confold` могут соответственно потерять ваши настройки или оставить несовместимый старый конфиг; это не базовый рецепт.

### «Закончился /boot или диск»

```bash
df -h / /var /boot
df -i / /var
dpkg-query -W 'linux-image*'
uname -r
sudo apt-get -s autoremove
```

Последняя команда — симуляция. Не удаляйте вручную текущее ядро и случайные файлы `/boot`. Сохраните рабочий резервный вариант; фактическое удаление выполняйте после просмотра списка.

### «Сервер или VPN упал после обновления»

Зафиксируйте время и слой отказа. Проверьте:

```bash
uptime -s
last -x | head -n 20
systemctl --failed
sudo journalctl -b -p err --no-pager
sudo journalctl -k --since '2 hours ago' --no-pager
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

Отличайте reboot, рестарт nginx, рестарт Docker, замену контейнера, OOM и внешнюю сетевую проблему. Не откатывайте весь сервер только по совпадению времени с APT.

## 18. Отключение и возврат настроек

### Временно запретить только автоматическую установку

В локальном файле измените:

```text
APT::Periodic::Unattended-Upgrade "0";
```

Можно сохранить `Update-Package-Lists "1"`, чтобы индексы обновлялись. Не добавляйте второй конфликтующий файл, если проще изменить уже созданную локальную политику. Проверьте `apt-config dump`.

Это не отменяет уже запущенную транзакцию и не запрещает ручной `unattended-upgrade`.

### Остановить будущие запуски таймеров

```bash
sudo systemctl disable --now apt-daily-upgrade.timer
```

При необходимости остановить и периодическое обновление индексов:

```bash
sudo systemctl disable --now apt-daily.timer
```

Остановка таймера не останавливает уже работающий сервис. На нестандартных установках проверьте cron и другие средства управления пакетами. Не отключайте только `unattended-upgrades.service` в надежде остановить расписание.

### Вернуть работу

Верните `Unattended-Upgrade "1"`, выполните dry-run, затем:

```bash
sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
```

### Удалить только расписание из этого руководства

```bash
sudo rm -f /etc/systemd/system/apt-daily.timer.d/90-local-schedule.conf
sudo rm -f /etc/systemd/system/apt-daily-upgrade.timer.d/90-local-schedule.conf
sudo systemctl daemon-reload
sudo systemctl restart apt-daily.timer apt-daily-upgrade.timer
systemctl cat apt-daily.timer apt-daily-upgrade.timer
```

Не используйте общий `systemctl revert`, если в drop-in есть чужие необходимые настройки. Если одноимённые файлы существовали до работы, восстановите копии вместо удаления.

### Вернуть локальную политику и исключения

Восстановите соответствующие файлы из своей копии. Если локальные файлы были созданы впервые этим руководством, их можно удалить после просмотра:

```bash
sudo rm -f /etc/apt/apt.conf.d/99zz-local-unattended-upgrades
sudo rm -f /etc/needrestart/conf.d/99-local-critical-services.conf
apt-config dump | grep -E 'APT::Periodic|Unattended-Upgrade'
```

Возврат настроек **не возвращает старые версии пакетов**. Для downgrade требуется отдельная оценка зависимостей, доступности версий, данных и security-риска; иногда правильнее исправить конфигурацию или восстановить резервную копию.

## 19. Практическая политика для VPN-флота

Ниже — предложение для инфраструктуры с nginx на Ubuntu и Remnawave/Xray в контейнерах, а не подтверждение текущих настроек ваших узлов.

| Решение | Стартовый вариант |
|---|---|
| Ubuntu security-пакеты | Автоматически в разнесённые окна |
| Автоматический reboot | Выключен до проверки восстановления и резерва |
| Рестарты критичных служб | Окно обслуживания; при необходимости точечные исключения needrestart с ручным завершением |
| Docker Engine / containerd | Отдельный контролируемый этап с пониманием источника пакета |
| Remnawave/Xray/контейнерный nginx | Отдельное обновление образов и e2e-проверка |
| Все серверы сразу | Сначала один проверочный узел, затем небольшие группы |
| Здоровье VPN | Реальная сессия и доступ к цели, не только порт 443 или статус online |

Для XHTTP Split A/B → origin обновление любого обязательного участника может оборвать сессию. Разделение направлений не даёт избыточности само по себе. Нужен заранее проверенный альтернативный полный профиль; не обновляйте одновременно A, B и общий origin.

Перед окном: копия конфигов и данных → доступ к консоли провайдера → проверка свободных ресурсов → dry-run → перевод тестового клиента на резерв. После: службы/контейнеры → TLS → XHTTP → открытие сайта → upload/download → потребность reboot.

Не исключайте nginx навсегда только ради непрерывного VPN. Выберите управляемый момент применения исправления и измерьте реальный перерыв.

## 20. Частые вопросы

**Будет ли новая Ubuntu установлена ночью?** Нет, обычный unattended-upgrades не выполняет release upgrade.

**Зачем reboot=false, если сервисы всё равно перезапускаются?** Это разные механизмы. ОС остаётся работающей, но отдельная служба может быть перезапущена пакетным скриптом или needrestart.

**Можно ли гарантировать отсутствие разрывов?** Одними настройками unattended-upgrades — нет. Нужны архитектурный резерв, проверенный клиентский переход и последовательное обслуживание.

**Как часто происходит обновление?** Сочетание календаря timer, случайной задержки, periodic-интервала, отметок времени и доступности пакетов. Смотрите фактические units и журналы.

**Обновится ли nginx в Docker после apt upgrade nginx?** Нет, это другой экземпляр и другой жизненный цикл.

**Почему пакет security не устанавливается?** Возможны hold/blacklist, неразрешённый источник, зависимости, конфликт конфига, недоступный репозиторий или отсутствие поддержки выпуска. Начните с policy и dry-run.

**Можно ли оставлять старое ядро установленным?** Да, разумный резерв полезен. Но контролируйте место и после reboot проверяйте `uname -r`; просто установить новое ядро недостаточно.

**Нужно ли ставить apt-transport-https?** Для современных APT в рассматриваемых Ubuntu поддержка HTTPS уже встроена; это не обязательный шаг настройки unattended-upgrades.

**Почему нет конкретных CVE nginx из переписки?** Номера и исправленные ревизии быстро устаревают и зависят от выпуска. Для решения об исправлении сверяйте текущий официальный USN и полную установленную DEB-версию.

## 21. Итоговая проверка

- [ ] Выпуск Ubuntu поддерживается; версия и timezone записаны.
- [ ] Есть резервный доступ и копия исходных настроек.
- [ ] Понятно, какие nginx/Xray работают на хосте, а какие в контейнерах.
- [ ] Итоговый `apt-config dump` соответствует выбранной политике источников.
- [ ] Hold, blacklist и сторонние репозитории просмотрены.
- [ ] Dry-run завершён, список кандидатов понятен.
- [ ] Расписание проверено через `list-timers`; учтены UTC, jitter и Persistent.
- [ ] Для Ubuntu 24.04 просмотрен реальный APT-hook needrestart.
- [ ] Решение о рестартах служб принято отдельно от решения о reboot.
- [ ] После реального обновления проверены журналы, службы и VPN e2e.
- [ ] Для исключённых пакетов/служб назначено ручное обслуживание.
- [ ] Контейнерные образы имеют отдельный план обновления.

## 22. Официальные источники

Ссылки проверялись при подготовке. Локальные файлы и man-страницы установленной версии имеют приоритет для поведения конкретного сервера.

1. [Ubuntu Server: Automatic updates](https://ubuntu.com/server/docs/how-to/software/automatic-updates/) — устройство механизма, параметры и диагностика.
2. [Canonical: needrestart changes in Ubuntu 24.04](https://discourse.ubuntu.com/t/needrestart-changes-in-ubuntu-24-04-service-restarts/44671) — изменение рестартов, override_rc и APT-hook.
3. [Ubuntu 24.04: unattended-upgrade(8)](https://manpages.ubuntu.com/manpages/noble/man8/unattended-upgrade.8.html) — CLI, dry-run, журналы.
4. [Ubuntu 24.04: apt.conf(5)](https://manpages.ubuntu.com/manpages/noble/man5/apt.conf.5.html) — порядок конфигурации, списки, #clear.
5. [Ubuntu 24.04: systemd.timer(5)](https://manpages.ubuntu.com/manpages/noble/man5/systemd.timer.5.html) — OnCalendar, случайная задержка и Persistent.
6. [Docker: Live restore](https://docs.docker.com/engine/daemon/live-restore/) — поведение контейнеров при остановке/обновлении daemon.
7. [Ubuntu Security Notices](https://ubuntu.com/security/notices) — точные пакеты и security-исправления.
8. [Ubuntu security: Security updates](https://documentation.ubuntu.com/security/security-updates/) — security, ESM и автоматические обновления.
9. [Ubuntu release cycle](https://ubuntu.com/about/release-cycle) — актуальные выпуски и сроки поддержки.

Локально: `man unattended-upgrade`, `man apt.conf`, `man systemd.timer`, `man needrestart`; поставляемый `/etc/apt/apt.conf.d/50unattended-upgrades`; `/usr/lib/apt/apt.systemd.daily`.
