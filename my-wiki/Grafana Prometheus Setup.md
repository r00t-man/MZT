# 🚨 Дисклеймер

> ⚠️ Установка Grafana/Prometheus в вашем сценарии возможна только:
> - 🌍 на **заграничный сервер**, или
> - 🇷🇺 на **российский сервер только под VPN/туннелем** (чтобы сервер имел стабильный доступ к внешним репозиториям и релизам).

---

# 📊 Установка Grafana + Prometheus (центральный сервер)

Этот гайд ставит:
- ✅ Prometheus (сбор метрик)
- ✅ Grafana (дашборды)
- ❗ Node Exporter вынесен в **отдельный скрипт** для нод/агентов, которые нужно мониторить.

## 1) 🚀 Установка одной командой

Выполните на центральном сервере:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)"
```

Или локально из репозитория:

```bash
sudo bash files/install_grafana_prometheus.sh
```

После установки:
- Grafana: `http://SERVER_IP:3000`
- Логин/пароль по умолчанию: `admin/admin`
- Prometheus: `http://SERVER_IP:9090`

---

## 2) 🔌 Подключение нод (агентов) для мониторинга

На **каждой удалённой ноде**, которую нужно мониторить, запустите:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)"
```

Или локально из репозитория:

```bash
sudo bash files/install_node_exporter_agent.sh
```

Node Exporter будет слушать `9100/tcp`.

---

## 3) 🧩 Добавьте ноды в конфиг Prometheus (на центральном сервере)

Отредактируйте `/etc/prometheus/prometheus.yml`:

```yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s

rule_files: []

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: Central-Prometheus
          group: central

  - job_name: nodes
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: Grafana
          group: central
      - targets: ['11.111.111.111:9100']
        labels:
          instance: 🇷🇺 Москва Remnawave
          group: moscow
      - targets: ['22.222.222.222:9100']
        labels:
          instance: 🇱🇻 Латвия YT no-ads 📺
          group: latvia
      - targets: ['33.33.33.33:9100']
        labels:
          instance: 🇩🇪 Германия - 3 YT no-ads 📺
          group: germany
      - targets: ['44.44.44.44:9100']
        labels:
          instance: 🇩🇪 Германия - Plus
          group: germany
```

Примените изменения:

```bash
sudo systemctl restart prometheus
```

Проверка:

```bash
sudo systemctl status prometheus --no-pager
curl -s http://localhost:9090/-/ready
```

---

## 4) 🎛️ Настройка Grafana datasource

1. Откройте `http://SERVER_IP:3000`
2. Войдите `admin/admin`
3. `Connections` → `Data sources` → `Add data source`
4. Выберите **Prometheus**
5. URL: `http://localhost:9090`
6. Нажмите `Save & test` ✅

---

## 5) 🔥 Порты firewall

Откройте необходимые порты:
- `3000/tcp` — Grafana
- `9090/tcp` — Prometheus
- `9100/tcp` — Node Exporter (на агентах)

---

## 6) 🛠️ Полезные команды

```bash
sudo systemctl status grafana-server --no-pager
sudo systemctl status prometheus --no-pager
sudo journalctl -u grafana-server -n 100 --no-pager
sudo journalctl -u prometheus -n 100 --no-pager
```

Удачной установки! 🚀📈
