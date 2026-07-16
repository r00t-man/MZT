# 📌 Шпаргалка: VLESS → JSON (дополнение к Remna)

Вот удобная шпаргалка: **что из VLESS-ссылки брать и куда вставлять в балансировочный JSON**.

---

## 1. Что из ссылки куда вставляется

Возьмём типовую ссылку:

```text
vless://UUID@node.example.com:443?security=reality&type=tcp&flow=xtls-rprx-vision&sni=github.com&pbk=PUBLIC_KEY&sid=SHORT_ID#NodeName
```

### Из начала ссылки

```text
vless://UUID@node.example.com:443
```

#### `UUID`

Идёт сюда:

```json
"users": [
  {
    "id": "UUID"
  }
]
```

#### `node.example.com`

Идёт сюда:

```json
"address": "node.example.com"
```

#### `443`

Идёт сюда:

```json
"port": 443
```

### Из параметров ссылки

#### `flow=xtls-rprx-vision`

Идёт сюда:

```json
"flow": "xtls-rprx-vision"
```

#### `sni=github.com`

Идёт сюда:

```json
"serverName": "github.com"
```

#### `pbk=PUBLIC_KEY`

Идёт сюда:

```json
"publicKey": "PUBLIC_KEY"
```

#### `sid=SHORT_ID`

Идёт сюда:

```json
"shortId": "SHORT_ID"
```

---

## 2. Готовое соответствие одним блоком

Если есть ссылка:

```text
vless://UUID@node.example.com:443?security=reality&type=tcp&flow=xtls-rprx-vision&sni=github.com&pbk=PUBLIC_KEY&sid=SHORT_ID#NodeName
```

то из неё получается такой `outbound`:

```json
{
  "tag": "TO-NODE-1",
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "node.example.com",
        "port": 443,
        "users": [
          {
            "id": "UUID",
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
      "publicKey": "PUBLIC_KEY",
      "shortId": "SHORT_ID"
    }
  }
}
```

---

## Что НЕ берётся из VLESS-ссылки

Есть важный момент: **не всё берётся из клиентской ссылки**.

### Для `inbound` на балансирующем сервере нужны отдельные данные

Это уже не из ссылки удалённой ноды, а **с самого входного сервера**, который принимает клиента.

### Эти значения надо генерировать или брать на самом сервере

#### `privateKey`

Сюда:

```json
"privateKey": "PRIVATE_KEY"
```

Это **приватный ключ Reality входного сервера**.

#### `shortIds`

Сюда:

```json
"shortIds": [
  "SHORT_ID_FOR_INBOUND"
]
```

Это **shortId входного сервера**, а не удалённой ноды.

#### `dest`

Сюда:

```json
"dest": "github.com:443"
```

Это сайт для маскировки входного Reality.

#### `serverNames`

Сюда:

```json
"serverNames": [
  "github.com"
]
```

Обычно совпадает с маскировочным доменом.

---

## Что относится к inbound, а что к outbound

### `inbound`

Это:

- сервер, на который подключается клиент
- твой балансирующий / каскадный узел

Тут свои:

- `privateKey`
- `shortIds`
- `dest`
- `serverNames`

### `outbound`

Это:

- удалённые ноды, куда балансировщик пересылает трафик

Тут берём из VLESS-ссылок:

- `address`
- `port`
- `id`
- `flow`
- `serverName`
- `publicKey`
- `shortId`

---

## Как назвать теги

Чтобы балансировка работала удобно, делай так:

```json
"tag": "TO-DE-1"
"tag": "TO-PL-1"
"tag": "TO-EE-1"
"tag": "TO-NL-1"
```

Почему так:

- все балансируемые ноды начинаются с `TO-`
- тогда можно использовать:

```json
"selector": ["TO-"]
```

и Xray автоматически включит все такие outbound’ы в балансировщик.

---

## Как добавить новую ноду

Допустим, дали новую ссылку:

```text
vless://NEW_UUID@fr.example.com:443?security=reality&type=tcp&flow=xtls-rprx-vision&sni=github.com&pbk=NEW_PBK&sid=NEW_SID#France
```

Тогда просто добавляешь ещё один блок:

```json
{
  "tag": "TO-FR-1",
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "fr.example.com",
        "port": 443,
        "users": [
          {
            "id": "NEW_UUID",
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
      "publicKey": "NEW_PBK",
      "shortId": "NEW_SID"
    }
  }
}
```

И всё. Если тег начинается с `TO-`, нода автоматически попадёт в:

```json
"subjectSelector": ["TO-"]
```

и:

```json
"selector": ["TO-"]
```

---

## Что менять, если другой человек делает такой конфиг

### Обязательно заменить

#### В `inbound`

- `tag`
- `port`
- `dest`
- `shortIds`
- `privateKey`
- `serverNames`

#### В каждом `outbound`

- `tag`
- `address`
- `port`
- `id`
- `flow`
- `serverName`
- `publicKey`
- `shortId`

#### В `balancers`

- `fallbackTag`

### Что обычно можно не менять

Чаще всего оставляют как есть:

```json
"protocol": "vless"
"network": "raw"
"security": "reality"
"encryption": "none"
"level": 0
```

И ещё часто не трогают:

```json
"sniffing": {
  "enabled": true,
  "destOverride": ["http", "tls", "quic"]
}
```

---

## Как понять, что конфиг собран правильно

Проверь 5 вещей:

1. У всех нод уникальные `tag`.
2. Все балансируемые ноды начинаются с `TO-`.
3. `fallbackTag` совпадает с существующим тегом.
4. У inbound свой `privateKey`, не от чужой ноды.
5. `publicKey` в outbound — это именно `pbk` из ссылки удалённой ноды.

---

## Мини-шпаргалка в одну строку

### Из ссылки

- `UUID` → `users[0].id`
- `host` → `vnext.address`
- `port` → `vnext.port`
- `flow` → `users[0].flow`
- `sni` → `realitySettings.serverName`
- `pbk` → `realitySettings.publicKey`
- `sid` → `realitySettings.shortId`

### Не из ссылки

- `inbound.privateKey`
- `inbound.shortIds`
- `inbound.dest`
- `inbound.serverNames`

---

## Самый короткий шаблон для копирования новой ноды

```json
{
  "tag": "TO-COUNTRY-1",
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "NODE_HOST",
        "port": 443,
        "users": [
          {
            "id": "NODE_UUID",
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
      "publicKey": "NODE_PUBLIC_KEY",
      "shortId": "NODE_SHORT_ID"
    }
  }
}
```
