# ⚖️ Конфиг балансировки в Remnawave (для новичков) — подробный разбор

> 🧭 Эта инструкция написана максимально «человечески»: с пояснениями **что это**, **зачем это**, **где брать значения** и **как не сломать прод**.

---

> 📝 Отдельное пояснение по резерву для обхода белых списков (с акцентом на Яндекс-ноды): [Примечание: резерв для Яндекс-ноды](./Примечание%20к%20балансировке%20remna%20—%20резерв%20для%20Яндекс-ноды.md).

## 📌 Что вообще делает балансировка в Remnawave

Если простыми словами:

- у вас есть **одна точка входа** (балансирующий сервер);
- и есть **несколько удалённых нод** (Германия, Польша, Нидерланды и т.д.);
- балансировщик решает, **на какую ноду отправить трафик прямо сейчас**.

Зачем это нужно:

- 🚀 меньше лагов у пользователей;
- 🛡️ выше отказоустойчивость (если одна нода недоступна, можно уйти на другую);
- ⚙️ меньше ручной рутины (не нужно каждый раз переключать ноду руками).

---

## 🧠 Три популярные стратегии выбора ноды

В `routing.balancers[].strategy.type` можно использовать:

### 1) `leastLoad`

**Что делает:** выбирает ноду с наименьшей текущей нагрузкой/RTT по метрикам `observatory`.

✅ Плюсы:

- обычно самый «умный» режим;
- может давать более стабильный результат при неравномерной нагрузке.

⚠️ Важно:

- зависит от корректной телеметрии (`burstObservatory`/`observatory`);
- если метрики не собираются — пользы меньше.

---

### 2) `leastPing`

**Что делает:** выбирает ноду с минимальным ping.

✅ Плюсы:

- просто и предсказуемо;
- очень хороший стартовый вариант для большинства.

⚠️ Важно:

- ping не всегда отражает реальную пропускную способность канала.

---

### 3) `roundRobin`

**Что делает:** отправляет запросы по кругу: нода 1 → нода 2 → нода 3 → снова нода 1.

✅ Плюсы:

- равномерное распределение;
- легко проверять и отлаживать.

⚠️ Важно:

- не учитывает качество канала в реальном времени.

---

## 🔐 Важное про безопасность перед началом

### Никогда не публикуйте в открытом доступе:

- `privateKey` входного Reality-сервера;
- рабочие `UUID` клиентов в боевой среде;
- живые полные VLESS-ссылки.

### Лучше маскировать:

- `publicKey`;
- `shortId`;
- реальные домены/адреса нод.

---

## 🛠️ Обезличенный учебный конфиг с комментариями (JSON)

> ⚠️ Важно: обычный JSON **не поддерживает комментарии**.
> Этот блок нужен для чтения/обучения. Перед вставкой в рабочий Xray/Remnawave удалите комментарии.

```jsonc
{
  "log": {
    // Уровень логов: info / warning / error / debug
    "loglevel": "info"
  },

  "inbounds": [
    {
      // Имя входящего подключения (используется в routing.rules.inboundTag)
      "tag": "BALANCE-ENTRY",

      // Порт приёма клиентов
      "port": 443,
      "listen": "0.0.0.0",
      "protocol": "vless",

      "settings": {
        // В Remnawave клиенты часто управляются отдельно
        "clients": [],
        "decryption": "none"
      },

      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      },

      "streamSettings": {
        // Для Reality TCP — network=raw
        "network": "raw",
        "security": "reality",

        "realitySettings": {
          // Домен-маска (доступный HTTPS-сайт)
          "dest": "REPLACE_DEST_SITE:443",
          "show": false,
          "xver": 0,

          // shortId и privateKey ИМЕННО этого входного сервера
          "shortIds": ["REPLACE_WITH_INBOUND_SHORT_ID"],
          "privateKey": "REPLACE_WITH_INBOUND_PRIVATE_KEY",

          "serverNames": ["REPLACE_DEST_SITE"]
        }
      }
    }
  ],

  "outbounds": [
    {
      // Удалённая нода №1
      "tag": "TO-DE-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "replace-node-1.example.com",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_NODE_UUID",
                "flow": "xtls-rprx-vision",
                "level": 0,
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "serverName": "github.com",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "shortId": "REPLACE_WITH_NODE_SHORT_ID"
        }
      }
    },

    {
      // Удалённая нода №2
      "tag": "TO-PL-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "replace-node-2.example.com",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_NODE_UUID",
                "flow": "xtls-rprx-vision",
                "level": 0,
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "serverName": "github.com",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "shortId": "REPLACE_WITH_NODE_SHORT_ID"
        }
      }
    },

    {
      // Удалённая нода №3
      "tag": "TO-EE-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "replace-node-3.example.com",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_NODE_UUID",
                "flow": "xtls-rprx-vision",
                "level": 0,
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "serverName": "github.com",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "shortId": "REPLACE_WITH_NODE_SHORT_ID"
        }
      }
    },

    {
      // Удалённая нода №4
      "tag": "TO-NL-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "replace-node-4.example.com",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_NODE_UUID",
                "flow": "xtls-rprx-vision",
                "level": 0,
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "serverName": "github.com",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "shortId": "REPLACE_WITH_NODE_SHORT_ID"
        }
      }
    },

    {
      // Прямой выход с балансировочного сервера
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      // Блокировка трафика
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],

  "burstObservatory": {
    "pingConfig": {
      // Хост для проверок доступности
      "destination": "http://www.gstatic.com/generate_204",
      "interval": "1m",
      "sampling": 1,
      "timeout": "3s",
      "connectivity": ""
    },
    // Собираем метрики по outbound-тегам TO-
    "subjectSelector": ["TO-"]
  },

  "routing": {
    "domainStrategy": "AsIs",

    "balancers": [
      {
        "tag": "MAIN-BALANCER",
        "selector": ["TO-"],
        "strategy": {
          // Варианты: leastLoad / leastPing / roundRobin
          "type": "leastPing"
        },

        // Резервная нода (должна существовать в outbounds - ниже пояснение)
        "fallbackTag": "TO-DE-1"
      }
    ],

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
        "inboundTag": ["BALANCE-ENTRY"],
        "balancerTag": "MAIN-BALANCER"
      }
    ]
  }
}
```

Тут подробнее отдельная статья [Резервная нода (должна существовать в outbounds)](https://github.com/r00t-man/MZT/blob/main/info/%D0%9F%D1%80%D0%B8%D0%BC%D0%B5%D1%87%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%BA%20%D0%B1%D0%B0%D0%BB%D0%B0%D0%BD%D1%81%D0%B8%D1%80%D0%BE%D0%B2%D0%BA%D0%B5%20remna%20%E2%80%94%20%D1%80%D0%B5%D0%B7%D0%B5%D1%80%D0%B2%20%D0%B4%D0%BB%D1%8F%20%D0%AF%D0%BD%D0%B4%D0%B5%D0%BA%D1%81-%D0%BD%D0%BE%D0%B4%D1%8B.md)

---

## 🧾 Быстрая шпаргалка: что из VLESS-ссылки куда вставлять

Для каждого `outbound` (каждой удалённой ноды):

- `address` ← хост после `@`
- `port` ← порт после `:`
- `id` ← UUID до `@`
- `serverName` ← `sni=...`
- `publicKey` ← `pbk=...`
- `shortId` ← `sid=...`
- `flow` ← обычно `xtls-rprx-vision`

---

## 🧱 Что менять во входном блоке (`inbounds`)

Это данные **самого балансировочного сервера**:

- `tag` — любое понятное имя (например, `BALANCE-ENTRY`)
- `port` — обычно `443`
- `dest` — сайт для маскировки (`github.com:443` и т.п.)
- `shortIds` — shortId этого входного Reality
- `privateKey` — приватный ключ этого входного Reality
- `serverNames` — домены маскировки

---

## 🔁 Как переключать стратегию в 1 строку

### Вариант A — lowest ping

```json
"strategy": { "type": "leastPing" }
```

### Вариант B — минимальная нагрузка

```json
"strategy": { "type": "leastLoad" }
```

### Вариант C — по кругу

```json
"strategy": { "type": "roundRobin" }
```

---

## ➕ Как добавить ещё одну ноду

1. Скопируйте любой блок `TO-...` в `outbounds`.
2. Измените:
   - `tag`
   - `address`
   - `id`
   - `serverName`
   - `publicKey`
   - `shortId`
3. Убедитесь, что `tag` начинается с `TO-` (иначе селектор `"TO-"` её не подхватит).
4. Проверьте, что `fallbackTag` указывает на реально существующий тег.

---

## 🧪 Минимальный чек-лист после настройки

- [ ] Конфиг валидируется без ошибок синтаксиса.
- [ ] В `outbounds` есть минимум 2 ноды с тегом `TO-...`.
- [ ] `fallbackTag` указывает на существующий `TO-...`.
- [ ] Включён `burstObservatory`, если используете `leastLoad` или `leastPing`.
- [ ] Нет утечки `privateKey` в публичных репозиториях/скринах.

---

## ✅ Рекомендация для старта

Если вы раньше не работали с балансировкой:

1. Начните с `leastPing`.
2. Понаблюдайте несколько дней.
3. Если нагрузка сильно «плавает» — попробуйте `leastLoad`.
4. Для максимально простого предсказуемого режима — `roundRobin`.

---

## 🧩 Чистый шаблон без комментариев (для вставки)

```json
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "tag": "BALANCE-ENTRY",
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
          "dest": "REPLACE_DEST_SITE:443",
          "show": false,
          "xver": 0,
          "shortIds": ["REPLACE_WITH_INBOUND_SHORT_ID"],
          "privateKey": "REPLACE_WITH_INBOUND_PRIVATE_KEY",
          "serverNames": ["REPLACE_DEST_SITE"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "TO-DE-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "replace-node-1.example.com",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_NODE_UUID",
                "flow": "xtls-rprx-vision",
                "level": 0,
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "serverName": "github.com",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "shortId": "REPLACE_WITH_NODE_SHORT_ID"
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
    }
  ],
  "burstObservatory": {
    "pingConfig": {
      "destination": "http://www.gstatic.com/generate_204",
      "interval": "1m",
      "sampling": 1,
      "timeout": "3s",
      "connectivity": ""
    },
    "subjectSelector": ["TO-"]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "balancers": [
      {
        "tag": "MAIN-BALANCER",
        "selector": ["TO-"],
        "strategy": {
          "type": "leastPing"
        },
        "fallbackTag": "TO-DE-1"
      }
    ],
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
        "inboundTag": ["BALANCE-ENTRY"],
        "balancerTag": "MAIN-BALANCER"
      }
    ]
  }
}
```
