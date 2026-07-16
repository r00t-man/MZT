# 🛣️ Правила маршрутизации Remna

Эта статья объясняет, как писать правила маршрутизации для профилей **Remnawave/Remnanode**: от базовых понятий до практических примеров с `DIRECT`, `WARP`, `BLOCK` и каскадными маршрутами.

---

## 📘 Базовые понятия (кратко по логике документации Remnawave)

В конфигурации Remnawave (на базе Xray-совместимого формата) обычно участвуют следующие блоки:

- 📥 **inbounds** — где и как клиентский трафик принимается на сервере.
- 📤 **outbounds** — куда трафик уходит дальше (напрямую, в прокси, в туннель, в blackhole и т.д.).
- 🧭 **routing** — правила, которые решают, какой трафик в какой `outbound` отправлять.
- 🧩 **tag** — имя маршрута/узла, по которому routing связывает правило и конкретный outbound.

> ⚠️ Важный принцип: правила в `routing.rules` проверяются **сверху вниз**, поэтому порядок правил критически важен.

---

## 🧱 Основные элементы маршрутизации

### 1) 📤 `outbounds`

`outbounds` определяют каналы выхода трафика.

- 🟢 **DIRECT** — прямой выход без VPN/прокси.
- ☁️ **WARP** — выход через SOCKS5-прокси WARP.
- ⛔ **BLOCK** — блокировка трафика (blackhole).

Пример:

```json
"outbounds": [
  {
    "tag": "DIRECT",
    "protocol": "freedom"
  },
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
    "tag": "BLOCK",
    "protocol": "blackhole"
  }
]
```

### 2) 🧭 `routing.rules`

В `routing` вы задаёте условия (домены, geosite, IP, protocol и т.д.) и назначаете `outboundTag`.

Пример:

```json
"routing": {
  "domainStrategy": "AsIs",
  "rules": [
    {
      "domain": [
        "regexp:\\.ru$",
        "regexp:\\.su$",
        "regexp:\\.рф$",
        "regexp:\\.xn--p1ai$"
      ],
      "outboundTag": "DIRECT"
    },
    {
      "domain": [
        "geosite:category-ads-all"
      ],
      "outboundTag": "BLOCK"
    },
    {
      "domain": [
        "domain:youtube.com",
        "domain:chat.openai.com"
      ],
      "outboundTag": "WARP"
    }
  ]
}
```

---

## 🔍 Как это работает

- 🇷🇺 Домены `.ru`, `.su`, `.рф`, `.xn--p1ai` идут через `DIRECT`.
- 🚫 Рекламные домены из `geosite:category-ads-all` блокируются через `BLOCK`.
- 🌍 Выбранные сервисы (`youtube.com`, `chat.openai.com`) идут через `WARP`.

---

## 🧠 Полезные приёмы

- 🧪 **Регулярные выражения**:
  - `"regexp:\\.ru$"` — все домены, оканчивающиеся на `.ru`
  - `"regexp:^www\\."` — все домены, начинающиеся с `www.`

- 🗂️ **geosite-категории**:
  - `geosite:category-ads-all` — рекламные домены
  - при необходимости можно добавлять другие категории (например, foreign/china и т.д.)

- ⛔ **Блокировка**:
  - для запрета трафика достаточно направить правило в `"outboundTag": "BLOCK"`.

---

## 🧪 Дополнительные шаблоны

### Шаблон 1: WARP для выбранных доменов, RU — напрямую

```json
"routing": {
  "domainStrategy": "AsIs",
  "rules": [
    {
      "domain": [
        "regexp:\\.ru$",
        "regexp:\\.su$",
        "regexp:\\.рф$",
        "regexp:\\.xn--p1ai$"
      ],
      "outboundTag": "DIRECT"
    },
    {
      "domain": [
        "domain:youtube.com",
        "domain:chat.openai.com"
      ],
      "outboundTag": "WARP"
    }
  ]
}
```

### Шаблон 2: Только один сайт через WARP

```json
"routing": {
  "domainStrategy": "AsIs",
  "rules": [
    {
      "domain": [
        "domain:example.com"
      ],
      "outboundTag": "WARP"
    },
    {
      "domain": [
        "regexp:\\.ru$",
        "regexp:\\.su$"
      ],
      "outboundTag": "DIRECT"
    }
  ]
}
```

---

## 🧬 Каскадная схема: RU ➜ DE ➜ WARP

Ниже логика для multi-hop сценария:

1. 🇷🇺 Российские домены — через локальный/российский маршрут.
2. 🇩🇪 Иностранный трафик — через узел в Германии.
3. ☁️ Отдельные сервисы (например YouTube/ChatGPT) — через WARP.
4. 🚫 Реклама — в `BLOCK`.

### Пример конфигурации (адаптируйте под свои ключи/адреса)

```json
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "tag": "YANDEX-RU",
      "port": 443,
      "listen": "0.0.0.0",
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
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "dest": "ads.x5.ru:443",
          "show": false,
          "xver": 0,
          "shortIds": ["*****"],
          "privateKey": "*****",
          "serverNames": ["ads.x5.ru"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "TO-DE",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "port": 443,
            "users": [
              {
                "id": "*****",
                "flow": "xtls-rprx-vision",
                "level": 0,
                "encryption": "none"
              }
            ],
            "address": "de-node-1.example.net"
          }
        ]
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "shortId": "*****",
          "publicKey": "*****",
          "serverName": "github.com"
        }
      }
    },
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    },
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
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "domain": ["geosite:category-ads-all"],
        "outboundTag": "BLOCK"
      },
      {
        "domain": [
          "regexp:.*\\.ru$",
          "regexp:.*\\.su$",
          "regexp:.*\\.xn--p1ai$"
        ],
        "outboundTag": "DIRECT"
      },
      {
        "domain": ["geosite:category-foreign"],
        "outboundTag": "TO-DE"
      },
      {
        "domain": ["domain:youtube.com", "domain:chat.openai.com"],
        "outboundTag": "WARP"
      }
    ]
  }
}
```

---
[📌 Шпаргалка: VLESS → JSON](./Шпаргалка%20VLESS%20в%20балансировочный%20JSON%20для%20remna.md)

## ✅ Итог

Чтобы написать свои правила маршрутизации в Remnawave:

1. Определите набор `outbounds` (например `DIRECT`, `WARP`, `BLOCK`, `TO-DE`).
2. Опишите `routing.rules` по доменам/категориям/IP.
3. Проверьте порядок правил сверху вниз.
4. Протестируйте профиль и при необходимости уточните исключения регулярными выражениями.

Такой подход даёт гибкую и управляемую маршрутизацию под любые сценарии: от простого split-трафика до каскадного multi-hop.
