# Профиль Remnawave `block-ru-v2-json`

Этот профиль предназначен для запуска **VLESS + XHTTP + TLS** в Remnawave и одновременно выполняет роль фильтра: пропускает обычный трафик, режет рекламу и блокирует российские домены/подсети по заданным правилам.

## ✨ Что делает этот конфиг

- 🔌 поднимает входящее подключение на `443/tcp` по протоколу `vless`;
- 🔒 использует транспорт `xhttp` поверх `tls` (маскировка под обычный HTTPS-трафик);
- 📝 пишет `access` и `error` логи в `/var/log/remnanode`;
- 🌐 использует DNS-резолверы и стратегию `UseIPv4`;
- 🚦 отправляет обычный трафик в `DIRECT`, а нежелательный — в `BLOCK` (`blackhole`);
- ⛔ блокирует:
  - рекламные домены из `geosite:category-ads-all`;
  - список конкретных `.ru`/российских сервисов в правилах;
  - все домены зон `.ru`, `.su`, `.рф` (`xn--p1ai`);
  - IP-диапазоны `geoip:ru`.

## 🧩 Что и для чего прописано в секциях

- `log` — пути к логам и уровень логирования (`warning`).
- `dns` — DNS-серверы и стратегия запросов (`UseIPv4`).
- `inbounds` — точка входа клиента:
  - `protocol: vless`, `port: 443`, `listen: 0.0.0.0`;
  - `sniffing` распознаёт тип трафика (`http/tls/quic`) для корректной маршрутизации;
  - `streamSettings` задаёт `xhttp + tls`;
  - `tlsSettings` — домен, сертификаты, версии TLS;
  - `xhttpSettings` — параметры HTTP-обёртки (host/path/buffering и т.д.).
- `outbounds`:
  - `DIRECT` (`freedom`) — разрешённый трафик;
  - `BLOCK` (`blackhole`) — трафик, который нужно отбросить.
- `routing.rules` — логика маршрутизации и блокировок.

```json
"headers": {},                   // Доп. HTTP-заголовки для транспорта (обычно пусто, можно маскировать под сайт)
"noSSEHeader": false,            // Отключать Server-Sent Events заголовки (false = использовать SSE, лучше маскировка под веб)
"xPaddingBytes": "100-1000",     // Случайный padding в байтах (размывает сигнатуру трафика, имитация обычного HTTP)
"scMaxBufferedPosts": 30,        // Максимум буферизованных POST-запросов (влияет на параллелизм/задержки)
"scMaxEachPostBytes": 1000000,   // Максимальный размер одного POST (≈1MB, влияет на фрагментацию трафика)
"scStreamUpServerSecs": "20-80"  // Интервал (сек) удержания аплинк-соединения перед пересозданием (рандом в диапазоне)
```

> ⚠️ Важно: замените в конфиге значения `ЗАМЕНИ СВОЙ ДОМЕН` и пути к сертификатам (`privkey.key`, `fullchain.pem`) на ваши реальные.

## 🐳 Чтобы логирование работало в Docker

Нужно заранее создать папку логов на хосте и примонтировать её в контейнер.

### 1) 📁 Создать каталог логов на хосте

```bash
mkdir -p /var/log/remnanode
chmod 755 /var/log/remnanode
```

### 2) 🧱 Добавить монтирование логов в `docker-compose.yml`

По сути конфиг стандартный — важно добавить последнюю строку в `volumes`.

```yml
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=2222
      - SECRET_KEY="..."
    volumes:
      - /var/log/remnanode:/var/log/remnanode
```

---

## 📦 JSON-конфиг профиля (начинается здесь)

Ниже — **чистый JSON** для импорта в профиль Remnawave.  
Чтобы было проще ориентироваться: секция Docker закончилась выше, сразу после блока `docker-compose.yml`.

```json
{
  "log": {
    "error": "/var/log/remnanode/error.log",
    "access": "/var/log/remnanode/access.log",
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      "8.8.8.8",
      "1.0.0.1",
      "1.1.1.1"
    ],
    "queryStrategy": "UseIPv4"
  },
  "inbounds": [
    {
      "tag": "block-ru-XHTTP-v2",
      "port": 443,
      "listen": "0.0.0.0",
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
        "security": "tls",
        "tlsSettings": {
          "alpn": [
            "h2",
            "http/1.1"
          ],
          "maxVersion": "1.3",
          "minVersion": "1.2",
          "serverName": "⚠️ЗАМЕНИ СВОЙ ДОМЕН⚠️",
          "certificates": [
            {
              "keyFile": "⚠️/root/cert/⚠️ТВОЙ СЕРТ ЗАМЕНИ⚠️/privkey.key⚠️",
              "certificateFile": "⚠️/root/cert/⚠️ТВОЙ СЕРТ ЗАМЕНИ⚠️/fullchain.pem⚠️"
            }
          ],
          "rejectUnknownSni": false
        },
        "xhttpSettings": {
          "host": "⚠️ЗАМЕНИ СВОЙ ДОМЕН⚠️",
          "mode": "auto",
          "path": "/",
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
    "rules": [
      {
        "ip": [
          "geoip:private"
        ],
        "type": "field",
        "outboundTag": "DIRECT"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "domain": [
          "max.ru",
          "download.max.ru",
          "help.max.ru",
          "ip.mail.ru",
          "privacy-cs.mail.ru",
          "top-fwz1.mail.ru",
          "trk.mail.ru",
          "voskhod.ru",
          "ns1.ok.ru",
          "ns2.ok.ru",
          "ns3.ok.ru",
          "oneme.ru",
          "api.oneme.ru",
          "api-gost.oneme.ru",
          "ws-api.oneme.ru",
          "fgost.oneme.ru",
          "calls.okcdn.ru",
          "gov.ru",
          "mycdn.me",
          "okcdn.ru",
          "vk-analytics.ru",
          "tracker-api.vk-analytics.ru",
          "sdk-api.apptracer.ru",
          "nuc-cdp.digital.gov.ru",
          "nuc-cdp.voskhod.ru",
          "adstat.yandex.ru",
          "mc.yandex.ru",
          "ipv4-internet.yandex.net",
          "ipv6-internet.yandex.net",
          "sferum-dev.ru",
          "vk-apps.ru",
          "vk.ru",
          "vk.com",
          "vk.cc",
          "vk.link",
          "vkontakte.ru",
          "vkontakte.com",
          "vk-cdn.net",
          "userapi.com",
          "vkuser.net",
          "vkuseraudio.com",
          "vkuseraudio.net",
          "vkuservideo.com",
          "vkuservideo.net",
          "vkuserlive.com",
          "vkuserlive.net",
          "vkpay.io",
          "vkpay.com",
          "vkpay.app",
          "vkcs.cloud",
          "ok.ru",
          "odkl.ru",
          "tamtam.chat",
          "ok.me",
          "apiok.ru",
          "apptracer.ru",
          "vkvideo.ru",
          "vk.company",
          "mail.ru",
          "tech-mail.ru",
          "vmailru.net",
          "smailru.net",
          "appsmail.ru",
          "cxhub.ru",
          "dzen.ru",
          "dzeninfra.ru",
          "vkplay.ru",
          "my.games",
          "algoritmika.org",
          "yaklass.ru",
          "umschool.net",
          "code-class.ru",
          "summerstage.ru",
          "vk-stadium.ru",
          "tetrika-school.ru",
          "sberbank-tele.com",
          "sberbank.ru",
          "sberbank.com",
          "2gis.com",
          "2gis.ru",
          "platiqr.ru",
          "sberpay.ru",
          "multiqr.ru",
          "platimultiqr.ru",
          "multiqrpay.ru",
          "sbdv.ru",
          "mysbertips.ru",
          "sber.ru",
          "ozon.ru",
          "finance.ozon.ru",
          "o3t.ru",
          "o3team.ru",
          "ozon-dostavka.ru",
          "o3.ru",
          "ozone.ru",
          "avito.ru",
          "avito.st",
          "t-bank-app.ru",
          "t-bank-app.su",
          "tcsbank.ru",
          "tinkoff.ru",
          "tbank.ru",
          "dolyame.ru",
          "t-tech.team",
          "gosuslugi.ru",
          "gu-st.ru",
          "rt.ru",
          "geobasket.ru",
          "paywb.com",
          "rwb.ru",
          "wb-basket.ru",
          "wb.ru",
          "wbbasket.ru",
          "wbpay.ru",
          "wibes.ru",
          "wildberries.ru"
        ],
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "domain": [
          "regexp:\\.ru$",
          "regexp:\\.su$",
          "regexp:\\.xn--p1ai$"
        ],
        "outboundTag": "BLOCK"
      },
      {
        "ip": [
          "geoip:ru"
        ],
        "type": "field",
        "outboundTag": "BLOCK"
      }
    ],
    "domainStrategy": "AsIs"
  }
}
```

✅ **Конец JSON-конфига** (на этом месте закрывается JSON-объект и блок кода).
