#!/bin/bash
# ==============================================================================
# SCRIPT: CÀI ĐẶT DNS MASTER (ADGUARD + UNBOUND) - BẢN FIX 2026
# REPO: https://github.com/hoafd/dns_adguard
# ==============================================================================

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
REAL_USER=${SUDO_USER:-$USER}
BASE_DIR="/opt/server-central/dns"
set -e

# 1. KIỂM TRA RAM TRỐNG
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
SUGGESTED_RAM=$((FREE_RAM / 2))
echo -e "\e[33m>>> HỆ THỐNG: Còn trống $FREE_RAM MB RAM.\e[0m"

# Fix lỗi cú pháp bằng cách sử dụng Default Value của Bash
read -p "Cấp RAM cho Unbound Cache (MB, nhấn Enter để lấy $SUGGESTED_RAM): " INPUT_RAM
USER_RAM=${INPUT_RAM:-$SUGGESTED_RAM}

# Đảm bảo USER_RAM chỉ chứa số
USER_RAM=$(echo $USER_RAM | tr -dc '0-9')
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

# 2. DỌN DẸP CONTAINER CŨ (FIX LỖI CONFLICT)
echo -e "\e[33m>>> Đang dọn dẹp các container cũ để tránh xung đột...\e[0m"
docker stop unbound adguard 2>/dev/null || true
docker rm -f unbound adguard 2>/dev/null || true

# 3. GIẢI PHÓNG CỔNG 53 & KIỂM TRA TUNNEL
if lsof -i :53 > /dev/null 2>&1; then
    echo -e "\e[33m>>> Đang giải phóng cổng 53 khỏi systemd-resolved...\e[0m"
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

if systemctl is-active --quiet cloudflared; then
    echo -e "\e[32m[✓] Cloudflare Tunnel đã sẵn sàng.\e[0m"
    read -p "Nhập Token mới (Nếu muốn cập nhật, không thì để trống): " CF_TOKEN
else
    read -p "Nhập Cloudflare Tunnel Token: " CF_TOKEN
fi

# Chỉ cài đặt nếu Token có độ dài hợp lệ (Tránh lỗi Base64)
if [ ${#CF_TOKEN} -gt 50 ]; then
    echo -e "\e[33m>>> Đang cài đặt Cloudflare Service với Token mới...\e[0m"
    cloudflared service uninstall || true
    cloudflared service install "$CF_TOKEN"
fi

# 4. TẠO CẤU HÌNH DOCKER
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
    so-rcvbuf: 8m
    so-sndbuf: 8m
EOF

cat <<EOF > "$BASE_DIR/docker-compose.yml"
services:
  unbound:
    image: mvance/unbound:latest
    container_name: unbound
    restart: unless-stopped
    volumes:
      - ./unbound/unbound.conf:/opt/unbound/etc/unbound/unbound.conf:ro
    network_mode: host

  adguard:
    image: adguard/adguardhome:latest
    container_name: adguard
    restart: unless-stopped
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf
      - /etc/letsencrypt:/etc/letsencrypt:ro
    network_mode: host
    depends_on: [unbound]
EOF

# 5. FIREWALL
ufw allow 22/tcp || true
ufw allow 53 || true
ufw default deny incoming || true
echo "y" | ufw enable || true

# 6. KHỞI CHẠY
chown -R "$REAL_USER:$REAL_USER" "$BASE_DIR"
cd "$BASE_DIR"
docker compose up -d --force-recreate

echo -e "\n\e[32m[✓] CẬP NHẬT DNS ADGUARD THÀNH CÔNG!\e[0m\n"
