[![OS Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![OpenSSL](https://img.shields.io/badge/OpenSSL-%E2%9C%94-green?logo=openssl&logoColor=white)](https://www.openssl.org/)
[![Xray](https://img.shields.io/badge/Xray-Ready-orange?logo=github)](https://github.com/XTLS/Xray-core)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

> [!IMPORTANT]
> Этот проект предназначен только для **личного использования**.  
> ⚠️ **Дисклеймер** ⚠️  
> Данный материал создан *исключительно в образовательных целях*.  
> Автор не несёт ответственности за возможные последствия использования.  
> Применяйте только в рамках законного тестирования и легальных задач.

# Рекомендую настроить безопасность ОС

## 🔒 Настройка SSH

Изменяем конфигурацию:

```bash
nano /etc/ssh/sshd_config
```

Пример:

Выбираем нестандартный порт, если у вас много серверов что бы не забыть можно ставить 22 и ваши последние цифры ip (4й октет) <br>
Например, если у вас ip сервера 151.45.20.132, ставим порт 22132, если 151.45.20.32 - ставим порт 22032 <br>

PasswordAuthentication no    # Этот параметр включаем ТОЛЬКО если у вас настроены ssh КЛЮЧИ

```ini
Port 22132
Banner none
PrintMotd no
DebianBanner no
#PasswordAuthentication no
```

Перезапуск:

```bash
systemctl restart ssh
```

*Зачем:* уменьшает вероятность атак на SSH. (Иногда нужен reboot сервера)

---

## 🛡 Настройка Fail2Ban

Создаём конфиг:

```bash
nano /etc/fail2ban/jail.local
```

Пример для SSH:

```ini
[sshd]
enabled = true
filter = sshd
action = nftables[name=SSH, port=ssh, protocol=tcp]
logpath = %(syslog_authpriv)s
findtime = 600
maxretry = 2
bantime = -1
backend = systemd
```

### 📖 Расшифровка параметров

* **enabled = true** — включает защиту для этого сервиса.
* **filter = sshd** — указывает, какой фильтр (шаблон поиска в логах) использовать.
* **action = nftables\[name=SSH, port=ssh, protocol=tcp]** — при срабатывании бана добавляется правило в `nftables`, закрывающее доступ к порту SSH.
* **logpath = %(syslog\_authpriv)s** — путь до логов (в Ubuntu 24.04 через systemd-journald маппится автоматически).
* **findtime = 600** — за какой период (в секундах, здесь 10 минут) учитываются попытки входа.
* **maxretry = 2** — сколько ошибок допускается прежде чем IP будет забанен.
* **bantime = -1** — время бана: `-1` значит **пожизненно** (IP останется в бане, пока админ вручную не снимет).
* **backend = systemd** — Fail2Ban получает логи напрямую через systemd-journald (правильно для Ubuntu 24).

---

⚠️ **Важно:** в самих конфиг-файлах (`jail.local`) комментарии внутри секции **писать нельзя** — Fail2Ban не примет такой файл и сервис не запустится.
Если нужны пояснения — лучше оставлять их в отдельной документации или в начале файла **перед секциями**.

Запуск:

```bash
systemctl enable fail2ban
systemctl restart fail2ban
```
#### Просмотр статуса Fail2Ban
Общий статус:
```bash
sudo fail2ban-client status
```

Статус конкретного jail (например, `sshd`):
```bash
sudo fail2ban-client status sshd
```

#### Разблокировка IP-адреса
Чтобы разблокировать определенный IP-адрес:
```bash
sudo fail2ban-client set sshd unbanip 192.168.1.100
```
---

## 🔥 Настройка фаервола (nftables)

⚠️ Перед настройкой обязательно проверьте **порт SSH** и **порты, которые использует 3X-UI** для Веб-ки и 443 (или 8433 если каскадный VPN)

В файле nftables.conf удаляем всё и вставляем содержимое ниже:

```bash
nano /etc/nftables.conf
```

```nft
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        # Loopback
        iif lo accept

        # Уже установленные соединения
        ct state established,related accept

        # SSH (укажите свой порт)
        tcp dport 60022 accept

        # Порты панели 3X-UI (замените на реальные)
        tcp dport 8443 accept
        tcp dport 60555 accept

        # Пример: iperf3 только с определенного IP
        ip saddr 192.168.1.1 tcp dport 5201 accept

    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}
```

Применяем:

```bash
systemctl enable nftables
systemctl restart nftables
nft list ruleset
```

---

## ⚡ Оптимизация логов (безопаснее в оперативке)

### 📌 Вариант 1: хранение в RAM

```ini
[Journal]
Storage=volatile
RuntimeMaxUse=50M
SystemMaxUse=0
```

* Логи очищаются при перезагрузке.
* Fail2Ban: при перезагрузке «история» атак обнуляется. Это не критично для большинства случаев, т.к. после старта новые атаки снова будут блокироваться.
* Логи будут храниться только в /run/log/journal/ (в оперативной памяти).
* После перезагрузки все записи очищаются.

---

### 📌 Вариант 2: хранение на диске

```ini
[Journal]
Storage=persistent
SystemMaxUse=500M
RuntimeMaxUse=50M
```

* Логи будут храниться в привычном месте /var/log/journal/ и сохраняться после перезагрузки.
* Fail2Ban: сможет анализировать длительную историю атак, а не только с момента старта системы.
* Минус: больше нагрузки на диск (особенно SSD/VPS с ограниченным ресурсом), но не критично.

Открыть конфиг на редактирование:

   ```bash
   sudo nano /etc/systemd/journald.conf
   ```

Сохранить и перезапустить службу:

   ```bash
   sudo systemctl restart systemd-journald
   ```
---

⚡ Проверить, где сейчас хранятся логи:

```bash
journalctl --disk-usage
```

👉 Если `Storage=volatile` — логи будут в `/run/log/journal/` (RAM).
👉 Если `Storage=persistent` — в `/var/log/journal/`.

---

---

## 🌐 Отключение IPv6 и защита от ICMP

### Почему отключаем IPv6?

* Многие VPN используют только IPv4.
* Если IPv6 оставить включённым, возможны **утечки реального IP через DNS или прямые соединения**, что может «выдать» вас.

Отключение:

```bash
echo "GRUB_CMDLINE_LINUX=\"ipv6.disable=1\"" | tee -a /etc/default/grub
update-grub
reboot
```
---

## 🔒 Дополнительная защита ICMP

Чтобы усложнить сетевые сканирования и защитить сервер:

```bash
# Добавляем параметры в /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf

# Применяем изменения
sysctl -p
```

## 📊 Объяснение параметров

```
ICMP пакеты
├── Echo Request (ping)
│   └─ net.ipv4.icmp_echo_ignore_all = 1  ✅ игнорируются все ping-запросы
├── Broadcast Echo Request (ping на широковещательный адрес)
│   └─ net.ipv4.icmp_echo_ignore_broadcasts = 1  ✅ защита от Smurf-атак
└── Подозрительные ICMP ошибки (bogus/error)
    └─ net.ipv4.icmp_ignore_bogus_error_responses = 1  ✅ игнор некорректных или потенциально опасных ICMP-пакетов
```

### 🔹 Пояснения

* `icmp_echo_ignore_all` → закрывает только обычные ping-запросы.
* `icmp_echo_ignore_broadcasts` → отдельно защищает от широковещательных ping (Smurf).
* `icmp_ignore_bogus_error_responses` → блокирует нестандартные/подозрительные ICMP сообщения.

⚠️ **Вывод:** для полной защиты сервера от ICMP-сканирования и атак нужно использовать **все три параметра вместе**.

---

### 1️⃣ `net.ipv4.icmp_echo_ignore_all = 1`

* Полностью **игнорирует все ICMP echo-запросы** (`ping`).
* Сервер **не отвечает на `ping`** ни от кого.
* **Влияет только на ICMP типа Echo Request**.

---

### 2️⃣ `net.ipv4.icmp_echo_ignore_broadcasts = 1`

* Игнорирует **ping на broadcast-адреса** (например, 192.168.1.255).
* Защищает от **Smurf-атак** (когда злоумышленник шлёт ping на широковещательный адрес, чтобы нагрузить сеть).
* **Не дублирует `icmp_echo_ignore_all`**, т.к. broadcast может обрабатываться отдельно, особенно если `icmp_echo_ignore_all` отключен (`0`).

---

### 3️⃣ `net.ipv4.icmp_ignore_bogus_error_responses = 1`

* Игнорирует **подозрительные ICMP ошибки**, которые могут использоваться для атак или сканирования.
* Примеры: ICMP Destination Unreachable с некорректным содержимым, ICMP Redirect, ICMP Parameter Problem.
* **Не относится к Echo Request**, поэтому не дублирует первое правило.

---

✅ Теперь сервер:

* Обновлён и защищён,
* Работает с **3X-UI панелью и сертификатами**,
* С надёжным **фаерволом (nftables)**,
* С оптимизированными логами,
* С отключённым IPv6 (чтобы избежать утечек).

---
