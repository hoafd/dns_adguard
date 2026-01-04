#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# CẬP NHẬT: Tùy chọn Cloudflare/SSL, tự bật Firewall, chọn Port

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> ĐANG KHỞI TẠO HỆ THỐNG DNS MASTER...\e[0m"

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

# --- PHẦN 3: THIẾT LẬP THÔNG SỐ ---
docker rm -f unbound adguard 2>/dev/null || true

# Chọn cổng quản trị
printf "Chọn cổng quản trị AdGuard (Mặc định 3000): "
read INPUT_PORT < /dev/tty
ADG_PORT=${INPUT_PORT:-3000}

# Cấp RAM cho Unbound
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
printf "Cấp RAM cho Unbound (MB, mặc định 768, RAM rảnh: $FREE_RAM MB): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-768}
USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')

# Cloudflare Tunnel (Tùy chọn)
printf "Bạn có muốn cài đặt Cloudflare Tunnel không? (y/n): "
read USE_CF < /dev/tty
if [ "$USE_CF" == "y" ]; then
    printf "Dán Tunnel Token: "
    read CF_TOKEN < /dev/tty
    if [ ${#CF_TOKEN} -gt 50 ]; then
        cloudflared service uninstall || true
        cloudflared service install "$CF_TOKEN"
    fi
fi

# SSL Setup (Tùy chọn)
printf "Bạn có muốn cài đặt SSL Let's Encrypt qua Cloudflare không? (y/n): "
read USE_SSL < /dev/tty
HAS_SSL=false
if [ "$USE_SSL" == "y" ]; then
    printf "Nhập Cloudflare API Token: "
    read CF_SSL_TOKEN < /dev/tty
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

# --- PHẦN 4: TỰ BẬT TƯỜNG LỬA ---
echo ">>> Đang cấu hình và bật tường lửa (ufw)..."
ufw allow 22/tcp
ufw allow 53/tcp
ufw allow 53/udp
ufw allow $ADG_PORT/tcp
if [ "$HAS_SSL" = true ]; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi
echo "y" | ufw enable

# --- PHẦN 5: KHỞI CHẠY DOCKER ---
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

# Tạo file Compose (Chỉ mount SSL nếu có)
SSL_MOUNT=""
if [ "$HAS_SSL" = true ]; then
    SSL_MOUNT="- /etc/letsencrypt:/etc/letsencrypt:ro"
fi

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
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf
      $SSL_MOUNT
EOF

cd "$BASE_DIR" && docker compose up -d --force-recreate

# Dọn dẹp hàng tuần
(crontab -l 2>/dev/null | grep -v "docker system prune" ; echo "0 0 * * 0 docker system prune -af > /dev/null 2>&1") | crontab -

# --- PHẦN 6: HƯỚNG DẪN SAU CÀI ĐẶT ---
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n\e[32m======================================================================"
echo -e "   🎉 CÀI ĐẶT DNS MASTER THÀNH CÔNG!"
echo -e "======================================================================\e[0m"
echo -e "👉 Truy cập Web UI thiết lập: \e[36mhttp://$SERVER_IP:$ADG_PORT\e[0m"
echo -e "✅ Tường lửa (UFW) đã được bật và mở cổng: 53, $ADG_PORT"
echo -e "✅ Đã thiết lập Tự động dọn dẹp rác Docker vào 0h Chủ Nhật."
echo -e "\e[33mBƯỚC TIẾP THEO:\e[0m"
echo -e "1. Vào AdGuard -> DNS Settings -> Upstream: 127.0.0.1:5335"
echo -e "2. Link Filter: https://raw.githubusercontent.com/hoafd/my-dns-blocklist/main/dns_filter.txt"
echo -e "======================================================================\n"
