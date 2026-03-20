# 🔐 Server Security

В этом разделе собраны материалы по защите и надёжной базовой настройке Linux/VPS-серверов,
которые применимы **не только к VPN**.

## 📚 Материалы

- [02_Настройка безопасности сервера](./02_%D0%9D%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D0%B1%D0%B5%D0%B7%D0%BE%D0%BF%D0%B0%D1%81%D0%BD%D0%BE%D1%81%D1%82%D0%B8%20%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0.md)
- [03_Безопасная настройка sudo](./03_%D0%91%D0%B5%D0%B7%D0%BE%D0%BF%D0%B0%D1%81%D0%BD%D0%B0%D1%8F%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20sudo.md)
- [06_Настройка безопасности sysctl.conf](./06_%D0%9D%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D0%B1%D0%B5%D0%B7%D0%BE%D0%BF%D0%B0%D1%81%D0%BD%D0%BE%D1%81%D1%82%D0%B8%20sysctl.conf.md)
- [07_Настройка SSH-ключей](./07_%D0%9D%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20SSH-%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%B9.md)
- [12_Безопасная DNS-конфигурация сервера (DoT + DNSSEC)](./12_%D0%91%D0%B5%D0%B7%D0%BE%D0%BF%D0%B0%D1%81%D0%BD%D0%B0%D1%8F%20DNS-%D0%BA%D0%BE%D0%BD%D1%84%D0%B8%D0%B3%D1%83%D1%80%D0%B0%D1%86%D0%B8%D1%8F%20%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0%20(DoT%20+%20DNSSEC).md)
- [13_Сетевой кейс VPS маски 24 и 32](./13_%D0%A1%D0%B5%D1%82%D0%B5%D0%B2%D0%BE%D0%B9%20%D0%BA%D0%B5%D0%B9%D1%81%20VPS%20%D0%BC%D0%B0%D1%81%D0%BA%D0%B8%2024%20%D0%B8%2032.md)

---

## ✅ Что осталось в `VPN_3x-ui`

В `VPN_3x-ui` остались материалы, которые относятся преимущественно к
развёртыванию и эксплуатации VPN: установка, каскадирование, доменные правила,
VPN-специфичные DNS-сценарии и маскировка трафика.

---

## 🆕 Новая статья по мониторингу

- 📘 [Grafana Prometheus Setup](../my-wiki/Grafana%20Prometheus%20Setup.md)

**Быстрый старт (центральный сервер):**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)
```

**Быстрый старт (агенты/ноды):**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)
```
---

## 🐳 Полезный инструмент для администрирования Docker

Если после базового hardening сервера нужен удобный инструмент для повседневной работы с Docker, смотри отдельную статью:

- 📘 [Dockermon — интерактивное управление Docker из терминала](../my-wiki/Dockermon%20—%20интерактивное%20управление%20Docker%20из%20терминала.md)

**Установка в одну команду:**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/r00t-man/MZT/main/files/dockermon.sh)
```
