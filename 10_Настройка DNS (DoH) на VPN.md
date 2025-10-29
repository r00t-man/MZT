# 🌐 Настройка DoH (DNS-over-HTTPS)

Настройка DoH на сервере требует дополнительных действий (в отличие от DoT).  
Поэтому первым делом установим и настроим **dnscrypt-proxy** версии **2.0.45** — она стабильна и проверена, а конфигурация чувствительна к версии.

---

## ⚙️ **1. Установка dnscrypt-proxy**

```bash
sudo apt update
sudo apt install curl wget unzip -y
wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_x86_64-2.0.45.tar.gz
tar -xvzf dnscrypt-proxy-linux_x86_64-2.0.45.tar.gz
sudo mv linux-x86_64 /usr/local/dnscrypt-proxy
sudo ln -s /usr/local/dnscrypt-proxy/dnscrypt-proxy /usr/sbin/dnscrypt-proxy
````

---

## 👤 **2. Создание системного пользователя**

```bash
sudo useradd -r -s /usr/sbin/nologin -d /var/cache/dnscrypt-proxy _dnscrypt-proxy
```

---

## 📁 **3. Директории и права**

```bash
sudo mkdir -p /var/cache/dnscrypt-proxy /var/log/dnscrypt-proxy /run/dnscrypt-proxy /etc/dnscrypt-proxy
sudo chown -R _dnscrypt-proxy:_dnscrypt-proxy /var/cache/dnscrypt-proxy /var/log/dnscrypt-proxy /run/dnscrypt-proxy
```

---

## 🧩 **4. Конфигурация dnscrypt-proxy**

Файл: `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`

```toml
listen_addresses = ['127.0.0.1:5353']

# Версия: stable-2025.10.25-gisoman

## nscrypt-proxy слушает только на localhost:5353, а не на 53 порту.
## Это важно, чтобы не конфликтовать с systemd-resolved.

# Логи
log_file = '/var/log/dnscrypt-proxy/dnscrypt-proxy.log'
log_level = 2

# Разрешаем только DoH
ipv4_servers = true
ipv6_servers = false
dnscrypt_servers = false
doh_servers = true

# Подключаешься только к DoH-серверам (DNS-over-HTTPS), не к старым DNSCrypt.
# Это современный и более совместимый способ шифрования DNS.

# Минимальные требования
require_dnssec = false
require_nolog = false
require_nofilter = false

# Не требуешь обязательного DNSSEC, отсутствия логов или фильтрации.
# Гибкий подход: мы не блокируем серверы из-за одного параметра, но доверяем нашему DNS vashdnsdomen.

# Серверы вручную
server_names = ['vashdnsdomen']
fallback_resolvers = ['1.1.1.1:53', '8.8.8.8:53']

# Основной сервер — твой собственный vashdnsdomen.ru через DoH.
# Если он недоступен — fallback на публичные DNS (Cloudflare, Google), но без шифрования (это обычный UDP-DNS).
# Ниже пояснение для чего нам fallback_resolvers

# Статический сервер
[static.'vashdnsdomen']
stamp = 'sdns://BfeAAAADDSASWAANd1tsZG4sLnJ1OjG0MwovDG5vLXF1TDJ3'

# Ручная настройка твоего сервера через DNS Stamp — это как QR-код для безопасного DNS.
# Указывает: «Подключайся к vashdnsdomen.ru:443 по DoH и используй этот путь /dns-query».
# Так ты полностью контролируешь свой DNS и можешь фильтровать рекламу через AdGuard.

# ⚠️ Обязательно указываем:
# fallback_resolvers = ['1.1.1.1:53', '8.8.8.8:53']
# 
# Так же мы указываем в конфиге:
# [static.'vashdnsdomen']
# stamp = 'sdns://Agc...vashdnsdomen.ru:443/dns-query'
# Это означает: «Подключайся к vashdnsdomen.ru по HTTPS и делай запросы там».
# Но перед тем как подключиться по HTTPS, dnscrypt-proxy должен:
# Преобразовать имя vashdnsdomen.ru → в IP-адрес (например, 94.183.234.239).
# А для этого нужен обычный DNS-запрос — "какой IP у vashdnsdomen.ru?".
# ⚠️ Проблема:
# Сам dnscrypt-proxy ещё не может использовать шифрованный DNS, потому что он ещё не подключён.
# Он как бы "застрял в круге":
# Чтобы подключиться к DoH, нужно знать IP → Чтобы узнать IP, нужен DNS → А DNS пока не работает… 
# Вот тут и нужен fallback_resolver:
# Это "спасательный" DNS-сервер, который отвечает по старинке, через обычный UDP/53, без шифрования.
# dnscrypt-proxy спрашивает у него: «Эй, а какой IP у vashdnsdomen.ru?»
# Получив ответ, он уже может установить защищённое HTTPS-соединение с vashdnsdomen.ru и начать использовать DoH.
```

💡 *Что важно знать:*

* `listen_addresses = ['127.0.0.1:5353']` — слушает только локально, чтобы не конфликтовать с `systemd-resolved`.
* `fallback_resolvers` нужны, чтобы получить IP твоего домена **до установления DoH-сессии**.
* `stamp` — это "подпись" DNS-сервера (генерируется вручную, см. ниже).

💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡
## Вот вам рабочий конфиг на DoH AdGuard официальный:💡
💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡
```bash
nano /etc/dnscrypt-proxy/dnscrypt-proxy.toml
```

```toml
listen_addresses = ['127.0.0.1:5353']

# Версия: stable-2025.10.25-gisoman

## nscrypt-proxy слушает только на localhost:5353, а не на 53 порту.
## Это важно, чтобы не конфликтовать с systemd-resolved.

# Логи
log_file = '/var/log/dnscrypt-proxy/dnscrypt-proxy.log'
log_level = 2

# Разрешаем только DoH
ipv4_servers = true
ipv6_servers = false
dnscrypt_servers = false
doh_servers = true

# Подключаешься только к DoH-серверам (DNS-over-HTTPS), не к старым DNSCrypt.
# Это современный и более совместимый способ шифрования DNS.

# Минимальные требования
require_dnssec = false
require_nolog = false
require_nofilter = false

# Не требуешь обязательного DNSSEC, отсутствия логов или фильтрации.
# Гибкий подход: мы не блокируем серверы из-за одного параметра, но доверяем нашему DNS vashdnsdomen.

# Серверы вручную

server_names = ['dns.adguard-dns']

fallback_resolvers = ['1.1.1.1:53', '8.8.8.8:53']

[static.'dns.adguard-dns']
stamp = 'sdns://AgcAAAAAAAAAAAAXZG5zLmFkZ3VhcmQtZG5zLmNvbTo0NDMKL2Rucy1xdWVyeQ'
```
💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡💡

---

## 🧾 **5. Генерация DNS Stamp**

Перейди на сайт [dnscrypt.info/stamps](https://dnscrypt.info/stamps/)

1. Введи свой домен с портом (например: `vashdnsdomen.ru:443`)
2. Путь: `/dns-query`
3. Скопируй готовый stamp и вставь его в конфиг выше.

📸 *Пример:*

![stamp-example](https://github.com/soulpastwk/share/blob/main/media/vpn00/stamp.png)

---

## 🔧 **6. Systemd-сервис**

Файл: `/usr/lib/systemd/system/dnscrypt-proxy.service`

```bash
nano /usr/lib/systemd/system/dnscrypt-proxy.service
```

```ini
[Unit]
Description=DNSCrypt client proxy
Documentation=https://github.com/DNSCrypt/dnscrypt-proxy/wiki
After=network.target
Before=nss-lookup.target
Wants=nss-lookup.target

[Service]
User=_dnscrypt-proxy
Group=_dnscrypt-proxy
WorkingDirectory=/var/cache/dnscrypt-proxy
ExecStart=/usr/sbin/dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml

ProtectHome=false
ProtectKernelModules=false
ProtectKernelTunables=false
ProtectControlGroups=false
MemoryDenyWriteExecute=false
NoNewPrivileges=false

CacheDirectory=dnscrypt-proxy
LogsDirectory=dnscrypt-proxy
RuntimeDirectory=dnscrypt-proxy
RuntimeDirectoryMode=0755

Restart=on-failure

[Install]
WantedBy=multi-user.target
```

---

## 🧠 **7. Настройка systemd-resolved**

Файл: `/etc/systemd/resolved.conf`

```bash
nano /etc/systemd/resolved.conf
```

```ini
[Resolve]
DNS=127.0.0.1:5353
DNSSEC=no
DNSOverTLS=no
Cache=no
MulticastDNS=no
LLMNR=no

# Что это даёт:
# ✅ DNS=127.0.0.1:5353
# Говорит systemd-resolved: «Все DNS-запросы отправляй в dnscrypt-proxy».
# Это главный мост между системой и зашифрованным DNS.
# ✅ DNSSEC=no
# Не включаешь проверку DNSSEC на уровне resolved.
# Логично, потому что мы не включаем require_dnssec в dnscrypt-proxy.
# Если бы включили — мог ли бы использовать DNSSEC=yes + trust-ad безопаснее.
# Но по факту DNSSEC редко используется.
# ✅ DNSOverTLS=no
# Не используем DoT, потому что у нас DoH через dnscrypt-proxy — это лучше и безопаснее.
# DoH и DoT — альтернативы, мы выбрали DoH, т.к. DoT могут заблокировать по порту 853, а DoH работает на 443.
# ✅ Cache=no
# Отключаем кеш DNS в resolved.
# Зачем? Чтобы всё проходило через dnscrypt-proxy, где, скорее всего, кеш уже есть.
# Полезно, если хотим чистые тесты или обход кеша при изменениях.
# ✅ MulticastDNS=no, LLMNR=no
# Отключаешь локальные протоколы поиска устройств в сети.
# Это повышает безопасность: меньше векторов атак и спуфинга.
# Особенно актуально, если мы не используем .local имена.
```

💬 *Зачем так:*

* `DNS=127.0.0.1:5353` — отправляем все DNS-запросы в `dnscrypt-proxy`.
* `DNSOverTLS=no` — не нужен, т.к. используется DoH.
* `Cache=no` — отключаем кэш systemd, чтобы всё шло через dnscrypt-proxy.
* `MulticastDNS` и `LLMNR` отключены для безопасности.

---

## 🧱 **8. Настройка resolv.conf**

Файл: `/etc/resolv.conf`

```bash
nano /etc/resolv.conf
```

```ini
nameserver 127.0.0.53
options edns0 trust-ad
search .

# Что это значит:
# ✅ nameserver 127.0.0.53
# Это адрес локального DNS-резолвера, который предоставляет systemd-resolved.
# Не указываем напрямую Cloudflare или Google — вместо этого используем посредника (resolved).
# Он работает как буфер: принимает запросы от приложений и пересылает их дальше (у нас в данном случае dnscrypt-proxy).
# Почему не 127.0.0.1? Потому что 127.0.0.53 — стандартный адрес для systemd-resolved, особенно если он запущен в режиме stub resolver. 
# 
# ✅ options edns0 trust-ad
# edns0 — расширение DNS, позволяющее передавать больше данных в одном пакете (например, поддержка DNSSEC).
# trust-ad — доверяй флагу "AD" (Authenticated Data) от локального резолвера.
# Флаг AD означает: «ответ прошёл проверку DNSSEC и подлинный».
# Мы говорим системе: «Если resolved сказал, что ответ защищён DNSSEC — я верю ему», даже если сам не проверял.
# ⚠️ В dnscrypt-proxy стоит require_dnssec = false, значит, на самом деле DNSSEC не проверяется строго, и trust-ad здесь безопасен.
# 
# ✅ search .
# Отключает поиск по доменам по умолчанию.
# Без этого, если мы выполним ping server, система может попробовать server.local, server.home и т.д.
# Мы сказали: «Не добавляй ничего автоматически — только полные имена».
```

💬 *Пояснение:*

* `127.0.0.53` — адрес `systemd-resolved`, он перенаправит запросы в dnscrypt-proxy.
* `trust-ad` — доверие флагу DNSSEC.
* `search .` — отключает автоматическое добавление доменов.

Применяем:

```bash
sudo systemctl restart systemd-resolved
```

---

## 🚀 **9. Запуск и проверка службы**

```bash
sudo systemctl daemon-reload
sudo systemctl enable dnscrypt-proxy
sudo systemctl start dnscrypt-proxy
sudo systemctl status dnscrypt-proxy
```

Посмотреть логи:

```bash
tail -f /var/log/dnscrypt-proxy/dnscrypt-proxy.log
```

---

## 🔍 **10. Проверка работы**

```bash
dig @127.0.0.1 -p 5353 www.google.com
curl -vk https://vashdnsdomen.ru/dns-query
```

✅ Если ответы приходят — всё настроено корректно!

---

## 📱 **11. Применение на клиентах**

* 💻 **Роутер** — указываем DoH-сервер `https://vashdnsdomen.ru/dns-query`
* 📱 **Android** — используем *Частный DNS* → `vashdnsdomen.ru` (работает через DoT)
* 🧠 **Совет:** держи оба протокола (DoH и DoT) активными — это улучшает совместимость.

---

### 🧩 **Итог:**

| Компонент            | Назначение                   | Протокол      |
| -------------------- | ---------------------------- | ------------- |
| `dnscrypt-proxy`     | Обеспечивает шифрованный DNS | DoH           |
| `systemd-resolved`   | Локальный резолвер           | DNS stub      |
| `resolv.conf`        | Прокси для приложений        | локальный DNS |
| `fallback_resolvers` | Резервный путь               | UDP/53        |

---

> ✨ Теперь твой сервер использует **современный, приватный и устойчивый к блокировкам DNS через HTTPS**.
>
> 🔒 Без утечек, без кэшей, с полным контролем трафика.

## ПРОВЕРКИ ✅
Давай проверим **несколькими способами**, от простого к профессиональному.  
Ты уже на правильном пути — но сейчас добавим **неопровержимые доказательства**.

---

## 🔍 Что у тебя уже есть (резюме)

- Ты используешь `dnscrypt-proxy`
- Слушает порт `127.0.0.1:5353`
- В конфиге:
  ```toml
  doh_servers = true
  server_names = ['dns.adguard-dns']
  ```
- Используется **AdGuard Public DoH**
- `fallback` — `1.1.1.1`, `8.8.8.8` (на случай сбоя)
- Запросы работают

✅ Это хорошая база. Но как **убедиться, что это именно DoH**, а не UDP?

---

# ✅ Методы проверки: работает ли DoH на самом деле

### 🔹 1. Проверка через `curl` — имитация DoH-запроса

Можно вручную проверить, доступен ли DoH-эндпоинт:

```bash
curl -v \
  --resolve dns.adguard-dns.com:443:94.140.14.14 \
  https://dns.adguard-dns.com/dns-query \
  --output /dev/null \
  --data-binary @<(echo -ne '\x00\x00\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x06google\x03com\x00\x00\x01\x00\x01') \
  -H 'Content-Type: application/dns-message' \
  -H 'Accept: application/dns-message'
```

(Это бинарный DNS-запрос к Google через DoH)

✅ Если ответ пришёл — значит, DoH работает.

---

### 🔹 2. Проверка: кто обрабатывает запрос? (через `resolvectl status`)

Выполни:

```bash
resolvectl status
```

Ищи строку:

```
Current DNS Server: 127.0.0.1% -- link: (lo)
```

А ниже:

```
DNS Servers: 127.0.0.1
```

→ Это означает: `resolved` использует твой `dnscrypt-proxy`.

Но сам `resolved` **не шифрует**, он просто клиент.  
Шифрование происходит **внутри `dnscrypt-proxy`**.

---

## 💡 Дополнительно: почему `resolvectl` пишет `encrypted transport: no`?

```bash
resolvectl query google.com
```

Потому что:
- `systemd-resolved` **не знает**, что за ним стоит `dnscrypt-proxy`
- Он видит только **UDP-ответ от 127.0.0.1:5353**
- А то, что внутри был DoH — для него "чёрный ящик"

👉 Это **не ошибка**, а особенность архитектуры.

Если бы ты использовал DoT/DoH **прямо в `resolved`** — тогда бы было `yes`.  
Но ты выбрал более гибкий путь — и это нормально.

---
## 💡💡💡💡💡💡💡
## Дополнительно проверьте на сайте:💡
Будучи подключённым к своему серверу
утечек ДНС быть не должно

```
dnsleaktest.com
```
