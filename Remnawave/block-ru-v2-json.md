
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
          "serverName": "ЗАМЕНИ СВОЙ ДОМЕН",
          "certificates": [
            {
              "keyFile": "/root/cert/ТВОЙ СЕРТ ЗАМЕНИ/privkey.key",
              "certificateFile": "/root/cert/ТВОЙ СЕРТ ЗАМЕНИ/fullchain.pem"
            }
          ],
          "rejectUnknownSni": false
        },
        "xhttpSettings": {
          "host": "ЗАМЕНИ СВОЙ ДОМЕН",
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