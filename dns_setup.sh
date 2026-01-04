#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# FIX: Đọc input trực tiếp từ TTY để không bị skip khi dùng curl | bash

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> ĐANG KHỞI TẠO HỆ THỐNG DNS MASTER...\e[0m"

# 1. DỌN DẸP CONTAINER CŨ ĐỂ TRÁNH XUNG ĐỘT (FIX CONFLICT)
echo -e "\e[33m>>> Dọn dẹp các container cũ (unbound, adguard)...\e[0m"
docker rm -f unbound adguard 2>/dev/null || true

# 2. KIỂM TRA RAM VÀ HỎI DỮ LIỆU (Dùng /dev/tty để bắt buộc nhập)
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
SUGGESTED_RAM=$((FREE_RAM / 2))
echo -e "\e[33m>>> RAM rảnh hiện tại: $FREE_RAM MB.\e[0m"
printf "Cấp RAM cho Unbound Cache (MB, Enter để lấy $SUGGESTED_RAM): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-$SUGGESTED_RAM}

# Đảm bảo USER_RAM là số
USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

# 3. KIỂM TRA CLOUDFLARE TUNNEL
if systemctl is-active --quiet cloudflared; then
    echo -e "\e[32m[✓] Cloudflare Tunnel đang hoạt động.\e[0m"
    printf "Nhập Token mới (Nếu muốn đổi, không thì để trống): "
    read CF_TOKEN < /dev/tty
else
    printf "Nhập Cloudflare Tunnel Token của bạn: "
    read CF_TOKEN < /dev/tty
fi

if [ ${#CF_TOKEN} -gt 50 ]; then
    cloudflared service uninstall || true
    cloudflared service install "$CF_TOKEN"
fi

# 4. GIẢI PHÓNG CỔNG 53
if lsof -i :53 > /dev/null 2>&1; then
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

# 5. TẠO CẤU HÌNH VÀ CHẠY DOCKER
mkdir -p "$BASE_DIR/unbound" "$BASE_DIR/adguard/conf" "$BASE_DIR/adguard/work"

cat <<EOF > "$BASE_DIR/unbound/unbound.conf"
server:
    interface: 0.0.0.0
    port: 5335
    access-control: 0.0.0.0/0 allow
    num-threads: $(nproc)
    msg-cache-size: ${MSG_CACHE}m
    rrset-cache-size: ${RRSET_CACHE}m
    cache-min-ttl: 3600
    prefetch: yes
    serve-expired: yes
EOF

cat <<EOF > "$BASE_DIR/docker-compose.yml"
services:
  unbound:
    image: mvance/unbound:latest
    container_name: unbound
    restart: unless-stopped
    network_mode: host
    volumes: ["./unbound/unbound.conf:/opt/unbound/etc/unbound/unbound.conf:ro"]
  adguard:
    image: adguard/adguardhome:latest
    container_name: adguard
    restart: unless-stopped
    network_mode: host
    volumes: ["./adguard/work:/opt/adguardhome/work","./adguard/conf:/opt/adguardhome/conf"]
    depends_on: [unbound]
EOF

cd "$BASE_DIR"
docker compose up -d --force-recreate

echo -e "\e[32m[✓] CÀI ĐẶT DNS THÀNH CÔNG!\e[0m"
