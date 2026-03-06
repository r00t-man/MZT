#!/usr/bin/env bash

set -e

echo "==[1] Basic APT cleanup =="
apt clean
apt autoclean
apt autoremove --purge -y
dpkg -l | awk '/^rc/ {print $2}' | xargs -r apt purge -y

echo "==[2] Journald cleanup =="
journalctl --vacuum-time=7d || true
journalctl --vacuum-size=100M || true

echo "==[3] APT lists cleanup (rebuild) =="
rm -rf /var/lib/apt/lists/*
apt update

echo "==[4] Docker cleanup (unused images/networks/build cache) =="
if command -v docker >/dev/null 2>&1; then
  docker system prune -a -f
fi

echo "==[5] Limit Docker logs (prevents future disk bloat) =="
if [ -d /etc/docker ]; then
  mkdir -p /etc/docker
  cat >/etc/docker/daemon.json <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
JSON
  systemctl restart docker || true
fi

echo "==[6] Remove docs + man pages =="
rm -rf /usr/share/doc/* /usr/share/man/*

echo "==[7] Remove Snap (common on Ubuntu, often useless on VPS) =="
if dpkg -l | grep -q '^ii\s\+snapd\s'; then
  systemctl stop snapd.socket snapd.service 2>/dev/null || true
  systemctl disable snapd.socket snapd.service 2>/dev/null || true
  apt purge -y snapd
  rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd
  apt autoremove --purge -y
fi

echo "==[8] Locale purge (keep only en_US + ru_RU if present) =="
# Safe default: keep en + ru. Adjust if you need more.
export DEBIAN_FRONTEND=noninteractive
apt install -y localepurge
sed -i 's/^#\?NEEDSCONFIGFIRST.*/NEEDSCONFIGFIRST="no"/' /etc/locale.nopurge || true
cat >/etc/locale.nopurge <<'EOF'
# Keep these locales
en_US.UTF-8
en_GB.UTF-8
ru_RU.UTF-8
# Keep all language packs for these locales only
EOF
localepurge || true

echo "==[9] Firmware removal (VPS-only recommendation) =="
# On VPS, linux-firmware is usually unnecessary and large.
# Comment these lines if you are on bare-metal or unsure.
if dpkg -l | grep -q '^ii\s\+linux-firmware\s'; then
  apt purge -y linux-firmware || true
  apt autoremove --purge -y
fi

echo "==[10] Remove build toolchains if you don't compile on the server =="
# llvm is a frequent big one. Also remove compilers if you don't need them.
apt purge -y llvm-* || true
apt autoremove --purge -y

echo "==[11] Kernel cleanup (keep current + one newest) =="
CURRENT_KERNEL="$(uname -r)"
KERNEL_PKGS="$(dpkg -l | awk '/^ii  linux-image-[0-9]/ {print $2}')"
LATEST_PKG="$(echo "$KERNEL_PKGS" | sort -V | tail -n 1)"
LATEST_VER="${LATEST_PKG#linux-image-}"

for P in $KERNEL_PKGS; do
  VER="${P#linux-image-}"
  if [ "$VER" != "$CURRENT_KERNEL" ] && [ "$VER" != "$LATEST_VER" ]; then
    apt purge -y "$P" || true
  fi
done
dpkg -l | awk '/^rc  linux-image-/ {print $2}' | xargs -r apt purge -y || true
apt autoremove --purge -y

echo "==[12] Clean tmp =="
rm -rf /tmp/* /var/tmp/* || true

echo "==[13] Final report =="
echo "--- Disk usage:"
df -h
echo
echo "--- Biggest directories:"
du -xh / 2>/dev/null | sort -h | tail -n 30
echo
echo "--- Docker usage:"
docker system df 2>/dev/null || true
echo
echo "DONE."
