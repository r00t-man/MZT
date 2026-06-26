# 🚀 Remnawave Node + Nginx + XHTTP + TLS Frontend

Рабочая схема:

- сайт открывается как обычный HTTPS-сайт;
- nginx принимает внешний TLS на `443`;
- Xray/Remnawave Node слушает только локально `127.0.0.1:8443`;
- VPN-трафик идёт через `/vpn`;
- клиент подключается к домену на `443` с `TLS`;
- внутри между nginx и Xray используется `security: none`.

---

## 🧠 Общая логика

```text
                        🌍 INTERNET
                            │
                            │ HTTPS / TLS / 443
                            │ SNI: vpn-node.example.com
                            │ Path: /vpn
                            ▼
┌────────────────────────────────────────────────────┐
│                    🧱 NGINX                       │
│              vpn-node.example.com:443                     │
│                                                    │
│  /                    → обычный сайт               │
│  /vpn                 → proxy to Xray              │
└────────────────────────────────────────────────────┘
                            │
                            │ HTTP без TLS
                            │ 127.0.0.1:8443
                            ▼
┌────────────────────────────────────────────────────┐
│              ⚡ Remnawave Node / Xray              │
│                                                    │
│  listen: 127.0.0.1                                 │
│  port: 8443                                        │
│  protocol: VLESS                                   │
│  transport: XHTTP                                  │
│  security: none                                    │
└────────────────────────────────────────────────────┘
                            │
                            ▼
                    🌐 DIRECT outbound
````

---

## 📦 Подготовленная структура

```text
/srv
├── certs
│   ├── vpn-node.example.com_fullchain.pem
│   └── vpn-node.example.com_privkey.key
│
└── vpnsite
    ├── index.html
    ├── script.js
    └── styles.css
```

---

# 1. Установка nginx

```bash
apt update
apt install -y nginx curl ca-certificates
```

---

# 2. Конфиг nginx

Файл:

```bash
/etc/nginx/sites-available/vpn-node.example.com
```

Полный конфиг:

```nginx
server {
    listen 80;
    server_name vpn-node.example.com;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name vpn-node.example.com;

    ssl_certificate     /srv/certs/vpn-node.example.com_fullchain.pem;
    ssl_certificate_key /srv/certs/vpn-node.example.com_privkey.key;

    root /srv/vpnsite;
    index index.html;

    access_log /var/log/nginx/site_access.log;
    error_log  /var/log/nginx/site_error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    location ^~ /vpn {
        access_log /var/log/nginx/vpn_access.log;
        error_log  /var/log/nginx/vpn_error.log;

        proxy_pass http://127.0.0.1:8443;
        proxy_http_version 1.1;

        proxy_set_header Host vpn-node.example.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Connection "keep-alive";

        proxy_buffering off;
        proxy_request_buffering off;
        proxy_cache off;
        proxy_redirect off;

        chunked_transfer_encoding on;
        client_max_body_size 0;

        proxy_connect_timeout 60s;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
        send_timeout 86400s;
    }
}
```

Активировать сайт:

```bash
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/vpn-node.example.com /etc/nginx/sites-enabled/vpn-node.example.com

nginx -t
systemctl reload nginx
```

---

# 3. Проверка nginx

```bash
curl -Iv https://vpn-node.example.com
```

Ожидаемо:

```text
HTTP/2 200
server: nginx
```

Проверка `/vpn`:

```bash
curl -vk https://vpn-node.example.com/vpn
```

Обычный `curl` может получить:

```text
HTTP/2 404
```

Это нормально.
`/vpn` — не обычная веб-страница, а XHTTP endpoint для клиента.

---

# 4. JSON для Remnawave Node / Xray

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "xhttp-in",
      "port": 8443,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "host": "vpn-node.example.com",
          "path": "/vpn",
          "mode": "auto",
          "headers": {},
          "noSSEHeader": false,
          "xPaddingBytes": "100-1000",
          "scMaxBufferedPosts": 30,
          "scMaxEachPostBytes": 1000000,
          "scStreamUpServerSecs": "20-80"
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "DIRECT"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "BLOCK"
      }
    ]
  }
}
```

---

# 5. Remnawave Host Settings

В настройках хоста Remnawave:

```text
Address: vpn-node.example.com
Port: 443
SNI: vpn-node.example.com
Host: vpn-node.example.com
Path: /vpn
Security Layer: TLS
Fingerprint: chrome
ALPN: h2,http/1.1
```

Главное правило:

```text
Клиент снаружи: TLS
Xray внутри: security none
```

---

# 6. Клиентский конфиг

Критически важно, чтобы клиент получал:

```json
{
  "tag": "proxy",
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "vpn-node.example.com",
        "port": 443,
        "users": [
          {
            "id": "USER_UUID",
            "encryption": "none",
            "flow": ""
          }
        ]
      }
    ]
  },
  "streamSettings": {
    "network": "xhttp",
    "xhttpSettings": {
      "mode": "auto",
      "host": "vpn-node.example.com",
      "path": "/vpn"
    },
    "security": "tls",
    "tlsSettings": {
      "serverName": "vpn-node.example.com",
      "fingerprint": "chrome",
      "alpn": [
        "h2",
        "http/1.1"
      ]
    }
  }
}
```

---

# 7. Самая важная ошибка, из-за которой не работало

Неправильно:

```json
"security": "none"
```

в клиентском конфиге.

Правильно:

```json
"security": "tls"
```

Почему:

```text
CLIENT → TLS → NGINX:443 → HTTP → Xray:8443
```

TLS должен быть у клиента, потому что клиент подключается к nginx на `443`.

А внутри Xray остаётся:

```json
"security": "none"
```

потому что TLS уже завершён на nginx.

---

# 8. Проверка портов

```bash
ss -lntp | grep -E ':443|:8443'
```

Ожидаемо:

```text
0.0.0.0:443        nginx
127.0.0.1:8443     rw-core
```

---

# 9. Логи

Nginx сайт:

```bash
tail -f /var/log/nginx/site_access.log /var/log/nginx/site_error.log
```

XHTTP endpoint:

```bash
tail -f /var/log/nginx/vpn_access.log /var/log/nginx/vpn_error.log
```

Remnawave Node:

```bash
docker logs -f remnanode
```

---

# 10. Быстрая диагностика

## Сайт не открывается

```bash
curl -Iv https://vpn-node.example.com
nginx -t
systemctl status nginx --no-pager -l
```

---

## Клиент пишет TLS error

Проверить клиентский конфиг:

```json
"security": "tls"
```

а не:

```json
"security": "none"
```

Проверить:

```json
"serverName": "vpn-node.example.com"
```

---

## В логах nginx нет `/vpn`

Значит клиент не доходит до сервера:

```bash
nslookup vpn-node.example.com
curl -Iv https://vpn-node.example.com
```

---

## В логах есть `/vpn`, но upstream error

Проверить:

```bash
ss -lntp | grep 8443
docker logs --tail 100 remnanode
```

---

# 11. Финальная схема

```text
┌───────────────────────────────────────────────────────────────┐
│                         CLIENT                                │
│                                                               │
│  VLESS                                                        │
│  Transport: XHTTP                                             │
│  Address: vpn-node.example.com                                       │
│  Port: 443                                                    │
│  Security: TLS                                                │
│  SNI: vpn-node.example.com                                           │
│  Host: vpn-node.example.com                                          │
│  Path: /vpn                                                   │
└───────────────────────────────┬───────────────────────────────┘
                                │
                                │ HTTPS / TLS
                                │
                                ▼
┌───────────────────────────────────────────────────────────────┐
│                         NGINX                                 │
│                                                               │
│  listen 443 ssl http2                                         │
│  server_name vpn-node.example.com                                    │
│                                                               │
│  /      → /srv/vpnsite                                       │
│  /vpn  → http://127.0.0.1:8443                                │
└───────────────────────────────┬───────────────────────────────┘
                                │
                                │ HTTP local only
                                │
                                ▼
┌───────────────────────────────────────────────────────────────┐
│                    REMNAWAVE NODE / XRAY                      │
│                                                               │
│  listen: 127.0.0.1                                            │
│  port: 8443                                                   │
│  protocol: vless                                              │
│  network: xhttp                                               │
│  security: none                                               │
│  path: /vpn                                                   │
└───────────────────────────────┬───────────────────────────────┘
                                │
                                │
                                ▼
┌───────────────────────────────────────────────────────────────┐
│                         OUTBOUND                              │
│                                                               │
│  DIRECT                                                       │
│  позже можно заменить/добавить WARP                           │
└───────────────────────────────────────────────────────────────┘
```

---

# 12. Важное правило

```text
Если nginx принимает внешний TLS,
то клиент = TLS,
а Xray inbound за nginx = none.
```

```text
Client security: tls
Server inbound security: none
```

# 13. В итоге добиваем всё это WARP

✔ XHTTP работает
✔ nginx фронт
✔ WARP поднят как SOCKS на `127.0.0.1:40000`

Теперь добавим WARP **как outbound в Xray** 🔥

---

# 🧠 Архитектура после добавления WARP

```text
CLIENT → TLS → NGINX → XHTTP → XRAY
                               │
                               ├── DIRECT
                               └── WARP (127.0.0.1:40000)
```

---

# 🎯 Задача

* весь трафик → через WARP
* (или потом сделаем гибкую маршрутизацию)

---

# 🔧 JSON с WARP

Вот твой обновлённый конфиг:

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "xhttp-in",
      "port": 8443,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "host": "vpn-node.example.com",
          "path": "/vpn",
          "mode": "auto",
          "headers": {},
          "noSSEHeader": false,
          "xPaddingBytes": "100-1000",
          "scMaxBufferedPosts": 30,
          "scMaxEachPostBytes": 1000000,
          "scStreamUpServerSecs": "20-80"
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "WARP",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 40000
          }
        ]
      }
    },
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "DIRECT"
      },
      {
        "type": "field",
        "domain": ["geosite:category-ads-all"],
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "WARP"
      }
    ]
  }
}
```


# 🔥 Что изменилось

## Добавили outbound:

```json
{
  "tag": "WARP",
  "protocol": "socks",
  "settings": {
    "servers": [
      {
        "address": "127.0.0.1",
        "port": 40000
      }
    ]
  }
}
```

---

## И правило:

```json
{
  "type": "field",
  "network": "tcp,udp",
  "outboundTag": "WARP"
}
```

👉 теперь ВСЁ идёт через WARP

---

# 🚀 Применяем

```bash
docker restart remnanode
```

---

# 🧪 Проверка

## 1. Через клиент

Открой:

```bash
curl ifconfig.me
```

👉 должен быть:

```text
104.xxx.xxx.xxx (Cloudflare WARP)
```

---

## 2. Проверка напрямую с сервера

```bash
curl --socks5 127.0.0.1:40000 ifconfig.me
```

✔ у тебя уже:

```text
104.28.x.x
```

---

# ⚠️ ВАЖНЫЕ МОМЕНТЫ

## 1. DNS

Если будут проблемы → добавим:

```json
"dns": {
  "servers": ["1.1.1.1", "8.8.8.8"]
}
```

---

## 2. Иногда UDP не нужен

Если будут глюки:

```json
"network": "tcp"
```

---

# 🧠 Дальше можно сделать мощнее

Ты сейчас на уровне:

```text
✔ nginx + xhttp + tls
✔ warp интеграция
```

---

## Следующие апгрейды (по желанию):

### 🔹 1. Разделить трафик

```text
RU → DIRECT  
НЕ RU → WARP  
```

🧠 Имеет смысл сделать если у нас RU нода 🧠

---

### 🔹 2. fallback схема

```text
xhttp + reality + tcp fallback
```

---

### 🔹 3. multi-exit

```text
WARP + DE server + cascade
```

---

# 🎯 Итог

Ты сейчас собрал:

## production-grade схема обхода DPI

✔ маскировка под сайт
✔ TLS фронт
✔ xhttp транспорт
✔ WARP выход

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                              🌍 CLIENT                                       │
│                                                                              │
│  HAPP / Hiddify / v2rayN / v2rayTun                                          │
│                                                                              │
│  Protocol: VLESS                                                             │
│  Transport: XHTTP                                                            │
│  Address: vpn-node.example.com                                                      │
│  Port: 443                                                                   │
│  Security: TLS                                                               │
│  SNI: vpn-node.example.com                                                          │
│  Host: vpn-node.example.com                                                         │
│  Path: /vpn                                                                  │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
                                       │ 🔐 HTTPS / TLS / 443
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              🧱 NGINX FRONT                                  │
│                                                                              │
│  Public: 0.0.0.0:443                                                         │
│  Domain: vpn-node.example.com                                                       │
│  Cert: /srv/certs/vpn-node.example.com_fullchain.pem                                │
│  Key:  /srv/certs/vpn-node.example.com_privkey.key                                  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │ /                                                                      │  │
│  │ └── обычный маскировочный сайт из /srv/vpnsite                        │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │ /vpn                                                                   │  │
│  │ └── proxy_pass http://127.0.0.1:8443                                   │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
                                       │ 🧩 локальный HTTP без TLS
                                       │ 127.0.0.1:8443
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                        ⚡ REMNAWAVE NODE / XRAY                               │
│                                                                              │
│  Inbound tag: xhttp-in                                                       │
│  Listen: 127.0.0.1                                                           │
│  Port: 8443                                                                  │
│  Protocol: VLESS                                                             │
│  Transport: XHTTP                                                            │
│  Server security: none                                                       │
│  XHTTP host: vpn-node.example.com                                                   │
│  XHTTP path: /vpn                                                            │
│                                                                              │
│  ВАЖНО:                                                                      │
│  Клиент снаружи использует TLS                                               │
│  Xray внутри за nginx использует security: none                              │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
                                       │ routing
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              🧭 ROUTING                                      │
│                                                                              │
│  geoip:private              ───────────────► DIRECT                          │
│  geosite:category-ads-all   ───────────────► BLOCK                           │
│  tcp / udp                  ───────────────► WARP                            │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
                                       │ SOCKS5
                                       │ 127.0.0.1:40000
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              ☁️ WARP                                         │
│                                                                              │
│  warp-svc listens: 127.0.0.1:40000                                           │
│  Status: Connected                                                           │
│  Network: healthy                                                            │
│                                                                              │
│  Server public IP: 203.0.113.10                                               │
│  Exit through WARP: 104.28.x.x                                            │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
                                       │ 🌐 внешний интернет
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
│                                                                              │
│  Сайты видят не IP сервера, а WARP exit IP                                   │
└──────────────────────────────────────────────────────────────────────────────┘
```

Коротко по слоям:

```text
CLIENT
  ↓ TLS / XHTTP / 443
NGINX
  ↓ HTTP local / 8443
XRAY
  ↓ SOCKS / 40000
WARP
  ↓
INTERNET
```


Коротко: твоя новая схема **xhttp + nginx (TLS termination) + WARP** — это уже не просто “VPN”, а полноценный **маскировочный транспортный слой**, тогда как второй вариант — это **обычный “палящийся” TLS-инбаунд Xray**.

Разберём без воды, по уровням.

---

# ⚔️ 1. Архитектура: кто “светится” наружу

## 🔴 Вариант 1 — Xray TLS напрямую

```text
CLIENT → TLS → XRAY (443)
```

**Что видит DPI / провайдер:**

* нестандартный TLS fingerprint (Xray)
* странное поведение HTTP/2
* нет реального сайта
* ALPN/JA3 может палиться

👉 это **детектится как VPN/обфускация**

---

## 🟢 Вариант 2 — твоя схема

```text
CLIENT → TLS → NGINX → XHTTP → XRAY → WARP
```

**Что видит DPI:**

* обычный nginx
* валидный сайт
* нормальный TLS handshake (OpenSSL / nginx)
* реальный HTTP/2 трафик

👉 это выглядит как:

> “обычный HTTPS сайт с бекендом”

---

# 🧠 2. TLS Fingerprint (самое важное)

## ❌ Xray TLS

* свой стек TLS
* даже с fingerprint=chrome → не 100% совпадение
* могут ловить по:

  * JA3
  * ALPN паттернам
  * timing

## ✅ Nginx TLS

* OpenSSL
* полностью “белый” fingerprint
* совпадает с обычными сайтами

👉 **ключевое преимущество схемы — TLS делает nginx, а не Xray**

---

# 🕵️ 3. Маскировка (реализм)

## ❌ Прямой Xray

* нет настоящего сайта
* `/` часто пустой
* `/vpn` — сразу аномалия
* легко сканится

## ✅ nginx схема

* есть сайт `/`
* есть статика (css/js)
* `/vpn` спрятан
* можно:

  * добавить fake API
  * добавить 404 поведение
  * имитировать backend

👉 уровень маскировки: **в разы выше**

---

# 🌐 4. Поведение трафика

## ❌ прямой TLS

* соединение → сразу туннель
* нет “нормального веба”

## ✅ xhttp через nginx

* реальные HTTP запросы
* chunked / POST / GET
* padding (`xPaddingBytes`)
* выглядит как:

  * upload API
  * streaming
  * websocket-like

---

# ☁️ 5. Добавка WARP

Вот тут вообще разрыв.

## ❌ без WARP

* выходной IP = твой сервер
* легко банится
* ASN палится

## ✅ с WARP

* выход = Cloudflare
* IP меняется
* ASN = Cloudflare
* гео обход лучше

👉 плюс:

* anti-DPI
* анти-блокировки сервисов

---

# 🧩 6. Гибкость

## ❌ прямой Xray TLS

* всё в одном процессе
* сложно масштабировать
* сложно миксовать

## ✅ nginx схема

ты можешь:

* 🔀 делать несколько путей:

  * `/vpn`
  * `/api`
  * `/cdn`
* 🌍 разные домены → один backend
* 🔐 добавить:

  * mTLS
  * geo rules
  * rate limit
* 🧠 балансировать
* 🔥 цепочки (cascade)

---

# ⚠️ 7. Минусы твоей схемы

На работу не влияю, просто сложности в обслуживании и в дебаге.

### ❗ сложнее

* nginx + xray + routing
* больше точек отказа

### ❗ overhead

* +1 hop (nginx → xray)

### ❗ нужно правильно настроить

* proxy_buffering off
* HTTP/2
* headers

---

# 🧠 Итог

| Критерий         | Прямой TLS Xray | Nginx + XHTTP |
| ---------------- | --------------- | ------------- |
| Маскировка       | ❌ слабая        | ✅ сильная     |
| TLS fingerprint  | ❌ палится       | ✅ чистый      |
| DPI устойчивость | ❌ средняя       | ✅ высокая     |
| Реалистичность   | ❌ нет сайта     | ✅ есть сайт   |
| Гибкость         | ❌ низкая        | ✅ высокая     |
| WARP интеграция  | ➖ отдельно      | ✅ естественно |
| Сложность        | ✅ простая       | ❌ выше        |

---

# 🧾 Вывод

👉 твоя текущая схема — это уже уровень:

```text
не просто VPN → а “маскированный CDN-подобный трафик”
```

👉 а старый конфиг — это:

```text
“VPN с обфускацией”
```

