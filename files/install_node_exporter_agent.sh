#!/bin/bash
set -e

# Установка Node Exporter на ноду/агент для мониторинга
apt update && apt upgrade -y
apt install -y wget tar

useradd --no-create-home --shell /bin/false node_exporter || true
VER=1.9.1
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VER}/node_exporter-${VER}.linux-amd64.tar.gz
tar xvf node_exporter-${VER}.linux-amd64.tar.gz
cp node_exporter-${VER}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-${VER}.linux-amd64*

cat > /etc/systemd/system/node_exporter.service <<'EOFSVC'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)(\\|$)
Restart=always

[Install]
WantedBy=multi-user.target
EOFSVC

systemctl daemon-reload
systemctl enable --now node_exporter

echo "✅ Node Exporter запущен на порту 9100"
