#!/bin/bash
set -e

# Установка Prometheus + Grafana (без Node Exporter)
apt update && apt upgrade -y
apt install -y wget tar software-properties-common apt-transport-https gnupg

# Prometheus
useradd --no-create-home --shell /bin/false prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /var/lib/prometheus

VER=3.9.0
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${VER}/prometheus-${VER}.linux-amd64.tar.gz
tar xvf prometheus-${VER}.linux-amd64.tar.gz
cp prometheus-${VER}.linux-amd64/prometheus prometheus-${VER}.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

cat > /etc/prometheus/prometheus.yml <<'PROMEOF'
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
PROMEOF

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
rm -rf prometheus-${VER}.linux-amd64*

cat > /etc/systemd/system/prometheus.service <<'EOF2'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=200h \
  --web.enable-lifecycle \
  --web.enable-admin-api
Restart=always

[Install]
WantedBy=multi-user.target
EOF2

systemctl daemon-reload
systemctl enable --now prometheus

# Grafana
install -d -m 0755 /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt update
apt install -y grafana
systemctl daemon-reload
systemctl enable --now grafana-server

echo ""
echo "✅ Установка завершена"
echo "Откройте Grafana: http://<SERVER_IP>:3000"
echo "Логин/пароль по умолчанию: admin/admin"
echo "Порты: 9090/tcp (Prometheus), 3000/tcp (Grafana), 9100/tcp (Node Exporter на агентах)"
