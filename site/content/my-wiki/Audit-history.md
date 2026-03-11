# 🛡️ Linux Command Audit + Bash History Logger (Ubuntu 24.04)

Полу-IDS уровень логирования для Linux сервера.

Скрипт автоматически настраивает:

- 🔎 аудит запускаемых команд через **auditd**
- ⌨️ логирование интерактивных **bash-команд**
- 🌍 фиксацию **IP подключений SSH**
- 👤 логирование **root и обычных пользователей**
- 📜 отдельный лог команд `/var/log/commands.log`
- 🗜️ автоматическую **ротацию логов**
- 🌐 опциональную отправку логов на **удалённый syslog**

---

# 🚀 Установка в один клик

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/audit-history.sh)
````

---

# 📥 Альтернативная установка

Скачать скрипт:

```bash
wget -O audit-history.sh https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/audit-history.sh
```

Сделать исполняемым и запустить:

```bash
chmod +x audit-history.sh
sudo ./audit-history.sh
```

---

# 📊 Что начинает логироваться

После установки сервер начинает фиксировать **все интерактивные команды пользователей**.

Пример строки лога:

```text
2026-03-08T11:12:49.459145+03:00 msk-test root:
user=root ip=95.85.249.132 tty=/dev/pts/0 host=msk-test pid=472788 rc=0 cmd=apt update
```

### В лог попадает

| Поле | Описание             |
| ---- | -------------------- |
| user | пользователь         |
| ip   | IP SSH подключения   |
| tty  | терминал             |
| host | hostname сервера     |
| pid  | PID процесса         |
| rc   | код возврата команды |
| cmd  | выполненная команда  |

---

# 📂 Основные файлы системы

## Лог bash команд

```
/var/log/commands.log
```

---

## Правила auditd

```
/etc/audit/rules.d/commands.rules
```

---

## Bash hook

```
/etc/profile.d/history-log.sh
```

---

## Подключение для root

```
/root/.bashrc
```

---

## Конфиг rsyslog

```
/etc/rsyslog.d/10-commands.conf
```

---

## Конфиг удалённого syslog

```
/etc/rsyslog.d/49-remote-forward.conf
```

---

## Ротация логов

```
/etc/logrotate.d/commands-log
```

---

# 🔎 Как смотреть логи

## Смотреть команды пользователей

```bash
tail -f /var/log/commands.log
```

---

## Последние 50 команд

```bash
tail -n 50 /var/log/commands.log
```

---

## Аудит root

```bash
ausearch -k root-commands -i | tail -n 50
```

---

## Аудит обычных пользователей

```bash
ausearch -k user-commands -i | tail -n 50
```

---

## Проверить активные audit правила

```bash
auditctl -l
```

---

# 🧪 Проверка работы

Выполните:

```bash
echo test_history_check
```

Потом:

```bash
tail -n 10 /var/log/commands.log
```

Если строка появилась — всё работает.

---

# 🔄 Управление службами

## Перезапустить auditd

```bash
systemctl restart auditd
```

---

## Перезапустить rsyslog

```bash
systemctl restart rsyslog
```

---

## Перезагрузить audit rules

```bash
augenrules --load
systemctl restart auditd
```

---

# ⚠️ Возможные проблемы

## Лог `/var/log/commands.log` не появляется

Проверьте:

```bash
systemctl status rsyslog
```

И выполните тест:

```bash
logger -p local6.debug "test"
```

Потом:

```bash
tail /var/log/commands.log
```

---

## Bash команды не логируются

Подключите профиль вручную:

```bash
source /etc/profile.d/history-log.sh
source /root/.bashrc
```

---

## Проверить что хук активен

```bash
echo $PROMPT_COMMAND
```

Должно быть:

```
__log_and_sync_history
```

---

# 🌐 Удалённый syslog

Скрипт поддерживает отправку логов на удалённый сервер.

В начале скрипта можно включить:

```bash
REMOTE_SYSLOG_ENABLED="true"
REMOTE_SYSLOG_HOST="192.0.2.10"
REMOTE_SYSLOG_PORT="514"
REMOTE_SYSLOG_PROTOCOL="tcp"
```

Можно отправлять:

* bash команды
* SSH авторизацию
* auditd события

---

# 🧹 Как удалить всё обратно

Если нужно полностью удалить систему логирования.

## Остановить сервисы

```bash
systemctl stop auditd
```

---

## Удалить конфиги

```bash
rm -f /etc/profile.d/history-log.sh
rm -f /etc/rsyslog.d/10-commands.conf
rm -f /etc/rsyslog.d/49-remote-forward.conf
rm -f /etc/audit/rules.d/commands.rules
rm -f /etc/logrotate.d/commands-log
```

---

## Удалить лог

```bash
rm -f /var/log/commands.log
```

---

## Перезапустить rsyslog

```bash
systemctl restart rsyslog
```

---

# 📌 Для чего это полезно

Этот инструмент помогает:

* расследовать действия пользователей
* фиксировать действия администраторов
* отслеживать взломы
* вести аудит безопасности
* анализировать ошибки администрирования

По сути это **микро IDS уровня сервера**.

---

# ⚙️ Совместимость

| Система      | Статус      |
| ------------ | ----------- |
| Ubuntu 24.04 | ✅ Tested    |
| Ubuntu 22.04 | ⚠️ Possible |
| Debian 12    | ⚠️ Possible |

---

# ⭐ Быстрая памятка

Установка:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/audit-history.sh)
```

Просмотр логов:

```bash
tail -f /var/log/commands.log
```

Аудит root:

```bash
ausearch -k root-commands -i
```

---

# 🔐 Безопасность

Система **не логирует типичные секреты**, например:

```
password
token
apikey
secret
Authorization
```

Это снижает риск утечки чувствительных данных в логах.

---

# 📜 Лицензия

Free to use.
