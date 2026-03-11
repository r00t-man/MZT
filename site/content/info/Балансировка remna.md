# ⚖️ Балансировка в Remna (injectHosts + balancers)

Эта статья — практический разбор балансировки трафика в **Remnawave/Remnanode** на базе Xray-логики: как использовать `injectHosts`, `tagPrefix`, `routing.balancers`, `fallbackTag` и когда выбирать `leastLoad`, `leastPing` или `roundRobin`.

Основа: расширенная JSON-логика маршрутизации Xray + механика Remnawave для автоматической инжекции скрытых хостов.

---

## 🧩 Что решает балансировка

Балансировка нужна, когда у вас:

- несколько одинаковых upstream-узлов;
- один основной и несколько резервных;
- разные задержки и нагрузка на узлах в течение суток.

Главная цель: не просто «раскидать» трафик, а сделать схему **устойчивой** — чтобы при деградации одного хоста маршрутизация продолжала работать без ручного переключения.

---

## 🧱 Ключевые элементы

### 1) `injectHosts`

`injectHosts` автоматически добавляет скрытые хосты в конфиг. Пользователь не выбирает их вручную, а `routing` работает с их `tag`.

Чаще всего выбор хостов делается через:

- `remarkRegex` (например, всё что начинается с `BAL-`);
- `uuids` (точечный выбор конкретных узлов).

### 2) `tagPrefix`

`tagPrefix` задаёт основу для авто-тегов:

- `proxy`
- `proxy-2`
- `proxy-3`
- ...

Это удобно, потому что в балансировщике можно использовать `selector: ["proxy"]` и автоматически покрывать всю группу.

### 3) `routing.balancers`

`balancers` управляют тем, какой outbound выбрать в моменте.

Популярные стратегии:

- `leastLoad` — выбор узла с наименьшей текущей нагрузкой/RTT по метрикам observatory;
- `leastPing` — выбор узла с минимальным ping;
- `roundRobin` — поочерёдная отправка запросов по кругу.

### 4) `fallbackTag`

`fallbackTag` — аварийный маршрут, если селектор балансировщика не дал живого/доступного кандидата.

---

## ✅ Базовый рабочий шаблон: виртуальный хост + 3 скрытых узла

```json
{
  "remnawave": {
    "injectHosts": [
      {
        "selector": {
          "type": "remarkRegex",
          "pattern": "^BAL-"
        },
        "tagPrefix": "proxy"
      }
    ]
  },
  "burstObservatory": {
    "pingConfig": {
      "timeout": "3s",
      "interval": "1m",
      "sampling": 1,
      "destination": "http://www.gstatic.com/generate_204",
      "connectivity": ""
    },
    "subjectSelector": ["proxy"]
  },
  "dns": {
    "servers": ["1.1.1.1", "1.0.0.1"],
    "queryStrategy": "UseIP"
  },
  "routing": {
    "domainMatcher": "hybrid",
    "domainStrategy": "IPIfNonMatch",
    "balancers": [
      {
        "tag": "main-balancer",
        "selector": ["proxy"],
        "strategy": {
          "type": "leastLoad",
          "settings": {
            "maxRTT": "1s",
            "expected": 2,
            "baselines": ["1s"],
            "tolerance": 0.01
          }
        },
        "fallbackTag": "direct"
      }
    ],
    "rules": [
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "balancerTag": "main-balancer"
      }
    ]
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "udp": true,
        "auth": "noauth"
      },
      "sniffing": {
        "enabled": true,
        "routeOnly": false,
        "destOverride": ["http", "tls", "quic"]
      }
    },
    {
      "tag": "http",
      "port": 10809,
      "listen": "127.0.0.1",
      "protocol": "http",
      "settings": {
        "allowTransparent": false
      },
      "sniffing": {
        "enabled": true,
        "routeOnly": false,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ]
}
```

### Что тут важно

- `injectHosts` берёт все хосты с `remark` по шаблону `^BAL-`;
- `burstObservatory` собирает метрики для группы `proxy`;
- `leastLoad` выбирает лучший узел по состоянию в моменте;
- `fallbackTag: direct` спасает в аварийном сценарии;
- правило `network: tcp,udp` отправляет весь общий трафик в балансировщик.

---

## 🔁 Альтернатива 1: равномерное распределение (Round Robin)

Подходит, когда узлы примерно одинаковые и не нужна «умная» оценка качества.

```json
{
  "routing": {
    "balancers": [
      {
        "tag": "rr-balancer",
        "selector": ["proxy"],
        "strategy": {
          "type": "roundRobin"
        },
        "fallbackTag": "direct"
      }
    ],
    "rules": [
      {
        "type": "field",
        "network": "tcp,udp",
        "balancerTag": "rr-balancer"
      }
    ]
  }
}
```

---

## 📉 Альтернатива 2: основной + резервы

Схема, когда есть **main** узел и 2+ backup узла.

```json
{
  "remnawave": {
    "injectHosts": [
      {
        "selector": {
          "type": "uuids",
          "values": ["UUID-MAIN", "UUID-BACKUP-1", "UUID-BACKUP-2"]
        },
        "tagPrefix": "proxy"
      }
    ]
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "balancers": [
      {
        "tag": "backup-balancer",
        "selector": ["proxy-"],
        "strategy": {
          "type": "leastPing"
        },
        "fallbackTag": "proxy"
      }
    ],
    "rules": [
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "balancerTag": "backup-balancer"
      }
    ]
  }
}
```

> Практический смысл: резервы подключаются автоматически при ухудшении канала/недоступности, а `fallbackTag` добавляет последнюю ступень отказоустойчивости.

---

## 🧠 Что добавить от себя (best practices)

1. **Смотрите на DNS-часть так же внимательно, как на balancer.**
   Плохой DNS легко «ломает» ощущение от балансировки, даже если сами узлы быстрые.

2. **Не смешивайте много стратегий сразу в одном правиле.**
   Лучше один balancer на один сценарий (общий трафик, media-трафик, backup-сценарий).

3. **Держите понятные теги.**
   Например: `proxy-eu`, `proxy-us`, `proxy-backup` вместо безликих названий.

4. **Проверяйте порядок routing-правил.**
   Сначала узкие исключения (`bittorrent`, служебные сети), потом общий `balancerTag`.

5. **Начинайте с `roundRobin`, переходите на `leastLoad` по мере роста.**
   Это простой путь: от минимальной сложности к более адаптивной схеме.

---

## 🧾 Короткий чек-лист перед запуском

- [ ] Хосты реально подхватываются через `injectHosts`.
- [ ] `selector` в `balancers` совпадает с вашими `tagPrefix`.
- [ ] Есть рабочий `fallbackTag`.
- [ ] Есть observatory/ping-метрики для стратегий качества (`leastLoad`, `leastPing`).
- [ ] В `routing.rules` нет конфликта правил по порядку.

---

## Итог

Для большинства сценариев Remna хороший старт:

- `injectHosts + tagPrefix` для группировки узлов;
- `leastLoad` для «умной» балансировки под текущую нагрузку;
- `fallbackTag` как обязательная страховка;
- понятные `routing.rules` без пересечений.

Если нужна простая и предсказуемая схема — берите `roundRobin`. Если важнее качество канала в реальном времени — `leastLoad`/`leastPing` + observatory.
