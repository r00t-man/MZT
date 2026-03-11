# 🛠 Готовый минимальный конфиг `sysctl.conf`, оптимизированный под **Linux-сервер** <br>
# Дополнение ко всем настройкам - конфликта не будет <br>
## 📌 Протестировано на hostvds и hostkey и hshp.host 📌 <br>

```conf
# ==========================
# 🔒 Безопасность сети
# ==========================

# Отключаем IPv6 полностью (исключаем утечки DNS и адресацию)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Отключаем маршрутизацию IPv6
net.ipv6.conf.all.forwarding = 0

# Игнорируем все входящие ICMP (сервер не пингуется)
net.ipv4.icmp_echo_ignore_all = 1
# Игнорируем широковещательные запросы (DoS-защита)
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Игнорируем ложные ICMP ошибки
net.ipv4.icmp_ignore_bogus_error_responses = 1

# ==========================
# ⚡ Оптимизация скорости
# ==========================

# Планировщик пакетов (нужен для BBR)
net.core.default_qdisc = fq

# Алгоритм TCP congestion control — BBR
net.ipv4.tcp_congestion_control = bbr

# ==========================
# 🛡 Дополнительно
# ==========================

# Включаем форвардинг IPv4 (нужно только если сервер выполняет маршрутизацию/проксирование)
net.ipv4.ip_forward = 1
````

---

## 📌 Как применить

1. Создай файл с настройками:

```bash
sudo nano /etc/sysctl.d/99-vpn.conf
```

2. Вставь туда содержимое конфига.

3. Применить настройки:

```bash
sudo sysctl --system
```

4. Проверка работы:

* IPv6 отключён?

```bash
ip a | grep inet6
```

* Включён ли BBR?

```bash
sysctl net.ipv4.tcp_congestion_control
```

* Разрешён ли форвардинг IPv4?

```bash
sysctl net.ipv4.ip_forward
```

---
## Рекомендую ещё добавить эти изменения в конфиги ниже: <br>
Если не добавили ранее.

## 🌐 Отключение IPv6 в самом GRUB и защита от ICMP

```bash
echo "GRUB_CMDLINE_LINUX=\"ipv6.disable=1\"" | tee -a /etc/default/grub
update-grub
reboot
```
---

## 🔒 Дополнительная защита ICMP

```bash
# Добавляем параметры в /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf

# Применяем изменения
sysctl -p
```

👉 Такой конфиг подходит именно для **VPN-сервера**:

* IPv6 глушим (нет утечек DNS/трафика),
* IPv4 форвардим (нужно для работы VPN),
* BBR включён (ускоряет соединения),
* ICMP-запросы закрыты (сервер не «светится» в сети).
