#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# CẬP NHẬT: Chọn Port quản trị, Auto-Docker, Port 53 Fix & Weekly Cleanup

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> ĐANG KHỞI TẠO HỆ THỐNG DNS MASTER (HARDENED VERSION)...\e[0m"

# --- PHẦN 1: TỰ ĐỘNG CÀI ĐẶT DOCKER ---
if ! [ -x "$(command -v docker)" ]; then
    echo -e "\e[33m[!] Đang cài đặt Docker...\e[0m"
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi
if ! docker compose version > /dev/null 2>&1; then
    apt-get update && apt-get install -y docker-compose-v2 -qq
fi

# --- PHẦN 2: GIẢI PHÓNG CỔNG 53 ---
echo ">>> Giải phóng cổng 53..."
apt-get install -y psmisc -qq
fuser -k 53/udp 2>/dev/null || true
fuser -k 53/tcp 2>/dev/null || true
systemctl stop systemd-resolved || true
systemctl disable systemd-resolved || true
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# --- PHẦN 3: THIẾT LẬP THÔNG SỐ & CỔNG ---
docker rm -f unbound adguard 2>/dev/null || true

# Chọn cổng quản trị AdGuard
printf "Chọn cổng quản trị AdGuard (Mặc định 3000): "
read INPUT_PORT < /dev/tty
ADG_PORT=${INPUT_PORT:-3000}

FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
printf "Cấp RAM cho Unbound (MB, mặc định 768, RAM rảnh: $FREE_RAM MB): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-768}
USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')

# SSL Setup
printf "Nhập Cloudflare API Token (Enter nếu đã có SSL): "
read CF_SSL_TOKEN < /dev/tty
HAS_SSL=false
if [ ${#CF_SSL_TOKEN} -gt 10 ]; then
    printf "Nhập Tên miền (VD: dns.hoafd.id.vn): "
    read DOMAIN_NAME < /dev/tty
    printf "Nhập Email: "
    read EMAIL < /dev/tty
    apt update && apt install -y certbot python3-certbot-dns-cloudflare -qq
    mkdir -p ~/.secrets && echo "dns_cloudflare_api_token = $CF_SSL_TOKEN" > ~/.secrets/cloudflare.ini
    chmod 600 ~/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
      -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL" --deploy-hook "docker restart adguard"
    HAS_SSL=true
fi

# Mở cổng Firewall dựa trên cổng đã chọn
ufw allow 22/tcp && ufw allow 53 && ufw allow $ADG_PORT/tcp && ufw allow 80/tcp && ufw allow 443/tcp
echo "y" | ufw enable

# --- PHẦN 4: KHỞI CHẠY DOCKER ---
mkdir -p "$BASE_DIR/unbound" "$BASE_DIR/adguard/conf" "$BASE_DIR/adguard/work"
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

cat <<EOF > "$BASE_DIR/unbound/unbound.conf"
server:
    interface: 0.0.0.0
    port: 5335
    access-control: 0.0.0.0/0 allow
    num-threads: $(nproc)
    msg-cache-size: ${MSG_CACHE}m
    rrset-cache-size: ${RRSET_CACHE}m
    so-rcvbuf: 1m
EOF

cat <<EOF > "$BASE_DIR/docker-compose.yml"
services:
  unbound:
    image: mvance/unbound:latest
    container_name: unbound
    restart: always
    network_mode: host
    volumes: ["./unbound/unbound.conf:/opt/unbound/etc/unbound/unbound.conf:ro"]
  adguard:
    image: adguard/adguardhome:latest
    container_name: adguard
    restart: always
    network_mode: host
    volumes: ["./adguard/work:/opt/adguardhome/work","./adguard/conf:/opt/adguardhome/conf","/etc/letsencrypt:/etc/letsencrypt:ro"]
EOF

cd "$BASE_DIR" && docker compose up -d --force-recreate

# --- PHẦN 5: AUTO CLEANUP ---
(crontab -l 2>/dev/null | grep -v "docker system prune" ; echo "0 0 * * 0 docker system prune -af > /dev/null 2>&1") | crontab -

# --- PHẦN 6: HƯỚNG DẪN SAU CÀI ĐẶT ---
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n\e[32m======================================================================"
echo -e "   🎉 CÀI ĐẶT DNS MASTER THÀNH CÔNG!"
echo -e "======================================================================\e[0m"
echo -e "👉 Truy cập Web UI thiết lập: \e[36mhttp://$SERVER_IP:$ADG_PORT\e[0m"
echo -e "✅ Đã mở cổng $ADG_PORT trên Firewall."
echo -e "✅ Đã thiết lập Tự động dọn dẹp rác Docker vào 0h Chủ Nhật hàng tuần."
if [ "$HAS_SSL" = true ]; then
echo -e "✅ Chứng chỉ cho: \e[32m$DOMAIN_NAME\e[0m"
fi
echo -e "\e[33mBƯỚC TIẾP THEO:\e[0m"
echo -e "1. Vào AdGuard -> DNS Settings -> Upstream: 127.0.0.1:5335"
echo -e "2. Thêm Filter của Hoa FD nếu muốn (https://github.com/hoafd/my-dns-blocklist): https://raw.githubusercontent.com/hoafd/my-dns-blocklist/main/dns_filter.txt"
echo -e "======================================================================\n"
