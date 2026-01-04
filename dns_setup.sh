#!/bin/bash
# ==============================================================================
# SCRIPT: CÀI ĐẶT DNS MASTER (ADGUARD + UNBOUND) - TỐI ƯU RAM TRỐNG
# REPO: https://github.com/hoafd/dns_adguard
# ==============================================================================

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
REAL_USER=${SUDO_USER:-$USER}
BASE_DIR="/opt/server-central/dns"
set -e

# 1. KIỂM TRA RAM TRỐNG (AVAILABLE RAM)
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
SUGGESTED_RAM=$((FREE_RAM / 2))
echo -e "\e[33m>>> KIỂM TRA RAM: Máy bạn đang còn trống thực tế $FREE_RAM MB RAM.\e[0m"
echo -e "\e[32m>>> Mức đề nghị cấp cho DNS Master: ${SUGGESTED_RAM} MB.\e[0m"
read -p "Nhập số RAM bạn muốn cấp (MB, nhấn Enter để lấy $SUGGESTED_RAM): " USER_RAM
USER_RAM=${USER_RAM:-$SUGGESTED_RAM}

MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

# 2. GIẢI PHÓNG CỔNG 53 & KIỂM TRA TUNNEL
if lsof -i :53 > /dev/null 2>&1; then
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

if systemctl is-active --quiet cloudflared; then
    echo -e "\e[32m[✓] Tunnel đang chạy.\e[0m"
    read -p "Nhập Token mới (nhấn Enter để giữ nguyên): " CF_TOKEN
else
    read -p "Nhập Cloudflare Tunnel Token: " CF_TOKEN
fi
[ -n "$CF_TOKEN" ] && (cloudflared service uninstall || true; cloudflared service install "$CF_TOKEN")

# 3. CÀI ĐẶT SSL (NẾU CHƯA CÓ)
EXISTING_CERT=$(ls /etc/letsencrypt/live/ 2>/dev/null | head -n 1 || true)
if [ -z "$EXISTING_CERT" ]; then
    read -p "Nhập Tên miền (VD: dns.hoafd.id.vn): " DOMAIN_NAME
    read -p "Nhập Cloudflare API Token: " CF_SSL_TOKEN
    read -p "Nhập Email: " EMAIL
    apt update && apt install -y certbot python3-certbot-dns-cloudflare -qq
    mkdir -p ~/.secrets && echo "dns_cloudflare_api_token = $CF_SSL_TOKEN" > ~/.secrets/cloudflare.ini
    chmod 600 ~/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
      -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
fi

# 4. CẤU HÌNH DOCKER
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

ufw allow 22/tcp && ufw allow 53 && echo "y" | ufw enable
chown -R "$REAL_USER:$REAL_USER" "$BASE_DIR"
cd "$BASE_DIR" && docker compose up -d
echo -e "\e[32m[✓] DNS MASTER HOÀN TẤT!\e[0m"
