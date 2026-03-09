# 🛡️ Установка собственного DNS сервера на базе AdGuard

[![Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![AdGuard](https://img.shields.io/badge/AdGuard-Home-3DDC84?logo=adguard&logoColor=white)](https://adguard.com/)
[![GitHub](https://img.shields.io/badge/Code-AdGuardHome-181717?logo=github&logoColor=white)](https://github.com/AdguardTeam/AdGuardHome)
[![Certbot](https://img.shields.io/badge/SSL-Certbot-2E7D32?logo=letsencrypt&logoColor=white)](https://certbot.eff.org/)
[![Guide](https://img.shields.io/badge/AdGuard-Официальная%20инструкция-00BFFF?logo=bookstack&logoColor=white)](https://adguard.com/ru/blog/adguard-home-on-public-server.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

---

📖 Полные официальные материалы:  
- 👉 [AdGuard Home на публичном сервере (Blog)](https://adguard.com/ru/blog/adguard-home-on-public-server.html)  
- 👉 [AdGuard Home на GitHub](https://github.com/AdguardTeam/AdGuardHome)  

## 1️⃣ Приобретение сервера  
Минимальные требования: **4 ГБ RAM**.  

Рекомендую [HostVDS](https://hostvds.com/?affiliate_uuid=92b0d8b4-f87f-4753-bb6a-c17f915c40da)  
(партнёрская ссылка, буду признателен за регистрацию по ней).  

Так же выбираем локацию ближе к себе, тут это **Финляндия** и тариф **2CPU + 4RAM**

---

## 2️⃣ Установка ОС  <br>
<br>
Ставим Ubuntu 24.04 <br>
Так же можем сразу добавить ssh-ключ что бы входить без пароля

После установки обновляем систему и ставим нужные пакеты:  

```bash
apt update && apt upgrade -y && apt dist-upgrade dnsutils knot-dnsutils ifupdown -y
apt install -y nano mc htop curl openssl systemd fail2ban nftables snapd
snap install core && snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
````

> \[!TIP]
> Во время установки будут вопросы о замене файлов конфигурации.
> Отвечаем **"1"** или **"yes"** (перезаписать).

---

## 3️⃣ Установка AdGuard Home ⚙️

```bash
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
```

Скрипт выдаст ссылки для доступа в **панель управления**.
Откройте `http://xxx.xxx.xxx.xxx:3000` (где `xxx.xxx.xxx.xxx` — ваш IP) и выполните первоначальную настройку.

> \[!IMPORTANT]
> • Используйте максимально сложный логин и пароль. <br>
> • Панель администрирования будет доступна через интернет — закрыть её без потери DOH нельзя. <br>
> • ⚠️**Обязательно меняйте стандартный порт** (например, `8081` вместо 80/443). <br>
> • ⚠️⚠️⚠️ 80 и 443 порты **НЕ ЗАНИМАТЬ** ⚠️⚠️⚠️

---

## 4️⃣ Решение конфликта с портом 53 🔌

Скорее всего будет сообщение:

```
alidating ports: listen tcp 0.0.0.0:53: bind: address already in use
```

Это значит, что порт 53 занят службой **systemd-resolved**. <br>
Оставляем её для работы локальной сети сервера, а в настройках AdGuard выбираем в обоих полях интерфейс с **IP сервера**. <br>
⚠️ На скриншоте второй интерфейс не выбран - надо выбрать тоже eth0 как и в первом ⚠️

![dns](https://github.com/soulpastwk/share/raw/main/media/vpn00/dns-02.png)

---

## 5️⃣ Покупка домена и настройка DNS 🌍

Рекомендую [Aeza](https://aeza.net/?ref=730263) (партнёрская ссылка).

1. Покупаем домен (зона `.ru` \~4€ в год). (оплата по СБП)
2. В панели домена добавляем **A-запись** → ваш IP VPS.
3. Ждём \~2 часа, пока обновятся записи.

> \[!TIP]
> Да нужно ввести паспортные данные, на пару цифр можно ошибиться не страшно ;-)

![dns](https://github.com/soulpastwk/share/raw/main/media/vpn00/dns-03.png)

---

## 6️⃣ Получение SSL-сертификата 🔐

После того, как домен привязан к ip севера - выполняем команду ниже, заменяя vash-domen.ru - на реальное имя вашего домена.

```bash
apt install certbot
certbot certonly --standalone -d vash-domen.ru
```

Подтверждаем запросы (`y`), указываем email.
Сертификаты будут сохранены, пути к ним нужно прописать в настройках веб-панели AdGuard.

![dns](https://github.com/soulpastwk/share/raw/main/media/vpn00/dns-04.png)

> [!IMPORTANT]
> ## Пока можно оставить, но потом снять !!! <br>
> ## ⚠️⚠️⚠️ **Снять галочку с `Включить незашифрованный DNS`** ⚠️⚠️⚠️ <br>
> ## НО в дальнейшем надо настроить сервера на DoH и DoT <br>

![dns](https://github.com/soulpastwk/share/raw/main/media/vpn00/dns-05.png)

![dns](https://github.com/soulpastwk/share/raw/main/media/vpn00/dns-06.png)

---

## 7️⃣ Проверка работы ✅

Теперь откройте панель управления по домену:

```
https://vash-domen.ru
```

Вводим логин/пароль → должны попасть в админку AdGuard.

---

## 8️⃣ Настройка DNS-схемы 🌐

Рекомендуется использовать несколько внешних серверов (Google, Quad9 и др.) как резолверы. <br>
В AdGuard есть выбор:

* **Параллельные запросы** → быстрее, но нагрузка на сеть.
* **Балансировка** → равномерно распределяет запросы.

### Примеры серверов:

```
https://dns10.quad9.net/dns-query
tls://8.8.8.8
tls://8.8.4.4
```

---

## 9️⃣ Фильтрация трафика 🚧

AdGuard поддерживает **публичные списки блокировок**.  
Можно использовать несколько вариантов:  

- ✅ Включить **готовые списки** в настройках.  
- 📂 Загрузить свой список (**RAW URL**).  
- 🛡️ Использовать **отфильтрованные DNS от AdGuard**:  

| 🏷️ Тип сервера      | 🌐 Протокол | 🔗 Адрес                                       |
| ------------------- | ----------- | ---------------------------------------------- |
| Сервер по умолчанию | DoH         | `https://dns.adguard-dns.com/dns-query`        |
| Без фильтрации      | DoH         | `https://unfiltered.adguard-dns.com/dns-query` |
| Семейный сервер     | DoH         | `https://family.adguard-dns.com/dns-query`     |
| Сервер по умолчанию | DoT         | `tls://dns.adguard-dns.com`                    |
| Без фильтрации      | DoT         | `tls://unfiltered.adguard-dns.com`             |
| Семейный сервер     | DoT         | `tls://family.adguard-dns.com`                 |
| Сервер по умолчанию | DoQ         | `quic://dns.adguard-dns.com`                   |
| Без фильтрации      | DoQ         | `quic://unfiltered.adguard-dns.com`            |
| Семейный сервер     | DoQ         | `quic://family.adguard-dns.com`                |
| Сервер по умолчанию | IPv4        | `94.140.14.14, 94.140.15.15`                   |
| Без фильтрации      | IPv4        | `94.140.14.140, 94.140.14.141`                 |
| Семейный сервер     | IPv4        | `94.140.14.15, 94.140.15.16`                   |
| Сервер по умолчанию | IPv6        | `2a10:50c0::ad1:ff, 2a10:50c0::ad2:ff`         |
| Без фильтрации      | IPv6        | `2a10:50c0::1:ff, 2a10:50c0::2:ff`             |
| Семейный сервер     | IPv6        | `2a10:50c0::bad1:ff, 2a10:50c0::bad2:ff`       |

---

> \[!IMPORTANT]
> ## Советую настроить основные Upstream DNS-серверы в веб-панели <br>
> ## "Настройки" - "Настройки DNS"👇

# ✅ Рекомендуемый порядок DNS-серверов в AdGuard

## 1. `https://dns10.quad9.net/dns-query` (DoH, Quad9)  
**Первый приоритет**  
- Главный сервер для безопасности: фильтрует malware, фишинг, ботнеты.  
- Работает через **DoH** → порт 443 почти никогда не блокируется.  

---

## 2. `tls://dns.adguard-dns.com` (DoT, AdGuard)  
**Второй приоритет**  
- Фильтрация рекламы и трекеров.  
- **DoT** даёт надёжное шифрование, но зависит от порта 853 (его иногда режут).  
- Поэтому ставим после Quad9: если DoT недоступен → всё равно останешься на DoH (Quad9).  

---

## 3. `https://dns.adguard-dns.com/dns-query` (DoH, AdGuard)  
**Третий приоритет (резерв)**  
- Дублирует сервер AdGuard, но через **DoH**.  
- Если порт 853 заблокирован → подхватит DoH.  

---

## 4. `tls://unfiltered.adguard-dns.com` (DoT, AdGuard Unfiltered)  
**Четвёртый приоритет (аварийный резерв)**  
- Чистый DNS **без блокировок**.  
- Используется только если остальные серверы недоступны или фильтрация мешает.  

![dns](https://github.com/soulpastwk/share/raw/main/media/vpn00/dns-07.png)

![dns](https://github.com/soulpastwk/share/raw/main/media/vpn00/dns-08.png)

---

## 🔒 Как это работает в реальности  

1. Все запросы в первую очередь идут через **Quad9 (DoH)** → защита от вредоносных сайтов.  
2. Если Quad9 недоступен → запросы переходят на **AdGuard (DoT)** → фильтрация рекламы.  
3. Если порт 853 заблокирован → AdGuard работает через **DoH**.  
4. Если что-то совсем не так (например, фильтр режет нужный сайт) → сработает **Unfiltered AdGuard**.  

---

## ⚡ В итоге у тебя:  
- 🛡 **Безопасность (Quad9)**  
- 🚫 **Блокировка рекламы/трекеров (AdGuard)**  
- 🔄 **Стабильность (есть DoH и DoT на случай блокировок)**  
- 🆘 **Резервный чистый DNS**  

### 🔗 Примеры RAW-списков блокировок

Можно найти десятки вариантов на GitHub (`blocklist`, `AdGuard list`, `PiHole list`).  
Я использую такие:  

### 📂 Список RAW-URL (нажмите, чтобы развернуть)

<details>
<summary>Развернуть список блокировок</summary>

- [Pi-hole blocklist](https://raw.githubusercontent.com/Pyenb/Pi-hole-blocklist/main/blocklist.txt)
- [StevenBlack hosts](https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts)
- [BlocklistProject ads](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/ads.txt)
- [BlocklistProject basic](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/basic.txt)
- [BlocklistProject crypto](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/crypto.txt)
- [BlocklistProject fraud](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/fraud.txt)
- [BlocklistProject gambling](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/gambling.txt)
- [BlocklistProject malware.ip](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/malware.ip)
- [BlocklistProject malware.txt](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/malware.txt)
- [BlocklistProject phishing](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/phishing.txt)
- [BlocklistProject ransomware](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/ransomware.txt)
- [BlocklistProject tracking](https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/tracking.txt)
- [YouTube Ads 4 Pi-hole (crowed_list)](https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/crowed_list.txt)
- [KADhosts](https://raw.githubusercontent.com/FiltersHeroes/KADhosts/refs/heads/master/KADhosts.txt)
- [AdGuard SDNS Filter](https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt)
- [YouTube Ads 4 Pi-hole (youtubelist)](https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/youtubelist.txt)
- [Energized Ultimate](https://block.energized.pro/ultimate/formats/domains.txt)
- [AdAway](https://adaway.org/hosts.txt)
- [Phishing Army](https://phishing.army/download/phishing_army_blocklist.txt)
- [Spam404 main-blacklist](https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt)
- [KADhosts azet12](https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt)

</details>

---

> [!TIP]  
> При добавлении списков в панели **Фильтры → Чёрные списки DNS**:  
> - Добавляйте списки **по одному**.  
> - Мониторьте сервер через `htop` — ждите, пока нагрузка спадёт, и только потом добавляйте следующий.  
> - Если нагрузка не снижается в течение **5 минут** → делайте `reboot`.  
> - Если завис SSH — перезагружайте сервер через **панель хостинг-провайдера**.  
>
> ⚠️ Некоторые листы содержат **миллионы доменов**, они добавляются, но могут подвиснуть сервер.  
