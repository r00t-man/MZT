# 📊 Grafana — дашборды Blackbox Exporter и cAdvisor

> [!NOTE]
> Эта статья — надстройка над [Grafana Prometheus Setup](./Grafana%20Prometheus%20Setup.md).
> Сначала поднимите центральный Prometheus + Grafana по той статье, потом возвращайтесь сюда.

Два готовых дашборда:

- **Blackbox Overview — Grouped TCP / SSH / ICMP** — живой ли сервер снаружи: пингуется ли (ICMP),
  открыт ли SSH-порт, открыт ли TCP 443 (или другой порт HTTPS/панели). Отдельно таблица
  "Current Targets Status" и "Average Duration" по всем job'ам сразу.
- **cAdvisor Docker Insights** — CPU/RAM/диск/сеть по каждому Docker-контейнеру на сервере, где
  запущен cAdvisor.

JSON обоих дашбордов лежат в [`wiki/dashboards/`](./dashboards/):
- [`Blackbox_Overview_-_Grouped_TCP_SSH_ICMP.json`](./dashboards/Blackbox_Overview_-_Grouped_TCP_SSH_ICMP.json)
- [`cAdvisor_Docker_Insights.json`](./dashboards/cAdvisor_Docker_Insights.json)

---

## 1) 🎯 Blackbox Exporter (ICMP / SSH / TCP)

Blackbox Exporter опрашивает цели снаружи и отдаёт Prometheus метрики `probe_success` /
`probe_duration_seconds`. Ставится **на том же сервере, где Prometheus** (или на любом, откуда
нужно "видеть" ноды).

### 1.1) Конфиг модулей

`/opt/blackbox/blackbox.yml`:

```yml
modules:
  http_2xx:
    prober: http
    timeout: 10s
    http:
      method: GET
      preferred_ip_protocol: ip4
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []
      no_follow_redirects: false
      fail_if_ssl: false
      fail_if_not_ssl: false

  tcp_connect:
    prober: tcp
    timeout: 8s
    tcp:
      preferred_ip_protocol: ip4

  icmp:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: ip4
```

### 1.2) Запуск через Docker Compose

`/opt/blackbox/docker-compose.yml`:

```yml
services:
  blackbox-exporter:
    image: quay.io/prometheus/blackbox-exporter:latest
    container_name: blackbox-exporter
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_RAW          # обязательно для ICMP-пробера
    volumes:
      - ./blackbox.yml:/etc/blackbox_exporter/config.yml:ro
    command:
      - --config.file=/etc/blackbox_exporter/config.yml
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "3"
```

```bash
cd /opt/blackbox && docker compose up -d
```

`network_mode: host` — иначе ICMP/TCP-пробы будут уходить не с реального внешнего интерфейса
сервера. Порт `9115` (веб-интерфейс exporter'а, `/probe`) слушает на хосте, наружу открывать не
нужно — Prometheus стучится в него локально.

### 1.3) Job'ы в `/etc/prometheus/prometheus.yml`

Дашборд ждёт ровно эти имена job: `blackbox_icmp`, `blackbox_ssh`, `blackbox_tcp_443` (плюс
опционально `blackbox_https` — он в дашборде исключён ad-hoc фильтром по умолчанию, но участвует
в общих таблицах через переменную `job_all`). У каждой цели можно (не обязательно) добавить
лейбл `display_name` — он используется на панели "Пинг с сервера мониторинга до всех серверов" для
человекочитаемых подписей вместо голых IP.

```yml
  - job_name: blackbox_icmp
    metrics_path: /probe
    params:
      module: [icmp]
    static_configs:
      - targets: ['11.111.111.111']
        labels:
          display_name: 'Москва Remnawave'
      - targets: ['22.222.222.222']
        labels:
          display_name: 'Латвия'

  - job_name: blackbox_ssh
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
          - '11.111.111.111:22'
          - '22.222.222.222:2222'

  - job_name: blackbox_tcp_443
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
          - 'panel.example.com:443'
          - 'edge.example.com:443'

  - job_name: blackbox_https
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - 'https://panel.example.com'
          - 'https://edge.example.com'
```

> [!IMPORTANT]
> Для `blackbox_icmp` / `blackbox_ssh` / `blackbox_tcp_443` / `blackbox_https` **обязательно**
> нужен ещё общий блок `relabel_configs`. Без него `probe_success` будет мерить сам blackbox-exporter,
> а не удалённые цели, а переменные дашборда (`target_tcp`, `target_ssh`, `target_icmp` и т.п.)
> останутся пустыми — они фильтруют именно по лейблу `target`, который Prometheus сам не создаёт:

```yml
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - source_labels: [__param_target]
        target_label: target
      - target_label: __address__
        replacement: 127.0.0.1:9115   # адрес blackbox-exporter
```

Добавьте этот `relabel_configs` в каждый из четырёх `blackbox_*` job'ов (после `static_configs`).

Применить:

```bash
sudo systemctl restart prometheus
curl -s 'http://localhost:9090/api/v1/query?query=probe_success' | head -c 300
```

---

## 2) 🐳 cAdvisor (метрики Docker-контейнеров)

Ставится на **каждом сервере**, где нужно видеть CPU/RAM/сеть по контейнерам (панель Docker,
ноды с ботами и т.п.) — не только на центральном сервере с Prometheus.

```bash
docker run -d \
  --name=cadvisor \
  --restart=unless-stopped \
  --privileged \
  -p 127.0.0.1:8081:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:rw \
  -v /sys:/sys:ro \
  -v /var/lib/docker:/var/lib/docker:ro \
  -v /dev/disk:/dev/disk:ro \
  gcr.io/cadvisor/cadvisor:latest \
  --docker_only=true \
  --housekeeping_interval=30s
```

Порт `8081` намеренно забинден только на `127.0.0.1` — наружу не торчит. Если Prometheus стоит
на **другом** сервере, добавьте туда доступ через SSH-туннель/VPN, а не открывайте `8081` в
интернет.

### 2.1) Job в `prometheus.yml`

```yml
  - job_name: cadvisor
    static_configs:
      - targets: ['127.0.0.1:8081']
        labels:
          instance: my-server
```

Если Prometheus ходит на cAdvisor удалённого сервера через туннель — укажите адрес туннеля
вместо `127.0.0.1:8081`.

```bash
sudo systemctl restart prometheus
```

---

## 3) 📥 Импорт дашбордов в Grafana

1. Скачайте нужный JSON из [`wiki/dashboards/`](./dashboards/) (или сразу по прямой ссылке ниже).
2. В Grafana: **Dashboards → New → Import**.
3. **Upload dashboard JSON file** — выберите скачанный файл (или вставьте содержимое в поле
   **Import via panel json**).
4. В выпадающем списке **Prometheus** выберите свой datasource (переменная `DS_PROMETHEUS` внутри
   дашборда — Grafana сама предложит выбор при импорте).
5. **Import**.

Прямые ссылки (можно скачать `curl`):

```bash
curl -fsSL -o Blackbox_Overview_-_Grouped_TCP_SSH_ICMP.json \
  https://raw.githubusercontent.com/r00t-man/MZT/main/wiki/dashboards/Blackbox_Overview_-_Grouped_TCP_SSH_ICMP.json

curl -fsSL -o cAdvisor_Docker_Insights.json \
  https://raw.githubusercontent.com/r00t-man/MZT/main/wiki/dashboards/cAdvisor_Docker_Insights.json
```

---

## 4) 🎛️ Что означают переменные дашборда Blackbox

| Переменная | Что делает |
|---|---|
| `target_tcp` / `target_ssh` / `target_icmp` | Мультиселект целей отдельно для каждого блока (TCP 443 / SSH / ICMP) — фильтрует верхние stat-панели и графики Probe Duration |
| `job_all` / `target_all` | Общие мультиселекты для нижних таблиц "Current Targets Status" и "Average Duration (5m)" — работают по всем job сразу |
| Ad-hoc фильтр `job != blackbox_https` | По умолчанию скрывает `blackbox_https` из общих таблиц, чтобы не дублировать TCP 443 и HTTPS-пробы одной и той же цели — уберите фильтр вручную в UI, если нужно видеть и его |
| `display_name` (лейбл таргета, не переменная) | Человекочитаемая подпись на gauge-панели ICMP вместо IP — задаётся в `prometheus.yml` у каждого таргета |

---

## 5) 🔥 Порты firewall (сводка)

- `9115/tcp` — Blackbox Exporter web/`/probe` — **не открывать наружу**, только локально для Prometheus
- `8081/tcp` — cAdvisor — забинден на `127.0.0.1`, наружу не открывать
- Остальное — см. [Grafana Prometheus Setup → 5) Порты firewall](./Grafana%20Prometheus%20Setup.md)

---

*Часть репозитория [r00t-man/MZT](https://github.com/r00t-man/MZT). Остальные статьи — в
[wiki/README.md](./README.md).*
