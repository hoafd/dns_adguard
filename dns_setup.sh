#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# CẬP NHẬT: Loại bỏ Watchtower, Fix RAM & SSL Token

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> BẮT ĐẦU CÀI ĐẶT DNS MASTER (KHÔNG WATCHTOWER)...\e[0m"

# 1. DỌN DẸP CONTAINER CŨ
docker rm -f unbound adguard watchtower 2>/dev/null || true

# 2. CẤU HÌNH RAM THÔNG MINH
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
# Đề xuất 512MB nếu máy mạnh, 256MB nếu máy yếu
[ "$FREE_RAM" -gt 2000 ] && SUGGESTED_RAM=512 || SUGGESTED_RAM=256

echo -e "\e[33m>>> RAM rảnh hiện tại: $FREE_RAM MB.\e[0m"
echo -e "\e[36m[HƯỚNG DẪN]: Nhấn ENTER để dùng mặc định ($SUGGESTED_RAM MB) hoặc tự nhập (VD: 768).\e[0m"
printf "Cấp RAM cho Unbound (MB): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-$SUGGESTED_RAM}
USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')

# 3. CLOUDFLARE TUNNEL TOKEN
if systemctl is-active --quiet cloudflared; then
    echo -e "\e[32m[✓] Cloudflare Tunnel đã có sẵn.\e[0m"
    printf "Tunnel Token (Nhấn Enter để giữ nguyên, hoặc dán Token mới): "
    read CF_TOKEN < /dev/tty
else
    echo -e "\e[31m[!] Chưa có Cloudflare Tunnel.\e[0m"
    printf "Dán Tunnel Token [BẮT BUỘC]: "
    read CF_TOKEN < /dev/tty
fi
if [ ${#CF_TOKEN} -gt 50 ]; then
    cloudflared service uninstall 2>/dev/null || true
    cloudflared service install "$CF_TOKEN"
fi

# 4. CLOUDFLARE API TOKEN (CHO SSL)
echo -e "\e[34m----------------------------------------------------------\e[0m"
echo -e "\e[33m>>> CẤU HÌNH SSL (CERTBOT)\e[0m"
printf "Nhập Cloudflare API Token (Nhấn Enter để bỏ qua): "
read CF_SSL_TOKEN < /dev/tty

if [ ${#CF_SSL_TOKEN} -gt 10 ]; then
    printf "Nhập Tên miền (VD: dns.hoafd.id.vn): "
    read DOMAIN_NAME < /dev/tty
    printf "Nhập Email: "
    read EMAIL < /dev/tty
    
    apt update && apt install -y certbot python3-certbot-dns-cloudflare -qq
    mkdir -p ~/.secrets && echo "dns_cloudflare_api_token = $CF_SSL_TOKEN" > ~/.secrets/cloudflare.ini
    chmod 600 ~/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
      -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
fi

# 5. GIẢI PHÓNG CỔNG 53 & CẤU HÌNH DOCKER
[ -f /etc/resolv.conf ] && (systemctl stop systemd-resolved || true; systemctl disable systemd-resolved || true; echo "nameserver 1.1.1.1" > /etc/resolv.conf)

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

cd "$BASE_DIR" && docker compose up -d --force-recreate

# 6. HƯỚNG DẪN SAU CÀI ĐẶT
echo -e "\n\e[32m======================================================================"
echo -e "   CÀI ĐẶT DNS HOÀN TẤT (ĐÃ LOẠI BỎ WATCHTOWER)"
echo -e "======================================================================\e[0m"
echo -e "1. Cloudflare Zero Trust: Trỏ domain về http://localhost:3000"
echo -e "2. AdGuard Upstream: Thiết lập '127.0.0.1:5335' trong giao diện Web."
echo -e "======================================================================\n"
