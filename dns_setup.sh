#!/bin/bash
# ==============================================================================
# SCRIPT 2: CÀI ĐẶT DNS MASTER (TÙY CHỈNH THEO RAM TRỐNG)
# ==============================================================================

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
REAL_USER=${SUDO_USER:-$USER}
BASE_DIR="/opt/server-central/dns"
set -e

# 1. KIỂM TRA RAM TRỐNG VÀ ĐỀ XUẤT
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
SUGGESTED_RAM=$((FREE_RAM / 2)) # Đề xuất dùng 50% lượng RAM đang rảnh
echo -e "\033[33m>>> KIỂM TRA RAM: Hệ thống đang còn trống $FREE_RAM MB RAM.\033[0m"
echo -e "\033[32m>>> Mức đề nghị cấp cho DNS Master: ${SUGGESTED_RAM} MB.\033[0m"
read -p "Nhập số RAM bạn muốn cấp (MB, nhấn Enter để lấy $SUGGESTED_RAM): " USER_RAM
USER_RAM=${USER_RAM:-$SUGGESTED_RAM}

# Tính toán phân bổ Cache (1/3 cho msg, 2/3 cho rrset)
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

# 2. GIẢI PHÓNG CỔNG 53 & TUNNEL
echo -e "\033[33m>>> ĐANG GIẢI PHÓNG CỔNG 53 VÀ KIỂM TRA TUNNEL...\033[0m"
if lsof -i :53 > /dev/null 2>&1; then
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

if systemctl is-active --quiet cloudflared; then
    echo -e "\033[32m[✓] Tunnel đang chạy.\033[0m"
    read -p "Nhập Token mới (nhấn Enter để giữ nguyên): " CF_TOKEN
else
    read -p "Nhập Cloudflare Tunnel Token: " CF_TOKEN
fi
[ -n "$CF_TOKEN" ] && (cloudflared service uninstall || true; cloudflared service install "$CF_TOKEN")

# 3. SSL (Chỉ hỏi nếu máy chưa có chứng chỉ)
EXISTING_CERT=$(ls /etc/letsencrypt/live/ 2>/dev/null | head -n 1 || true)
if [ -z "$EXISTING_CERT" ]; then
    read -p "Nhập Tên miền (VD: dns.hoafd.id.vn): " DOMAIN_NAME
    read -p "Nhập Cloudflare API Token: " CF_SSL_TOKEN
    read -p "Nhập Email: " EMAIL
    mkdir -p ~/.secrets && echo "dns_cloudflare_api_token = $CF_SSL_TOKEN" > ~/.secrets/cloudflare.ini
    chmod 600 ~/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
      -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
fi

# 4. TẠO CẤU HÌNH UNBOUND (DYN RAM)
mkdir -p "$BASE_DIR/unbound" "$BASE_DIR/adguard/conf" "$BASE_DIR/adguard/work"

cat <<EOF > "$BASE_DIR/unbound/unbound.conf"
server:
    interface: 0.0.0.0
    port: 5335
    access-control: 0.0.0.0/0 allow
    num-threads: $(nproc)
    # Tối ưu dựa trên RAM đã chọn
    msg-cache-size: ${MSG_CACHE}m
    rrset-cache-size: ${RRSET_CACHE}m
    msg-cache-slabs: 8
    rrset-cache-slabs: 8
    cache-min-ttl: 3600
    prefetch: yes
    serve-expired: yes
    so-rcvbuf: 8m
    so-sndbuf: 8m
EOF

# 5. DOCKER COMPOSE
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

# 6. KHỞI CHẠY
ufw allow 22/tcp && ufw allow 53 && echo "y" | ufw enable
chown -R "$REAL_USER:$REAL_USER" "$BASE_DIR"
cd "$BASE_DIR" && docker compose up -d

echo -e "\033[32m[✓] DNS MASTER HOÀN TẤT VỚI CACHE ${USER_RAM}MB!\033[0m"
echo -e "\033[36m>>> TRANG QUẢN TRỊ: http://localhost:3000\033[0m"
