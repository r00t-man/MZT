# ⚖️ Конфиг балансировки в Remnawave (для новичков) — подробный разбор

> 🧭 Эта инструкция написана максимально «человечески»: с пояснениями **что это**, **зачем это**, **где брать значения** и **как не сломать прод**.

---

> 📝 Отдельное пояснение по резерву для обхода белых списков (с акцентом на Яндекс-ноды):<br>
> [Примечание: резерв для Яндекс-ноды](./Примечание%20к%20балансировке%20remna%20—%20резерв%20для%20Яндекс-ноды.md). <br>
> 📌 И отдельная статья [Шпаргалка: VLESS → JSON](./Шпаргалка%20VLESS%20в%20балансировочный%20JSON%20для%20remna.md)

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

## 🆕 Современный способ: автоподстановка нод через `injectHosts`

> [!TIP]
> Если панель Remnawave достаточно свежая — весь ручной JSON ниже можно не писать вообще. Оставьте
> раздел как справку «что происходит под капотом» и для нетиповых случаев (кастомные теги, ноды не
> из этой панели и т.п.), а для обычной сборки балансировщика используйте это.

Вместо того чтобы руками вытаскивать `UUID`/`publicKey`/`shortId` из VLESS-ссылки каждой ноды и
вставлять их в `outbounds` (как показано ниже), панель умеет подставлять их сама через корневой ключ
`remnawave.injectHosts` в JSON-шаблоне:

1. Заводите ноды как обычные **Host** в панели (как для любого другого профиля).
2. Хосты-участники балансировки помечаете **Hidden** (карточка хоста → Advanced → Hide Host).
3. В шаблоне указываете `injectHosts` с селектором — по `uuids`, `remarkRegex`, `tagRegex` или
   `sameTagAsRecipient` (все скрытые хосты с тем же тегом, что у «виртуального» хоста-носителя).
4. Шаблон вешаете на отдельный **виртуальный хост** — он не участвует в реальном подключении, нужен
   только как носитель шаблона и remark; его адрес может быть любым.
5. При генерации подписки панель сама подставляет outbound-блоки нод в начало `outbounds`, с тегами
   `proxy`, `proxy-2`, `proxy-3`… (первый тег — без суффикса, его удобно использовать как `fallbackTag`).

Минимальный шаблон (селектор по UUID хостов, остальное — `outbounds`/`balancers`/`burstObservatory`
из этой статьи без изменений):

```json
{
  "remnawave": {
    "injectHosts": [
      {
        "selector": {
          "type": "uuids",
          "values": ["UUID_ХОСТА_1", "UUID_ХОСТА_2", "UUID_ХОСТА_3"]
        },
        "tagPrefix": "TO"
      }
    ]
  },
  "burstObservatory": {
    "pingConfig": { "timeout": "3s", "interval": "1m" },
    "subjectSelector": ["TO"]
  },
  "routing": {
    "balancers": [
      {
        "tag": "MAIN-BALANCER",
        "selector": ["TO"],
        "strategy": { "type": "roundRobin" },
        "fallbackTag": "TO"
      }
    ]
  }
}
```

Подробности (типы селекторов, `useHostRemarkAsTag`/`useHostTagAsTag`, порядок подстановки outbound'ов,
условия работы) — в официальной документации: [Xray JSON — Advanced](https://docs.rw/learn/xray-json-advanced/).

---

## 🛠️ Ручная сборка (что происходит под капотом / для нетиповых случаев)

Ниже — учебный обезличенный пример именно для `roundRobin`, если нужно понять логику или собрать
конфиг руками (панель без `injectHosts`, ноды не заведены как Host в этой панели, кастомная схема
тегов). Все чувствительные данные — заглушки: UUID, ключи, shortId, адреса серверов и маскирующие домены.

> [!IMPORTANT]
> Блок ниже — **для чтения и понимания логики**. Он специально дан **не как чистый JSON**, а как
> учебный шаблон с комментариями. Перед вставкой в рабочий конфиг уберите комментарии и подставьте
> свои значения.

```json
{
  "log": {
    // Базовый уровень логирования: для старта обычно достаточно info
    "loglevel": "info"
  },

  "inbounds": [
    {
      // Тег входа балансировщика.
      // Именно на него потом ссылается routing.rules[].inboundTag
      "tag": "BALANCER-IN",
      "port": 443,
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {
        // В Remnawave список клиентов часто ведётся отдельно
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
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          // Маскирующий HTTPS-ресурс для входа
          "dest": "cover.example.com:443",
          "show": false,
          "xver": 0,
          // Это параметры именно входного Reality на балансировщике
          "shortIds": [
            "REPLACE_WITH_BALANCER_SHORT_ID"
          ],
          "privateKey": "REPLACE_WITH_BALANCER_PRIVATE_KEY",
          "serverNames": [
            "cover.example.com"
          ]
        }
      }
    }
  ],

  "outbounds": [
    {
      // Нода №1
      "tag": "TO-DE-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "de-node-1.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      // Нода №2
      "tag": "TO-PL-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "pl-node-1.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      // Нода №3
      "tag": "TO-EE-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "ee-node-1.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      // Нода №4
      "tag": "TO-NL-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "nl-node-1.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      // Дополнительная нода, если хотите расширить пул
      "tag": "TO-DE-2",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "de-node-2.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      // Отдельная резервная нода, не входящая в selector TO-
      "tag": "YA-BACKUP",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "backup-node.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_BACKUP_UUID",
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
          "shortId": "REPLACE_WITH_BACKUP_SHORT_ID",
          "publicKey": "REPLACE_WITH_BACKUP_PUBLIC_KEY",
          "serverName": "cover.example.com"
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

  "routing": {
    "rules": [
      {
        // Рекламные домены сразу режем
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "BLOCK"
      },
      {
        // Локальные/нужные домены можно пустить напрямую мимо балансировщика
        "domain": [
          "regexp:.*\.ru$",
          "regexp:.*\.su$",
          "regexp:.*\.xn--p1ai$"
        ],
        "outboundTag": "DIRECT"
      },
      {
        // Всё, что пришло на балансировочный inbound,
        // отправляем в balancer MAIN-BALANCER
        "inboundTag": [
          "BALANCER-IN"
        ],
        "balancerTag": "MAIN-BALANCER"
      }
    ],
    "balancers": [
      {
        "tag": "MAIN-BALANCER",
        // В пул попадают все outbound с тегом, начинающимся на TO-
        "selector": [
          "TO-"
        ],
        "strategy": {
          // Для roundRobin ноды выбираются строго по кругу
          "type": "roundRobin"
        },
        // Отдельный резерв на случай проблем с основным пулом
        "fallbackTag": "YA-BACKUP"
      }
    ],
    "domainStrategy": "AsIs"
  }
}
```

### Что важно именно для `roundRobin`

- `burstObservatory` и замеры ping **не обязательны**, потому что стратегия не ориентируется на latency.
- В балансировку попадут **только** те `outbound`, чьи теги подходят под `selector`, то есть начинаются с `TO-`.
- `fallbackTag` удобно держать отдельным, чтобы резервная нода не участвовала в обычном цикле round robin.
- Если хотите, чтобы резерв тоже участвовал в круге, дайте ему тег вида `TO-...` и не выносите его в отдельный `fallbackTag`.

Тут подробнее отдельная статья [Резервная нода (должна существовать в outbounds)](./Примечание%20к%20балансировке%20remna%20—%20резерв%20для%20Яндекс-ноды.md)

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

- `tag` — любое понятное имя (например, `BALANCER-IN`)
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
4. Если используете отдельный резерв, проверьте, что `fallbackTag` указывает на реально существующий тег.
5. Для `roundRobin` убедитесь, что все нужные ноды попадают под `selector` (например, имеют префикс `TO-`).

---

## 🧪 Минимальный чек-лист после настройки

- [ ] Конфиг валидируется без ошибок синтаксиса.
- [ ] В `outbounds` есть минимум 2 ноды с тегом `TO-...`.
- [ ] `fallbackTag` указывает на существующий тег, если вы используете резерв.
- [ ] `burstObservatory` включён только если используете `leastLoad` или `leastPing`; для `roundRobin` он не нужен.
- [ ] Нет утечки `privateKey` в публичных репозиториях/скринах.

---

## ✅ Рекомендация для старта

Если вы раньше не работали с балансировкой:

1. Если нужен самый простой и предсказуемый режим — начните с `roundRobin`.
2. Если позже захотите выбирать ноду по качеству канала — переходите на `leastPing`.
3. Если нагрузка сильно «плавает» — пробуйте `leastLoad`.
4. После любой смены стратегии проверьте маршрутизацию и логи.

---

## 🧩 Чистый шаблон без комментариев (для вставки)

```json
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "tag": "BALANCER-IN",
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
          "dest": "cover.example.com:443",
          "show": false,
          "xver": 0,
          "shortIds": ["REPLACE_WITH_BALANCER_SHORT_ID"],
          "privateKey": "REPLACE_WITH_BALANCER_PRIVATE_KEY",
          "serverNames": ["cover.example.com"]
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
            "address": "de-node-1.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      "tag": "TO-PL-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "pl-node-1.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      "tag": "TO-EE-1",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "ee-node-1.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_SHARED_OR_NODE_UUID",
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
          "shortId": "REPLACE_WITH_NODE_SHORT_ID",
          "publicKey": "REPLACE_WITH_NODE_PUBLIC_KEY",
          "serverName": "github.com"
        }
      }
    },
    {
      "tag": "YA-BACKUP",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "backup-node.example.net",
            "port": 443,
            "users": [
              {
                "id": "REPLACE_WITH_BACKUP_UUID",
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
          "shortId": "REPLACE_WITH_BACKUP_SHORT_ID",
          "publicKey": "REPLACE_WITH_BACKUP_PUBLIC_KEY",
          "serverName": "cover.example.com"
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
  "routing": {
    "domainStrategy": "AsIs",
    "balancers": [
      {
        "tag": "MAIN-BALANCER",
        "selector": ["TO-"],
        "strategy": {
          "type": "roundRobin"
        },
        "fallbackTag": "YA-BACKUP"
      }
    ],
    "rules": [
      {
        "domain": ["geosite:category-ads-all"],
        "outboundTag": "BLOCK"
      },
      {
        "domain": [
          "regexp:.*\.ru$",
          "regexp:.*\.su$",
          "regexp:.*\.xn--p1ai$"
        ],
        "outboundTag": "DIRECT"
      },
      {
        "inboundTag": ["BALANCER-IN"],
        "balancerTag": "MAIN-BALANCER"
      }
    ]
  }
}
```
