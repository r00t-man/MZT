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

## 🚀 Установка в один клик

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/audit-history.sh)
```

### 📥 Альтернативная установка

```bash
wget -O audit-history.sh https://raw.githubusercontent.com/r00t-man/MZT/refs/heads/main/files/audit-history.sh
chmod +x audit-history.sh
sudo ./audit-history.sh
```

---

## 📊 Что начинает логироваться

После установки сервер начинает фиксировать **все интерактивные команды пользователей**.

Пример строки лога:

```text
2026-03-08T11:12:49.459145+03:00 msk-test root:
user=root ip=203.0.113.1 tty=/dev/pts/0 host=msk-test pid=472788 rc=0 cmd=apt update
```

### В лог попадает

| Поле | Описание             |
| ---- | --------------------- |
| user | пользователь         |
| ip   | IP SSH подключения   |
| tty  | терминал             |
| host | hostname сервера     |
| pid  | PID процесса         |
| rc   | код возврата команды |
| cmd  | выполненная команда  |

---

## 📂 Основные файлы системы

| Файл | Назначение |
|---|---|
| `/var/log/commands.log` | лог bash-команд |
| `/etc/audit/rules.d/commands.rules` | правила auditd |
| `/etc/profile.d/history-log.sh` | bash hook |
| `/root/.bashrc` | подключение для root |
| `/etc/rsyslog.d/10-commands.conf` | конфиг rsyslog |
| `/etc/rsyslog.d/49-remote-forward.conf` | конфиг удалённого syslog |
| `/etc/logrotate.d/commands-log` | ротация логов |

---

## 🔎 Как смотреть логи

```bash
tail -f /var/log/commands.log        # команды пользователей в реальном времени
tail -n 50 /var/log/commands.log     # последние 50 команд
ausearch -k root-commands -i | tail -n 50   # аудит root
ausearch -k user-commands -i | tail -n 50   # аудит обычных пользователей
auditctl -l                          # активные audit-правила
```

---

## 🧪 Проверка работы

```bash
echo test_history_check
tail -n 10 /var/log/commands.log
```

Если строка появилась — всё работает.

---

## 🔄 Управление службами

```bash
systemctl restart auditd
systemctl restart rsyslog
augenrules --load && systemctl restart auditd   # перезагрузить audit-правила
```

---

## ⚠️ Возможные проблемы

> [!NOTE]
> **Лог `/var/log/commands.log` не появляется** — проверьте `systemctl status rsyslog`, затем тест:
> ```bash
> logger -p local6.debug "test"
> tail /var/log/commands.log
> ```

> [!NOTE]
> **Bash-команды не логируются** — подключите профиль вручную:
> ```bash
> source /etc/profile.d/history-log.sh
> source /root/.bashrc
> ```
> Проверить, что хук активен: `echo $PROMPT_COMMAND` — должно быть `__log_and_sync_history`.

---

## 🌐 Удалённый syslog

Скрипт поддерживает отправку логов на удалённый сервер. В начале скрипта можно включить:

```bash
REMOTE_SYSLOG_ENABLED="true"
REMOTE_SYSLOG_HOST="203.0.113.10"
REMOTE_SYSLOG_PORT="514"
REMOTE_SYSLOG_PROTOCOL="tcp"
```

Можно отправлять: bash-команды, SSH-авторизацию, auditd-события.

---

## 🧹 Как удалить всё обратно

```bash
systemctl stop auditd
rm -f /etc/profile.d/history-log.sh \
      /etc/rsyslog.d/10-commands.conf \
      /etc/rsyslog.d/49-remote-forward.conf \
      /etc/audit/rules.d/commands.rules \
      /etc/logrotate.d/commands-log \
      /var/log/commands.log
systemctl restart rsyslog
```

---

## 📌 Для чего это полезно

Помогает расследовать действия пользователей, фиксировать действия администраторов, отслеживать
взломы, вести аудит безопасности и анализировать ошибки администрирования. По сути — микро-IDS
уровня сервера.

## ⚙️ Совместимость

| Система      | Статус      |
| ------------ | ----------- |
| Ubuntu 24.04 | ✅ Tested    |
| Ubuntu 22.04 | ⚠️ Possible |
| Debian 12    | ⚠️ Possible |

---

## 🔐 Безопасность

> [!TIP]
> Система **не логирует типичные секреты** (`password`, `token`, `apikey`, `secret`, `Authorization`) —
> это снижает риск утечки чувствительных данных в логах.

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Остальные статьи — в
[wiki/README.md](./README.md).*
